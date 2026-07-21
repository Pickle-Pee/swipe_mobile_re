import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'liquid_ui.dart';

class GlassNavigationDestination {
  const GlassNavigationDestination({
    required this.label,
    required this.icon,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final int badgeCount;
}

class GlassNavigationBar extends StatelessWidget {
  const GlassNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<GlassNavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    assert(destinations.length >= 2);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        0,
        AppTokens.space16,
        AppTokens.space12,
      ),
      child: GlassSurface(
        level: GlassLevel.navigation,
        radius: AppTokens.radiusXLarge,
        padding: const EdgeInsets.all(AppTokens.space4),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var index = 0; index < destinations.length; index++)
                Expanded(
                  child: _NavigationItem(
                    destination: destinations[index],
                    selected: currentIndex == index,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final GlassNavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final badge = destination.badgeCount;
    final semanticsLabel = badge > 0
        ? '${destination.label}, $badge unread'
        : destination.label;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          onTap: onTap,
          child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : AppTokens.motionTab,
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.all(AppTokens.space4),
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
            decoration: BoxDecoration(
              color: selected ? AppTokens.glassActive : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
              border: selected
                  ? Border.all(color: AppTokens.glassBorder)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      destination.icon,
                      size: AppTokens.iconNavigation,
                      color: selected
                          ? AppTokens.textPrimary
                          : AppTokens.textMuted,
                    ),
                    if (badge > 0)
                      Positioned(
                        right: -12,
                        top: -8,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.space4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTokens.brandRose,
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusPill,
                            ),
                            border: Border.all(
                              color: AppTokens.backgroundElevated,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            badge > 99 ? '99+' : '$badge',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTokens.textPrimary,
                              fontSize: 10,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTokens.space4),
                AnimatedDefaultTextStyle(
                  duration: reduceMotion ? Duration.zero : AppTokens.motionTab,
                  style:
                      Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected
                            ? AppTokens.textPrimary
                            : AppTokens.textMuted,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ) ??
                      const TextStyle(),
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// Compatibility wrapper retained for callers outside the redesigned shell.
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
    return GlassNavigationBar(
      currentIndex: currentIndex,
      onSelected: onTap,
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
    );
  }
}
