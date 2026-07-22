import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../shared/media/app_network_image.dart';
import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/liquid_ui.dart';
import '../../../shared/ui/midnight_components.dart';
import '../../subscription/application/subscription_providers.dart';
import '../application/likes_providers.dart';
import '../domain/likes_models.dart';

typedef LikesImageProviderBuilder =
    ImageProvider<Object>? Function(LikesUser user);

class LikesView extends StatelessWidget {
  const LikesView({
    super.key,
    required this.state,
    required this.access,
    required this.onBack,
    required this.onRetry,
    required this.onRefresh,
    required this.onSelectCategory,
    required this.onOpenSubscription,
    required this.onOpenDiscovery,
    required this.onOpenProfile,
    this.imageProviderBuilder,
  });

  final LikesState state;
  final SubscriptionAccessState access;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final ValueChanged<LikesCategory> onSelectCategory;
  final VoidCallback onOpenSubscription;
  final VoidCallback onOpenDiscovery;
  final ValueChanged<LikesUser> onOpenProfile;
  final LikesImageProviderBuilder? imageProviderBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.backgroundBase,
      body: AppGradientScaffold(
        safeArea: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space12,
                  AppTokens.space8,
                  AppTokens.space12,
                  0,
                ),
                child: LikesTopBar(count: state.incomingCount, onBack: onBack),
              ),
              const SizedBox(height: AppTokens.space12),
              LikesCategorySelector(
                selected: state.category,
                onSelected: onSelectCategory,
              ),
              const SizedBox(height: AppTokens.space8),
              if (state.isRefreshing || access.isRefreshing)
                const LinearProgressIndicator(
                  key: Key('likes-refresh-progress'),
                  minHeight: 2,
                  color: AppTokens.brandViolet,
                  backgroundColor: Colors.transparent,
                  semanticsLabel: 'Refreshing Likes',
                ),
              Expanded(child: _content(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final accessUnresolved =
        access.status == SubscriptionAccessStatus.initial ||
        access.status == SubscriptionAccessStatus.loading;
    if (accessUnresolved || state.isInitialLoading) {
      return const LikesLoadingGrid(key: Key('likes-loading'));
    }
    if (access.status == SubscriptionAccessStatus.error) {
      return _CenteredState(
        child: ErrorState(
          title: 'Premium access unavailable',
          message:
              'We could not check your subscription. Your Likes stay private until access is confirmed.',
          actionLabel: 'Try again',
          onAction: onRetry,
        ),
      );
    }
    if (state.status == LikesStatus.error && state.data == null) {
      return _CenteredState(
        child: ErrorState(
          title: 'Could not load Likes',
          message: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: onRetry,
        ),
      );
    }

    final users = state.visible;
    if (users.isEmpty) {
      final incoming = state.category == LikesCategory.likedMe;
      if (incoming && access.status == SubscriptionAccessStatus.inactive) {
        return _CenteredState(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyState(
                key: const Key('likes-empty'),
                title: 'New likes will appear here',
                message:
                    'There are no incoming Likes right now. Premium reveals real profiles here when someone likes you.',
                actionLabel: 'View Premium plans',
                onAction: onOpenSubscription,
                icon: Icons.favorite_border_rounded,
              ),
              const SizedBox(height: AppTokens.space8),
              TextButton(
                onPressed: onOpenDiscovery,
                child: const Text('Discover people'),
              ),
            ],
          ),
        );
      }
      return _CenteredState(
        child: EmptyState(
          key: const Key('likes-empty'),
          title: incoming ? 'New likes will appear here' : 'Nothing here yet',
          message: incoming
              ? 'When someone new likes you, their profile will be waiting here.'
              : 'This real list is empty right now.',
          actionLabel: incoming ? 'Discover people' : 'Refresh',
          onAction: incoming ? onOpenDiscovery : onRetry,
          icon: incoming
              ? Icons.favorite_border_rounded
              : Icons.nightlight_round,
        ),
      );
    }

    final inlineError = state.error ?? access.error;
    final grid =
        state.category == LikesCategory.likedMe &&
            access.status == SubscriptionAccessStatus.inactive
        ? LockedLikesGrid(
            key: const Key('likes-locked'),
            users: users,
            imageProviderBuilder: imageProviderBuilder,
            onSubscribe: onOpenSubscription,
          )
        : LikesProfileGrid(
            key: Key('likes-grid-${state.category.name}'),
            users: users,
            pageStorageKey: 'likes-grid-${state.category.name}',
            imageProviderBuilder: imageProviderBuilder,
            onOpenProfile: onOpenProfile,
            onRefresh: onRefresh,
          );

    if (inlineError == null) return grid;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space16,
            0,
            AppTokens.space16,
            AppTokens.space8,
          ),
          child: LikesInlineError(onRetry: onRetry),
        ),
        Expanded(child: grid),
      ],
    );
  }
}

class LikesTopBar extends StatelessWidget {
  const LikesTopBar({super.key, required this.count, required this.onBack});

  final int? count;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AppTopBar(
      key: const Key('likes-top-bar'),
      title: 'Likes',
      leading: GlassIconButton(
        icon: Icons.arrow_back_rounded,
        semanticLabel: 'Back to Discover',
        tooltip: 'Back',
        onPressed: onBack,
      ),
      actions: [if (count != null) PremiumBadge(count: count!)],
    );
  }
}

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 new like' : '$count new likes';
    return Semantics(
      label: label,
      child: Container(
        key: const Key('likes-real-count'),
        constraints: const BoxConstraints(minHeight: AppTokens.minTouchTarget),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12),
        decoration: BoxDecoration(
          color: AppTokens.brandRose.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          border: Border.all(
            color: AppTokens.brandRose.withValues(alpha: 0.38),
          ),
        ),
        child: Text(
          '$count',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class LikesCategorySelector extends StatelessWidget {
  const LikesCategorySelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final LikesCategory selected;
  final ValueChanged<LikesCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Likes categories',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
        child: Row(
          children: [
            for (final category in LikesCategory.values) ...[
              ChoiceChip(
                key: Key('likes-category-${category.name}'),
                label: Text(_categoryLabel(category)),
                selected: selected == category,
                onSelected: (_) => onSelected(category),
                showCheckmark: selected == category,
                selectedColor: AppTokens.glassActive,
                backgroundColor: AppTokens.surfaceSolid,
                side: BorderSide(
                  color: selected == category
                      ? AppTokens.brandViolet
                      : AppTokens.glassBorder,
                ),
                shape: const StadiumBorder(),
              ),
              if (category != LikesCategory.values.last)
                const SizedBox(width: AppTokens.space8),
            ],
          ],
        ),
      ),
    );
  }
}

class LikesProfileGrid extends StatelessWidget {
  const LikesProfileGrid({
    super.key,
    required this.users,
    required this.pageStorageKey,
    required this.onOpenProfile,
    this.imageProviderBuilder,
    this.onRefresh,
    this.locked = false,
  });

  final List<LikesUser> users;
  final String pageStorageKey;
  final ValueChanged<LikesUser>? onOpenProfile;
  final LikesImageProviderBuilder? imageProviderBuilder;
  final Future<void> Function()? onRefresh;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final grid = LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 4
            : constraints.maxWidth >= 520
            ? 3
            : 2;
        final compact = constraints.maxWidth < 350;
        return GridView.builder(
          key: PageStorageKey<String>(pageStorageKey),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            compact ? AppTokens.space12 : AppTokens.space16,
            AppTokens.space8,
            compact ? AppTokens.space12 : AppTokens.space16,
            AppTokens.floatingNavigationClearance + AppTokens.space24,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: compact ? AppTokens.space8 : AppTokens.space12,
            mainAxisSpacing: compact ? AppTokens.space8 : AppTokens.space12,
            childAspectRatio: compact ? 0.70 : 0.72,
          ),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return LikesProfileCard(
              key: ValueKey<String>('likes-profile-${user.id}'),
              user: user,
              locked: locked,
              imageProviderBuilder: imageProviderBuilder,
              onTap: locked || onOpenProfile == null
                  ? null
                  : () => onOpenProfile!(user),
            );
          },
        );
      },
    );
    final refresh = onRefresh;
    return refresh == null
        ? grid
        : RefreshIndicator(onRefresh: refresh, child: grid);
  }
}

class LikesProfileCard extends StatelessWidget {
  const LikesProfileCard({
    super.key,
    required this.user,
    required this.onTap,
    this.imageProviderBuilder,
    this.locked = false,
  });

  final LikesUser user;
  final VoidCallback? onTap;
  final LikesImageProviderBuilder? imageProviderBuilder;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final age = user.age;
    final identity = [
      user.firstName.trim(),
      if (age != null) '$age',
    ].where((value) => value.isNotEmpty).join(', ');
    final semantic = [
      if (identity.isNotEmpty) identity,
      if (user.city.trim().isNotEmpty) user.city.trim(),
      if (user.mutual) 'Mutual match',
    ].join('. ');

    return RepaintBoundary(
      child: Semantics(
        button: onTap != null,
        enabled: onTap != null,
        label: locked ? null : semantic,
        excludeSemantics: true,
        child: Material(
          color: AppTokens.surfaceSolid,
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _LikesProfileMedia(
                  user: user,
                  imageProviderBuilder: imageProviderBuilder,
                  exposeSemantics: !locked,
                ),
                if (!locked) ...[
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x22000000),
                          Color(0xF2000000),
                        ],
                        stops: [0.42, 0.64, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppTokens.space12,
                    right: AppTokens.space12,
                    bottom: AppTokens.space12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                identity.isEmpty ? 'Profile' : identity,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppTokens.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            if (user.mutual)
                              const Icon(
                                Icons.favorite_rounded,
                                size: AppTokens.iconCompact,
                                color: AppTokens.brandRose,
                              ),
                          ],
                        ),
                        if (user.city.trim().isNotEmpty) ...[
                          const SizedBox(height: AppTokens.space4),
                          Text(
                            user.city.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTokens.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LockedLikesGrid extends StatelessWidget {
  const LockedLikesGrid({
    super.key,
    required this.users,
    required this.onSubscribe,
    this.imageProviderBuilder,
  });

  final List<LikesUser> users;
  final VoidCallback onSubscribe;
  final LikesImageProviderBuilder? imageProviderBuilder;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: IgnorePointer(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0x6611131B),
                  BlendMode.srcOver,
                ),
                child: LikesProfileGrid(
                  users: users,
                  pageStorageKey: 'likes-grid-locked',
                  onOpenProfile: null,
                  imageProviderBuilder: imageProviderBuilder,
                  locked: true,
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space20),
            child: PremiumGateOverlay(onSubscribe: onSubscribe),
          ),
        ),
      ],
    );
  }
}

class PremiumGateOverlay extends StatelessWidget {
  const PremiumGateOverlay({super.key, required this.onSubscribe});

  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Incoming Likes are available with Premium',
      child: SubscriptionUpsellCard(onSubscribe: onSubscribe),
    );
  }
}

class SubscriptionUpsellCard extends StatelessWidget {
  const SubscriptionUpsellCard({super.key, required this.onSubscribe});

  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Container(
        key: const Key('likes-premium-gate'),
        padding: const EdgeInsets.all(AppTokens.space24),
        decoration: BoxDecoration(
          color: highContrast
              ? AppTokens.backgroundBase
              : AppTokens.surfaceSolid.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          border: Border.all(
            color: highContrast
                ? AppTokens.glassHighlight
                : AppTokens.brandViolet.withValues(alpha: 0.50),
          ),
          boxShadow: AppTokens.surfaceShadow(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTokens.ctaGradient,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: AppTokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppTokens.space16),
            Text(
              'See who already likes you',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              'Premium reveals your real incoming Likes. Subscription status is always confirmed by the backend.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTokens.textSecondary),
            ),
            const SizedBox(height: AppTokens.space20),
            PrimaryActionButton(
              key: const Key('likes-open-subscription'),
              label: 'View plans',
              icon: Icons.auto_awesome_rounded,
              onPressed: onSubscribe,
            ),
          ],
        ),
      ),
    );
  }
}

class LikesLoadingGrid extends StatelessWidget {
  const LikesLoadingGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading Likes',
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space16,
          AppTokens.space8,
          AppTokens.space16,
          AppTokens.floatingNavigationClearance + AppTokens.space24,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppTokens.space12,
          mainAxisSpacing: AppTokens.space12,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (_, index) => const SkeletonLoader(
          height: double.infinity,
          radius: AppTokens.radiusLarge,
        ),
      ),
    );
  }
}

class LikesInlineError extends StatelessWidget {
  const LikesInlineError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space12,
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
            const Expanded(child: Text('Could not refresh Likes.')),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _LikesProfileMedia extends StatelessWidget {
  const _LikesProfileMedia({
    required this.user,
    required this.imageProviderBuilder,
    required this.exposeSemantics,
  });

  final LikesUser user;
  final LikesImageProviderBuilder? imageProviderBuilder;
  final bool exposeSemantics;

  @override
  Widget build(BuildContext context) {
    final image =
        imageProviderBuilder?.call(user) ?? appNetworkImage(user.avatarUrl);
    if (image == null) {
      return _LikesMediaPlaceholder(exposeSemantics: exposeSemantics);
    }
    return Image(
      image: ResizeImage.resizeIfNeeded(420, null, image),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      excludeFromSemantics: !exposeSemantics,
      semanticLabel: exposeSemantics ? '${user.firstName} profile photo' : null,
      frameBuilder: (context, child, frame, synchronouslyLoaded) {
        if (synchronouslyLoaded || frame != null) return child;
        return const SkeletonLoader(
          height: double.infinity,
          radius: AppTokens.radiusLarge,
        );
      },
      errorBuilder: (_, _, _) =>
          _LikesMediaPlaceholder(exposeSemantics: exposeSemantics),
    );
  }
}

class _LikesMediaPlaceholder extends StatelessWidget {
  const _LikesMediaPlaceholder({required this.exposeSemantics});

  final bool exposeSemantics;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: exposeSemantics ? 'Profile photo unavailable' : null,
      excludeSemantics: !exposeSemantics,
      child: const DecoratedBox(
        key: Key('likes-missing-image'),
        decoration: BoxDecoration(gradient: AppTokens.missingMediaGradient),
        child: Center(
          child: Icon(
            Icons.person_outline_rounded,
            size: 52,
            color: AppTokens.textMuted,
          ),
        ),
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space20,
          AppTokens.space20,
          AppTokens.space20,
          AppTokens.floatingNavigationClearance + AppTokens.space24,
        ),
        child: child,
      ),
    );
  }
}

String _categoryLabel(LikesCategory category) => switch (category) {
  LikesCategory.likedMe => 'Liked me',
  LikesCategory.likedUsers => 'My likes',
  LikesCategory.favorites => 'Favorites',
  LikesCategory.mutual => 'Matches',
};
