import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/core/network/api_client.dart';
import 'package:swipe_mobile_re/features/profile/domain/public_profile_repository.dart';

void main() {
  test(
    'loads real public details and ordered photos from existing endpoints',
    () async {
      final adapter = _MockHttpAdapter((options) async {
        if (options.path == '/user/9') {
          return _jsonResponse(200, {
            'id': 9,
            'first_name': 'Mila',
            'last_name': 'Stone',
            'date_of_birth': '1995-04-12',
            'gender': 'female',
            'city_name': 'Lisbon',
            'about_me': 'Real profile copy',
            'avatar_url': '/avatar.jpg',
            'interests': [
              {'interest_id': 1, 'interest_text': 'Travel'},
            ],
            'attributes': {
              'height': 170,
              'what_looking_for': 'long_term_relationship',
            },
          });
        }
        expect(options.path, '/user/user/photos/9');
        return _jsonResponse(200, {
          'photos': [
            {'id': 2, 'photo_url': '/second.jpg', 'is_avatar': false},
            {'id': 1, 'photo_url': '/avatar.jpg', 'is_avatar': true},
          ],
        });
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter;
      final repository = DioPublicProfileRepository(
        ApiClient(dio: dio, tokenStore: _EmptyTokenStore(), logSink: (_) {}),
      );

      final profile = await repository.getProfile(9);

      expect(profile.displayName, 'Mila Stone');
      expect(profile.heroPhoto?.id, 1);
      expect(profile.photos.map((photo) => photo.id), [2, 1]);
      expect(profile.interests.single.label, 'Travel');
      expect(profile.facts['Height'], '170 cm');
      expect(profile.facts['Looking for'], 'Long Term Relationship');
      expect(adapter.paths, ['/user/9', '/user/user/photos/9']);
    },
  );
}

typedef _MockHandler = Future<ResponseBody> Function(RequestOptions options);

class _MockHttpAdapter implements HttpClientAdapter {
  _MockHttpAdapter(this._handler);

  final _MockHandler _handler;
  final List<String> paths = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    paths.add(options.path);
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(int statusCode, Object body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

class _EmptyTokenStore implements ApiTokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {}
}
