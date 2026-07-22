import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/presentation/own_profile_components.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  test('maps picker permission failures to a user-facing message', () {
    expect(
      profileErrorMessage(
        PlatformException(code: 'photo_access_denied_permanently'),
      ),
      contains('system settings'),
    );
  });

  testWidgets('renders deterministic loading and initial error states', (
    tester,
  ) async {
    await _pump(tester, const ProfileState(status: ProfileStatus.loading));
    expect(find.byKey(const Key('own-profile-loading')), findsOneWidget);

    await _pump(
      tester,
      ProfileState(status: ProfileStatus.error, error: Exception('offline')),
    );
    expect(find.byKey(const Key('own-profile-error')), findsOneWidget);
    expect(find.text('Could not load your profile'), findsOneWidget);
  });

  testWidgets('complete own profile shows real management content only', (
    tester,
  ) async {
    await _pump(
      tester,
      const ProfileState(status: ProfileStatus.data, profile: _complete),
      premium: true,
    );

    expect(find.textContaining('Mila Stone'), findsOneWidget);
    expect(find.text('Profile complete'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Premium active'), findsOneWidget);
    expect(find.text('online'), findsNothing);
    expect(find.textContaining('popularity'), findsNothing);
    expect(find.text('Like'), findsNothing);
    expect(find.text('Pass'), findsNothing);
  });

  testWidgets('incomplete profile exposes one concrete next edit action', (
    tester,
  ) async {
    ProfileCompletionStep? selected;
    await _pump(
      tester,
      const ProfileState(status: ProfileStatus.data, profile: _incomplete),
      onEditStep: (step) => selected = step,
    );

    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Add a primary photo'), findsWidgets);
    await tester.tap(find.byKey(const Key('profile-completeness-action')));
    expect(selected, ProfileCompletionStep.primaryPhoto);
  });

  testWidgets('top bar and management actions expose callbacks', (
    tester,
  ) async {
    var edits = 0;
    var previews = 0;
    var settings = 0;
    await _pump(
      tester,
      const ProfileState(status: ProfileStatus.data, profile: _complete),
      onEdit: () => edits++,
      onPreview: () => previews++,
      onSettings: () => settings++,
    );

    await tester.tap(find.byKey(const Key('own-profile-edit-action')));
    await tester.tap(find.byKey(const Key('own-profile-preview-action')));
    await tester.tap(find.byKey(const Key('own-profile-settings-action')));
    expect(edits, 1);
    expect(previews, 1);
    expect(settings, 1);
  });

  testWidgets('long content fits compact screen at text scale 1.3', (
    tester,
  ) async {
    await _pump(
      tester,
      const ProfileState(status: ProfileStatus.data, profile: _long),
      size: const Size(320, 568),
      textScale: 1.3,
    );

    expect(find.byKey(const Key('own-profile-hero')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  ProfileState state, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool? premium,
  VoidCallback? onEdit,
  VoidCallback? onPreview,
  VoidCallback? onSettings,
  ValueChanged<ProfileCompletionStep>? onEditStep,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.midnight(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: 1,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: OwnProfileView(
          state: state,
          hasPremiumAccess: premium,
          onRefresh: () async {},
          onRetry: () {},
          onEdit: onEdit ?? () {},
          onPreview: onPreview ?? () {},
          onSettings: onSettings ?? () {},
          onSubscription: () {},
          onEditStep: onEditStep ?? (_) {},
          imageProviderBuilder: (_) => null,
        ),
      ),
    ),
  );
  await tester.pump();
}

const _complete = UserProfile(
  id: 1,
  firstName: 'Mila',
  lastName: 'Stone',
  dateOfBirth: null,
  gender: 'female',
  city: 'Lisbon',
  aboutMe: 'Weekend walks, tiny galleries, and good coffee.',
  status: 'online',
  isSubscription: true,
  attributes: ProfileAttributes(
    height: 174,
    whatLookingFor: 'Serious relationship',
  ),
  interests: [ProfileInterest(id: 1, label: 'Travel')],
  photos: [ProfilePhoto(id: 1, url: 'memory://primary', isAvatar: true)],
);

const _incomplete = UserProfile(
  id: 2,
  firstName: 'Noor',
  lastName: '',
  dateOfBirth: null,
  city: 'Helsinki',
  aboutMe: '',
  status: '',
  isSubscription: false,
  interests: [ProfileInterest(id: 2, label: 'Design')],
  photos: [],
);

const _long = UserProfile(
  id: 3,
  firstName: 'Alexandria Catherine with an exceptionally long name',
  lastName: 'Montgomery-Wellington',
  dateOfBirth: null,
  gender: 'non-binary',
  city: 'A very long city name that remains readable on compact screens',
  aboutMe:
      'A deliberately long saved description used to verify wrapping and '
      'scrolling on compact screens at larger text scale.',
  status: '',
  isSubscription: false,
  attributes: ProfileAttributes(whatLookingFor: 'New friends'),
  interests: [
    ProfileInterest(id: 1, label: 'Contemporary architecture'),
    ProfileInterest(id: 2, label: 'Independent cinema'),
    ProfileInterest(id: 3, label: 'Long-distance cycling'),
    ProfileInterest(id: 4, label: 'Experimental cooking'),
  ],
  photos: [],
);
