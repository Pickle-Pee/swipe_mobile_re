import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/config/config.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';
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

  @override
  void initState() {
    super.initState();
    _details = ref
        .read(chatRepositoryProvider)
        .getChatDetails(int.parse(widget.chatId));
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
              const Expanded(
                child: Center(child: Text('No messages loaded yet')),
              ),
            ],
          );
        },
      ),
    ),
  );
}

String _mediaUrl(String value) {
  final uri = Uri.parse(value);
  return uri.hasScheme
      ? uri.toString()
      : Uri.parse(AppConfig.baseAppUrl).resolve(value).toString();
}
