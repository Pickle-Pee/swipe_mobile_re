import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/tokens.dart';
import 'application/profile_providers.dart';
import 'application/public_profile_providers.dart';
import 'public_profile_screen.dart';

class OwnProfilePreviewScreen extends ConsumerStatefulWidget {
  const OwnProfilePreviewScreen({super.key});

  @override
  ConsumerState<OwnProfilePreviewScreen> createState() =>
      _OwnProfilePreviewScreenState();
}

class _OwnProfilePreviewScreenState
    extends ConsumerState<OwnProfilePreviewScreen> {
  @override
  void initState() {
    super.initState();
    final state = ref.read(profileControllerProvider);
    if (state.profile == null && state.status != ProfileStatus.loading) {
      Future.microtask(ref.read(profileControllerProvider.notifier).load);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(profileControllerProvider);
    final profile = current.profile;
    final previewState = profile != null
        ? PublicProfileState(
            status: PublicProfileStatus.data,
            profile: profile.toPublicProfile(),
          )
        : switch (current.status) {
            ProfileStatus.loading || ProfileStatus.initial =>
              const PublicProfileState(status: PublicProfileStatus.loading),
            ProfileStatus.error => PublicProfileState(
              status: PublicProfileStatus.error,
              error: current.error,
            ),
            _ => const PublicProfileState(status: PublicProfileStatus.missing),
          };
    return Stack(
      fit: StackFit.expand,
      children: [
        PublicProfileView(
          key: const Key('own-profile-preview'),
          state: previewState,
          title: 'Public preview',
          onBack: () => context.pop(),
          onRetry: () =>
              unawaited(ref.read(profileControllerProvider.notifier).load()),
          enableHero: false,
          showActions: false,
        ),
        if (profile != null)
          Positioned(
            top: 88,
            left: AppTokens.space20,
            right: AppTokens.space20,
            child: SafeArea(
              bottom: false,
              child: IgnorePointer(
                child: Semantics(
                  label: 'This is how other people see your saved profile',
                  child: Container(
                    key: const Key('own-profile-preview-hint'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space12,
                      vertical: AppTokens.space8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.scrim,
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(color: AppTokens.glassBorder),
                    ),
                    child: const Text(
                      'This is how other people see your saved profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTokens.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
