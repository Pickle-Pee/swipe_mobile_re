import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_providers.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_state.dart';
import 'package:swipe_mobile_re/features/auth/data/session_storage.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_models.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_preferences.dart';
import 'package:swipe_mobile_re/features/settings/application/discovery_preferences_providers.dart';
import 'package:swipe_mobile_re/features/settings/data/discovery_preferences_storage.dart';

void main() {
  group('DiscoveryPreferences', () {
    test('maps saved values to the backend query contract', () {
      const preferences = DiscoveryPreferences(
        minAge: 24,
        maxAge: 38,
        smokingAttitude: 'Non-smoker',
        whatLookingFor: 'Serious relationship',
      );

      expect(preferences.toQueryParameters(), {
        'minAge': 24,
        'maxAge': 38,
        'smokingAttitude': 'Non-smoker',
        'whatLookingFor': 'Serious relationship',
      });
      expect(DiscoveryPreferences.fromJson(preferences.toJson()), preferences);
    });

    test(
      'validates the real minimum and age ordering without a fake maximum',
      () {
        expect(
          const DiscoveryPreferencesDraft(
            minAge: '17',
            maxAge: '30',
          ).validationMessage,
          contains('at least 18'),
        );
        expect(
          const DiscoveryPreferencesDraft(
            minAge: '40',
            maxAge: '30',
          ).validationMessage,
          contains('must not be greater'),
        );
        expect(
          const DiscoveryPreferencesDraft(
            minAge: '25',
            maxAge: '250',
          ).validationMessage,
          isNull,
        );
        expect(
          const DiscoveryPreferencesDraft().validatedPreferences,
          DiscoveryPreferences.empty,
        );
      },
    );
  });

  test('secure storage round-trips per-user values and clears them', () async {
    final backend = _MemorySecureStorage();
    final storage = SecureDiscoveryPreferencesStorage(backend: backend);
    const preferences = DiscoveryPreferences(
      minAge: 22,
      maxAge: 34,
      religion: 'Spiritual',
    );

    await storage.write(7, preferences);

    expect(await storage.read(7), preferences);
    expect(await storage.read(8), DiscoveryPreferences.empty);

    await storage.clear(7);
    expect(await storage.read(7), DiscoveryPreferences.empty);
  });

  test('corrupt local preference data is removed instead of exposed', () async {
    final backend = _MemorySecureStorage()
      ..values['discovery_preferences_user_7'] = '{bad json';
    final storage = SecureDiscoveryPreferencesStorage(backend: backend);

    expect(await storage.read(7), DiscoveryPreferences.empty);
    expect(backend.values, isEmpty);
  });

  test(
    'controller serializes Save and publishes canonical values once',
    () async {
      final storage = _FakePreferencesStorage(
        saved: const DiscoveryPreferences(minAge: 20, maxAge: 30),
      );
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_AuthenticatedController.new),
          discoveryPreferencesStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        discoveryPreferencesControllerProvider.notifier,
      );
      await controller.ensureStoredPreferencesLoaded();
      controller.updateMinimumAge('24');
      controller.updateMaximumAge('36');

      final first = controller.save();
      final second = controller.save();

      expect(storage.writeCalls, 1);
      expect(
        container.read(discoveryPreferencesControllerProvider).isSaving,
        isTrue,
      );
      storage.writeCompleter.complete();
      expect(await Future.wait([first, second]), [true, true]);

      final state = container.read(discoveryPreferencesControllerProvider);
      expect(state.saved.minAge, 24);
      expect(state.saved.maxAge, 36);
      expect(state.isDirty, isFalse);
    },
  );

  test(
    'failed Save preserves the draft and previous canonical value',
    () async {
      final storage = _FakePreferencesStorage(
        saved: const DiscoveryPreferences(minAge: 20, maxAge: 30),
        writeError: Exception('offline'),
      );
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_AuthenticatedController.new),
          discoveryPreferencesStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        discoveryPreferencesControllerProvider.notifier,
      );
      await controller.ensureStoredPreferencesLoaded();
      controller.updateMinimumAge('25');
      controller.updateMaximumAge('35');

      expect(await controller.save(), isFalse);

      final state = container.read(discoveryPreferencesControllerProvider);
      expect(state.saved.minAge, 20);
      expect(state.draft.minAge, '25');
      expect(state.draft.maxAge, '35');
      expect(state.saveError, isNotNull);
      expect(state.isDirty, isTrue);
    },
  );
}

class _AuthenticatedController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(AuthUser(id: 7));
}

class _MemorySecureStorage implements SecureStorageBackend {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _FakePreferencesStorage implements DiscoveryPreferencesStorage {
  _FakePreferencesStorage({required this.saved, this.writeError});

  final DiscoveryPreferences saved;
  final Object? writeError;
  final writeCompleter = Completer<void>();
  int writeCalls = 0;

  @override
  Future<void> clear(int userId) async {}

  @override
  Future<DiscoveryPreferences> read(int userId) async => saved;

  @override
  Future<void> write(int userId, DiscoveryPreferences preferences) {
    writeCalls++;
    final error = writeError;
    if (error != null) return Future<void>.error(error);
    return writeCompleter.future;
  }
}
