import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/chat/application/chat_providers.dart';
import 'package:swipe_mobile_re/features/chat/application/chat_socket.dart';
import 'package:swipe_mobile_re/features/chat/chat_screen.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_models.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_repository.dart';
import 'package:swipe_mobile_re/features/chat/presentation/chat_components.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';

void main() {
  testWidgets('opens a chat after details resolve without a Riverpod error', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(_ChatRepository()),
          chatMessagesControllerProvider.overrideWith2(
            _ChatMessagesController.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.midnight(),
          home: const ChatScreen(chatId: '7'),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Mira'), findsOneWidget);
    expect(find.text('Start the conversation'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('renders real history, day separators, and no list blur', (
    tester,
  ) async {
    final now = DateTime.now();
    await _pumpConversation(
      tester,
      messages: [
        _message(
          id: 1,
          senderId: 2,
          text: 'An incoming real message',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        _message(
          id: 2,
          senderId: 1,
          text: 'A real reply',
          status: ChatMessageStatus.read,
          createdAt: now,
        ),
      ],
    );

    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('An incoming real message'), findsOneWidget);
    expect(find.text('A real reply'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MessageList),
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
    expect(find.byType(BackdropFilter), findsNWidgets(2));
  });

  testWidgets('shows loading, empty, and retryable history states', (
    tester,
  ) async {
    await _pumpConversation(tester, messagesState: const ChatMessagesState());
    expect(find.byKey(const Key('chat-history-loading')), findsOneWidget);

    await _pumpConversation(
      tester,
      messagesState: const ChatMessagesState(isLoading: false),
    );
    expect(find.byKey(const Key('chat-history-empty')), findsOneWidget);

    var retries = 0;
    await _pumpConversation(
      tester,
      messagesState: const ChatMessagesState(
        isLoading: false,
        error: ChatHistoryFailure(),
      ),
      onRetryHistory: () => retries++,
    );
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('shows compact older-page loading, retry, and beginning states', (
    tester,
  ) async {
    final message = _message(id: 1, senderId: 2, text: 'Existing message');
    await _pumpConversation(
      tester,
      messagesState: ChatMessagesState(
        messages: [message],
        isLoading: false,
        isLoadingOlder: true,
        hasMore: true,
        nextCursor: 'older',
      ),
    );
    expect(find.byKey(const Key('chat-history-older-loading')), findsOneWidget);
    expect(find.text('Existing message'), findsOneWidget);

    var retries = 0;
    await _pumpConversation(
      tester,
      messagesState: ChatMessagesState(
        messages: [message],
        isLoading: false,
        loadOlderError: const ChatOlderHistoryFailure(),
        hasMore: true,
        nextCursor: 'older',
      ),
      onRetryOlder: () => retries++,
    );
    await tester.tap(find.byKey(const Key('chat-history-older-retry')));
    expect(retries, 1);

    await _pumpConversation(
      tester,
      messagesState: ChatMessagesState(messages: [message], isLoading: false),
    );
    expect(find.text('Beginning of conversation'), findsOneWidget);
  });

  testWidgets('failed message stays visible and exposes one retry action', (
    tester,
  ) async {
    String? retriedId;
    await _pumpConversation(
      tester,
      messages: [
        _message(
          id: null,
          localId: 'failed-local',
          senderId: 1,
          text: 'Please retry this message',
          status: ChatMessageStatus.failed,
        ),
      ],
      onRetryMessage: (localId) => retriedId = localId,
    );

    expect(find.text('Please retry this message'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retriedId, 'failed-local');
  });

  testWidgets('composer enables Send only for non-empty connected text', (
    tester,
  ) async {
    var sends = 0;
    await _pumpConversation(tester, onSend: () => sends++);

    IconButton sendButton() =>
        tester.widget<IconButton>(find.byKey(const Key('chat-send')));

    expect(sendButton().onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('chat-message-input')),
      'Hello',
    );
    await tester.pump();
    expect(sendButton().onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('chat-send')));
    expect(sends, 1);
  });

  testWidgets('offline state is honest and keeps Send disabled', (
    tester,
  ) async {
    await _pumpConversation(
      tester,
      connectionState: ChatConnectionState.offline,
      initialText: 'Waiting for a connection',
    );

    expect(find.byKey(const Key('chat-connection-banner')), findsOneWidget);
    expect(find.textContaining('No connection'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byKey(const Key('chat-send'))).onPressed,
      isNull,
    );
  });

  testWidgets('Back and profile actions preserve their real callbacks', (
    tester,
  ) async {
    var backs = 0;
    var profileOpens = 0;
    await _pumpConversation(
      tester,
      onBack: () => backs++,
      onOpenProfile: () => profileOpens++,
    );

    await tester.tap(find.byKey(const Key('chat-open-profile')));
    await tester.tap(find.byKey(const Key('chat-back')));
    expect(profileOpens, 1);
    expect(backs, 1);
  });

  testWidgets('image history has bounded fallback without layout shift', (
    tester,
  ) async {
    await _pumpConversation(
      tester,
      messages: [
        _message(
          id: 4,
          senderId: 2,
          text: '',
          type: ChatMessageType.image,
          mediaUrls: const ['memory://image'],
        ),
      ],
    );

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long content and expanded composer fit a compact scaled view', (
    tester,
  ) async {
    await _pumpConversation(
      tester,
      size: const Size(320, 568),
      textScale: 1.3,
      initialText: 'First line\nSecond line\nThird line\nFourth line',
      messages: [
        _message(
          id: 9,
          senderId: 2,
          text:
              'A very long message with a URL https://example.test/path and emoji 🌙 that must wrap naturally without clipping or horizontal overflow.',
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('chat-composer')), findsOneWidget);
  });

  testWidgets('a thousand-message state remains lazily built', (tester) async {
    final messages = List.generate(
      1000,
      (index) => _message(
        id: index + 1,
        senderId: index.isEven ? 1 : 2,
        text: 'Message ${index + 1}',
        createdAt: DateTime.utc(2026, 7, 1).add(Duration(minutes: index)),
      ),
    );

    await _pumpConversation(tester, messages: messages);

    expect(find.byType(MessageBubble).evaluate().length, lessThan(50));
    expect(find.text('Message 1000'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('prepending older messages preserves the visible scroll range', (
    tester,
  ) async {
    final initial = List.generate(
      80,
      (index) => _message(
        id: index + 31,
        senderId: index.isEven ? 1 : 2,
        text: 'Current ${index + 31}',
        createdAt: DateTime.utc(2026, 7, 22).add(Duration(minutes: index + 31)),
      ),
    );
    late _MutableChatMessagesController controller;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(_ChatRepository()),
          chatMessagesControllerProvider.overrideWith2((chatId) {
            controller = _MutableChatMessagesController(chatId, initial);
            return controller;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.midnight(),
          home: const ChatScreen(chatId: '7'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final list = find.byType(ListView);
    await tester.drag(list, const Offset(0, -1200));
    await tester.pumpAndSettle();
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.pixels, greaterThan(160));
    final distanceFromBottom = position.maxScrollExtent - position.pixels;

    controller.startLoadingOlder();
    await tester.pump();
    controller.finishLoadingOlder(
      List.generate(
        30,
        (index) => _message(
          id: index + 1,
          senderId: index.isEven ? 1 : 2,
          text: 'Older ${index + 1}',
          createdAt: DateTime.utc(
            2026,
            7,
            22,
          ).add(Duration(minutes: index + 1)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      position.maxScrollExtent - position.pixels,
      closeTo(distanceFromBottom, 1),
    );
    expect(find.bySemanticsLabel('Scroll to 30 new messages'), findsNothing);
  });
}

Future<void> _pumpConversation(
  WidgetTester tester, {
  List<ChatMessage>? messages,
  ChatMessagesState? messagesState,
  ChatConnectionState connectionState = ChatConnectionState.connected,
  String initialText = '',
  VoidCallback? onBack,
  VoidCallback? onOpenProfile,
  VoidCallback? onRetryDetails,
  VoidCallback? onRetryHistory,
  VoidCallback? onRetryOlder,
  ValueChanged<String>? onRetryMessage,
  VoidCallback? onSend,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

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
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: ChatConversationView(
          details: _details,
          detailsLoading: false,
          detailsError: null,
          messagesState:
              messagesState ??
              ChatMessagesState(
                messages: messages ?? const [],
                isLoading: false,
              ),
          currentUserId: 1,
          connectionState: connectionState,
          messageController: textController,
          focusNode: focusNode,
          scrollController: scrollController,
          showScrollToBottom: false,
          unreadBelow: 0,
          onBack: onBack ?? () {},
          onOpenProfile: onOpenProfile ?? () {},
          onRetryDetails: onRetryDetails ?? () {},
          onRetryHistory: onRetryHistory ?? () {},
          onRetryOlder: onRetryOlder ?? () {},
          onRetryMessage: onRetryMessage ?? (_) {},
          onSend: onSend ?? () {},
          onScrollToBottom: () {},
          imageProviderBuilder: (_) => null,
        ),
      ),
    ),
  );
  await tester.pump();
}

ChatMessage _message({
  required int? id,
  required int senderId,
  required String text,
  String? localId,
  ChatMessageStatus status = ChatMessageStatus.delivered,
  ChatMessageType type = ChatMessageType.text,
  List<String> mediaUrls = const [],
  DateTime? createdAt,
}) {
  return ChatMessage(
    id: id,
    localId: localId ?? 'local-${id ?? text.hashCode}',
    chatId: 7,
    senderId: senderId,
    text: text,
    status: status,
    type: type,
    mediaUrls: mediaUrls,
    createdAt: createdAt ?? DateTime.now(),
  );
}

const _details = ChatDetails(
  chatId: 7,
  user: ChatUser(
    id: 2,
    firstName: 'Mira',
    age: 28,
    avatarUrl: null,
    status: null,
  ),
);

class _ChatMessagesController extends ChatMessagesController {
  _ChatMessagesController(super.chatId);

  @override
  ChatMessagesState build() {
    return const ChatMessagesState(isLoading: false);
  }
}

class _MutableChatMessagesController extends ChatMessagesController {
  _MutableChatMessagesController(super.chatId, this.initialMessages);

  final List<ChatMessage> initialMessages;

  @override
  ChatMessagesState build() => ChatMessagesState(
    messages: initialMessages,
    initialLoading: false,
    hasMore: true,
    nextCursor: 'older',
  );

  @override
  Future<void> loadOlder() async {}

  void startLoadingOlder() {
    state = state.copyWith(isLoadingOlder: true, loadOlderError: null);
  }

  void finishLoadingOlder(List<ChatMessage> older) {
    state = state.copyWith(
      messages: [...older, ...state.messages],
      isLoadingOlder: false,
      hasMore: true,
      nextCursor: 'older-again',
    );
  }
}

class _ChatRepository implements ChatRepository {
  @override
  Future<ChatDetails> getChatDetails(int chatId) async => _details;

  @override
  Future<ChatMessagePage> getMessages(
    int chatId, {
    String? before,
    int limit = 30,
  }) async =>
      const ChatMessagePage(items: [], nextCursor: null, hasMore: false);

  @override
  Future<int> createChat(int userId) => throw UnimplementedError();

  @override
  Future<int?> getChatIdByUserId(int userId) => throw UnimplementedError();

  @override
  Future<List<ChatSummary>> getChats() => throw UnimplementedError();
}
