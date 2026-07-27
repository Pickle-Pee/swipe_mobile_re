import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_gate.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/liquid_ui.dart';
import '../../../shared/ui/midnight_components.dart';
import '../../profile/application/profile_providers.dart';
import '../application/auth_providers.dart';
import '../application/auth_state.dart';

class AppBootstrapScreen extends ConsumerStatefulWidget {
  const AppBootstrapScreen({super.key});

  @override
  ConsumerState<AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends ConsumerState<AppBootstrapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = ref.read(authControllerProvider);
      if (auth.status == AuthStatus.initial) {
        ref.read(authControllerProvider.notifier).restoreSession();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(appGateProvider);
    return Scaffold(
      body: AppGradientScaffold(
        child: SessionRestoreView(gate: gate, onRetry: _retry),
      ),
    );
  }

  void _retry() {
    final auth = ref.read(authControllerProvider);
    if (auth.status == AuthStatus.restoreError ||
        auth.status == AuthStatus.initial) {
      ref.read(authControllerProvider.notifier).restoreSession();
      return;
    }
    ref.read(profileControllerProvider.notifier).load();
  }
}

class SessionRestoreView extends StatelessWidget {
  const SessionRestoreView({
    super.key,
    required this.gate,
    required this.onRetry,
  });

  final AppGateState gate;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final unavailable = gate.status == AppGateStatus.unavailable;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.space24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: unavailable
              ? ErrorState(
                  title: 'Could not restore your session',
                  message: _messageFor(gate.error),
                  actionLabel: 'Try again',
                  onAction: onRetry,
                )
              : const _RestoreProgress(),
        ),
      ),
    );
  }

  String _messageFor(Object? error) {
    if (error is NetworkApiException) {
      return 'Check your connection and try again. Your saved session is still secure.';
    }
    if (error is ServerApiException) {
      return 'The service is temporarily unavailable. Please try again.';
    }
    return 'We could not finish the secure session check. Please try again.';
  }
}

class _RestoreProgress extends StatelessWidget {
  const _RestoreProgress();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Restoring secure session',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: AppTokens.ctaGradient,
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
              boxShadow: AppTokens.brandShadow(),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppTokens.textPrimary,
              size: 34,
            ),
          ),
          const SizedBox(height: AppTokens.space20),
          Text('Swipe', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: AppTokens.space16),
          const SizedBox(
            width: 120,
            child: LinearProgressIndicator(minHeight: 3),
          ),
          const SizedBox(height: AppTokens.space12),
          Text(
            'Restoring your session…',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
