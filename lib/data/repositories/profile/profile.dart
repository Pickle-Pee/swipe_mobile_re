import 'package:mobx/mobx.dart';
import 'package:swipe_mobile_re/core/network/photo_http/photo_http.dart';
import 'package:swipe_mobile_re/core/network/user/user_http.dart';

part 'profile.g.dart';

class ProfileStore = _ProfileStore with _$ProfileStore;

abstract class _ProfileStore with Store {
  @observable
  UserInfo? userInfo;

  @observable
  bool validData = false;

  @observable
  ObservableList<Photo> photos = ObservableList();

  @observable
  int getMeInfoStatus = 0;

  @action
  Future<int> getMeInfo() async {
    final result = await UserHttp().getMeInfo();
    if (result != null) {
      runInAction(() {
        validData = true;
        userInfo = result;
      });
      await getUserPhoto();
      print("Количество фотографий: ${photos.length}");
      return 0; // Успешно
    } else {
      return -1; // Ошибка
    }
  }

  @action
  void updateValidData(bool updateValue) {
    validData = updateValue;
  }

  @action
  void editMeInfo(UserInfo newUserInfo) {
    if (userInfo != null) {
      userInfo!.aboutMe = newUserInfo.aboutMe;
      userInfo!.dateOfBirth = newUserInfo.dateOfBirth;
      userInfo!.firstName = newUserInfo.firstName;
      userInfo!.gender = newUserInfo.gender;
      userInfo!.cityName = newUserInfo.cityName;
    }
  }

  @action
  void editMeInterest(List<Interest> newUserInterest) {
    if (userInfo != null) {
      userInfo!.interest = newUserInterest;
    }
  }

  @action
  Future<void> getUserPhoto() async {
    final result = await PhotoHttp().getUserPhoto();
    if (result.isNotEmpty) {
      result.sort(
        (a, b) => a.isAvatar ? 0 : 1,
      );
      photos = ObservableList.of(result);
    }
  }

  @action
  void clearRepository() {
    userInfo = null;
    validData = false;
  }
}

final profileStore = ProfileStore();

class Photo {
  int id;
  String photoUrl;
  bool isAvatar;
  double scale;
  double positionX;
  double positionY;

  Photo({
    required this.id,
    required this.isAvatar,
    required this.photoUrl,
    required this.scale,
    required this.positionX,
    required this.positionY,
  });
}
