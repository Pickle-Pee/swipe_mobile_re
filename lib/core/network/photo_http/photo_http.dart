import 'package:dio/dio.dart';
import 'package:swipe_mobile_re/core/config/config.dart';
import 'package:swipe_mobile_re/core/network/dio_interceptors.dart';
import 'package:swipe_mobile_re/data/repositories/profile/profile.dart';

class PhotoHttp {
  late Dio dio;
  PhotoHttp() {
    dio = Dio();
    dio.interceptors.add(SwipeInterceptor(dio));
  }

  Future<List<Photo>> getUserPhoto() async {
    try {
      Response response = await dio.get(
        "${AppConfig.baseAppUrl}/user/user/photos",
      );

      final result = response.data;
      List<dynamic> list = result["photos"];
      List<Photo> photos = list.map((photo) {
        return Photo(
          id: photo["id"],
          isAvatar: photo["is_avatar"],
          photoUrl: photo["photo_url"],
          scale: photo["scale"] ?? 1.0,
          positionX: photo["position_x"] ?? 0.0,
          positionY: photo["position_y"] ?? 0.0,
        );
      }).toList();
      return photos;
    } catch (e) {
      return [];
    }
  }

  Future<List<Photo>> getUserPhotos(int userId) async {
    try {
      Response response = await dio.get(
        "${AppConfig.baseAppUrl}/user/user/photos/$userId",
      );

      final result = response.data;
      List<dynamic> list = result["photos"];
      List<Photo> photos = list.map((photo) {
        return Photo(
          id: photo["id"],
          isAvatar: photo["is_avatar"],
          photoUrl: photo["photo_url"],
          scale: photo["scale"] ?? 1.0,
          positionX: photo["position_x"] ?? 0.0,
          positionY: photo["position_y"] ?? 0.0,
        );
      }).toList();
      return photos;
    } catch (e) {
      print('Ошибка при загрузке фотографий пользователя $userId: $e');
      return [];
    }
  }

  Future<int> uploadUserPhoto(
    FormData formData,
    bool isAvatar,
    Function(int, int) progress,
    double scale,
    double positionX,
    double positionY,
  ) async {
    try {
      // Формирование строки запроса с параметрами
      String url = "${AppConfig.baseAppUrl}/service/upload/profile_photo?"
          "is_avatar=$isAvatar"
          "&scale=${scale.toString()}"
          "&position_x=${positionX.toString()}"
          "&position_y=${positionY.toString()}";

      // Отправка запроса
      await dio.post(
        url,
        data: formData,
        onReceiveProgress: (count, total) {},
        onSendProgress: (count, total) {
          progress(count, total);
        },
      );

      return 0;
    } catch (e) {
      print("Error during upload: $e");
      return -1;
    }
  }

  Future<int> uploadVerifyPhoto(FormData formData) async {
    try {
      //Response response =
      await dio.post(
        "${AppConfig.baseAppUrl}/auth/upload_verify_photos",
        data: formData,
      );

      //final result=response.data;
      //print(result);
      return 0;
    } catch (e) {
      //print(e);
      return -1;
    }
  }

  // Метод для установки фото как аватара
  Future<int> setAvatar(int photoId) async {
    try {
      Response response = await dio.post(
        "${AppConfig.baseAppUrl}/user/set_avatar/$photoId",
      );

      if (response.statusCode == 200) {
        print("Аватар успешно установлен");
        return 0;
      } else {
        print("Ошибка при установке аватара: ${response.statusMessage}");
        return -1;
      }
    } catch (e) {
      print("Error during set avatar: $e");
      return -1;
    }
  }

  // Метод для удаления фото
  Future<int> deletePhoto(int photoId) async {
    try {
      Response response = await dio.delete(
        "${AppConfig.baseAppUrl}/user/photos/$photoId",
      );

      if (response.statusCode == 204) {
        print("Фото успешно удалено");
        return 0;
      } else {
        print("Ошибка при удалении фото: ${response.statusMessage}");
        return -1;
      }
    } catch (e) {
      print("Error during photo deletion: $e");
      return -1;
    }
  }
}
