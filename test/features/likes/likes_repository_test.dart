import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/core/network/api_client.dart';
import 'package:swipe_mobile_re/features/likes/domain/likes_repository.dart';

void main() {
  test('loads all lists and deduplicates mutual matches by user id', () async {
    final adapter = MockHttpAdapter((options) async {
      if (options.path == '/likes/favorites') {
        return jsonResponse(200, [userJson(3)]);
      }
      if (options.path == '/likes/liked_me') {
        return jsonResponse(200, [userJson(1, mutual: true)]);
      }
      return jsonResponse(200, [userJson(1, mutual: true), userJson(2)]);
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    final repository = DioLikesRepository(
      ApiClient(dio: dio, tokenStore: EmptyTokenStore(), logSink: (_) {}),
    );

    final data = await repository.getLikes();

    expect(data.likedMe.map((user) => user.id), [1]);
    expect(data.likedUsers.map((user) => user.id), [1, 2]);
    expect(data.favorites.map((user) => user.id), [3]);
    expect(data.mutual.map((user) => user.id), [1]);
  });
}

Map<String, dynamic> userJson(int id, {bool mutual = false}) => {
  'id': id,
  'first_name': 'User $id',
  'date_of_birth': '1990-01-01',
  'mutual': mutual,
};

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

ResponseBody jsonResponse(int statusCode, Object body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

class EmptyTokenStore implements ApiTokenStore {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<String?> readRefreshToken() async => null;
  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {}
}
