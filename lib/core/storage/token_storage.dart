import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<int> setAccessToken(String accessToken) async {
    try {
      await _storage.write(key: 'access_token', value: accessToken);
      return 0;
    } catch (_) {
      return -1;
    }
  }

  Future<int> setRefreshToken(String refreshToken) async {
    try {
      await _storage.write(key: 'refresh_token', value: refreshToken);
      return 0;
    } catch (_) {
      return -1;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: 'refresh_token');
    } catch (_) {
      return null;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: 'access_token');
    } catch (_) {
      return null;
    }
  }

  Future<int> clearTokens() async {
    try {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      return 0;
    } catch (_) {
      return -1;
    }
  }
}
