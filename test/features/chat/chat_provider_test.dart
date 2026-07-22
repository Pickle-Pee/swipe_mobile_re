import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/features/chat/application/chat_providers.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_models.dart';
import 'package:swipe_mobile_re/features/chat/domain/chat_repository.dart';

void main() {
  test('openOrCreate reuses an existing chat', () async {
    final repository = FakeChatRepository(existingId: 4);
    final container = ProviderContainer(
      overrides: [chatRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(chatListControllerProvider.notifier)
        .openOrCreate(9);

    expect(result, 4);
    expect(repository.createCalls, 0);
  });

  test('openOrCreate creates a missing chat once', () async {
    final repository = FakeChatRepository();
    final container = ProviderContainer(
      overrides: [chatRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(chatListControllerProvider.notifier);

    final first = controller.openOrCreate(9);
    final second = controller.openOrCreate(9);
    expect(await first, 8);
    expect(await second, isNull);
    expect(repository.createCalls, 1);
  });

  test('load preserves server order and removes duplicate chat ids', () async {
    final repository = FakeChatRepository(
      chats: [_summary(2), _summary(1), _summary(2)],
    );
    final container = ProviderContainer(
      overrides: [chatRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(chatListControllerProvider.notifier).load();

    expect(
      container.read(chatListControllerProvider).chats.map((chat) => chat.id),
      [2, 1],
    );
  });

  test('replayed realtime message increments unread only once', () async {
    final repository = FakeChatRepository(
      chats: [_summary(1), _summary(2, unread: 3)],
    );
    final container = ProviderContainer(
      overrides: [chatRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(chatListControllerProvider.notifier);
    await controller.load();
    final message = ChatMessage(
      id: 40,
      localId: 'server-40',
      chatId: 2,
      senderId: 9,
      text: 'New message',
      status: ChatMessageStatus.delivered,
      createdAt: DateTime(2026, 7, 22),
    );

    await controller.applyMessage(message, isOpen: false);
    await controller.applyMessage(message, isOpen: false);

    final state = container.read(chatListControllerProvider);
    expect(state.chats.first.id, 2);
    expect(state.chats.first.unreadCount, 4);
    controller.markChatOpen(2);
    expect(
      container.read(chatListControllerProvider).chats.first.unreadCount,
      0,
    );
  });
}

class FakeChatRepository implements ChatRepository {
  FakeChatRepository({this.existingId, this.chats = const []});
  final int? existingId;
  final List<ChatSummary> chats;
  int createCalls = 0;

  @override
  Future<int> createChat(int userId) async {
    createCalls++;
    return 8;
  }

  @override
  Future<ChatDetails> getChatDetails(int chatId) => throw UnimplementedError();

  @override
  Future<int?> getChatIdByUserId(int userId) async => existingId;

  @override
  Future<List<ChatSummary>> getChats() async => chats;
}

ChatSummary _summary(int id, {int unread = 0}) => ChatSummary(
  id: id,
  user: ChatUser(
    id: id + 10,
    firstName: 'User $id',
    age: null,
    avatarUrl: null,
    status: null,
  ),
  createdAt: DateTime(2026, 7, 22),
  lastMessage: 'Message $id',
  unreadCount: unread,
);
