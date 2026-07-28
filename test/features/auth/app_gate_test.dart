import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/app/router/app_gate.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_providers.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_models.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_repository.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_repository.dart';

void main() {
  test(
    'no session resolves to signed-out gate without a private flash',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_GateAuthRepository()),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(appGateProvider).status,
        AppGateStatus.checkingSession,
      );

      await container.read(authControllerProvider.notifier).restoreSession();

      expect(container.read(appGateProvider).status, AppGateStatus.signedOut);
    },
  );

  test('authenticated complete profile resolves to the main gate', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _GateAuthRepository(user: const AuthUser(id: 4)),
        ),
        profileRepositoryProvider.overrideWithValue(
          _GateProfileRepository(_completeProfile),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).restoreSession();
    container.read(appGateProvider);
    await container.read(profileControllerProvider.notifier).load();

    expect(container.read(appGateProvider).status, AppGateStatus.ready);
  });

  test('authenticated incomplete profile resolves to onboarding', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _GateAuthRepository(user: const AuthUser(id: 4)),
        ),
        profileRepositoryProvider.overrideWithValue(
          _GateProfileRepository(
            _completeProfile.copyWith(
              attributes: const ProfileAttributes(),
              interests: const [],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).restoreSession();
    container.read(appGateProvider);
    await container.read(profileControllerProvider.notifier).load();

    expect(
      container.read(appGateProvider).status,
      AppGateStatus.onboardingRequired,
    );
  });
}

class _GateAuthRepository implements AuthRepository {
  _GateAuthRepository({this.user});

  final AuthUser? user;

  @override
  Future<AuthUser?> restoreSession() async => user;

  @override
  Future<void> checkCode(CheckCodeRequest request) async {}

  @override
  Future<AccountStatus> checkPhone(String phoneNumber) async =>
      AccountStatus.existingUser;

  @override
  Future<AuthUser> login(LoginRequest request) async => user!;

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUser> refreshSession() async => user!;

  @override
  Future<AuthUser> register(RegisterRequest request) async => user!;

  @override
  Future<SendCodeResponse> sendCode(SendCodeRequest request) async =>
      const SendCodeResponse();

  @override
  Future<AuthUser> whoAmI() async => user!;
}

class _GateProfileRepository implements ProfileRepository {
  const _GateProfileRepository(this.profile);

  final UserProfile profile;

  @override
  Future<UserProfile> getCurrentProfile() async => profile;

  @override
  Future<ProfileEditCatalog> getEditCatalog() async =>
      const ProfileEditCatalog();

  @override
  Future<UserProfile> saveProfile(ProfileSaveRequest request) async => profile;

  @override
  Future<UserProfile> updateProfile(ProfileUpdate update) async => profile;

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

final _completeProfile = UserProfile(
  id: 4,
  firstName: 'Mila',
  lastName: 'Stone',
  dateOfBirth: DateTime(1994, 5, 4),
  gender: 'female',
  city: 'Lisbon',
  aboutMe: '',
  status: '',
  isSubscription: false,
  attributes: const ProfileAttributes(whatLookingFor: 'Serious relationship'),
  interests: const [ProfileInterest(id: 1, label: 'Cinema')],
  photos: const [],
);
