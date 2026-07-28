import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/network/api_exception.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/midnight_components.dart';
import '../auth/presentation/auth_components.dart';
import '../profile/application/profile_providers.dart';
import '../profile/domain/profile_models.dart';
import 'application/onboarding_providers.dart';
import 'domain/onboarding_models.dart';
import 'presentation/onboarding_components.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _firstNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _aboutController = TextEditingController();
  final _firstNameFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();
  final _aboutFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(onboardingControllerProvider.notifier).start();
      if (mounted) _syncControllers(ref.read(onboardingControllerProvider));
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _cityController.dispose();
    _aboutController.dispose();
    _firstNameFocusNode.dispose();
    _cityFocusNode.dispose();
    _aboutFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OnboardingState>(onboardingControllerProvider, (previous, next) {
      _syncControllers(next);
    });
    final state = ref.watch(onboardingControllerProvider);
    final photoState = ref.watch(profileControllerProvider);
    final stepNumber = OnboardingStep.values.indexOf(state.step) + 1;

    if (state.status == OnboardingStatus.loading ||
        state.status == OnboardingStatus.idle) {
      return AuthScaffold(
        title: 'Preparing your profile',
        subtitle: 'Loading the latest saved details before you continue.',
        stepLabel: 'Profile',
        fillBody: true,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == OnboardingStatus.error ||
        state.draft == null ||
        state.profile == null ||
        state.catalog == null) {
      return AuthScaffold(
        title: 'Profile setup',
        subtitle: 'Your saved profile is safe. Retry when you are ready.',
        stepLabel: 'Profile',
        fillBody: true,
        child: OnboardingErrorView(
          message: _messageFor(state.error),
          onRetry: () =>
              ref.read(onboardingControllerProvider.notifier).retry(),
        ),
      );
    }

    final photoBusy = photoState.isPhotoBusy;
    final busy = state.isBusy || photoBusy;
    return AuthScaffold(
      title: _titleFor(state.step),
      subtitle: _subtitleFor(state.step),
      stepLabel: '$stepNumber of ${OnboardingStep.values.length}',
      fillBody: true,
      onBack: state.step == OnboardingStep.basic || busy
          ? null
          : () => ref.read(onboardingControllerProvider.notifier).goBack(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingProgress(
            step: stepNumber,
            total: OnboardingStep.values.length,
          ),
          const SizedBox(height: AppTokens.space20),
          Expanded(
            child: SingleChildScrollView(
              key: PageStorageKey<String>('onboarding-${state.step.name}'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTokens.space20),
                decoration: BoxDecoration(
                  color: AppTokens.surfaceTranslucent,
                  borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                  border: Border.all(color: AppTokens.glassBorder),
                  boxShadow: AppTokens.surfaceShadow(),
                ),
                child: _content(state, photoState),
              ),
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: AppTokens.space12),
            Semantics(
              liveRegion: true,
              child: Text(
                _messageFor(state.error),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTokens.error),
              ),
            ),
          ],
          const SizedBox(height: AppTokens.space20),
          PrimaryActionButton(
            key: const Key('onboarding-continue'),
            label: _actionLabel(state, photoState),
            icon: state.step == OnboardingStep.review
                ? Icons.favorite_rounded
                : Icons.arrow_forward_rounded,
            loading: state.status == OnboardingStatus.saving,
            onPressed: busy ? null : _continue,
          ),
        ],
      ),
    );
  }

  Widget _content(OnboardingState state, ProfileState photoState) {
    final draft = state.draft!;
    final catalog = state.catalog!;
    final enabled = !state.isBusy;
    switch (state.step) {
      case OnboardingStep.basic:
        return BasicProfileStep(
          firstNameController: _firstNameController,
          cityController: _cityController,
          firstNameFocusNode: _firstNameFocusNode,
          cityFocusNode: _cityFocusNode,
          dateOfBirth: draft.dateOfBirth,
          gender: draft.gender,
          errors: state.fieldErrors,
          enabled: enabled,
          onFirstNameChanged: ref
              .read(onboardingControllerProvider.notifier)
              .updateFirstName,
          onCityChanged: ref
              .read(onboardingControllerProvider.notifier)
              .updateCity,
          onBirthday: _pickBirthday,
          onGenderChanged: ref
              .read(onboardingControllerProvider.notifier)
              .updateGender,
        );
      case OnboardingStep.preferences:
        return PreferencesStep(
          aboutController: _aboutController,
          aboutFocusNode: _aboutFocusNode,
          options: catalog.optionsFor('what_looking_for'),
          selectedGoal: draft.whatLookingFor,
          errors: state.fieldErrors,
          enabled: enabled,
          onAboutChanged: ref
              .read(onboardingControllerProvider.notifier)
              .updateAboutMe,
          onGoalChanged: ref
              .read(onboardingControllerProvider.notifier)
              .updateWhatLookingFor,
        );
      case OnboardingStep.interests:
        return InterestsStep(
          interests: catalog.interests,
          selectedIds: draft.interestIds.toSet(),
          errors: state.fieldErrors,
          enabled: enabled,
          onToggle: ref
              .read(onboardingControllerProvider.notifier)
              .toggleInterest,
        );
      case OnboardingStep.photos:
        return ProfilePhotosStep(
          state: photoState,
          onAdd: _addPhoto,
          onRetryUpload: _retryPhoto,
          onDelete: _deletePhoto,
          onSetPrimary: _setPrimary,
        );
      case OnboardingStep.review:
        return OnboardingReviewStep(profile: state.profile!);
    }
  }

  Future<void> _continue() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = ref.read(onboardingControllerProvider.notifier);
    final wasReview =
        ref.read(onboardingControllerProvider).step == OnboardingStep.review;
    final success = await controller.continueStep();
    if (!mounted || !success) return;
    if (wasReview && !ref.read(onboardingControllerProvider).active) {
      context.go(Routes.discover);
    }
  }

  Future<void> _pickBirthday() async {
    final draft = ref.read(onboardingControllerProvider).draft;
    final now = DateTime.now();
    final lastDate = DateTime(now.year - 18, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: draft?.dateOfBirth ?? DateTime(lastDate.year - 7),
      firstDate: DateTime(1900),
      lastDate: lastDate,
      helpText: 'Choose your date of birth',
    );
    if (selected != null && mounted) {
      ref
          .read(onboardingControllerProvider.notifier)
          .updateDateOfBirth(selected);
    }
  }

  Future<void> _addPhoto() async {
    final success = await ref
        .read(profileControllerProvider.notifier)
        .pickAndUploadPhoto();
    if (success && mounted) _syncLatestProfile();
  }

  Future<void> _retryPhoto() async {
    final success = await ref
        .read(profileControllerProvider.notifier)
        .retryPhotoUpload();
    if (success && mounted) _syncLatestProfile();
  }

  Future<void> _deletePhoto(ProfilePhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this photo?'),
        content: Text(
          photo.isAvatar
              ? 'This is your primary photo. Another saved photo will become primary when possible.'
              : 'The photo will be removed from your saved profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep photo'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await ref
        .read(profileControllerProvider.notifier)
        .deletePhoto(photo);
    if (success && mounted) _syncLatestProfile();
  }

  Future<void> _setPrimary(int photoId) async {
    final success = await ref
        .read(profileControllerProvider.notifier)
        .setAvatar(photoId);
    if (success && mounted) _syncLatestProfile();
  }

  void _syncLatestProfile() {
    final profile = ref.read(profileControllerProvider).profile;
    if (profile != null) {
      ref.read(onboardingControllerProvider.notifier).syncProfile(profile);
    }
  }

  void _syncControllers(OnboardingState state) {
    final draft = state.draft;
    if (draft == null) return;
    _setControllerText(_firstNameController, draft.firstName);
    _setControllerText(_cityController, draft.city);
    _setControllerText(_aboutController, draft.aboutMe);
  }

  void _setControllerText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  String _actionLabel(OnboardingState state, ProfileState photoState) {
    return switch (state.step) {
      OnboardingStep.photos when photoState.profile?.photos.isEmpty ?? true =>
        'Skip for now',
      OnboardingStep.review => 'Open Discovery',
      _ => 'Continue',
    };
  }

  String _titleFor(OnboardingStep step) => switch (step) {
    OnboardingStep.basic => 'Complete your basics',
    OnboardingStep.preferences => 'What brings you here?',
    OnboardingStep.interests => 'Choose your interests',
    OnboardingStep.photos => 'Add your best photos',
    OnboardingStep.review => 'Your profile is ready',
  };

  String _subtitleFor(OnboardingStep step) => switch (step) {
    OnboardingStep.basic =>
      'We found a few required profile details that still need attention.',
    OnboardingStep.preferences =>
      'Choose a real relationship goal from the Swipe catalog. Your introduction is optional.',
    OnboardingStep.interests =>
      'Saved interests help people find a genuine conversation starter.',
    OnboardingStep.photos =>
      'Use the same secure photo manager as your profile. The server currently makes this step optional.',
    OnboardingStep.review =>
      'Review the canonical details saved by the server before entering the app.',
  };

  String _messageFor(Object? error) {
    if (error is NetworkApiException) {
      return 'Check your connection and try again. Your current draft is still here.';
    }
    if (error is ValidationApiException) return error.message;
    if (error is ServerApiException) {
      return 'The service is temporarily unavailable. Please try again.';
    }
    if (error is InvalidProfilePhotoException) return error.message;
    if (error is ApiException) return error.message;
    return 'We could not save this step. Please try again.';
  }
}
