import '../domain/auth_models.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  const AuthState.initial() : this(status: AuthStatus.initial);
  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.authenticated(AuthUser user)
      : this(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated()
      : this(status: AuthStatus.unauthenticated);
  const AuthState.error(Object error)
      : this(status: AuthStatus.error, error: error);

  final AuthStatus status;
  final AuthUser? user;
  final Object? error;
}
