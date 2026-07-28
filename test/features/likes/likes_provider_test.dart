import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/likes/application/likes_providers.dart';
import 'package:swipe_mobile_re/features/likes/domain/likes_models.dart';
import 'package:swipe_mobile_re/features/likes/domain/likes_repository.dart';

void main() {
  test('loads the real pending incoming count', () async {
    final container = ProviderContainer(
      overrides: [
        likesRepositoryProvider.overrideWithValue(
          FakeLikesRepository(
            LikesData(
              likedMe: const [incoming, mutual],
              likedUsers: const [mutual],
              favorites: const [],
              mutual: const [mutual],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(likesControllerProvider.notifier).load();

    final state = container.read(likesControllerProvider);
    expect(state.status, LikesStatus.data);
    expect(state.incomingCount, 1);
    expect(state.visible, [incoming]);
  });

  test(
    'processed incoming profile is removed and mutual data is updated',
    () async {
      final container = ProviderContainer(
        overrides: [
          likesRepositoryProvider.overrideWithValue(
            FakeLikesRepository(
              const LikesData(
                likedMe: [incoming],
                likedUsers: [],
                favorites: [],
                mutual: [],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(likesControllerProvider.notifier);
      await controller.load();

      controller.resolveIncoming(incoming.id, isMatch: true);

      final state = container.read(likesControllerProvider);
      expect(state.visible, isEmpty);
      expect(state.incomingCount, 0);
      expect(state.data!.likedUsers.single.id, incoming.id);
      expect(state.data!.mutual.single.id, incoming.id);
      expect(state.data!.mutual.single.mutual, isTrue);
    },
  );

  test('category selection preserves each backend dataset', () async {
    final container = ProviderContainer(
      overrides: [
        likesRepositoryProvider.overrideWithValue(
          FakeLikesRepository(
            const LikesData(
              likedMe: [incoming],
              likedUsers: [outgoing],
              favorites: [favorite],
              mutual: [mutual],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(likesControllerProvider.notifier);
    await controller.load();

    for (final entry in {
      LikesCategory.likedMe: incoming,
      LikesCategory.likedUsers: outgoing,
      LikesCategory.favorites: favorite,
      LikesCategory.mutual: mutual,
    }.entries) {
      controller.select(entry.key);
      expect(container.read(likesControllerProvider).visible, [entry.value]);
    }
  });

  test('refresh error retains already loaded real Likes', () async {
    final repository = FakeLikesRepository(
      const LikesData(
        likedMe: [incoming],
        likedUsers: [],
        favorites: [],
        mutual: [],
      ),
    );
    final container = ProviderContainer(
      overrides: [likesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(likesControllerProvider.notifier);
    await controller.load();
    repository.error = Exception('offline');

    await controller.load();

    final state = container.read(likesControllerProvider);
    expect(state.status, LikesStatus.error);
    expect(state.visible, [incoming]);
    expect(state.error, isNotNull);
  });
}

class FakeLikesRepository implements LikesRepository {
  FakeLikesRepository(this.data);

  final LikesData data;
  Object? error;

  @override
  Future<LikesData> getLikes() async {
    if (error != null) throw error!;
    return data;
  }
}

const incoming = LikesUser(
  id: 1,
  firstName: 'Mila',
  dateOfBirth: null,
  city: 'Lisbon',
  aboutMe: 'Real incoming profile',
  status: '',
  avatarUrl: null,
  mutual: false,
);

const outgoing = LikesUser(
  id: 2,
  firstName: 'Nora',
  dateOfBirth: null,
  city: 'Oslo',
  aboutMe: '',
  status: '',
  avatarUrl: null,
  mutual: false,
);

const favorite = LikesUser(
  id: 3,
  firstName: 'Ava',
  dateOfBirth: null,
  city: 'Rome',
  aboutMe: '',
  status: '',
  avatarUrl: null,
  mutual: false,
);

const mutual = LikesUser(
  id: 4,
  firstName: 'Lea',
  dateOfBirth: null,
  city: 'Paris',
  aboutMe: '',
  status: '',
  avatarUrl: null,
  mutual: true,
);
