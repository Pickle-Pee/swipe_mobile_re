import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/config/config.dart';
import '../../core/network/api_exception.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';
import '../../shared/ui/midnight_components.dart';
import '../auth/application/auth_providers.dart';
import 'application/chat_providers.dart';
import 'presentation/chat_components.dart';

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
      if (chatId != null && mounted) context.go(Routes.chatFor(chatId));
      return;
    }
    final state = ref.read(chatListControllerProvider);
    if (state.status == ChatListStatus.initial) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatListControllerProvider);
    final currentUserId = ref.watch(authControllerProvider).user?.id;
    return ChatListView(
      state: state,
      currentUserId: currentUserId,
      onRetry: _reload,
      onDiscover: () => context.go(Routes.discover),
      onOpenChat: (chatId) => context.push(Routes.chatFor(chatId)),
      imageProviderBuilder: _chatImageProvider,
    );
  }

  Future<void> _reload() =>
      ref.read(chatListControllerProvider.notifier).load();
}

class ChatListView extends StatelessWidget {
  const ChatListView({
    super.key,
    required this.state,
    required this.currentUserId,
    required this.onRetry,
    required this.onDiscover,
    required this.onOpenChat,
    this.imageProviderBuilder,
  });

  final ChatListState state;
  final int? currentUserId;
  final Future<void> Function() onRetry;
  final VoidCallback onDiscover;
  final ValueChanged<int> onOpenChat;
  final ChatImageProviderBuilder? imageProviderBuilder;

  @override
  Widget build(BuildContext context) {
    final unreadCount = state.chats.fold<int>(
      0,
      (total, chat) => total + chat.unreadCount,
    );
    return Scaffold(
      backgroundColor: AppTokens.backgroundBase,
      body: AppGradientScaffold(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space12,
                  AppTokens.space8,
                  AppTokens.space12,
                  AppTokens.space8,
                ),
                child: ChatsTopBar(
                  key: const Key('chats-top-bar'),
                  unreadCount: unreadCount,
                ),
              ),
              Expanded(child: _content(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (state.status == ChatListStatus.loading && state.chats.isEmpty) {
      return const ChatListSkeleton();
    }
    if (state.status == ChatListStatus.error && state.chats.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space20,
            AppTokens.space20,
            AppTokens.space20,
            AppTokens.floatingNavigationClearance,
          ),
          child: ErrorState(
            key: const Key('chat-list-error'),
            title: 'Chats are unavailable',
            message: _errorMessage(state.error),
            actionLabel: 'Try again',
            onAction: onRetry,
          ),
        ),
      );
    }
    if (state.chats.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space20,
            AppTokens.space20,
            AppTokens.space20,
            AppTokens.floatingNavigationClearance,
          ),
          child: EmptyState(
            key: const Key('chat-list-empty'),
            icon: Icons.chat_bubble_outline_rounded,
            title: 'No conversations yet',
            message:
                'Your conversations will appear here after a mutual match.',
            actionLabel: 'Explore profiles',
            onAction: onDiscover,
          ),
        ),
      );
    }

    return Column(
      children: [
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppTokens.motionContent,
          child: state.error == null
              ? const SizedBox.shrink(key: Key('chat-list-no-inline-error'))
              : _InlineListError(
                  key: const Key('chat-list-inline-error'),
                  message: _errorMessage(state.error),
                  onRetry: onRetry,
                ),
        ),
        if (state.status == ChatListStatus.loading)
          const LinearProgressIndicator(
            key: Key('chat-list-refresh-progress'),
            minHeight: 2,
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRetry,
            child: ListView.builder(
              key: const PageStorageKey<String>('chat-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space16,
                AppTokens.space4,
                AppTokens.space16,
                AppTokens.floatingNavigationClearance,
              ),
              itemCount: state.chats.length,
              itemBuilder: (context, index) {
                final chat = state.chats[index];
                return ChatListTile(
                  key: ValueKey('chat-${chat.id}'),
                  chat: chat,
                  currentUserId: currentUserId,
                  imageProviderBuilder: imageProviderBuilder,
                  onTap: () => onOpenChat(chat.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _errorMessage(Object? error) => error is ApiException
      ? error.message
      : 'Check your connection and try again.';
}

class _InlineListError extends StatelessWidget {
  const _InlineListError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space12,
          vertical: AppTokens.space8,
        ),
        decoration: BoxDecoration(
          color: AppTokens.error.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(color: AppTokens.error.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: AppTokens.iconCompact,
              color: AppTokens.error,
            ),
            const SizedBox(width: AppTokens.space8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

ImageProvider<Object>? _chatImageProvider(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parsed = Uri.tryParse(value);
  if (parsed == null) return null;
  final url = parsed.hasScheme
      ? parsed.toString()
      : Uri.parse(AppConfig.baseAppUrl).resolveUri(parsed).toString();
  return NetworkImage(url);
}
