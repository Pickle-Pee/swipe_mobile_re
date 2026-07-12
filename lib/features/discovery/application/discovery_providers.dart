import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/discovery_models.dart';
import '../domain/discovery_repository.dart';

enum DiscoveryStatus { initial, loading, data, empty, error }

class DiscoveryState {
  const DiscoveryState({
    this.status = DiscoveryStatus.initial,
    this.profiles = const [],
    this.isProcessing = false,
    this.error,
    this.lastReaction,
    this.matchedProfile,
  });

  final DiscoveryStatus status;
  final List<DiscoveryProfile> profiles;
  final bool isProcessing;
  final Object? error;
  final DiscoveryReactionResult? lastReaction;
  final DiscoveryProfile? matchedProfile;

  DiscoveryProfile? get current => profiles.isEmpty ? null : profiles.first;
}

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DioDiscoveryRepository(ref.watch(apiClientProvider));
});

final discoveryControllerProvider =
    NotifierProvider<DiscoveryController, DiscoveryState>(
      DiscoveryController.new,
    );

class DiscoveryController extends Notifier<DiscoveryState> {
  DiscoveryRepository get _repository => ref.read(discoveryRepositoryProvider);

  @override
  DiscoveryState build() => const DiscoveryState();

  Future<void> load() async {
    state = DiscoveryState(
      status: DiscoveryStatus.loading,
      profiles: state.profiles,
    );
    try {
      final profiles = await _repository.getProfiles();
      state = DiscoveryState(
        status: profiles.isEmpty ? DiscoveryStatus.empty : DiscoveryStatus.data,
        profiles: profiles,
      );
    } on Object catch (error) {
      state = DiscoveryState(
        status: DiscoveryStatus.error,
        profiles: state.profiles,
        error: error,
      );
    }
  }

  Future<void> like() => _react(DiscoveryReaction.like);
  Future<void> pass() => _react(DiscoveryReaction.pass);

  Future<void> _react(DiscoveryReaction reaction) async {
    final current = state.current;
    if (current == null || state.isProcessing) return;
    state = DiscoveryState(
      status: state.status,
      profiles: state.profiles,
      isProcessing: true,
    );
    try {
      final result = await _repository.react(current.id, reaction);
      final remaining = state.profiles.skip(1).toList();
      state = DiscoveryState(
        status: remaining.isEmpty
            ? DiscoveryStatus.empty
            : DiscoveryStatus.data,
        profiles: remaining,
        lastReaction: result,
        matchedProfile: result.isMatch ? current : null,
      );
    } on Object catch (error) {
      state = DiscoveryState(
        status: DiscoveryStatus.error,
        profiles: state.profiles,
        error: error,
      );
    }
  }

  void consumeMatch() {
    state = DiscoveryState(
      status: state.status,
      profiles: state.profiles,
      isProcessing: state.isProcessing,
      error: state.error,
      lastReaction: state.lastReaction,
    );
  }
}
