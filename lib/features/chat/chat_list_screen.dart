import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/config/config.dart';
import '../../core/network/api_exception.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';
import 'application/chat_providers.dart';
import 'domain/chat_models.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key, this.initialUserId});
  final int? initialUserId;

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  bool _handledInitialUser = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initialize);
  }

  Future<void> _initialize() async {
    final userId = widget.initialUserId;
    if (userId != null && !_handledInitialUser) {
      _handledInitialUser = true;
      final chatId = await ref
          .read(chatListControllerProvider.notifier)
          .openOrCreate(userId);
      if (chatId != null && mounted) context.go('/chat/$chatId');
    } else {
      await ref.read(chatListControllerProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatListControllerProvider);
    return Scaffold(
      body: AppGradientScaffold(
        child: Column(
          children: [
            Padding(
              padding: AppTokens.screenPadding,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(Routes.discover),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text(
                    'All Chats',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Expanded(child: _content(state)),
          ],
        ),
      ),
    );
  }

  Widget _content(ChatListState state) {
    if ((state.status == ChatListStatus.loading || state.isCreating) &&
        state.chats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ChatListStatus.error && state.chats.isEmpty) {
      return _ChatMessage(
        message: _errorMessage(state.error),
        onRetry: _reload,
      );
    }
    if (state.chats.isEmpty) {
      return _ChatMessage(message: 'No conversations yet', onRetry: _reload);
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.chats.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) => _ChatTile(chat: state.chats[index]),
      ),
    );
  }

  Future<void> _reload() =>
      ref.read(chatListControllerProvider.notifier).load();

  String _errorMessage(Object? error) => error is ApiException
      ? error.message
      : 'Could not load chats. Please try again.';
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.chat});
  final ChatSummary chat;

  @override
  Widget build(BuildContext context) => GlassSurface(
    padding: const EdgeInsets.all(12),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppTokens.surfaceStrong,
        backgroundImage: chat.user.avatarUrl == null
            ? null
            : NetworkImage(_mediaUrl(chat.user.avatarUrl!)),
        child: chat.user.avatarUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.user.firstName,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (chat.createdAt != null)
            Text(
              TimeOfDay.fromDateTime(chat.createdAt!.toLocal()).format(context),
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
      subtitle: Text(
        chat.lastMessage ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: chat.unreadCount > 0
          ? Badge(label: Text('${chat.unreadCount}'))
          : chat.user.status == null
          ? null
          : PillTag(label: chat.user.status!),
      onTap: () => context.go('/chat/${chat.id}'),
    ),
  );
}

class _ChatMessage extends StatelessWidget {
  const _ChatMessage({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 10),
        TextButton(onPressed: onRetry, child: const Text('Reload')),
      ],
    ),
  );
}

String _mediaUrl(String value) {
  final uri = Uri.parse(value);
  return uri.hasScheme
      ? uri.toString()
      : Uri.parse(AppConfig.baseAppUrl).resolve(value).toString();
}
