import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientScaffold(
        child: ListView(
          padding: AppTokens.screenPadding,
          children: [
            Row(children: [
              IconButton(onPressed: () => context.go(Routes.discover), icon: const Icon(Icons.chevron_left_rounded)),
              Text('Profile', style: Theme.of(context).textTheme.titleLarge),
            ]),
            const SizedBox(height: 10),
            const GlassSurface(
              child: Column(
                children: [
                  CircleAvatar(radius: 38, child: Icon(Icons.person, size: 40)),
                  SizedBox(height: 10),
                  Text('You, 28', style: TextStyle(color: Colors.white, fontSize: 20)),
                  SizedBox(height: 8),
                  Text('Story-driven creator who values empathy, honesty and emotionally mature conversation.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const AiInsightCard(
              title: 'AI profile insight',
              message: 'Profiles with one reflective prompt answer get 34% deeper opening conversations.',
            ),
            const SizedBox(height: 12),
            GlassSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Interests', style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: const [
                    PillTag(label: 'Books'),
                    PillTag(label: 'Cafes', color: AppTokens.pinkSoft),
                    PillTag(label: 'Museums'),
                  ]),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(onPressed: () {}, child: const Text('Edit profile')),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
