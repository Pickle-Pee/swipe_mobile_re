import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/profile_models.dart';
import '../domain/public_profile_repository.dart';

enum PublicProfileStatus { initial, loading, data, missing, error }

class PublicProfileState {
  const PublicProfileState({
    this.status = PublicProfileStatus.initial,
    this.profile,
    this.error,
  });

  final PublicProfileStatus status;
  final PublicUserProfile? profile;
  final Object? error;
}

final publicProfileRepositoryProvider = Provider<PublicProfileRepository>((
  ref,
) {
  return DioPublicProfileRepository(ref.watch(apiClientProvider));
});

final publicProfileControllerProvider =
    NotifierProvider.family<PublicProfileController, PublicProfileState, int>(
      PublicProfileController.new,
    );

class PublicProfileController extends Notifier<PublicProfileState> {
  PublicProfileController(this.userId);

  final int userId;

  PublicProfileRepository get _repository =>
      ref.read(publicProfileRepositoryProvider);

  @override
  PublicProfileState build() => const PublicProfileState();

  Future<void> load({PublicUserProfile? seed}) async {
    final retained = seed ?? state.profile;
    state = PublicProfileState(
      status: PublicProfileStatus.loading,
      profile: retained,
    );
    try {
      state = PublicProfileState(
        status: PublicProfileStatus.data,
        profile: await _repository.getProfile(userId),
      );
    } on ApiException catch (error) {
      state = PublicProfileState(
        status: error.statusCode == 404 && retained == null
            ? PublicProfileStatus.missing
            : PublicProfileStatus.error,
        profile: retained,
        error: error,
      );
    } on Object catch (error) {
      state = PublicProfileState(
        status: PublicProfileStatus.error,
        profile: retained,
        error: error,
      );
    }
  }
}
