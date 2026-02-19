import 'package:mobx/mobx.dart';
import 'package:swipe_mobile_re/core/network/likes/likes_http.dart';

part 'likes_repo.g.dart';

class LikesStore = _LikesStore with _$LikesStore;

abstract class _LikesStore with Store {
  @observable
  ObservableList<CardInfo> likesList = ObservableList();

  @observable
  ObservableList<CardInfo> favoriteList = ObservableList();

  @observable
  ObservableList<CardInfo> melikedList = ObservableList();

  @observable
  bool requiredUpdate = true;

  @observable
  bool requiredUpdateFavorite = true;

  @observable
  bool requiredUpdatemeliked = true;

  @action
  Future<void> getListLikes() async {
    final data = await LikesHttp().getListLikes();
    if (data is List<CardInfo>) {
      likesList = ObservableList.of(data);
    }
    requiredUpdate = false;
  }

  @action
  Future<void> getListMeLiked() async {
    final data = await LikesHttp().getListMeLiked();
    if (data is List<CardInfo>) {
      melikedList = ObservableList.of(data);
    }
    requiredUpdatemeliked = false;
  }

  @action
  Future<void> getListFavorite() async {
    final data = await LikesHttp().getListFavorite();
    if (data is List<CardInfo>) {
      favoriteList = ObservableList.of(data);
    }
    requiredUpdateFavorite = false;
  }

  @action
  likesEditRequiredUpdate() {
    requiredUpdate = true;
  }

  @action
  favoriteEditRequiredUpdate() {
    requiredUpdateFavorite = true;
  }

  @action
  meLikedEditRequiredUpdate() {
    requiredUpdateFavorite = true;
  }
}

final likesStore = LikesStore();

class CardInfo {
  int id;
  String firstName;
  String dateOfBirth;
  String cityName;
  bool? isFavorite;
  String? aboutMe;
  String status;
  String? avatarUrl;
  int matchPercentage;
  bool mutual;
  CardInfo(
      {required this.avatarUrl,
      required this.cityName,
      required this.dateOfBirth,
      required this.firstName,
      required this.aboutMe,
      required this.id,
      required this.isFavorite,
      required this.matchPercentage,
      required this.mutual,
      required this.status});
}
