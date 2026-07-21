import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/discovery/application/discovery_providers.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_models.dart';
import 'package:swipe_mobile_re/features/discovery/domain/discovery_repository.dart';

void main() {
  const profile = DiscoveryProfile(
    id: 1,
    firstName: 'API user',
    dateOfBirth: null,
    city: '',
    aboutMe: '',
    photoUrl: null,
    interests: [],
    attributes: {},
  );

  test('failed reaction keeps the current card', () async {
    final repository = FakeDiscoveryRepository([profile])..failReaction = true;
    final container = ProviderContainer(
      overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(discoveryControllerProvider.notifier);
    await controller.load();

    await controller.like();

    final state = container.read(discoveryControllerProvider);
    expect(state.status, DiscoveryStatus.error);
    expect(state.current?.id, profile.id);
  });

  test(
    'double reaction starts one request and advances after success',
    () async {
      final repository = FakeDiscoveryRepository([profile]);
      final container = ProviderContainer(
        overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final controller = container.read(discoveryControllerProvider.notifier);
      await controller.load();

      final first = controller.pass();
      final second = controller.pass();
      expect(repository.reactionCalls, 1);
      repository.reactionCompleter.complete(
        const DiscoveryReactionResult(isMatch: false),
      );
      await Future.wait([first, second]);

      expect(
        container.read(discoveryControllerProvider).status,
        DiscoveryStatus.empty,
      );
    },
  );

  test('mutual like exposes the matched profile once', () async {
    final repository = FakeDiscoveryRepository([profile]);
    final container = ProviderContainer(
      overrides: [discoveryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(discoveryControllerProvider.notifier);
    await controller.load();

    final request = controller.like();
    repository.reactionCompleter.complete(
      const DiscoveryReactionResult(isMatch: true),
    );
    await request;

    expect(container.read(discoveryControllerProvider).matchedProfile?.id, 1);
    controller.consumeMatch();
    expect(container.read(discoveryControllerProvider).matchedProfile, isNull);
  });
}

class FakeDiscoveryRepository implements DiscoveryRepository {
  FakeDiscoveryRepository(this.profiles);
  final List<DiscoveryProfile> profiles;
  final reactionCompleter = Completer<DiscoveryReactionResult>();
  bool failReaction = false;
  int reactionCalls = 0;

  @override
  Future<List<DiscoveryProfile>> getProfiles() async => profiles;

  @override
  Future<DiscoveryReactionResult> react(
    int profileId,
    DiscoveryReaction reaction,
  ) {
    reactionCalls++;
    if (failReaction) return Future.error(Exception('offline'));
    return reactionCompleter.future;
  }
}
