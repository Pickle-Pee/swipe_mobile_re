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
  var hasAuthenticated = ref.watch(chatSocketManagerProvider).isAuthenticated;
  final subscription = ref.watch(chatSocketManagerProvider).events.listen((
    event,
  ) {
    if (event.name == ChatSocketManager.authenticated) {
      if (hasAuthenticated) {
        unawaited(ref.read(chatListControllerProvider.notifier).load());
      }
      hasAuthenticated = true;
      return;
    }
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

const _stateUnset = Object();

class ChatMessagesState {
  const ChatMessagesState({
    this.messages = const [],
    bool initialLoading = true,
    bool? isLoading,
    this.isLoadingOlder = false,
    this.loadOlderError,
    this.hasMore = false,
    this.nextCursor,
    this.isSending = false,
    this.error,
  }) : initialLoading = isLoading ?? initialLoading;

  final List<ChatMessage> messages;
  final bool initialLoading;
  final bool isLoadingOlder;
  final Object? loadOlderError;
  final bool hasMore;
  final String? nextCursor;
  final bool isSending;
  final Object? error;

  bool get isLoading => initialLoading;

  ChatMessagesState copyWith({
    List<ChatMessage>? messages,
    bool? initialLoading,
    bool? isLoadingOlder,
    Object? loadOlderError = _stateUnset,
    bool? hasMore,
    Object? nextCursor = _stateUnset,
    bool? isSending,
    Object? error = _stateUnset,
  }) => ChatMessagesState(
    messages: messages ?? this.messages,
    initialLoading: initialLoading ?? this.initialLoading,
    isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
    loadOlderError: identical(loadOlderError, _stateUnset)
        ? this.loadOlderError
        : loadOlderError,
    hasMore: hasMore ?? this.hasMore,
    nextCursor: identical(nextCursor, _stateUnset)
        ? this.nextCursor
        : nextCursor as String?,
    isSending: isSending ?? this.isSending,
    error: identical(error, _stateUnset) ? this.error : error,
  );
}

final chatMessagesControllerProvider = NotifierProvider.autoDispose
    .family<ChatMessagesController, ChatMessagesState, int>(
      ChatMessagesController.new,
    );

class ChatMessagesController extends Notifier<ChatMessagesState> {
  ChatMessagesController(this.chatId);

  static const _pageLimit = 30;

  final int chatId;
  StreamSubscription<ChatSocketEvent>? _subscription;
  bool _awaitingInitialAuthentication = false;
  bool _initialLoadInFlight = false;
  bool _latestSyncInFlight = false;
  bool _disposed = false;

  ChatSocketManager get _socket => ref.read(chatSocketManagerProvider);
  ChatRepository get _repository => ref.read(chatRepositoryProvider);

  @override
  ChatMessagesState build() {
    final socket = _socket;
    _subscription = socket.events.listen(_onEvent);
    _awaitingInitialAuthentication = !socket.isAuthenticated;
    socket.joinChat(chatId);
    ref.onDispose(() {
      _disposed = true;
      final subscription = _subscription;
      if (subscription != null) unawaited(subscription.cancel());
      socket.leaveChat(chatId);
    });
    scheduleMicrotask(() => unawaited(loadInitial()));
    return const ChatMessagesState();
  }

  Future<void> loadInitial() async {
    if (_initialLoadInFlight || _disposed) return;
    _initialLoadInFlight = true;
    state = state.copyWith(
      initialLoading: true,
      error: null,
      loadOlderError: null,
    );
    try {
      final page = await _repository.getMessages(chatId, limit: _pageLimit);
      if (_disposed) return;
      _merge(
        page.items,
        initialLoading: false,
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
        clearError: true,
        clearOlderError: true,
      );
      _markIncomingRead(page.items);
      ref.read(chatListControllerProvider.notifier).markChatOpen(chatId);
    } on Object {
      if (_disposed) return;
      state = state.copyWith(
        initialLoading: false,
        error: const ChatHistoryFailure(),
      );
    } finally {
      _initialLoadInFlight = false;
    }
  }

  Future<void> loadOlder() async {
    final cursor = state.nextCursor;
    if (_disposed ||
        state.initialLoading ||
        state.isLoadingOlder ||
        !state.hasMore ||
        cursor == null) {
      return;
    }

    state = state.copyWith(isLoadingOlder: true, loadOlderError: null);
    try {
      final page = await _repository.getMessages(
        chatId,
        before: cursor,
        limit: _pageLimit,
      );
      if (_disposed) return;
      _merge(
        page.items,
        isLoadingOlder: false,
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
        clearOlderError: true,
      );
      _markIncomingRead(page.items);
    } on Object {
      if (_disposed) return;
      state = state.copyWith(
        isLoadingOlder: false,
        loadOlderError: const ChatOlderHistoryFailure(),
      );
    }
  }

  Future<void> _syncLatest() async {
    if (_disposed || _initialLoadInFlight || _latestSyncInFlight) return;
    _latestSyncInFlight = true;
    try {
      final page = await _repository.getMessages(chatId, limit: _pageLimit);
      if (_disposed) return;
      final initializePagination = state.messages.isEmpty;
      _merge(
        page.items,
        initialLoading: false,
        hasMore: initializePagination ? page.hasMore : null,
        nextCursor: initializePagination ? page.nextCursor : _stateUnset,
        clearError: initializePagination,
      );
      _markIncomingRead(page.items);
      ref.read(chatListControllerProvider.notifier).markChatOpen(chatId);
    } on Object {
      if (_disposed || state.messages.isNotEmpty) return;
      state = state.copyWith(
        initialLoading: false,
        error: const ChatHistoryFailure(),
      );
    } finally {
      _latestSyncInFlight = false;
    }
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
    state = state.copyWith(
      messages: [...state.messages, optimistic],
      initialLoading: false,
      isSending: true,
      error: null,
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

  void retryHistory() => unawaited(loadInitial());

  void retryOlder() => unawaited(loadOlder());

  void _onEvent(ChatSocketEvent event) {
    if (event.name == ChatSocketManager.authenticated) {
      if (_awaitingInitialAuthentication) {
        _awaitingInitialAuthentication = false;
        return;
      }
      _socket.joinChat(chatId);
      unawaited(_syncLatest());
      return;
    }
    if (event.name == ChatSocketManager.incoming) {
      if (_int(event.data['chat_id']) != chatId) return;
      final message = ChatMessage.fromJson(event.data, chatId: chatId);
      _merge([message], initialLoading: false);
      _markIncomingRead([message]);
      return;
    }
    if (event.name == ChatSocketManager.completed) {
      if (_int(event.data['chat_id']) != chatId) return;
      final localId = event.data['external_message_id']?.toString();
      if (localId == null) return;
      final current = state.messages
          .where((message) => message.localId == localId)
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
      state = state.copyWith(
        messages: [
          for (final message in state.messages)
            if (message.senderId == userId)
              message.copyWith(status: ChatMessageStatus.read)
            else
              message,
        ],
      );
      return;
    }
    if (event.name == ChatSocketManager.socketError) {
      final eventChatId = _int(event.data['chat_id']);
      if (eventChatId != null && eventChatId != chatId) return;
      final hasPending = state.messages.any(
        (message) => message.status == ChatMessageStatus.sending,
      );
      if (!hasPending) return;
      state = state.copyWith(
        messages: [
          for (final message in state.messages)
            if (message.status == ChatMessageStatus.sending)
              message.copyWith(status: ChatMessageStatus.failed)
            else
              message,
        ],
        isSending: false,
        error: const ChatSendFailure(),
      );
    }
  }

  void _markIncomingRead(Iterable<ChatMessage> messages) {
    final userId = ref.read(authControllerProvider).user?.id;
    final unreadIds = messages
        .where(
          (message) =>
              message.id != null &&
              message.senderId != userId &&
              message.status != ChatMessageStatus.read,
        )
        .map((message) => message.id!)
        .toList(growable: false);
    if (unreadIds.isEmpty) return;
    _socket.markDelivered(unreadIds);
    _socket.markRead(unreadIds);
  }

  void _merge(
    List<ChatMessage> additions, {
    bool? initialLoading,
    bool? isLoadingOlder,
    bool? hasMore,
    Object? nextCursor = _stateUnset,
    bool clearError = false,
    bool clearOlderError = false,
  }) {
    final messages = [...state.messages];
    for (final addition in additions) {
      final index = _mergeIndex(messages, addition);
      if (index < 0) {
        messages.add(addition);
      } else {
        messages[index] = _mergeMessage(messages[index], addition);
      }
    }
    messages.sort(_compareMessages);
    state = state.copyWith(
      messages: messages,
      initialLoading: initialLoading,
      isLoadingOlder: isLoadingOlder,
      hasMore: hasMore,
      nextCursor: nextCursor,
      error: clearError ? null : _stateUnset,
      loadOlderError: clearOlderError ? null : _stateUnset,
    );
  }

  void _replace(
    String localId,
    ChatMessage replacement, {
    bool? isSending,
    bool clearError = false,
  }) {
    final messages = [
      for (final message in state.messages)
        if (message.localId == localId) replacement else message,
    ]..sort(_compareMessages);
    state = state.copyWith(
      messages: messages,
      isSending: isSending,
      error: clearError ? null : _stateUnset,
    );
  }

  int _mergeIndex(List<ChatMessage> messages, ChatMessage addition) {
    final exactIndex = messages.indexWhere(
      (item) =>
          (addition.id != null && item.id == addition.id) ||
          item.localId == addition.localId,
    );
    if (exactIndex >= 0 || addition.id == null) return exactIndex;

    var bestIndex = -1;
    var bestDifference = const Duration(minutes: 2);
    for (var index = 0; index < messages.length; index++) {
      final candidate = messages[index];
      if (!_canReconcileOptimistic(candidate, addition)) continue;
      final difference = candidate.createdAt
          .difference(addition.createdAt)
          .abs();
      if (difference <= bestDifference) {
        bestDifference = difference;
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  bool _canReconcileOptimistic(
    ChatMessage candidate,
    ChatMessage serverMessage,
  ) {
    if (candidate.id != null ||
        (candidate.status != ChatMessageStatus.sending &&
            candidate.status != ChatMessageStatus.failed)) {
      return false;
    }
    return candidate.chatId == serverMessage.chatId &&
        candidate.senderId == serverMessage.senderId &&
        candidate.text == serverMessage.text &&
        candidate.type == serverMessage.type &&
        _sameStrings(candidate.mediaUrls, serverMessage.mediaUrls);
  }

  ChatMessage _mergeMessage(ChatMessage current, ChatMessage incoming) {
    final currentHasClientId = current.localId != 'server-${current.id}';
    final incomingHasClientId = incoming.localId != 'server-${incoming.id}';
    final localId = currentHasClientId
        ? current.localId
        : incomingHasClientId
        ? incoming.localId
        : current.localId;
    return ChatMessage(
      id: incoming.id ?? current.id,
      localId: localId,
      chatId: incoming.chatId,
      senderId: incoming.senderId,
      text: incoming.text,
      status: _strongerStatus(current.status, incoming.status),
      createdAt: incoming.createdAt,
      type: incoming.type,
      mediaUrls: incoming.mediaUrls,
      voiceData: incoming.voiceData,
    );
  }
}

class ChatSendFailure implements Exception {
  const ChatSendFailure();
}

class ChatHistoryFailure implements Exception {
  const ChatHistoryFailure();
}

class ChatOlderHistoryFailure implements Exception {
  const ChatOlderHistoryFailure();
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

bool _sameStrings(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

int _compareMessages(ChatMessage first, ChatMessage second) {
  final timestamp = first.createdAt.compareTo(second.createdAt);
  if (timestamp != 0) return timestamp;
  if (first.id != null && second.id != null) {
    return first.id!.compareTo(second.id!);
  }
  if (first.id != null) return -1;
  if (second.id != null) return 1;
  return first.localId.compareTo(second.localId);
}

ChatMessageStatus _strongerStatus(
  ChatMessageStatus current,
  ChatMessageStatus incoming,
) {
  if ((current == ChatMessageStatus.sending ||
          current == ChatMessageStatus.failed) &&
      incoming != ChatMessageStatus.sending &&
      incoming != ChatMessageStatus.failed) {
    return incoming;
  }
  return _statusRank(incoming) >= _statusRank(current) ? incoming : current;
}

int _statusRank(ChatMessageStatus status) => switch (status) {
  ChatMessageStatus.failed => -2,
  ChatMessageStatus.sending => -1,
  ChatMessageStatus.sent => 0,
  ChatMessageStatus.delivered => 1,
  ChatMessageStatus.read => 2,
};
