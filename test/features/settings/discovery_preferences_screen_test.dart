import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_providers.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_state.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_models.dart';
import 'package:swipe_mobile_re/features/discovery/application/discovery_providers.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_models.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_preferences.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_repository.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_repository.dart';
import 'package:swipe_mobile_re/features/settings/application/discovery_preferences_providers.dart';
import 'package:swipe_mobile_re/features/settings/data/discovery_preferences_storage.dart';
import 'package:swipe_mobile_re/features/settings/discovery_preferences_screen.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('loads persisted values and keeps unchanged Save disabled', (
    tester,
  ) async {
    final storage = _PreferencesStorage(
      saved: const DiscoveryPreferences(
        minAge: 23,
        maxAge: 37,
        whatLookingFor: 'Serious relationship',
      ),
    );
    await _pump(tester, storage: storage);

    final minimum = tester.widget<TextField>(_ageInput('minimum-age-field'));
    final maximum = tester.widget<TextField>(_ageInput('maximum-age-field'));
    expect(minimum.controller!.text, '23');
    expect(maximum.controller!.text, '37');
    expect(find.text('Serious relationship'), findsOneWidget);

    final save = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byKey(const Key('save-discovery-preferences')),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('Save persists canonical filters and refreshes Discovery once', (
    tester,
  ) async {
    final storage = _PreferencesStorage();
    final discovery = _DiscoveryRepository();
    await _pump(tester, storage: storage, discovery: discovery);

    await tester.enterText(_ageInput('minimum-age-field'), '24');
    await tester.enterText(_ageInput('maximum-age-field'), '36');
    await tester.ensureVisible(find.text('Serious relationship'));
    await tester.tap(find.text('Serious relationship'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-discovery-preferences')));
    await tester.pumpAndSettle();

    expect(storage.writeCalls, 1);
    expect(storage.written, isNotNull);
    expect(storage.written!.minAge, 24);
    expect(storage.written!.maxAge, 36);
    expect(storage.written!.whatLookingFor, 'Serious relationship');
    expect(discovery.loadCalls, 1);
    expect(discovery.received.single, storage.written);
    expect(
      find.text('Preferences saved and Discovery refreshed.'),
      findsOneWidget,
    );
  });

  testWidgets('invalid age order keeps Save disabled and explains the error', (
    tester,
  ) async {
    await _pump(tester, storage: _PreferencesStorage());

    await tester.enterText(_ageInput('minimum-age-field'), '40');
    await tester.enterText(_ageInput('maximum-age-field'), '30');
    await tester.pump();

    expect(
      find.text('Minimum age must not be greater than maximum age.'),
      findsOneWidget,
    );
    final save = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byKey(const Key('save-discovery-preferences')),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('Back keeps or discards a real unsaved draft deliberately', (
    tester,
  ) async {
    await _pump(tester, storage: _PreferencesStorage());
    await tester.enterText(_ageInput('minimum-age-field'), '25');
    await tester.enterText(_ageInput('maximum-age-field'), '35');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('unsaved-preferences-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('keep-editing-preferences')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('discovery-preferences-list')), findsOneWidget);
    expect(
      tester.widget<TextField>(_ageInput('minimum-age-field')).controller!.text,
      '25',
    );
  });
}

Finder _ageInput(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

Future<void> _pump(
  WidgetTester tester, {
  required _PreferencesStorage storage,
  _DiscoveryRepository? discovery,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_AuthenticatedController.new),
        discoveryPreferencesStorageProvider.overrideWithValue(storage),
        profileRepositoryProvider.overrideWithValue(_CatalogRepository()),
        discoveryRepositoryProvider.overrideWithValue(
          discovery ?? _DiscoveryRepository(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.midnight(),
        home: const DiscoveryPreferencesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _AuthenticatedController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(AuthUser(id: 7));
}

class _PreferencesStorage implements DiscoveryPreferencesStorage {
  _PreferencesStorage({this.saved = DiscoveryPreferences.empty});

  final DiscoveryPreferences saved;
  DiscoveryPreferences? written;
  int writeCalls = 0;

  @override
  Future<void> clear(int userId) async {}

  @override
  Future<DiscoveryPreferences> read(int userId) async => saved;

  @override
  Future<void> write(int userId, DiscoveryPreferences preferences) async {
    writeCalls++;
    written = preferences;
  }
}

class _DiscoveryRepository implements DiscoveryRepository {
  final received = <DiscoveryPreferences>[];
  int loadCalls = 0;

  @override
  Future<List<DiscoveryProfile>> getProfiles(
    DiscoveryPreferences preferences,
  ) async {
    loadCalls++;
    received.add(preferences);
    return const [];
  }

  @override
  Future<DiscoveryReactionResult> react(
    int profileId,
    DiscoveryReaction reaction,
  ) async => const DiscoveryReactionResult(isMatch: false);
}

class _CatalogRepository implements ProfileRepository {
  static const profile = UserProfile(
    id: 7,
    firstName: 'Mila',
    lastName: 'Stone',
    dateOfBirth: null,
    city: 'Demo City',
    aboutMe: '',
    status: '',
    isSubscription: false,
    interests: [],
    photos: [],
  );

  @override
  Future<ProfileEditCatalog> getEditCatalog() async => const ProfileEditCatalog(
    attributes: {
      'what_looking_for': [
        ProfileAttributeOption(
          name: 'SERIOUS_RELATIONSHIP',
          description: 'Serious relationship',
        ),
        ProfileAttributeOption(name: 'NEW_FRIENDS', description: 'New friends'),
      ],
    },
  );

  @override
  Future<UserProfile> getCurrentProfile() async => profile;

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
