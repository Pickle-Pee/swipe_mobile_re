import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_repository.dart';

void main() {
  test(
    'edit draft becomes dirty and failed save preserves entered values',
    () async {
      final repository = _ProfileRepository()..saveError = Exception('offline');
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(profileControllerProvider.notifier).load();
      await container
          .read(profileEditControllerProvider.notifier)
          .begin(repository.profile);

      container
          .read(profileEditControllerProvider.notifier)
          .updateAboutMe('Draft that must survive');
      final result = await container
          .read(profileEditControllerProvider.notifier)
          .save();

      final state = container.read(profileEditControllerProvider);
      expect(result, isNull);
      expect(state.isDirty, isTrue);
      expect(state.draft?.aboutMe, 'Draft that must survive');
      expect(state.error, isNotNull);
    },
  );

  test('double Save is guarded while the first request is in flight', () async {
    final repository = _ProfileRepository()
      ..saveCompleter = Completer<UserProfile>();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(profileControllerProvider.notifier).load();
    await container
        .read(profileEditControllerProvider.notifier)
        .begin(repository.profile);
    container
        .read(profileEditControllerProvider.notifier)
        .updateAboutMe('Updated once');

    final first = container.read(profileEditControllerProvider.notifier).save();
    final second = await container
        .read(profileEditControllerProvider.notifier)
        .save();
    expect(repository.saveCalls, 1);
    expect(second, isNull);

    repository.saveCompleter!.complete(
      repository.profile.copyWith(aboutMe: 'Updated once'),
    );
    final saved = await first;
    expect(saved?.aboutMe, 'Updated once');
    expect(container.read(profileEditControllerProvider).isDirty, isFalse);
  });

  test('photo upload error stays local and exposes retry', () async {
    final repository = _ProfileRepository()..uploadError = Exception('timeout');
    final container = _container(
      repository,
      picker: const _PhotoPicker(
        ProfilePhotoFile(name: 'photo.jpg', bytes: [0xFF, 0xD8, 0xFF]),
      ),
    );
    addTearDown(container.dispose);
    await container.read(profileControllerProvider.notifier).load();

    final uploaded = await container
        .read(profileControllerProvider.notifier)
        .pickAndUploadPhoto();
    final state = container.read(profileControllerProvider);

    expect(uploaded, isFalse);
    expect(state.status, ProfileStatus.data);
    expect(state.profile, isNotNull);
    expect(state.photoError, isNotNull);
    expect(state.canRetryPhotoUpload, isTrue);
  });

  test('picker cancel returns to idle without publishing an error', () async {
    final repository = _ProfileRepository();
    final container = _container(repository, picker: const _PhotoPicker(null));
    addTearDown(container.dispose);
    await container.read(profileControllerProvider.notifier).load();

    await container
        .read(profileControllerProvider.notifier)
        .pickAndUploadPhoto();

    final state = container.read(profileControllerProvider);
    expect(state.photoOperation, ProfilePhotoOperation.idle);
    expect(state.photoError, isNull);
    expect(repository.uploadCalls, 0);
  });
}

ProviderContainer _container(
  _ProfileRepository repository, {
  ProfilePhotoPicker? picker,
}) {
  return ProviderContainer(
    overrides: [
      profileRepositoryProvider.overrideWithValue(repository),
      if (picker != null) profilePhotoPickerProvider.overrideWithValue(picker),
    ],
  );
}

class _ProfileRepository implements ProfileRepository {
  UserProfile profile = _profile;
  Object? saveError;
  Object? uploadError;
  Completer<UserProfile>? saveCompleter;
  int saveCalls = 0;
  int uploadCalls = 0;

  @override
  Future<UserProfile> getCurrentProfile() async => profile;

  @override
  Future<ProfileEditCatalog> getEditCatalog() async => const ProfileEditCatalog(
    interests: [
      ProfileInterest(id: 1, label: 'Travel'),
      ProfileInterest(id: 2, label: 'Cinema'),
    ],
    attributes: {
      'what_looking_for': [
        ProfileAttributeOption(
          name: 'SERIOUS',
          description: 'Serious relationship',
        ),
      ],
    },
  );

  @override
  Future<UserProfile> saveProfile(ProfileSaveRequest request) async {
    saveCalls++;
    final error = saveError;
    if (error != null) throw error;
    final pending = saveCompleter;
    if (pending != null) return pending.future;
    profile = profile.copyWith(
      firstName: request.profile.firstName,
      dateOfBirth: request.profile.dateOfBirth,
      gender: request.profile.gender,
      city: request.profile.city,
      aboutMe: request.profile.aboutMe,
    );
    return profile;
  }

  @override
  Future<UserProfile> updateProfile(ProfileUpdate update) async => profile;

  @override
  Future<UserProfile> uploadPhoto(
    ProfilePhotoFile file, {
    bool isAvatar = false,
    void Function(int, int)? onProgress,
  }) async {
    uploadCalls++;
    onProgress?.call(1, 2);
    final error = uploadError;
    if (error != null) throw error;
    profile = profile.withPhotos([
      ...profile.photos,
      ProfilePhoto(id: 9, url: '/new.jpg', isAvatar: isAvatar),
    ]);
    return profile;
  }

  @override
  Future<UserProfile> deletePhoto(int photoId, {bool wasAvatar = false}) async {
    profile = profile.withPhotos(
      profile.photos.where((photo) => photo.id != photoId).toList(),
    );
    return profile;
  }

  @override
  Future<UserProfile> setAvatar(int photoId) async {
    profile = profile.withPhotos(
      profile.photos
          .map(
            (photo) => ProfilePhoto(
              id: photo.id,
              url: photo.url,
              isAvatar: photo.id == photoId,
            ),
          )
          .toList(),
    );
    return profile;
  }
}

class _PhotoPicker implements ProfilePhotoPicker {
  const _PhotoPicker(this.file);
  final ProfilePhotoFile? file;

  @override
  Future<ProfilePhotoFile?> pickFromGallery() async => file;
}

final _profile = UserProfile(
  id: 1,
  firstName: 'Mila',
  lastName: 'Stone',
  dateOfBirth: DateTime(1990, 1, 1),
  gender: 'female',
  city: 'Lisbon',
  aboutMe: 'Original introduction',
  status: '',
  isSubscription: false,
  attributes: ProfileAttributes(whatLookingFor: 'Serious relationship'),
  interests: [ProfileInterest(id: 1, label: 'Travel')],
  photos: [ProfilePhoto(id: 1, url: '/primary.jpg', isAvatar: true)],
);
