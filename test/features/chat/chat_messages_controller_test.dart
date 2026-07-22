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
      final controller = harness.container.read(provider.notifier);

      final first = controller.send('Hello from the client');
      final second = controller.send('Duplicate tap');

      expect(await first, isTrue);
      expect(await second, isFalse);
      expect(_emissions(harness.transport, 'send_message'), hasLength(1));
      final optimistic = harness.container.read(provider).messages.single;
      expect(optimistic.status, ChatMessageStatus.sending);

      harness.transport.fire('error', {'error': 'send failed'});
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
    'history and reconnect events merge by server id without duplicates',
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
      final history = {
        'chatId': 7,
        'messages': [
          {
            'message_id': 12,
            'message': 'Stable history',
            'sender_id': 2,
            'status': 1,
            'message_type': 'text',
            'created_at': '2026-07-22T08:00:00Z',
            'media_urls': <String>[],
          },
        ],
      };

      harness.transport.fire('get_messages', history);
      harness.transport.fire('get_messages', history);
      await pumpEventQueue();

      expect(harness.container.read(provider).messages, hasLength(1));

      harness.transport.fire('disconnect');
      harness.transport.fire('reconnect_attempt');
      harness.transport.connectedValue = true;
      harness.transport.fire('connect');
      await pumpEventQueue();
      harness.transport.fire('auth_response', {'status': 200});
      await pumpEventQueue();
      harness.transport.fire('get_messages', history);
      await pumpEventQueue();

      expect(harness.container.read(provider).messages, hasLength(1));
      expect(harness.manager.connectionState, ChatConnectionState.connected);
    },
  );

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
  });

  final ProviderContainer container;
  final SessionStorage storage;
  final ChatSocketManager manager;
  final _FakeSocketTransport transport;

  static Future<_Harness> create({List<ChatSummary> chats = const []}) async {
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
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_AuthenticatedAuthController.new),
        chatSocketManagerProvider.overrideWithValue(manager),
        chatRepositoryProvider.overrideWithValue(_ChatRepository(chats)),
      ],
    );
    return _Harness(
      container: container,
      storage: storage,
      manager: manager,
      transport: transport,
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

class _ChatRepository implements ChatRepository {
  _ChatRepository(this.chats);

  final List<ChatSummary> chats;

  @override
  Future<int> createChat(int userId) async => 7;

  @override
  Future<ChatDetails> getChatDetails(int chatId) => throw UnimplementedError();

  @override
  Future<int?> getChatIdByUserId(int userId) async => 7;

  @override
  Future<List<ChatSummary>> getChats() async => chats;
}

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
