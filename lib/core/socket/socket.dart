// socket.dart

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:swipe_mobile_re/app/providers/navigation_events_provider.dart';
import 'package:swipe_mobile_re/core/config/config.dart';
import 'package:swipe_mobile_re/core/network/user/user_http.dart';
import 'package:swipe_mobile_re/core/storage/token_storage.dart';
import 'package:swipe_mobile_re/data/repositories/chat/chat_repo.dart';
import 'package:swipe_mobile_re/data/repositories/chat/message.dart';
import 'package:swipe_mobile_re/data/repositories/profile/profile.dart';


class AppSocket {
  static const status_mapping = {
    'sent': 0,
    'delivered': 1,
    'read': 2,
    'sending': -1,
  };


  final NavigationEvents navigationEvents;

  factory AppSocket(NavigationEvents navigationEvents) {
    return AppSocket._internal(navigationEvents);
  }

  // Приватный конструктор
  AppSocket._internal(this.navigationEvents);

  int _parseStatus(dynamic status) {
    if (status is int) {
      return status;
    } else if (status is String) {
      switch (status.toLowerCase()) {
        case 'sent':
          return 0;
        case 'delivered':
          return 1;
        case 'read':
          return 2;
        default:
          return 0; // Значение по умолчанию для неизвестных статусов
      }
    } else {
      return 0; // Значение по умолчанию
    }
  }

  bool _isInitialized = false;
  bool _isListenersSetup = false;

  IO.Socket? _socket;
  bool chatsLoaded = false;

  IO.Socket? get socket => _socket;

  /// Функция для парсинга даты и времени из строки в локальное время
  DateTime? parseUtcDateTime(String? dateString) {
    if (dateString == null) return null;

    try {
      // 1. Парсим ISO-строку
      DateTime dateTime = DateTime.parse(dateString);

      // 2. Если вы уверены, что это UTC (или без таймзоны),
      //    приводим к UTC:
      dateTime = dateTime.toUtc();

      // 3. Потом делаем toLocal()
      return dateTime.toLocal();
    } catch (e) {
      print("Error parsing date: $e");
      return null;
    }
  }

  /// Инициализация подключения к сокету
  void connect() async {
    if (_isInitialized) {
      print("Socket уже инициализирован.");
      if (_socket != null && !_socket!.connected) {
        _socket!.connect();
      }
      return;
    }

    try {
      _initializeSocket();
      _setupSocketListeners();
      _isInitialized = true;
      _socket!.connect();
    } catch (e) {
      print("Socket connection error: $e");
    }
  }

  /// Настройка параметров сокета
  void _initializeSocket() {
    if (_socket != null) {
      print("Socket уже инициализирован.");
      return;
    }

    _socket = IO.io(
      AppConfig.baseAppSocketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection() // Включаем автоматическое переподключение
          .setReconnectionDelay(
              2000) // Задержка между попытками в миллисекундах
          .disableAutoConnect()
          .build(),
    );
  }

  /// Настройка слушателей событий сокета
  void _setupSocketListeners() {
    if (_isListenersSetup) {
      print("Слушатели событий уже настроены.");
      return;
    }

    _socket!.on('connect', _onConnect);
    _socket!.on('auth_response', _onAuthResponse);
    _socket!.on('verification_update', _handleVerificationStatusUpdate);
    _socket!.on('disconnect', _onDisconnect);
    _socket!.on('connect_error', _onConnectError);
    _socket!.on('reconnect', _onReconnect);
    _socket!.on('reconnect_attempt', _onReconnectAttempt);
    _socket!.on('new_message', _handleNewMessageEvent);
    _socket!.on('message_status_update', _handleMessageStatusUpdateEvent);
    _socket!.on('completer', _handleCompleterEvent);
    _socket!.on('get_messages', _handleGetMessagesEvent);
    _socket!.on('delete_chat', _handleDeleteChatEvent);
    _socket!.on('all_messages_read', _handleAllMessagesReadEvent);

    // Используем onAny только для логирования непойманных событий
    _socket!.onAny((event, data) {
      // Исключаем события, уже обработанные специфическими обработчиками
      if (![
        "completer",
        "new_message",
        "message_status_update",
        "get_messages",
        "delete_chat",
        "all_messages_read",
        "message_read",
        "message_delivered",
        "read_messages"
      ].contains(event)) {
        print("Socket Event: $event /// Data: $data");
        // Обработка других событий при необходимости
      }
    });

    _isListenersSetup = true;
    print("Слушатели событий настроены.");
  }

  /// Обработчик события подключения сокета
  Future<void> _onConnect(_) async {
    print("Socket connected. Authenticating...");
    await _authenticateSocket();
  }

  /// Метод для аутентификации сокета
  Future<void> _authenticateSocket() async {
    String? accessToken = await TokenStorage().getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      print("No access token found. Redirecting to AuthPage.");
      navigationEvents.navigate('/auth');
      return;
    }

    Map<String, dynamic> data = {"token": accessToken};
    _socket?.emit("authenticate", data);
  }

  /// Обработчик ответа на аутентификацию
  Future<void> _onAuthResponse(dynamic data) async {
    int status = data["status"];
    if (status == 401) {
      print("Authentication failed. Attempting to refresh token.");
      int result = await UserHttp().refresh();
      print("Refresh token result: $result");
      if (result == 0) {
        await _authenticateSocket();
      } else {
        print("Failed to refresh token. Redirecting to AuthPage.");
        navigationEvents.navigate('/auth');
      }
    } else {
      print("Authentication successful.");
      if (chatsLoaded == false) {
        chatsLoaded = true;
        chatStore.getChats();
      }
    }
  }

  /// Обработчик события отключения сокета
  void _onDisconnect(_) {
    print("Socket disconnected.");
    // Не вызываем _socket!.connect(), так как автоматическое переподключение уже настроено
  }

  /// Обработчик ошибки подключения
  void _onConnectError(dynamic error) {
    print("Socket connection error: $error");
  }

  /// Обработчик события успешного переподключения
  void _onReconnect(_) {
    print("Socket reconnected. Re-authenticating...");
    _authenticateSocket();
  }

  /// Обработчик попытки переподключения
  void _onReconnectAttempt(dynamic attempt) {
    print("Attempting to reconnect... (Attempt: $attempt)");
  }

  /// Обработчик обновления статуса верификации
  Future<void> _handleVerificationStatusUpdate(dynamic data) async {
    int userId = data['user_id'];
    String status = data['status'];

    String currentUserId = await _getCurrentUserId();

    if (userId.toString() == currentUserId) {
      if (status == 'approved') {
        print('Verification approved');
        navigationEvents.navigate('/tab');
      } else if (status == 'denied') {
        print('Verification denied');
        navigationEvents.navigate('/verification_failed');
      }
    }
  }

  /// Обработчик события подтверждения отправки сообщения
  Future<void> _handleCompleterEvent(dynamic data) async {
    print("[_handleCompleterEvent] data=$data");

    final int status = data["status"];
    final int chatId = data["chat_id"];
    final String localId = data["external_message_id"];
    final int id = data["id"];
    final String? createdAtStr = data["created_at"];
    final DateTime? createdAt = parseUtcDateTime(createdAtStr);

    print("[_handleCompleterEvent] chatId=$chatId, localId=$localId, "
        "id=$id, status=$status, createdAt=$createdAt");

    // Обновляем
    chatStore.updateStatus(chatId, status, localId, id, createdAt);

    // Если нужно, меняем chatId, если оно было -1 (временное)
    chatStore.updateChatId(localId, chatId);

    print(
        "[_handleCompleterEvent] after updateStatus/updateChatId, chat $chatId now has messages:");
    final chat = chatStore.chats[chatId];
    if (chat != null) {
      for (var i = 0; i < chat.messages.length; i++) {
        final m = chat.messages[i];
        print(
            "   index=$i -> id=${m.id}, localId=${m.localId}, status=${m.status}");
      }
    }
  }

  /// Обработчик события удаления чата
  void _handleDeleteChatEvent(dynamic data) {
    int chatId = data['chat_id'];
    print("Handling delete_chat event for chat ID: $chatId");

    // Удаляем чат из локального хранилища
    chatStore.deleteChat(chatId);
  }

  /// Обработчик события получения нового сообщения
  void _handleNewMessageEvent(dynamic data) {
    print("[_handleNewMessageEvent] data=$data");

    final int chatId = data["chat_id"];
    final int id = data["message_id"];
    final int senderId = data["sender_id"];
    final String? extMsgId = data["external_message_id"];
    final String content = data["message"] ?? "<no content>";
    final String? createdAtStr = data["created_at"];
    final DateTime? createdAt = parseUtcDateTime(createdAtStr);

    final int status = data["status"] ?? 1; // default delivered=1

    print("[_handleNewMessageEvent] chatId=$chatId, id=$id, "
        "senderId=$senderId, extMsgId=$extMsgId, content=$content, status=$status");

    // Создаем сообщение
    final mess = Message(
      chatId: chatId,
      id: id,
      senderId: senderId,
      content: content,
      status: status,
      localId: extMsgId,
      createdAt: createdAt,
      replyMessageId: data["reply_message_id"],
      // и т. д.
    );

    // Добавляем
    print(
        "[_handleNewMessageEvent] Will call addMessage with localId=$extMsgId");
    chatStore.addMessage(mess, caller: "_handleNewMessageEvent");

    print("[_handleNewMessageEvent] -> messageDelivered for message $id");
    messageDelivered([id]);

    // Проверяем, если это чужое сообщение, возможно сразу read
    final currentUserId = profileStore.userInfo?.id;
    if (senderId != currentUserId) {
      if (chatStore.chatIdUsed == chatId) {
        print(
            "[_handleNewMessageEvent] chatIdUsed=$chatId => auto read message $id");
        sendMessageRead([id]);
        chatStore.updateMessageStatus(id, 2, null, DateTime.now().toLocal());
      } else {
        print("[_handleNewMessageEvent] chatIdUsed != $chatId => keep unread");
      }
    } else {
      print(
          "[_handleNewMessageEvent] This message is from current user => ignoring read logic");
    }
  }

  void _handleAllMessagesReadEvent(dynamic data) {
    print("Handling all_messages_read event with data: $data");
    try {
      int chatId = data["chat_id"];
      String? readAtStr = data["read_at"];
      DateTime? readAt = parseUtcDateTime(readAtStr);

      final chat = chatStore.chats[chatId];
      if (chat != null) {
        for (var message in chat.messages) {
          if (message.senderId == profileStore.userInfo?.id &&
              message.status < 2) {
            message.status = 2;
            message.readAt = readAt;
          }
        }
      }
    } catch (e) {
      print("Error handling all_messages_read event: $e");
    }
  }

  /// Обработчик события обновления статуса сообщения
  void _handleMessageStatusUpdateEvent(dynamic data) {
    print("Handling message_status_update event with data: $data");
    try {
      final dynamic messageIdRaw = data["message_id"];
      final dynamic statusRaw = data["status"];
      final String? deliveredAtStr = data["delivered_at"];
      final String? readAtStr = data["read_at"];

      // Парсим deliveredAt / readAt, если есть
      final DateTime? deliveredAt =
          deliveredAtStr != null ? parseUtcDateTime(deliveredAtStr) : null;
      final DateTime? readAt =
          readAtStr != null ? parseUtcDateTime(readAtStr) : null;

      // Получаем messageId как int
      int messageId;
      if (messageIdRaw is int) {
        messageId = messageIdRaw;
      } else if (messageIdRaw is String) {
        messageId = int.tryParse(messageIdRaw) ?? 0;
      } else {
        throw Exception("Invalid type for message_id");
      }

      // Парсим статус (sent=0, delivered=1, read=2)
      int status = _parseStatus(statusRaw);

      // Для наглядности — выведем, какую иконку стоит показать
      if (status == 0) {
        print(
            "message_status_update: message ID $messageId => status=0 (sent). Иконка: Icons.access_time");
      } else if (status == 1) {
        print(
            "message_status_update: message ID $messageId => status=1 (delivered). Иконка: Icons.check");
      } else if (status == 2) {
        print(
            "message_status_update: message ID $messageId => status=2 (read). Иконка: Icons.done_all");
      } else {
        print(
            "message_status_update: message ID $messageId => статус неизвестен. Иконка: Icons.access_time");
      }

      print(
          "Received message_status_update for message ID $messageId with status $status");

      // Вызываем обновление статуса в ChatStore
      // (учтёт, если новый статус > старого)
      chatStore.updateMessageStatus(messageId, status, deliveredAt, readAt);
    } catch (e) {
      print("Error handling message_status_update event: $e");
    }
  }

  /// Обработчик получения сообщений чата
  void _handleGetMessagesEvent(dynamic data) {
    print("Socket Event: get_messages /// Data: $data");
    try {
      final chatId = data["chatId"] as int;
      final messagesData = data["messages"] as List<dynamic>;
      print("Received messages: $messagesData");

      // Преобразуем List<dynamic> в List<Map<String, dynamic>>
      List<Map<String, dynamic>> messages =
          List<Map<String, dynamic>>.from(messagesData);

      chatStore.addMessages(chatId, messages);
    } catch (e) {
      print("Error handling get_messages: $e");
    }
  }

  /// Метод для отправки сообщения
  void sendMessage(Message message) {
    final data = {
      if (message.chatId != null) 'chat_id': message.chatId,
      'message': message.content,
      'external_message_id': message.localId,
      'message_type': message.messageType,
      if (message.chatId == null && message.recipientId != null)
        'recipient_id': message.recipientId, // Добавлено
    };
    _socket?.emit('send_message', data);
    print("Sent send_message event with data: $data");
  }

  /// Метод для пометки сообщений как прочитанных
  void readMessages(int chatId) {
    if (_socket == null || !_socket!.connected) {
      print("Socket is not connected. Unable to mark messages as read.");
      return;
    }
    final chat = chatStore.chats[chatId];
    if (chat != null) {
      List<int> messageIds = chat.messages
          .where((message) =>
              message.senderId != profileStore.userInfo!.id &&
              message.status != 2)
          .map((message) => message.id)
          .toList();
      if (messageIds.isNotEmpty) {
        sendMessageRead(messageIds);
      }
    }
  }

  // Метод для удаления чата
  void deleteChat(int chatId, {bool deleteForBoth = false}) {
    if (_socket == null || !_socket!.connected) {
      print("Socket is not connected. Unable to delete chat.");
      return;
    }

    // Формируем данные для удаления чата
    Map<String, dynamic> data = {
      "chat_id": chatId,
      "delete_for_both": deleteForBoth,
    };

    // Отправляем событие на удаление чата через сокет
    _socket?.emit("delete_chat", data);
    print("Sent delete_chat event with data: $data");
  }

  /// Метод для получения сообщений в чате
  void getMessagesInChat(int chatId) {
    if (_socket == null || !_socket!.connected) {
      print("Socket is not connected. Unable to get messages.");
      return;
    }
    Map<String, dynamic> data = {
      "chat_id": chatId,
    };
    print("Sent get_messages event with data: $data");
    _socket?.emit("get_messages", data);
  }

  /// Метод для отправки подтверждения доставки сообщений
  void messageDelivered(List<int> messageIds) {
    if (_socket == null || !_socket!.connected) {
      print("Socket is not connected. Unable to send message delivered event.");
      return;
    }
    Map<String, dynamic> data = {
      "message_ids": messageIds,
    };
    _socket?.emit("message_delivered", data);
    print("Sent message_delivered event with data: $data");
  }

  /// Метод для отправки подтверждения прочтения сообщений
  void sendMessageRead(List<int> messageIds) {
    if (_socket == null || !_socket!.connected) {
      print("Socket is not connected. Unable to send message_read event.");
      return;
    }
    Map<String, dynamic> data = {
      "message_ids": messageIds,
    };
    _socket?.emit("message_read", data);
    print("Sent message_read event with data: $data");
  }

  /// Получение текущего ID пользователя
  Future<String> _getCurrentUserId() async {
    final UserInfo? userInfo = await UserHttp().getMeInfo();
    return userInfo?.id.toString() ?? "0";
  }

  /// Отключение и очистка сокета
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isInitialized = false;
      _isListenersSetup = false;
      chatsLoaded = false; // Сбрасываем флаг загрузки чатов
      print("Socket disconnected and disposed.");
    }
  }
}

// Инициализируем AppSocket как Singleton
late final AppSocket appSocket;

void initializeAppSocket(NavigationEvents navigationEvents) {
  appSocket = AppSocket(navigationEvents);
}
