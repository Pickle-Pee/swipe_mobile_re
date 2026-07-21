import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/config.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/chat_models.dart';
import '../domain/chat_repository.dart';
import 'chat_socket.dart';

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

  void applyMessage(ChatMessage message, {required bool isOpen}) {
    final index = state.chats.indexWhere((chat) => chat.id == message.chatId);
    if (index < 0) return;
    final chats = [...state.chats];
    final current = chats.removeAt(index);
    chats.insert(
      0,
      current.copyWith(
        lastMessage: message.text,
        unreadCount: isOpen ? 0 : current.unreadCount + 1,
      ),
    );
    state = ChatListState(status: ChatListStatus.data, chats: chats);
  }
}

final chatSocketManagerProvider = Provider<ChatSocketManager>((ref) {
  final manager = ChatSocketManager(
    transport: IoSocketTransport(AppConfig.baseAppSocketUrl),
    storage: ref.watch(sessionStorageProvider),
  );
  ref.onDispose(manager.dispose);
  unawaited(manager.connect());
  return manager;
});

final chatRealtimeProvider = Provider<void>((ref) {
  final subscription = ref.watch(chatSocketManagerProvider).events.listen((
    event,
  ) {
    if (event.name != ChatSocketManager.incoming) return;
    final message = ChatMessage.fromJson(event.data);
    ref
        .read(chatListControllerProvider.notifier)
        .applyMessage(message, isOpen: false);
  });
  ref.onDispose(subscription.cancel);
});

class ChatMessagesState {
  const ChatMessagesState({
    this.messages = const [],
    this.isLoading = true,
    this.isSending = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final Object? error;
}

final chatMessagesControllerProvider =
    NotifierProvider.family<ChatMessagesController, ChatMessagesState, int>(
      ChatMessagesController.new,
    );

class ChatMessagesController extends Notifier<ChatMessagesState> {
  ChatMessagesController(this.chatId);
  final int chatId;
  StreamSubscription<ChatSocketEvent>? _subscription;
  bool _awaitingInitialAuthentication = false;

  ChatSocketManager get _socket => ref.read(chatSocketManagerProvider);

  @override
  ChatMessagesState build() {
    _subscription = _socket.events.listen(_onEvent);
    ref.onDispose(() => _subscription?.cancel());
    _awaitingInitialAuthentication = !_socket.isAuthenticated;
    _socket.requestHistory(chatId);
    return const ChatMessagesState();
  }

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    final userId = ref.read(authControllerProvider).user?.id;
    if (text.isEmpty || userId == null || state.isSending) return;
    final externalId = '${DateTime.now().microsecondsSinceEpoch}-$userId';
    final optimistic = ChatMessage(
      localId: externalId,
      chatId: chatId,
      senderId: userId,
      text: text,
      status: ChatMessageStatus.sending,
      createdAt: DateTime.now(),
    );
    state = ChatMessagesState(
      messages: [...state.messages, optimistic],
      isLoading: false,
      isSending: true,
    );
    _socket.sendMessage(chatId: chatId, text: text, externalId: externalId);
    _replace(
      externalId,
      optimistic.copyWith(status: ChatMessageStatus.sent),
      isSending: true,
    );
  }

  void _onEvent(ChatSocketEvent event) {
    if (event.name == ChatSocketManager.authenticated) {
      if (_awaitingInitialAuthentication) {
        _awaitingInitialAuthentication = false;
        return;
      }
      _socket.requestHistory(chatId);
      return;
    }
    if (event.name == ChatSocketManager.history) {
      if (_int(event.data['chatId']) != chatId) return;
      final raw = event.data['messages'];
      final history = raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (item) => ChatMessage.fromJson(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                    chatId: chatId,
                  ),
                )
                .toList()
          : <ChatMessage>[];
      _merge(history, isLoading: false);
      return;
    }
    if (event.name == ChatSocketManager.incoming) {
      if (_int(event.data['chat_id']) != chatId) return;
      final message = ChatMessage.fromJson(event.data, chatId: chatId);
      _merge([message], isLoading: false);
      if (message.id != null) {
        _socket.markDelivered([message.id!]);
        _socket.markRead([message.id!]);
      }
      ref
          .read(chatListControllerProvider.notifier)
          .applyMessage(message, isOpen: true);
      return;
    }
    if (event.name == ChatSocketManager.completed) {
      if (_int(event.data['chat_id']) != chatId) return;
      final localId = event.data['external_message_id']?.toString();
      if (localId == null) return;
      final current = state.messages
          .where((m) => m.localId == localId)
          .firstOrNull;
      if (current == null) return;
      _replace(
        localId,
        current.copyWith(
          id: _int(event.data['id']),
          status: _status(event.data['status']),
        ),
        isSending: false,
      );
      ref
          .read(chatListControllerProvider.notifier)
          .applyMessage(current, isOpen: true);
      return;
    }
    if (event.name == ChatSocketManager.statusUpdate) {
      final id = _int(event.data['message_id']);
      if (id == null) return;
      final index = state.messages.indexWhere((message) => message.id == id);
      if (index < 0) return;
      _replace(
        state.messages[index].localId,
        state.messages[index].copyWith(status: _status(event.data['status'])),
      );
    }
  }

  void _merge(List<ChatMessage> additions, {bool? isLoading}) {
    final messages = [...state.messages];
    for (final addition in additions) {
      final index = messages.indexWhere(
        (item) =>
            (addition.id != null && item.id == addition.id) ||
            item.localId == addition.localId,
      );
      if (index < 0) {
        messages.add(addition);
      } else {
        messages[index] = addition;
      }
    }
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = ChatMessagesState(
      messages: messages,
      isLoading: isLoading ?? state.isLoading,
      isSending: state.isSending,
    );
  }

  void _replace(String localId, ChatMessage replacement, {bool? isSending}) {
    state = ChatMessagesState(
      messages: [
        for (final message in state.messages)
          if (message.localId == localId) replacement else message,
      ],
      isLoading: state.isLoading,
      isSending: isSending ?? state.isSending,
    );
  }
}

int? _int(Object? value) => switch (value) {
  int number => number,
  String text => int.tryParse(text),
  _ => null,
};

ChatMessageStatus _status(Object? value) =>
    switch (value?.toString().toLowerCase()) {
      '2' || 'read' => ChatMessageStatus.read,
      '1' || 'delivered' => ChatMessageStatus.delivered,
      '0' || 'sent' => ChatMessageStatus.sent,
      _ => ChatMessageStatus.sent,
    };
