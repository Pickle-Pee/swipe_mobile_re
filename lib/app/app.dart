import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/chat/application/chat_providers.dart';
import 'router/app_router.dart';
import 'providers/navigation_events_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription? _navSub;

  @override
  void initState() {
    super.initState();

    // Subscribe once at app start
    final nav = ref.read(navigationEventsProvider);
    final router = ref.read(appRouterProvider);
    unawaited(ref.read(authControllerProvider.notifier).restoreSession());
    ref.read(chatSocketManagerProvider);
    ref.read(chatRealtimeProvider);

    _navSub = nav.stream.listen((event) {
      router.go(event.route);
    });
  }

  @override
  void dispose() {
    _navSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
