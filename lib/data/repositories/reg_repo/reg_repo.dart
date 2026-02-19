import 'package:mobx/mobx.dart';

part 'reg_repo.g.dart';

class RegRepo = _RegRepo with _$RegRepo;

abstract class _RegRepo with Store {
  @observable
  String name = "";

  @observable
  String surname = "";

  @observable
  String birth = "";

  @observable
  String gender = "";

  @observable
  String number = "";

  @observable
  String city = "";

  @action
  void updateName(String updatedValue) {
    name = updatedValue;
  }

  @action
  void updateSurname(String updatedValue) {
    surname = updatedValue;
  }

  @action
  void updateBirth(String updatedValue) {
    birth = updatedValue;
  }

  @action
  void updateGender(String updatedValue) {
    gender = updatedValue;
  }

  @action
  void updateNumber(String updatedValue) {
    number = updatedValue;
  }

  @action
  void updateCity(String updatedValue) {
    city = updatedValue;
  }

  Map<String, dynamic> generateJSON() {
    return {
      "phone_number": number,
      "first_name": name,
      "last_name": surname,
      "date_of_birth": birth,
      "gender": gender,
      "city_name": city
    };
  }
}

RegRepo regRepo = RegRepo();
