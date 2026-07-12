import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'chat_models.dart';

abstract interface class ChatRepository {
  Future<int> createChat(int userId);
  Future<List<ChatSummary>> getChats();
  Future<ChatDetails> getChatDetails(int chatId);
  Future<int?> getChatIdByUserId(int userId);
}

class DioChatRepository implements ChatRepository {
  DioChatRepository(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<int> createChat(int userId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/communication/create_chat',
      data: {'user_id': userId},
    );
    final id = response.data?['chat_id'];
    if (id is! int) throw const FormatException('Chat response has no id');
    return id;
  }

  @override
  Future<List<ChatSummary>> getChats() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/communication/get_chats',
    );
    return (response.data ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ChatSummary.fromJson)
        .toList();
  }

  @override
  Future<ChatDetails> getChatDetails(int chatId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/communication/$chatId',
    );
    final data = response.data;
    if (data == null) throw const FormatException('Empty chat details');
    return ChatDetails.fromJson(chatId, data);
  }

  @override
  Future<int?> getChatIdByUserId(int userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/communication/get_chat_id_by_user_id',
        queryParameters: {'recipient_id': userId},
      );
      return response.data?['chat_id'] as int?;
    } on UnknownApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }
}
