import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/onboarding/application/onboarding_providers.dart';
import 'package:swipe_mobile_re/features/onboarding/domain/onboarding_models.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_repository.dart';

void main() {
  test('registration profile continues through real canonical setup', () async {
    final repository = OnboardingRepository();
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(onboardingControllerProvider.notifier);

    await controller.start();
    expect(
      container.read(onboardingControllerProvider).step,
      OnboardingStep.preferences,
    );

    controller.updateWhatLookingFor('Serious relationship');
    controller.updateAboutMe('Small galleries and long walks.');
    expect(await controller.continueStep(), isTrue);
    expect(
      container.read(onboardingControllerProvider).step,
      OnboardingStep.interests,
    );

    controller.toggleInterest(2);
    expect(await controller.continueStep(), isTrue);
    expect(
      container.read(onboardingControllerProvider).step,
      OnboardingStep.photos,
    );

    expect(await controller.continueStep(), isTrue);
    expect(
      container.read(onboardingControllerProvider).step,
      OnboardingStep.review,
    );
    expect(await controller.continueStep(), isTrue);

    final state = container.read(onboardingControllerProvider);
    expect(state.active, isFalse);
    expect(OnboardingReadiness.fromProfile(state.profile!).isComplete, isTrue);
    expect(repository.saveCalls, 2);
  });

  test('resume skips already completed steps', () async {
    final repository = OnboardingRepository(
      profile: OnboardingRepository.baseProfile.copyWith(
        attributes: const ProfileAttributes(
          whatLookingFor: 'Serious relationship',
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(onboardingControllerProvider.notifier).start();

    expect(
      container.read(onboardingControllerProvider).step,
      OnboardingStep.interests,
    );
  });

  test('double Continue performs one save and retains the draft', () async {
    final repository = DelayedOnboardingRepository();
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(onboardingControllerProvider.notifier);
    await controller.start();
    controller.updateWhatLookingFor('Serious relationship');

    final first = controller.continueStep();
    final second = controller.continueStep();
    expect(await second, isFalse);
    expect(repository.saveCalls, 1);
    expect(
      container.read(onboardingControllerProvider).draft?.whatLookingFor,
      'Serious relationship',
    );

    repository.saveCompleter.complete(
      repository.profile.copyWith(
        attributes: const ProfileAttributes(
          whatLookingFor: 'Serious relationship',
        ),
      ),
    );
    expect(await first, isTrue);
  });
}

class OnboardingRepository implements ProfileRepository {
  OnboardingRepository({UserProfile? profile})
    : profile = profile ?? baseProfile;

  static final baseProfile = UserProfile(
    id: 4,
    firstName: 'Mila',
    lastName: 'Stone',
    dateOfBirth: DateTime(1994, 5, 4),
    gender: 'female',
    city: 'Lisbon',
    aboutMe: '',
    status: '',
    isSubscription: false,
    interests: const [],
    photos: const [],
  );

  UserProfile profile;
  int saveCalls = 0;

  static const catalog = ProfileEditCatalog(
    interests: [
      ProfileInterest(id: 1, label: 'Travel'),
      ProfileInterest(id: 2, label: 'Cinema'),
    ],
    attributes: {
      'what_looking_for': [
        ProfileAttributeOption(
          name: 'SERIOUS_RELATIONSHIP',
          description: 'Serious relationship',
        ),
      ],
    },
  );

  @override
  Future<UserProfile> getCurrentProfile() async => profile;

  @override
  Future<ProfileEditCatalog> getEditCatalog() async => catalog;

  @override
  Future<UserProfile> saveProfile(ProfileSaveRequest request) async {
    saveCalls++;
    profile = _apply(request);
    return profile;
  }

  UserProfile _apply(ProfileSaveRequest request) {
    var attributes = profile.attributes;
    for (final entry in request.attributeValues.entries) {
      attributes = attributes.copyWithValue(entry.key, entry.value);
    }
    final selected = request.interestIds;
    return profile.copyWith(
      aboutMe: request.profile.aboutMe,
      attributes: attributes,
      interests: selected == null
          ? null
          : catalog.interests
                .where((interest) => selected.contains(interest.id))
                .toList(growable: false),
    );
  }

  @override
  Future<UserProfile> updateProfile(ProfileUpdate update) async {
    profile = profile.copyWith(
      firstName: update.firstName,
      dateOfBirth: update.dateOfBirth,
      gender: update.gender,
      city: update.city,
      aboutMe: update.aboutMe,
    );
    return profile;
  }

  @override
  Future<UserProfile> uploadPhoto(
    ProfilePhotoFile file, {
    bool isAvatar = false,
    void Function(int, int)? onProgress,
  }) async => profile;

  @override
  Future<UserProfile> deletePhoto(
    int photoId, {
    bool wasAvatar = false,
  }) async => profile;

  @override
  Future<UserProfile> setAvatar(int photoId) async => profile;
}

class DelayedOnboardingRepository extends OnboardingRepository {
  final saveCompleter = Completer<UserProfile>();

  @override
  Future<UserProfile> saveProfile(ProfileSaveRequest request) {
    saveCalls++;
    return saveCompleter.future.then((value) {
      profile = value;
      return value;
    });
  }
}
