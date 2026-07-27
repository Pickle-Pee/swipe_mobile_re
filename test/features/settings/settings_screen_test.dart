import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:swipe_mobile_re/app/router/routes.dart';
import 'package:swipe_mobile_re/features/settings/settings_screen.dart';
import 'package:swipe_mobile_re/features/subscription/application/subscription_providers.dart';
import 'package:swipe_mobile_re/features/subscription/domain/subscription_models.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('Settings exposes only real sections and opens Account', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await _pump(
      tester,
      router: router,
      subscriptionController: _InactiveAccessController.new,
    );

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Discovery preferences'), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('App information'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Enhanced safety mode'), findsNothing);
    expect(find.text('AI conversation support'), findsNothing);
    expect(find.text('Notifications'), findsNothing);
    expect(find.text('Privacy and safety'), findsNothing);
    expect(find.text('Blocked users'), findsNothing);
    expect(find.text('Legal'), findsNothing);

    await tester.tap(find.byKey(const Key('settings-account')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, Routes.accountSettings);
    expect(find.text('Account destination'), findsOneWidget);
  });

  testWidgets('Subscription failure is section-scoped and retryable', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await _pump(
      tester,
      router: router,
      subscriptionController: _ErrorAccessController.new,
    );

    expect(find.text('Unavailable'), findsOneWidget);
    expect(
      find.text('Subscription status could not be refreshed.'),
      findsOneWidget,
    );
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('logout confirmation can be cancelled without changing route', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await _pump(
      tester,
      router: router,
      subscriptionController: _InactiveAccessController.new,
    );
    await tester.ensureVisible(find.byKey(const Key('settings-logout')));
    await tester.tap(find.byKey(const Key('settings-logout')));
    await tester.pumpAndSettle();

    expect(find.text('Sign out of Swipe?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancel-settings-logout')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, Routes.settings);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('active plan and real end date are shown without recurrent UI', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await _pump(
      tester,
      router: router,
      subscriptionController: _ActiveAccessController.new,
    );

    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Premium 90 · Ends Oct 20, 2026'), findsOneWidget);
    expect(find.textContaining('auto-renew', findRichText: true), findsNothing);
    expect(
      find.textContaining('next charge', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('Settings scrolls on a compact viewport at text scale 1.3', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final router = _router();
    addTearDown(router.dispose);
    await _pump(
      tester,
      router: router,
      subscriptionController: _ActiveAccessController.new,
      textScale: 1.3,
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-logout')),
      220,
      scrollable: find.byKey(const Key('settings-list')),
    );

    expect(find.byKey(const Key('settings-logout')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required GoRouter router,
  required SubscriptionAccessController Function() subscriptionController,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionAccessControllerProvider.overrideWith(
          subscriptionController,
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.midnight(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter _router() => GoRouter(
  initialLocation: Routes.settings,
  routes: [
    GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
    GoRoute(
      path: Routes.accountSettings,
      builder: (_, _) =>
          const Scaffold(body: Center(child: Text('Account destination'))),
    ),
    GoRoute(
      path: Routes.discoveryPreferences,
      builder: (_, _) =>
          const Scaffold(body: Center(child: Text('Preferences destination'))),
    ),
    GoRoute(
      path: Routes.premium,
      builder: (_, _) =>
          const Scaffold(body: Center(child: Text('Premium destination'))),
    ),
    GoRoute(
      path: Routes.appInformation,
      builder: (_, _) =>
          const Scaffold(body: Center(child: Text('About destination'))),
    ),
    GoRoute(
      path: Routes.profile,
      builder: (_, _) =>
          const Scaffold(body: Center(child: Text('Profile destination'))),
    ),
    GoRoute(
      path: Routes.welcome,
      builder: (_, _) =>
          const Scaffold(body: Center(child: Text('Welcome destination'))),
    ),
  ],
);

class _InactiveAccessController extends SubscriptionAccessController {
  @override
  SubscriptionAccessState build() =>
      const SubscriptionAccessState(status: SubscriptionAccessStatus.inactive);
}

class _ErrorAccessController extends SubscriptionAccessController {
  @override
  SubscriptionAccessState build() => SubscriptionAccessState(
    status: SubscriptionAccessStatus.error,
    error: Exception('offline'),
  );

  @override
  Future<void> refresh() async {}
}

class _ActiveAccessController extends SubscriptionAccessController {
  @override
  SubscriptionAccessState build() => SubscriptionAccessState(
    status: SubscriptionAccessStatus.active,
    activeSubscription: ActiveSubscription(
      subscriptionId: 2,
      name: 'Premium 90',
      startAt: DateTime.utc(2026, 7, 22),
      endAt: DateTime.utc(2026, 10, 20),
      renewable: false,
    ),
  );
}
