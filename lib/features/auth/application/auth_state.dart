import '../domain/auth_models.dart';

enum AuthStatus {
  initial,
  restoring,
  unauthenticated,
  submitting,
  authenticated,
  restoreError,
  signingOut,
}

class AuthState {
  const AuthState({required this.status, this.user, this.error});

  const AuthState.initial() : this(status: AuthStatus.initial);
  const AuthState.restoring() : this(status: AuthStatus.restoring);
  const AuthState.submitting() : this(status: AuthStatus.submitting);
  const AuthState.authenticated(AuthUser user)
    : this(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated([Object? error])
    : this(status: AuthStatus.unauthenticated, error: error);
  const AuthState.restoreError(Object error)
    : this(status: AuthStatus.restoreError, error: error);
  const AuthState.signingOut() : this(status: AuthStatus.signingOut);

  final AuthStatus status;
  final AuthUser? user;
  final Object? error;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
}
