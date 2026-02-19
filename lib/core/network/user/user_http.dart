import 'package:dio/dio.dart';
import 'package:swipe_mobile_re/core/config/config.dart';
import 'package:swipe_mobile_re/core/network/dio_interceptors.dart';
import 'package:swipe_mobile_re/core/storage/token_storage.dart';
import 'package:swipe_mobile_re/data/models/attributes_response_user.dart';

class UserHttp {
  // Singleton instance
  static final UserHttp _instance = UserHttp._internal();
  factory UserHttp() => _instance;

  late Dio dio;

  UserHttp._internal() {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseAppUrl,
      connectTimeout: Duration(milliseconds: 5000),
      receiveTimeout: Duration(milliseconds: 3000),
    ));
    dio.interceptors.add(SwipeInterceptor(dio));
  }

  Future<AttributesResponseUser?> getUserAttributes() async {
    try {
      Response response = await dio.get("/attributes/user_attributes");
      if (response.statusCode == 200) {
        return AttributesResponseUser.fromJson(response.data);
      } else if (response.statusCode == 404) {
        // Атрибуты не найдены
        return null;
      } else {
        print("Unexpected status code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching user attributes: $e");
      return null;
    }
  }

  Future<int> addUserAttributes(AttributesResponseUser attributes) async {
    try {
      Map<String, dynamic> data = attributes.toJson();
      Response response =
          await dio.post("/attributes/add_attributes", data: data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return 0;
      } else {
        print("Unexpected status code: ${response.statusCode}");
        return -1;
      }
    } catch (e) {
      print("Error adding user attributes: $e");
      return -1;
    }
  }

  Future<int> updateUserAttributes(AttributesResponseUser attributes) async {
    try {
      Map<String, dynamic> data = attributes.toJson();
      Response response =
          await dio.put("/attributes/update_attributes", data: data);
      if (response.statusCode == 200) {
        return 0;
      } else {
        print("Unexpected status code: ${response.statusCode}");
        return -1;
      }
    } catch (e) {
      print("Error updating user attributes: $e");
      return -1;
    }
  }

  Future<int> setUserGeo(double lat, double lon) async {
    try {
      await dio.post("/user/add_geolocation", data: {
        "latitude": lat,
        "longitude": lon,
      });
      return 0;
    } catch (e) {
      print("Error setting user geo: $e");
      return -1;
    }
  }

  Future<int> setUserInterest(List<int> interests) async {
    try {
      await dio
          .post("/interest/add_interests", data: {"interest_ids": interests});
      return 0;
    } catch (e) {
      print("Error setting user interests: $e");
      return -1;
    }
  }

  Future<List<Interest>> getUserInterest() async {
    try {
      Response response = await dio.get("/interest/user_interests");
      final result = response.data;
      List<dynamic> list = result["interests"];
      if (list.isEmpty) {
        return [];
      }
      List<Interest> userInterests =
          list.map((json) => Interest.fromJson(json)).toList();
      return userInterests;
    } catch (e) {
      print("Error fetching user interests: $e");
      return [];
    }
  }

  Future<List<Interest>> getListInterests() async {
    try {
      Response response = await dio.get("/interest/interests_list");
      final result = response.data;
      List<dynamic> list = result["interests"];
      return list.map((el) => Interest.fromJson(el)).toList();
    } catch (e) {
      print("Error fetching interests list: $e");
      return [];
    }
  }

  Future<int> editVerify(int userId) async {
    try {
      await dio.put("/service/verify/$userId", data: {"status": "approved"});
      return 0;
    } catch (e) {
      print("Error editing verify: $e");
      return -1;
    }
  }

  Future<int> getMeUserId() async {
    try {
      Response response = await dio.get("/auth/whoami");
      final result = response.data;
      return result["id"];
    } catch (e) {
      print("Error getting user ID: $e");
      return -1;
    }
  }

  Future<String> checkVerify() async {
    try {
      Response response = await dio.get("/user/verify/check_verify");
      String result = response.data["verify"];

      if (result.contains('.')) {
        result = result.split('.').last;
      }

      // Переводим в нижний регистр
      result = result.toLowerCase();
      print("result: $result");

      return result;
    } catch (e) {
      print("Error checking verify: $e");
      return "error";
    }
  }

  Future<List<String>> getCities(String city) async {
    try {
      print("start");
      Response response =
          await dio.get("/service/cities", queryParameters: {"query": city});
      print("end");
      List<dynamic> result = response.data;
      return result.map((element) => element as String).toList();
    } catch (e) {
      print("Error getting cities: $e");
      return [];
    }
  }

  Future<int> registration(Map<String, dynamic> data) async {
    try {
      Response response = await dio.post("/auth/register", data: data);
      final result = response.data;

      // Удаляем 'Bearer ' из токенов перед сохранением
      String? accessToken = result["access_token"];
      String? refreshToken = result["refresh_token"];

      if (accessToken != null && accessToken.startsWith('Bearer ')) {
        accessToken = accessToken.substring(7);
      }

      await TokenStorage().setAccessToken(accessToken ?? "");
      await TokenStorage().setRefreshToken(refreshToken ?? "");
      return 0;
    } catch (e) {
      print("Error during registration: $e");
      return -1;
    }
  }

  Future<int> checkOTP(String phoneNumber, String otp) async {
    try {
      await dio.post("/auth/check_code", queryParameters: {
        "phone_number": phoneNumber,
        "verification_code": otp
      });
      return 0;
    } catch (e) {
      print("Error checking OTP: $e");
      return -1;
    }
  }

  Future<int> checkPhonForReg(String phoneNumber) async {
    try {
      Response response = await dio.post("/auth/check_phone",
          queryParameters: {"phone_number": phoneNumber});
      print("Response data: ${response.data}");
      final result = response.data;
      if (result['code'] == 667) {
        return 667;
      } else if (result['code'] == 612) {
        return 612;
      } else if (result['code'] == 0) {
        return 0;
      }
      return -1;
    } on DioException catch (e) {
      print("DioException: $e");
      if (e.response?.statusCode == 400) {
        final errorResponse = e.response?.data;
        if (errorResponse != null && errorResponse['code'] == 667) {
          return 667;
        } else if (errorResponse != null && errorResponse['code'] == 612) {
          return 612;
        }
      }
      return -1;
    } catch (e) {
      print("Exception: $e");
      return -1;
    }
  }

  Future<int> sendOTP(String phoneNumber) async {
    try {
      await dio.post("/auth/send_code",
          queryParameters: {"phone_number": phoneNumber});
      return 0;
    } catch (e) {
      print("Error sending OTP: $e");
      return -1;
    }
  }

  Future<int> login(String phoneNumber, String code) async {
    try {
      Response response = await dio.post(
        "/auth/login",
        queryParameters: {"phone_number": phoneNumber, "code": code},
      );
      final result = response.data;

      // Удаляем 'Bearer ' из токенов перед сохранением
      String? accessToken = result["access_token"];
      String? refreshToken = result["refresh_token"];

      if (accessToken != null && accessToken.startsWith('Bearer ')) {
        accessToken = accessToken.substring(7);
      }

      await TokenStorage().setAccessToken(accessToken ?? "");
      await TokenStorage().setRefreshToken(refreshToken ?? "");
      return 0;
    } catch (e) {
      print("Error during login: $e");
      return -1;
    }
  }

  Future<int> refresh() async {
    try {
      print("startRE#F");
      final String? token = await TokenStorage().getRefreshToken();
      if (token == null || token.isEmpty) {
        print("Invalid refresh token.");
        return -1;
      }
      Response response = await dio.post(
        "/auth/refresh_token",
        queryParameters: {"refresh_token": token},
        options: Options(receiveTimeout: Duration(milliseconds: 5000)),
      );
      print("endRE#F");
      print(response.data);

      // Удаляем 'Bearer ' из токенов перед сохранением
      String? newAccessToken = response.data["access_token"];
      String? newRefreshToken = response.data["refresh_token"];

      if (newAccessToken != null && newAccessToken.startsWith('Bearer ')) {
        newAccessToken = newAccessToken.substring(7);
      }

      await TokenStorage().setAccessToken(newAccessToken ?? "");
      await TokenStorage().setRefreshToken(newRefreshToken ?? "");
      return 0;
    } catch (e) {
      print("Error refreshing token: $e");
      return -1;
    }
  }

  Future<int> updateFcmToken(String token) async {
    try {
      Response response = await dio
          .post("/communication/update_fcm_token", data: {"token": token});
      print("FCM-токен успешно отправлен на сервер: ${response.data}");
      return 0;
    } catch (e) {
      print("Ошибка при отправке FCM-токена на сервер: $e");
      return -1;
    }
  }

  Future<UserInfo?> getUserInfo(int userId) async {
    try {
      Response response = await dio.get("/user/$userId");
      final res = response.data;

      AttributesResponseUser? attributes;
      if (res["attributes"] != null) {
        attributes = AttributesResponseUser.fromJson(res["attributes"]);
      }

      UserInfo userInfo = UserInfo(
        aboutMe: res["about_me"] ?? "",
        avatarUrl: res["avatar_url"] ?? "",
        cityName: res["city_name"] ?? "",
        dateOfBirth: res["date_of_birth"] ?? "",
        firstName: res["first_name"] ?? "",
        gender: res["gender"] ?? "",
        id: res["id"],
        interest: (() {
          List<dynamic> list = res["interests"] ?? [];
          return list.map((element) {
            return Interest(
              interestId: element["interest_id"] ?? 0,
              interestText: element["interest_text"] ?? "",
            );
          }).toList();
        })(),
        isFavorite: res["is_favorite"] ?? false,
        isSubscription: res["is_subscription"] ?? false,
        lastName: res["last_name"] ?? "",
        matchPercentage: (res["match_percentage"] as num?)?.toDouble() ?? 0.0,
        status: res["status"] ?? "",
        verify: res["verify"],
        attributes: attributes,
      );
      return userInfo;
    } catch (e) {
      print("Error getting user info: $e");
      return null;
    }
  }

  Future<int> updateMeInfo(UserInfo userInfo) async {
    try {
      Map<String, dynamic> data = {
        "first_name": userInfo.firstName,
        "date_of_birth": userInfo.dateOfBirth,
        "gender": userInfo.gender,
        "city_name": userInfo.cityName,
        "about_me": userInfo.aboutMe,
      };

      Response response = await dio.put("/user/update_user", data: data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("User info updated successfully.");
        return 0;
      } else {
        print("Unexpected status code: ${response.statusCode}");
        print("Response data: ${response.data}");
        return -1;
      }
    } on DioException catch (e) {
      print("DioException: $e");
      if (e.response != null) {
        print("Response data: ${e.response?.data}");
      }
      return -1;
    } catch (e) {
      print("Error updating user info: $e");
      return -1;
    }
  }

  Future<UserInfo?> getMeInfo() async {
    try {
      Response response = await dio.get("/user/me");
      final res = response.data;

      print('Server Response: $res');

      UserInfo userInfo = UserInfo.fromJson(res);
      return userInfo;
    } catch (e) {
      print('Error in getMeInfo: $e');
      return null;
    }
  }

  Future<int> deleteUser() async {
    try {
      await dio.delete("/user/delete_user");
      return 0;
    } catch (e) {
      print("Error deleting user: $e");
      return -1;
    }
  }

  Future<bool> checkSubscription() async {
    try {
      UserInfo? me = await getMeInfo();
      return me?.isSubscription ?? false;
    } catch (e) {
      print("Error checking subscription: $e");
      return false;
    }
  }
}

class UserInfo {
  int id;
  String firstName;
  String lastName;
  String dateOfBirth;
  String gender;
  bool isSubscription;
  String cityName;
  bool isFavorite;
  String aboutMe;
  String status;
  String? avatarUrl; // Сделаем nullable
  List<Interest> interest;
  double matchPercentage;
  String? verify;
  AttributesResponseUser? attributes;

  UserInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.isSubscription,
    required this.cityName,
    required this.isFavorite,
    required this.aboutMe,
    required this.status,
    this.avatarUrl, // nullable
    required this.interest,
    required this.matchPercentage,
    this.verify,
    this.attributes,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      gender: json['gender'] ?? '',
      isSubscription: json['is_subscription'] ?? false,
      cityName: json['city_name'] ?? '',
      isFavorite: json['is_favorite'] ?? false,
      aboutMe: json['about_me'] ?? '',
      status: json['status'] ?? '',
      avatarUrl: json['avatar_url'], // теперь может быть null
      interest: (json['interests'] as List<dynamic>?)
              ?.map((e) => Interest.fromJson(e))
              .toList() ??
          [],
      matchPercentage: (json['match_percentage'] as num?)?.toDouble() ?? 0.0,
      verify: json['verify'],
      attributes: json['attributes'] != null
          ? AttributesResponseUser.fromJson(json['attributes'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "first_name": firstName,
      "last_name": lastName,
      "date_of_birth": dateOfBirth,
      "gender": gender,
      "city_name": cityName,
      "about_me": aboutMe,
    };
  }
}

class Interest {
  final int interestId;
  final String interestText;

  Interest({required this.interestId, required this.interestText});

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      interestId: json['id'] ?? json['interest_id'], // Обработка разных ключей
      interestText: json['interest_text'] ?? json['interestText'],
    );
  }
}
