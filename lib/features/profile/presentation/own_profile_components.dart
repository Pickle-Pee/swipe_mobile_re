import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/media/app_network_image.dart';
import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/discovery_components.dart';
import '../../../shared/ui/liquid_ui.dart';
import '../../../shared/ui/midnight_components.dart';
import '../../../shared/ui/profile_components.dart';
import '../application/profile_providers.dart';
import '../domain/profile_models.dart';

typedef OwnProfileImageProviderBuilder =
    ImageProvider<Object>? Function(String? url);

class OwnProfileView extends StatelessWidget {
  const OwnProfileView({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onRetry,
    required this.onEdit,
    required this.onPreview,
    required this.onSettings,
    required this.onSubscription,
    required this.onEditStep,
    this.hasPremiumAccess,
    this.subscriptionLoading = false,
    this.imageProviderBuilder = appNetworkImage,
  });

  final ProfileState state;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onSettings;
  final VoidCallback onSubscription;
  final ValueChanged<ProfileCompletionStep> onEditStep;
  final bool? hasPremiumAccess;
  final bool subscriptionLoading;
  final OwnProfileImageProviderBuilder imageProviderBuilder;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    return Scaffold(
      backgroundColor: AppTokens.backgroundBase,
      body: AppGradientScaffold(
        safeArea: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RefreshIndicator(onRefresh: onRefresh, child: _content(context)),
            Positioned(
              left: AppTokens.space12,
              right: AppTokens.space12,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppTokens.space8),
                  child: OwnProfileTopBar(
                    onSettings: onSettings,
                    onEdit: profile == null ? null : onEdit,
                    onPreview: profile == null ? null : onPreview,
                  ),
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
    if (state.status == ProfileStatus.loading && profile == null) {
      return const _OwnProfileLoading(key: Key('own-profile-loading'));
    }
    if (state.status == ProfileStatus.error && profile == null) {
      return _OwnProfileStateFrame(
        child: ErrorState(
          key: const Key('own-profile-error'),
          title: 'Could not load your profile',
          message: profileErrorMessage(state.error),
          actionLabel: 'Try again',
          onAction: onRetry,
        ),
      );
    }
    if (profile == null) {
      return _OwnProfileStateFrame(
        child: EmptyState(
          key: const Key('own-profile-empty'),
          title: 'Your profile is not ready',
          message: 'Reload it or continue editing the existing profile data.',
          actionLabel: 'Reload',
          onAction: onRetry,
          icon: Icons.person_add_alt_1_outlined,
        ),
      );
    }

    final premium = hasPremiumAccess ?? profile.isSubscription;
    final interests = profile.interests
        .map((interest) => interest.label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    final facts = profile.attributes.facts;
    if (profile.gender.trim().isNotEmpty) {
      facts.addAll({'Gender': readableProfileValue(profile.gender)});
    }
    return CustomScrollView(
      key: const PageStorageKey<String>('own-profile-scroll'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space16,
            AppTokens.space8,
            AppTokens.space16,
            AppTokens.floatingNavigationClearance + AppTokens.space24,
          ),
          sliver: SliverList.list(
            children: [
              if (state.status == ProfileStatus.loading) ...[
                const LinearProgressIndicator(
                  key: Key('own-profile-refreshing'),
                  minHeight: 2,
                ),
                const SizedBox(height: AppTokens.space12),
              ],
              if (state.status == ProfileStatus.error) ...[
                _InlineProfileError(
                  key: const Key('own-profile-inline-error'),
                  message: profileErrorMessage(state.error),
                  onRetry: onRetry,
                ),
                const SizedBox(height: AppTokens.space12),
              ],
              OwnProfileHero(
                profile: profile,
                imageProvider: imageProviderBuilder(profile.primaryPhotoUrl),
              ),
              const SizedBox(height: AppTokens.space16),
              ProfileCompletenessCard(
                completeness: profile.completeness,
                onAction: profile.completeness.nextStep == null
                    ? null
                    : () => onEditStep(profile.completeness.nextStep!),
              ),
              const SizedBox(height: AppTokens.space16),
              _SubscriptionEntry(
                active: premium,
                loading: subscriptionLoading,
                onTap: onSubscription,
              ),
              const SizedBox(height: AppTokens.space16),
              ProfileSection(
                key: const Key('own-profile-photos'),
                title: 'Photos',
                icon: Icons.photo_library_outlined,
                child: profile.photos.isEmpty
                    ? _AddContentPrompt(
                        label: 'Add your first photo',
                        icon: Icons.add_photo_alternate_outlined,
                        onTap: () =>
                            onEditStep(ProfileCompletionStep.primaryPhoto),
                      )
                    : _OwnPhotoStrip(
                        photos: profile.photos,
                        imageProviderBuilder: imageProviderBuilder,
                      ),
              ),
              const SizedBox(height: AppTokens.space16),
              ProfileSection(
                key: const Key('own-profile-about'),
                title: 'About',
                icon: Icons.notes_rounded,
                child: profile.aboutMe.trim().isEmpty
                    ? _AddContentPrompt(
                        label: 'Add an introduction',
                        icon: Icons.add_rounded,
                        onTap: () => onEditStep(ProfileCompletionStep.about),
                      )
                    : Text(
                        profile.aboutMe.trim(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
              ),
              const SizedBox(height: AppTokens.space16),
              ProfileSection(
                key: const Key('own-profile-interests'),
                title: 'Interests',
                icon: Icons.auto_awesome_outlined,
                child: interests.isEmpty
                    ? _AddContentPrompt(
                        label: 'Choose interests',
                        icon: Icons.add_rounded,
                        onTap: () =>
                            onEditStep(ProfileCompletionStep.interests),
                      )
                    : Wrap(
                        spacing: AppTokens.space8,
                        runSpacing: AppTokens.space8,
                        children: interests
                            .map((label) => InterestChip(label: label))
                            .toList(growable: false),
                      ),
              ),
              if (facts.isNotEmpty) ...[
                const SizedBox(height: AppTokens.space16),
                ProfileSection(
                  key: const Key('own-profile-facts'),
                  title: 'Profile details',
                  icon: Icons.tune_rounded,
                  child: ProfileFacts(facts: facts),
                ),
              ],
              const SizedBox(height: AppTokens.space20),
              PrimaryActionButton(
                key: const Key('own-profile-edit'),
                label: 'Edit profile',
                icon: Icons.edit_outlined,
                onPressed: onEdit,
              ),
              const SizedBox(height: AppTokens.space12),
              SecondaryActionButton(
                key: const Key('own-profile-preview'),
                label: 'View my public profile',
                icon: Icons.visibility_outlined,
                onPressed: onPreview,
              ),
              const SizedBox(height: AppTokens.space12),
              _SettingsEntry(onTap: onSettings),
            ],
          ),
        ),
      ],
    );
  }
}

class OwnProfileTopBar extends StatelessWidget {
  const OwnProfileTopBar({
    super.key,
    required this.onSettings,
    required this.onEdit,
    required this.onPreview,
  });

  final VoidCallback onSettings;
  final VoidCallback? onEdit;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    return AppTopBar(
      key: const Key('own-profile-top-bar'),
      title: 'My profile',
      actions: [
        GlassIconButton(
          key: const Key('own-profile-preview-action'),
          icon: Icons.visibility_outlined,
          semanticLabel: 'Preview public profile',
          tooltip: 'Preview',
          onPressed: onPreview,
        ),
        GlassIconButton(
          key: const Key('own-profile-edit-action'),
          icon: Icons.edit_outlined,
          semanticLabel: 'Edit profile',
          tooltip: 'Edit',
          onPressed: onEdit,
        ),
        GlassIconButton(
          key: const Key('own-profile-settings-action'),
          icon: Icons.settings_outlined,
          semanticLabel: 'Open settings',
          tooltip: 'Settings',
          onPressed: onSettings,
        ),
      ],
    );
  }
}

class OwnProfileHero extends StatelessWidget {
  const OwnProfileHero({
    super.key,
    required this.profile,
    required this.imageProvider,
  });

  final UserProfile profile;
  final ImageProvider<Object>? imageProvider;

  @override
  Widget build(BuildContext context) {
    final age = profile.age;
    final name = profile.displayName.trim().isEmpty
        ? 'Your profile'
        : profile.displayName.trim();
    return Container(
      key: const Key('own-profile-hero'),
      height: 330,
      decoration: BoxDecoration(
        color: AppTokens.surfaceSolid,
        borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
        border: Border.all(color: AppTokens.glassBorder),
        boxShadow: AppTokens.surfaceShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _OwnProfileImage(
            imageProvider: imageProvider,
            semanticLabel: 'Primary profile photo of $name',
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000000),
                  Colors.transparent,
                  Color(0xE6000000),
                ],
                stops: [0, 0.46, 1],
              ),
            ),
          ),
          Positioned(
            left: AppTokens.space20,
            right: AppTokens.space20,
            bottom: AppTokens.space20,
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    age == null ? name : '$name, $age',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (profile.city.trim().isNotEmpty) ...[
                    const SizedBox(height: AppTokens.space8),
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
                            profile.city.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppTokens.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileCompletenessCard extends StatelessWidget {
  const ProfileCompletenessCard({
    super.key,
    required this.completeness,
    required this.onAction,
  });

  final ProfileCompleteness completeness;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final complete = completeness.isComplete;
    final next = completeness.nextStep;
    return Semantics(
      container: true,
      label:
          'Profile completeness ${completeness.percent} percent, '
          '${completeness.completedCount} of '
          '${ProfileCompleteness.totalSteps} steps',
      child: Container(
        key: const Key('profile-completeness'),
        padding: const EdgeInsets.all(AppTokens.space20),
        decoration: BoxDecoration(
          color: AppTokens.surfaceSolid,
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          border: Border.all(
            color: complete
                ? AppTokens.success.withValues(alpha: 0.42)
                : AppTokens.glassBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    complete ? 'Profile complete' : 'Complete your profile',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${completeness.percent}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: complete ? AppTokens.success : AppTokens.brandRose,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: completeness.percent / 100,
                backgroundColor: AppTokens.backgroundElevated,
                color: complete ? AppTokens.success : AppTokens.brandRose,
              ),
            ),
            const SizedBox(height: AppTokens.space12),
            Text(
              complete
                  ? 'All five saved profile steps are complete.'
                  : '${completeness.completedCount} of '
                        '${ProfileCompleteness.totalSteps} steps · '
                        '${profileCompletionActionLabel(next!)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!complete) ...[
              const SizedBox(height: AppTokens.space8),
              TextButton.icon(
                key: const Key('profile-completeness-action'),
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(profileCompletionActionLabel(next!)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String profileCompletionActionLabel(ProfileCompletionStep step) =>
    switch (step) {
      ProfileCompletionStep.primaryPhoto => 'Add a primary photo',
      ProfileCompletionStep.about => 'Add an introduction',
      ProfileCompletionStep.interests => 'Choose interests',
      ProfileCompletionStep.city => 'Add your city',
      ProfileCompletionStep.lookingFor => 'Choose what you are looking for',
    };

class _SubscriptionEntry extends StatelessWidget {
  const _SubscriptionEntry({
    required this.active,
    required this.loading,
    required this.onTap,
  });

  final bool active;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SolidEntry(
      key: const Key('own-profile-subscription'),
      icon: active ? Icons.workspace_premium_rounded : Icons.auto_awesome,
      iconColor: active ? AppTokens.success : AppTokens.brandViolet,
      title: active ? 'Premium active' : 'Free access',
      subtitle: active
          ? 'Manage your active subscription'
          : 'Explore subscription options',
      trailing: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _SettingsEntry extends StatelessWidget {
  const _SettingsEntry({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _SolidEntry(
    key: const Key('own-profile-settings'),
    icon: Icons.settings_outlined,
    iconColor: AppTokens.textSecondary,
    title: 'Settings',
    subtitle: 'Safety and app preferences',
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _SolidEntry extends StatelessWidget {
  const _SolidEntry({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surfaceSolid,
      borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(AppTokens.space16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            border: Border.all(color: AppTokens.glassBorder),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppTokens.space4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.space8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnPhotoStrip extends StatelessWidget {
  const _OwnPhotoStrip({
    required this.photos,
    required this.imageProviderBuilder,
  });

  final List<ProfilePhoto> photos;
  final OwnProfileImageProviderBuilder imageProviderBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.space8),
        itemBuilder: (context, index) {
          final photo = photos[index];
          return Semantics(
            image: true,
            label:
                'Profile photo ${index + 1} of ${photos.length}'
                '${photo.isAvatar ? ', primary' : ''}',
            child: SizedBox(
              key: ValueKey<String>('own-photo-${photo.id}'),
              width: 88,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _OwnProfileImage(
                      imageProvider: imageProviderBuilder(photo.url),
                      semanticLabel: 'Profile photo ${index + 1}',
                    ),
                    if (photo.isAvatar)
                      const Positioned(
                        left: AppTokens.space4,
                        right: AppTokens.space4,
                        bottom: AppTokens.space4,
                        child: _PrimaryPhotoLabel(),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PrimaryPhotoLabel extends StatelessWidget {
  const _PrimaryPhotoLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space8,
        vertical: AppTokens.space4,
      ),
      decoration: BoxDecoration(
        color: AppTokens.scrim,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_rounded, size: 13, color: AppTokens.warning),
          SizedBox(width: AppTokens.space4),
          Flexible(child: Text('Primary', style: TextStyle(fontSize: 11))),
        ],
      ),
    );
  }
}

class _OwnProfileImage extends StatelessWidget {
  const _OwnProfileImage({
    required this.imageProvider,
    required this.semanticLabel,
  });

  final ImageProvider<Object>? imageProvider;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final provider = imageProvider;
    if (provider == null) {
      return ProfileMediaPlaceholder(semanticLabel: semanticLabel);
    }
    final logicalWidth = MediaQuery.sizeOf(context).width;
    final decodeWidth = (logicalWidth * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, 2048)
        .toInt();
    return Image(
      image: ResizeImage.resizeIfNeeded(decodeWidth, null, provider),
      fit: BoxFit.cover,
      semanticLabel: semanticLabel,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const SkeletonLoader(radius: 0);
      },
      errorBuilder: (_, __, ___) =>
          ProfileMediaPlaceholder(semanticLabel: semanticLabel),
    );
  }
}

class _AddContentPrompt extends StatelessWidget {
  const _AddContentPrompt({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    ),
  );
}

class _InlineProfileError extends StatelessWidget {
  const _InlineProfileError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppTokens.space12),
        decoration: BoxDecoration(
          color: AppTokens.surfaceSolid,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          border: Border.all(color: AppTokens.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTokens.error),
            const SizedBox(width: AppTokens.space8),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _OwnProfileLoading extends StatelessWidget {
  const _OwnProfileLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        104,
        AppTokens.space16,
        AppTokens.floatingNavigationClearance,
      ),
      children: const [
        SkeletonLoader(height: 330, radius: AppTokens.radiusXLarge),
        SizedBox(height: AppTokens.space16),
        SkeletonLoader(height: 148),
        SizedBox(height: AppTokens.space16),
        SkeletonLoader(height: 80),
        SizedBox(height: AppTokens.space16),
        SkeletonLoader(height: 180),
      ],
    );
  }
}

class _OwnProfileStateFrame extends StatelessWidget {
  const _OwnProfileStateFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space20,
        112,
        AppTokens.space20,
        AppTokens.floatingNavigationClearance,
      ),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.58,
          child: Center(child: child),
        ),
      ],
    );
  }
}

String profileErrorMessage(Object? error) {
  if (error is InvalidProfilePhotoException) return error.message;
  if (error is PartialProfileSaveException) {
    return 'Some sections were saved, but the profile update did not finish. '
        'Your remaining draft is still here.';
  }
  if (error is ApiException) return error.message;
  return 'Something went wrong. Please try again.';
}
