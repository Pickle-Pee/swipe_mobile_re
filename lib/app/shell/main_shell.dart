import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:swipe_mobile_re/shared/ui/glass_tabbar.dart';

import '../../shared/ui/liquid_ui.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;
  

  @override
  Widget build(BuildContext context) {
    return AppGradientScaffold(
      child: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Align(
            alignment: Alignment.bottomCenter,
            child: GlassTabBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (i) => navigationShell.goBranch(
                i,
                initialLocation: i == navigationShell.currentIndex,
              )
            ),
          ),
        ],
      ),
    );
  }
}
