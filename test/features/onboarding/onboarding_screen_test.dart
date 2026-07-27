import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/onboarding/onboarding_screen.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_repository.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('screen resumes at the first missing canonical step', (
    tester,
  ) async {
    await _pumpOnboarding(tester, _ScreenRepository());
    await tester.pump();
    await tester.pump();

    expect(find.text('What brings you here?'), findsOneWidget);
    expect(find.text('2 of 5'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-goal')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-about')), findsOneWidget);
  });

  testWidgets('setup layout supports 1.3 text scale on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(_ScreenRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.midnight(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(1.3),
            ),
            child: const OnboardingScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('interests continue renders the optional photos step', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 914);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpOnboarding(tester, _InterestsRepository());
    await tester.pump();
    await tester.pump();

    expect(find.text('Choose your interests'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('edit-interest-1')));
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Add your best photos'), findsOneWidget);
    expect(find.byKey(const Key('profile-photo-manager')), findsOneWidget);
    expect(find.byKey(const Key('add-profile-photo')), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpOnboarding(
  WidgetTester tester,
  ProfileRepository repository,
) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.midnight(),
        home: const OnboardingScreen(),
      ),
    ),
  );
}

class _ScreenRepository implements ProfileRepository {
  final profile = UserProfile(
    id: 3,
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

  @override
  Future<UserProfile> getCurrentProfile() async => profile;

  @override
  Future<ProfileEditCatalog> getEditCatalog() async => const ProfileEditCatalog(
    interests: [ProfileInterest(id: 1, label: 'Cinema')],
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

class _InterestsRepository extends _ScreenRepository {
  @override
  final profile = UserProfile(
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
    interests: const [],
    photos: const [],
  );

  @override
  Future<UserProfile> saveProfile(ProfileSaveRequest request) async =>
      UserProfile(
        id: profile.id,
        firstName: profile.firstName,
        lastName: profile.lastName,
        dateOfBirth: profile.dateOfBirth,
        gender: profile.gender,
        city: profile.city,
        aboutMe: profile.aboutMe,
        status: profile.status,
        isSubscription: profile.isSubscription,
        attributes: profile.attributes,
        interests: const [ProfileInterest(id: 1, label: 'Cinema')],
        photos: const [],
      );
}
