import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/core/network/api_exception.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_providers.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_state.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_models.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_repository.dart';

void main() {
  test('restoreSession publishes authenticated state', () async {
    final repository = FakeAuthRepository(restoredUser: const AuthUser(id: 3));
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).restoreSession();

    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.id, 3);
  });

  test(
    'restoreSession publishes unauthenticated state without a session',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).restoreSession();

      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
    },
  );

  test(
    'logout clears repository session and publishes unauthenticated',
    () async {
      final repository = FakeAuthRepository(
        restoredUser: const AuthUser(id: 3),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(authControllerProvider.notifier);
      await controller.restoreSession();

      await controller.logout();

      expect(repository.logoutCalled, isTrue);
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
    },
  );

  test('duplicate restore calls share one repository operation', () async {
    final repository = DelayedRestoreRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(authControllerProvider.notifier);

    final first = controller.restoreSession();
    final second = controller.restoreSession();
    expect(identical(first, second), isTrue);
    expect(repository.restoreCalls, 1);

    repository.restoreCompleter.complete(const AuthUser(id: 8));
    await Future.wait([first, second]);
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.authenticated,
    );
  });

  test('logout during restore ignores the stale restored user', () async {
    final repository = DelayedRestoreRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(authControllerProvider.notifier);

    final restoring = controller.restoreSession();
    await controller.logout();
    repository.restoreCompleter.complete(const AuthUser(id: 8));
    await restoring;

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
  });

  test('offline restore exposes a retryable restore error', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          ErrorRestoreRepository(const NetworkApiException(message: 'offline')),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).restoreSession();

    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.restoreError);
    expect(state.error, isA<NetworkApiException>());
  });
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.restoredUser});

  AuthUser? restoredUser;
  bool logoutCalled = false;

  @override
  Future<void> checkCode(CheckCodeRequest request) async {}

  @override
  Future<AccountStatus> checkPhone(String phoneNumber) async =>
      AccountStatus.existingUser;

  @override
  Future<AuthUser> login(LoginRequest request) async => const AuthUser(id: 1);

  @override
  Future<void> logout() async {
    logoutCalled = true;
    restoredUser = null;
  }

  @override
  Future<AuthUser> refreshSession() async => const AuthUser(id: 1);

  @override
  Future<AuthUser> register(RegisterRequest request) async =>
      const AuthUser(id: 1);

  @override
  Future<AuthUser?> restoreSession() async => restoredUser;

  @override
  Future<SendCodeResponse> sendCode(SendCodeRequest request) async =>
      const SendCodeResponse();

  @override
  Future<AuthUser> whoAmI() async => restoredUser ?? const AuthUser(id: 1);
}

class DelayedRestoreRepository extends FakeAuthRepository {
  final restoreCompleter = Completer<AuthUser?>();
  int restoreCalls = 0;

  @override
  Future<AuthUser?> restoreSession() {
    restoreCalls++;
    return restoreCompleter.future;
  }
}

class ErrorRestoreRepository extends FakeAuthRepository {
  ErrorRestoreRepository(this.error);

  final Object error;

  @override
  Future<AuthUser?> restoreSession() async => throw error;
}
