import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId});
  final String chatId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final List<(String, bool)> messages = [
    ('I appreciate your thoughtful pace.', false),
    ('Thanks, I feel the same in our chats.', true),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientScaffold(
        child: Column(
          children: [
            Padding(
              padding: AppTokens.screenPadding,
              child: Row(
                children: [
                  IconButton(onPressed: () => context.go(Routes.chats), icon: const Icon(Icons.chevron_left_rounded)),
                  const CircleAvatar(child: Icon(Icons.person_outline)),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Maya', style: Theme.of(context).textTheme.titleMedium),
                    const Text('Communication style: Reflective', style: TextStyle(fontSize: 12, color: AppTokens.blueSoft)),
                  ])
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) => ChatBubbleGlass(text: messages[index].$1, mine: messages[index].$2),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: messages.length,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: AiInsightCard(
                title: 'AI suggestion',
                message: 'Try sharing a specific moment from your week to deepen emotional context.',
              ),
            ),
            Padding(
              padding: AppTokens.screenPadding,
              child: Row(
                children: [
                  Expanded(
                    child: GlassSurface(
                      radius: 999,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(hintText: 'Message', border: InputBorder.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {
                      if (_controller.text.trim().isEmpty) return;
                      setState(() {
                        messages.add((_controller.text.trim(), true));
                        _controller.clear();
                      });
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, color: AppTokens.blueSoft),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
