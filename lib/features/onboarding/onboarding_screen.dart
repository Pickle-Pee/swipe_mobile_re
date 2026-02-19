import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientScaffold(
        child: Padding(
          padding: AppTokens.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTokens.ctaGradient,
                  boxShadow: AppTokens.glowShadow(),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 54),
              ),
              const SizedBox(height: 24),
              const PillTag(label: 'AI-powered connection'),
              const SizedBox(height: 24),
              Text('Welcome to emotional\nintelligence',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 12),
              const Text(
                'An AI-native experience designed to understand who you are and help you find meaningful connections.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTokens.textSecondary),
              ),
              const SizedBox(height: 36),
              GradientButton(label: 'Begin your journey', onPressed: () => context.go(Routes.register)),
            ],
          ),
        ),
      ),
    );
  }
}
