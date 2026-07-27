import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_providers.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_models.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_repository.dart';
import 'package:swipe_mobile_re/features/settings/settings_screen.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('logout is guarded and replaces the private route', (
    tester,
  ) async {
    final repository = _LogoutRepository();
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Signed out'))),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          theme: AppTheme.midnight(),
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-logout')));
    await tester.tap(find.byKey(const Key('settings-logout')));
    expect(repository.logoutCalls, 1);

    repository.logoutCompleter.complete();
    await tester.pump();
    await tester.pump();

    expect(router.state.uri.path, '/welcome');
    expect(find.text('Signed out'), findsOneWidget);
  });
}

class _LogoutRepository implements AuthRepository {
  final logoutCompleter = Completer<void>();
  int logoutCalls = 0;

  @override
  Future<void> logout() {
    logoutCalls++;
    return logoutCompleter.future;
  }

  @override
  Future<void> checkCode(CheckCodeRequest request) async {}

  @override
  Future<AccountStatus> checkPhone(String phoneNumber) async =>
      AccountStatus.existingUser;

  @override
  Future<AuthUser> login(LoginRequest request) async => const AuthUser(id: 1);

  @override
  Future<AuthUser> refreshSession() async => const AuthUser(id: 1);

  @override
  Future<AuthUser> register(RegisterRequest request) async =>
      const AuthUser(id: 1);

  @override
  Future<AuthUser?> restoreSession() async => const AuthUser(id: 1);

  @override
  Future<SendCodeResponse> sendCode(SendCodeRequest request) async =>
      const SendCodeResponse();

  @override
  Future<AuthUser> whoAmI() async => const AuthUser(id: 1);
}
