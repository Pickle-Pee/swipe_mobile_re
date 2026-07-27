import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/session_storage.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';
import 'auth_state.dart';

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  final storage = SessionStorage();
  ref.onDispose(storage.dispose);
  return storage;
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

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  Future<void>? _restoreFuture;
  var _sessionEpoch = 0;

  @override
  AuthState build() {
    _restoreFuture = null;
    return const AuthState.initial();
  }

  Future<void> restoreSession() {
    final running = _restoreFuture;
    if (running != null) return running;
    if (state.isAuthenticated || state.status == AuthStatus.signingOut) {
      return Future.value();
    }

    late final Future<void> tracked;
    tracked = _performRestore().whenComplete(() {
      if (identical(_restoreFuture, tracked)) _restoreFuture = null;
    });
    _restoreFuture = tracked;
    return tracked;
  }

  Future<bool> login(LoginRequest request) =>
      _authenticate(() => _repository.login(request));

  Future<bool> register(RegisterRequest request) =>
      _authenticate(() => _repository.register(request));

  Future<void> refreshSession() async {
    final epoch = _sessionEpoch;
    state = const AuthState.restoring();
    try {
      final user = await _repository.refreshSession();
      if (epoch == _sessionEpoch) state = AuthState.authenticated(user);
    } on UnauthorizedApiException catch (error) {
      if (epoch == _sessionEpoch) state = AuthState.unauthenticated(error);
    } on Object catch (error) {
      if (epoch == _sessionEpoch) state = AuthState.restoreError(error);
    }
  }

  Future<void> logout() async {
    if (state.status == AuthStatus.signingOut) return;
    _sessionEpoch++;
    state = const AuthState.signingOut();
    try {
      await _repository.logout();
      state = const AuthState.unauthenticated();
    } on Object catch (error) {
      state = AuthState.unauthenticated(error);
    }
  }

  void sessionInvalidated() {
    if (state.status == AuthStatus.signingOut ||
        state.status == AuthStatus.unauthenticated) {
      return;
    }
    _sessionEpoch++;
    state = const AuthState.unauthenticated();
  }

  Future<SendCodeResponse> sendCode(SendCodeRequest request) =>
      _repository.sendCode(request);

  Future<void> checkCode(CheckCodeRequest request) =>
      _repository.checkCode(request);

  Future<void> _performRestore() async {
    final epoch = _sessionEpoch;
    state = const AuthState.restoring();
    try {
      final user = await _repository.restoreSession();
      if (epoch != _sessionEpoch) return;
      state = user == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(user);
    } on UnauthorizedApiException catch (error) {
      if (epoch == _sessionEpoch) state = AuthState.unauthenticated(error);
    } on Object catch (error) {
      if (epoch == _sessionEpoch) state = AuthState.restoreError(error);
    }
  }

  Future<bool> _authenticate(Future<AuthUser> Function() operation) async {
    if (state.status == AuthStatus.submitting) return false;
    final epoch = _sessionEpoch;
    state = const AuthState.submitting();
    try {
      final user = await operation();
      if (epoch != _sessionEpoch) return false;
      state = AuthState.authenticated(user);
      return true;
    } on UnauthorizedApiException catch (error) {
      if (epoch == _sessionEpoch) state = AuthState.unauthenticated(error);
      return false;
    } on Object catch (error) {
      if (epoch == _sessionEpoch) state = AuthState.unauthenticated(error);
      return false;
    }
  }
}
