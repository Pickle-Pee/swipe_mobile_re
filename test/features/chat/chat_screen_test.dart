import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/chat/application/chat_providers.dart';
import 'package:swipe_mobile_re/features/chat/chat_screen.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_models.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_repository.dart';
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
}

class _ChatMessagesController extends ChatMessagesController {
  _ChatMessagesController(super.chatId);

  @override
  ChatMessagesState build() {
    return const ChatMessagesState(isLoading: false);
  }
}

class _ChatRepository implements ChatRepository {
  @override
  Future<ChatDetails> getChatDetails(int chatId) async {
    return ChatDetails(
      chatId: chatId,
      user: const ChatUser(
        id: 2,
        firstName: 'Mira',
        age: 28,
        avatarUrl: null,
        status: 'offline',
      ),
    );
  }

  @override
  Future<int> createChat(int userId) => throw UnimplementedError();

  @override
  Future<int?> getChatIdByUserId(int userId) => throw UnimplementedError();

  @override
  Future<List<ChatSummary>> getChats() => throw UnimplementedError();
}
