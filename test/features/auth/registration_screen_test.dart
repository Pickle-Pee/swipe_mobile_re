import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/core/network/api_exception.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_providers.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_models.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_repository.dart';
import 'package:swipe_mobile_re/features/onboarding/registration_screen.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('empty identity step shows field errors', (tester) async {
    await _pumpRegistration(tester, RegistrationAuthRepository());

    await tester.tap(find.byKey(const Key('registration-continue')));
    await tester.pump();

    expect(find.text('First name is required'), findsOneWidget);
    expect(find.text('Last name is required'), findsOneWidget);
  });

  testWidgets('valid registration submits canonical fields only once', (
    tester,
  ) async {
    final repository = RegistrationAuthRepository(delayed: true);
    await _pumpRegistration(tester, repository);
    await _advanceToReview(tester);

    await tester.tap(find.byKey(const Key('registration-continue')));
    await tester.tap(find.byKey(const Key('registration-continue')));
    await tester.pump();

    expect(repository.registerCalls, 1);
    expect(repository.lastRequest?.phoneNumber, '79990000000');
    expect(repository.lastRequest?.firstName, 'Mila');
    expect(repository.lastRequest?.lastName, 'Stone');
    expect(repository.lastRequest?.gender, 'female');
    expect(repository.lastRequest?.cityName, 'Lisbon');
    expect(repository.lastRequest?.additionalFields, isEmpty);

    repository.registerCompleter.completeError(
      const NetworkApiException(message: 'offline'),
    );
    await tester.pump();
  });

  testWidgets('account conflict keeps form and offers login', (tester) async {
    final repository = RegistrationAuthRepository(
      registerError: const ValidationApiException(
        message: 'Phone number already registered',
        statusCode: 400,
      ),
    );
    await _pumpRegistration(tester, repository);
    await _advanceToReview(tester);

    await tester.tap(find.byKey(const Key('registration-continue')));
    await tester.pump();

    expect(
      find.text('An account with this phone number already exists.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('registration-sign-in')), findsOneWidget);
    expect(find.text('Mila Stone'), findsOneWidget);
    expect(find.text('Lisbon'), findsOneWidget);
  });
}

Future<void> _pumpRegistration(WidgetTester tester, AuthRepository repository) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.midnight(),
        home: const RegistrationScreen(phoneNumber: '79990000000'),
      ),
    ),
  );
}

Future<void> _advanceToReview(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('registration-first-name')),
    'Mila',
  );
  await tester.enterText(
    find.byKey(const Key('registration-last-name')),
    'Stone',
  );
  await tester.tap(find.byKey(const Key('registration-continue')));
  await tester.pump();

  await tester.tap(find.byKey(const Key('registration-birthday')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('registration-continue')));
  await tester.pump();

  await tester.tap(find.byKey(const Key('registration-gender-female')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('registration-continue')));
  await tester.pump();

  await tester.enterText(find.byKey(const Key('registration-city')), 'Lisbon');
  await tester.tap(find.byKey(const Key('registration-continue')));
  await tester.pump();
}

class RegistrationAuthRepository implements AuthRepository {
  RegistrationAuthRepository({this.delayed = false, this.registerError});

  final bool delayed;
  final Object? registerError;
  final registerCompleter = Completer<AuthUser>();
  int registerCalls = 0;
  RegisterRequest? lastRequest;

  @override
  Future<AuthUser> register(RegisterRequest request) {
    registerCalls++;
    lastRequest = request;
    final error = registerError;
    if (error != null) return Future<AuthUser>.error(error);
    if (delayed) return registerCompleter.future;
    return Future.value(const AuthUser(id: 9));
  }

  @override
  Future<void> checkCode(CheckCodeRequest request) async {}

  @override
  Future<AccountStatus> checkPhone(String phoneNumber) async =>
      AccountStatus.newUser;

  @override
  Future<AuthUser> login(LoginRequest request) async => const AuthUser(id: 9);

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUser> refreshSession() async => const AuthUser(id: 9);

  @override
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<SendCodeResponse> sendCode(SendCodeRequest request) async =>
      const SendCodeResponse();

  @override
  Future<AuthUser> whoAmI() async => const AuthUser(id: 9);
}
