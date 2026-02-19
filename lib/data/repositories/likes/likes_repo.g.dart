// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'likes_repo.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$LikesStore on _LikesStore, Store {
  late final _$likesListAtom =
      Atom(name: '_LikesStore.likesList', context: context);

  @override
  ObservableList<CardInfo> get likesList {
    _$likesListAtom.reportRead();
    return super.likesList;
  }

  @override
  set likesList(ObservableList<CardInfo> value) {
    _$likesListAtom.reportWrite(value, super.likesList, () {
      super.likesList = value;
    });
  }

  late final _$favoriteListAtom =
      Atom(name: '_LikesStore.favoriteList', context: context);

  @override
  ObservableList<CardInfo> get favoriteList {
    _$favoriteListAtom.reportRead();
    return super.favoriteList;
  }

  @override
  set favoriteList(ObservableList<CardInfo> value) {
    _$favoriteListAtom.reportWrite(value, super.favoriteList, () {
      super.favoriteList = value;
    });
  }

  late final _$melikedListAtom =
      Atom(name: '_LikesStore.melikedList', context: context);

  @override
  ObservableList<CardInfo> get melikedList {
    _$melikedListAtom.reportRead();
    return super.melikedList;
  }

  @override
  set melikedList(ObservableList<CardInfo> value) {
    _$melikedListAtom.reportWrite(value, super.melikedList, () {
      super.melikedList = value;
    });
  }

  late final _$requiredUpdateAtom =
      Atom(name: '_LikesStore.requiredUpdate', context: context);

  @override
  bool get requiredUpdate {
    _$requiredUpdateAtom.reportRead();
    return super.requiredUpdate;
  }

  @override
  set requiredUpdate(bool value) {
    _$requiredUpdateAtom.reportWrite(value, super.requiredUpdate, () {
      super.requiredUpdate = value;
    });
  }

  late final _$requiredUpdateFavoriteAtom =
      Atom(name: '_LikesStore.requiredUpdateFavorite', context: context);

  @override
  bool get requiredUpdateFavorite {
    _$requiredUpdateFavoriteAtom.reportRead();
    return super.requiredUpdateFavorite;
  }

  @override
  set requiredUpdateFavorite(bool value) {
    _$requiredUpdateFavoriteAtom
        .reportWrite(value, super.requiredUpdateFavorite, () {
      super.requiredUpdateFavorite = value;
    });
  }

  late final _$requiredUpdatemelikedAtom =
      Atom(name: '_LikesStore.requiredUpdatemeliked', context: context);

  @override
  bool get requiredUpdatemeliked {
    _$requiredUpdatemelikedAtom.reportRead();
    return super.requiredUpdatemeliked;
  }

  @override
  set requiredUpdatemeliked(bool value) {
    _$requiredUpdatemelikedAtom.reportWrite(value, super.requiredUpdatemeliked,
        () {
      super.requiredUpdatemeliked = value;
    });
  }

  late final _$getListLikesAsyncAction =
      AsyncAction('_LikesStore.getListLikes', context: context);

  @override
  Future<void> getListLikes() {
    return _$getListLikesAsyncAction.run(() => super.getListLikes());
  }

  late final _$getListMeLikedAsyncAction =
      AsyncAction('_LikesStore.getListMeLiked', context: context);

  @override
  Future<void> getListMeLiked() {
    return _$getListMeLikedAsyncAction.run(() => super.getListMeLiked());
  }

  late final _$getListFavoriteAsyncAction =
      AsyncAction('_LikesStore.getListFavorite', context: context);

  @override
  Future<void> getListFavorite() {
    return _$getListFavoriteAsyncAction.run(() => super.getListFavorite());
  }

  late final _$_LikesStoreActionController =
      ActionController(name: '_LikesStore', context: context);

  @override
  dynamic likesEditRequiredUpdate() {
    final _$actionInfo = _$_LikesStoreActionController.startAction(
        name: '_LikesStore.likesEditRequiredUpdate');
    try {
      return super.likesEditRequiredUpdate();
    } finally {
      _$_LikesStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  dynamic favoriteEditRequiredUpdate() {
    final _$actionInfo = _$_LikesStoreActionController.startAction(
        name: '_LikesStore.favoriteEditRequiredUpdate');
    try {
      return super.favoriteEditRequiredUpdate();
    } finally {
      _$_LikesStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  dynamic meLikedEditRequiredUpdate() {
    final _$actionInfo = _$_LikesStoreActionController.startAction(
        name: '_LikesStore.meLikedEditRequiredUpdate');
    try {
      return super.meLikedEditRequiredUpdate();
    } finally {
      _$_LikesStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
likesList: ${likesList},
favoriteList: ${favoriteList},
melikedList: ${melikedList},
requiredUpdate: ${requiredUpdate},
requiredUpdateFavorite: ${requiredUpdateFavorite},
requiredUpdatemeliked: ${requiredUpdatemeliked}
    ''';
  }
}
