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
}

class FakeChatRepository implements ChatRepository {
  FakeChatRepository({this.existingId});
  final int? existingId;
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
  Future<List<ChatSummary>> getChats() async => const [];
}
