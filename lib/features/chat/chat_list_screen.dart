import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // dummy IDs so routes work
    final chats = const ['a1', 'b2', 'c3'];

    return Scaffold(
      appBar: AppBar(title: const Text('All Chats')),
      body: ListView.separated(
        itemCount: chats.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final id = chats[index];
          return ListTile(
            title: Text('Chat $id'),
            subtitle: const Text('Last message preview…'),
            onTap: () => context.go('/chat/$id'),
          );
        },
      ),
    );
  }
}
