import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/core/network/api_client.dart';
import 'package:swipe_mobile_re/features/settings/domain/settings_models.dart';
import 'package:swipe_mobile_re/features/settings/domain/settings_repository.dart';

void main() {
  test(
    'delete account uses the existing authenticated DELETE endpoint',
    () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter;
      final repository = DioSettingsRepository(
        ApiClient(dio: dio, tokenStore: _TokenStore(), logSink: (_) {}),
      );

      await repository.deleteAccount();

      expect(adapter.method, 'DELETE');
      expect(adapter.path, '/user/delete_user');
    },
  );

  test('package information rejects missing platform metadata', () {
    expect(
      () => AppPackageInfo.fromPlatform({
        'appName': 'Swipe',
        'version': '',
        'buildNumber': '1',
      }),
      throwsFormatException,
    );
  });
}

class _Adapter implements HttpClientAdapter {
  String? method;
  String? path;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    path = options.path;
    return ResponseBody.fromString(
      jsonEncode({'status': 'success', 'message': 'Profile deleted'}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _TokenStore implements ApiTokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => 'access';

  @override
  Future<String?> readRefreshToken() async => 'refresh';

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {}
}
