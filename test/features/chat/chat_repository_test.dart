import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/core/network/api_client.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_repository.dart';

void main() {
  test('loads server chat summaries', () async {
    final adapter = MockHttpAdapter(
      (options) async => jsonResponse(200, [
        {
          'chat_id': 5,
          'created_at': '2026-07-12T12:30:00',
          'last_message': 'Hello',
          'unread_count': 2,
          'user': {
            'user_id': 9,
            'first_name': 'API user',
            'user_age': 30,
            'avatar_url': null,
            'status': 'online',
          },
        },
      ]),
    );
    final repository = createRepository(adapter);

    final chats = await repository.getChats();

    expect(chats.single.id, 5);
    expect(chats.single.user.firstName, 'API user');
    expect(chats.single.lastMessage, 'Hello');
    expect(chats.single.unreadCount, 2);
  });

  test('createChat returns backend id', () async {
    final adapter = MockHttpAdapter((options) async {
      expect(options.path, '/communication/create_chat');
      expect(options.data, {'user_id': 9});
      return jsonResponse(200, {'chat_id': 7});
    });

    expect(await createRepository(adapter).createChat(9), 7);
  });
}

DioChatRepository createRepository(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  return DioChatRepository(
    ApiClient(dio: dio, tokenStore: EmptyTokenStore(), logSink: (_) {}),
  );
}

typedef MockHandler = Future<ResponseBody> Function(RequestOptions options);

class MockHttpAdapter implements HttpClientAdapter {
  MockHttpAdapter(this._handler);
  final MockHandler _handler;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => _handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int statusCode, Object body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

class EmptyTokenStore implements ApiTokenStore {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<String?> readRefreshToken() async => null;
  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {}
}
