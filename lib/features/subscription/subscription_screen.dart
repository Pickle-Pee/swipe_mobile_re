import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientScaffold(
        child: ListView(
          padding: AppTokens.screenPadding,
          children: [
            Row(children: [
              IconButton(onPressed: () => context.go(Routes.discover), icon: const Icon(Icons.chevron_left_rounded)),
              Text('Premium', style: Theme.of(context).textTheme.titleLarge),
            ]),
            const SizedBox(height: 6),
            const GlassSurface(
              child: Column(
                children: [
                  Icon(Icons.auto_awesome, color: AppTokens.blueSoft, size: 40),
                  SizedBox(height: 10),
                  Text('Deepen Your Connections', style: TextStyle(color: Colors.white, fontSize: 22)),
                  SizedBox(height: 8),
                  Text('Unlock calm tools that support meaningful relationships faster.', textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...const [
              _FeatureTile(icon: Icons.favorite_border, title: 'See Who Likes You', subtitle: 'View all profiles with intent'),
              _FeatureTile(icon: Icons.chat_bubble_outline, title: 'Unlimited Messaging', subtitle: 'No limits on thoughtful chats'),
              _FeatureTile(icon: Icons.shield_outlined, title: 'Enhanced Safety', subtitle: 'Extra verification and controls'),
            ],
            const SizedBox(height: 12),
            const GlassSurface(
              borderColor: AppTokens.blueSoft,
              child: ListTile(
                title: Text('3 Months', style: TextStyle(color: Colors.white)),
                subtitle: Text('Best value • 40% off'),
                trailing: Text('\$29.99', style: TextStyle(color: AppTokens.blueSoft, fontSize: 22)),
              ),
            ),
            const SizedBox(height: 10),
            const GlassSurface(
              child: ListTile(
                title: Text('1 Month', style: TextStyle(color: Colors.white)),
                subtitle: Text('Renews monthly'),
                trailing: Text('\$19.99', style: TextStyle(color: Colors.white, fontSize: 22)),
              ),
            ),
            const SizedBox(height: 12),
            const AiInsightCard(
              title: 'Personalized insight',
              message: 'Premium can increase high-compatibility conversations based on your current profile activity.',
            ),
            const SizedBox(height: 16),
            GradientButton(label: 'Continue', onPressed: _noop),
            const SizedBox(height: 10),
            const Text(
              'Cancel anytime. Auto-renewal can be managed in account settings.',
              style: TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}

void _noop() {}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassSurface(
        child: Row(
          children: [
            CircleAvatar(backgroundColor: AppTokens.surfaceStrong, child: Icon(icon, color: AppTokens.blueSoft)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white)),
                  Text(subtitle),
                ],
              ),
            ),
            const Icon(Icons.check_circle, color: AppTokens.mint),
          ],
        ),
      ),
    );
  }
}
