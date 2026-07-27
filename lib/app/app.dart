import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/application/auth_state.dart';
import '../features/chat/application/chat_providers.dart';
import '../features/discovery/application/discovery_providers.dart';
import '../features/likes/application/likes_providers.dart';
import '../features/onboarding/application/onboarding_providers.dart';
import '../features/profile/application/profile_providers.dart';
import '../features/profile/application/public_profile_providers.dart';
import '../features/subscription/application/subscription_providers.dart';
import 'router/app_router.dart';
import 'providers/navigation_events_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription? _navSub;
  StreamSubscription<String?>? _tokenSub;
  ProviderSubscription<AuthState>? _authSub;
  var _hadAuthenticatedSession = false;

  @override
  void initState() {
    super.initState();

    // Subscribe once at app start
    final nav = ref.read(navigationEventsProvider);
    final router = ref.read(appRouterProvider);
    ref.read(chatSocketManagerProvider);
    ref.read(chatRealtimeProvider);

    _navSub = nav.stream.listen((event) {
      router.go(event.route);
    });
    _tokenSub = ref.read(sessionStorageProvider).accessTokenChanges.listen((
      token,
    ) {
      if (token != null || !mounted) return;
      final auth = ref.read(authControllerProvider);
      if (auth.isAuthenticated) {
        ref.read(authControllerProvider.notifier).sessionInvalidated();
      }
    });
    _hadAuthenticatedSession = ref.read(authControllerProvider).isAuthenticated;
    _authSub = ref.listenManual<AuthState>(authControllerProvider, (_, next) {
      if (next.isAuthenticated) {
        _hadAuthenticatedSession = true;
        return;
      }
      final endedSession =
          _hadAuthenticatedSession &&
          (next.status == AuthStatus.signingOut ||
              next.status == AuthStatus.unauthenticated);
      if (endedSession) {
        _hadAuthenticatedSession = false;
        _clearPrivateState();
      }
    });
  }

  void _clearPrivateState() {
    ref.invalidate(onboardingControllerProvider);
    ref.invalidate(profileEditControllerProvider);
    ref.invalidate(profileControllerProvider);
    ref.invalidate(publicProfileControllerProvider);
    ref.invalidate(discoveryControllerProvider);
    ref.invalidate(likesControllerProvider);
    ref.invalidate(chatMessagesControllerProvider);
    ref.invalidate(chatListControllerProvider);
    ref.invalidate(activeChatRegistryProvider);
    ref.invalidate(subscriptionControllerProvider);
    ref.invalidate(subscriptionAccessControllerProvider);
  }

  @override
  void dispose() {
    _navSub?.cancel();
    _tokenSub?.cancel();
    _authSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.midnight(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
