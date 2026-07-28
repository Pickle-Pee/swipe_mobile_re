import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';
import '../../shared/ui/midnight_components.dart';
import 'application/profile_providers.dart';
import 'domain/profile_models.dart';
import 'presentation/edit_profile_components.dart';
import 'presentation/own_profile_components.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.initialSection});

  final ProfileEditSection? initialSection;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _firstName = TextEditingController();
  final _city = TextEditingController();
  final _about = TextEditingController();
  final _height = TextEditingController();
  final _scrollController = ScrollController();
  final _basicKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _interestsKey = GlobalKey();
  final _attributesKey = GlobalKey();
  final _photosKey = GlobalKey();

  bool _initialized = false;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_begin);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _city.dispose();
    _about.dispose();
    _height.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final edit = ref.watch(profileEditControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    final draft = edit.draft;
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_requestExit());
      },
      child: Scaffold(
        backgroundColor: AppTokens.backgroundBase,
        body: AppGradientScaffold(
          safeArea: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!_initialized)
                const _EditProfileLoading()
              else if (draft == null)
                _EditProfileUnavailable(onRetry: () => unawaited(_begin()))
              else
                FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: ListView(
                    key: const Key('edit-profile-scroll'),
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.space16,
                      104,
                      AppTokens.space16,
                      132,
                    ),
                    children: [
                      if (edit.error != null) ...[
                        _EditErrorBanner(
                          message: profileErrorMessage(edit.error),
                          onDismiss: ref
                              .read(profileEditControllerProvider.notifier)
                              .clearError,
                        ),
                        const SizedBox(height: AppTokens.space16),
                      ],
                      KeyedSubtree(
                        key: _basicKey,
                        child: _basicSection(edit, draft, profileState.profile),
                      ),
                      const SizedBox(height: AppTokens.space16),
                      KeyedSubtree(key: _aboutKey, child: _aboutSection(edit)),
                      const SizedBox(height: AppTokens.space16),
                      KeyedSubtree(
                        key: _interestsKey,
                        child: _interestsSection(edit, draft),
                      ),
                      const SizedBox(height: AppTokens.space16),
                      KeyedSubtree(
                        key: _attributesKey,
                        child: _attributesSection(edit, draft),
                      ),
                      const SizedBox(height: AppTokens.space16),
                      KeyedSubtree(
                        key: _photosKey,
                        child: EditProfileSection(
                          key: const Key('edit-profile-photos'),
                          title: 'Photos',
                          subtitle:
                              'Photo changes are applied immediately after '
                              'the server confirms them.',
                          icon: Icons.photo_library_outlined,
                          child: ProfilePhotoManager(
                            state: profileState,
                            onAdd: () => unawaited(
                              ref
                                  .read(profileControllerProvider.notifier)
                                  .pickAndUploadPhoto(),
                            ),
                            onRetryUpload: () => unawaited(
                              ref
                                  .read(profileControllerProvider.notifier)
                                  .retryPhotoUpload(),
                            ),
                            onDelete: (photo) =>
                                unawaited(_confirmDeletePhoto(photo)),
                            onSetPrimary: (id) =>
                                unawaited(_setPrimaryPhoto(id)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Positioned(
                left: AppTokens.space12,
                right: AppTokens.space12,
                top: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppTokens.space8),
                    child: AppTopBar(
                      key: const Key('edit-profile-top-bar'),
                      title: 'Edit profile',
                      leading: GlassIconButton(
                        key: const Key('edit-profile-back'),
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: 'Back',
                        tooltip: 'Back',
                        onPressed: edit.isSaving
                            ? null
                            : () => unawaited(_requestExit()),
                      ),
                    ),
                  ),
                ),
              ),
              if (_initialized && draft != null)
                Positioned(
                  left: AppTokens.space12,
                  right: AppTokens.space12,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: AppTokens.space8),
                    child: ProfileSaveBar(
                      dirty: edit.isDirty,
                      valid: edit.fieldErrors.isEmpty,
                      saving: edit.isSaving,
                      photoBusy: profileState.isPhotoBusy,
                      onSave: () => unawaited(_saveAndLeave()),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _basicSection(
    ProfileEditState edit,
    ProfileEditDraft draft,
    UserProfile? profile,
  ) {
    final controller = ref.read(profileEditControllerProvider.notifier);
    return EditProfileSection(
      key: const Key('edit-profile-basic'),
      title: 'Basic information',
      subtitle:
          'Name, birth date, gender, and city are required by the current '
          'profile contract.',
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: TextField(
              key: const Key('edit-first-name'),
              controller: _firstName,
              enabled: !edit.isSaving,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.givenName],
              onChanged: controller.updateFirstName,
              decoration: InputDecoration(
                labelText: 'First name',
                errorText: edit.fieldErrors['first_name'],
              ),
            ),
          ),
          if (profile?.lastName.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: AppTokens.space12),
            TextFormField(
              key: const Key('edit-last-name-read-only'),
              initialValue: profile!.lastName,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Last name',
                helperText: 'Read-only in the current server contract',
              ),
            ),
          ],
          const SizedBox(height: AppTokens.space12),
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: _DateOfBirthField(
              value: draft.dateOfBirth,
              errorText: edit.fieldErrors['date_of_birth'],
              onTap: edit.isSaving
                  ? null
                  : () => unawaited(_pickBirthDate(draft.dateOfBirth)),
            ),
          ),
          const SizedBox(height: AppTokens.space12),
          FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: DropdownButtonFormField<String>(
              key: const Key('edit-gender'),
              initialValue: draft.gender.isEmpty ? null : draft.gender,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Gender',
                errorText: edit.fieldErrors['gender'],
              ),
              items: _genderItems(draft.gender),
              onChanged: edit.isSaving
                  ? null
                  : (value) {
                      if (value != null) controller.updateGender(value);
                    },
            ),
          ),
          const SizedBox(height: AppTokens.space12),
          FocusTraversalOrder(
            order: const NumericFocusOrder(4),
            child: TextField(
              key: const Key('edit-city'),
              controller: _city,
              enabled: !edit.isSaving,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.addressCity],
              onChanged: controller.updateCity,
              decoration: InputDecoration(
                labelText: 'City',
                helperText: 'Use the city name stored by the app',
                errorText: edit.fieldErrors['city_name'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutSection(ProfileEditState edit) {
    return EditProfileSection(
      key: const Key('edit-profile-about'),
      title: 'About you',
      subtitle:
          'The server does not declare a character limit. Line breaks are '
          'preserved.',
      icon: Icons.notes_rounded,
      child: FocusTraversalOrder(
        order: const NumericFocusOrder(5),
        child: TextField(
          key: const Key('edit-about'),
          controller: _about,
          enabled: !edit.isSaving,
          minLines: 3,
          maxLines: 7,
          textCapitalization: TextCapitalization.sentences,
          onChanged: ref
              .read(profileEditControllerProvider.notifier)
              .updateAboutMe,
          decoration: InputDecoration(
            labelText: 'Introduction',
            alignLabelWithHint: true,
            errorText: edit.fieldErrors['about_me'],
          ),
        ),
      ),
    );
  }

  Widget _interestsSection(ProfileEditState edit, ProfileEditDraft draft) {
    final catalog = edit.catalog;
    return EditProfileSection(
      key: const Key('edit-profile-interests'),
      title: 'Interests',
      subtitle:
          'Options come from the server catalog. The current contract does '
          'not define a selection limit.',
      icon: Icons.auto_awesome_outlined,
      child: switch (edit.catalogStatus) {
        ProfileEditCatalogStatus.loading when catalog == null => const Center(
          child: CircularProgressIndicator(),
        ),
        ProfileEditCatalogStatus.error when catalog == null => _CatalogError(
          onRetry: _reloadCatalog,
        ),
        _ => InterestSelector(
          interests: catalog?.interests ?? const [],
          selectedIds: draft.interestIds.toSet(),
          onToggle: ref
              .read(profileEditControllerProvider.notifier)
              .toggleInterest,
        ),
      },
    );
  }

  Widget _attributesSection(ProfileEditState edit, ProfileEditDraft draft) {
    final catalog = edit.catalog;
    final controller = ref.read(profileEditControllerProvider.notifier);
    return EditProfileSection(
      key: const Key('edit-profile-attributes'),
      title: 'Profile details',
      subtitle: 'Enum choices come directly from the current server catalog.',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          TextField(
            key: const Key('edit-height'),
            controller: _height,
            enabled: !edit.isSaving,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            onChanged: controller.updateHeight,
            decoration: InputDecoration(
              labelText: 'Height in cm',
              helperText: 'Optional whole number; no server range is declared',
              errorText: edit.fieldErrors['height'],
            ),
          ),
          if (edit.catalogStatus == ProfileEditCatalogStatus.error) ...[
            const SizedBox(height: AppTokens.space12),
            _CatalogError(onRetry: _reloadCatalog),
          ],
          for (final key in _attributeKeys) ...[
            const SizedBox(height: AppTokens.space12),
            _AttributeDropdown(
              attributeKey: key,
              value: draft.attributes.valueFor(key) as String?,
              options: catalog?.optionsFor(key) ?? const [],
              enabled: !edit.isSaving,
              onChanged: (value) => controller.updateAttribute(key, value),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _begin() async {
    if (mounted) setState(() => _initialized = false);
    var profile = ref.read(profileControllerProvider).profile;
    if (profile == null) {
      await ref.read(profileControllerProvider.notifier).load();
      profile = ref.read(profileControllerProvider).profile;
      if (profile == null) {
        if (mounted) setState(() => _initialized = true);
        return;
      }
    }
    final future = ref
        .read(profileEditControllerProvider.notifier)
        .begin(profile);
    final draft = ref.read(profileEditControllerProvider).draft;
    if (draft != null) {
      _firstName.text = draft.firstName;
      _city.text = draft.city;
      _about.text = draft.aboutMe;
      _height.text = draft.heightText;
    }
    if (!mounted) return;
    setState(() => _initialized = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitial());
    unawaited(future);
  }

  void _reloadCatalog() =>
      unawaited(ref.read(profileEditControllerProvider.notifier).loadCatalog());

  Future<void> _pickBirthDate(DateTime? current) async {
    final now = DateTime.now();
    final initial = current == null || current.isAfter(now) ? now : current;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (selected != null) {
      ref
          .read(profileEditControllerProvider.notifier)
          .updateDateOfBirth(selected);
    }
  }

  Future<void> _saveAndLeave() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final profile = await ref
        .read(profileEditControllerProvider.notifier)
        .save();
    if (!mounted || profile == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    _leave();
  }

  Future<void> _requestExit() async {
    final edit = ref.read(profileEditControllerProvider);
    if (edit.isSaving) return;
    if (ref.read(profileControllerProvider).isPhotoBusy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wait for the photo update to finish')),
      );
      return;
    }
    if (!edit.isDirty) {
      _leave();
      return;
    }
    final choice = await showDialog<UnsavedChangesChoice>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UnsavedChangesDialog(
        canSave:
            edit.canSave && !ref.read(profileControllerProvider).isPhotoBusy,
        saving: edit.isSaving,
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case UnsavedChangesChoice.save:
        await _saveAndLeave();
        return;
      case UnsavedChangesChoice.discard:
        ref.read(profileEditControllerProvider.notifier).discard();
        _leave();
        return;
      case UnsavedChangesChoice.keepEditing:
        return;
    }
  }

  Future<void> _confirmDeletePhoto(ProfilePhoto photo) async {
    final photos =
        ref.read(profileControllerProvider).profile?.photos ?? const [];
    final details = photo.isAvatar && photos.length == 1
        ? 'This is your primary and last photo. Your profile will have no photo.'
        : photo.isAvatar
        ? 'This is your primary photo. Another saved photo will become primary.'
        : photos.length == 1
        ? 'This is your last photo. Your profile will have no photo.'
        : 'This photo will be permanently removed from your profile.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('delete-profile-photo-dialog'),
        backgroundColor: AppTokens.surfaceSolid,
        title: const Text('Delete this photo?'),
        content: Text(details),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-delete-profile-photo'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await ref
        .read(profileControllerProvider.notifier)
        .deletePhoto(photo);
    if (mounted && deleted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Photo deleted')));
    }
  }

  Future<void> _setPrimaryPhoto(int id) async {
    final updated = await ref
        .read(profileControllerProvider.notifier)
        .setAvatar(id);
    if (mounted && updated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Primary photo updated')));
    }
  }

  void _leave() {
    if (_canPop || !mounted) return;
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      }
    });
  }

  void _scrollToInitial() {
    final key = switch (widget.initialSection) {
      ProfileEditSection.basic => _basicKey,
      ProfileEditSection.about => _aboutKey,
      ProfileEditSection.interests => _interestsKey,
      ProfileEditSection.attributes => _attributesKey,
      ProfileEditSection.photos => _photosKey,
      null => null,
    };
    final target = key?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppTokens.motionContent,
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }
}

class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({
    required this.value,
    required this.errorText,
    required this.onTap,
  });

  final DateTime? value;
  final String? errorText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final date = value == null
        ? 'Choose a date'
        : '${value!.day.toString().padLeft(2, '0')}.'
              '${value!.month.toString().padLeft(2, '0')}.'
              '${value!.year}';
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Date of birth, $date',
      child: InkWell(
        key: const Key('edit-date-of-birth'),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of birth',
            errorText: errorText,
            suffixIcon: const Icon(Icons.calendar_month_outlined),
          ),
          child: Text(date),
        ),
      ),
    );
  }
}

class _AttributeDropdown extends StatelessWidget {
  const _AttributeDropdown({
    required this.attributeKey,
    required this.value,
    required this.options,
    required this.enabled,
    required this.onChanged,
  });

  final String attributeKey;
  final String? value;
  final List<ProfileAttributeOption> options;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = <String, String>{
      for (final option in options) option.description: option.description,
    };
    final current = value?.trim();
    if (current != null && current.isNotEmpty) {
      values.putIfAbsent(current, () => readableProfileValue(current));
    }
    return DropdownButtonFormField<String>(
      key: ValueKey<String>('edit-attribute-$attributeKey'),
      initialValue: current == null || current.isEmpty ? '' : current,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: profileAttributeLabel(attributeKey),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Not specified')),
        ...values.entries.map(
          (entry) => DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: enabled
          ? (selected) => onChanged(
              selected == null || selected.isEmpty ? null : selected,
            )
          : null,
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.sync_problem_rounded, color: AppTokens.error),
        const SizedBox(width: AppTokens.space8),
        const Expanded(child: Text('Could not load profile choices.')),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _EditErrorBanner extends StatelessWidget {
  const _EditErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('edit-profile-error'),
        padding: const EdgeInsets.all(AppTokens.space12),
        decoration: BoxDecoration(
          color: AppTokens.surfaceSolid,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          border: Border.all(color: AppTokens.error.withValues(alpha: 0.52)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTokens.error),
            const SizedBox(width: AppTokens.space8),
            Expanded(child: Text(message)),
            IconButton(
              tooltip: 'Dismiss error',
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileLoading extends StatelessWidget {
  const _EditProfileLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        104,
        AppTokens.space16,
        120,
      ),
      children: const [
        SkeletonLoader(height: 360),
        SizedBox(height: AppTokens.space16),
        SkeletonLoader(height: 220),
        SizedBox(height: AppTokens.space16),
        SkeletonLoader(height: 260),
      ],
    );
  }
}

class _EditProfileUnavailable extends StatelessWidget {
  const _EditProfileUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space20,
            96,
            AppTokens.space20,
            AppTokens.space20,
          ),
          child: ErrorState(
            key: const Key('edit-profile-unavailable'),
            title: 'Profile unavailable',
            message: 'Load your saved profile before editing it.',
            actionLabel: 'Try again',
            onAction: onRetry,
          ),
        ),
      ),
    );
  }
}

const _genderOptions = {
  'Woman': 'female',
  'Man': 'male',
  'Non-binary': 'non-binary',
};

List<DropdownMenuItem<String>> _genderItems(String current) {
  final values = <String, String>{..._genderOptions};
  if (current.trim().isNotEmpty && !values.containsValue(current)) {
    values[readableProfileValue(current)] = current;
  }
  return values.entries
      .map(
        (entry) => DropdownMenuItem(value: entry.value, child: Text(entry.key)),
      )
      .toList(growable: false);
}

const _attributeKeys = [
  'what_looking_for',
  'appearance',
  'smoking_attitude',
  'alcohol_attitude',
  'children_preference',
  'religion',
];
