import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_providers.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_models.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_repository.dart';
import 'package:swipe_mobile_re/features/auth/presentation/phone_auth_screen.dart';

void main() {
  testWidgets('demo account shortcut fills the seeded user phone', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(DelayedAuthRepository()),
        ],
        child: const MaterialApp(home: PhoneAuthScreen()),
      ),
    );

    await tester.tap(find.byKey(const Key('use-demo-account')));

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '70000000001',
    );
  });

  testWidgets('double tap sends only one code request', (tester) async {
    final repository = DelayedAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: PhoneAuthScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField), '79990000000');
    await tester.tap(find.text('Send code'));
    await tester.tap(find.text('Send code'));

    expect(repository.sendCodeCalls, 1);

    repository.sendCodeCompleter.complete(const SendCodeResponse());
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class DelayedAuthRepository implements AuthRepository {
  final sendCodeCompleter = Completer<SendCodeResponse>();
  int sendCodeCalls = 0;

  @override
  Future<SendCodeResponse> sendCode(SendCodeRequest request) {
    sendCodeCalls++;
    return sendCodeCompleter.future;
  }

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
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<AuthUser> whoAmI() async => const AuthUser(id: 1);
}
