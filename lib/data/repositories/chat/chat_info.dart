// chat_info.dart

import 'package:mobx/mobx.dart';
import 'package:swipe_mobile_re/data/repositories/chat/chat_repo.dart';
import 'message.dart';

part 'chat_info.g.dart';

class ChatInfo = _ChatInfo with _$ChatInfo;

abstract class _ChatInfo with Store {
  _ChatInfo({
    required this.chatId,
    required this.user,
    this.createdAt,
    this.lastMessage,
    List<Message>? messages,
    this.unreadCount = 0,
    this.isHidden = false, // Новое свойство
  }) : messages = ObservableList<Message>.of(messages ?? []);

  @observable
  int chatId;

  @observable
  UserInChat user;

  @observable
  String? createdAt;

  @observable
  String? lastMessage;

  @observable
  ObservableList<Message> messages;

  @observable
  int unreadCount = 0;

  @observable
  bool isHidden = false; // Новое свойство

  @action
  void addMessage(Message message) {
    messages.add(message);
    if (isHidden) {
      isHidden = false; // Разрешаем показывать чат при добавлении сообщения
      print("Chat ID $chatId unhidden due to new message.");
    }
  }

  @action
  void updateMessage(Message message) {
    int index = messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      messages[index] = message;
    }
  }

  @action
  void markAllMessagesAsRead(DateTime? readAt) {
    for (var message in messages) {
      if (message.status < 2) {
        message.status = 2;
        message.readAt = readAt;
      }
    }
  }

  @action
  void hideChat() {
    isHidden = true;
    print("Chat ID $chatId is now hidden.");
  }

  @action
  void unhideChat() {
    isHidden = false;
    print("Chat ID $chatId is now visible.");
  }
}
