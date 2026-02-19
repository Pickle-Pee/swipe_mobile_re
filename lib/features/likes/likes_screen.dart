import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final likes = const ['Elena', 'Kai', 'Rina'];

    return Scaffold(
      body: AppGradientScaffold(
        child: Column(
          children: [
            Padding(
              padding: AppTokens.screenPadding,
              child: Row(children: [
                IconButton(onPressed: () => context.go(Routes.discover), icon: const Icon(Icons.chevron_left_rounded)),
                Text('Likes', style: Theme.of(context).textTheme.titleLarge),
              ]),
            ),
            Expanded(
              child: likes.isEmpty
                  ? const Center(child: Text('No likes yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemBuilder: (_, i) => GlassSurface(
                        child: ListTile(
                          title: Text(likes[i], style: const TextStyle(color: Colors.white)),
                          subtitle: const Text('Alignment signal: strong'),
                          trailing: const Icon(Icons.favorite, color: AppTokens.pinkSoft),
                        ),
                      ),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: likes.length,
                    ),
            )
          ],
        ),
      ),
    );
  }
}
