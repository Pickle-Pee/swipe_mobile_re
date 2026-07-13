import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/profile/application/profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_repository.dart';

void main() {
  test(
    'network failure publishes error without throwing from controller',
    () async {
      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(
            FailingProfileRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(profileControllerProvider.notifier).load();

      expect(
        container.read(profileControllerProvider).status,
        ProfileStatus.error,
      );
    },
  );
}

class FailingProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile> getCurrentProfile() => Future.error(Exception('offline'));

  @override
  Future<UserProfile> setAvatar(int photoId) =>
      Future.error(Exception('offline'));

  @override
  Future<UserProfile> updateProfile(ProfileUpdate update) =>
      Future.error(Exception('offline'));

  @override
  Future<UserProfile> uploadPhoto(
    ProfilePhotoFile file, {
    bool isAvatar = false,
    void Function(int, int)? onProgress,
  }) => Future.error(Exception('offline'));
}
