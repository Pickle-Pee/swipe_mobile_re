import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/config/config.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';
import '../auth/application/auth_providers.dart';
import 'application/chat_providers.dart';
import 'domain/chat_models.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});
  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late final Future<ChatDetails> _details;
  late final int _chatId;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatId = int.parse(widget.chatId);
    _details = ref.read(chatRepositoryProvider).getChatDetails(_chatId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppGradientScaffold(
      child: FutureBuilder<ChatDetails>(
        future: _details,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Could not open this chat'));
          }
          final details = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: AppTokens.screenPadding,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go(Routes.chats),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    CircleAvatar(
                      backgroundImage: details.user.avatarUrl == null
                          ? null
                          : NetworkImage(_mediaUrl(details.user.avatarUrl!)),
                      child: details.user.avatarUrl == null
                          ? const Icon(Icons.person_outline)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details.user.firstName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (details.user.status != null)
                          Text(
                            details.user.status!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTokens.blueSoft,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(child: _messages()),
              _composer(),
            ],
          );
        },
      ),
    ),
  );

  Widget _messages() {
    final state = ref.watch(chatMessagesControllerProvider(_chatId));
    ref.listen(chatMessagesControllerProvider(_chatId), (previous, next) {
      if ((previous?.messages.length ?? 0) != next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.messages.isEmpty) {
      return const Center(child: Text('Start the conversation'));
    }
    final currentUserId = ref.watch(authControllerProvider).user?.id;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final mine = message.senderId == currentUserId;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 290),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: mine ? AppTokens.blueSoft : AppTokens.surfaceStrong,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(message.text),
                if (mine) ...[
                  const SizedBox(height: 3),
                  Text(
                    _statusLabel(message.status),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _composer() {
    final state = ref.watch(chatMessagesControllerProvider(_chatId));
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: state.isSending ? null : (_) => _send(),
                decoration: const InputDecoration(hintText: 'Message'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: state.isSending ? null : _send,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    _messageController.clear();
    await ref.read(chatMessagesControllerProvider(_chatId).notifier).send(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

String _statusLabel(ChatMessageStatus status) => switch (status) {
  ChatMessageStatus.sending => 'Sending…',
  ChatMessageStatus.sent => 'Sent',
  ChatMessageStatus.delivered => 'Delivered',
  ChatMessageStatus.read => 'Read',
};

String _mediaUrl(String value) {
  final uri = Uri.parse(value);
  return uri.hasScheme
      ? uri.toString()
      : Uri.parse(AppConfig.baseAppUrl).resolve(value).toString();
}
