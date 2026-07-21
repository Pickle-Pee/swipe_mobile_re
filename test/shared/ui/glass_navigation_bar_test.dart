import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_mobile_re/shared/ui/app_theme.dart';
import 'package:swipe_mobile_re/shared/ui/glass_tabbar.dart';

void main() {
  testWidgets('navigation exposes the selected tab and handles selection', (
    tester,
  ) async {
    var selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.midnight(),
        home: Scaffold(
          bottomNavigationBar: GlassNavigationBar(
            currentIndex: 2,
            onSelected: (value) => selected = value,
            destinations: const [
              GlassNavigationDestination(
                label: 'Discover',
                icon: Icons.explore_outlined,
              ),
              GlassNavigationDestination(
                label: 'Chats',
                icon: Icons.chat_bubble_outline_rounded,
              ),
              GlassNavigationDestination(
                label: 'Likes',
                icon: Icons.favorite_border_rounded,
              ),
              GlassNavigationDestination(
                label: 'Profile',
                icon: Icons.person_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );

    final likesNode = tester.getSemantics(find.bySemanticsLabel('Likes'));
    expect(likesNode.flagsCollection.isSelected, Tristate.isTrue);

    await tester.tap(find.bySemanticsLabel('Chats'));
    expect(selected, 1);
  });

  testWidgets('navigation renders only a real unread badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.midnight(),
        home: Scaffold(
          bottomNavigationBar: GlassNavigationBar(
            currentIndex: 0,
            onSelected: (_) {},
            destinations: const [
              GlassNavigationDestination(
                label: 'Discover',
                icon: Icons.explore_outlined,
              ),
              GlassNavigationDestination(
                label: 'Chats',
                icon: Icons.chat_bubble_outline_rounded,
                badgeCount: 7,
              ),
              GlassNavigationDestination(
                label: 'Likes',
                icon: Icons.favorite_border_rounded,
              ),
              GlassNavigationDestination(
                label: 'Profile',
                icon: Icons.person_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('7'), findsOneWidget);
    expect(find.bySemanticsLabel('Chats, 7 unread'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });
}
