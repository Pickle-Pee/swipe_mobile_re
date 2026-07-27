import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/app/router/app_router.dart';
import 'package:swipe_mobile_re/app/router/routes.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_providers.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_models.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_repository.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('signed-out deep route is replaced by Welcome', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_SignedOutRepository()),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.midnight(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Meet people\nat your pace.'), findsOneWidget);

    router.go(Routes.profile);
    await tester.pump();
    expect(router.state.uri.path, Routes.welcome);
    expect(find.text('Meet people\nat your pace.'), findsOneWidget);
  });
}

class _SignedOutRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<void> checkCode(CheckCodeRequest request) async {}

  @override
  Future<AccountStatus> checkPhone(String phoneNumber) async =>
      AccountStatus.newUser;

  @override
  Future<AuthUser> login(LoginRequest request) async => const AuthUser(id: 1);

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUser> refreshSession() async => const AuthUser(id: 1);

  @override
  Future<AuthUser> register(RegisterRequest request) async =>
      const AuthUser(id: 1);

  @override
  Future<SendCodeResponse> sendCode(SendCodeRequest request) async =>
      const SendCodeResponse();

  @override
  Future<AuthUser> whoAmI() async => const AuthUser(id: 1);
}
