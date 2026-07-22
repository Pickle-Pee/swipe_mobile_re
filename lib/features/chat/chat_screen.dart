import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/media/app_network_image.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';
import '../../shared/ui/midnight_components.dart';
import '../auth/application/auth_providers.dart';
import 'application/chat_providers.dart';
import 'application/chat_socket.dart';
import 'domain/chat_models.dart';
import 'presentation/chat_composer.dart';
import 'presentation/chat_components.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  ProviderSubscription<ChatMessagesState>? _messagesSubscription;
  ActiveChatRegistry? _activeChatRegistry;
  Future<ChatDetails>? _details;
  int? _chatId;
  int _unreadBelow = 0;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _chatId = int.tryParse(widget.chatId);
    _scrollController.addListener(_handleScroll);
    final chatId = _chatId;
    if (chatId == null) return;
    _activeChatRegistry = ref.read(activeChatRegistryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _activateChat();
      ref.read(chatListControllerProvider.notifier).markChatOpen(chatId);
    });
    _messagesSubscription = ref.listenManual(
      chatMessagesControllerProvider(chatId),
      _handleMessagesChanged,
    );
    _loadDetails();
  }

  @override
  void dispose() {
    final chatId = _chatId;
    _messagesSubscription?.close();
    if (chatId != null) {
      _activeChatRegistry?.close(chatId);
    }
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatId = _chatId;
    final messagesState = chatId == null
        ? const ChatMessagesState(isLoading: false, error: ChatHistoryFailure())
        : ref.watch(chatMessagesControllerProvider(chatId));
    final currentUserId = ref.watch(authControllerProvider).user?.id;
    final connectionState =
        ref.watch(chatConnectionStateProvider).value ??
        ref.read(chatSocketManagerProvider).connectionState;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _deactivateChat();
      },
      child: FutureBuilder<ChatDetails>(
        future: _details,
        builder: (context, snapshot) {
          return ChatConversationView(
            details: snapshot.data,
            detailsLoading:
                chatId != null &&
                snapshot.connectionState != ConnectionState.done,
            detailsError: chatId == null
                ? const FormatException('Invalid chat id')
                : snapshot.error,
            messagesState: messagesState,
            currentUserId: currentUserId,
            connectionState: connectionState,
            messageController: _messageController,
            focusNode: _focusNode,
            scrollController: _scrollController,
            showScrollToBottom: _showScrollToBottom,
            unreadBelow: _unreadBelow,
            onBack: _handleBack,
            onOpenProfile: snapshot.data == null
                ? null
                : () => _openProfile(snapshot.data!.user.id),
            onRetryDetails: _loadDetails,
            onRetryHistory: chatId == null
                ? () {}
                : () => ref
                      .read(chatMessagesControllerProvider(chatId).notifier)
                      .retryHistory(),
            onRetryMessage: chatId == null
                ? (_) {}
                : (localId) => ref
                      .read(chatMessagesControllerProvider(chatId).notifier)
                      .retry(localId),
            onSend: _send,
            onScrollToBottom: () => _scrollToBottom(),
            imageProviderBuilder: _chatImageProvider,
          );
        },
      ),
    );
  }

  void _loadDetails() {
    final chatId = _chatId;
    if (chatId == null) return;
    setState(() {
      _details = ref.read(chatRepositoryProvider).getChatDetails(chatId);
    });
  }

  Future<void> _send() async {
    final chatId = _chatId;
    if (chatId == null) return;
    final sent = await ref
        .read(chatMessagesControllerProvider(chatId).notifier)
        .send(_messageController.text);
    if (!sent || !mounted) return;
    _messageController.clear();
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  void _handleMessagesChanged(
    ChatMessagesState? previous,
    ChatMessagesState next,
  ) {
    final previousLength = previous?.messages.length ?? 0;
    final added = next.messages.length - previousLength;
    if (previous?.isLoading == true &&
        !next.isLoading &&
        next.messages.isNotEmpty) {
      _scrollToBottom(animate: false);
      return;
    }
    if (added <= 0 || next.messages.isEmpty) return;
    final currentUserId = ref.read(authControllerProvider).user?.id;
    final latestIsMine = next.messages.last.senderId == currentUserId;
    if (latestIsMine || _isNearBottom) {
      _scrollToBottom();
      return;
    }
    if (!mounted) return;
    setState(() {
      _unreadBelow += added;
      _showScrollToBottom = true;
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final shouldShow = !_isNearBottom;
    if (shouldShow == _showScrollToBottom &&
        (shouldShow || _unreadBelow == 0)) {
      return;
    }
    setState(() {
      _showScrollToBottom = shouldShow;
      if (!shouldShow) _unreadBelow = 0;
    });
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels < 96;
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (!animate || MediaQuery.disableAnimationsOf(context)) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: AppTokens.motionContent,
          curve: Curves.easeOutCubic,
        );
      }
      if (_showScrollToBottom || _unreadBelow > 0) {
        setState(() {
          _showScrollToBottom = false;
          _unreadBelow = 0;
        });
      }
    });
  }

  void _handleBack() {
    _focusNode.unfocus();
    _deactivateChat();
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go(Routes.chats);
    }
  }

  Future<void> _openProfile(int userId) async {
    _deactivateChat();
    await context.push(Routes.publicProfileFor(userId));
    if (mounted) _activateChat();
  }

  void _activateChat() {
    final chatId = _chatId;
    if (chatId != null) {
      _activeChatRegistry?.open(chatId);
    }
  }

  void _deactivateChat() {
    final chatId = _chatId;
    if (chatId != null) {
      _activeChatRegistry?.close(chatId);
    }
  }
}

class ChatConversationView extends StatelessWidget {
  const ChatConversationView({
    super.key,
    required this.details,
    required this.detailsLoading,
    required this.detailsError,
    required this.messagesState,
    required this.currentUserId,
    required this.connectionState,
    required this.messageController,
    required this.focusNode,
    required this.scrollController,
    required this.showScrollToBottom,
    required this.unreadBelow,
    required this.onBack,
    required this.onOpenProfile,
    required this.onRetryDetails,
    required this.onRetryHistory,
    required this.onRetryMessage,
    required this.onSend,
    required this.onScrollToBottom,
    this.imageProviderBuilder,
  });

  final ChatDetails? details;
  final bool detailsLoading;
  final Object? detailsError;
  final ChatMessagesState messagesState;
  final int? currentUserId;
  final ChatConnectionState connectionState;
  final TextEditingController messageController;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final bool showScrollToBottom;
  final int unreadBelow;
  final VoidCallback onBack;
  final VoidCallback? onOpenProfile;
  final VoidCallback onRetryDetails;
  final VoidCallback onRetryHistory;
  final ValueChanged<String> onRetryMessage;
  final VoidCallback onSend;
  final VoidCallback onScrollToBottom;
  final ChatImageProviderBuilder? imageProviderBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.backgroundBase,
      resizeToAvoidBottomInset: true,
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
                child: details == null
                    ? _ChatTopBarSkeleton(onBack: onBack)
                    : ChatTopBar(
                        key: const Key('chat-top-bar'),
                        user: details!.user,
                        connectionState: connectionState,
                        onBack: onBack,
                        onOpenProfile: onOpenProfile ?? () {},
                        imageProviderBuilder: imageProviderBuilder,
                      ),
              ),
              if (detailsError != null && !detailsLoading && details == null)
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTokens.space20),
                      child: ErrorState(
                        key: const Key('chat-details-error'),
                        title: 'Could not open this chat',
                        message:
                            'The conversation details are unavailable. Try again.',
                        actionLabel: 'Try again',
                        onAction: onRetryDetails,
                      ),
                    ),
                  ),
                )
              else ...[
                ConnectionBanner(connectionState: connectionState),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MessageList(
                          state: messagesState,
                          currentUserId: currentUserId,
                          scrollController: scrollController,
                          onRetryHistory: onRetryHistory,
                          onRetryMessage: onRetryMessage,
                          imageProviderBuilder: imageProviderBuilder,
                        ),
                      ),
                      if (showScrollToBottom)
                        Positioned(
                          right: AppTokens.space16,
                          bottom: AppTokens.space12,
                          child: ScrollToBottomButton(
                            onPressed: onScrollToBottom,
                            unreadBelow: unreadBelow,
                          ),
                        ),
                    ],
                  ),
                ),
                ChatComposer(
                  controller: messageController,
                  focusNode: focusNode,
                  connectionState: connectionState,
                  isSending: messagesState.isSending,
                  onSend: onSend,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatTopBarSkeleton extends StatelessWidget {
  const _ChatTopBarSkeleton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      key: const Key('chat-top-bar-loading'),
      level: GlassLevel.overlay,
      radius: AppTokens.radiusLarge,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space8,
        vertical: AppTokens.space4,
      ),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Back to chats',
            onPressed: onBack,
          ),
          const SizedBox(width: AppTokens.space8),
          const SkeletonLoader(width: 42, height: 42, radius: 21),
          const SizedBox(width: AppTokens.space12),
          const Expanded(child: SkeletonLoader(height: 18)),
          const SizedBox(width: AppTokens.space20),
        ],
      ),
    );
  }
}

ImageProvider<Object>? _chatImageProvider(String? value) {
  return appNetworkImage(value);
}
