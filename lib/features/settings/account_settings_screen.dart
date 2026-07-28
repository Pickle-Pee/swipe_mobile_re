import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/midnight_components.dart';
import '../auth/application/auth_providers.dart';
import 'presentation/settings_components.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountId = ref.watch(
      authControllerProvider.select((state) => state.user?.id),
    );
    return SettingsPageScaffold(
      title: 'Account',
      onBack: () => _back(context),
      child: accountId == null
          ? ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space20,
                112,
                AppTokens.space20,
                AppTokens.space40,
              ),
              children: [
                ErrorState(
                  title: 'Account unavailable',
                  message:
                      'Your authenticated account information is not '
                      'available right now.',
                  actionLabel: 'Back to Settings',
                  onAction: () => _back(context),
                ),
              ],
            )
          : ListView(
              key: const Key('account-settings-list'),
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space20,
                96,
                AppTokens.space20,
                AppTokens.space40,
              ),
              children: [
                AccountInfoSection(accountId: accountId),
                const SizedBox(height: AppTokens.space24),
                SettingsSection(
                  title: 'Danger zone',
                  footer: const Text(
                    'Account deletion is a permanent server action. '
                    'You will review its known consequences first.',
                  ),
                  children: [
                    SettingsTile(
                      key: const Key('account-delete-route'),
                      leadingIcon: Icons.person_remove_outlined,
                      title: 'Delete account',
                      subtitle: 'Review permanent account deletion',
                      statusLabel: 'Permanent',
                      destructive: true,
                      onTap: () async {
                        await context.push<void>(Routes.deleteAccount);
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

void _back(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(Routes.settings);
  }
}
