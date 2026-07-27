import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/application/public_profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/presentation/edit_profile_components.dart';
import 'package:swipe_mobile_re/features/profile/presentation/own_profile_components.dart';
import 'package:swipe_mobile_re/features/profile/public_profile_screen.dart';
import 'package:swipe_mobile_re/shared/theme/tokens.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';
import 'package:swipe_mobile_re/shared/ui/liquid_ui.dart';

// DES-08 is the full redesign verification pass, so these baselines are active.
const _baselineDeferred = false;

void main() {
  testWidgets('Own Profile complete golden', (tester) async {
    await _pumpOwn(
      tester,
      const ProfileState(status: ProfileStatus.data, profile: _complete),
    );
    await expectLater(
      find.byKey(const Key('own-profile-golden-surface')),
      matchesGoldenFile('goldens/own_profile_complete.png'),
    );
  }, skip: _baselineDeferred);

  testWidgets('Own Profile incomplete golden', (tester) async {
    await _pumpOwn(
      tester,
      const ProfileState(status: ProfileStatus.data, profile: _incomplete),
    );
    await expectLater(
      find.byKey(const Key('own-profile-golden-surface')),
      matchesGoldenFile('goldens/own_profile_incomplete.png'),
    );
  }, skip: _baselineDeferred);

  testWidgets('Own Profile loading golden', (tester) async {
    await _pumpOwn(tester, const ProfileState(status: ProfileStatus.loading));
    await expectLater(
      find.byKey(const Key('own-profile-golden-surface')),
      matchesGoldenFile('goldens/own_profile_loading.png'),
    );
  }, skip: _baselineDeferred);

  testWidgets('Own Profile error golden', (tester) async {
    await _pumpOwn(
      tester,
      ProfileState(status: ProfileStatus.error, error: Exception('offline')),
    );
    await expectLater(
      find.byKey(const Key('own-profile-golden-surface')),
      matchesGoldenFile('goldens/own_profile_error.png'),
    );
  }, skip: _baselineDeferred);

  testWidgets('Edit Profile saving golden', (tester) async {
    await _pumpSurface(
      tester,
      Scaffold(
        backgroundColor: AppTokens.backgroundBase,
        body: AppGradientScaffold(
          safeArea: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space16,
                  104,
                  AppTokens.space16,
                  132,
                ),
                children: const [
                  EditProfileSection(
                    title: 'About you',
                    subtitle: 'Saved multiline profile introduction.',
                    icon: Icons.notes_rounded,
                    child: TextField(
                      maxLines: 4,
                      decoration: InputDecoration(labelText: 'Introduction'),
                    ),
                  ),
                ],
              ),
              const Positioned(
                left: AppTokens.space12,
                right: AppTokens.space12,
                bottom: AppTokens.space8,
                child: ProfileSaveBar(
                  dirty: true,
                  valid: true,
                  saving: true,
                  onSave: null,
                ),
              ),
            ],
          ),
        ),
      ),
      goldenKey: const Key('edit-profile-golden-surface'),
    );
    await expectLater(
      find.byKey(const Key('edit-profile-golden-surface')),
      matchesGoldenFile('goldens/edit_profile_saving.png'),
    );
  }, skip: _baselineDeferred);

  testWidgets('Own Profile Preview golden', (tester) async {
    await _pumpSurface(
      tester,
      PublicProfileView(
        state: PublicProfileState(
          status: PublicProfileStatus.data,
          profile: _complete.toPublicProfile(),
        ),
        title: 'Public preview',
        onBack: _noop,
        onRetry: _noop,
        enableHero: false,
        showActions: false,
        imageProviderBuilder: (_) => null,
      ),
      goldenKey: const Key('own-profile-preview-golden-surface'),
    );
    await expectLater(
      find.byKey(const Key('own-profile-preview-golden-surface')),
      matchesGoldenFile('goldens/own_profile_preview.png'),
    );
  }, skip: _baselineDeferred);
}

Future<void> _pumpOwn(WidgetTester tester, ProfileState state) async {
  await _pumpSurface(
    tester,
    OwnProfileView(
      state: state,
      onRefresh: () async {},
      onRetry: _noop,
      onEdit: _noop,
      onPreview: _noop,
      onSettings: _noop,
      onSubscription: _noop,
      onEditStep: (_) {},
      imageProviderBuilder: (_) => null,
    ),
    goldenKey: const Key('own-profile-golden-surface'),
  );
}

Future<void> _pumpSurface(
  WidgetTester tester,
  Widget child, {
  required Key goldenKey,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.midnight(),
      home: RepaintBoundary(key: goldenKey, child: child),
    ),
  );
  await tester.pump();
}

void _noop() {}

const _complete = UserProfile(
  id: 1,
  firstName: 'Mila',
  lastName: 'Stone',
  dateOfBirth: null,
  gender: 'female',
  city: 'Lisbon',
  aboutMe: 'Weekend walks, tiny galleries, and good coffee.',
  status: '',
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
  gender: '',
  city: '',
  aboutMe: '',
  status: '',
  isSubscription: false,
  interests: [],
  photos: [],
);
