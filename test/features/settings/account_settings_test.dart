import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:swipe_mobile_re/app/router/routes.dart';
import 'package:swipe_mobile_re/core/network/api_exception.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_providers.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_state.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_models.dart';
import 'package:swipe_mobile_re/features/settings/account_settings_screen.dart';
import 'package:swipe_mobile_re/features/settings/app_information_screen.dart';
import 'package:swipe_mobile_re/features/settings/application/settings_providers.dart';
import 'package:swipe_mobile_re/features/settings/delete_account_screen.dart';
import 'package:swipe_mobile_re/features/settings/domain/settings_models.dart';
import 'package:swipe_mobile_re/features/settings/domain/settings_repository.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('Account shows only real identity and opens deletion warning', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: Routes.accountSettings,
      routes: [
        GoRoute(
          path: Routes.accountSettings,
          builder: (_, _) => const AccountSettingsScreen(),
        ),
        GoRoute(
          path: Routes.deleteAccount,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('Delete destination'))),
        ),
        GoRoute(
          path: Routes.settings,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('Settings'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_AuthenticatedController.new),
        ],
        child: MaterialApp.router(
          theme: AppTheme.midnight(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('#42'), findsOneWidget);
    expect(find.text('Phone verification code'), findsOneWidget);
    expect(find.textContaining('access token'), findsNothing);
    expect(find.textContaining('Verified'), findsNothing);

    await tester.tap(find.byKey(const Key('account-delete-route')));
    await tester.pumpAndSettle();
    expect(find.text('Delete destination'), findsOneWidget);
  });

  test(
    'delete controller serializes the destructive request and cleanup',
    () async {
      final repository = _SettingsRepository();
      var cleanupCalls = 0;
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          deleteAccountSessionCleanupProvider.overrideWithValue(() async {
            cleanupCalls++;
          }),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        deleteAccountControllerProvider.notifier,
      );

      final first = controller.deleteAccount();
      final second = controller.deleteAccount();

      expect(repository.deleteCalls, 1);
      expect(await second, isFalse);
      repository.completer.complete();
      expect(await first, isTrue);
      expect(cleanupCalls, 1);
      expect(
        container.read(deleteAccountControllerProvider).status,
        DeleteAccountStatus.deleted,
      );
    },
  );

  testWidgets(
    'delete error keeps the account screen stable and exposes retry copy',
    (tester) async {
      final repository = _SettingsRepository(
        error: const NetworkApiException(message: 'offline'),
      );
      final router = _deleteRouter();
      addTearDown(router.dispose);
      await _pumpDelete(tester, router, repository);

      await tester.tap(find.byKey(const Key('delete-account-continue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-delete-account')));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, Routes.deleteAccount);
      expect(find.byKey(const Key('delete-account-error')), findsOneWidget);
      expect(find.textContaining('still active'), findsOneWidget);
      expect(find.text('Review and retry deletion'), findsOneWidget);
    },
  );

  testWidgets('delete success clears locally only after backend confirmation', (
    tester,
  ) async {
    final repository = _SettingsRepository();
    var cleanupCalls = 0;
    final router = _deleteRouter();
    addTearDown(router.dispose);
    await _pumpDelete(
      tester,
      router,
      repository,
      cleanup: () async {
        cleanupCalls++;
      },
    );

    await tester.tap(find.byKey(const Key('delete-account-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-account')));
    await tester.pump();

    expect(find.byKey(const Key('delete-account-progress')), findsOneWidget);
    expect(cleanupCalls, 0);
    expect(router.state.uri.path, Routes.deleteAccount);

    repository.completer.complete();
    await tester.pumpAndSettle();

    expect(cleanupCalls, 1);
    expect(router.state.uri.path, Routes.welcome);
    expect(find.text('Welcome after deletion'), findsOneWidget);
  });

  testWidgets('App information uses installed package values from its source', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appInformationSourceProvider.overrideWithValue(
            const _AppInformationSource(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.midnight(),
          home: const AppInformationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Swipe'), findsOneWidget);
    expect(find.text('0.1.0'), findsOneWidget);
    expect(find.text('17'), findsOneWidget);
    expect(find.textContaining('API base'), findsNothing);
  });
}

class _AuthenticatedController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(AuthUser(id: 42));
}

class _SettingsRepository implements SettingsRepository {
  _SettingsRepository({this.error});

  final Object? error;
  final completer = Completer<void>();
  int deleteCalls = 0;

  @override
  Future<void> deleteAccount() {
    deleteCalls++;
    final failure = error;
    if (failure != null) return Future<void>.error(failure);
    return completer.future;
  }
}

class _AppInformationSource implements AppInformationSource {
  const _AppInformationSource();

  @override
  Future<AppPackageInfo> load() async => const AppPackageInfo(
    appName: 'Swipe',
    version: '0.1.0',
    buildNumber: '17',
  );
}

GoRouter _deleteRouter() => GoRouter(
  initialLocation: Routes.deleteAccount,
  routes: [
    GoRoute(
      path: Routes.deleteAccount,
      builder: (_, _) => const DeleteAccountScreen(),
    ),
    GoRoute(
      path: Routes.accountSettings,
      builder: (_, _) => const Scaffold(body: Center(child: Text('Account'))),
    ),
    GoRoute(
      path: Routes.welcome,
      builder: (_, _) =>
          const Scaffold(body: Center(child: Text('Welcome after deletion'))),
    ),
  ],
);

Future<void> _pumpDelete(
  WidgetTester tester,
  GoRouter router,
  _SettingsRepository repository, {
  Future<void> Function()? cleanup,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repository),
        deleteAccountSessionCleanupProvider.overrideWithValue(
          cleanup ?? () async {},
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.midnight(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
