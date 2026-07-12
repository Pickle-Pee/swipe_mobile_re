import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';

abstract interface class SecureStorageBackend {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureStorageBackend implements SecureStorageBackend {
  const FlutterSecureStorageBackend([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class SessionStorage implements ApiTokenStore {
  SessionStorage({SecureStorageBackend? backend})
    : _backend = backend ?? const FlutterSecureStorageBackend();

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';

  final SecureStorageBackend _backend;
  final _accessTokenChanges = StreamController<String?>.broadcast();

  Stream<String?> get accessTokenChanges => _accessTokenChanges.stream;

  Future<bool> get hasSession async {
    final accessToken = await readAccessToken();
    final refreshToken = await readRefreshToken();
    return accessToken?.isNotEmpty == true && refreshToken?.isNotEmpty == true;
  }

  @override
  Future<String?> readAccessToken() => _backend.read(accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _backend.read(refreshTokenKey);

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw ArgumentError('Session tokens must not be empty');
    }
    try {
      final normalizedAccessToken = _stripBearer(accessToken);
      await _backend.write(accessTokenKey, normalizedAccessToken);
      await _backend.write(refreshTokenKey, _stripBearer(refreshToken));
      _accessTokenChanges.add(normalizedAccessToken);
    } on Object {
      await clear();
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    await _backend.delete(accessTokenKey);
    await _backend.delete(refreshTokenKey);
    _accessTokenChanges.add(null);
  }

  Future<void> dispose() => _accessTokenChanges.close();

  static String _stripBearer(String token) =>
      token.startsWith('Bearer ') ? token.substring(7) : token;
}
