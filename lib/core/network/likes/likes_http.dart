import 'package:dio/dio.dart';
import 'package:swipe_mobile_re/core/config/config.dart';
import 'package:swipe_mobile_re/core/network/dio_interceptors.dart';
import 'package:swipe_mobile_re/data/repositories/likes/likes_repo.dart';

class LikesHttp {
  Dio dio = Dio();
  LikesHttp() {
    dio.interceptors.add(SwipeInterceptor(dio));
  }

  Future<dynamic> getListMeLiked() async {
    try {
      Response response =
          await dio.get("${AppConfig.baseAppUrl}/likes/liked_me");
      //print(response);
      List<dynamic> list = response.data;
      List<CardInfo> listCardInfo = [];
      listCardInfo = list.map((element) {
        return CardInfo(
            avatarUrl: element["avatar_url"],
            cityName: element["city_name"],
            dateOfBirth: element["date_of_birth"],
            firstName: element["first_name"],
            aboutMe: element["about_me"],
            id: element["id"],
            isFavorite: element["is_favorite"] ?? false,
            matchPercentage: element["match_percentage"] ?? 0,
            mutual: element["mutual"] ?? false,
            status: element["status"] ?? "status");
      }).toList();
      return listCardInfo;
    } catch (e) {
      //(e);
      return null;
    }
  }

  Future<dynamic> getListFavorite() async {
    try {
      Response response =
          await dio.get("${AppConfig.baseAppUrl}/likes/favorites");
      //print(response);
      List<dynamic> list = response.data;
      List<CardInfo> listCardInfo = [];
      listCardInfo = list.map((element) {
        return CardInfo(
            avatarUrl: element["avatar_url"],
            cityName: element["city_name"],
            dateOfBirth: element["date_of_birth"],
            firstName: element["first_name"],
            aboutMe: element["about_me"],
            id: element["id"],
            isFavorite: element["is_favorite"] ?? false,
            matchPercentage: element["match_percentage"] ?? 0,
            mutual: element["mutual"] ?? false,
            status: element["status"] ?? "status");
      }).toList();
      return listCardInfo;
    } catch (e) {
      //print(e);
      return null;
    }
  }

  Future<List<CardInfo>?> getListLikes() async {
    try {
      Response response =
          await dio.get("${AppConfig.baseAppUrl}/likes/liked_users");
      print(response);
      List<dynamic> list = response.data;
      List<CardInfo> listCardInfo = [];
      listCardInfo = list.map((element) {
        return CardInfo(
            avatarUrl: element["avatar_url"],
            cityName: element["city_name"],
            dateOfBirth: element["date_of_birth"],
            firstName: element["first_name"],
            aboutMe: element["about_me"],
            id: element["id"],
            isFavorite: element["is_favorite"] ?? false,
            matchPercentage: element["match_percentage"] ?? 0,
            mutual: element["mutual"] ?? false,
            status: element["status"] ?? "status");
      }).toList();
      return listCardInfo;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
