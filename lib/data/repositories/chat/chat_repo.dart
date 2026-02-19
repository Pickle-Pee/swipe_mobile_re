// chat_store.dart


import 'package:collection/collection.dart';
import 'package:mobx/mobx.dart';
import 'package:swipe_mobile_re/core/network/chat/chat_http.dart';
import 'package:swipe_mobile_re/core/socket/socket.dart';
import 'package:swipe_mobile_re/data/repositories/chat/chat_info.dart';
import 'package:swipe_mobile_re/data/repositories/chat/message.dart';
import 'package:swipe_mobile_re/data/repositories/profile/profile.dart';

part 'chat_repo.g.dart';

class ChatStore = _ChatStore with _$ChatStore;

abstract class _ChatStore with Store {
  // Публичный конструктор
  _ChatStore() {
    // Инициализация слушателей сокета
    appSocket.socket?.on('delete_chat', _handleDeleteChatEvent);
  }

  // Единственный экземпляр ChatHttp
  final ChatHttp _chatHttp = ChatHttp();

  @observable
  int? _chatIdUsed;

  @computed
  int? get chatIdUsed => _chatIdUsed;

  @action
  void setChatIdUsed(int? value) {
    print("Setting chatIdUsed to $value");
    _chatIdUsed = value;
  }

  @observable
  ObservableMap<int, ChatInfo> chats = ObservableMap<int, ChatInfo>();

  @observable
  ObservableMap<int, bool> notificationsEnabled = ObservableMap<int, bool>();

  @observable
  Map<String, int> localIdToExternalId = {};

  @action
  bool toggleNotifications(int chatId) {
    if (notificationsEnabled.containsKey(chatId)) {
      notificationsEnabled[chatId] = !notificationsEnabled[chatId]!;
    } else {
      notificationsEnabled[chatId] = false;
    }
    // Логика сохранения состояния
    return notificationsEnabled[chatId]!;
  }

  bool areNotificationsEnabled(int chatId) {
    return notificationsEnabled[chatId] ?? true;
  }

  @action
  Future<int?> createChat(int recipientId) async {
    try {
      final chatId = await _chatHttp.createChat(recipientId);
      if (chatId != null) {
        setChatIdUsed(chatId);
        await getChatInfo(chatId, null);
      }
      return chatId;
    } catch (e) {
      print('Error creating chat: $e');
      return null;
    }
  }

  @action
  void deleteChat(int chatId) {
    chats.remove(chatId);
    print("Chat with ID $chatId deleted from local storage.");
  }

  @action
  void hideChat(int chatId) {
    final chat = chats[chatId];
    if (chat != null) {
      chat.isHidden = true;
      print("Chat with ID $chatId marked as hidden.");
    }
  }

  @action
  Future<void> getChats() async {
    final data = await _chatHttp.getUserChats();
    if (data.isNotEmpty) {
      for (var chatInfo in data) {
        chats[chatInfo.chatId] = chatInfo;
      }
    }
    for (var element in chats.values) {
      appSocket.getMessagesInChat(element.chatId);
    }
  }

  @action
  Future<void> getChatInfo(int chatId, Message? mess) async {
    if (chats.containsKey(chatId)) {
      return;
    }
    final data = await _chatHttp.getChatInfo(chatId);
    if (data != null) {
      if (mess != null) {
        data.messages.add(mess);
      }
      chats[chatId] = data;
      print("Chat with ID $chatId added to chats.");
    }
  }

  @action
  Future<void> sendMessage(Message mess) async {
    print("[sendMessage] START with localId=${mess.localId}, "
        "chatId=${mess.chatId}, content=${mess.content}");

    int? chatId = mess.chatId;
    if (chatId == null || !chats.containsKey(chatId)) {
      print(
          "[sendMessage] Chat $chatId not in store, trying to create chat with recipientId=${mess.recipientId}");
      if (mess.recipientId == null) {
        print("[sendMessage] ERROR: recipientId is null, cannot proceed.");
        return;
      }
      chatId = await createChat(mess.recipientId!);
      if (chatId == null) {
        print(
            "[sendMessage] ERROR: createChat() returned null for recipientId=${mess.recipientId}");
        return;
      }
      mess.chatId = chatId;
    }

    // 1) Оптимистически добавляем
    print("[sendMessage] Calling addMessage for localId=${mess.localId}, "
        "id=${mess.id}, chatId=${mess.chatId}");
    addMessage(mess, caller: "sendMessage");

    // 2) Запоминаем localId
    localIdToExternalId[mess.localId] = -1;

    // 3) Отправляем сокету
    print("[sendMessage] Emitting send_message to socket with "
        "localId=${mess.localId}, chatId=${mess.chatId}");
    appSocket.sendMessage(mess);

    print("[sendMessage] END for localId=${mess.localId}, id=${mess.id}");
  }

  @action
  void updateStatus(int chatId, int status, String externalMessageId, int id,
      DateTime? createdAt) {
    print(
        "[updateStatus] chatId=$chatId, externalMessageId=$externalMessageId, "
        "newID=$id, newStatus=$status, createdAt=$createdAt");

    final ChatInfo? chat = chats[chatId];
    if (chat == null) {
      print("[updateStatus] chat not found for chatId=$chatId");
      return;
    }

    final message =
        chat.messages.firstWhereOrNull((m) => m.localId == externalMessageId);
    if (message == null) {
      print(
          "[updateStatus] message with localId=$externalMessageId not found in chat $chatId!");
      for (var i = 0; i < chat.messages.length; i++) {
        final mm = chat.messages[i];
        print(
            "   index=$i -> id=${mm.id}, localId=${mm.localId}, status=${mm.status}");
      }
      return;
    }

    print(
        "[updateStatus] Found message id=${message.id}, localId=${message.localId}, "
        "oldStatus=${message.status}. Updating...");
    message.status = status;
    message.id = id;
    if (createdAt != null) {
      message.createdAt = createdAt;
      print("[updateStatus] updated createdAt to $createdAt");
    }
  }

  @action
  void addMessage(Message mess, {String caller = ""}) {
    print("[addMessage $caller] Called with id=${mess.id}, "
        "localId=${mess.localId}, chatId=${mess.chatId}, "
        "status=${mess.status}");

    final chatId = mess.chatId;
    if (chatId == null || !chats.containsKey(chatId)) {
      print(
          "[addMessage $caller] ERROR: chatId is null or Chat $chatId not found.");
      return;
    }

    final chat = chats[chatId];
    if (chat == null) {
      print(
          "[addMessage $caller] ERROR: chat object is null for chatId=$chatId.");
      return;
    }

    // Логируем список сообщений до добавления
    print("[addMessage $caller] Before adding, chat $chatId has messages:");
    for (var i = 0; i < chat.messages.length; i++) {
      final m = chat.messages[i];
      print(
          "   index=$i -> id=${m.id}, localId=${m.localId}, status=${m.status}");
    }

    // Проверяем, нет ли такого же localId
    final existingIndex =
        chat.messages.indexWhere((m) => m.localId == mess.localId);
    if (existingIndex != -1) {
      print(
          "[addMessage $caller] Found existing message at index=$existingIndex "
          "with same localId=${mess.localId}. Updating...");
      chat.messages[existingIndex] = mess;
    } else {
      print(
          "[addMessage $caller] localId=${mess.localId} not found. Trying to match by ID...");
      // Если id != -1, тоже можно проверять
      final existingByIdIndex = chat.messages
          .indexWhere((m) => m.id == mess.id && m.id != -1 && mess.id != -1);
      if (existingByIdIndex != -1) {
        print(
            "[addMessage $caller] Found existing message by ID at index=$existingByIdIndex -> id=${mess.id}. Updating...");
        chat.messages[existingByIdIndex] = mess;
      } else {
        print(
            "[addMessage $caller] No existing message found, adding new message to chat $chatId.");
        chat.messages.add(mess);
      }
    }

    // Логируем, что получилось после
    print("[addMessage $caller] After adding, chat $chatId has messages:");
    for (var i = 0; i < chat.messages.length; i++) {
      final m = chat.messages[i];
      print(
          "   index=$i -> id=${m.id}, localId=${m.localId}, status=${m.status}");
    }
  }

  @action
  void _handleDeleteChatEvent(dynamic data) {
    int chatId = data['chat_id'];
    print("Received delete_chat event for chatId: $chatId");

    // Удаляем чат из локального хранилища
    hideChat(chatId);
  }

  @action
  void updateChatId(String externalMessageId, int newChatId) {
    for (var chat in chats.values) {
      final Message? message = chat.messages.firstWhereOrNull(
        (element) => element.localId == externalMessageId,
      );

      if (message != null) {
        final oldChatId = message.chatId;

        // 1) Если chatId уже совпадает, нет смысла добавлять заново
        if (oldChatId == newChatId) {
          print(
              "[updateChatId] message already in chat $newChatId, skip re-adding");
          break;
        }

        // 2) Иначе переносим сообщение в новый чат
        message.chatId = newChatId;

        // 3) Проверяем, есть ли уже такой чат
        if (chats.containsKey(newChatId)) {
          final newChat = chats[newChatId]!;

          // Проверяем, нет ли уже этого сообщения в новом чате по localId
          final existingIndex =
              newChat.messages.indexWhere((m) => m.localId == message.localId);
          if (existingIndex >= 0) {
            print(
                "[updateChatId] message with localId=$externalMessageId already in chat $newChatId, skipping add.");
          } else {
            newChat.messages.add(message);
            print(
                "[updateChatId] message with localId=$externalMessageId added to chat $newChatId");
          }
        } else {
          // Если чата ещё нет, создаём его (редкий случай, когда было chatId=-1)
          print(
              "[updateChatId] newChatId=$newChatId not found, creating new chat in store...");
          final newChat = ChatInfo(
            chatId: newChatId,
            user: UserInChat(
              userId: message.recipientId ?? 0,
              firstName: 'Unknown',
              userAge: 0,
              avatarUrl: null,
              status: 'offline',
              hasSubscription: true
            ),
            createdAt: DateTime.now().toString(),
            lastMessage: message.content,
            messages: ObservableList<Message>.of([message]),
            unreadCount: 0,
          );
          chats[newChatId] = newChat;
          print(
              "[updateChatId] Created new chat with ID $newChatId and added message.");
        }

        print(
            "[updateChatId] Updated message localId=$externalMessageId from chat $oldChatId to chat $newChatId");
        break; // Прекращаем, так как нашли нужное сообщение
      }
    }
  }

  @action
  void readMessages(int chatId) {
    appSocket.readMessages(chatId);
    final ChatInfo? chat = chats[chatId];
    if (chat != null) {
      chat.unreadCount = 0;
      if (profileStore.userInfo == null) {
        print("User info is not initialized.");
        return;
      }
      for (var message in chat.messages) {
        if (message.senderId != profileStore.userInfo!.id) {
          message.status = 2;
          message.readAt = DateTime.now().toLocal();
          print("Сообщение ${message.id} помечено как прочитанное.");
        }
      }
      // Нет необходимости пересоздавать коллекции
    }
  }

  @action
  void allRead(int chatId, DateTime? readAt) {
    final ChatInfo? chat = chats[chatId];
    if (chat != null) {
      for (var message in chat.messages) {
        if (message.senderId == profileStore.userInfo!.id &&
            message.status == 1) {
          message.status = 2;
          message.readAt = readAt;
          print(
              "Сообщение ${message.id} помечено как прочитанное с датой $readAt.");
        }
      }
      // Нет необходимости пересоздавать коллекции
    }
  }

  @action
  void updateUnreadMessageCount(int chatId) {
    final chat = chats[chatId];
    if (chat != null) {
      final currentUserId = profileStore.userInfo?.id;
      if (currentUserId != null) {
        final unreadMessages = chat.messages
            .where((message) =>
                message.status < 2 && message.senderId != currentUserId)
            .length;
        chat.unreadCount = unreadMessages;
        print(
            "Updated unread message count for chat ID $chatId: ${chat.unreadCount}");
      } else {
        chat.unreadCount = 0;
      }
    }
  }

  @action
  void updateMessageStatus(
      int messageId, int status, DateTime? deliveredAt, DateTime? readAt) {
    print(
        "Called updateMessageStatus for messageId: $messageId, status: $status");
    for (var chat in chats.values) {
      final Message? message = chat.messages.firstWhereOrNull(
        (element) =>
            element.id == messageId || element.localId == messageId.toString(),
      );
      if (message != null) {
        if (status > message.status) {
          final oldStatus = message.status;
          print(
              "Updating Message ID ${message.id} from status ${message.status} to $status");
          message.status = status;
          if (deliveredAt != null) {
            message.deliveredAt = deliveredAt;
          }
          if (readAt != null) {
            message.readAt = readAt;
          }
          print(
              "Message ID ${message.id} updated: status=$status, deliveredAt=$deliveredAt, readAt=$readAt");
          // Корректируем unreadCount, если сообщение стало прочитанным
          if (message.senderId != profileStore.userInfo?.id) {
            if (oldStatus < 2 && status >= 2) {
              final chatId = message.chatId;
              final chat = chats[chatId];
              if (chat != null) {
                chat.unreadCount -= 1;
                if (chat.unreadCount < 0) chat.unreadCount = 0;
                print(
                    "Decremented unreadCount for chat ID $chatId to ${chat.unreadCount}");
              }
            }
          }
        } else {
          print(
              "Ignoring status update for Message ID ${message.id}: new status $status is not higher than current status ${message.status}");
        }
        return;
      }
    }
    print("Message ID $messageId not found in any chat");
  }

  @action
  void addMessages(int chatId, List<Map<String, dynamic>> messagesData) {
    print(
        "[addMessages] Called with chatId=$chatId, messagesData.length=${messagesData.length}");
    final ChatInfo? chat = chats[chatId];
    if (chat == null) {
      print("[addMessages] ERROR: no chat in store for chatId=$chatId");
      return;
    }

    for (var msgData in messagesData) {
      print("[addMessages] Processing: $msgData");
      final message = Message.fromJson(Map<String, dynamic>.from(msgData));

      // Проверка localId, если есть
      if (message.localId != null) {
        final existingIdxLocal =
            chat.messages.indexWhere((m) => m.localId == message.localId);
        if (existingIdxLocal != -1) {
          print(
              "[addMessages] Found existing by localId=${message.localId} at index=$existingIdxLocal -> updating...");
          chat.messages[existingIdxLocal] = message;
          continue;
        }
      }

      // Проверка ID, если не -1
      if (message.id != -1) {
        final existingIdxId =
            chat.messages.indexWhere((m) => m.id == message.id);
        if (existingIdxId != -1) {
          print(
              "[addMessages] Found existing by id=${message.id} at index=$existingIdxId -> updating...");
          chat.messages[existingIdxId] = message;
          continue;
        }
      }

      print(
          "[addMessages] No existing found, adding new ID=${message.id}, localId=${message.localId}");
      chat.messages.add(message);
    }

    // Логируем, что вышло
    print("[addMessages] After, chat $chatId has messages:");
    for (var i = 0; i < chat.messages.length; i++) {
      final m = chat.messages[i];
      print(
          "   index=$i -> id=${m.id}, localId=${m.localId}, status=${m.status}");
    }

    // updateUnreadMessageCount(chatId); // или что нужно
  }

  @action
  Future<void> clearRepository() async {
    chats.clear();
  }

  @action
  void markMessagesAsRead(int chatId, List<int> messageIds) {
    final ChatInfo? chat = chats[chatId];
    if (chat != null) {
      for (var message in chat.messages) {
        if (messageIds.contains(message.id)) {
          message.status = 2;
          message.readAt = DateTime.now().toLocal();
          print("Message ${message.id} marked as read locally.");
        }
      }
      // Пересчитываем unreadCount
      updateUnreadMessageCount(chatId);
      // Логируем текущие статусы сообщений
      for (var msg in chat.messages) {
        print("Message ID: ${msg.id}, Status: ${msg.status}");
      }
    }
  }

  // Метод для поиска сообщения по localId
  Message? findMessageByLocalId(int chatId, String? localId) {
    if (localId == null) return null;
    final ChatInfo? chat = chats[chatId];
    if (chat != null) {
      final Message? message = chat.messages.firstWhereOrNull(
        (element) => element.localId == localId,
      );
      return message;
    }
    return null;
  }
}


// Объявляем Singleton экземпляр
final ChatStore chatStore = ChatStore();

// Дополнительные классы и модели остаются без изменений

class UserInChat {
  final int userId;
  final String firstName;
  final int userAge;
  final String? avatarUrl;
  final String status;

  /// Новый флаг
  final bool hasSubscription;

  UserInChat({
    required this.userId,
    required this.firstName,
    required this.userAge,
    this.avatarUrl,
    required this.status,
    required this.hasSubscription,
  });

  factory UserInChat.fromJson(Map<String, dynamic> json) {
    return UserInChat(
      userId: json['id'], // <-- на бэке он приходит как 'id'
      firstName: json['first_name'],
      userAge: _calculateAge(json['date_of_birth']), // если нужно
      avatarUrl: json['avatar_url'],
      status: json['status'],
      // Берём is_subscription из бэка и записываем в hasSubscription
      hasSubscription: json['is_subscription'] == true,
    );
  }

  /// Метод для вычисления возраста по дате рождения (примерно)
  static int _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 0;
    final birthDate = DateTime.parse(dob);
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
