import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/chat/application/chat_providers.dart';
import 'package:swipe_mobile_re/features/chat/chat_list_screen.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_models.dart';
import 'package:swipe_mobile_re/features/chat/presentation/chat_components.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('shows skeleton rows while the first chat page loads', (
    tester,
  ) async {
    await _pump(tester, const ChatListState(status: ChatListStatus.loading));

    expect(find.byKey(const Key('chat-list-loading')), findsOneWidget);
    expect(find.byType(ChatListTile), findsNothing);
  });

  testWidgets('shows the empty state and real Discovery action', (
    tester,
  ) async {
    var discoveryCalls = 0;
    await _pump(
      tester,
      const ChatListState(status: ChatListStatus.empty),
      onDiscover: () => discoveryCalls++,
    );

    expect(find.byKey(const Key('chat-list-empty')), findsOneWidget);
    expect(find.text('No conversations yet'), findsOneWidget);
    await tester.tap(find.text('Explore profiles'));
    expect(discoveryCalls, 1);
  });

  testWidgets('shows a retryable first-load error', (tester) async {
    var retries = 0;
    await _pump(
      tester,
      ChatListState(status: ChatListStatus.error, error: Exception('offline')),
      onRetry: () async => retries++,
    );

    expect(find.byKey(const Key('chat-list-error')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('renders real unread state and opens the selected chat', (
    tester,
  ) async {
    int? openedChat;
    await _pump(
      tester,
      ChatListState(
        status: ChatListStatus.data,
        chats: [
          _chat(
            id: 7,
            name: 'Mira',
            message: 'A real message from the repository',
            unread: 3,
          ),
          _chat(id: 8, name: 'Noor', message: 'Already read', unread: 0),
        ],
      ),
      onOpenChat: (chatId) => openedChat = chatId,
    );

    expect(find.byType(ChatListTile), findsNWidgets(2));
    expect(find.byType(UnreadBadge), findsNWidgets(2));
    final firstTile = find.byType(ChatListTile).first;
    expect(
      find.descendant(of: firstTile, matching: find.byType(BackdropFilter)),
      findsNothing,
    );
    await tester.tap(find.text('Mira'));
    expect(openedChat, 7);
  });

  testWidgets('long content, missing avatar, and text scale 1.3 do not overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      ChatListState(
        status: ChatListStatus.data,
        chats: [
          _chat(
            id: 10,
            name:
                'Alexandria Catherine with an exceptionally long profile name',
            message:
                'A deliberately long last message that must stay within two lines on a compact viewport without moving the unread badge.',
            unread: 12,
          ),
        ],
      ),
      size: const Size(320, 568),
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ChatAvatar), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  ChatListState state, {
  Future<void> Function()? onRetry,
  VoidCallback? onDiscover,
  ValueChanged<int>? onOpenChat,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.midnight(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: 1,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: ChatListView(
          state: state,
          currentUserId: 1,
          onRetry: onRetry ?? () async {},
          onDiscover: onDiscover ?? () {},
          onOpenChat: onOpenChat ?? (_) {},
          imageProviderBuilder: (_) => null,
        ),
      ),
    ),
  );
  await tester.pump();
}

ChatSummary _chat({
  required int id,
  required String name,
  required String message,
  required int unread,
}) {
  return ChatSummary(
    id: id,
    user: ChatUser(
      id: id + 100,
      firstName: name,
      age: null,
      avatarUrl: null,
      status: null,
    ),
    createdAt: DateTime.now(),
    lastMessage: message,
    unreadCount: unread,
    lastMessageStatus: ChatMessageStatus.read,
    lastMessageSenderId: 1,
    lastMessageType: ChatMessageType.text,
  );
}
