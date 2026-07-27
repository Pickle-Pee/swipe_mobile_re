import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/app/router/app_gate.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_providers.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_state.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_models.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_repository.dart';
import 'package:swipe_mobile_re/features/onboarding/application/onboarding_providers.dart';
import 'package:swipe_mobile_re/features/onboarding/domain/onboarding_models.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_repository.dart';

void main() {
  test(
    'fresh registration completes canonical setup and unlocks Discovery',
    () async {
      final authRepository = _FlowAuthRepository();
      final profileRepository = _FlowProfileRepository(_basicProfile());
      final container = _flowContainer(authRepository, profileRepository);
      addTearDown(container.dispose);
      final auth = container.read(authControllerProvider.notifier);

      final response = await auth.sendCode(
        const SendCodeRequest('79990000000'),
      );
      expect(response.demoVerificationCode, '123456');
      await auth.checkCode(
        const CheckCodeRequest(
          phoneNumber: '79990000000',
          verificationCode: '123456',
        ),
      );
      expect(
        await auth.register(
          const RegisterRequest(
            phoneNumber: '79990000000',
            firstName: 'Mila',
            lastName: 'Stone',
            dateOfBirth: '1994-05-04',
            gender: 'female',
            cityName: 'Lisbon',
          ),
        ),
        isTrue,
      );

      await container.read(profileControllerProvider.notifier).load();
      expect(
        container.read(appGateProvider).status,
        AppGateStatus.onboardingRequired,
      );

      final onboarding = container.read(onboardingControllerProvider.notifier);
      await onboarding.start();
      expect(
        container.read(onboardingControllerProvider).step,
        OnboardingStep.preferences,
      );

      onboarding.updateWhatLookingFor('Serious relationship');
      onboarding.updateAboutMe('Small galleries and long walks.');
      expect(await onboarding.continueStep(), isTrue);
      onboarding.toggleInterest(2);
      expect(await onboarding.continueStep(), isTrue);
      expect(
        container.read(onboardingControllerProvider).step,
        OnboardingStep.photos,
      );

      expect(
        await container
            .read(profileControllerProvider.notifier)
            .pickAndUploadPhoto(),
        isTrue,
      );
      onboarding.syncProfile(
        container.read(profileControllerProvider).profile!,
      );
      expect(await onboarding.continueStep(), isTrue);
      expect(await onboarding.continueStep(), isTrue);

      expect(profileRepository.profile.photos, hasLength(1));
      expect(container.read(appGateProvider).status, AppGateStatus.ready);
    },
  );

  test('login, logout, and login again keep the gate canonical', () async {
    final authRepository = _FlowAuthRepository();
    final profileRepository = _FlowProfileRepository(_completeProfile());
    final container = _flowContainer(authRepository, profileRepository);
    addTearDown(container.dispose);
    final auth = container.read(authControllerProvider.notifier);

    await auth.restoreSession();
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(container.read(appGateProvider).status, AppGateStatus.signedOut);

    expect(
      await auth.login(
        const LoginRequest(phoneNumber: '79990000000', code: '123456'),
      ),
      isTrue,
    );
    await container.read(profileControllerProvider.notifier).load();
    expect(container.read(appGateProvider).status, AppGateStatus.ready);

    await auth.logout();
    expect(container.read(appGateProvider).status, AppGateStatus.signedOut);

    expect(
      await auth.login(
        const LoginRequest(phoneNumber: '79990000000', code: '123456'),
      ),
      isTrue,
    );
    await container.read(profileControllerProvider.notifier).load();

    expect(authRepository.loginCalls, 2);
    expect(container.read(appGateProvider).status, AppGateStatus.ready);
  });

  test('restart resumes the first incomplete canonical step', () async {
    final authRepository = _FlowAuthRepository();
    final profileRepository = _FlowProfileRepository(_basicProfile());
    final firstRun = _flowContainer(authRepository, profileRepository);
    final firstAuth = firstRun.read(authControllerProvider.notifier);

    expect(
      await firstAuth.register(
        const RegisterRequest(
          phoneNumber: '79990000000',
          firstName: 'Mila',
          lastName: 'Stone',
          dateOfBirth: '1994-05-04',
          gender: 'female',
          cityName: 'Lisbon',
        ),
      ),
      isTrue,
    );
    await firstRun.read(profileControllerProvider.notifier).load();
    final firstOnboarding = firstRun.read(
      onboardingControllerProvider.notifier,
    );
    await firstOnboarding.start();
    firstOnboarding.updateWhatLookingFor('Serious relationship');
    expect(await firstOnboarding.continueStep(), isTrue);
    expect(
      firstRun.read(onboardingControllerProvider).step,
      OnboardingStep.interests,
    );
    firstRun.dispose();

    final restarted = _flowContainer(authRepository, profileRepository);
    addTearDown(restarted.dispose);
    await restarted.read(authControllerProvider.notifier).restoreSession();
    await restarted.read(profileControllerProvider.notifier).load();
    expect(
      restarted.read(appGateProvider).status,
      AppGateStatus.onboardingRequired,
    );

    final resumed = restarted.read(onboardingControllerProvider.notifier);
    await resumed.start();
    expect(
      restarted.read(onboardingControllerProvider).step,
      OnboardingStep.interests,
    );
    resumed.toggleInterest(2);
    expect(await resumed.continueStep(), isTrue);
    expect(await resumed.continueStep(), isTrue);
    expect(await resumed.continueStep(), isTrue);

    expect(restarted.read(appGateProvider).status, AppGateStatus.ready);
  });
}

ProviderContainer _flowContainer(
  AuthRepository authRepository,
  ProfileRepository profileRepository,
) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepository),
      profileRepositoryProvider.overrideWithValue(profileRepository),
      profilePhotoPickerProvider.overrideWithValue(const _FlowPhotoPicker()),
    ],
  );
}

class _FlowAuthRepository implements AuthRepository {
  bool hasSession = false;
  int loginCalls = 0;

  static const user = AuthUser(
    id: 21,
    phoneNumber: '79990000000',
    firstName: 'Mila',
    lastName: 'Stone',
  );

  @override
  Future<SendCodeResponse> sendCode(SendCodeRequest request) async {
    expect(request.phoneNumber, '79990000000');
    return const SendCodeResponse(demoVerificationCode: '123456');
  }

  @override
  Future<void> checkCode(CheckCodeRequest request) async {
    expect(request.verificationCode, '123456');
  }

  @override
  Future<AccountStatus> checkPhone(String phoneNumber) async =>
      AccountStatus.newUser;

  @override
  Future<AuthUser> login(LoginRequest request) async {
    loginCalls++;
    hasSession = true;
    return user;
  }

  @override
  Future<AuthUser> register(RegisterRequest request) async {
    hasSession = true;
    return user;
  }

  @override
  Future<AuthUser?> restoreSession() async => hasSession ? user : null;

  @override
  Future<AuthUser> refreshSession() async => user;

  @override
  Future<AuthUser> whoAmI() async => user;

  @override
  Future<void> logout() async {
    hasSession = false;
  }
}

class _FlowPhotoPicker implements ProfilePhotoPicker {
  const _FlowPhotoPicker();

  @override
  Future<ProfilePhotoFile?> pickFromGallery() async {
    return const ProfilePhotoFile(
      name: 'profile.png',
      bytes: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    );
  }
}

class _FlowProfileRepository implements ProfileRepository {
  _FlowProfileRepository(this.profile);

  UserProfile profile;

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
  Future<UserProfile> saveProfile(ProfileSaveRequest request) async {
    var attributes = profile.attributes;
    for (final entry in request.attributeValues.entries) {
      attributes = attributes.copyWithValue(entry.key, entry.value);
    }
    final interestIds = request.interestIds;
    profile = profile.copyWith(
      firstName: request.profile.firstName,
      dateOfBirth: request.profile.dateOfBirth,
      gender: request.profile.gender,
      city: request.profile.city,
      aboutMe: request.profile.aboutMe,
      attributes: attributes,
      interests: interestIds == null
          ? null
          : catalog.interests
                .where((interest) => interestIds.contains(interest.id))
                .toList(growable: false),
    );
    return profile;
  }

  @override
  Future<UserProfile> uploadPhoto(
    ProfilePhotoFile file, {
    bool isAvatar = false,
    void Function(int, int)? onProgress,
  }) async {
    onProgress?.call(file.bytes.length, file.bytes.length);
    profile = profile.copyWith(
      photos: [
        ProfilePhoto(
          id: 501,
          url: 'https://example.test/profile.png',
          isAvatar: isAvatar,
        ),
      ],
    );
    return profile;
  }

  @override
  Future<UserProfile> deletePhoto(int photoId, {bool wasAvatar = false}) async {
    profile = profile.copyWith(
      photos: profile.photos
          .where((photo) => photo.id != photoId)
          .toList(growable: false),
    );
    return profile;
  }

  @override
  Future<UserProfile> setAvatar(int photoId) async {
    profile = profile.copyWith(
      photos: profile.photos
          .map(
            (photo) => ProfilePhoto(
              id: photo.id,
              url: photo.url,
              isAvatar: photo.id == photoId,
            ),
          )
          .toList(growable: false),
    );
    return profile;
  }
}

UserProfile _basicProfile() {
  return UserProfile(
    id: 21,
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
}

UserProfile _completeProfile() {
  return _basicProfile().copyWith(
    attributes: const ProfileAttributes(whatLookingFor: 'Serious relationship'),
    interests: const [ProfileInterest(id: 2, label: 'Cinema')],
  );
}
