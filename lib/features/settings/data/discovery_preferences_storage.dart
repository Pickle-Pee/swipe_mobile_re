import 'dart:convert';

import '../../auth/data/session_storage.dart';
import '../../discovery/domain/discovery_preferences.dart';

abstract interface class DiscoveryPreferencesStorage {
  Future<DiscoveryPreferences> read(int userId);
  Future<void> write(int userId, DiscoveryPreferences preferences);
  Future<void> clear(int userId);
}

class SecureDiscoveryPreferencesStorage implements DiscoveryPreferencesStorage {
  SecureDiscoveryPreferencesStorage({SecureStorageBackend? backend})
    : _backend = backend ?? const FlutterSecureStorageBackend();

  static const _keyPrefix = 'discovery_preferences_user_';

  final SecureStorageBackend _backend;

  @override
  Future<DiscoveryPreferences> read(int userId) async {
    final raw = await _backend.read(_key(userId));
    if (raw == null || raw.trim().isEmpty) return DiscoveryPreferences.empty;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Preferences payload must be an object');
      }
      return DiscoveryPreferences.fromJson(decoded);
    } on FormatException {
      await clear(userId);
      return DiscoveryPreferences.empty;
    }
  }

  @override
  Future<void> write(int userId, DiscoveryPreferences preferences) {
    return _backend.write(_key(userId), jsonEncode(preferences.toJson()));
  }

  @override
  Future<void> clear(int userId) => _backend.delete(_key(userId));

  String _key(int userId) => '$_keyPrefix$userId';
}
