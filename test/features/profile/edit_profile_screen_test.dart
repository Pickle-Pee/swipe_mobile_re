import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_repository.dart';
import 'package:swipe_mobile_re/features/profile/edit_profile_screen.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('form starts from canonical values and saves explicit draft', (
    tester,
  ) async {
    final repository = _EditRepository();
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(profileControllerProvider.notifier).load();

    await _pump(tester, container);

    final firstName = tester.widget<TextField>(
      find.byKey(const Key('edit-first-name')),
    );
    expect(firstName.controller?.text, 'Mila');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('edit-about')))
          .controller
          ?.text,
      'Original introduction',
    );

    await tester.enterText(
      find.byKey(const Key('edit-about')),
      'Updated saved introduction',
    );
    await tester.pump();
    expect(container.read(profileEditControllerProvider).isDirty, isTrue);

    await tester.tap(find.byKey(const Key('edit-profile-save')));
    await tester.pump();
    await tester.pump();

    expect(repository.saveCalls, 1);
    expect(repository.profile.aboutMe, 'Updated saved introduction');
    expect(container.read(profileEditControllerProvider).isDirty, isFalse);
    expect(find.text('Profile saved'), findsOneWidget);
  });

  testWidgets('dirty Back offers keep editing and discard choices', (
    tester,
  ) async {
    final repository = _EditRepository();
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(profileControllerProvider.notifier).load();
    await _pump(tester, container);

    await tester.enterText(find.byKey(const Key('edit-city')), 'Porto');
    await tester.pump();
    await tester.tap(find.byKey(const Key('edit-profile-back')));
    await tester.pump();
    expect(find.byKey(const Key('unsaved-profile-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('keep-editing-profile')));
    await tester.pump();
    expect(find.byKey(const Key('unsaved-profile-dialog')), findsNothing);
    expect(container.read(profileEditControllerProvider).draft?.city, 'Porto');

    await tester.tap(find.byKey(const Key('edit-profile-back')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('discard-profile-changes')));
    await tester.pump();

    expect(container.read(profileEditControllerProvider).isDirty, isFalse);
    expect(container.read(profileEditControllerProvider).draft?.city, 'Lisbon');
  });

  testWidgets('photo deletion requires explicit confirmation', (tester) async {
    final repository = _EditRepository();
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(profileControllerProvider.notifier).load();
    await _pump(tester, container);

    final delete = find.byKey(const ValueKey<String>('delete-photo-2'));
    final editScrollable = find
        .descendant(
          of: find.byKey(const Key('edit-profile-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(delete, 500, scrollable: editScrollable);
    await tester.pumpAndSettle();
    await tester.tap(delete);
    await tester.pump();
    expect(
      find.byKey(const Key('delete-profile-photo-dialog')),
      findsOneWidget,
    );
    expect(repository.deleteCalls, 0);

    await tester.tap(find.byKey(const Key('confirm-delete-profile-photo')));
    await tester.pump();
    await tester.pump();
    expect(repository.deleteCalls, 1);
  });
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final router = GoRouter(
    initialLocation: '/profile/edit',
    routes: [
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfileScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.midnight(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

class _EditRepository implements ProfileRepository {
  UserProfile profile = UserProfile(
    id: 1,
    firstName: 'Mila',
    lastName: 'Stone',
    dateOfBirth: DateTime(1990, 1, 1),
    gender: 'female',
    city: 'Lisbon',
    aboutMe: 'Original introduction',
    status: '',
    isSubscription: false,
    attributes: const ProfileAttributes(
      height: 170,
      whatLookingFor: 'Serious relationship',
    ),
    interests: const [ProfileInterest(id: 1, label: 'Travel')],
    photos: const [
      ProfilePhoto(id: 1, url: '', isAvatar: true),
      ProfilePhoto(id: 2, url: '', isAvatar: false),
    ],
  );
  int saveCalls = 0;
  int deleteCalls = 0;

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
  }) async => profile;

  @override
  Future<UserProfile> deletePhoto(int photoId, {bool wasAvatar = false}) async {
    deleteCalls++;
    profile = profile.withPhotos(
      profile.photos.where((photo) => photo.id != photoId).toList(),
    );
    return profile;
  }

  @override
  Future<UserProfile> setAvatar(int photoId) async => profile;
}
