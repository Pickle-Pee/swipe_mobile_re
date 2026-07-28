import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_providers.dart';
import 'package:swipe_mobile_re/features/auth/application/auth_state.dart';
import 'package:swipe_mobile_re/features/auth/data/session_storage.dart';
import 'package:swipe_mobile_re/features/auth/domain/auth_models.dart';
import 'package:swipe_mobile_re/features/chat/application/chat_providers.dart';
import 'package:swipe_mobile_re/features/chat/application/chat_socket.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_models.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_repository.dart';

void main() {
  test(
    'double send is blocked and explicit failure retries one local row',
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);
      final provider = chatMessagesControllerProvider(7);
      final listener = harness.container.listen<ChatMessagesState>(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(listener.close);
      await pumpEventQueue();
      final controller = harness.container.read(provider.notifier);

      final first = controller.send('Hello from the client');
      final second = controller.send('Duplicate tap');

      expect(await first, isTrue);
      expect(await second, isFalse);
      expect(_emissions(harness.transport, 'send_message'), hasLength(1));
      final optimistic = harness.container.read(provider).messages.single;
      expect(optimistic.status, ChatMessageStatus.sending);

      harness.transport.fire('error', {'chat_id': 7, 'error': 'send failed'});
      await pumpEventQueue();
      expect(
        harness.container.read(provider).messages.single.status,
        ChatMessageStatus.failed,
      );

      expect(controller.retry(optimistic.localId), isTrue);
      expect(harness.container.read(provider).messages, hasLength(1));
      expect(_emissions(harness.transport, 'send_message'), hasLength(2));
      expect(
        (_emissions(harness.transport, 'send_message').last.$2
            as Map)['external_message_id'],
        optimistic.localId,
      );

      harness.transport.fire('completer', {
        'chat_id': 7,
        'id': 90,
        'status': 1,
        'external_message_id': optimistic.localId,
        'created_at': '2026-07-22T08:30:00Z',
      });
      await pumpEventQueue();
      final acknowledged = harness.container.read(provider);
      expect(acknowledged.messages, hasLength(1));
      expect(acknowledged.messages.single.id, 90);
      expect(acknowledged.messages.single.status, ChatMessageStatus.delivered);
      expect(acknowledged.isSending, isFalse);
    },
  );

  test(
    'loads latest and older pages in stable order without duplicates',
    () async {
      final repository = _ChatRepository(
        messageResponses: [
          () async => _page(
            List.generate(30, (index) => index + 31),
            nextCursor: 'before-31',
            hasMore: true,
          ),
          () async => _page(
            List.generate(31, (index) => index + 1),
            nextCursor: null,
            hasMore: false,
          ),
        ],
      );
      final harness = await _Harness.create(repository: repository);
      addTearDown(harness.dispose);
      final provider = chatMessagesControllerProvider(7);
      final listener = harness.container.listen<ChatMessagesState>(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(listener.close);

      await pumpEventQueue();
      var state = harness.container.read(provider);
      expect(
        state.messages.map((message) => message.id),
        List.generate(30, (index) => index + 31),
      );
      expect(state.hasMore, isTrue);
      expect(state.nextCursor, 'before-31');
      expect(repository.messageCalls, hasLength(1));
      expect(repository.messageCalls.single.before, isNull);
      expect(repository.messageCalls.single.limit, 30);

      await harness.container.read(provider.notifier).loadOlder();

      state = harness.container.read(provider);
      expect(state.messages, hasLength(60));
      expect(
        state.messages.map((message) => message.id),
        List.generate(60, (index) => index + 1),
      );
      expect(state.hasMore, isFalse);
      expect(state.nextCursor, isNull);
      expect(repository.messageCalls.last.before, 'before-31');
    },
  );

  test(
    'guards concurrent older requests and exposes retryable errors',
    () async {
      final older = Completer<ChatMessagePage>();
      final repository = _ChatRepository(
        messageResponses: [
          () async => _page(
            List.generate(30, (index) => index + 31),
            nextCursor: 'older',
            hasMore: true,
          ),
          () => older.future,
          () async => throw StateError('temporary failure'),
          () async => _page(
            List.generate(30, (index) => index + 1),
            nextCursor: null,
            hasMore: false,
          ),
        ],
      );
      final harness = await _Harness.create(repository: repository);
      addTearDown(harness.dispose);
      final provider = chatMessagesControllerProvider(7);
      final listener = harness.container.listen<ChatMessagesState>(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(listener.close);
      await pumpEventQueue();
      final controller = harness.container.read(provider.notifier);

      final first = controller.loadOlder();
      final duplicate = controller.loadOlder();
      expect(repository.messageCalls, hasLength(2));
      expect(harness.container.read(provider).isLoadingOlder, isTrue);
      older.complete(
        _page(
          List.generate(15, (index) => index + 16),
          nextCursor: 'older-again',
          hasMore: true,
        ),
      );
      await Future.wait([first, duplicate]);
      expect(repository.messageCalls, hasLength(2));

      await controller.loadOlder();
      var state = harness.container.read(provider);
      expect(state.isLoadingOlder, isFalse);
      expect(state.loadOlderError, isA<ChatOlderHistoryFailure>());
      expect(state.nextCursor, 'older-again');

      controller.retryOlder();
      await pumpEventQueue();
      state = harness.container.read(provider);
      expect(state.loadOlderError, isNull);
      expect(state.hasMore, isFalse);
      expect(
        state.messages.map((message) => message.id),
        List.generate(60, (index) => index + 1),
      );
      expect(repository.messageCalls, hasLength(4));
    },
  );

  test(
    'reconnect syncs latest page but preserves the older-page cursor',
    () async {
      final repository = _ChatRepository(
        messageResponses: [
          () async => _page(
            List.generate(30, (index) => index + 61),
            nextCursor: 'before-61',
            hasMore: true,
          ),
          () async => _page(
            List.generate(30, (index) => index + 31),
            nextCursor: 'before-31',
            hasMore: true,
          ),
          () async => _page(
            List.generate(30, (index) => index + 62),
            nextCursor: 'latest-cursor-must-not-win',
            hasMore: true,
          ),
        ],
      );
      final harness = await _Harness.create(repository: repository);
      addTearDown(harness.dispose);
      final provider = chatMessagesControllerProvider(7);
      final listener = harness.container.listen<ChatMessagesState>(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(listener.close);
      await pumpEventQueue();
      await harness.container.read(provider.notifier).loadOlder();

      await _reconnect(harness);

      final state = harness.container.read(provider);
      expect(state.messages, hasLength(61));
      expect(
        state.messages.map((message) => message.id),
        List.generate(61, (index) => index + 31),
      );
      expect(state.nextCursor, 'before-31');
      expect(state.hasMore, isTrue);
      expect(repository.messageCalls, hasLength(3));
      expect(repository.messageCalls.last.before, isNull);
      expect(
        _emissions(harness.transport, ChatSocketManager.join),
        hasLength(2),
      );
      expect(_emissions(harness.transport, 'get_messages'), isEmpty);
      expect(harness.manager.connectionState, ChatConnectionState.connected);
    },
  );

  test('missed ack is reconciled by REST and replayed socket data', () async {
    final repository = _ChatRepository();
    final harness = await _Harness.create(repository: repository);
    addTearDown(harness.dispose);
    final provider = chatMessagesControllerProvider(7);
    final listener = harness.container.listen<ChatMessagesState>(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(listener.close);
    await pumpEventQueue();
    final controller = harness.container.read(provider.notifier);

    expect(await controller.send('Survives a missed ack'), isTrue);
    final optimistic = harness.container.read(provider).messages.single;
    final serverMessage = _message(
      99,
      text: optimistic.text,
      createdAt: optimistic.createdAt.add(const Duration(seconds: 1)),
      status: ChatMessageStatus.delivered,
    );
    repository.messageResponses.add(
      () async => ChatMessagePage(
        items: [serverMessage],
        nextCursor: null,
        hasMore: false,
      ),
    );

    await _reconnect(harness);

    harness.transport.fire('new_message', _messageJson(serverMessage));
    await pumpEventQueue();
    final reconciled = harness.container.read(provider);
    expect(reconciled.messages, hasLength(1));
    expect(reconciled.messages.single.id, 99);
    expect(reconciled.messages.single.localId, optimistic.localId);
    expect(reconciled.messages.single.status, ChatMessageStatus.delivered);
    expect(reconciled.isSending, isFalse);
    expect(await controller.send('Next message is unblocked'), isTrue);
    expect(harness.container.read(provider).messages, hasLength(2));
  });

  test(
    'global realtime uses active chat and deduplicates unread updates',
    () async {
      final harness = await _Harness.create(chats: [_summary(7), _summary(8)]);
      addTearDown(harness.dispose);
      await harness.container.read(chatListControllerProvider.notifier).load();
      harness.container.read(chatRealtimeProvider);
      final registry = harness.container.read(activeChatRegistryProvider);
      registry.open(7);

      harness.transport.fire('new_message', _incoming(40, 7));
      await pumpEventQueue();
      expect(
        harness.container
            .read(chatListControllerProvider)
            .chats
            .firstWhere((chat) => chat.id == 7)
            .unreadCount,
        0,
      );

      registry.close(7);
      harness.transport.fire('new_message', _incoming(41, 7));
      harness.transport.fire('new_message', _incoming(41, 7));
      await pumpEventQueue();
      final chat = harness.container
          .read(chatListControllerProvider)
          .chats
          .firstWhere((item) => item.id == 7);
      expect(chat.unreadCount, 1);
    },
  );
}

class _Harness {
  _Harness({
    required this.container,
    required this.storage,
    required this.manager,
    required this.transport,
    required this.repository,
  });

  final ProviderContainer container;
  final SessionStorage storage;
  final ChatSocketManager manager;
  final _FakeSocketTransport transport;
  final _ChatRepository repository;

  static Future<_Harness> create({
    List<ChatSummary> chats = const [],
    _ChatRepository? repository,
  }) async {
    final storage = SessionStorage(backend: _MemoryStorage());
    await storage.saveTokens('access', 'refresh');
    final transport = _FakeSocketTransport();
    final manager = ChatSocketManager(transport: transport, storage: storage);
    await manager.connect();
    transport.connectedValue = true;
    transport.fire('connect');
    await pumpEventQueue();
    transport.fire('auth_response', {'status': 200});
    await pumpEventQueue();
    final chatRepository = repository ?? _ChatRepository(chats: chats);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_AuthenticatedAuthController.new),
        chatSocketManagerProvider.overrideWithValue(manager),
        chatRepositoryProvider.overrideWithValue(chatRepository),
      ],
    );
    return _Harness(
      container: container,
      storage: storage,
      manager: manager,
      transport: transport,
      repository: chatRepository,
    );
  }

  Future<void> dispose() async {
    container.dispose();
    await manager.dispose();
    await storage.dispose();
  }
}

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(AuthUser(id: 1));
}

class _MemoryStorage implements SecureStorageBackend {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _FakeSocketTransport implements SocketTransport {
  bool connectedValue = false;
  final handlers = <String, void Function(dynamic data)>{};
  final emitted = <(String, Object)>[];

  @override
  bool get connected => connectedValue;

  @override
  void connect() {}

  @override
  void disconnect() => connectedValue = false;

  @override
  void dispose() {}

  @override
  void emit(String event, Object data) => emitted.add((event, data));

  @override
  void off(String event) => handlers.remove(event);

  @override
  void on(String event, void Function(dynamic data) handler) {
    handlers[event] = handler;
  }

  void fire(String event, [dynamic data]) => handlers[event]?.call(data);
}

typedef _MessageResponse = Future<ChatMessagePage> Function();

class _ChatRepository implements ChatRepository {
  _ChatRepository({
    this.chats = const [],
    List<_MessageResponse>? messageResponses,
  }) : messageResponses = messageResponses ?? [];

  final List<ChatSummary> chats;
  final List<_MessageResponse> messageResponses;
  final List<({int chatId, String? before, int limit})> messageCalls = [];

  @override
  Future<int> createChat(int userId) async => 7;

  @override
  Future<ChatDetails> getChatDetails(int chatId) => throw UnimplementedError();

  @override
  Future<int?> getChatIdByUserId(int userId) async => 7;

  @override
  Future<List<ChatSummary>> getChats() async => chats;

  @override
  Future<ChatMessagePage> getMessages(
    int chatId, {
    String? before,
    int limit = 30,
  }) {
    messageCalls.add((chatId: chatId, before: before, limit: limit));
    if (messageResponses.isEmpty) {
      return Future.value(
        const ChatMessagePage(items: [], nextCursor: null, hasMore: false),
      );
    }
    return messageResponses.removeAt(0)();
  }
}

Future<void> _reconnect(_Harness harness) async {
  harness.transport.connectedValue = false;
  harness.transport.fire('disconnect');
  harness.transport.fire('reconnect_attempt');
  harness.transport.connectedValue = true;
  harness.transport.fire('connect');
  await pumpEventQueue();
  harness.transport.fire('auth_response', {'status': 200});
  await pumpEventQueue();
}

ChatMessagePage _page(
  List<int> ids, {
  required String? nextCursor,
  required bool hasMore,
}) => ChatMessagePage(
  items: ids.map(_message).toList(growable: false),
  nextCursor: nextCursor,
  hasMore: hasMore,
);

ChatMessage _message(
  int id, {
  String? text,
  int senderId = 1,
  DateTime? createdAt,
  ChatMessageStatus status = ChatMessageStatus.read,
}) => ChatMessage(
  id: id,
  localId: 'server-$id',
  chatId: 7,
  senderId: senderId,
  text: text ?? 'Message $id',
  status: status,
  createdAt: createdAt ?? DateTime.utc(2026, 7, 22, 8, 0, id),
);

Map<String, Object> _messageJson(ChatMessage message) => {
  'message_id': message.id!,
  'message': message.text,
  'chat_id': message.chatId,
  'sender_id': message.senderId,
  'status': 1,
  'message_type': 'text',
  'created_at': message.createdAt.toIso8601String(),
};

List<(String, Object)> _emissions(
  _FakeSocketTransport transport,
  String event,
) => transport.emitted.where((emission) => emission.$1 == event).toList();

Map<String, Object> _incoming(int id, int chatId) => {
  'message_id': id,
  'message': 'Incoming $id',
  'chat_id': chatId,
  'sender_id': 2,
  'status': 1,
  'message_type': 'text',
  'created_at': '2026-07-22T08:00:00Z',
};

ChatSummary _summary(int id) => ChatSummary(
  id: id,
  user: ChatUser(
    id: id + 100,
    firstName: 'User $id',
    age: null,
    avatarUrl: null,
    status: null,
  ),
  createdAt: DateTime(2026, 7, 22),
  lastMessage: 'Previous',
  unreadCount: 0,
);
