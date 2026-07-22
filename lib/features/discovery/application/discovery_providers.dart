import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/discovery_models.dart';
import '../domain/discovery_repository.dart';

enum DiscoveryStatus { initial, loading, data, empty, error }

enum DiscoveryEmptyReason { noProfiles, endOfFeed }

class DiscoveryState {
  const DiscoveryState({
    this.status = DiscoveryStatus.initial,
    this.profiles = const [],
    this.processingReaction,
    this.processingProfileId,
    this.failedReaction,
    this.failedProfile,
    this.emptyReason,
    this.error,
    this.lastReaction,
    this.matchedProfile,
  });

  final DiscoveryStatus status;
  final List<DiscoveryProfile> profiles;
  final DiscoveryReaction? processingReaction;
  final int? processingProfileId;
  final DiscoveryReaction? failedReaction;
  final DiscoveryProfile? failedProfile;
  final DiscoveryEmptyReason? emptyReason;
  final Object? error;
  final DiscoveryReactionResult? lastReaction;
  final DiscoveryProfile? matchedProfile;

  DiscoveryProfile? get current => profiles.isEmpty ? null : profiles.first;
  bool get isProcessing => processingReaction != null;
}

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DioDiscoveryRepository(ref.watch(apiClientProvider));
});

final discoveryControllerProvider =
    NotifierProvider<DiscoveryController, DiscoveryState>(
      DiscoveryController.new,
    );

class DiscoveryController extends Notifier<DiscoveryState> {
  final Set<int> _reactedProfileIds = <int>{};
  int? _activeUserId;
  bool _failedReactionCoordinatesMatch = true;

  DiscoveryRepository get _repository => ref.read(discoveryRepositoryProvider);

  @override
  DiscoveryState build() {
    final userId = ref.watch(
      authControllerProvider.select((auth) => auth.user?.id),
    );
    if (_activeUserId != userId) {
      _activeUserId = userId;
      _reactedProfileIds.clear();
    }
    return const DiscoveryState();
  }

  Future<void> load() async {
    final activeUserId = _activeUserId;
    state = DiscoveryState(
      status: DiscoveryStatus.loading,
      profiles: state.profiles,
      emptyReason: state.emptyReason,
    );
    try {
      final fetchedProfiles = await _repository.getProfiles();
      if (_activeUserId != activeUserId) return;
      final profiles = fetchedProfiles
          .where((profile) => !_reactedProfileIds.contains(profile.id))
          .toList(growable: false);
      state = DiscoveryState(
        status: profiles.isEmpty ? DiscoveryStatus.empty : DiscoveryStatus.data,
        profiles: profiles,
        emptyReason: profiles.isEmpty
            ? fetchedProfiles.isEmpty
                  ? DiscoveryEmptyReason.noProfiles
                  : DiscoveryEmptyReason.endOfFeed
            : null,
      );
    } on Object catch (error) {
      if (_activeUserId != activeUserId) return;
      state = DiscoveryState(
        status: DiscoveryStatus.error,
        profiles: state.profiles,
        emptyReason: state.emptyReason,
        error: error,
      );
    }
  }

  Future<DiscoveryReactionResult?> like() => _react(DiscoveryReaction.like);
  Future<DiscoveryReactionResult?> pass() => _react(DiscoveryReaction.pass);

  Future<DiscoveryReactionResult?> likeProfile(DiscoveryProfile profile) =>
      _react(DiscoveryReaction.like, target: profile, coordinateMatch: false);

  Future<DiscoveryReactionResult?> retryReaction() async {
    final reaction = state.failedReaction;
    if (reaction == null) return null;
    return _react(
      reaction,
      target: state.failedProfile,
      coordinateMatch: _failedReactionCoordinatesMatch,
    );
  }

  Future<DiscoveryReactionResult?> _react(
    DiscoveryReaction reaction, {
    DiscoveryProfile? target,
    bool coordinateMatch = true,
  }) async {
    final current = target ?? state.current;
    if (current == null || state.isProcessing) return null;
    final activeUserId = _activeUserId;
    state = DiscoveryState(
      status: state.status,
      profiles: state.profiles,
      processingReaction: reaction,
      processingProfileId: current.id,
      emptyReason: state.emptyReason,
      lastReaction: state.lastReaction,
    );
    try {
      final result = await _repository.react(current.id, reaction);
      if (_activeUserId != activeUserId) return null;
      _reactedProfileIds.add(current.id);
      final targetWasInFeed = state.profiles.any(
        (profile) => profile.id == current.id,
      );
      final remaining = state.profiles
          .where((profile) => profile.id != current.id)
          .toList(growable: false);
      state = DiscoveryState(
        status: targetWasInFeed
            ? remaining.isEmpty
                  ? DiscoveryStatus.empty
                  : DiscoveryStatus.data
            : state.status,
        profiles: remaining,
        emptyReason: targetWasInFeed && remaining.isEmpty
            ? DiscoveryEmptyReason.endOfFeed
            : state.emptyReason,
        lastReaction: result,
        matchedProfile: coordinateMatch && result.isMatch ? current : null,
      );
      return result;
    } on Object catch (error) {
      if (_activeUserId != activeUserId) return null;
      _failedReactionCoordinatesMatch = coordinateMatch;
      state = DiscoveryState(
        status: coordinateMatch ? DiscoveryStatus.error : state.status,
        profiles: state.profiles,
        failedReaction: reaction,
        failedProfile: current,
        emptyReason: state.emptyReason,
        error: error,
        lastReaction: state.lastReaction,
      );
      return null;
    }
  }

  void consumeMatch() {
    state = DiscoveryState(
      status: state.status,
      profiles: state.profiles,
      processingReaction: state.processingReaction,
      processingProfileId: state.processingProfileId,
      failedReaction: state.failedReaction,
      failedProfile: state.failedProfile,
      emptyReason: state.emptyReason,
      error: state.error,
      lastReaction: state.lastReaction,
    );
  }
}
