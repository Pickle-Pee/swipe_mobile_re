import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/routes.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discovery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Placeholder Discovery UI'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.go(Routes.chats),
            child: const Text('Open Chats'),
          ),
          ElevatedButton(
            onPressed: () => context.go(Routes.likes),
            child: const Text('Open Likes'),
          ),
          ElevatedButton(
            onPressed: () => context.go(Routes.profile),
            child: const Text('Open Profile'),
          ),
          ElevatedButton(
            onPressed: () => context.go(Routes.settings),
            child: const Text('Open Settings'),
          ),
          ElevatedButton(
            onPressed: () => context.go(Routes.premium),
            child: const Text('Open Subscription'),
          ),
        ],
      ),
    );
  }
}
