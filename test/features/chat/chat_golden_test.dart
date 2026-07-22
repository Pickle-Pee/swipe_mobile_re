import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/chat/application/chat_providers.dart';
import 'package:swipe_mobile_re/features/chat/application/chat_socket.dart';
import 'package:swipe_mobile_re/features/chat/chat_list_screen.dart';
import 'package:swipe_mobile_re/features/chat/chat_screen.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_models.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';
import 'package:swipe_mobile_re/shared/ui/glass_tabbar.dart';

import '../../helpers/golden_profile_image.dart';

late MemoryImage _profileImage;
late MemoryImage _messageImage;

void main() {
  const phoneSize = Size(390, 844);

  setUpAll(() async {
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
    _profileImage = await createGoldenProfileImage();
    _messageImage = await createGoldenProfileImage(alternate: true);
  });

  testWidgets('Chats normal golden', (tester) async {
    await _pumpChatList(
      tester,
      ChatListState(
        status: ChatListStatus.data,
        chats: [
          _chat(id: 7, name: 'Mira', message: 'See you near the gallery?'),
          _chat(id: 8, name: 'Noor', message: 'That sounds perfect.'),
          _chat(id: 9, name: 'Alex', message: 'Sent a photo'),
        ],
      ),
      size: phoneSize,
    );
    await _expectGolden(tester, 'goldens/chats_normal.png');
  });

  testWidgets('Chats unread golden', (tester) async {
    await _pumpChatList(
      tester,
      ChatListState(
        status: ChatListStatus.data,
        chats: [
          _chat(
            id: 7,
            name: 'Mira',
            message: 'I found the tiny cinema you mentioned.',
            unread: 3,
            mine: false,
          ),
          _chat(id: 8, name: 'Noor', message: 'Coffee this weekend?'),
        ],
      ),
      size: phoneSize,
    );
    await _expectGolden(tester, 'goldens/chats_unread.png');
  });

  testWidgets('Chats empty golden', (tester) async {
    await _pumpChatList(
      tester,
      const ChatListState(status: ChatListStatus.empty),
      size: phoneSize,
    );
    await _expectGolden(tester, 'goldens/chats_empty.png');
  });

  testWidgets('Chats error golden', (tester) async {
    await _pumpChatList(
      tester,
      ChatListState(status: ChatListStatus.error, error: Exception('offline')),
      size: phoneSize,
    );
    await _expectGolden(tester, 'goldens/chats_error.png');
  });

  testWidgets('Chat normal golden', (tester) async {
    await _pumpConversation(
      tester,
      messages: [
        _message(id: 1, senderId: 2, text: 'Hey! How was your day?'),
        _message(
          id: 2,
          senderId: 1,
          text: 'Good. I finally visited that little gallery.',
          status: ChatMessageStatus.read,
        ),
        _message(id: 3, senderId: 2, text: 'The one near the river?'),
      ],
      size: phoneSize,
    );
    await _expectGolden(tester, 'goldens/chat_normal.png');
  });

  testWidgets('Chat long messages golden', (tester) async {
    await _pumpConversation(
      tester,
      messages: [
        _message(
          id: 4,
          senderId: 2,
          text:
              'A longer message verifies natural wrapping, readable rhythm, '
              'and stable bubble width without a blur layer in the scrolling list.',
        ),
        _message(
          id: 5,
          senderId: 1,
          text:
              'Perfect. The layout also needs to keep timestamps and delivery '
              'state clear when a reply spans several lines.',
          status: ChatMessageStatus.delivered,
        ),
      ],
      size: phoneSize,
    );
    await _expectGolden(tester, 'goldens/chat_long_messages.png');
  });

  testWidgets('Chat image golden', (tester) async {
    await _pumpConversation(
      tester,
      messages: [
        _message(
          id: 6,
          senderId: 2,
          text: 'A quiet place for the weekend.',
          type: ChatMessageType.image,
          mediaUrls: const ['memory://message'],
        ),
      ],
      size: phoneSize,
    );
    await _expectGolden(tester, 'goldens/chat_image.png');
  });

  testWidgets('Chat offline golden', (tester) async {
    await _pumpConversation(
      tester,
      messages: [_message(id: 7, senderId: 2, text: 'Are you still there?')],
      connectionState: ChatConnectionState.offline,
      initialText: 'My reply will wait',
      size: phoneSize,
    );
    await _expectGolden(tester, 'goldens/chat_offline.png');
  });

  testWidgets('Chat send error golden', (tester) async {
    await _pumpConversation(
      tester,
      messages: [
        _message(
          id: null,
          localId: 'failed-golden',
          senderId: 1,
          text: 'This message could not be sent.',
          status: ChatMessageStatus.failed,
        ),
      ],
      size: phoneSize,
    );
    await _expectGolden(tester, 'goldens/chat_send_error.png');
  });

  testWidgets('Chat expanded composer golden', (tester) async {
    await _pumpConversation(
      tester,
      messages: [
        _message(id: 8, senderId: 2, text: 'Tell me the whole story.'),
      ],
      initialText:
          'First line of a thoughtful reply.\n'
          'Second line keeps the composer bounded.\n'
          'Third line remains readable.\n'
          'Fourth line shows the maximum useful height.',
      size: phoneSize,
    );
    await _expectGolden(tester, 'goldens/chat_composer_expanded.png');
  });
}

Future<void> _pumpChatList(
  WidgetTester tester,
  ChatListState state, {
  required Size size,
}) async {
  await _configureView(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.midnight(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: 1,
          disableAnimations: true,
        ),
        child: RepaintBoundary(
          key: const Key('chat-golden-surface'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ChatListView(
                state: state,
                currentUserId: 1,
                onRetry: () async {},
                onDiscover: () {},
                onOpenChat: (_) {},
                imageProviderBuilder: _imageProvider,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: GlassNavigationBar(
                  currentIndex: 1,
                  onSelected: (_) {},
                  destinations: const [
                    GlassNavigationDestination(
                      label: 'Discover',
                      icon: Icons.explore_outlined,
                    ),
                    GlassNavigationDestination(
                      label: 'Chats',
                      icon: Icons.chat_bubble_outline_rounded,
                    ),
                    GlassNavigationDestination(
                      label: 'Likes',
                      icon: Icons.favorite_border_rounded,
                    ),
                    GlassNavigationDestination(
                      label: 'Profile',
                      icon: Icons.person_outline_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await _precacheImages(tester, find.byType(ChatListView));
  await tester.pumpAndSettle();
}

Future<void> _pumpConversation(
  WidgetTester tester, {
  required List<ChatMessage> messages,
  required Size size,
  ChatConnectionState connectionState = ChatConnectionState.connected,
  String initialText = '',
}) async {
  await _configureView(tester, size);
  final textController = TextEditingController(text: initialText);
  final focusNode = FocusNode();
  final scrollController = ScrollController();
  addTearDown(textController.dispose);
  addTearDown(focusNode.dispose);
  addTearDown(scrollController.dispose);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.midnight(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: 1,
          disableAnimations: true,
        ),
        child: RepaintBoundary(
          key: const Key('chat-golden-surface'),
          child: ChatConversationView(
            details: _details,
            detailsLoading: false,
            detailsError: null,
            messagesState: ChatMessagesState(
              messages: messages,
              isLoading: false,
            ),
            currentUserId: 1,
            connectionState: connectionState,
            messageController: textController,
            focusNode: focusNode,
            scrollController: scrollController,
            showScrollToBottom: false,
            unreadBelow: 0,
            onBack: () {},
            onOpenProfile: () {},
            onRetryDetails: () {},
            onRetryHistory: () {},
            onRetryMessage: (_) {},
            onSend: () {},
            onScrollToBottom: () {},
            imageProviderBuilder: _imageProvider,
          ),
        ),
      ),
    ),
  );
  await _precacheImages(tester, find.byType(ChatConversationView));
  await tester.pumpAndSettle();
}

Future<void> _configureView(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _precacheImages(WidgetTester tester, Finder finder) async {
  final context = tester.element(finder);
  await tester.runAsync(() async {
    await precacheImage(_profileImage, context);
    await precacheImage(_messageImage, context);
  });
}

Future<void> _expectGolden(WidgetTester tester, String path) => expectLater(
  find.byKey(const Key('chat-golden-surface')),
  matchesGoldenFile(path),
);

ImageProvider<Object>? _imageProvider(String? url) {
  if (url == null) return null;
  return url.contains('message') ? _messageImage : _profileImage;
}

ChatSummary _chat({
  required int id,
  required String name,
  required String message,
  int unread = 0,
  bool mine = true,
}) {
  return ChatSummary(
    id: id,
    user: ChatUser(
      id: id + 100,
      firstName: name,
      age: null,
      avatarUrl: 'memory://profile',
      status: null,
    ),
    createdAt: DateTime(2024, 1, id + 1, 18, id),
    lastMessage: message,
    unreadCount: unread,
    lastMessageStatus: mine
        ? ChatMessageStatus.read
        : ChatMessageStatus.delivered,
    lastMessageSenderId: mine ? 1 : id + 100,
    lastMessageType: ChatMessageType.text,
  );
}

ChatMessage _message({
  required int? id,
  required int senderId,
  required String text,
  String? localId,
  ChatMessageStatus status = ChatMessageStatus.delivered,
  ChatMessageType type = ChatMessageType.text,
  List<String> mediaUrls = const [],
}) {
  return ChatMessage(
    id: id,
    localId: localId ?? 'golden-${id ?? 0}',
    chatId: 7,
    senderId: senderId,
    text: text,
    status: status,
    type: type,
    mediaUrls: mediaUrls,
    createdAt: DateTime(2024, 1, 12, 18, 20 + (id ?? 0)),
  );
}

const _details = ChatDetails(
  chatId: 7,
  user: ChatUser(
    id: 2,
    firstName: 'Mira',
    age: 28,
    avatarUrl: 'memory://profile',
    status: null,
  ),
);
