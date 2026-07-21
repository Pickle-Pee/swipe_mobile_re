import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'midnight_components.dart';

class ProfileMediaCard extends StatelessWidget {
  const ProfileMediaCard({
    super.key,
    required this.semanticLabel,
    required this.overlay,
    this.imageProvider,
  });

  final String semanticLabel;
  final ImageProvider<Object>? imageProvider;
  final Widget overlay;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: imageProvider == null
                ? const _MissingProfileMedia()
                : Image(
                    image: imageProvider!,
                    fit: BoxFit.cover,
                    semanticLabel: semanticLabel,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded || frame != null) {
                            return child;
                          }
                          return const SkeletonLoader(
                            radius: AppTokens.radiusXLarge,
                          );
                        },
                    errorBuilder: (context, error, stackTrace) {
                      return const _MissingProfileMedia();
                    },
                  ),
          ),
          overlay,
        ],
      ),
    );
  }
}

class _MissingProfileMedia extends StatelessWidget {
  const _MissingProfileMedia();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('profile-media-missing'),
      image: true,
      label: 'Profile photo unavailable',
      child: const DecoratedBox(
        decoration: BoxDecoration(gradient: AppTokens.missingMediaGradient),
        child: Center(
          child: Icon(
            Icons.person_outline_rounded,
            size: 88,
            color: AppTokens.textMuted,
          ),
        ),
      ),
    );
  }
}

class ProfileInfoOverlay extends StatelessWidget {
  const ProfileInfoOverlay({
    super.key,
    required this.identity,
    required this.interests,
    required this.onOpenDetails,
    required this.actionBar,
    this.location,
    this.inlineMessage,
  });

  final String identity;
  final String? location;
  final List<String> interests;
  final VoidCallback onOpenDetails;
  final Widget actionBar;
  final Widget? inlineMessage;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: highContrast
              ? const [Colors.transparent, Color(0xD9000000), Colors.black]
              : const [
                  Colors.transparent,
                  Color(0xB3000000),
                  Color(0xF2000000),
                ],
          stops: const [0, 0.38, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space20,
          AppTokens.space40,
          AppTokens.space20,
          AppTokens.space20,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    identity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                GlassIconButton(
                  icon: Icons.expand_less_rounded,
                  semanticLabel: 'Open full profile',
                  tooltip: 'Profile details',
                  onPressed: onOpenDetails,
                ),
              ],
            ),
            if (location != null && location!.isNotEmpty) ...[
              const SizedBox(height: AppTokens.space4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: AppTokens.iconCompact,
                    color: AppTokens.textSecondary,
                  ),
                  const SizedBox(width: AppTokens.space4),
                  Expanded(
                    child: Text(
                      location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (interests.isNotEmpty) ...[
              const SizedBox(height: AppTokens.space12),
              Wrap(
                spacing: AppTokens.space8,
                runSpacing: AppTokens.space8,
                children: interests
                    .take(3)
                    .map((label) => InterestChip(label: label))
                    .toList(growable: false),
              ),
            ],
            if (inlineMessage != null) ...[
              const SizedBox(height: AppTokens.space12),
              inlineMessage!,
            ],
            const SizedBox(height: AppTokens.space16),
            actionBar,
          ],
        ),
      ),
    );
  }
}

class DiscoveryActionBar extends StatelessWidget {
  const DiscoveryActionBar({
    super.key,
    required this.onPass,
    required this.onLike,
    this.passLoading = false,
    this.likeLoading = false,
  });

  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final bool passLoading;
  final bool likeLoading;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Row(
        children: [
          Expanded(
            child: FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: SecondaryActionButton(
                key: const Key('discovery-pass'),
                label: 'Pass',
                icon: Icons.close_rounded,
                loading: passLoading,
                onPressed: onPass,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space12),
          Expanded(
            child: FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: PrimaryActionButton(
                key: const Key('discovery-like'),
                label: 'Like',
                icon: Icons.favorite_rounded,
                loading: likeLoading,
                onPressed: onLike,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
