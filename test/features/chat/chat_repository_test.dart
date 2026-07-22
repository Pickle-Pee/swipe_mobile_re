import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/core/network/api_client.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_models.dart';
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
          'last_message_status': 2,
          'last_message_sender_id': 1,
          'last_message_type': 'text',
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
    expect(chats.single.lastMessageStatus, ChatMessageStatus.read);
    expect(chats.single.lastMessageSenderId, 1);
    expect(chats.single.lastMessageType, ChatMessageType.text);
  });

  test('createChat returns backend id', () async {
    final adapter = MockHttpAdapter((options) async {
      expect(options.path, '/communication/create_chat');
      expect(options.data, {'user_id': 9});
      return jsonResponse(200, {'chat_id': 7});
    });

    expect(await createRepository(adapter).createChat(9), 7);
  });

  test('loads one bounded message page with cursor query parameters', () async {
    final adapter = MockHttpAdapter((options) async {
      expect(options.method, 'GET');
      expect(options.path, '/communication/7/messages');
      expect(options.queryParameters, {'limit': 30, 'before': 'cursor-value'});
      return jsonResponse(200, {
        'items': [
          {
            'message_id': 10,
            'chat_id': 7,
            'sender_id': 2,
            'message': 'Older image',
            'status': 1,
            'message_type': 'image',
            'created_at': '2026-07-22T08:00:00Z',
            'media_urls': ['https://cdn.example.test/message.jpg'],
            'voice_data': null,
          },
          {
            'message_id': 11,
            'chat_id': 7,
            'sender_id': 1,
            'message': '',
            'status': 2,
            'message_type': 'voice',
            'created_at': '2026-07-22T08:01:00Z',
            'media_urls': <String>[],
            'voice_data': [1, 2, 255],
          },
        ],
        'next_cursor': 'next-page',
        'has_more': true,
      });
    });

    final page = await createRepository(
      adapter,
    ).getMessages(7, before: 'cursor-value');

    expect(page.items.map((message) => message.id), [10, 11]);
    expect(page.items.first.type, ChatMessageType.image);
    expect(page.items.first.mediaUrls, [
      'https://cdn.example.test/message.jpg',
    ]);
    expect(page.items.last.type, ChatMessageType.voice);
    expect(page.items.last.voiceData, [1, 2, 255]);
    expect(page.items.last.status, ChatMessageStatus.read);
    expect(page.nextCursor, 'next-page');
    expect(page.hasMore, isTrue);
  });

  test('omits before on the latest page request', () async {
    final adapter = MockHttpAdapter((options) async {
      expect(options.path, '/communication/4/messages');
      expect(options.queryParameters, {'limit': 12});
      return jsonResponse(200, {
        'items': <Object>[],
        'next_cursor': null,
        'has_more': false,
      });
    });

    final page = await createRepository(adapter).getMessages(4, limit: 12);

    expect(page.items, isEmpty);
    expect(page.nextCursor, isNull);
    expect(page.hasMore, isFalse);
  });

  test('rejects a response that promises another page without a cursor', () {
    expect(
      () => ChatMessagePage.fromJson({
        'items': <Object>[],
        'next_cursor': null,
        'has_more': true,
      }, chatId: 7),
      throwsFormatException,
    );
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
