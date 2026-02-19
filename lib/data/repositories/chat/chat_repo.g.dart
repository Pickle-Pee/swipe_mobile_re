// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_repo.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ChatStore on _ChatStore, Store {
  Computed<int?>? _$chatIdUsedComputed;

  @override
  int? get chatIdUsed => (_$chatIdUsedComputed ??=
          Computed<int?>(() => super.chatIdUsed, name: '_ChatStore.chatIdUsed'))
      .value;

  late final _$_chatIdUsedAtom =
      Atom(name: '_ChatStore._chatIdUsed', context: context);

  @override
  int? get _chatIdUsed {
    _$_chatIdUsedAtom.reportRead();
    return super._chatIdUsed;
  }

  @override
  set _chatIdUsed(int? value) {
    _$_chatIdUsedAtom.reportWrite(value, super._chatIdUsed, () {
      super._chatIdUsed = value;
    });
  }

  late final _$chatsAtom = Atom(name: '_ChatStore.chats', context: context);

  @override
  ObservableMap<int, ChatInfo> get chats {
    _$chatsAtom.reportRead();
    return super.chats;
  }

  @override
  set chats(ObservableMap<int, ChatInfo> value) {
    _$chatsAtom.reportWrite(value, super.chats, () {
      super.chats = value;
    });
  }

  late final _$notificationsEnabledAtom =
      Atom(name: '_ChatStore.notificationsEnabled', context: context);

  @override
  ObservableMap<int, bool> get notificationsEnabled {
    _$notificationsEnabledAtom.reportRead();
    return super.notificationsEnabled;
  }

  @override
  set notificationsEnabled(ObservableMap<int, bool> value) {
    _$notificationsEnabledAtom.reportWrite(value, super.notificationsEnabled,
        () {
      super.notificationsEnabled = value;
    });
  }

  late final _$localIdToExternalIdAtom =
      Atom(name: '_ChatStore.localIdToExternalId', context: context);

  @override
  Map<String, int> get localIdToExternalId {
    _$localIdToExternalIdAtom.reportRead();
    return super.localIdToExternalId;
  }

  @override
  set localIdToExternalId(Map<String, int> value) {
    _$localIdToExternalIdAtom.reportWrite(value, super.localIdToExternalId, () {
      super.localIdToExternalId = value;
    });
  }

  late final _$createChatAsyncAction =
      AsyncAction('_ChatStore.createChat', context: context);

  @override
  Future<int?> createChat(int recipientId) {
    return _$createChatAsyncAction.run(() => super.createChat(recipientId));
  }

  late final _$getChatsAsyncAction =
      AsyncAction('_ChatStore.getChats', context: context);

  @override
  Future<void> getChats() {
    return _$getChatsAsyncAction.run(() => super.getChats());
  }

  late final _$getChatInfoAsyncAction =
      AsyncAction('_ChatStore.getChatInfo', context: context);

  @override
  Future<void> getChatInfo(int chatId, Message? mess) {
    return _$getChatInfoAsyncAction.run(() => super.getChatInfo(chatId, mess));
  }

  late final _$sendMessageAsyncAction =
      AsyncAction('_ChatStore.sendMessage', context: context);

  @override
  Future<void> sendMessage(Message mess) {
    return _$sendMessageAsyncAction.run(() => super.sendMessage(mess));
  }

  late final _$clearRepositoryAsyncAction =
      AsyncAction('_ChatStore.clearRepository', context: context);

  @override
  Future<void> clearRepository() {
    return _$clearRepositoryAsyncAction.run(() => super.clearRepository());
  }

  late final _$_ChatStoreActionController =
      ActionController(name: '_ChatStore', context: context);

  @override
  void setChatIdUsed(int? value) {
    final _$actionInfo = _$_ChatStoreActionController.startAction(
        name: '_ChatStore.setChatIdUsed');
    try {
      return super.setChatIdUsed(value);
    } finally {
      _$_ChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool toggleNotifications(int chatId) {
    final _$actionInfo = _$_ChatStoreActionController.startAction(
        name: '_ChatStore.toggleNotifications');
    try {
      return super.toggleNotifications(chatId);
    } finally {
      _$_ChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void deleteChat(int chatId) {
    final _$actionInfo =
        _$_ChatStoreActionController.startAction(name: '_ChatStore.deleteChat');
    try {
      return super.deleteChat(chatId);
    } finally {
      _$_ChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void hideChat(int chatId) {
    final _$actionInfo =
        _$_ChatStoreActionController.startAction(name: '_ChatStore.hideChat');
    try {
      return super.hideChat(chatId);
    } finally {
      _$_ChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateStatus(int chatId, int status, String externalMessageId, int id,
      DateTime? createdAt) {
    final _$actionInfo = _$_ChatStoreActionController.startAction(
        name: '_ChatStore.updateStatus');
    try {
      return super
          .updateStatus(chatId, status, externalMessageId, id, createdAt);
    } finally {
      _$_ChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addMessage(Message mess, {String caller = ""}) {
    final _$actionInfo =
        _$_ChatStoreActionController.startAction(name: '_ChatStore.addMessage');
    try {
      return super.addMessage(mess, caller: caller);
    } finally {
      _$_ChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleDeleteChatEvent(dynamic data) {
    final _$actionInfo = _$_ChatStoreActionController.startAction(
        name: '_ChatStore._handleDeleteChatEvent');
    try {
      return super._handleDeleteChatEvent(data);
    } finally {
      _$_ChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateChatId(String externalMessageId, int newChatId) {
    final _$actionInfo = _$_ChatStoreActionController.startAction(
        name: '_ChatStore.updateChatId');
    try {
      return super.updateChatId(externalMessageId, newChatId);
    } finally {
      _$_ChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void readMessages(int chatId) {
    final _$actionInfo = _$_ChatStoreActionController.startAction(
        name: '_ChatStore.readMessages');
    try {
      return super.readMessages(chatId);
    } finally {
      _$_ChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void allRead(int chatId, DateTime? readAt) {
    final _$actionInfo =
        _$_ChatStoreActionController.startAction(name: '_ChatStore.allRead');
    try {
      return super.allRead(chatId, readAt);
    } finally {
      _$_ChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateUnreadMessageCount(int chatId) {
    final _$actionInfo = _$_ChatStoreActionController.startAction(
        name: '_ChatStore.updateUnreadMessageCount');
    try {
      return super.updateUnreadMessageCount(chatId);
    } finally {
      _$_ChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateMessageStatus(
      int messageId, int status, DateTime? deliveredAt, DateTime? readAt) {
    final _$actionInfo = _$_ChatStoreActionController.startAction(
        name: '_ChatStore.updateMessageStatus');
    try {
      return super.updateMessageStatus(messageId, status, deliveredAt, readAt);
    } finally {
      _$_ChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addMessages(int chatId, List<Map<String, dynamic>> messagesData) {
    final _$actionInfo = _$_ChatStoreActionController.startAction(
        name: '_ChatStore.addMessages');
    try {
      return super.addMessages(chatId, messagesData);
    } finally {
      _$_ChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void markMessagesAsRead(int chatId, List<int> messageIds) {
    final _$actionInfo = _$_ChatStoreActionController.startAction(
        name: '_ChatStore.markMessagesAsRead');
    try {
      return super.markMessagesAsRead(chatId, messageIds);
    } finally {
      _$_ChatStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
chats: ${chats},
notificationsEnabled: ${notificationsEnabled},
localIdToExternalId: ${localIdToExternalId},
chatIdUsed: ${chatIdUsed}
    ''';
  }
}
