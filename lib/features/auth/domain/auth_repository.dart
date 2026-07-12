import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/session_storage.dart';
import 'auth_models.dart';

abstract interface class AuthRepository {
  Future<void> sendCode(SendCodeRequest request);
  Future<void> checkCode(CheckCodeRequest request);
  Future<AuthUser> register(RegisterRequest request);
  Future<AuthUser> login(LoginRequest request);
  Future<AuthUser> refreshSession();
  Future<AuthUser> whoAmI();
  Future<void> logout();
  Future<AuthUser?> restoreSession();
}

class DioAuthRepository implements AuthRepository {
  DioAuthRepository({
    required ApiClient apiClient,
    required SessionStorage storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  final ApiClient _apiClient;
  final SessionStorage _storage;

  @override
  Future<void> sendCode(SendCodeRequest request) async {
    await _apiClient.post<void>(
      '/auth/send_code',
      queryParameters: request.toQueryParameters(),
    );
  }

  @override
  Future<void> checkCode(CheckCodeRequest request) async {
    await _apiClient.post<void>(
      '/auth/check_code',
      queryParameters: request.toQueryParameters(),
    );
  }

  @override
  Future<AuthUser> register(RegisterRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/register',
      data: request.toJson(),
    );
    await _saveSession(response.data);
    return whoAmI();
  }

  @override
  Future<AuthUser> login(LoginRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      queryParameters: request.toQueryParameters(),
    );
    await _saveSession(response.data);
    return whoAmI();
  }

  @override
  Future<AuthUser> refreshSession() async {
    if (!await _apiClient.refreshSession()) {
      await logout();
      throw const UnauthorizedApiException(
        message: 'Session refresh failed',
        statusCode: 401,
      );
    }
    return whoAmI();
  }

  @override
  Future<AuthUser> whoAmI() async {
    final response =
        await _apiClient.get<Map<String, dynamic>>('/auth/whoami');
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty whoami response');
    }
    return AuthUser.fromJson(data);
  }

  @override
  Future<void> logout() => _storage.clear();

  @override
  Future<AuthUser?> restoreSession() async {
    if (!await _storage.hasSession) {
      return null;
    }
    try {
      return await whoAmI();
    } on UnauthorizedApiException {
      await logout();
      return null;
    }
  }

  Future<void> _saveSession(Map<String, dynamic>? data) async {
    if (data == null) {
      throw const FormatException('Empty authentication response');
    }
    final session = AuthSession.fromJson(data);
    await _storage.saveTokens(session.accessToken, session.refreshToken);
  }
}
