import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'liquid_ui.dart';

class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Плавающий: НЕ “впритык” к низу
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
      child: GlassSurface(
        radius: 30,
        // Чуть меньше padding, как в TG
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical:5),
        // Для тёмной подложки “стекло” лучше не белое, а дымчатое:
        backgroundColor: AppTokens.surface.withOpacity(0.18),
        borderColor: Colors.white.withOpacity(0.08),
        child: Row(
          children: [
            _TabItem(
              label: 'Discover',
              icon: Icons.auto_awesome_outlined,
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _TabItem(
              label: 'Chats',
              icon: Icons.chat_bubble_outline,
              selected: currentIndex == 1,
              onTap: () => onTap(1),
              badge: 34, // пример бейджа для Чатов
            ),
            _TabItem(
              label: 'Likes',
              icon: Icons.favorite_border,
              selected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _TabItem(
              label: 'Profile',
              icon: Icons.account_circle_outlined,
              selected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final active = selected;

    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        // Мягкая подсветка активного таба (как TG)
                        gradient: active ? AppTokens.ctaGradient : null,
                        color: active ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: active
                            ? Colors.white
                            : Colors.white.withOpacity(0.70),
                      ),
                    ),
                    if (badge != null && badge! > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
                          ),
                          child: Text(
                            '$badge',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: active
                        ? Colors.white
                        : Colors.white.withOpacity(0.70),
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
