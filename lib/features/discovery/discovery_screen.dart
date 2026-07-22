import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/config/config.dart';
import '../../core/network/api_exception.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/discovery_components.dart';
import '../../shared/ui/liquid_ui.dart';
import '../../shared/ui/midnight_components.dart';
import '../../shared/ui/profile_components.dart';
import 'application/discovery_providers.dart';
import 'domain/discovery_models.dart';

typedef DiscoveryImageProviderBuilder =
    ImageProvider<Object>? Function(DiscoveryProfile profile);

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(ref.read(discoveryControllerProvider.notifier).load);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<DiscoveryState>(discoveryControllerProvider, (previous, next) {
      final matched = next.matchedProfile;
      if (matched != null && previous?.matchedProfile == null) {
        ref.read(discoveryControllerProvider.notifier).consumeMatch();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_showMatch(matched));
        });
      }
    });

    final state = ref.watch(discoveryControllerProvider);
    return DiscoveryView(
      state: state,
      onLike: _like,
      onPass: _pass,
      onRetry: _reload,
      onRetryInline: _retryInline,
      onOpenLikes: () => context.go(Routes.likes),
      onOpenChats: () => context.go(Routes.chats),
      onOpenProfile: (profile) {
        unawaited(
          context.push(Routes.publicProfileFor(profile.id), extra: profile),
        );
      },
    );
  }

  void _reload() {
    unawaited(ref.read(discoveryControllerProvider.notifier).load());
  }

  void _like() {
    unawaited(ref.read(discoveryControllerProvider.notifier).like());
  }

  void _pass() {
    unawaited(ref.read(discoveryControllerProvider.notifier).pass());
  }

  void _retryInline() {
    final controller = ref.read(discoveryControllerProvider.notifier);
    final state = ref.read(discoveryControllerProvider);
    if (state.failedReaction != null) {
      unawaited(controller.retryReaction());
    } else {
      unawaited(controller.load());
    }
  }

  Future<void> _showMatch(DiscoveryProfile profile) async {
    final write = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.68),
      builder: (context) => _MatchSheet(profile: profile),
    );
    if (write == true && mounted) {
      context.go('${Routes.chats}?userId=${profile.id}');
    }
  }
}

/// Presentation-only Discovery body. Keeping it independent from Riverpod makes
/// every visual state deterministic in widget and golden tests.
class DiscoveryView extends StatelessWidget {
  const DiscoveryView({
    super.key,
    required this.state,
    required this.onLike,
    required this.onPass,
    required this.onRetry,
    required this.onRetryInline,
    required this.onOpenLikes,
    required this.onOpenChats,
    required this.onOpenProfile,
    this.imageProviderBuilder,
    this.navigationClearance = AppTokens.floatingNavigationClearance,
  });

  final DiscoveryState state;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final VoidCallback onRetry;
  final VoidCallback onRetryInline;
  final VoidCallback onOpenLikes;
  final VoidCallback onOpenChats;
  final ValueChanged<DiscoveryProfile> onOpenProfile;
  final DiscoveryImageProviderBuilder? imageProviderBuilder;
  final double navigationClearance;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: AppGradientScaffold(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppTokens.space12,
              AppTokens.space8,
              AppTokens.space12,
              navigationClearance,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Semantics(
                  sortKey: const OrdinalSortKey(1),
                  child: AnimatedSwitcher(
                    duration: reduceMotion
                        ? Duration.zero
                        : AppTokens.motionContent,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.992, end: 1).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: _content(context),
                  ),
                ),
                Positioned(
                  top: AppTokens.space12,
                  left: AppTokens.space12,
                  right: AppTokens.space12,
                  child: Semantics(
                    sortKey: const OrdinalSortKey(0),
                    child: AppTopBar(
                      key: const Key('discovery-top-bar'),
                      title: 'Discovery',
                      actions: [
                        GlassIconButton(
                          key: const Key('discovery-open-likes'),
                          icon: Icons.favorite_border_rounded,
                          semanticLabel: 'Open Likes',
                          tooltip: 'Likes',
                          onPressed: onOpenLikes,
                        ),
                        const SizedBox(width: AppTokens.space4),
                        GlassIconButton(
                          key: const Key('discovery-open-chats'),
                          icon: Icons.chat_bubble_outline_rounded,
                          semanticLabel: 'Open Chats',
                          tooltip: 'Chats',
                          onPressed: onOpenChats,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final profile = state.current;
    if ((state.status == DiscoveryStatus.initial ||
            state.status == DiscoveryStatus.loading) &&
        profile == null) {
      return const _DiscoveryLoading(key: Key('discovery-loading'));
    }
    if (state.status == DiscoveryStatus.error && profile == null) {
      return _StateFrame(
        key: const Key('discovery-error'),
        child: ErrorState(
          title: 'Discovery is offline',
          message: _errorMessage(state.error),
          actionLabel: 'Try again',
          onAction: onRetry,
        ),
      );
    }
    if (profile == null) {
      final endOfFeed = state.emptyReason == DiscoveryEmptyReason.endOfFeed;
      return _StateFrame(
        key: ValueKey(endOfFeed ? 'discovery-end-of-feed' : 'discovery-empty'),
        child: EmptyState(
          title: endOfFeed ? "You're all caught up" : 'No profiles nearby',
          message: endOfFeed
              ? "You've reached the end of this feed."
              : 'New people can appear here soon.',
          actionLabel: endOfFeed ? 'Check again' : 'Reload profiles',
          onAction: onRetry,
          icon: endOfFeed ? Icons.done_all_rounded : Icons.nightlight_round,
        ),
      );
    }

    final identity = _identity(profile);
    final interests = profile.interests
        .map((interest) => interest.label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    final processing = state.processingReaction;
    final inlineError = state.status == DiscoveryStatus.error
        ? _InlineDiscoveryError(
            message: _errorMessage(state.error),
            onRetry: onRetryInline,
          )
        : null;
    return ProfileMediaCard(
      key: ValueKey('discovery-profile-${profile.id}'),
      heroTag: profileMediaHeroTag(profile.id),
      semanticLabel: profile.firstName.trim().isEmpty
          ? 'Profile photo'
          : 'Profile photo of ${profile.firstName.trim()}',
      imageProvider:
          imageProviderBuilder?.call(profile) ?? _profileImage(profile),
      overlay: ProfileInfoOverlay(
        identity: identity,
        location: profile.city.trim().isEmpty ? null : profile.city.trim(),
        interests: interests,
        onOpenDetails: () => onOpenProfile(profile),
        inlineMessage: inlineError,
        actionBar: DiscoveryActionBar(
          passLoading: processing == DiscoveryReaction.pass,
          likeLoading: processing == DiscoveryReaction.like,
          onPass: processing == null ? onPass : null,
          onLike: processing == null ? onLike : null,
        ),
      ),
    );
  }
}

class _DiscoveryLoading extends StatelessWidget {
  const _DiscoveryLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const SkeletonLoader(radius: AppTokens.radiusXLarge),
          Positioned(
            left: AppTokens.space20,
            right: AppTokens.space20,
            bottom: AppTokens.space20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: 180, height: 30),
                const SizedBox(height: AppTokens.space12),
                const SkeletonLoader(width: 120, height: 18),
                const SizedBox(height: AppTokens.space16),
                const Row(
                  children: [
                    Expanded(child: SkeletonLoader(height: 56, radius: 28)),
                    SizedBox(width: AppTokens.space12),
                    Expanded(child: SkeletonLoader(height: 56, radius: 28)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateFrame extends StatelessWidget {
  const _StateFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 76),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.space12),
          child: child,
        ),
      ),
    );
  }
}

class _InlineDiscoveryError extends StatelessWidget {
  const _InlineDiscoveryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('discovery-inline-error'),
        padding: const EdgeInsets.only(left: AppTokens.space12),
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTokens.textSecondary),
              ),
            ),
            IconButton(
              key: const Key('discovery-inline-retry'),
              tooltip: 'Retry',
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchSheet extends StatelessWidget {
  const _MatchSheet({required this.profile});

  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
    final image = _profileImage(profile);
    final name = profile.firstName.trim();
    return GlassSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppTokens.glassHighlight,
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            ),
          ),
          const SizedBox(height: AppTokens.space24),
          ClipOval(
            child: SizedBox.square(
              dimension: 96,
              child: image == null
                  ? const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppTokens.missingMediaGradient,
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 48,
                        color: AppTokens.textMuted,
                      ),
                    )
                  : Image(
                      image: image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppTokens.missingMediaGradient,
                            ),
                            child: Icon(Icons.person_outline_rounded, size: 48),
                          ),
                    ),
            ),
          ),
          const SizedBox(height: AppTokens.space16),
          Text(
            "It's a match!",
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppTokens.space8),
          Text(
            name.isEmpty
                ? 'You liked each other.'
                : 'You and $name liked each other.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTokens.space24),
          Row(
            children: [
              Expanded(
                child: SecondaryActionButton(
                  label: 'Keep exploring',
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: PrimaryActionButton(
                  label: 'Write',
                  icon: Icons.chat_bubble_rounded,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _identity(DiscoveryProfile profile) {
  final parts = <String>[
    if (profile.firstName.trim().isNotEmpty) profile.firstName.trim(),
    if (profile.age != null) '${profile.age}',
  ];
  return parts.isEmpty ? 'Profile' : parts.join(', ');
}

ImageProvider<Object>? _profileImage(DiscoveryProfile profile) {
  final value = profile.photoUrl?.trim();
  if (value == null || value.isEmpty) return null;
  return NetworkImage(_mediaUrl(value));
}

String _errorMessage(Object? error) => error is ApiException
    ? error.message
    : 'Could not complete the request. Please try again.';

String _mediaUrl(String value) {
  final uri = Uri.parse(value);
  return uri.hasScheme
      ? uri.toString()
      : Uri.parse(AppConfig.baseAppUrl).resolve(value).toString();
}
