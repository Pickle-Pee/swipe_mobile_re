// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_info.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ChatInfo on _ChatInfo, Store {
  late final _$chatIdAtom = Atom(name: '_ChatInfo.chatId', context: context);

  @override
  int get chatId {
    _$chatIdAtom.reportRead();
    return super.chatId;
  }

  @override
  set chatId(int value) {
    _$chatIdAtom.reportWrite(value, super.chatId, () {
      super.chatId = value;
    });
  }

  late final _$userAtom = Atom(name: '_ChatInfo.user', context: context);

  @override
  UserInChat get user {
    _$userAtom.reportRead();
    return super.user;
  }

  @override
  set user(UserInChat value) {
    _$userAtom.reportWrite(value, super.user, () {
      super.user = value;
    });
  }

  late final _$createdAtAtom =
      Atom(name: '_ChatInfo.createdAt', context: context);

  @override
  String? get createdAt {
    _$createdAtAtom.reportRead();
    return super.createdAt;
  }

  @override
  set createdAt(String? value) {
    _$createdAtAtom.reportWrite(value, super.createdAt, () {
      super.createdAt = value;
    });
  }

  late final _$lastMessageAtom =
      Atom(name: '_ChatInfo.lastMessage', context: context);

  @override
  String? get lastMessage {
    _$lastMessageAtom.reportRead();
    return super.lastMessage;
  }

  @override
  set lastMessage(String? value) {
    _$lastMessageAtom.reportWrite(value, super.lastMessage, () {
      super.lastMessage = value;
    });
  }

  late final _$messagesAtom =
      Atom(name: '_ChatInfo.messages', context: context);

  @override
  ObservableList<Message> get messages {
    _$messagesAtom.reportRead();
    return super.messages;
  }

  @override
  set messages(ObservableList<Message> value) {
    _$messagesAtom.reportWrite(value, super.messages, () {
      super.messages = value;
    });
  }

  late final _$unreadCountAtom =
      Atom(name: '_ChatInfo.unreadCount', context: context);

  @override
  int get unreadCount {
    _$unreadCountAtom.reportRead();
    return super.unreadCount;
  }

  @override
  set unreadCount(int value) {
    _$unreadCountAtom.reportWrite(value, super.unreadCount, () {
      super.unreadCount = value;
    });
  }

  late final _$isHiddenAtom =
      Atom(name: '_ChatInfo.isHidden', context: context);

  @override
  bool get isHidden {
    _$isHiddenAtom.reportRead();
    return super.isHidden;
  }

  @override
  set isHidden(bool value) {
    _$isHiddenAtom.reportWrite(value, super.isHidden, () {
      super.isHidden = value;
    });
  }

  late final _$_ChatInfoActionController =
      ActionController(name: '_ChatInfo', context: context);

  @override
  void addMessage(Message message) {
    final _$actionInfo =
        _$_ChatInfoActionController.startAction(name: '_ChatInfo.addMessage');
    try {
      return super.addMessage(message);
    } finally {
      _$_ChatInfoActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateMessage(Message message) {
    final _$actionInfo = _$_ChatInfoActionController.startAction(
        name: '_ChatInfo.updateMessage');
    try {
      return super.updateMessage(message);
    } finally {
      _$_ChatInfoActionController.endAction(_$actionInfo);
    }
  }

  @override
  void markAllMessagesAsRead(DateTime? readAt) {
    final _$actionInfo = _$_ChatInfoActionController.startAction(
        name: '_ChatInfo.markAllMessagesAsRead');
    try {
      return super.markAllMessagesAsRead(readAt);
    } finally {
      _$_ChatInfoActionController.endAction(_$actionInfo);
    }
  }

  @override
  void hideChat() {
    final _$actionInfo =
        _$_ChatInfoActionController.startAction(name: '_ChatInfo.hideChat');
    try {
      return super.hideChat();
    } finally {
      _$_ChatInfoActionController.endAction(_$actionInfo);
    }
  }

  @override
  void unhideChat() {
    final _$actionInfo =
        _$_ChatInfoActionController.startAction(name: '_ChatInfo.unhideChat');
    try {
      return super.unhideChat();
    } finally {
      _$_ChatInfoActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
chatId: ${chatId},
user: ${user},
createdAt: ${createdAt},
lastMessage: ${lastMessage},
messages: ${messages},
unreadCount: ${unreadCount},
isHidden: ${isHidden}
    ''';
  }
}
