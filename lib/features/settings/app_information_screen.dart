import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/midnight_components.dart';
import 'application/settings_providers.dart';
import 'domain/settings_models.dart';
import 'presentation/settings_components.dart';

class AppInformationScreen extends ConsumerStatefulWidget {
  const AppInformationScreen({super.key});

  @override
  ConsumerState<AppInformationScreen> createState() =>
      _AppInformationScreenState();
}

class _AppInformationScreenState extends ConsumerState<AppInformationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      ref.read(appInformationControllerProvider.notifier).ensureLoaded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appInformationControllerProvider);
    return SettingsPageScaffold(
      title: 'App information',
      onBack: _back,
      child: ListView(
        key: const Key('app-information-list'),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space20,
          104,
          AppTokens.space20,
          AppTokens.space40,
        ),
        children: [_content(state)],
      ),
    );
  }

  Widget _content(AppInformationState state) {
    switch (state.status) {
      case AppInformationStatus.initial:
      case AppInformationStatus.loading:
        return const Column(
          key: Key('app-information-loading'),
          children: [
            SkeletonLoader(height: 76),
            SizedBox(height: AppTokens.space8),
            SkeletonLoader(height: 76),
          ],
        );
      case AppInformationStatus.error:
        return ErrorState(
          key: const Key('app-information-error'),
          title: 'App information unavailable',
          message:
              'Swipe could not read the installed package information. '
              'No internal build details are shown.',
          actionLabel: 'Retry',
          onAction: () => unawaited(
            ref.read(appInformationControllerProvider.notifier).retry(),
          ),
        );
      case AppInformationStatus.data:
        final info = state.packageInfo!;
        return SettingsSection(
          title: 'Installed application',
          footer: const Text(
            'Legal and support links are not configured in the current '
            'application contract.',
          ),
          children: [
            SettingsTile(
              key: const Key('app-information-name'),
              leadingIcon: Icons.nightlight_round,
              title: 'Application',
              statusLabel: info.appName,
            ),
            SettingsTile(
              key: const Key('app-information-version'),
              leadingIcon: Icons.layers_outlined,
              title: 'Version',
              statusLabel: info.version,
            ),
            SettingsTile(
              key: const Key('app-information-build'),
              leadingIcon: Icons.build_outlined,
              title: 'Build',
              statusLabel: info.buildNumber,
            ),
          ],
        );
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.settings);
    }
  }
}
