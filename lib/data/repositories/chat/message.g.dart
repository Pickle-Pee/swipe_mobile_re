// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$Message on _Message, Store {
  late final _$idAtom = Atom(name: '_Message.id', context: context);

  @override
  int get id {
    _$idAtom.reportRead();
    return super.id;
  }

  @override
  set id(int value) {
    _$idAtom.reportWrite(value, super.id, () {
      super.id = value;
    });
  }

  late final _$chatIdAtom = Atom(name: '_Message.chatId', context: context);

  @override
  int? get chatId {
    _$chatIdAtom.reportRead();
    return super.chatId;
  }

  @override
  set chatId(int? value) {
    _$chatIdAtom.reportWrite(value, super.chatId, () {
      super.chatId = value;
    });
  }

  late final _$senderIdAtom = Atom(name: '_Message.senderId', context: context);

  @override
  int get senderId {
    _$senderIdAtom.reportRead();
    return super.senderId;
  }

  @override
  set senderId(int value) {
    _$senderIdAtom.reportWrite(value, super.senderId, () {
      super.senderId = value;
    });
  }

  late final _$recipientIdAtom =
      Atom(name: '_Message.recipientId', context: context);

  @override
  int? get recipientId {
    _$recipientIdAtom.reportRead();
    return super.recipientId;
  }

  @override
  set recipientId(int? value) {
    _$recipientIdAtom.reportWrite(value, super.recipientId, () {
      super.recipientId = value;
    });
  }

  late final _$contentAtom = Atom(name: '_Message.content', context: context);

  @override
  String get content {
    _$contentAtom.reportRead();
    return super.content;
  }

  @override
  set content(String value) {
    _$contentAtom.reportWrite(value, super.content, () {
      super.content = value;
    });
  }

  late final _$localIdAtom = Atom(name: '_Message.localId', context: context);

  @override
  String get localId {
    _$localIdAtom.reportRead();
    return super.localId;
  }

  @override
  set localId(String value) {
    _$localIdAtom.reportWrite(value, super.localId, () {
      super.localId = value;
    });
  }

  late final _$replyMessageIdAtom =
      Atom(name: '_Message.replyMessageId', context: context);

  @override
  int? get replyMessageId {
    _$replyMessageIdAtom.reportRead();
    return super.replyMessageId;
  }

  @override
  set replyMessageId(int? value) {
    _$replyMessageIdAtom.reportWrite(value, super.replyMessageId, () {
      super.replyMessageId = value;
    });
  }

  late final _$voiceDataAtom =
      Atom(name: '_Message.voiceData', context: context);

  @override
  String? get voiceData {
    _$voiceDataAtom.reportRead();
    return super.voiceData;
  }

  @override
  set voiceData(String? value) {
    _$voiceDataAtom.reportWrite(value, super.voiceData, () {
      super.voiceData = value;
    });
  }

  late final _$statusAtom = Atom(name: '_Message.status', context: context);

  @override
  int get status {
    _$statusAtom.reportRead();
    return super.status;
  }

  @override
  set status(int value) {
    _$statusAtom.reportWrite(value, super.status, () {
      super.status = value;
    });
  }

  late final _$createdAtAtom =
      Atom(name: '_Message.createdAt', context: context);

  @override
  DateTime? get createdAt {
    _$createdAtAtom.reportRead();
    return super.createdAt;
  }

  @override
  set createdAt(DateTime? value) {
    _$createdAtAtom.reportWrite(value, super.createdAt, () {
      super.createdAt = value;
    });
  }

  late final _$deliveredAtAtom =
      Atom(name: '_Message.deliveredAt', context: context);

  @override
  DateTime? get deliveredAt {
    _$deliveredAtAtom.reportRead();
    return super.deliveredAt;
  }

  @override
  set deliveredAt(DateTime? value) {
    _$deliveredAtAtom.reportWrite(value, super.deliveredAt, () {
      super.deliveredAt = value;
    });
  }

  late final _$readAtAtom = Atom(name: '_Message.readAt', context: context);

  @override
  DateTime? get readAt {
    _$readAtAtom.reportRead();
    return super.readAt;
  }

  @override
  set readAt(DateTime? value) {
    _$readAtAtom.reportWrite(value, super.readAt, () {
      super.readAt = value;
    });
  }

  late final _$messageTypeAtom =
      Atom(name: '_Message.messageType', context: context);

  @override
  String get messageType {
    _$messageTypeAtom.reportRead();
    return super.messageType;
  }

  @override
  set messageType(String value) {
    _$messageTypeAtom.reportWrite(value, super.messageType, () {
      super.messageType = value;
    });
  }

  late final _$mediaUrlsAtom =
      Atom(name: '_Message.mediaUrls', context: context);

  @override
  ObservableList<String>? get mediaUrls {
    _$mediaUrlsAtom.reportRead();
    return super.mediaUrls;
  }

  @override
  set mediaUrls(ObservableList<String>? value) {
    _$mediaUrlsAtom.reportWrite(value, super.mediaUrls, () {
      super.mediaUrls = value;
    });
  }

  @override
  String toString() {
    return '''
id: ${id},
chatId: ${chatId},
senderId: ${senderId},
recipientId: ${recipientId},
content: ${content},
localId: ${localId},
replyMessageId: ${replyMessageId},
voiceData: ${voiceData},
status: ${status},
createdAt: ${createdAt},
deliveredAt: ${deliveredAt},
readAt: ${readAt},
messageType: ${messageType},
mediaUrls: ${mediaUrls}
    ''';
  }
}
