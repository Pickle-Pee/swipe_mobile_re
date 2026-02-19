// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reg_repo.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$RegRepo on _RegRepo, Store {
  late final _$nameAtom = Atom(name: '_RegRepo.name', context: context);

  @override
  String get name {
    _$nameAtom.reportRead();
    return super.name;
  }

  @override
  set name(String value) {
    _$nameAtom.reportWrite(value, super.name, () {
      super.name = value;
    });
  }

  late final _$surnameAtom = Atom(name: '_RegRepo.surname', context: context);

  @override
  String get surname {
    _$surnameAtom.reportRead();
    return super.surname;
  }

  @override
  set surname(String value) {
    _$surnameAtom.reportWrite(value, super.surname, () {
      super.surname = value;
    });
  }

  late final _$birthAtom = Atom(name: '_RegRepo.birth', context: context);

  @override
  String get birth {
    _$birthAtom.reportRead();
    return super.birth;
  }

  @override
  set birth(String value) {
    _$birthAtom.reportWrite(value, super.birth, () {
      super.birth = value;
    });
  }

  late final _$genderAtom = Atom(name: '_RegRepo.gender', context: context);

  @override
  String get gender {
    _$genderAtom.reportRead();
    return super.gender;
  }

  @override
  set gender(String value) {
    _$genderAtom.reportWrite(value, super.gender, () {
      super.gender = value;
    });
  }

  late final _$numberAtom = Atom(name: '_RegRepo.number', context: context);

  @override
  String get number {
    _$numberAtom.reportRead();
    return super.number;
  }

  @override
  set number(String value) {
    _$numberAtom.reportWrite(value, super.number, () {
      super.number = value;
    });
  }

  late final _$cityAtom = Atom(name: '_RegRepo.city', context: context);

  @override
  String get city {
    _$cityAtom.reportRead();
    return super.city;
  }

  @override
  set city(String value) {
    _$cityAtom.reportWrite(value, super.city, () {
      super.city = value;
    });
  }

  late final _$_RegRepoActionController =
      ActionController(name: '_RegRepo', context: context);

  @override
  void updateName(String updatedValue) {
    final _$actionInfo =
        _$_RegRepoActionController.startAction(name: '_RegRepo.updateName');
    try {
      return super.updateName(updatedValue);
    } finally {
      _$_RegRepoActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateSurname(String updatedValue) {
    final _$actionInfo =
        _$_RegRepoActionController.startAction(name: '_RegRepo.updateSurname');
    try {
      return super.updateSurname(updatedValue);
    } finally {
      _$_RegRepoActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateBirth(String updatedValue) {
    final _$actionInfo =
        _$_RegRepoActionController.startAction(name: '_RegRepo.updateBirth');
    try {
      return super.updateBirth(updatedValue);
    } finally {
      _$_RegRepoActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateGender(String updatedValue) {
    final _$actionInfo =
        _$_RegRepoActionController.startAction(name: '_RegRepo.updateGender');
    try {
      return super.updateGender(updatedValue);
    } finally {
      _$_RegRepoActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateNumber(String updatedValue) {
    final _$actionInfo =
        _$_RegRepoActionController.startAction(name: '_RegRepo.updateNumber');
    try {
      return super.updateNumber(updatedValue);
    } finally {
      _$_RegRepoActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCity(String updatedValue) {
    final _$actionInfo =
        _$_RegRepoActionController.startAction(name: '_RegRepo.updateCity');
    try {
      return super.updateCity(updatedValue);
    } finally {
      _$_RegRepoActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
name: ${name},
surname: ${surname},
birth: ${birth},
gender: ${gender},
number: ${number},
city: ${city}
    ''';
  }
}
