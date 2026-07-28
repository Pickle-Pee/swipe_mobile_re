import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_repository.dart';

void main() {
  test(
    'edit, interests, photo, Save, and public preview share canonical state',
    () async {
      final repository = _FlowRepository();
      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(repository),
          profilePhotoPickerProvider.overrideWithValue(const _FlowPicker()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(profileControllerProvider.notifier).load();
      await container
          .read(profileEditControllerProvider.notifier)
          .begin(repository.profile);
      final edit = container.read(profileEditControllerProvider.notifier);
      edit.updateAboutMe('Updated through the integrated flow');
      edit.toggleInterest(2);

      await container
          .read(profileControllerProvider.notifier)
          .pickAndUploadPhoto();
      final saved = await edit.save();
      final current = container.read(profileControllerProvider).profile;
      final preview = current?.toPublicProfile();

      expect(saved, isNotNull);
      expect(current?.aboutMe, 'Updated through the integrated flow');
      expect(current?.interests.map((item) => item.id), containsAll([1, 2]));
      expect(current?.photos.single.isAvatar, isTrue);
      expect(preview?.aboutMe, current?.aboutMe);
      expect(preview?.interests, current?.interests);
    },
  );

  test(
    'discard restores canonical draft without mutating current profile',
    () async {
      final repository = _FlowRepository();
      final container = ProviderContainer(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(profileControllerProvider.notifier).load();
      await container
          .read(profileEditControllerProvider.notifier)
          .begin(repository.profile);
      final edit = container.read(profileEditControllerProvider.notifier);
      edit.updateCity('Unsaved city');

      edit.discard();

      expect(container.read(profileEditControllerProvider).isDirty, isFalse);
      expect(
        container.read(profileEditControllerProvider).draft?.city,
        'Lisbon',
      );
      expect(container.read(profileControllerProvider).profile?.city, 'Lisbon');
    },
  );
}

class _FlowRepository implements ProfileRepository {
  UserProfile profile = UserProfile(
    id: 1,
    firstName: 'Mila',
    lastName: 'Stone',
    dateOfBirth: DateTime(1990, 1, 1),
    gender: 'female',
    city: 'Lisbon',
    aboutMe: 'Original',
    status: '',
    isSubscription: false,
    attributes: const ProfileAttributes(whatLookingFor: 'Serious relationship'),
    interests: const [ProfileInterest(id: 1, label: 'Travel')],
    photos: const [],
  );

  static const catalog = ProfileEditCatalog(
    interests: [
      ProfileInterest(id: 1, label: 'Travel'),
      ProfileInterest(id: 2, label: 'Cinema'),
    ],
  );

  @override
  Future<UserProfile> getCurrentProfile() async => profile;

  @override
  Future<ProfileEditCatalog> getEditCatalog() async => catalog;

  @override
  Future<UserProfile> saveProfile(ProfileSaveRequest request) async {
    final selected = request.interestIds;
    profile = profile.copyWith(
      firstName: request.profile.firstName,
      dateOfBirth: request.profile.dateOfBirth,
      gender: request.profile.gender,
      city: request.profile.city,
      aboutMe: request.profile.aboutMe,
      interests: selected == null
          ? null
          : catalog.interests
                .where((interest) => selected.contains(interest.id))
                .toList(),
    );
    return profile;
  }

  @override
  Future<UserProfile> uploadPhoto(
    ProfilePhotoFile file, {
    bool isAvatar = false,
    void Function(int, int)? onProgress,
  }) async {
    profile = profile.withPhotos([
      ProfilePhoto(id: 5, url: '/flow.jpg', isAvatar: isAvatar),
    ]);
    return profile;
  }

  @override
  Future<UserProfile> deletePhoto(
    int photoId, {
    bool wasAvatar = false,
  }) async => profile;

  @override
  Future<UserProfile> setAvatar(int photoId) async => profile;

  @override
  Future<UserProfile> updateProfile(ProfileUpdate update) async => profile;
}

class _FlowPicker implements ProfilePhotoPicker {
  const _FlowPicker();

  @override
  Future<ProfilePhotoFile?> pickFromGallery() async =>
      const ProfilePhotoFile(name: 'flow.jpg', bytes: [0xFF, 0xD8, 0xFF]);
}
