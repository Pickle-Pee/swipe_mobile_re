import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_repository.dart';
import 'package:swipe_mobile_re/features/profile/own_profile_preview_screen.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('preview reuses saved public profile without reaction actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(_PreviewRepository()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.midnight(),
          home: const OwnProfilePreviewScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('own-profile-preview')), findsOneWidget);
    expect(find.text('Public preview'), findsOneWidget);
    expect(
      find.text('This is how other people see your saved profile'),
      findsOneWidget,
    );
    expect(find.text('Mila Stone'), findsOneWidget);
    expect(find.byKey(const Key('public-profile-action-bar')), findsNothing);
    expect(find.byKey(const Key('public-profile-like')), findsNothing);
    expect(find.byKey(const Key('public-profile-pass')), findsNothing);
  });
}

class _PreviewRepository implements ProfileRepository {
  @override
  Future<UserProfile> getCurrentProfile() async => _profile;

  @override
  Future<ProfileEditCatalog> getEditCatalog() async =>
      const ProfileEditCatalog();

  @override
  Future<UserProfile> saveProfile(ProfileSaveRequest request) async => _profile;

  @override
  Future<UserProfile> updateProfile(ProfileUpdate update) async => _profile;

  @override
  Future<UserProfile> uploadPhoto(
    ProfilePhotoFile file, {
    bool isAvatar = false,
    void Function(int, int)? onProgress,
  }) async => _profile;

  @override
  Future<UserProfile> deletePhoto(
    int photoId, {
    bool wasAvatar = false,
  }) async => _profile;

  @override
  Future<UserProfile> setAvatar(int photoId) async => _profile;
}

const _profile = UserProfile(
  id: 1,
  firstName: 'Mila',
  lastName: 'Stone',
  dateOfBirth: null,
  gender: 'female',
  city: 'Lisbon',
  aboutMe: 'Saved introduction shown in public preview.',
  status: 'online',
  isSubscription: false,
  attributes: ProfileAttributes(whatLookingFor: 'Serious relationship'),
  interests: [ProfileInterest(id: 1, label: 'Travel')],
  photos: [],
);
