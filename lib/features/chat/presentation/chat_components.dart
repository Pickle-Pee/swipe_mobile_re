import 'package:flutter/material.dart';

import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/liquid_ui.dart';
import '../../../shared/ui/midnight_components.dart';
import '../domain/chat_models.dart';
import '../application/chat_providers.dart';
import '../application/chat_socket.dart';
import 'chat_time_formatter.dart';

typedef ChatImageProviderBuilder =
    ImageProvider<Object>? Function(String? imageUrl);

class ChatsTopBar extends StatelessWidget {
  const ChatsTopBar({super.key, required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: unreadCount > 0 ? 'Chats, $unreadCount unread messages' : 'Chats',
      child: GlassSurface(
        level: GlassLevel.overlay,
        radius: AppTokens.radiusLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space20,
          vertical: AppTokens.space12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Chats',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (unreadCount > 0) UnreadBadge(count: unreadCount),
          ],
        ),
      ),
    );
  }
}

class ChatListTile extends StatelessWidget {
  const ChatListTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
    this.imageProviderBuilder,
  });

  final ChatSummary chat;
  final int? currentUserId;
  final VoidCallback onTap;
  final ChatImageProviderBuilder? imageProviderBuilder;

  @override
  Widget build(BuildContext context) {
    final preview = _preview(chat);
    final unread = chat.unreadCount > 0;
    final semantics = StringBuffer('${chat.user.firstName}. $preview');
    if (unread) {
      semantics.write('. ${chat.unreadCount} unread messages');
    }

    return Semantics(
      button: true,
      label: semantics.toString(),
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          splashColor: AppTokens.brandViolet.withValues(alpha: 0.10),
          highlightColor: AppTokens.glassLow,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppTokens.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space8,
              vertical: AppTokens.space12,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTokens.glassLow)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ChatAvatar(
                  name: chat.user.firstName,
                  imageProvider: imageProviderBuilder?.call(
                    chat.user.avatarUrl,
                  ),
                  size: 56,
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              chat.user.firstName.isEmpty
                                  ? 'Unnamed profile'
                                  : chat.user.firstName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: unread
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (chat.createdAt != null) ...[
                            const SizedBox(width: AppTokens.space8),
                            Text(
                              ChatTimeFormatter.summary(
                                context,
                                chat.createdAt!,
                              ),
                              maxLines: 1,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppTokens.textMuted),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppTokens.space4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_showsLastMessageStatus) ...[
                            _CompactMessageStatus(
                              status: chat.lastMessageStatus!,
                            ),
                            const SizedBox(width: AppTokens.space4),
                          ],
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: unread
                                        ? AppTokens.textPrimary
                                        : AppTokens.textSecondary,
                                    fontWeight: unread
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: AppTokens.space8),
                            UnreadBadge(count: chat.unreadCount),
                          ],
                        ],
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
  }

  bool get _showsLastMessageStatus =>
      chat.lastMessageStatus != null &&
      currentUserId != null &&
      chat.lastMessageSenderId == currentUserId;

  static String _preview(ChatSummary chat) {
    final text = chat.lastMessage?.trim();
    if (text != null && text.isNotEmpty) return text;
    return 'No messages yet';
  }
}

class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final safeCount = count < 0 ? 0 : count;
    final label = safeCount > 99 ? '99+' : '$safeCount';
    return Semantics(
      label: '$safeCount unread messages',
      child: Container(
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppTokens.ctaGradient,
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.name,
    required this.size,
    this.imageProvider,
  });

  final String name;
  final double size;
  final ImageProvider<Object>? imageProvider;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTokens.missingMediaGradient,
      ),
      child: Center(
        child: Text(
          _initial,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    return Semantics(
      image: true,
      label: name.isEmpty ? 'Profile photo unavailable' : '$name profile photo',
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: imageProvider == null
              ? fallback
              : Image(
                  image: imageProvider!,
                  fit: BoxFit.cover,
                  frameBuilder: (context, child, frame, synchronous) =>
                      frame == null && !synchronous ? fallback : child,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }

  String get _initial {
    final value = name.trim();
    return value.isEmpty ? '?' : value.characters.first.toUpperCase();
  }
}

class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key, this.rows = 5});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading chats',
      child: ListView.builder(
        key: const Key('chat-list-loading'),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space16,
          AppTokens.space8,
          AppTokens.space16,
          AppTokens.floatingNavigationClearance,
        ),
        itemCount: rows,
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppTokens.space12),
          child: Row(
            children: [
              SkeletonLoader(width: 56, height: 56, radius: 28),
              SizedBox(width: AppTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 132, height: 16),
                    SizedBox(height: AppTokens.space8),
                    SkeletonLoader(height: 13),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatTopBar extends StatelessWidget {
  const ChatTopBar({
    super.key,
    required this.user,
    required this.connectionState,
    required this.onBack,
    required this.onOpenProfile,
    this.imageProviderBuilder,
  });

  final ChatUser user;
  final ChatConnectionState connectionState;
  final VoidCallback onBack;
  final VoidCallback onOpenProfile;
  final ChatImageProviderBuilder? imageProviderBuilder;

  @override
  Widget build(BuildContext context) {
    final connectionLabel = switch (connectionState) {
      ChatConnectionState.connected => null,
      ChatConnectionState.connecting => 'Connecting…',
      ChatConnectionState.reconnecting => 'Reconnecting…',
      ChatConnectionState.offline => 'Offline',
      ChatConnectionState.failed => 'Connection unavailable',
    };
    return GlassSurface(
      level: GlassLevel.overlay,
      radius: AppTokens.radiusLarge,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space8,
        vertical: AppTokens.space4,
      ),
      child: Row(
        children: [
          GlassIconButton(
            key: const Key('chat-back'),
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Back to chats',
            tooltip: 'Back',
            onPressed: onBack,
          ),
          const SizedBox(width: AppTokens.space4),
          Expanded(
            child: Semantics(
              button: true,
              label: 'Open ${user.firstName} profile',
              onTap: onOpenProfile,
              excludeSemantics: true,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                child: InkWell(
                  key: const Key('chat-open-profile'),
                  onTap: onOpenProfile,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space4,
                      vertical: AppTokens.space4,
                    ),
                    child: Row(
                      children: [
                        ChatAvatar(
                          name: user.firstName,
                          imageProvider: imageProviderBuilder?.call(
                            user.avatarUrl,
                          ),
                          size: 42,
                        ),
                        const SizedBox(width: AppTokens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user.firstName.isEmpty
                                    ? 'Profile'
                                    : user.firstName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (connectionLabel != null)
                                Text(
                                  connectionLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color:
                                            connectionState ==
                                                ChatConnectionState.failed
                                            ? AppTokens.error
                                            : AppTokens.textMuted,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.connectionState});

  final ChatConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    final message = switch (connectionState) {
      ChatConnectionState.connected => null,
      ChatConnectionState.connecting => 'Connecting to chat…',
      ChatConnectionState.reconnecting => 'Restoring the connection…',
      ChatConnectionState.offline =>
        'No connection. Sending is available when you are back online.',
      ChatConnectionState.failed =>
        'Chat connection is unavailable. Check your network.',
    };
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppTokens.motionContent,
      child: message == null
          ? const SizedBox.shrink(key: Key('chat-connected'))
          : Semantics(
              key: const Key('chat-connection-banner'),
              liveRegion: true,
              label: message,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(
                  AppTokens.space16,
                  0,
                  AppTokens.space16,
                  AppTokens.space4,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space12,
                  vertical: AppTokens.space8,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.backgroundElevated,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                  border: Border.all(
                    color: connectionState == ChatConnectionState.failed
                        ? AppTokens.error.withValues(alpha: 0.34)
                        : AppTokens.glassBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      connectionState == ChatConnectionState.failed
                          ? Icons.cloud_off_rounded
                          : Icons.sync_rounded,
                      size: AppTokens.iconCompact,
                      color: connectionState == ChatConnectionState.failed
                          ? AppTokens.error
                          : AppTokens.textSecondary,
                    ),
                    const SizedBox(width: AppTokens.space8),
                    Expanded(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class MessageList extends StatelessWidget {
  const MessageList({
    super.key,
    required this.state,
    required this.currentUserId,
    required this.scrollController,
    required this.onRetryHistory,
    required this.onRetryMessage,
    this.imageProviderBuilder,
  });

  final ChatMessagesState state;
  final int? currentUserId;
  final ScrollController scrollController;
  final VoidCallback onRetryHistory;
  final ValueChanged<String> onRetryMessage;
  final ChatImageProviderBuilder? imageProviderBuilder;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.messages.isEmpty) {
      return const _MessageListSkeleton();
    }
    if (state.error is ChatHistoryFailure && state.messages.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.space20),
          child: ErrorState(
            key: const Key('chat-history-error'),
            title: 'Messages are unavailable',
            message: 'Check your connection and try loading this chat again.',
            actionLabel: 'Try again',
            onAction: onRetryHistory,
          ),
        ),
      );
    }
    if (state.messages.isEmpty) {
      return const ChatEmptyState();
    }

    return ListView.builder(
      key: const PageStorageKey<String>('chat-message-list'),
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        AppTokens.space12,
        AppTokens.space16,
        AppTokens.space20,
      ),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final previous = index == 0 ? null : state.messages[index - 1];
        final showDay =
            previous == null ||
            !ChatTimeFormatter.isSameDay(
              previous.createdAt.toLocal(),
              message.createdAt.toLocal(),
            );
        return RepaintBoundary(
          key: ValueKey(
            message.id == null
                ? 'message-local-${message.localId}'
                : 'message-${message.id}',
          ),
          child: Column(
            children: [
              if (showDay) DaySeparator(date: message.createdAt),
              MessageBubble(
                message: message,
                mine: message.senderId == currentUserId,
                onRetry: message.status == ChatMessageStatus.failed
                    ? () => onRetryMessage(message.localId)
                    : null,
                imageProviderBuilder: imageProviderBuilder,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'No messages. Start the conversation when you are ready.',
        child: Container(
          key: const Key('chat-history-empty'),
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.all(AppTokens.space20),
          padding: const EdgeInsets.all(AppTokens.space24),
          decoration: BoxDecoration(
            color: AppTokens.surfaceSolid,
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            border: Border.all(color: AppTokens.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 34,
                color: AppTokens.brandViolet,
              ),
              const SizedBox(height: AppTokens.space12),
              Text(
                'Start the conversation',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTokens.space8),
              Text(
                'Say hello when you are ready.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DaySeparator extends StatelessWidget {
  const DaySeparator({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final label = ChatTimeFormatter.dayLabel(date);
    return Semantics(
      header: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space12,
            vertical: AppTokens.space4,
          ),
          decoration: BoxDecoration(
            color: AppTokens.backgroundElevated,
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(color: AppTokens.glassLow),
          ),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTokens.textMuted),
          ),
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    this.onRetry,
    this.imageProviderBuilder,
  });

  final ChatMessage message;
  final bool mine;
  final VoidCallback? onRetry;
  final ChatImageProviderBuilder? imageProviderBuilder;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final responsiveWidth = constraints.maxWidth * 0.78;
          final maxWidth = responsiveWidth > 340 ? 340.0 : responsiveWidth;
          return Container(
            constraints: BoxConstraints(minWidth: 76, maxWidth: maxWidth),
            margin: const EdgeInsets.only(bottom: AppTokens.space8),
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space12,
              AppTokens.space12,
              AppTokens.space12,
              AppTokens.space8,
            ),
            decoration: BoxDecoration(
              color: mine
                  ? AppTokens.brandViolet.withValues(
                      alpha: highContrast ? 0.34 : 0.22,
                    )
                  : AppTokens.surfaceSolid,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppTokens.radiusMedium),
                topRight: const Radius.circular(AppTokens.radiusMedium),
                bottomLeft: Radius.circular(
                  mine ? AppTokens.radiusMedium : AppTokens.space4,
                ),
                bottomRight: Radius.circular(
                  mine ? AppTokens.space4 : AppTokens.radiusMedium,
                ),
              ),
              border: Border.all(
                color: mine
                    ? AppTokens.brandViolet.withValues(alpha: 0.32)
                    : AppTokens.glassBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MessageContent(
                  message: message,
                  imageProviderBuilder: imageProviderBuilder,
                ),
                const SizedBox(height: AppTokens.space4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      ChatTimeFormatter.messageTime(context, message.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTokens.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    if (mine) ...[
                      const SizedBox(width: AppTokens.space4),
                      MessageStatus(status: message.status),
                    ],
                  ],
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppTokens.space4),
                  TextButton.icon(
                    key: Key('retry-message-${message.localId}'),
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(
                        AppTokens.minTouchTarget,
                        AppTokens.minTouchTarget,
                      ),
                      foregroundColor: AppTokens.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space8,
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.message,
    required this.imageProviderBuilder,
  });

  final ChatMessage message;
  final ChatImageProviderBuilder? imageProviderBuilder;

  @override
  Widget build(BuildContext context) {
    return switch (message.type) {
      ChatMessageType.text => Text(
        message.text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTokens.textPrimary,
          height: 1.4,
        ),
      ),
      ChatMessageType.image => _ImageMessageContent(
        message: message,
        imageProviderBuilder: imageProviderBuilder,
      ),
      ChatMessageType.voice => const _UnavailableMediaContent(
        icon: Icons.mic_none_rounded,
        label: 'Voice message',
        detail: 'Playback is not available in this client yet.',
      ),
      ChatMessageType.unknown => _UnavailableMediaContent(
        icon: Icons.insert_drive_file_outlined,
        label: message.text.trim().isEmpty ? 'Message' : message.text,
        detail: 'This message type is not supported.',
      ),
    };
  }
}

class _ImageMessageContent extends StatelessWidget {
  const _ImageMessageContent({
    required this.message,
    required this.imageProviderBuilder,
  });

  final ChatMessage message;
  final ChatImageProviderBuilder? imageProviderBuilder;

  @override
  Widget build(BuildContext context) {
    final url = message.mediaUrls.firstOrNull;
    final provider = imageProviderBuilder?.call(url);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: provider == null
                ? const _ImageMessageFallback()
                : Image(
                    image: provider,
                    fit: BoxFit.cover,
                    frameBuilder: (context, child, frame, synchronous) =>
                        frame == null && !synchronous
                        ? const SkeletonLoader(radius: 0)
                        : child,
                    errorBuilder: (_, _, _) => const _ImageMessageFallback(),
                  ),
          ),
        ),
        if (message.text.trim().isNotEmpty) ...[
          const SizedBox(height: AppTokens.space8),
          Text(
            message.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTokens.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _ImageMessageFallback extends StatelessWidget {
  const _ImageMessageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppTokens.backgroundElevated,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: AppTokens.textMuted),
      ),
    );
  }
}

class _UnavailableMediaContent extends StatelessWidget {
  const _UnavailableMediaContent({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTokens.textSecondary),
        const SizedBox(width: AppTokens.space8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                detail,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTokens.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MessageStatus extends StatelessWidget {
  const MessageStatus({super.key, required this.status});

  final ChatMessageStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      ChatMessageStatus.sending => (
        Icons.schedule_rounded,
        AppTokens.textMuted,
        'Sending',
      ),
      ChatMessageStatus.sent => (
        Icons.check_rounded,
        AppTokens.textMuted,
        'Sent',
      ),
      ChatMessageStatus.delivered => (
        Icons.done_all_rounded,
        AppTokens.textMuted,
        'Delivered',
      ),
      ChatMessageStatus.read => (
        Icons.done_all_rounded,
        AppTokens.brandViolet,
        'Read',
      ),
      ChatMessageStatus.failed => (
        Icons.error_outline_rounded,
        AppTokens.error,
        'Failed to send',
      ),
    };
    return Semantics(
      label: label,
      child: Icon(icon, size: 14, color: color),
    );
  }
}

class ScrollToBottomButton extends StatelessWidget {
  const ScrollToBottomButton({
    super.key,
    required this.onPressed,
    required this.unreadBelow,
  });

  final VoidCallback onPressed;
  final int unreadBelow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: unreadBelow > 0
          ? 'Scroll to $unreadBelow new messages'
          : 'Scroll to latest message',
      onTap: onPressed,
      excludeSemantics: true,
      child: Material(
        color: AppTokens.surfaceSolid,
        elevation: 8,
        shadowColor: AppTokens.shadow,
        shape: const StadiumBorder(
          side: BorderSide(color: AppTokens.glassBorder),
        ),
        child: InkWell(
          key: const Key('chat-scroll-to-bottom'),
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppTokens.minTouchTarget,
              minHeight: AppTokens.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.keyboard_arrow_down_rounded),
                  if (unreadBelow > 0) ...[
                    const SizedBox(width: AppTokens.space4),
                    Text('$unreadBelow'),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageListSkeleton extends StatelessWidget {
  const _MessageListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading messages',
      child: ListView(
        key: const Key('chat-history-loading'),
        padding: const EdgeInsets.all(AppTokens.space16),
        children: const [
          Align(
            alignment: Alignment.centerLeft,
            child: SkeletonLoader(width: 210, height: 64),
          ),
          SizedBox(height: AppTokens.space12),
          Align(
            alignment: Alignment.centerRight,
            child: SkeletonLoader(width: 176, height: 72),
          ),
          SizedBox(height: AppTokens.space12),
          Align(
            alignment: Alignment.centerLeft,
            child: SkeletonLoader(width: 232, height: 86),
          ),
        ],
      ),
    );
  }
}

class _CompactMessageStatus extends StatelessWidget {
  const _CompactMessageStatus({required this.status});

  final ChatMessageStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      ChatMessageStatus.sending => (
        Icons.schedule_rounded,
        AppTokens.textMuted,
        'Sending',
      ),
      ChatMessageStatus.sent => (
        Icons.check_rounded,
        AppTokens.textMuted,
        'Sent',
      ),
      ChatMessageStatus.delivered => (
        Icons.done_all_rounded,
        AppTokens.textMuted,
        'Delivered',
      ),
      ChatMessageStatus.read => (
        Icons.done_all_rounded,
        AppTokens.brandViolet,
        'Read',
      ),
      ChatMessageStatus.failed => (
        Icons.error_outline_rounded,
        AppTokens.error,
        'Failed',
      ),
    };
    return Semantics(
      label: label,
      child: Icon(icon, size: 15, color: color),
    );
  }
}
