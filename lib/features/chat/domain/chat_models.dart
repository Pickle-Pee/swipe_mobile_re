class ChatUser {
  const ChatUser({
    required this.id,
    required this.firstName,
    required this.age,
    required this.avatarUrl,
    required this.status,
  });

  final int id;
  final String firstName;
  final int? age;
  final String? avatarUrl;
  final String? status;

  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
    id: json['user_id'] as int,
    firstName: json['first_name'] as String? ?? '',
    age: json['user_age'] as int?,
    avatarUrl: json['avatar_url'] as String?,
    status: json['status'] as String?,
  );
}

class ChatSummary {
  const ChatSummary({
    required this.id,
    required this.user,
    required this.createdAt,
    required this.lastMessage,
    required this.unreadCount,
  });

  final int id;
  final ChatUser user;
  final DateTime? createdAt;
  final String? lastMessage;
  final int unreadCount;

  ChatSummary copyWith({String? lastMessage, int? unreadCount}) => ChatSummary(
    id: id,
    user: user,
    createdAt: createdAt,
    lastMessage: lastMessage ?? this.lastMessage,
    unreadCount: unreadCount ?? this.unreadCount,
  );

  factory ChatSummary.fromJson(Map<String, dynamic> json) => ChatSummary(
    id: json['chat_id'] as int,
    user: ChatUser.fromJson(json['user'] as Map<String, dynamic>),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    lastMessage: json['last_message'] as String?,
    unreadCount: json['unread_count'] as int? ?? 0,
  );
}

enum ChatMessageStatus { sending, sent, delivered, read }

class ChatMessage {
  const ChatMessage({
    required this.localId,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.status,
    required this.createdAt,
    this.id,
  });

  final int? id;
  final String localId;
  final int chatId;
  final int senderId;
  final String text;
  final ChatMessageStatus status;
  final DateTime createdAt;

  ChatMessage copyWith({int? id, ChatMessageStatus? status}) => ChatMessage(
    id: id ?? this.id,
    localId: localId,
    chatId: chatId,
    senderId: senderId,
    text: text,
    status: status ?? this.status,
    createdAt: createdAt,
  );

  factory ChatMessage.fromJson(Map<String, dynamic> json, {int? chatId}) {
    final id = _asInt(json['message_id'] ?? json['id']);
    return ChatMessage(
      id: id,
      localId: json['external_message_id']?.toString() ?? 'server-$id',
      chatId: _asInt(json['chat_id'] ?? json['chatId'] ?? chatId) ?? 0,
      senderId: _asInt(json['sender_id']) ?? 0,
      text: json['message']?.toString() ?? '',
      status: _messageStatus(json['status']),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

int? _asInt(Object? value) => switch (value) {
  int number => number,
  String text => int.tryParse(text),
  _ => null,
};

ChatMessageStatus _messageStatus(Object? value) {
  final normalized = value?.toString().toLowerCase();
  return switch (normalized) {
    '2' || 'read' => ChatMessageStatus.read,
    '1' || 'delivered' => ChatMessageStatus.delivered,
    '0' || 'sent' => ChatMessageStatus.sent,
    _ => ChatMessageStatus.sent,
  };
}

class ChatDetails {
  const ChatDetails({required this.chatId, required this.user});
  final int chatId;
  final ChatUser user;

  factory ChatDetails.fromJson(int chatId, Map<String, dynamic> json) =>
      ChatDetails(chatId: chatId, user: ChatUser.fromJson(json));
}
