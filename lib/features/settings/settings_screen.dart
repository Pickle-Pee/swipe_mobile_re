import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';
import '../auth/application/auth_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool safeMode = true;
  bool aiAssist = true;
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientScaffold(
        child: ListView(
          padding: AppTokens.screenPadding,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(Routes.discover);
                    }
                  },
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text('Settings', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            GlassSurface(
              child: Column(
                children: [
                  SwitchListTile(
                    value: safeMode,
                    onChanged: (v) => setState(() => safeMode = v),
                    title: const Text(
                      'Enhanced safety mode',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SwitchListTile(
                    value: aiAssist,
                    onChanged: (v) => setState(() => aiAssist = v),
                    title: const Text(
                      'AI conversation support',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ListTile(
                    title: const Text(
                      'Subscription',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go(Routes.premium),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('settings-logout'),
                    enabled: !_isLoggingOut,
                    leading: _isLoggingOut
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.logout_rounded,
                            color: AppTokens.error,
                          ),
                    title: Text(
                      _isLoggingOut ? 'Signing out…' : 'Sign out',
                      style: const TextStyle(color: AppTokens.error),
                    ),
                    onTap: _isLoggingOut ? null : _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    context.go(Routes.welcome);
  }
}
