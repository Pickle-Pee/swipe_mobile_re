import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/auth/data/session_storage.dart';
import 'package:swipe_mobile_re/features/chat/application/chat_socket.dart';

void main() {
  test(
    'uses one connection and authenticates again when token changes',
    () async {
      final backend = MemoryStorage();
      final storage = SessionStorage(backend: backend);
      final transport = FakeSocketTransport();
      await storage.saveTokens('first', 'refresh');
      final manager = ChatSocketManager(transport: transport, storage: storage);
      addTearDown(manager.dispose);
      addTearDown(storage.dispose);

      await manager.connect();
      await manager.connect();
      expect(transport.connectCalls, 1);
      expect(
        transport.listenerCounts.values.every((count) => count == 1),
        isTrue,
      );

      transport.connectedValue = true;
      transport.fire('connect');
      await pumpEventQueue();
      expect(transport.emitted.last.$1, 'authenticate');
      expect(transport.emitted.last.$2, {'token': 'first'});

      await storage.saveTokens('second', 'refresh');
      await pumpEventQueue();
      expect(transport.emitted.last.$1, 'authenticate');
      expect(transport.emitted.last.$2, {'token': 'second'});
    },
  );

  test(
    'queues history until authenticated and disconnects on logout',
    () async {
      final backend = MemoryStorage();
      final storage = SessionStorage(backend: backend);
      final transport = FakeSocketTransport();
      await storage.saveTokens('token', 'refresh');
      final manager = ChatSocketManager(transport: transport, storage: storage);
      addTearDown(manager.dispose);
      addTearDown(storage.dispose);

      manager.requestHistory(7);
      await pumpEventQueue();
      transport.connectedValue = true;
      transport.fire('connect');
      await pumpEventQueue();
      transport.fire('auth_response', {'status': 200});

      final history = transport.emitted.singleWhere(
        (emission) => emission.$1 == 'get_messages',
      );
      expect(history.$2, {'chat_id': 7});
      await storage.clear();
      await pumpEventQueue();
      expect(transport.disconnectCalls, 1);
    },
  );

  test(
    'exposes real connection states and removes every listener on dispose',
    () async {
      final backend = MemoryStorage();
      final storage = SessionStorage(backend: backend);
      final transport = FakeSocketTransport();
      await storage.saveTokens('token', 'refresh');
      final manager = ChatSocketManager(transport: transport, storage: storage);
      final states = <ChatConnectionState>[];
      final subscription = manager.connectionStates.listen(states.add);

      await manager.connect();
      expect(manager.connectionState, ChatConnectionState.connecting);
      transport.connectedValue = true;
      transport.fire('connect');
      await pumpEventQueue();
      transport.fire('auth_response', {'status': 200});
      await pumpEventQueue();
      expect(manager.connectionState, ChatConnectionState.connected);

      transport.fire('disconnect');
      expect(manager.connectionState, ChatConnectionState.reconnecting);
      transport.fire('connect_error');
      expect(manager.connectionState, ChatConnectionState.failed);
      expect(states, contains(ChatConnectionState.connected));

      await subscription.cancel();
      await manager.dispose();
      await storage.dispose();
      expect(transport.handlers, isEmpty);
    },
  );
}

class MemoryStorage implements SecureStorageBackend {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class FakeSocketTransport implements SocketTransport {
  bool connectedValue = false;
  int connectCalls = 0;
  int disconnectCalls = 0;
  final handlers = <String, void Function(dynamic data)>{};
  final listenerCounts = <String, int>{};
  final emitted = <(String, Object)>[];

  @override
  bool get connected => connectedValue;
  @override
  void connect() => connectCalls++;
  @override
  void disconnect() {
    disconnectCalls++;
    connectedValue = false;
  }

  @override
  void dispose() {}
  @override
  void emit(String event, Object data) => emitted.add((event, data));
  @override
  void off(String event) => handlers.remove(event);
  @override
  void on(String event, void Function(dynamic data) handler) {
    handlers[event] = handler;
    listenerCounts[event] = (listenerCounts[event] ?? 0) + 1;
  }

  void fire(String event, [dynamic data]) => handlers[event]?.call(data);
}
