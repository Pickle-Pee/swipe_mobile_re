import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/theme/tokens.dart';
import '../auth/application/auth_providers.dart';
import '../subscription/application/subscription_providers.dart';
import 'presentation/settings_components.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      ref.read(subscriptionAccessControllerProvider.notifier).ensureLoaded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionAccessControllerProvider);
    final subscriptionPresentation = _subscriptionPresentation(subscription);
    return SettingsPageScaffold(
      title: 'Settings',
      onBack: _back,
      child: ListView(
        key: const Key('settings-list'),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space20,
          96,
          AppTokens.space20,
          AppTokens.space40,
        ),
        children: [
          SettingsSection(
            title: 'Your account',
            children: [
              SettingsTile(
                key: const Key('settings-account'),
                leadingIcon: Icons.person_outline_rounded,
                title: 'Account',
                subtitle: 'Account details and deletion',
                onTap: () async {
                  await context.push<void>(Routes.accountSettings);
                },
              ),
              SettingsTile(
                key: const Key('settings-discovery-preferences'),
                leadingIcon: Icons.tune_rounded,
                title: 'Discovery preferences',
                subtitle: 'Age and profile preferences',
                onTap: () async {
                  await context.push<void>(Routes.discoveryPreferences);
                },
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space24),
          SettingsSection(
            title: 'Access',
            footer: subscription.status == SubscriptionAccessStatus.error
                ? SettingsInlineMessage(
                    message: 'Subscription status could not be refreshed.',
                    actionLabel: 'Retry',
                    isError: true,
                    onAction: () => unawaited(
                      ref
                          .read(subscriptionAccessControllerProvider.notifier)
                          .refresh(),
                    ),
                  )
                : null,
            children: [
              SettingsTile(
                key: const Key('settings-subscription'),
                leadingIcon: subscriptionPresentation.icon,
                title: 'Subscription',
                subtitle: subscriptionPresentation.subtitle,
                statusLabel: subscriptionPresentation.status,
                loading:
                    subscription.status == SubscriptionAccessStatus.initial ||
                    subscription.status == SubscriptionAccessStatus.loading,
                onTap: () async {
                  await context.push<void>(Routes.premium);
                },
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space24),
          SettingsSection(
            title: 'About',
            children: [
              SettingsTile(
                key: const Key('settings-app-information'),
                leadingIcon: Icons.info_outline_rounded,
                title: 'App information',
                subtitle: 'Version and build information',
                onTap: () async {
                  await context.push<void>(Routes.appInformation);
                },
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space24),
          SettingsSection(
            title: 'Session',
            children: [
              SettingsTile(
                key: const Key('settings-logout'),
                leadingIcon: Icons.logout_rounded,
                title: 'Sign out',
                subtitle: 'Remove private session data from this device',
                destructive: true,
                loading: _isLoggingOut,
                enabled: !_isLoggingOut,
                onTap: _confirmLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppTokens.scrim,
      builder: (_) => const LogoutConfirmationSheet(),
    );
    if (confirmed == true && mounted) await _logout();
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    context.go(Routes.welcome);
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.profile);
    }
  }
}

class _SubscriptionPresentation {
  const _SubscriptionPresentation({
    required this.icon,
    required this.subtitle,
    required this.status,
  });

  final IconData icon;
  final String subtitle;
  final String? status;
}

_SubscriptionPresentation _subscriptionPresentation(
  SubscriptionAccessState state,
) {
  switch (state.status) {
    case SubscriptionAccessStatus.initial:
    case SubscriptionAccessStatus.loading:
      return const _SubscriptionPresentation(
        icon: Icons.workspace_premium_outlined,
        subtitle: 'Checking your current access…',
        status: null,
      );
    case SubscriptionAccessStatus.inactive:
      return const _SubscriptionPresentation(
        icon: Icons.auto_awesome_outlined,
        subtitle: 'Explore the available plans',
        status: 'Free',
      );
    case SubscriptionAccessStatus.active:
      final active = state.activeSubscription!;
      return _SubscriptionPresentation(
        icon: Icons.workspace_premium_rounded,
        subtitle: '${active.name} · Ends ${_shortDate(active.endAt)}',
        status: 'Active',
      );
    case SubscriptionAccessStatus.error:
      return const _SubscriptionPresentation(
        icon: Icons.workspace_premium_outlined,
        subtitle: 'Open Subscription to view available plans',
        status: 'Unavailable',
      );
  }
}

String _shortDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = value.toLocal();
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}
