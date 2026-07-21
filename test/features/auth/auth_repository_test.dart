import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/core/network/api_client.dart';
import 'package:swipe_mobile_re/features/auth/data/session_storage.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_models.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_repository.dart';

void main() {
  late MemorySecureStorage backend;
  late SessionStorage storage;

  DioAuthRepository createRepository(MockHandler handler) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = MockHttpAdapter(handler);
    final client = ApiClient(dio: dio, tokenStore: storage, logSink: (_) {});
    return DioAuthRepository(apiClient: client, storage: storage);
  }

  setUp(() {
    backend = MemorySecureStorage();
    storage = SessionStorage(backend: backend);
  });

  test('login stores tokens and returns whoami user', () async {
    final repository = createRepository((options) async {
      if (options.path == '/auth/login') {
        expect(options.queryParameters, {
          'phone_number': '+79990000000',
          'code': '1234',
        });
        return jsonResponse(200, {
          'access_token': 'Bearer access-one',
          'refresh_token': 'refresh-one',
        });
      }
      expect(options.path, '/auth/whoami');
      expect(options.headers['Authorization'], 'Bearer access-one');
      return jsonResponse(200, {'id': 7, 'first_name': 'Ada'});
    });

    final user = await repository.login(
      const LoginRequest(phoneNumber: '+79990000000', code: '1234'),
    );

    expect(user.id, 7);
    expect(await storage.readAccessToken(), 'access-one');
    expect(await storage.readRefreshToken(), 'refresh-one');
  });

  test('sendCode exposes the backend demo code response', () async {
    final repository = createRepository((options) async {
      expect(options.path, '/auth/send_code');
      expect(options.queryParameters['phone_number'], '79990000000');
      return jsonResponse(200, {'verification_code': '000000'});
    });

    final response = await repository.sendCode(
      const SendCodeRequest('79990000000'),
    );

    expect(response.demoVerificationCode, '000000');
  });

  test('checkPhone maps backend account status codes', () async {
    Future<AccountStatus> check(int code) {
      final repository = createRepository((options) async {
        expect(options.path, '/auth/check_phone');
        return jsonResponse(400, {'code': code, 'detail': 'status'});
      });
      return repository.checkPhone('79990000000');
    }

    expect(await check(667), AccountStatus.newUser);
    expect(await check(612), AccountStatus.existingUser);
  });

  test('a new repository instance restores a persisted session', () async {
    await storage.saveTokens('persisted-access', 'persisted-refresh');
    storage = SessionStorage(backend: backend);
    final repository = createRepository((options) async {
      expect(options.headers['Authorization'], 'Bearer persisted-access');
      return jsonResponse(200, {'id': 42});
    });

    final user = await repository.restoreSession();

    expect(user?.id, 42);
  });

  test('logout removes the complete session', () async {
    await storage.saveTokens('access', 'refresh');
    final repository = createRepository((options) async {
      fail('logout must not perform an HTTP request');
    });

    await repository.logout();

    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
    expect(await storage.hasSession, isFalse);
  });

  test('restore refreshes an expired access token', () async {
    await storage.saveTokens('expired', 'valid-refresh');
    var refreshCount = 0;
    final repository = createRepository((options) async {
      if (options.path == '/auth/refresh_token') {
        refreshCount++;
        expect(options.queryParameters['refresh_token'], 'valid-refresh');
        return jsonResponse(200, {
          'access_token': 'fresh-access',
          'refresh_token': 'fresh-refresh',
        });
      }
      if (options.headers['Authorization'] == 'Bearer fresh-access') {
        return jsonResponse(200, {'id': 9});
      }
      return jsonResponse(401, {'detail': 'expired'});
    });

    final user = await repository.restoreSession();

    expect(user?.id, 9);
    expect(refreshCount, 1);
    expect(await storage.readAccessToken(), 'fresh-access');
  });

  test('invalid refresh ends the restored session', () async {
    await storage.saveTokens('expired', 'invalid-refresh');
    final repository = createRepository((options) async {
      return jsonResponse(401, {'detail': 'unauthorized'});
    });

    final user = await repository.restoreSession();

    expect(user, isNull);
    expect(await storage.hasSession, isFalse);
  });
}

typedef MockHandler = Future<ResponseBody> Function(RequestOptions options);

class MockHttpAdapter implements HttpClientAdapter {
  MockHttpAdapter(this._handler);

  final MockHandler _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => _handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int statusCode, Object body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

class MemorySecureStorage implements SecureStorageBackend {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
