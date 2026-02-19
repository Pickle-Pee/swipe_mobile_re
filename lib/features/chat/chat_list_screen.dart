import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chats = const [
      ('a1', 'Maya', 'Your reflection felt very grounded ✨', 'Resonance: Calm'),
      ('b2', 'Noah', 'Want to continue our city stories?', 'Style: Warm'),
      ('c3', 'Lina', 'I liked your idea about Sunday rituals.', 'Style: Curious'),
    ];

    return Scaffold(
      body: AppGradientScaffold(
        child: Column(
          children: [
            Padding(
              padding: AppTokens.screenPadding,
              child: Row(
                children: [
                  IconButton(onPressed: () => context.go(Routes.discover), icon: const Icon(Icons.chevron_left_rounded)),
                  Text('All Chats', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: chats.isEmpty
                  ? const Center(child: Text('No conversations yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemBuilder: (context, index) {
                        final item = chats[index];
                        return GlassSurface(
                          padding: const EdgeInsets.all(12),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(backgroundColor: AppTokens.surfaceStrong, child: Icon(Icons.person)),
                            title: Text(item.$2, style: const TextStyle(color: Colors.white)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [Text(item.$3), const SizedBox(height: 4), PillTag(label: item.$4)],
                            ),
                            onTap: () => context.go('/chat/${item.$1}'),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: chats.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
