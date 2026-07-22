import 'dart:async';
import 'dart:collection';

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
  static const _seenMessageLimit = 512;

  final LinkedHashSet<String> _seenMessages = LinkedHashSet<String>();
  bool _unknownChatReloadInFlight = false;

  ChatRepository get _repository => ref.read(chatRepositoryProvider);

  @override
  ChatListState build() => const ChatListState();

  Future<void> load() async {
    state = ChatListState(
      status: ChatListStatus.loading,
      chats: state.chats,
      isCreating: state.isCreating,
    );
    try {
      final loaded = await _repository.getChats();
      final seen = <int>{};
      final chats = [
        for (final chat in loaded)
          if (seen.add(chat.id)) chat,
      ];
      state = ChatListState(
        status: chats.isEmpty ? ChatListStatus.empty : ChatListStatus.data,
        chats: chats,
      );
    } on Object catch (error) {
      state = ChatListState(
        status: state.chats.isEmpty
            ? ChatListStatus.error
            : ChatListStatus.data,
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
        status: state.chats.isEmpty
            ? ChatListStatus.error
            : ChatListStatus.data,
        chats: state.chats,
        error: error,
      );
      return null;
    }
  }

  Future<void> applyMessage(ChatMessage message, {required bool isOpen}) async {
    final messageKey = message.id == null
        ? 'local:${message.localId}'
        : 'server:${message.id}';
    if (!_seenMessages.add(messageKey)) return;
    if (_seenMessages.length > _seenMessageLimit) {
      _seenMessages.remove(_seenMessages.first);
    }

    final index = state.chats.indexWhere((chat) => chat.id == message.chatId);
    if (index < 0) {
      if (_unknownChatReloadInFlight) return;
      _unknownChatReloadInFlight = true;
      try {
        await load();
      } finally {
        _unknownChatReloadInFlight = false;
      }
      return;
    }
    final chats = [...state.chats];
    final current = chats.removeAt(index);
    chats.insert(
      0,
      current.copyWith(
        lastMessage: _messagePreview(message),
        unreadCount: isOpen ? 0 : current.unreadCount + 1,
        lastMessageStatus: message.status,
        lastMessageSenderId: message.senderId,
        lastMessageType: message.type,
      ),
    );
    state = ChatListState(
      status: ChatListStatus.data,
      chats: chats,
      error: state.error,
      isCreating: state.isCreating,
    );
  }

  void markChatOpen(int chatId) {
    final index = state.chats.indexWhere((chat) => chat.id == chatId);
    if (index < 0 || state.chats[index].unreadCount == 0) return;
    final chats = [...state.chats];
    chats[index] = chats[index].copyWith(unreadCount: 0);
    state = ChatListState(
      status: state.status,
      chats: chats,
      error: state.error,
      isCreating: state.isCreating,
    );
  }
}

String _messagePreview(ChatMessage message) => switch (message.type) {
  ChatMessageType.image => 'Image',
  ChatMessageType.voice => 'Voice message',
  ChatMessageType.text || ChatMessageType.unknown =>
    message.text.trim().isEmpty ? 'Message' : message.text.trim(),
};

final chatSocketManagerProvider = Provider<ChatSocketManager>((ref) {
  final manager = ChatSocketManager(
    transport: IoSocketTransport(AppConfig.baseAppSocketUrl),
    storage: ref.watch(sessionStorageProvider),
  );
  ref.onDispose(manager.dispose);
  unawaited(manager.connect());
  return manager;
});

final chatConnectionStateProvider = StreamProvider<ChatConnectionState>((
  ref,
) async* {
  final manager = ref.watch(chatSocketManagerProvider);
  yield manager.connectionState;
  yield* manager.connectionStates;
});

final activeChatRegistryProvider = Provider<ActiveChatRegistry>((ref) {
  return ActiveChatRegistry();
});

class ActiveChatRegistry {
  int? _chatId;

  int? get chatId => _chatId;

  void open(int chatId) => _chatId = chatId;

  void close(int chatId) {
    if (_chatId == chatId) _chatId = null;
  }
}

final chatRealtimeProvider = Provider<void>((ref) {
  final subscription = ref.watch(chatSocketManagerProvider).events.listen((
    event,
  ) {
    if (event.name != ChatSocketManager.incoming) return;
    final message = ChatMessage.fromJson(event.data);
    final isOpen =
        ref.read(activeChatRegistryProvider).chatId == message.chatId;
    unawaited(
      ref
          .read(chatListControllerProvider.notifier)
          .applyMessage(message, isOpen: isOpen),
    );
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

final chatMessagesControllerProvider = NotifierProvider.autoDispose
    .family<ChatMessagesController, ChatMessagesState, int>(
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

  Future<bool> send(String rawText) async {
    final text = rawText.trim();
    final userId = ref.read(authControllerProvider).user?.id;
    if (text.isEmpty ||
        userId == null ||
        state.isSending ||
        _socket.connectionState != ChatConnectionState.connected) {
      return false;
    }
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
    return true;
  }

  bool retry(String localId) {
    if (state.isSending ||
        _socket.connectionState != ChatConnectionState.connected) {
      return false;
    }
    final index = state.messages.indexWhere(
      (message) =>
          message.localId == localId &&
          message.status == ChatMessageStatus.failed,
    );
    if (index < 0) return false;
    final message = state.messages[index];
    _replace(
      localId,
      message.copyWith(status: ChatMessageStatus.sending),
      isSending: true,
      clearError: true,
    );
    _socket.sendMessage(
      chatId: chatId,
      text: message.text,
      externalId: localId,
    );
    return true;
  }

  void retryHistory() {
    state = ChatMessagesState(
      messages: state.messages,
      isLoading: true,
      isSending: state.isSending,
    );
    _socket.requestHistory(chatId);
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
      _merge(history, isLoading: false, clearError: true);
      final userId = ref.read(authControllerProvider).user?.id;
      final unreadIds = history
          .where(
            (message) =>
                message.id != null &&
                message.senderId != userId &&
                message.status != ChatMessageStatus.read,
          )
          .map((message) => message.id!)
          .toList(growable: false);
      if (unreadIds.isNotEmpty) {
        _socket.markDelivered(unreadIds);
        _socket.markRead(unreadIds);
      }
      ref.read(chatListControllerProvider.notifier).markChatOpen(chatId);
      return;
    }
    if (event.name == ChatSocketManager.incoming) {
      if (_int(event.data['chat_id']) != chatId) return;
      final message = ChatMessage.fromJson(event.data, chatId: chatId);
      _merge([message], isLoading: false);
      final userId = ref.read(authControllerProvider).user?.id;
      if (message.id != null && message.senderId != userId) {
        _socket.markDelivered([message.id!]);
        _socket.markRead([message.id!]);
      }
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
      final acknowledged = current.copyWith(
        id: _int(event.data['id']),
        status: _status(event.data['status']),
        createdAt: DateTime.tryParse(
          event.data['created_at']?.toString() ?? '',
        ),
      );
      _replace(localId, acknowledged, isSending: false, clearError: true);
      unawaited(
        ref
            .read(chatListControllerProvider.notifier)
            .applyMessage(acknowledged, isOpen: true),
      );
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
      return;
    }
    if (event.name == ChatSocketManager.allRead) {
      if (_int(event.data['chat_id']) != chatId) return;
      final userId = ref.read(authControllerProvider).user?.id;
      state = ChatMessagesState(
        messages: [
          for (final message in state.messages)
            if (message.senderId == userId)
              message.copyWith(status: ChatMessageStatus.read)
            else
              message,
        ],
        isLoading: state.isLoading,
        isSending: state.isSending,
        error: state.error,
      );
      return;
    }
    if (event.name == ChatSocketManager.socketError) {
      final eventChatId = _int(event.data['chat_id']);
      if (eventChatId != null && eventChatId != chatId) return;
      final hasPending = state.messages.any(
        (message) => message.status == ChatMessageStatus.sending,
      );
      state = ChatMessagesState(
        messages: [
          for (final message in state.messages)
            if (message.status == ChatMessageStatus.sending)
              message.copyWith(status: ChatMessageStatus.failed)
            else
              message,
        ],
        isLoading: false,
        isSending: false,
        error: hasPending
            ? const ChatSendFailure()
            : const ChatHistoryFailure(),
      );
    }
  }

  void _merge(
    List<ChatMessage> additions, {
    bool? isLoading,
    bool clearError = false,
  }) {
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
      error: clearError ? null : state.error,
    );
  }

  void _replace(
    String localId,
    ChatMessage replacement, {
    bool? isSending,
    bool clearError = false,
  }) {
    state = ChatMessagesState(
      messages: [
        for (final message in state.messages)
          if (message.localId == localId) replacement else message,
      ],
      isLoading: state.isLoading,
      isSending: isSending ?? state.isSending,
      error: clearError ? null : state.error,
    );
  }
}

class ChatSendFailure implements Exception {
  const ChatSendFailure();
}

class ChatHistoryFailure implements Exception {
  const ChatHistoryFailure();
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
