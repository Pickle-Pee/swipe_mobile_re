import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/liquid_ui.dart';
import '../../../shared/ui/midnight_components.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientScaffold(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space20,
                AppTokens.space24,
                AppTokens.space20,
                AppTokens.space24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppTokens.space24 * 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _WelcomeBrand(),
                    const SizedBox(height: AppTokens.space40),
                    const _WelcomeHero(),
                    const SizedBox(height: AppTokens.space40),
                    GlassSurface(
                      level: GlassLevel.overlay,
                      child: Column(
                        children: [
                          PrimaryActionButton(
                            key: const Key('welcome-register'),
                            label: 'Create account',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () =>
                                context.go(Routes.registrationPhone),
                          ),
                          const SizedBox(height: AppTokens.space12),
                          SecondaryActionButton(
                            key: const Key('welcome-login'),
                            label: 'I already have an account',
                            onPressed: () => context.go(Routes.loginPhone),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeBrand extends StatelessWidget {
  const _WelcomeBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppTokens.minTouchTarget,
          height: AppTokens.minTouchTarget,
          decoration: BoxDecoration(
            gradient: AppTokens.ctaGradient,
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
            boxShadow: AppTokens.brandShadow(),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: AppTokens.textPrimary,
          ),
        ),
        const SizedBox(width: AppTokens.space12),
        Text('Swipe', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 76,
            height: 5,
            decoration: BoxDecoration(
              gradient: AppTokens.ctaGradient,
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            ),
          ),
          const SizedBox(height: AppTokens.space24),
          Text(
            'Meet people\nat your pace.',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppTokens.space16),
          Text(
            'A calm place to discover real profiles, start conversations, and build a connection.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
