import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/app/router/app_router.dart';
import 'package:swipe_mobile_re/app/router/routes.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_providers.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_models.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_repository.dart';
import 'package:swipe_mobile_re/features/discovery/application/discovery_providers.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_models.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_preferences.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_repository.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_repository.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('signed-out deep route is replaced by Welcome', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_SignedOutRepository()),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.midnight(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Meet people\nat your pace.'), findsOneWidget);

    router.go(Routes.profile);
    await tester.pump();
    expect(router.state.uri.path, Routes.welcome);
    expect(find.text('Meet people\nat your pace.'), findsOneWidget);

    router.go(Routes.deleteAccount);
    await tester.pump();
    expect(router.state.uri.path, Routes.welcome);
  });

  testWidgets('ready gate replaces bootstrap after profile restore', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_ReadyAuthRepository()),
        profileRepositoryProvider.overrideWithValue(_ReadyProfileRepository()),
        discoveryRepositoryProvider.overrideWithValue(
          _EmptyDiscoveryRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.midnight(),
          routerConfig: router,
        ),
      ),
    );
    await container.read(authControllerProvider.notifier).restoreSession();
    await container.read(profileControllerProvider.notifier).load();
    await tester.pump();
    await tester.pump();

    expect(router.state.uri.path, Routes.discover);
    expect(find.text('Discovery'), findsOneWidget);
  });
}

class _SignedOutRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<void> checkCode(CheckCodeRequest request) async {}

  @override
  Future<AccountStatus> checkPhone(String phoneNumber) async =>
      AccountStatus.newUser;

  @override
  Future<AuthUser> login(LoginRequest request) async => const AuthUser(id: 1);

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUser> refreshSession() async => const AuthUser(id: 1);

  @override
  Future<AuthUser> register(RegisterRequest request) async =>
      const AuthUser(id: 1);

  @override
  Future<SendCodeResponse> sendCode(SendCodeRequest request) async =>
      const SendCodeResponse();

  @override
  Future<AuthUser> whoAmI() async => const AuthUser(id: 1);
}

class _ReadyAuthRepository extends _SignedOutRepository {
  @override
  Future<AuthUser?> restoreSession() async => const AuthUser(id: 2);
}

class _ReadyProfileRepository implements ProfileRepository {
  static final profile = UserProfile(
    id: 2,
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

  @override
  Future<UserProfile> getCurrentProfile() async => profile;

  @override
  Future<ProfileEditCatalog> getEditCatalog() async =>
      const ProfileEditCatalog();

  @override
  Future<UserProfile> updateProfile(ProfileUpdate update) async => profile;

  @override
  Future<UserProfile> saveProfile(ProfileSaveRequest request) async => profile;

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

class _EmptyDiscoveryRepository implements DiscoveryRepository {
  @override
  Future<List<DiscoveryProfile>> getProfiles(
    DiscoveryPreferences preferences,
  ) async => const [];

  @override
  Future<DiscoveryReactionResult> react(
    int profileId,
    DiscoveryReaction reaction,
  ) async => const DiscoveryReactionResult(isMatch: false);
}
