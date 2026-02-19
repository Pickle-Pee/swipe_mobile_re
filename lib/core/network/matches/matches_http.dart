import 'package:dio/dio.dart';
import 'package:swipe_mobile_re/core/config/config.dart';
import 'package:swipe_mobile_re/core/network/dio_interceptors.dart';

class MatchesHttp {
  Dio dio = Dio();
  MatchesHttp() {
    dio.interceptors.add(SwipeInterceptor(dio));
  }

  Future<List<UserMatchInfo>?> getMatches(
      {Map<String, dynamic>? filters}) async {
    try {
      Map<String, dynamic> queryParameters = {};
      if (filters != null && filters.isNotEmpty) {
        if (filters['city'] != null) {
          queryParameters['city'] = filters['city'];
        }

        // minAge, maxAge, minHeight, maxHeight - это числа, просто передаем их
        if (filters['minAge'] != null) {
          queryParameters['minAge'] = filters['minAge'].toString();
        }
        if (filters['maxAge'] != null) {
          queryParameters['maxAge'] = filters['maxAge'].toString();
        }
        if (filters['minHeight'] != null) {
          queryParameters['minHeight'] = filters['minHeight'].toString();
        }
        if (filters['maxHeight'] != null) {
          queryParameters['maxHeight'] = filters['maxHeight'].toString();
        }

        // Атрибуты - теперь уже строки
        if (filters['smokingAttitude'] != null) {
          queryParameters['smokingAttitude'] = filters['smokingAttitude'];
        }
        if (filters['alcoholAttitude'] != null) {
          queryParameters['alcoholAttitude'] = filters['alcoholAttitude'];
        }
        if (filters['childrenPreference'] != null) {
          queryParameters['childrenPreference'] = filters['childrenPreference'];
        }
        if (filters['whatLookingFor'] != null) {
          queryParameters['whatLookingFor'] = filters['whatLookingFor'];
        }
        if (filters['appearance'] != null) {
          queryParameters['appearance'] = filters['appearance'];
        }
        if (filters['religion'] != null) {
          queryParameters['religion'] = filters['religion'];
        }
      }

      Response response = await dio.get(
        "${AppConfig.baseAppUrl}/match/find_matches",
        queryParameters: queryParameters,
      );
      print(response.data);
      List<dynamic> list = response.data;
      List<UserMatchInfo> listUserMatch = list.map((element) {
        return UserMatchInfo(
          avatarUrl: element["avatar_url"] ?? "",
          cityName: element["city_name"] ?? "Неизвестно",
          dateOfBirth: element["date_of_birth"],
          firstName: element["first_name"],
          gender: element["gender"],
          matchPercentage: (element["match_percentage"] as num).toDouble(),
          status: element["status"] ?? "offline",
          userId: element["user_id"],
          isFavarite: element["is_favorite"] ?? false,
          mutual: element["mutual"] ?? false,
        );
      }).toList();
      return listUserMatch;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<int> like(int userId) async {
    try {
      await dio.post("${AppConfig.baseAppUrl}/likes/like/$userId");
      return 0;
    } catch (e) {
      return -1;
    }
  }

  Future<int> dislike(int userId) async {
    try {
      await dio.post("${AppConfig.baseAppUrl}/likes/dislike/$userId");
      return 0;
    } catch (e) {
      return -1;
    }
  }

  Future<int> addFavorite(int userId) async {
    try {
      Response response = await dio
          .post("${AppConfig.baseAppUrl}/likes/add_to_favorites/$userId");
      print(response.data);
      return 0;
    } catch (e) {
      return -1;
    }
  }

  Future<int> deleteFavorite(int userId) async {
    try {
      Response response = await dio.delete(
          "${AppConfig.baseAppUrl}/likes/remove_from_favorites/$userId");
      print(response.data);
      return 0;
    } catch (e) {
      return -1;
    }
  }
}

class UserMatchInfo {
  int userId;
  String firstName;
  String dateOfBirth;
  String gender;
  String status;
  String cityName;
  String avatarUrl;
  double matchPercentage;
  bool isFavarite;
  bool mutual;
  UserMatchInfo(
      {required this.avatarUrl,
      required this.cityName,
      required this.dateOfBirth,
      required this.firstName,
      required this.gender,
      required this.matchPercentage,
      required this.status,
      required this.userId,
      required this.isFavarite,
      required this.mutual,});
}
