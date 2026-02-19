import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';

part 'message.g.dart';

enum MessageTypeEnum { text, voice }

int _parseStatus(dynamic status) {
  if (status is int) {
    print("Parsed status (int): $status");
    return status;
  } else if (status is String) {
    final normalized = status.trim().toLowerCase();
    print("Parsing status (string): '$status' -> '$normalized'");
    switch (normalized) {
      case 'sent':
        return 0; // Отправлено
      case 'delivered':
        return 1; // Доставлено
      case 'read':
        return 2; // Прочитано
      case '0':
        return 0; // Отправлено
      case '1':
        return 1; // Доставлено
      case '2':
        return 2; // Прочитано
      default:
        print("Unknown status: '$status', defaulting to 0");
        return 0; // Статус по умолчанию
    }
  } else {
    print("Unknown status type: ${status.runtimeType}, defaulting to 0");
    return 0; // Статус по умолчанию
  }
}

class Message extends _Message with _$Message {
  Message({
    required int id,
    int? chatId,
    required int status,
    required String content,
    required int senderId,
    int? recipientId, // Добавлено поле recipientId
    int? replyMessageId,
    String? voiceData,
    List<String>? mediaUrls,
    String? messageType,
    DateTime? createdAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? localId,
  }) : super(
          id: id,
          chatId: chatId,
          status: status,
          content: content,
          senderId: senderId,
          recipientId: recipientId, // Инициализируем recipientId
          replyMessageId: replyMessageId,
          voiceData: voiceData,
          mediaUrls:
              mediaUrls != null ? ObservableList<String>.of(mediaUrls) : null,
          messageType: messageType ?? 'text',
          createdAt: createdAt,
          deliveredAt: deliveredAt,
          readAt: readAt,
          localId: localId,
        );

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['message_id'] is int
          ? json['message_id']
          : int.tryParse(json['message_id'].toString()) ?? 0,
      chatId: json['chat_id'] is int
          ? json['chat_id']
          : int.tryParse(json['chat_id'].toString()),
      status: _parseStatus(json['status']),
      content: json['message'] ?? "<empty>",
      senderId: json['sender_id'] is int
          ? json['sender_id']
          : int.tryParse(json['sender_id'].toString()) ?? 0,
      // recipientId не приходит с сервера, поэтому не парсится из json
      replyMessageId: json['reply_to_message_id'] is int
          ? json['reply_to_message_id']
          : int.tryParse(json['reply_to_message_id'].toString()),
      voiceData: json['voice_data'],
      mediaUrls: json['media_urls'] != null
          ? ObservableList<String>.of(List<String>.from(json['media_urls']))
          : null,
      messageType: json['message_type'] ?? 'text',
      createdAt: parseUtcDateTime(json['created_at']),
      deliveredAt: parseUtcDateTime(json['delivered_at']),
      readAt: parseUtcDateTime(json['read_at']),
      localId: json['external_message_id'],
    );
  }
}

abstract class _Message with Store {
  @observable
  int id;

  @observable
  int? chatId; // Сделаем chatId nullable, поскольку его может не быть до создания чата

  @observable
  int senderId;

  @observable
  int? recipientId; // Добавлено поле recipientId

  @observable
  String content;

  @observable
  String localId;

  @observable
  int? replyMessageId;

  @observable
  String? voiceData;

  @observable
  int status;

  @observable
  DateTime? createdAt;

  @observable
  DateTime? deliveredAt;

  @observable
  DateTime? readAt;

  @observable
  String messageType;

  @observable
  ObservableList<String>? mediaUrls;

  _Message({
    required this.id,
    int? chatId,
    required this.status,
    required this.content,
    required this.senderId,
    this.recipientId, // Инициализация recipientId
    this.replyMessageId,
    this.voiceData,
    this.mediaUrls,
    String? messageType,
    this.createdAt,
    this.deliveredAt,
    this.readAt,
    String? localId,
  })  : chatId = chatId, // Инициализируем chatId
        messageType = messageType ?? 'text',
        localId = localId ?? const Uuid().v4();
}

// Функция для парсинга даты из строки в DateTime
DateTime? parseUtcDateTime(String? dateString) {
  if (dateString == null) return null;

  try {
    // Попытка парсинга ISO 8601 формата
    DateTime dateTime = DateTime.parse(dateString).toUtc();
    return dateTime.toLocal();
  } catch (e) {
    print("Error parsing date: $e");
    return null;
  }
}
