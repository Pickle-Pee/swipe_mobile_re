import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/settings_models.dart';
import '../domain/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return DioSettingsRepository(ref.watch(apiClientProvider));
});

final appInformationSourceProvider = Provider<AppInformationSource>((ref) {
  return const PlatformAppInformationSource();
});

final deleteAccountSessionCleanupProvider = Provider<Future<void> Function()>((
  ref,
) {
  return ref.read(authControllerProvider.notifier).logout;
});

final appInformationControllerProvider =
    NotifierProvider<AppInformationController, AppInformationState>(
      AppInformationController.new,
    );

class AppInformationController extends Notifier<AppInformationState> {
  Future<void>? _loadFuture;

  @override
  AppInformationState build() {
    _loadFuture = null;
    return const AppInformationState();
  }

  Future<void> ensureLoaded() {
    if (state.status == AppInformationStatus.data) return Future.value();
    final running = _loadFuture;
    if (running != null) return running;
    return _load();
  }

  Future<void> retry() => _load();

  Future<void> _load() {
    final running = _loadFuture;
    if (running != null) return running;

    late final Future<void> tracked;
    tracked = _performLoad().whenComplete(() {
      if (identical(_loadFuture, tracked)) _loadFuture = null;
    });
    _loadFuture = tracked;
    return tracked;
  }

  Future<void> _performLoad() async {
    state = const AppInformationState(status: AppInformationStatus.loading);
    try {
      final packageInfo = await ref.read(appInformationSourceProvider).load();
      state = AppInformationState(
        status: AppInformationStatus.data,
        packageInfo: packageInfo,
      );
    } on Object catch (error) {
      state = AppInformationState(
        status: AppInformationStatus.error,
        error: error,
      );
    }
  }
}

final deleteAccountControllerProvider =
    NotifierProvider<DeleteAccountController, DeleteAccountState>(
      DeleteAccountController.new,
    );

class DeleteAccountController extends Notifier<DeleteAccountState> {
  @override
  DeleteAccountState build() => const DeleteAccountState();

  Future<bool> deleteAccount() async {
    if (state.isDeleting || state.status == DeleteAccountStatus.deleted) {
      return false;
    }
    state = const DeleteAccountState(status: DeleteAccountStatus.deleting);
    try {
      await ref.read(settingsRepositoryProvider).deleteAccount();
      await ref.read(deleteAccountSessionCleanupProvider)();
      state = const DeleteAccountState(status: DeleteAccountStatus.deleted);
      return true;
    } on Object catch (error) {
      state = DeleteAccountState(
        status: DeleteAccountStatus.error,
        error: error,
      );
      return false;
    }
  }

  void reset() {
    if (state.isDeleting) return;
    state = const DeleteAccountState();
  }
}
