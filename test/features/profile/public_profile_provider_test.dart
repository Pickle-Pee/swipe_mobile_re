import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/core/network/api_exception.dart';
import 'package:swipe_mobile_re/features/profile/application/public_profile_providers.dart';
import 'package:swipe_mobile_re/features/profile/domain/profile_models.dart';
import 'package:swipe_mobile_re/features/profile/domain/public_profile_repository.dart';

void main() {
  test('publishes loaded public profile', () async {
    final container = ProviderContainer(
      overrides: [
        publicProfileRepositoryProvider.overrideWithValue(
          _FakePublicProfileRepository(profile: _profile),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(publicProfileControllerProvider(7).notifier).load();

    final state = container.read(publicProfileControllerProvider(7));
    expect(state.status, PublicProfileStatus.data);
    expect(state.profile?.id, 7);
  });

  test('404 without seed publishes missing state', () async {
    final container = ProviderContainer(
      overrides: [
        publicProfileRepositoryProvider.overrideWithValue(
          _FakePublicProfileRepository(
            error: const UnknownApiException(
              message: 'not found',
              statusCode: 404,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(publicProfileControllerProvider(7).notifier).load();

    expect(
      container.read(publicProfileControllerProvider(7)).status,
      PublicProfileStatus.missing,
    );
  });

  test('refresh error retains the real Discovery seed', () async {
    final container = ProviderContainer(
      overrides: [
        publicProfileRepositoryProvider.overrideWithValue(
          _FakePublicProfileRepository(error: Exception('offline')),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(publicProfileControllerProvider(7).notifier)
        .load(seed: _profile);

    final state = container.read(publicProfileControllerProvider(7));
    expect(state.status, PublicProfileStatus.error);
    expect(state.profile?.firstName, 'Mila');
  });
}

class _FakePublicProfileRepository implements PublicProfileRepository {
  _FakePublicProfileRepository({this.profile, this.error});

  final PublicUserProfile? profile;
  final Object? error;

  @override
  Future<PublicUserProfile> getProfile(int userId) async {
    if (error != null) throw error!;
    return profile!;
  }
}

const _profile = PublicUserProfile(
  id: 7,
  firstName: 'Mila',
  lastName: '',
  dateOfBirth: null,
  gender: '',
  city: 'Lisbon',
  aboutMe: 'Real profile copy',
  avatarUrl: null,
  interests: [],
  photos: [],
  facts: {},
);
