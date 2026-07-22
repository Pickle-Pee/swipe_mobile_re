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
  late String currentAbout;
  late List<int> currentInterestIds;
  String? currentLookingFor;

  setUp(() {
    currentAbout = 'Profile from API';
    currentInterestIds = [2];
    currentLookingFor = null;
    adapter = MockHttpAdapter((options) async {
      if (options.path == '/user/me') {
        return jsonResponse(200, {
          'id': 1,
          'first_name': 'Ada',
          'last_name': 'Lovelace',
          'date_of_birth': '1990-12-10',
          'city_name': 'Demo City',
          'about_me': currentAbout,
          'status': 'online',
          'is_subscription': true,
          'interests': currentInterestIds
              .map(
                (id) => {
                  'interest_id': id,
                  'interest_text': id == 2 ? 'Books' : 'Architecture',
                },
              )
              .toList(),
          'attributes': {
            if (currentLookingFor != null)
              'what_looking_for': currentLookingFor,
          },
        });
      }
      if (options.path == '/user/user/photos') {
        return jsonResponse(200, {
          'photos': [
            {'id': 4, 'photo_url': '/photo.jpg', 'is_avatar': true},
          ],
        });
      }
      if (options.path == '/interest/interests_list') {
        return jsonResponse(200, {
          'interests': [
            {'id': 9, 'interest_text': 'Architecture'},
          ],
        });
      }
      if (options.path == '/attributes/') {
        return jsonResponse(200, {
          'what_looking_for': [
            {'name': 'SERIOUS', 'description': 'Serious relationship'},
          ],
        });
      }
      if (options.path == '/user/update_user') {
        final data = options.data as Map<String, dynamic>;
        currentAbout = data['about_me'] as String? ?? currentAbout;
        return jsonResponse(201, {});
      }
      if (options.path == '/interest/add_interests') {
        final data = options.data as Map<String, dynamic>;
        currentInterestIds = List<int>.from(
          data['interest_ids'] as List<dynamic>,
        );
        return jsonResponse(201, {});
      }
      if (options.path == '/attributes/add_attributes') {
        final data = options.data as Map<String, dynamic>;
        currentLookingFor = data['what_looking_for'] as String?;
        return jsonResponse(201, {});
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

  test('loads interests and enum descriptions from backend catalogs', () async {
    final catalog = await repository.getEditCatalog();

    expect(catalog.interests.single.label, 'Architecture');
    expect(
      catalog.optionsFor('what_looking_for').single.description,
      'Serious relationship',
    );
  });

  test(
    'save sends only requested logical sections before canonical reload',
    () async {
      await repository.saveProfile(
        const ProfileSaveRequest(
          profile: ProfileUpdate(aboutMe: 'Saved biography'),
          interestIds: [2, 9],
          attributeValues: {'what_looking_for': 'Serious relationship'},
        ),
      );

      final paths = adapter.requests.map((request) => request.path).toList();
      expect(
        paths,
        containsAllInOrder([
          '/user/update_user',
          '/interest/add_interests',
          '/attributes/add_attributes',
          '/user/me',
          '/user/user/photos',
        ]),
      );
      final interests = adapter.requests.singleWhere(
        (request) => request.path == '/interest/add_interests',
      );
      expect(interests.data, {
        'interest_ids': [2, 9],
      });
    },
  );

  test(
    'save verifies that the canonical server value actually changed',
    () async {
      await expectLater(
        repository.saveProfile(
          const ProfileSaveRequest(
            profile: ProfileUpdate(city: 'Unknown City'),
          ),
        ),
        throwsA(
          isA<PartialProfileSaveException>().having(
            (error) => error.canonicalProfile?.city,
            'canonical city',
            'Demo City',
          ),
        ),
      );
    },
  );

  test('deleting avatar promotes first canonical remaining photo', () async {
    var deleted = false;
    var primaryUpdated = false;
    final deleteAdapter = MockHttpAdapter((options) async {
      if (options.path == '/user/photos/4') {
        deleted = true;
        return jsonResponse(204, {});
      }
      if (options.path == '/user/set_avatar/5') {
        primaryUpdated = true;
        return jsonResponse(200, {});
      }
      if (options.path == '/user/me') {
        return jsonResponse(200, {
          'id': 1,
          'first_name': 'Ada',
          'last_name': '',
          'date_of_birth': '1990-12-10',
          'gender': 'female',
          'city_name': 'Demo City',
          'about_me': '',
          'status': '',
          'is_subscription': false,
          'interests': <Object>[],
        });
      }
      if (options.path == '/user/user/photos') {
        return jsonResponse(200, {
          'photos': deleted
              ? [
                  {
                    'id': 5,
                    'photo_url': '/remaining.jpg',
                    'is_avatar': primaryUpdated,
                  },
                ]
              : [
                  {'id': 4, 'photo_url': '/avatar.jpg', 'is_avatar': true},
                  {'id': 5, 'photo_url': '/remaining.jpg', 'is_avatar': false},
                ],
        });
      }
      return jsonResponse(200, {});
    });
    final deleteDio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = deleteAdapter;
    final deleteRepository = DioProfileRepository(
      ApiClient(dio: deleteDio, tokenStore: EmptyTokenStore(), logSink: (_) {}),
    );

    final profile = await deleteRepository.deletePhoto(4, wasAvatar: true);

    expect(primaryUpdated, isTrue);
    expect(profile.photos.single.isAvatar, isTrue);
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
