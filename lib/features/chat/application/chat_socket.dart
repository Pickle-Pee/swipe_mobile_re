import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../auth/data/session_storage.dart';

abstract interface class SocketTransport {
  bool get connected;
  void connect();
  void disconnect();
  void dispose();
  void emit(String event, Object data);
  void on(String event, void Function(dynamic data) handler);
  void off(String event);
}

class IoSocketTransport implements SocketTransport {
  IoSocketTransport(String url)
    : _socket = io.io(
        url,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableReconnection()
            .build(),
      );

  final io.Socket _socket;

  @override
  bool get connected => _socket.connected;
  @override
  void connect() => _socket.connect();
  @override
  void disconnect() => _socket.disconnect();
  @override
  void dispose() => _socket.dispose();
  @override
  void emit(String event, Object data) => _socket.emit(event, data);
  @override
  void on(String event, void Function(dynamic data) handler) =>
      _socket.on(event, handler);
  @override
  void off(String event) => _socket.off(event);
}

class ChatSocketEvent {
  const ChatSocketEvent(this.name, this.data);
  final String name;
  final Map<String, dynamic> data;
}

enum ChatConnectionState {
  connecting,
  connected,
  reconnecting,
  offline,
  failed,
}

class ChatSocketManager {
  ChatSocketManager({
    required SocketTransport transport,
    required SessionStorage storage,
  }) : _transport = transport,
       _storage = storage {
    _bindListeners();
    _tokenSubscription = storage.accessTokenChanges.listen(_onTokenChanged);
  }

  static const authenticated = 'authenticated';
  static const history = 'get_messages';
  static const incoming = 'new_message';
  static const completed = 'completer';
  static const statusUpdate = 'message_status_update';
  static const allRead = 'all_messages_read';
  static const socketError = 'error';

  final SocketTransport _transport;
  final SessionStorage _storage;
  final _events = StreamController<ChatSocketEvent>.broadcast();
  final _connectionStates = StreamController<ChatConnectionState>.broadcast();
  final List<MapEntry<String, Object>> _pending = [];
  late final StreamSubscription<String?> _tokenSubscription;
  bool _isAuthenticated = false;
  bool _connectRequested = false;
  bool _hasConnected = false;
  ChatConnectionState _connectionState = ChatConnectionState.offline;

  Stream<ChatSocketEvent> get events => _events.stream;
  Stream<ChatConnectionState> get connectionStates => _connectionStates.stream;
  bool get isAuthenticated => _isAuthenticated;
  ChatConnectionState get connectionState => _connectionState;

  Future<void> connect() async {
    if (_connectRequested) return;
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      _setConnectionState(ChatConnectionState.offline);
      return;
    }
    _connectRequested = true;
    if (!_transport.connected) {
      _setConnectionState(
        _hasConnected
            ? ChatConnectionState.reconnecting
            : ChatConnectionState.connecting,
      );
      _transport.connect();
    }
  }

  void requestHistory(int chatId) =>
      _emitAuthenticated(history, {'chat_id': chatId});

  void sendMessage({
    required int chatId,
    required String text,
    required String externalId,
  }) => _emitAuthenticated('send_message', {
    'chat_id': chatId,
    'message': text,
    'external_message_id': externalId,
    'message_type': 'text',
  });

  void markDelivered(Iterable<int> ids) =>
      _emitAuthenticated('message_delivered', {'message_ids': ids.toList()});

  void markRead(Iterable<int> ids) =>
      _emitAuthenticated('message_read', {'message_ids': ids.toList()});

  void disconnect() {
    _connectRequested = false;
    _isAuthenticated = false;
    _pending.clear();
    if (_transport.connected) _transport.disconnect();
    _setConnectionState(ChatConnectionState.offline);
  }

  void _bindListeners() {
    _transport.on('connect', (_) {
      _setConnectionState(
        _hasConnected
            ? ChatConnectionState.reconnecting
            : ChatConnectionState.connecting,
      );
      unawaited(_authenticate());
    });
    _transport.on('disconnect', (_) {
      _isAuthenticated = false;
      _setConnectionState(
        _connectRequested
            ? ChatConnectionState.reconnecting
            : ChatConnectionState.offline,
      );
    });
    _transport.on('reconnect_attempt', (_) {
      _setConnectionState(ChatConnectionState.reconnecting);
    });
    _transport.on('connect_error', (_) {
      _isAuthenticated = false;
      _setConnectionState(ChatConnectionState.failed);
    });
    _transport.on('auth_response', (data) {
      final payload = _map(data);
      _isAuthenticated = payload['status'] == 200;
      if (!_isAuthenticated) {
        _setConnectionState(ChatConnectionState.failed);
        return;
      }
      _hasConnected = true;
      _setConnectionState(ChatConnectionState.connected);
      _events.add(ChatSocketEvent(authenticated, payload));
      for (final command in List.of(_pending)) {
        _transport.emit(command.key, command.value);
      }
      _pending.clear();
    });
    for (final event in [history, incoming, completed, statusUpdate, allRead]) {
      _transport.on(event, (data) {
        _events.add(ChatSocketEvent(event, _map(data)));
      });
    }
    _transport.on(socketError, (data) {
      _events.add(ChatSocketEvent(socketError, _map(data)));
    });
  }

  Future<void> _authenticate() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      disconnect();
      return;
    }
    _isAuthenticated = false;
    _setConnectionState(
      _hasConnected
          ? ChatConnectionState.reconnecting
          : ChatConnectionState.connecting,
    );
    _transport.emit('authenticate', {'token': token});
  }

  void _emitAuthenticated(String event, Object data) {
    if (_isAuthenticated) {
      _transport.emit(event, data);
    } else {
      _pending.add(MapEntry(event, data));
      unawaited(connect());
    }
  }

  void _onTokenChanged(String? token) {
    if (token == null || token.isEmpty) {
      disconnect();
    } else if (_transport.connected) {
      unawaited(_authenticate());
    } else {
      unawaited(connect());
    }
  }

  void _setConnectionState(ChatConnectionState value) {
    if (_connectionState == value || _connectionStates.isClosed) return;
    _connectionState = value;
    _connectionStates.add(value);
  }

  Map<String, dynamic> _map(dynamic value) => value is Map
      ? value.map((key, item) => MapEntry(key.toString(), item))
      : <String, dynamic>{};

  Future<void> dispose() async {
    await _tokenSubscription.cancel();
    for (final event in [
      'connect',
      'disconnect',
      'auth_response',
      history,
      incoming,
      completed,
      statusUpdate,
      allRead,
      socketError,
      'reconnect_attempt',
      'connect_error',
    ]) {
      _transport.off(event);
    }
    _transport.dispose();
    await _events.close();
    await _connectionStates.close();
  }
}
