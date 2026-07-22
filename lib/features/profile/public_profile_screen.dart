import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/config/config.dart';
import '../../core/network/api_exception.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';
import '../../shared/ui/midnight_components.dart';
import '../../shared/ui/profile_components.dart';
import '../discovery/domain/discovery_models.dart';
import '../discovery/application/discovery_providers.dart';
import 'application/public_profile_providers.dart';
import 'domain/profile_models.dart';
import 'domain/public_profile_seed.dart';

typedef PublicProfileImageProviderBuilder =
    ImageProvider<Object>? Function(String? photoUrl);

class PublicProfileScreen extends ConsumerStatefulWidget {
  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.initialProfile,
  });

  final int userId;
  final DiscoveryProfile? initialProfile;

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void didUpdateWidget(covariant PublicProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publicProfileControllerProvider(widget.userId));
    final discovery = ref.watch(discoveryControllerProvider);
    final isCurrentProfile = discovery.current?.id == widget.userId;
    return PublicProfileView(
      state: state,
      onBack: () => Navigator.maybePop(context),
      onRetry: _load,
      showActions: isCurrentProfile,
      passLoading: discovery.processingReaction == DiscoveryReaction.pass,
      likeLoading: discovery.processingReaction == DiscoveryReaction.like,
      reactionError: isCurrentProfile && discovery.failedReaction != null
          ? discovery.error
          : null,
      onPass: isCurrentProfile && !discovery.isProcessing
          ? () => unawaited(_react(DiscoveryReaction.pass))
          : null,
      onLike: isCurrentProfile && !discovery.isProcessing
          ? () => unawaited(_react(DiscoveryReaction.like))
          : null,
      onRetryReaction: discovery.failedReaction != null
          ? () => unawaited(_retryReaction())
          : null,
    );
  }

  void _load() {
    unawaited(
      ref
          .read(publicProfileControllerProvider(widget.userId).notifier)
          .load(seed: publicProfileSeedFromDiscovery(widget.initialProfile)),
    );
  }

  Future<void> _react(DiscoveryReaction reaction) async {
    final controller = ref.read(discoveryControllerProvider.notifier);
    final result = reaction == DiscoveryReaction.like
        ? await controller.like()
        : await controller.pass();
    if (!mounted || result == null) return;
    if (!result.isMatch) context.go(Routes.discover);
  }

  Future<void> _retryReaction() async {
    final result = await ref
        .read(discoveryControllerProvider.notifier)
        .retryReaction();
    if (!mounted || result == null) return;
    if (!result.isMatch) context.go(Routes.discover);
  }
}

/// Presentation-only public profile used by widget and golden tests.
class PublicProfileView extends StatelessWidget {
  const PublicProfileView({
    super.key,
    required this.state,
    required this.onBack,
    required this.onRetry,
    this.imageProviderBuilder,
    this.enableHero = true,
    this.showActions = false,
    this.onPass,
    this.onLike,
    this.onRetryReaction,
    this.passLoading = false,
    this.likeLoading = false,
    this.reactionError,
  });

  final PublicProfileState state;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  final PublicProfileImageProviderBuilder? imageProviderBuilder;
  final bool enableHero;
  final bool showActions;
  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final VoidCallback? onRetryReaction;
  final bool passLoading;
  final bool likeLoading;
  final Object? reactionError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.backgroundBase,
      body: AppGradientScaffold(
        safeArea: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _content(context),
            Positioned(
              left: AppTokens.space12,
              right: AppTokens.space12,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppTokens.space8),
                  child: AppTopBar(
                    key: const Key('public-profile-top-bar'),
                    title: 'Profile',
                    leading: GlassIconButton(
                      key: const Key('public-profile-back'),
                      icon: Icons.arrow_back_rounded,
                      semanticLabel: 'Back to Discovery',
                      tooltip: 'Back',
                      onPressed: onBack,
                    ),
                  ),
                ),
              ),
            ),
            if (showActions)
              Positioned(
                left: AppTokens.space12,
                right: AppTokens.space12,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: AppTokens.space8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (reactionError != null) ...[
                        _ProfileReactionError(
                          message: _profileErrorMessage(reactionError),
                          onRetry: onRetryReaction,
                        ),
                        const SizedBox(height: AppTokens.space8),
                      ],
                      ProfileActionBar(
                        key: const Key('public-profile-action-bar'),
                        onPass: onPass,
                        onLike: onLike,
                        passLoading: passLoading,
                        likeLoading: likeLoading,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final profile = state.profile;
    if ((state.status == PublicProfileStatus.initial ||
            state.status == PublicProfileStatus.loading) &&
        profile == null) {
      return const _PublicProfileLoading(key: Key('public-profile-loading'));
    }
    if (state.status == PublicProfileStatus.missing && profile == null) {
      return _PublicProfileStateFrame(
        key: const Key('public-profile-missing'),
        child: EmptyState(
          title: 'Profile unavailable',
          message: 'This profile may have been removed.',
          actionLabel: 'Go back',
          onAction: onBack,
          icon: Icons.person_off_outlined,
        ),
      );
    }
    if (state.status == PublicProfileStatus.error && profile == null) {
      return _PublicProfileStateFrame(
        key: const Key('public-profile-error'),
        child: ErrorState(
          title: 'Could not load profile',
          message: _profileErrorMessage(state.error),
          actionLabel: 'Try again',
          onAction: onRetry,
        ),
      );
    }
    if (profile == null) {
      return _PublicProfileStateFrame(
        child: EmptyState(
          title: 'Profile unavailable',
          message: 'There is no profile data to show.',
          actionLabel: 'Go back',
          onAction: onBack,
          icon: Icons.person_off_outlined,
        ),
      );
    }
    return _PublicProfileContent(
      profile: profile,
      loading: state.status == PublicProfileStatus.loading,
      refreshError: state.status == PublicProfileStatus.error
          ? state.error
          : null,
      onRetry: onRetry,
      imageProviderBuilder: imageProviderBuilder ?? _networkProfileImage,
      enableHero: enableHero,
      bottomClearance: showActions ? 164 : AppTokens.space40,
    );
  }
}

class _PublicProfileContent extends StatelessWidget {
  const _PublicProfileContent({
    required this.profile,
    required this.loading,
    required this.refreshError,
    required this.onRetry,
    required this.imageProviderBuilder,
    required this.enableHero,
    required this.bottomClearance,
  });

  final PublicUserProfile profile;
  final bool loading;
  final Object? refreshError;
  final VoidCallback onRetry;
  final PublicProfileImageProviderBuilder imageProviderBuilder;
  final bool enableHero;
  final double bottomClearance;

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (viewportHeight * 0.66).clamp(360.0, 620.0).toDouble();
    final interests = profile.interests
        .map((interest) => interest.label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    return CustomScrollView(
      key: const Key('public-profile-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: ProfileHero(
            profile: profile,
            imageProvider: imageProviderBuilder(profile.heroPhotoUrl),
            height: heroHeight,
            enableHero: enableHero,
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppTokens.space16,
            AppTokens.space20,
            AppTokens.space16,
            bottomClearance,
          ),
          sliver: SliverList.list(
            children: [
              if (loading) ...[
                const LinearProgressIndicator(
                  key: Key('public-profile-refreshing'),
                  minHeight: 2,
                ),
                const SizedBox(height: AppTokens.space16),
              ],
              if (refreshError != null) ...[
                _ProfileRefreshError(
                  message: _profileErrorMessage(refreshError),
                  onRetry: onRetry,
                ),
                const SizedBox(height: AppTokens.space16),
              ],
              if (profile.aboutMe.trim().isNotEmpty) ...[
                ProfileSection(
                  key: const Key('public-profile-about'),
                  title: 'About',
                  icon: Icons.notes_rounded,
                  child: Text(
                    profile.aboutMe.trim(),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
              ],
              if (profile.additionalPhotos.isNotEmpty) ...[
                ProfileSection(
                  key: const Key('public-profile-photos'),
                  title: 'Photos',
                  icon: Icons.photo_library_outlined,
                  child: ProfilePhotoGallery(
                    photos: profile.additionalPhotos,
                    imageProviderBuilder: (photo) =>
                        imageProviderBuilder(photo.url),
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
              ],
              if (interests.isNotEmpty) ...[
                ProfileSection(
                  key: const Key('public-profile-interests'),
                  title: 'Interests',
                  icon: Icons.auto_awesome_outlined,
                  child: Wrap(
                    spacing: AppTokens.space8,
                    runSpacing: AppTokens.space8,
                    children: interests
                        .map((label) => InterestChip(label: label))
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
              ],
              if (profile.facts.isNotEmpty)
                ProfileSection(
                  key: const Key('public-profile-facts'),
                  title: 'Profile details',
                  icon: Icons.tune_rounded,
                  child: ProfileFacts(facts: profile.facts),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileRefreshError extends StatelessWidget {
  const _ProfileRefreshError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('public-profile-inline-error'),
        padding: const EdgeInsets.all(AppTokens.space16),
        decoration: BoxDecoration(
          color: AppTokens.surfaceSolid,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          border: Border.all(color: AppTokens.error.withValues(alpha: 0.54)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTokens.error),
            const SizedBox(width: AppTokens.space12),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ProfileReactionError extends StatelessWidget {
  const _ProfileReactionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('public-profile-reaction-error'),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space16,
          AppTokens.space8,
          AppTokens.space8,
          AppTokens.space8,
        ),
        decoration: BoxDecoration(
          color: AppTokens.surfaceSolid,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          border: Border.all(color: AppTokens.error.withValues(alpha: 0.54)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTokens.error,
              size: AppTokens.iconStandard,
            ),
            const SizedBox(width: AppTokens.space8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _PublicProfileLoading extends StatelessWidget {
  const _PublicProfileLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: const [
        SkeletonLoader(height: 500, radius: 0),
        Padding(
          padding: EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(width: 180, height: 24),
              SizedBox(height: AppTokens.space16),
              SkeletonLoader(height: 140),
              SizedBox(height: AppTokens.space16),
              SkeletonLoader(height: 96),
            ],
          ),
        ),
      ],
    );
  }
}

class _PublicProfileStateFrame extends StatelessWidget {
  const _PublicProfileStateFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space20,
            96,
            AppTokens.space20,
            AppTokens.space20,
          ),
          child: child,
        ),
      ),
    );
  }
}

ImageProvider<Object>? _networkProfileImage(String? value) {
  final photo = value?.trim();
  if (photo == null || photo.isEmpty) return null;
  final uri = Uri.parse(photo);
  final resolved = uri.hasScheme
      ? uri.toString()
      : Uri.parse(AppConfig.baseAppUrl).resolve(photo).toString();
  return NetworkImage(resolved);
}

String _profileErrorMessage(Object? error) => error is ApiException
    ? error.message
    : 'Could not load this profile. Please try again.';
