import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool safeMode = true;
  bool aiAssist = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientScaffold(
        child: ListView(
          padding: AppTokens.screenPadding,
          children: [
            Row(children: [
              IconButton(onPressed: () => context.go(Routes.discover), icon: const Icon(Icons.chevron_left_rounded)),
              Text('Settings', style: Theme.of(context).textTheme.titleLarge),
            ]),
            GlassSurface(
              child: Column(
                children: [
                  SwitchListTile(
                    value: safeMode,
                    onChanged: (v) => setState(() => safeMode = v),
                    title: const Text('Enhanced safety mode', style: TextStyle(color: Colors.white)),
                  ),
                  SwitchListTile(
                    value: aiAssist,
                    onChanged: (v) => setState(() => aiAssist = v),
                    title: const Text('AI conversation support', style: TextStyle(color: Colors.white)),
                  ),
                  ListTile(
                    title: const Text('Subscription', style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go(Routes.premium),
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
