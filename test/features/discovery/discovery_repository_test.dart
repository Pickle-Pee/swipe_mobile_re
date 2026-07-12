import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/core/network/api_client.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_models.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_repository.dart';

void main() {
  late MockHttpAdapter adapter;
  late DioDiscoveryRepository repository;

  setUp(() {
    adapter = MockHttpAdapter((options) async {
      if (options.path == '/match/find_matches') {
        return jsonResponse(200, [
          {
            'user_id': 12,
            'first_name': 'Backend name',
            'date_of_birth': '1995-02-10',
          },
        ]);
      }
      if (options.path == '/user/12') {
        return jsonResponse(200, {
          'id': 12,
          'first_name': 'Real profile',
          'date_of_birth': '1995-02-10',
          'city_name': 'Demo City',
          'about_me': 'From database',
          'avatar_url': '/avatar.jpg',
          'interests': [
            {'interest_id': 1, 'interest_text': 'Travel'},
          ],
          'attributes': {'height': 170},
        });
      }
      return jsonResponse(200, {'message': 'Liked'});
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    repository = DioDiscoveryRepository(
      ApiClient(dio: dio, tokenStore: EmptyTokenStore(), logSink: (_) {}),
    );
  });

  test('loads match ids then enriches cards from user API', () async {
    final profiles = await repository.getProfiles();

    expect(profiles.single.firstName, 'Real profile');
    expect(profiles.single.aboutMe, 'From database');
    expect(profiles.single.interests.single.label, 'Travel');
    expect(profiles.single.attributes['Height'], '170');
  });

  test('like and pass use server endpoints', () async {
    await repository.react(12, DiscoveryReaction.like);
    await repository.react(13, DiscoveryReaction.pass);

    expect(adapter.paths, contains('/likes/like/12'));
    expect(adapter.paths, contains('/likes/dislike/13'));
  });
}

typedef MockHandler = Future<ResponseBody> Function(RequestOptions options);

class MockHttpAdapter implements HttpClientAdapter {
  MockHttpAdapter(this._handler);
  final MockHandler _handler;
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
