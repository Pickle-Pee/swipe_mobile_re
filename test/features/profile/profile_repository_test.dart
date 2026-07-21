import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/core/network/api_client.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_repository.dart';

void main() {
  late MockHttpAdapter adapter;
  late DioProfileRepository repository;

  setUp(() {
    adapter = MockHttpAdapter((options) async {
      if (options.path == '/user/me') {
        return jsonResponse(200, {
          'id': 1,
          'first_name': 'Ada',
          'last_name': 'Lovelace',
          'date_of_birth': '1990-12-10',
          'city_name': 'Demo City',
          'about_me': 'Profile from API',
          'status': 'online',
          'is_subscription': true,
          'interests': [
            {'interest_id': 2, 'interest_text': 'Books'},
          ],
        });
      }
      if (options.path == '/user/user/photos') {
        return jsonResponse(200, {
          'photos': [
            {'id': 4, 'photo_url': '/photo.jpg', 'is_avatar': true},
          ],
        });
      }
      return jsonResponse(201, {});
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    repository = DioProfileRepository(
      ApiClient(dio: dio, tokenStore: EmptyTokenStore(), logSink: (_) {}),
    );
  });

  test('loads profile and photos without hardcoded values', () async {
    final profile = await repository.getCurrentProfile();

    expect(profile.firstName, 'Ada');
    expect(profile.city, 'Demo City');
    expect(profile.aboutMe, 'Profile from API');
    expect(profile.interests.single.label, 'Books');
    expect(profile.photos.single.isAvatar, isTrue);
  });

  test('update sends editable fields and reloads profile', () async {
    await repository.updateProfile(
      const ProfileUpdate(
        firstName: 'Grace',
        city: 'Another City',
        aboutMe: 'Updated',
      ),
    );

    final update = adapter.requests.singleWhere(
      (request) => request.path == '/user/update_user',
    );
    expect(update.method, 'PUT');
    expect(update.data, containsPair('about_me', 'Updated'));
  });

  test('unsupported image is rejected before an HTTP request', () async {
    final requestsBefore = adapter.requests.length;

    await expectLater(
      repository.uploadPhoto(
        const ProfilePhotoFile(name: 'profile.txt', bytes: [1, 2, 3]),
      ),
      throwsA(isA<InvalidProfilePhotoException>()),
    );

    expect(adapter.requests.length, requestsBefore);
  });

  test('renamed non-image file is rejected by its signature', () async {
    await expectLater(
      repository.uploadPhoto(
        const ProfilePhotoFile(name: 'profile.jpg', bytes: [1, 2, 3, 4]),
      ),
      throwsA(isA<InvalidProfilePhotoException>()),
    );
  });
}

typedef MockHandler = Future<ResponseBody> Function(RequestOptions options);

class MockHttpAdapter implements HttpClientAdapter {
  MockHttpAdapter(this._handler);
  final MockHandler _handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
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
