import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';

enum ChatListStatus { initial, loading, data, empty, error }

class ChatListState {
  const ChatListState({
    this.status = ChatListStatus.initial,
    this.chats = const [],
    this.error,
    this.isCreating = false,
  });

  final ChatListStatus status;
  final List<ChatSummary> chats;
  final Object? error;
  final bool isCreating;
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return DioChatRepository(ref.watch(apiClientProvider));
});

final chatListControllerProvider =
    NotifierProvider<ChatListController, ChatListState>(ChatListController.new);

class ChatListController extends Notifier<ChatListState> {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);

  @override
  ChatListState build() => const ChatListState();

  Future<void> load() async {
    state = ChatListState(status: ChatListStatus.loading, chats: state.chats);
    try {
      final chats = await _repository.getChats();
      state = ChatListState(
        status: chats.isEmpty ? ChatListStatus.empty : ChatListStatus.data,
        chats: chats,
      );
    } on Object catch (error) {
      state = ChatListState(
        status: ChatListStatus.error,
        chats: state.chats,
        error: error,
      );
    }
  }

  Future<int?> openOrCreate(int userId) async {
    if (state.isCreating) return null;
    state = ChatListState(
      status: state.status,
      chats: state.chats,
      isCreating: true,
    );
    try {
      final existing = await _repository.getChatIdByUserId(userId);
      final chatId = existing ?? await _repository.createChat(userId);
      await load();
      return chatId;
    } on Object catch (error) {
      state = ChatListState(
        status: ChatListStatus.error,
        chats: state.chats,
        error: error,
      );
      return null;
    }
  }
}
