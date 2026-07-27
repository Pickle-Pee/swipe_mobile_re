import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/application/profile_providers.dart';
import '../../profile/domain/profile_models.dart';
import '../../profile/domain/profile_repository.dart';
import '../domain/onboarding_models.dart';

const _unset = Object();

enum OnboardingStatus { idle, loading, ready, saving, error }

class OnboardingState {
  const OnboardingState({
    this.active = false,
    this.status = OnboardingStatus.idle,
    this.step = OnboardingStep.preferences,
    this.profile,
    this.catalog,
    this.draft,
    this.fieldErrors = const {},
    this.error,
  });

  final bool active;
  final OnboardingStatus status;
  final OnboardingStep step;
  final UserProfile? profile;
  final ProfileEditCatalog? catalog;
  final OnboardingDraft? draft;
  final Map<String, String> fieldErrors;
  final Object? error;

  bool get isBusy =>
      status == OnboardingStatus.loading || status == OnboardingStatus.saving;

  OnboardingState copyWith({
    bool? active,
    OnboardingStatus? status,
    OnboardingStep? step,
    Object? profile = _unset,
    Object? catalog = _unset,
    Object? draft = _unset,
    Map<String, String>? fieldErrors,
    Object? error = _unset,
  }) {
    return OnboardingState(
      active: active ?? this.active,
      status: status ?? this.status,
      step: step ?? this.step,
      profile: identical(profile, _unset)
          ? this.profile
          : profile as UserProfile?,
      catalog: identical(catalog, _unset)
          ? this.catalog
          : catalog as ProfileEditCatalog?,
      draft: identical(draft, _unset) ? this.draft : draft as OnboardingDraft?,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      error: identical(error, _unset) ? this.error : error,
    );
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

class OnboardingController extends Notifier<OnboardingState> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);
  Future<void>? _startFuture;

  @override
  OnboardingState build() {
    _startFuture = null;
    return const OnboardingState();
  }

  Future<void> start() {
    final running = _startFuture;
    if (running != null) return running;
    if (state.active &&
        state.status == OnboardingStatus.ready &&
        state.draft != null) {
      return Future.value();
    }

    late final Future<void> tracked;
    tracked = _performStart().whenComplete(() {
      if (identical(_startFuture, tracked)) _startFuture = null;
    });
    _startFuture = tracked;
    return tracked;
  }

  Future<void> retry() {
    state = state.copyWith(
      status: OnboardingStatus.idle,
      catalog: null,
      error: null,
    );
    return start();
  }

  Future<void> _performStart() async {
    state = state.copyWith(
      active: true,
      status: OnboardingStatus.loading,
      fieldErrors: const {},
      error: null,
    );
    try {
      var profile = ref.read(profileControllerProvider).profile;
      profile ??= await _repository.getCurrentProfile();
      ref.read(profileControllerProvider.notifier).adopt(profile);
      final catalog = state.catalog ?? await _repository.getEditCatalog();
      final firstMissing = OnboardingReadiness.fromProfile(
        profile,
      ).firstMissingStep;
      state = state.copyWith(
        active: true,
        status: OnboardingStatus.ready,
        step: firstMissing ?? OnboardingStep.photos,
        profile: profile,
        catalog: catalog,
        draft: OnboardingDraft.fromProfile(profile),
        fieldErrors: const {},
        error: null,
      );
    } on Object catch (error) {
      state = state.copyWith(
        active: true,
        status: OnboardingStatus.error,
        error: error,
      );
    }
  }

  void updateFirstName(String value) =>
      _updateDraft((draft) => draft.copyWith(firstName: value), 'first_name');

  void updateDateOfBirth(DateTime value) => _updateDraft(
    (draft) => draft.copyWith(dateOfBirth: value),
    'date_of_birth',
  );

  void updateGender(String value) =>
      _updateDraft((draft) => draft.copyWith(gender: value), 'gender');

  void updateCity(String value) =>
      _updateDraft((draft) => draft.copyWith(city: value), 'city_name');

  void updateAboutMe(String value) =>
      _updateDraft((draft) => draft.copyWith(aboutMe: value), 'about_me');

  void updateWhatLookingFor(String value) => _updateDraft(
    (draft) => draft.copyWith(whatLookingFor: value),
    'what_looking_for',
  );

  void toggleInterest(int id) {
    final draft = state.draft;
    if (draft == null || state.isBusy) return;
    final selected = [...draft.interestIds];
    selected.contains(id) ? selected.remove(id) : selected.add(id);
    _updateDraft((value) => value.copyWith(interestIds: selected), 'interests');
  }

  Future<bool> continueStep() async {
    if (state.isBusy) return false;
    final draft = state.draft;
    final profile = state.profile;
    if (draft == null || profile == null) return false;

    final errors = _validateStep(state.step, draft);
    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors, error: null);
      return false;
    }

    if (state.step == OnboardingStep.photos) {
      final latest = ref.read(profileControllerProvider).profile ?? profile;
      state = state.copyWith(
        status: OnboardingStatus.ready,
        step: OnboardingStep.review,
        profile: latest,
        draft: OnboardingDraft.fromProfile(latest),
        fieldErrors: const {},
        error: null,
      );
      return true;
    }
    if (state.step == OnboardingStep.review) return finish();

    state = state.copyWith(
      status: OnboardingStatus.saving,
      fieldErrors: const {},
      error: null,
    );
    try {
      final UserProfile canonical;
      switch (state.step) {
        case OnboardingStep.basic:
          canonical = await _repository.updateProfile(
            ProfileUpdate(
              firstName: draft.firstName.trim(),
              dateOfBirth: draft.dateOfBirth,
              gender: draft.gender,
              city: draft.city.trim(),
            ),
          );
        case OnboardingStep.preferences:
          canonical = await _repository.saveProfile(
            ProfileSaveRequest(
              profile: ProfileUpdate(
                aboutMe: draft.aboutMe == profile.aboutMe
                    ? null
                    : draft.aboutMe.trim(),
              ),
              attributeValues: {'what_looking_for': draft.whatLookingFor},
            ),
          );
        case OnboardingStep.interests:
          canonical = await _repository.saveProfile(
            ProfileSaveRequest(
              profile: const ProfileUpdate(),
              interestIds: draft.interestIds,
            ),
          );
        case OnboardingStep.photos:
        case OnboardingStep.review:
          return false;
      }
      ref.read(profileControllerProvider.notifier).adopt(canonical);
      state = state.copyWith(
        status: OnboardingStatus.ready,
        step: _nextStep(state.step),
        profile: canonical,
        draft: OnboardingDraft.fromProfile(canonical),
        fieldErrors: const {},
        error: null,
      );
      return true;
    } on Object catch (error) {
      state = state.copyWith(status: OnboardingStatus.ready, error: error);
      return false;
    }
  }

  Future<bool> finish() async {
    if (state.isBusy) return false;
    state = state.copyWith(
      status: OnboardingStatus.saving,
      fieldErrors: const {},
      error: null,
    );
    try {
      final canonical = await _repository.getCurrentProfile();
      ref.read(profileControllerProvider.notifier).adopt(canonical);
      final readiness = OnboardingReadiness.fromProfile(canonical);
      final missing = readiness.firstMissingStep;
      if (missing != null) {
        state = state.copyWith(
          status: OnboardingStatus.ready,
          step: missing,
          profile: canonical,
          draft: OnboardingDraft.fromProfile(canonical),
          error: const ProfileSaveVerificationException([
            'profile setup is incomplete',
          ]),
        );
        return false;
      }
      state = state.copyWith(
        active: false,
        status: OnboardingStatus.ready,
        profile: canonical,
        draft: OnboardingDraft.fromProfile(canonical),
        error: null,
      );
      return true;
    } on Object catch (error) {
      state = state.copyWith(status: OnboardingStatus.ready, error: error);
      return false;
    }
  }

  void goBack() {
    if (state.isBusy) return;
    final index = OnboardingStep.values.indexOf(state.step);
    if (index <= 0) return;
    state = state.copyWith(
      step: OnboardingStep.values[index - 1],
      fieldErrors: const {},
      error: null,
    );
  }

  void syncProfile(UserProfile profile) {
    if (!state.active) return;
    state = state.copyWith(
      profile: profile,
      draft: OnboardingDraft.fromProfile(profile),
      error: null,
    );
  }

  void deactivate() {
    state = state.copyWith(active: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void _updateDraft(
    OnboardingDraft Function(OnboardingDraft draft) update,
    String field,
  ) {
    final draft = state.draft;
    if (draft == null || state.isBusy) return;
    final errors = {...state.fieldErrors}..remove(field);
    state = state.copyWith(
      draft: update(draft),
      fieldErrors: errors,
      error: null,
    );
  }

  Map<String, String> _validateStep(
    OnboardingStep step,
    OnboardingDraft draft,
  ) {
    final errors = <String, String>{};
    switch (step) {
      case OnboardingStep.basic:
        if (draft.firstName.trim().isEmpty) {
          errors['first_name'] = 'First name is required';
        }
        final date = draft.dateOfBirth;
        if (date == null) {
          errors['date_of_birth'] = 'Date of birth is required';
        } else if (!isAtLeastEighteen(date)) {
          errors['date_of_birth'] = 'You must be at least 18';
        }
        if (draft.gender.trim().isEmpty) {
          errors['gender'] = 'Choose a gender';
        }
        if (draft.city.trim().isEmpty) {
          errors['city_name'] = 'City is required';
        }
      case OnboardingStep.preferences:
        if (draft.whatLookingFor.trim().isEmpty) {
          errors['what_looking_for'] = 'Choose what you are looking for';
        }
      case OnboardingStep.interests:
        if (draft.interestIds.isEmpty) {
          errors['interests'] = 'Choose at least one interest';
        }
      case OnboardingStep.photos:
      case OnboardingStep.review:
        break;
    }
    return errors;
  }

  OnboardingStep _nextStep(OnboardingStep step) {
    final index = OnboardingStep.values.indexOf(step);
    final next = (index + 1).clamp(0, OnboardingStep.values.length - 1) as int;
    return OnboardingStep.values[next];
  }
}
