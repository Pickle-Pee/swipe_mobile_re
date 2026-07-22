import 'package:flutter/material.dart';

import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/liquid_ui.dart';
import '../../../shared/ui/midnight_components.dart';
import '../domain/chat_models.dart';
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
