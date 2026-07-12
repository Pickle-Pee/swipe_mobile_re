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

  factory ChatSummary.fromJson(Map<String, dynamic> json) => ChatSummary(
    id: json['chat_id'] as int,
    user: ChatUser.fromJson(json['user'] as Map<String, dynamic>),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    lastMessage: json['last_message'] as String?,
    unreadCount: json['unread_count'] as int? ?? 0,
  );
}

class ChatDetails {
  const ChatDetails({required this.chatId, required this.user});
  final int chatId;
  final ChatUser user;

  factory ChatDetails.fromJson(int chatId, Map<String, dynamic> json) =>
      ChatDetails(chatId: chatId, user: ChatUser.fromJson(json));
}
