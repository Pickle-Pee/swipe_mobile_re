import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/network/api_exception.dart';
import '../../shared/media/app_network_image.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/discovery_components.dart';
import '../../shared/ui/liquid_ui.dart';
import '../../shared/ui/midnight_components.dart';
import '../chat/application/chat_providers.dart';
import '../discovery/domain/discovery_models.dart';
import '../profile/application/profile_providers.dart';
import '../profile/application/public_profile_providers.dart';
import '../profile/domain/profile_models.dart';
import '../profile/domain/public_profile_seed.dart';

typedef MatchImageProviderBuilder =
    ImageProvider<Object>? Function(String? photoUrl);

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key, required this.userId, this.initialProfile});

  final int userId;
  final DiscoveryProfile? initialProfile;

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  bool _openingChat = false;
  Object? _chatError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initialize);
  }

  @override
  Widget build(BuildContext context) {
    final publicState = ref.watch(
      publicProfileControllerProvider(widget.userId),
    );
    final currentState = ref.watch(profileControllerProvider);
    final chatState = ref.watch(chatListControllerProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _continueDiscovering();
      },
      child: MatchView(
        matchedProfile: publicState.profile,
        currentProfile: currentState.profile,
        profileLoading:
            publicState.status == PublicProfileStatus.initial ||
            publicState.status == PublicProfileStatus.loading,
        profileError: publicState.status == PublicProfileStatus.error
            ? publicState.error
            : null,
        chatError: _chatError,
        openingChat: _openingChat || chatState.isCreating,
        onBack: _continueDiscovering,
        onRetryProfile: _loadMatchedProfile,
        onStartChat: _openChat,
        onContinue: _continueDiscovering,
      ),
    );
  }

  void _initialize() {
    final publicState = ref.read(
      publicProfileControllerProvider(widget.userId),
    );
    if (publicState.status == PublicProfileStatus.initial) {
      _loadMatchedProfile();
    }
    if (ref.read(profileControllerProvider).profile == null) {
      unawaited(ref.read(profileControllerProvider.notifier).load());
    }
  }

  void _loadMatchedProfile() {
    unawaited(
      ref
          .read(publicProfileControllerProvider(widget.userId).notifier)
          .load(seed: publicProfileSeedFromDiscovery(widget.initialProfile)),
    );
  }

  Future<void> _openChat() async {
    if (_openingChat) return;
    setState(() {
      _openingChat = true;
      _chatError = null;
    });
    final chatId = await ref
        .read(chatListControllerProvider.notifier)
        .openOrCreate(widget.userId);
    if (!mounted) return;
    if (chatId == null) {
      setState(() {
        _openingChat = false;
        _chatError =
            ref.read(chatListControllerProvider).error ??
            StateError('Chat is unavailable');
      });
      return;
    }
    context.go('/chat/$chatId');
  }

  void _continueDiscovering() => context.go(Routes.discover);
}

/// Presentation-only Match experience used by widget and golden tests.
class MatchView extends StatefulWidget {
  const MatchView({
    super.key,
    required this.matchedProfile,
    required this.currentProfile,
    required this.profileLoading,
    required this.openingChat,
    required this.onBack,
    required this.onRetryProfile,
    required this.onStartChat,
    required this.onContinue,
    this.profileError,
    this.chatError,
    this.imageProviderBuilder,
  });

  final PublicUserProfile? matchedProfile;
  final UserProfile? currentProfile;
  final bool profileLoading;
  final Object? profileError;
  final bool openingChat;
  final Object? chatError;
  final VoidCallback onBack;
  final VoidCallback onRetryProfile;
  final VoidCallback onStartChat;
  final VoidCallback onContinue;
  final MatchImageProviderBuilder? imageProviderBuilder;

  @override
  State<MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<MatchView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;
  late final Animation<double> _photosAnimation;
  late final Animation<double> _photoScale;
  late final Animation<double> _titleAnimation;
  late final Animation<double> _actionsAnimation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _photosAnimation = CurvedAnimation(
      parent: _reveal,
      curve: const Interval(0, 0.58, curve: Curves.easeOutCubic),
    );
    _photoScale = Tween<double>(begin: 0.94, end: 1).animate(_photosAnimation);
    _titleAnimation = CurvedAnimation(
      parent: _reveal,
      curve: const Interval(0.28, 0.76, curve: Curves.easeOutCubic),
    );
    _actionsAnimation = CurvedAnimation(
      parent: _reveal,
      curve: const Interval(0.58, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
    } else {
      unawaited(_reveal.forward());
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matched = widget.matchedProfile;
    return Scaffold(
      backgroundColor: AppTokens.backgroundBase,
      body: AppGradientScaffold(
        safeArea: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space12,
              AppTokens.space8,
              AppTokens.space12,
              AppTokens.space12,
            ),
            child: Column(
              children: [
                AppTopBar(
                  key: const Key('match-top-bar'),
                  title: 'Mutual match',
                  leading: GlassIconButton(
                    key: const Key('match-back'),
                    icon: Icons.close_rounded,
                    semanticLabel: 'Close match and return to Discovery',
                    tooltip: 'Close',
                    onPressed: widget.onBack,
                  ),
                ),
                const SizedBox(height: AppTokens.space12),
                Expanded(
                  child: matched == null
                      ? _stateContent()
                      : _matchContent(matched),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stateContent() {
    if (widget.profileLoading) {
      return const _MatchLoading(key: Key('match-loading'));
    }
    return Center(
      child: SingleChildScrollView(
        child: ErrorState(
          title: 'Match unavailable',
          message: _matchErrorMessage(widget.profileError),
          actionLabel: 'Try again',
          onAction: widget.onRetryProfile,
        ),
      ),
    );
  }

  Widget _matchContent(PublicUserProfile matched) {
    final imageBuilder = widget.imageProviderBuilder ?? _networkMatchImage;
    final currentPhoto = _currentAvatarUrl(widget.currentProfile);
    final name = matched.displayName.trim();
    final message = name.isEmpty
        ? 'Вы понравились друг другу.'
        : 'У вас взаимная симпатия с $name.';
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          key: const Key('match-scroll'),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space8,
                  vertical: AppTokens.space16,
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    FadeTransition(
                      opacity: _photosAnimation,
                      child: ScaleTransition(
                        scale: _photoScale,
                        child: MatchPhotoPair(
                          currentImage: imageBuilder(currentPhoto),
                          matchedImage: imageBuilder(matched.heroPhotoUrl),
                          currentLabel: _currentDisplayName(
                            widget.currentProfile,
                          ),
                          matchedLabel: name,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.space32),
                    FadeTransition(
                      opacity: _titleAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Это взаимно!',
                            key: const Key('match-title'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                          const SizedBox(height: AppTokens.space12),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppTokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: AppTokens.space32),
                    FadeTransition(
                      opacity: _actionsAnimation,
                      child: MatchActionPanel(
                        openingChat: widget.openingChat,
                        chatError: widget.chatError == null
                            ? null
                            : _matchErrorMessage(widget.chatError),
                        onStartChat: widget.onStartChat,
                        onContinue: widget.onContinue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MatchPhotoPair extends StatelessWidget {
  const MatchPhotoPair({
    super.key,
    required this.currentImage,
    required this.matchedImage,
    required this.currentLabel,
    required this.matchedLabel,
  });

  final ImageProvider<Object>? currentImage;
  final ImageProvider<Object>? matchedImage;
  final String currentLabel;
  final String matchedLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Your photo and ${matchedLabel.isEmpty ? 'match' : matchedLabel}',
      child: RepaintBoundary(
        child: SizedBox(
          width: 276,
          height: 164,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 10,
                child: Transform.rotate(
                  angle: -0.055,
                  child: _MatchPhoto(
                    key: const Key('match-current-photo'),
                    image: currentImage,
                    semanticLabel: currentImage == null
                        ? 'Your profile photo unavailable'
                        : currentLabel.isEmpty
                        ? 'Your profile photo'
                        : 'Profile photo of $currentLabel',
                  ),
                ),
              ),
              Positioned(
                right: 10,
                child: Transform.rotate(
                  angle: 0.055,
                  child: _MatchPhoto(
                    key: const Key('match-matched-photo'),
                    image: matchedImage,
                    semanticLabel: matchedImage == null
                        ? 'Matched profile photo unavailable'
                        : matchedLabel.isEmpty
                        ? 'Matched profile photo'
                        : 'Profile photo of $matchedLabel',
                  ),
                ),
              ),
              const Icon(
                Icons.favorite_rounded,
                size: 34,
                color: AppTokens.brandRose,
                shadows: [Shadow(color: AppTokens.shadow, blurRadius: 14)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchPhoto extends StatelessWidget {
  const _MatchPhoto({
    super.key,
    required this.image,
    required this.semanticLabel,
  });

  final ImageProvider<Object>? image;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedImage = image == null
        ? null
        : ResizeImage.resizeIfNeeded(
            (142 * MediaQuery.devicePixelRatioOf(context)).ceil(),
            null,
            image!,
          );
    return Semantics(
      container: true,
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        width: 142,
        height: 154,
        padding: const EdgeInsets.all(AppTokens.space4),
        decoration: BoxDecoration(
          color: AppTokens.surfaceSolid,
          borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
          border: Border.all(color: AppTokens.glassHighlight),
          boxShadow: AppTokens.surfaceShadow(),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          child: resolvedImage == null
              ? ProfileMediaPlaceholder(semanticLabel: semanticLabel)
              : Image(
                  image: resolvedImage,
                  fit: BoxFit.cover,
                  frameBuilder: (context, child, frame, loaded) {
                    if (loaded || frame != null) return child;
                    return const SkeletonLoader(radius: AppTokens.radiusLarge);
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return ProfileMediaPlaceholder(
                      semanticLabel: semanticLabel,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class MatchActionPanel extends StatelessWidget {
  const MatchActionPanel({
    super.key,
    required this.openingChat,
    required this.onStartChat,
    required this.onContinue,
    this.chatError,
  });

  final bool openingChat;
  final String? chatError;
  final VoidCallback onStartChat;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      key: const Key('match-action-panel'),
      level: GlassLevel.overlay,
      radius: AppTokens.radiusLarge,
      padding: const EdgeInsets.all(AppTokens.space12),
      child: Column(
        children: [
          if (chatError != null) ...[
            Semantics(
              liveRegion: true,
              child: Container(
                key: const Key('match-chat-error'),
                width: double.infinity,
                padding: const EdgeInsets.all(AppTokens.space12),
                decoration: BoxDecoration(
                  color: AppTokens.surfaceSolid,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                  border: Border.all(
                    color: AppTokens.error.withValues(alpha: 0.54),
                  ),
                ),
                child: Text(
                  chatError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTokens.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space8),
          ],
          PrimaryActionButton(
            key: const Key('match-start-chat'),
            label: 'Начать общение',
            icon: Icons.chat_bubble_rounded,
            loading: openingChat,
            onPressed: openingChat ? null : onStartChat,
          ),
          const SizedBox(height: AppTokens.space8),
          SecondaryActionButton(
            key: const Key('match-continue'),
            label: 'Продолжить просмотр',
            onPressed: openingChat ? null : onContinue,
          ),
        ],
      ),
    );
  }
}

class _MatchLoading extends StatelessWidget {
  const _MatchLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonLoader(width: 276, height: 164, radius: 82),
          SizedBox(height: AppTokens.space32),
          SkeletonLoader(width: 220, height: 40),
          SizedBox(height: AppTokens.space12),
          SkeletonLoader(width: 280, height: 24),
        ],
      ),
    );
  }
}

String? _currentAvatarUrl(UserProfile? profile) {
  if (profile == null) return null;
  for (final photo in profile.photos) {
    if (photo.isAvatar && photo.url.trim().isNotEmpty) return photo.url;
  }
  return profile.photos.isEmpty ? null : profile.photos.first.url;
}

String _currentDisplayName(UserProfile? profile) {
  if (profile == null) return '';
  return [
    profile.firstName.trim(),
    profile.lastName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');
}

ImageProvider<Object>? _networkMatchImage(String? value) {
  return appNetworkImage(value);
}

String _matchErrorMessage(Object? error) => error is ApiException
    ? error.message
    : 'Не удалось выполнить действие. Попробуйте ещё раз.';
