import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/core/network/api_client.dart';
import 'package:swipe_mobile_re/core/network/api_exception.dart';

void main() {
  late MemoryTokenStore tokenStore;
  late MockHttpAdapter adapter;
  late List<String> logs;

  ApiClient createClient(MockHandler handler) {
    adapter = MockHttpAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    return ApiClient(
      dio: dio,
      tokenStore: tokenStore,
      logSink: logs.add,
    );
  }

  setUp(() {
    tokenStore = MemoryTokenStore(
      accessToken: 'access-secret',
      refreshToken: 'refresh-secret',
    );
    logs = [];
  });

  test(
    'successful request includes the access token without logging it',
    () async {
      final client = createClient((options, requestNumber) async {
        expect(options.headers['Authorization'], 'Bearer access-secret');
        return jsonResponse(200, {'ok': true});
      });

      final response = await client.get<Map<String, dynamic>>('/resource');

      expect(response.data, {'ok': true});
      expect(adapter.requestCount, 1);
      expect(logs.join(), isNot(contains('access-secret')));
      expect(logs.join(), isNot(contains('refresh-secret')));
    },
  );

  test('401 refreshes tokens and retries the original request once', () async {
    final client = createClient((options, requestNumber) async {
      if (options.path == '/auth/refresh_token') {
        expect(options.queryParameters['refresh_token'], 'refresh-secret');
        return jsonResponse(200, {
          'access_token': 'new-access',
          'refresh_token': 'new-refresh',
        });
      }
      if (options.headers['Authorization'] == 'Bearer new-access') {
        return jsonResponse(200, {'retried': true});
      }
      return jsonResponse(401, {'detail': 'expired'});
    });

    final response = await client.get<Map<String, dynamic>>('/protected');

    expect(response.data, {'retried': true});
    expect(adapter.requestCount, 3);
    expect(tokenStore.accessToken, 'new-access');
    expect(tokenStore.refreshToken, 'new-refresh');
    expect(tokenStore.clearCount, 0);
  });

  test('failed refresh clears the session and returns unauthorized', () async {
    final client = createClient((options, requestNumber) async {
      if (options.path == '/auth/refresh_token') {
        return jsonResponse(401, {'detail': 'invalid refresh'});
      }
      return jsonResponse(401, {'detail': 'expired'});
    });

    await expectLater(
      client.get<void>('/protected'),
      throwsA(
        isA<UnauthorizedApiException>().having(
          (error) => error.type,
          'type',
          ApiExceptionType.unauthorized,
        ),
      ),
    );
    expect(adapter.requestCount, 2);
    expect(tokenStore.clearCount, 1);
    expect(tokenStore.accessToken, isNull);
    expect(tokenStore.refreshToken, isNull);
  });

  test('a retried request cannot start an infinite refresh loop', () async {
    final client = createClient((options, requestNumber) async {
      if (options.path == '/auth/refresh_token') {
        return jsonResponse(200, {
          'access_token': 'still-invalid',
          'refresh_token': 'new-refresh',
        });
      }
      return jsonResponse(401, {'detail': 'unauthorized'});
    });

    await expectLater(
      client.get<void>('/protected'),
      throwsA(isA<ApiException>()),
    );

    expect(adapter.requestCount, 3);
    expect(tokenStore.clearCount, 1);
  });

  test('simultaneous 401 responses share one refresh request', () async {
    final releaseRefresh = Completer<void>();
    var refreshCount = 0;
    final client = createClient((options, requestNumber) async {
      if (options.path == '/auth/refresh_token') {
        refreshCount++;
        await releaseRefresh.future;
        return jsonResponse(200, {
          'access_token': 'new-access',
          'refresh_token': 'new-refresh',
        });
      }
      if (options.headers['Authorization'] == 'Bearer new-access') {
        return jsonResponse(200, {'ok': true});
      }
      return jsonResponse(401, {'detail': 'expired'});
    });

    final requests = [client.get('/one'), client.get('/two')];
    await Future<void>.delayed(Duration.zero);
    releaseRefresh.complete();
    await Future.wait(requests);

    expect(refreshCount, 1);
    expect(adapter.requestCount, 5);
  });

  test('response failures use the documented exception classes', () async {
    Future<void> expectStatus<T extends ApiException>(int statusCode) async {
      final client = createClient((options, requestNumber) async {
        return jsonResponse(statusCode, {'detail': 'failure'});
      });
      await expectLater(client.get('/failure'), throwsA(isA<T>()));
    }

    await expectStatus<ValidationApiException>(422);
    await expectStatus<ServerApiException>(500);
    await expectStatus<UnknownApiException>(404);
  });

  test('connection failures use NetworkApiException', () async {
    final client = createClient((options, requestNumber) async {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    });

    await expectLater(
      client.get('/failure'),
      throwsA(isA<NetworkApiException>()),
    );
  });
}

typedef MockHandler = Future<ResponseBody> Function(
  RequestOptions options,
  int requestNumber,
);

class MockHttpAdapter implements HttpClientAdapter {
  MockHttpAdapter(this._handler);

  final MockHandler _handler;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requestCount++;
    return _handler(options, requestCount);
  }

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

class MemoryTokenStore implements ApiTokenStore {
  MemoryTokenStore({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount++;
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}
