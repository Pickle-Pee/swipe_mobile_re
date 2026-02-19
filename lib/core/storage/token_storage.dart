import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<int> setAccessToken(String accessToken) async {
    try {
      await _storage.write(key: 'access_token', value: accessToken);
      return 0;
    } catch (e) {
      print("Error setting access token: $e");
      return -1;
    }
  }

  Future<int> setRefreshToken(String refreshToken) async {
    try {
      await _storage.write(key: 'refresh_token', value: refreshToken);
      return 0;
    } catch (e) {
      print("Error setting refresh token: $e");
      return -1;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: 'refresh_token');
    } catch (e) {
      print("Error getting refresh token: $e");
      return null;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: 'access_token');
    } catch (e) {
      print("Error getting access token: $e");
      return null;
    }
  }

  Future<int> clearTokens() async {
    try {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      return 0;
    } catch (e) {
      print("Error clearing tokens: $e");
      return -1;
    }
  }
}
