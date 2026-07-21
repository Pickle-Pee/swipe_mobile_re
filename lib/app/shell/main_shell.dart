import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/application/chat_providers.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/glass_tabbar.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatListControllerProvider).chats;
    final unreadCount = chats.fold<int>(
      0,
      (sum, chat) => sum + chat.unreadCount,
    );

    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        backgroundColor: AppTokens.backgroundBase,
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: GlassNavigationBar(
          key: const Key('main-navigation'),
          currentIndex: navigationShell.currentIndex,
          onSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: [
            const GlassNavigationDestination(
              label: 'Discover',
              icon: Icons.explore_outlined,
            ),
            GlassNavigationDestination(
              label: 'Chats',
              icon: Icons.chat_bubble_outline_rounded,
              badgeCount: unreadCount,
            ),
            const GlassNavigationDestination(
              label: 'Likes',
              icon: Icons.favorite_border_rounded,
            ),
            const GlassNavigationDestination(
              label: 'Profile',
              icon: Icons.person_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
