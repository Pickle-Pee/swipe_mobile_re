import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/likes_models.dart';
import '../domain/likes_repository.dart';

enum LikesStatus { initial, loading, data, empty, error }

enum LikesCategory { likedMe, likedUsers, favorites, mutual }

class LikesState {
  const LikesState({
    this.status = LikesStatus.initial,
    this.category = LikesCategory.likedMe,
    this.data,
    this.error,
  });

  final LikesStatus status;
  final LikesCategory category;
  final LikesData? data;
  final Object? error;

  List<LikesUser> get visible => switch (category) {
    LikesCategory.likedMe => data?.likedMe ?? const [],
    LikesCategory.likedUsers => data?.likedUsers ?? const [],
    LikesCategory.favorites => data?.favorites ?? const [],
    LikesCategory.mutual => data?.mutual ?? const [],
  };
}

final likesRepositoryProvider = Provider<LikesRepository>((ref) {
  return DioLikesRepository(ref.watch(apiClientProvider));
});

final likesControllerProvider = NotifierProvider<LikesController, LikesState>(
  LikesController.new,
);

class LikesController extends Notifier<LikesState> {
  LikesRepository get _repository => ref.read(likesRepositoryProvider);

  @override
  LikesState build() => const LikesState();

  Future<void> load() async {
    state = LikesState(
      status: LikesStatus.loading,
      category: state.category,
      data: state.data,
    );
    try {
      final data = await _repository.getLikes();
      state = LikesState(
        status: LikesStatus.data,
        category: state.category,
        data: data,
      );
      _updateEmptyStatus();
    } on Object catch (error) {
      state = LikesState(
        status: LikesStatus.error,
        category: state.category,
        data: state.data,
        error: error,
      );
    }
  }

  void select(LikesCategory category) {
    state = LikesState(
      status: LikesStatus.data,
      category: category,
      data: state.data,
    );
    _updateEmptyStatus();
  }

  void _updateEmptyStatus() {
    if (state.visible.isEmpty) {
      state = LikesState(
        status: LikesStatus.empty,
        category: state.category,
        data: state.data,
      );
    }
  }
}
