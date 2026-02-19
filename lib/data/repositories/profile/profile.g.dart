// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ProfileStore on _ProfileStore, Store {
  late final _$userInfoAtom =
      Atom(name: '_ProfileStore.userInfo', context: context);

  @override
  UserInfo? get userInfo {
    _$userInfoAtom.reportRead();
    return super.userInfo;
  }

  @override
  set userInfo(UserInfo? value) {
    _$userInfoAtom.reportWrite(value, super.userInfo, () {
      super.userInfo = value;
    });
  }

  late final _$validDataAtom =
      Atom(name: '_ProfileStore.validData', context: context);

  @override
  bool get validData {
    _$validDataAtom.reportRead();
    return super.validData;
  }

  @override
  set validData(bool value) {
    _$validDataAtom.reportWrite(value, super.validData, () {
      super.validData = value;
    });
  }

  late final _$photosAtom =
      Atom(name: '_ProfileStore.photos', context: context);

  @override
  ObservableList<Photo> get photos {
    _$photosAtom.reportRead();
    return super.photos;
  }

  @override
  set photos(ObservableList<Photo> value) {
    _$photosAtom.reportWrite(value, super.photos, () {
      super.photos = value;
    });
  }

  late final _$getMeInfoStatusAtom =
      Atom(name: '_ProfileStore.getMeInfoStatus', context: context);

  @override
  int get getMeInfoStatus {
    _$getMeInfoStatusAtom.reportRead();
    return super.getMeInfoStatus;
  }

  @override
  set getMeInfoStatus(int value) {
    _$getMeInfoStatusAtom.reportWrite(value, super.getMeInfoStatus, () {
      super.getMeInfoStatus = value;
    });
  }

  late final _$getMeInfoAsyncAction =
      AsyncAction('_ProfileStore.getMeInfo', context: context);

  @override
  Future<int> getMeInfo() {
    return _$getMeInfoAsyncAction.run(() => super.getMeInfo());
  }

  late final _$getUserPhotoAsyncAction =
      AsyncAction('_ProfileStore.getUserPhoto', context: context);

  @override
  Future<void> getUserPhoto() {
    return _$getUserPhotoAsyncAction.run(() => super.getUserPhoto());
  }

  late final _$_ProfileStoreActionController =
      ActionController(name: '_ProfileStore', context: context);

  @override
  void updateValidData(bool updateValue) {
    final _$actionInfo = _$_ProfileStoreActionController.startAction(
        name: '_ProfileStore.updateValidData');
    try {
      return super.updateValidData(updateValue);
    } finally {
      _$_ProfileStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void editMeInfo(UserInfo newUserInfo) {
    final _$actionInfo = _$_ProfileStoreActionController.startAction(
        name: '_ProfileStore.editMeInfo');
    try {
      return super.editMeInfo(newUserInfo);
    } finally {
      _$_ProfileStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void editMeInterest(List<Interest> newUserInterest) {
    final _$actionInfo = _$_ProfileStoreActionController.startAction(
        name: '_ProfileStore.editMeInterest');
    try {
      return super.editMeInterest(newUserInterest);
    } finally {
      _$_ProfileStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearRepository() {
    final _$actionInfo = _$_ProfileStoreActionController.startAction(
        name: '_ProfileStore.clearRepository');
    try {
      return super.clearRepository();
    } finally {
      _$_ProfileStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
userInfo: ${userInfo},
validData: ${validData},
photos: ${photos},
getMeInfoStatus: ${getMeInfoStatus}
    ''';
  }
}
