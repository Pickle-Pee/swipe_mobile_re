import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../discovery/domain/discovery_preferences.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/domain/profile_models.dart';
import '../data/discovery_preferences_storage.dart';

enum PreferencesLoadStatus { initial, loading, ready, error }

enum PreferencesCatalogStatus { initial, loading, ready, error }

class DiscoveryPreferencesState {
  const DiscoveryPreferencesState({
    this.userId,
    this.loadStatus = PreferencesLoadStatus.initial,
    this.catalogStatus = PreferencesCatalogStatus.initial,
    this.saved = DiscoveryPreferences.empty,
    this.draft = const DiscoveryPreferencesDraft(),
    this.catalog = const ProfileEditCatalog(),
    this.isSaving = false,
    this.loadError,
    this.catalogError,
    this.saveError,
  });

  final int? userId;
  final PreferencesLoadStatus loadStatus;
  final PreferencesCatalogStatus catalogStatus;
  final DiscoveryPreferences saved;
  final DiscoveryPreferencesDraft draft;
  final ProfileEditCatalog catalog;
  final bool isSaving;
  final Object? loadError;
  final Object? catalogError;
  final Object? saveError;

  bool get isDirty => draft != DiscoveryPreferencesDraft.fromPreferences(saved);
  String? get validationMessage => draft.validationMessage;
  bool get canSave =>
      loadStatus == PreferencesLoadStatus.ready &&
      isDirty &&
      validationMessage == null &&
      !isSaving;

  DiscoveryPreferencesState copyWith({
    PreferencesLoadStatus? loadStatus,
    PreferencesCatalogStatus? catalogStatus,
    DiscoveryPreferences? saved,
    DiscoveryPreferencesDraft? draft,
    ProfileEditCatalog? catalog,
    bool? isSaving,
    Object? loadError,
    bool clearLoadError = false,
    Object? catalogError,
    bool clearCatalogError = false,
    Object? saveError,
    bool clearSaveError = false,
  }) => DiscoveryPreferencesState(
    userId: userId,
    loadStatus: loadStatus ?? this.loadStatus,
    catalogStatus: catalogStatus ?? this.catalogStatus,
    saved: saved ?? this.saved,
    draft: draft ?? this.draft,
    catalog: catalog ?? this.catalog,
    isSaving: isSaving ?? this.isSaving,
    loadError: clearLoadError ? null : loadError ?? this.loadError,
    catalogError: clearCatalogError ? null : catalogError ?? this.catalogError,
    saveError: clearSaveError ? null : saveError ?? this.saveError,
  );
}

final discoveryPreferencesStorageProvider =
    Provider<DiscoveryPreferencesStorage>((ref) {
      return SecureDiscoveryPreferencesStorage();
    });

final discoveryPreferencesControllerProvider =
    NotifierProvider<DiscoveryPreferencesController, DiscoveryPreferencesState>(
      DiscoveryPreferencesController.new,
    );

class DiscoveryPreferencesController
    extends Notifier<DiscoveryPreferencesState> {
  Future<void>? _preferencesLoad;
  Future<void>? _catalogLoad;
  Future<bool>? _saveFuture;

  DiscoveryPreferencesStorage get _storage =>
      ref.read(discoveryPreferencesStorageProvider);

  @override
  DiscoveryPreferencesState build() {
    _preferencesLoad = null;
    _catalogLoad = null;
    _saveFuture = null;
    final userId = ref.watch(
      authControllerProvider.select((auth) => auth.user?.id),
    );
    return DiscoveryPreferencesState(userId: userId);
  }

  Future<void> ensureLoaded() async {
    await Future.wait([ensureStoredPreferencesLoaded(), ensureCatalogLoaded()]);
  }

  Future<void> ensureStoredPreferencesLoaded() {
    if (state.loadStatus == PreferencesLoadStatus.ready) {
      return Future.value();
    }
    final running = _preferencesLoad;
    if (running != null) return running;
    late final Future<void> tracked;
    tracked = _loadStoredPreferences().whenComplete(() {
      if (identical(_preferencesLoad, tracked)) _preferencesLoad = null;
    });
    _preferencesLoad = tracked;
    return tracked;
  }

  Future<void> retryStoredPreferences() => ensureStoredPreferencesLoaded();

  Future<void> ensureCatalogLoaded() {
    if (state.catalogStatus == PreferencesCatalogStatus.ready) {
      return Future.value();
    }
    final running = _catalogLoad;
    if (running != null) return running;
    late final Future<void> tracked;
    tracked = _loadCatalog().whenComplete(() {
      if (identical(_catalogLoad, tracked)) _catalogLoad = null;
    });
    _catalogLoad = tracked;
    return tracked;
  }

  void updateMinimumAge(String value) {
    if (state.isSaving) return;
    state = state.copyWith(
      draft: state.draft.copyWith(minAge: value),
      clearSaveError: true,
    );
  }

  void updateMaximumAge(String value) {
    if (state.isSaving) return;
    state = state.copyWith(
      draft: state.draft.copyWith(maxAge: value),
      clearSaveError: true,
    );
  }

  void updateAttribute(String key, String? value) {
    if (state.isSaving || !DiscoveryPreferences.attributeKeys.contains(key)) {
      return;
    }
    state = state.copyWith(
      draft: state.draft.copyWithAttribute(key, value),
      clearSaveError: true,
    );
  }

  Future<bool> save() {
    final running = _saveFuture;
    if (running != null) return running;
    if (!state.canSave) return Future.value(false);

    late final Future<bool> tracked;
    tracked = _performSave().whenComplete(() {
      if (identical(_saveFuture, tracked)) _saveFuture = null;
    });
    _saveFuture = tracked;
    return tracked;
  }

  void discardDraft() {
    if (state.isSaving) return;
    state = state.copyWith(
      draft: DiscoveryPreferencesDraft.fromPreferences(state.saved),
      clearSaveError: true,
    );
  }

  Future<void> _loadStoredPreferences() async {
    final userId = state.userId;
    if (userId == null) {
      state = state.copyWith(
        loadStatus: PreferencesLoadStatus.error,
        loadError: StateError('Authenticated account is unavailable'),
      );
      return;
    }
    state = state.copyWith(
      loadStatus: PreferencesLoadStatus.loading,
      clearLoadError: true,
    );
    try {
      final saved = await _storage.read(userId);
      if (state.userId != userId) return;
      state = state.copyWith(
        loadStatus: PreferencesLoadStatus.ready,
        saved: saved,
        draft: DiscoveryPreferencesDraft.fromPreferences(saved),
        clearLoadError: true,
      );
    } on Object catch (error) {
      if (state.userId != userId) return;
      state = state.copyWith(
        loadStatus: PreferencesLoadStatus.error,
        loadError: error,
      );
    }
  }

  Future<void> _loadCatalog() async {
    state = state.copyWith(
      catalogStatus: PreferencesCatalogStatus.loading,
      clearCatalogError: true,
    );
    try {
      final cached = ref.read(profileEditControllerProvider).catalog;
      final catalog =
          cached ?? await ref.read(profileRepositoryProvider).getEditCatalog();
      state = state.copyWith(
        catalogStatus: PreferencesCatalogStatus.ready,
        catalog: catalog,
        clearCatalogError: true,
      );
    } on Object catch (error) {
      state = state.copyWith(
        catalogStatus: PreferencesCatalogStatus.error,
        catalogError: error,
      );
    }
  }

  Future<bool> _performSave() async {
    final userId = state.userId;
    final preferences = state.draft.validatedPreferences;
    if (userId == null || preferences == null) return false;
    state = state.copyWith(isSaving: true, clearSaveError: true);
    try {
      await _storage.write(userId, preferences);
      if (state.userId != userId) return false;
      state = state.copyWith(
        saved: preferences,
        draft: DiscoveryPreferencesDraft.fromPreferences(preferences),
        isSaving: false,
        clearSaveError: true,
      );
      return true;
    } on Object catch (error) {
      if (state.userId != userId) return false;
      state = state.copyWith(isSaving: false, saveError: error);
      return false;
    }
  }
}
