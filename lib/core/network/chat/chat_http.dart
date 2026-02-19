import 'dart:io';

import 'package:dio/dio.dart';
import 'package:swipe_mobile_re/core/config/config.dart';
import 'package:swipe_mobile_re/core/network/dio_interceptors.dart';
import 'package:swipe_mobile_re/data/repositories/chat/chat_info.dart';
import 'package:swipe_mobile_re/data/repositories/chat/chat_repo.dart';
import 'package:swipe_mobile_re/data/repositories/chat/message.dart';


class ChatHttp {
  Dio dio = Dio();
  ChatHttp() {
    dio.interceptors.add(SwipeInterceptor(dio));
  }

  Future<ChatInfo?> getChatInfo(int chatId) async {
    try {
      Response response = await dio.get(
        "${AppConfig.baseAppUrl}/communication/$chatId",
      );
      final data = response.data;
      print(data);

      // Парсим пользователя
      final user = UserInChat(
          avatarUrl: data["avatar_url"],
          firstName: data["first_name"],
          status: data["status"],
          userAge: data["user_age"],
          userId: data["user_id"],
          hasSubscription: data["is_subscription"]);

      // Парсим сообщения
      List<Message> messages = [];
      if (data["messages"] != null) {
        messages = (data["messages"] as List<dynamic>).map((messageData) {
          return Message(
            id: messageData["message_id"],
            chatId: chatId,
            status: 1, // Статус можно определить на основе данных
            content: messageData["message"],
            senderId: messageData["sender_id"],
            createdAt: DateTime.parse(messageData["created_at"]),
            deliveredAt: null,
            readAt: null,
          );
        }).toList();
      }

      final chatInfo = ChatInfo(
        chatId: chatId,
        user: user,
        createdAt: data["created_at"],
        lastMessage: data["last_message"],
        messages: messages, // Передаём список сообщений
        unreadCount: data["unread_count"] ?? 0,
      );

      return chatInfo;
    } catch (e) {
      print("Error in getChatInfo: $e");
      return null;
    }
  }

  Future<int?> getChatIdByUserId(int recipientId) async {
    try {
      final String requestUrl = '/communication/get_chat_id_by_user_id';
      print(
          'Requesting URL: ${AppConfig.baseAppUrl}$requestUrl?recipient_id=$recipientId');

      Response response = await dio.get(
        requestUrl,
        queryParameters: {'recipient_id': recipientId},
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        int chatId = data['chat_id'];
        return chatId;
      } else {
        print('Не удалось получить chat_id: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка при получении chatId по userId: $e');
      return null;
    }
  }

  Future<int> createChat(int userId) async {
    try {
      Response response = await dio.post(
        "${AppConfig.baseAppUrl}/communication/create_chat",
        data: {"user_id": userId},
      );
      final data = response.data;
      int chatId = data["chat_id"];
      print(data);
      return chatId;
    } catch (e) {
      print("Error in createChat: $e");
      return -1;
    }
  }

  Future<List<ChatInfo>> getUserChats() async {
    try {
      Response response =
          await dio.get("${AppConfig.baseAppUrl}/communication/get_chats");
      final data = response.data;
      List<dynamic> list = data;
      List<ChatInfo> userChats = list.map((chat) {
        final userData = chat["user"] ?? {};
        final user = UserInChat(
            avatarUrl: userData["avatar_url"] ?? '',
            firstName: userData["first_name"] ?? 'Unknown',
            status: userData["status"] ?? 'offline',
            userAge: userData["user_age"] ?? 0,
            userId: userData["user_id"] ?? 0,
            hasSubscription: userData["is_subscription"] ?? false);

        // Парсим сообщения
        List<Message> messages = [];
        if (chat["messages"] != null) {
          messages = (chat["messages"] as List<dynamic>).map((messageData) {
            return Message.fromJson(messageData);
          }).toList();
        }

        return ChatInfo(
          chatId: chat["chat_id"] ?? 0,
          createdAt: chat["created_at"] ?? '',
          lastMessage: chat["last_message"] ?? '',
          user: user,
          messages: messages, // Передаём список сообщений
          unreadCount: chat["unread_count"] ?? 0,
        );
      }).toList();
      return userChats;
    } catch (e) {
      print("Error in getUserChats: $e");
      return [];
    }
  }

  Future<String?> uploadMessageImage(int chatId, File imageFile) async {
    try {
      String uploadUrl =
          "${AppConfig.baseAppUrl}/service/upload/message_image/$chatId";

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(imageFile.path,
            filename: imageFile.path.split('/').last),
        // Добавьте другие поля, если необходимо, например, access_token
      });

      Response response = await dio.post(
        uploadUrl,
        data: formData,
        options: Options(
          headers: {
            // Добавьте необходимые заголовки, например, авторизационные токены
            // "Authorization": "Bearer your_access_token",
          },
        ),
        onSendProgress: (int sent, int total) {
          double progress = sent / total;
          print(
              "Загрузка изображения: ${(progress * 100).toStringAsFixed(0)}%");
          // Здесь вы можете обновить UI, например, показать прогресс-бар
        },
      );

      if (response.statusCode == 200) {
        // Предполагаем, что сервер возвращает JSON с полем 'file_key'
        String fileKey = response.data['file_key'];
        // Предполагаем, что URL формируется как BASE_URL + '/uploads/' + file_key
        String fileUrl = "${AppConfig.baseAppUrl}/service/get_file/$fileKey";
        return fileUrl;
      } else {
        print(
            "Не удалось загрузить изображение. Статус: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Ошибка при загрузке изображения: $e");
      return null;
    }
  }

  /// Метод для загрузки голосового сообщения
  Future<String?> uploadMessageVoice(int chatId, File voiceFile) async {
    try {
      String uploadUrl =
          "${AppConfig.baseAppUrl}/service/upload/message_voice/$chatId";

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(voiceFile.path,
            filename: voiceFile.path.split('/').last),
        // Добавьте другие поля, если необходимо, например, access_token
      });

      Response response = await dio.post(
        uploadUrl,
        data: formData,
        options: Options(
          headers: {
            // Добавьте необходимые заголовки, например, авторизационные токены
            // "Authorization": "Bearer your_access_token",
          },
        ),
        onSendProgress: (int sent, int total) {
          double progress = sent / total;
          print(
              "Загрузка голосового сообщения: ${(progress * 100).toStringAsFixed(0)}%");
          // Здесь вы можете обновить UI, например, показать прогресс-бар
        },
      );

      if (response.statusCode == 200) {
        // Предполагаем, что сервер возвращает JSON с полем 'file_key'
        String fileKey = response.data['file_key'];
        // Предполагаем, что URL формируется как BASE_URL + '/uploads/' + file_key
        String fileUrl = "${AppConfig.baseAppUrl}/service/get_file/$fileKey";
        return fileUrl;
      } else {
        print(
            "Не удалось загрузить голосовое сообщение. Статус: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Ошибка при загрузке голосового сообщения: $e");
      return null;
    }
  }
}
