import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/session_storage.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';
import 'auth_state.dart';

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStore: ref.watch(sessionStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return DioAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    storage: ref.watch(sessionStorageProvider),
  );
});

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() => const AuthState.initial();

  Future<void> restoreSession() => _authenticate(
        _repository.restoreSession,
        nullIsUnauthenticated: true,
      );

  Future<void> login(LoginRequest request) =>
      _authenticate(() => _repository.login(request));

  Future<void> register(RegisterRequest request) =>
      _authenticate(() => _repository.register(request));

  Future<void> refreshSession() =>
      _authenticate(_repository.refreshSession);

  Future<void> logout() async {
    state = const AuthState.loading();
    try {
      await _repository.logout();
      state = const AuthState.unauthenticated();
    } on Object catch (error) {
      state = AuthState.error(error);
    }
  }

  Future<void> sendCode(SendCodeRequest request) =>
      _runAction(() => _repository.sendCode(request));

  Future<void> checkCode(CheckCodeRequest request) =>
      _runAction(() => _repository.checkCode(request));

  Future<void> _authenticate(
    Future<AuthUser?> Function() operation, {
    bool nullIsUnauthenticated = false,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await operation();
      if (user == null && nullIsUnauthenticated) {
        state = const AuthState.unauthenticated();
      } else if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } on UnauthorizedApiException {
      state = const AuthState.unauthenticated();
    } on Object catch (error) {
      state = AuthState.error(error);
    }
  }

  Future<void> _runAction(Future<void> Function() operation) async {
    final previous = state;
    state = const AuthState.loading();
    try {
      await operation();
      state = previous;
    } on Object catch (error) {
      state = AuthState.error(error);
    }
  }
}
