import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientScaffold(
        child: Column(
          children: [
            Padding(
              padding: AppTokens.screenPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Discovery', style: Theme.of(context).textTheme.titleLarge),
                  Row(children: [
                    IconButton(onPressed: () => context.go(Routes.likes), icon: const Icon(Icons.favorite_border)),
                    IconButton(onPressed: () => context.go(Routes.chats), icon: const Icon(Icons.chat_bubble_outline)),
                  ])
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassSurface(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      Container(
                        height: 220,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusLg)),
                          gradient: AppTokens.coolGradient,
                        ),
                        child: const Center(child: Icon(Icons.person, size: 80, color: Colors.white70)),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Maya, 27', style: TextStyle(fontSize: 24, color: Colors.white)),
                              SizedBox(height: 8),
                              Text('Sync level 92% • emotional alignment high',
                                  style: TextStyle(color: AppTokens.blueSoft)),
                              SizedBox(height: 14),
                              Text(
                                  'Mindful designer who values calm communication, deep talks and spontaneous museum walks.'),
                              SizedBox(height: 14),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                PillTag(label: 'Reflective'),
                                PillTag(label: 'Curious', color: AppTokens.pinkSoft),
                                PillTag(label: 'Travel'),
                                PillTag(label: 'Books', color: AppTokens.mint),
                              ]),
                              SizedBox(height: 14),
                              AiInsightCard(
                                title: 'AI resonance insight',
                                message:
                                    'You both prefer thoughtful pacing and ask open-ended questions, a strong indicator of lasting rapport.',
                              ),
                              SizedBox(height: 12),
                              SafetyBadge(label: 'Identity and safety checks passed'),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: AppTokens.screenPadding,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTokens.border),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Pass'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(label: 'Like', onPressed: () => context.go(Routes.likes)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(label: 'Profile', icon: Icons.person_outline, onTap: () => context.go(Routes.profile)),
                  _NavItem(label: 'Settings', icon: Icons.settings_outlined, onTap: () => context.go(Routes.settings)),
                  _NavItem(label: 'Premium', icon: Icons.workspace_premium_outlined, onTap: () => context.go(Routes.premium)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTokens.textSecondary),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTokens.textSecondary)),
        ],
      ),
    );
  }
}
