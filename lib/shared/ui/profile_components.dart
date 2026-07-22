import 'package:flutter/material.dart';

import '../../features/profile/domain/profile_models.dart';
import '../theme/tokens.dart';
import 'discovery_components.dart';
import 'midnight_components.dart';

String profileMediaHeroTag(int profileId) => 'public-profile-media-$profileId';

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.profile,
    required this.imageProvider,
    required this.height,
    this.enableHero = true,
  });

  final PublicUserProfile profile;
  final ImageProvider<Object>? imageProvider;
  final double height;
  final bool enableHero;

  @override
  Widget build(BuildContext context) {
    final highContrast = MediaQuery.highContrastOf(context);
    final media = RepaintBoundary(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppTokens.radiusXLarge),
        ),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _BoundedProfileImage(
                imageProvider: imageProvider,
                semanticLabel: profile.displayName.trim().isEmpty
                    ? 'Profile photo'
                    : 'Profile photo of ${profile.displayName.trim()}',
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: highContrast
                        ? const [
                            Color(0x99000000),
                            Colors.transparent,
                            Color(0xF2000000),
                            Colors.black,
                          ]
                        : const [
                            Color(0x70000000),
                            Colors.transparent,
                            Color(0xC7000000),
                            Color(0xFA000000),
                          ],
                    stops: const [0, 0.28, 0.72, 1],
                  ),
                ),
              ),
              Positioned(
                left: AppTokens.space20,
                right: AppTokens.space20,
                bottom: AppTokens.space24,
                child: Semantics(
                  header: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.identity,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineLarge,
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
        ),
      ),
    );
    return enableHero
        ? Hero(tag: profileMediaHeroTag(profile.id), child: media)
        : media;
  }
}

class ProfilePhotoGallery extends StatefulWidget {
  const ProfilePhotoGallery({
    super.key,
    required this.photos,
    required this.imageProviderBuilder,
  });

  final List<ProfilePhoto> photos;
  final ImageProvider<Object>? Function(ProfilePhoto photo)
  imageProviderBuilder;

  @override
  State<ProfilePhotoGallery> createState() => _ProfilePhotoGalleryState();
}

class _ProfilePhotoGalleryState extends State<ProfilePhotoGallery> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didUpdateWidget(covariant ProfilePhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= widget.photos.length) _page = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (constraints.maxWidth * 1.12).clamp(280.0, 520.0);
        return Column(
          children: [
            SizedBox(
              height: height,
              child: PageView.builder(
                key: const Key('public-profile-gallery'),
                controller: _controller,
                itemCount: widget.photos.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final photo = widget.photos[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == widget.photos.length - 1
                          ? 0
                          : AppTokens.space8,
                    ),
                    child: Semantics(
                      image: true,
                      label:
                          'Profile photo ${index + 2} of ${widget.photos.length + 1}',
                      child: RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusLarge,
                          ),
                          child: _BoundedProfileImage(
                            imageProvider: widget.imageProviderBuilder(photo),
                            semanticLabel:
                                'Additional profile photo ${index + 1}',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.photos.length > 1) ...[
              const SizedBox(height: AppTokens.space12),
              Semantics(
                liveRegion: true,
                label: 'Photo ${_page + 1} of ${widget.photos.length}',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.photos.length,
                    (index) => AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : AppTokens.motionTab,
                      width: index == _page ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: index == _page
                            ? AppTokens.textPrimary
                            : AppTokens.textMuted,
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusPill,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.space20),
      decoration: BoxDecoration(
        color: AppTokens.surfaceSolid,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: AppTokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppTokens.iconStandard,
                  color: AppTokens.textSecondary,
                ),
                const SizedBox(width: AppTokens.space8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space12),
          child,
        ],
      ),
    );
  }
}

class ProfileFacts extends StatelessWidget {
  const ProfileFacts({super.key, required this.facts});

  final Map<String, String> facts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < facts.length; index++) ...[
          _FactRow(
            label: facts.keys.elementAt(index),
            value: facts.values.elementAt(index),
          ),
          if (index != facts.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTokens.space12),
              child: Divider(height: 1),
            ),
        ],
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTokens.textSecondary),
          ),
        ),
        const SizedBox(width: AppTokens.space16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTokens.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _BoundedProfileImage extends StatelessWidget {
  const _BoundedProfileImage({
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
    return Image(
      image: provider,
      fit: BoxFit.cover,
      semanticLabel: semanticLabel,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const SkeletonLoader(radius: 0);
      },
      errorBuilder: (context, error, stackTrace) {
        return ProfileMediaPlaceholder(semanticLabel: semanticLabel);
      },
    );
  }
}
