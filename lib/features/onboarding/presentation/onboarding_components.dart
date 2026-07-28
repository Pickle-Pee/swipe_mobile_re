import 'package:flutter/material.dart';

import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/midnight_components.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/domain/profile_models.dart';
import '../../profile/presentation/edit_profile_components.dart';

class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.step,
    required this.total,
  });

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $step of $total',
      value: 'Step $step of $total',
      child: LinearProgressIndicator(
        value: step / total,
        minHeight: 5,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
    );
  }
}

class BasicProfileStep extends StatelessWidget {
  const BasicProfileStep({
    super.key,
    required this.firstNameController,
    required this.cityController,
    required this.firstNameFocusNode,
    required this.cityFocusNode,
    required this.dateOfBirth,
    required this.gender,
    required this.errors,
    required this.enabled,
    required this.onFirstNameChanged,
    required this.onCityChanged,
    required this.onBirthday,
    required this.onGenderChanged,
  });

  final TextEditingController firstNameController;
  final TextEditingController cityController;
  final FocusNode firstNameFocusNode;
  final FocusNode cityFocusNode;
  final DateTime? dateOfBirth;
  final String gender;
  final Map<String, String> errors;
  final bool enabled;
  final ValueChanged<String> onFirstNameChanged;
  final ValueChanged<String> onCityChanged;
  final VoidCallback onBirthday;
  final ValueChanged<String> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('onboarding-first-name'),
          controller: firstNameController,
          focusNode: firstNameFocusNode,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.givenName],
          onChanged: onFirstNameChanged,
          onSubmitted: (_) => cityFocusNode.requestFocus(),
          decoration: InputDecoration(
            labelText: 'First name',
            errorText: errors['first_name'],
          ),
        ),
        const SizedBox(height: AppTokens.space12),
        TextField(
          key: const Key('onboarding-birthday'),
          readOnly: true,
          enabled: enabled,
          onTap: onBirthday,
          decoration: InputDecoration(
            labelText: 'Date of birth',
            hintText: dateOfBirth == null
                ? 'Choose a date'
                : _dateOnly(dateOfBirth!),
            prefixIcon: const Icon(Icons.cake_outlined),
            errorText: errors['date_of_birth'],
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        Text('Gender', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppTokens.space8),
        Wrap(
          spacing: AppTokens.space8,
          runSpacing: AppTokens.space8,
          children:
              const {
                    'Woman': 'female',
                    'Man': 'male',
                    'Non-binary': 'non-binary',
                  }.entries
                  .map(
                    (entry) => Semantics(
                      selected: gender == entry.value,
                      button: true,
                      child: ChoiceChip(
                        key: ValueKey<String>(
                          'onboarding-gender-${entry.value}',
                        ),
                        label: Text(entry.key),
                        selected: gender == entry.value,
                        onSelected: enabled
                            ? (_) => onGenderChanged(entry.value)
                            : null,
                      ),
                    ),
                  )
                  .toList(growable: false),
        ),
        if (errors['gender'] != null) ...[
          const SizedBox(height: AppTokens.space8),
          _FieldError(errors['gender']!),
        ],
        const SizedBox(height: AppTokens.space16),
        TextField(
          key: const Key('onboarding-city'),
          controller: cityController,
          focusNode: cityFocusNode,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.addressCity],
          onChanged: onCityChanged,
          decoration: InputDecoration(
            labelText: 'City',
            errorText: errors['city_name'],
          ),
        ),
      ],
    );
  }
}

class PreferencesStep extends StatelessWidget {
  const PreferencesStep({
    super.key,
    required this.aboutController,
    required this.aboutFocusNode,
    required this.options,
    required this.selectedGoal,
    required this.errors,
    required this.enabled,
    required this.onAboutChanged,
    required this.onGoalChanged,
  });

  final TextEditingController aboutController;
  final FocusNode aboutFocusNode;
  final List<ProfileAttributeOption> options;
  final String selectedGoal;
  final Map<String, String> errors;
  final bool enabled;
  final ValueChanged<String> onAboutChanged;
  final ValueChanged<String> onGoalChanged;

  @override
  Widget build(BuildContext context) {
    final values = options.map((option) => option.description).toSet();
    final safeValue = values.contains(selectedGoal) ? selectedGoal : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('onboarding-goal'),
          initialValue: safeValue,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'What are you looking for?',
            errorText: errors['what_looking_for'],
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.description,
                  child: Text(
                    readableProfileValue(option.description),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: enabled
              ? (value) {
                  if (value != null) onGoalChanged(value);
                }
              : null,
        ),
        const SizedBox(height: AppTokens.space16),
        TextField(
          key: const Key('onboarding-about'),
          controller: aboutController,
          focusNode: aboutFocusNode,
          enabled: enabled,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
          minLines: 4,
          maxLines: 7,
          onChanged: onAboutChanged,
          decoration: const InputDecoration(
            labelText: 'A short introduction (optional)',
            hintText: 'Share something that can start a real conversation.',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

class InterestsStep extends StatelessWidget {
  const InterestsStep({
    super.key,
    required this.interests,
    required this.selectedIds,
    required this.errors,
    required this.enabled,
    required this.onToggle,
  });

  final List<ProfileInterest> interests;
  final Set<int> selectedIds;
  final Map<String, String> errors;
  final bool enabled;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choose at least one. The list comes from the current Swipe catalog.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppTokens.space16),
        IgnorePointer(
          ignoring: !enabled,
          child: InterestSelector(
            interests: interests,
            selectedIds: selectedIds,
            onToggle: onToggle,
          ),
        ),
        if (errors['interests'] != null) ...[
          const SizedBox(height: AppTokens.space12),
          _FieldError(errors['interests']!),
        ],
      ],
    );
  }
}

class ProfilePhotosStep extends StatelessWidget {
  const ProfilePhotosStep({
    super.key,
    required this.state,
    required this.onAdd,
    required this.onRetryUpload,
    required this.onDelete,
    required this.onSetPrimary,
  });

  final ProfileState state;
  final VoidCallback onAdd;
  final VoidCallback onRetryUpload;
  final ValueChanged<ProfilePhoto> onDelete;
  final ValueChanged<int> onSetPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTokens.space12),
          decoration: BoxDecoration(
            color: AppTokens.brandViolet.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            border: Border.all(color: AppTokens.glassBorder),
          ),
          child: Text(
            'Photos are optional in the current server contract. Add a primary photo now, or continue and add one from your profile later.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        ProfilePhotoManager(
          state: state,
          onAdd: onAdd,
          onRetryUpload: onRetryUpload,
          onDelete: onDelete,
          onSetPrimary: onSetPrimary,
        ),
      ],
    );
  }
}

class OnboardingReviewStep extends StatelessWidget {
  const OnboardingReviewStep({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final goal = profile.attributes.whatLookingFor;
    final rows = {
      'Name': profile.displayName,
      'City': profile.city,
      'Looking for': goal == null ? '' : readableProfileValue(goal),
      'Interests': profile.interests.map((item) => item.label).join(', '),
      'Primary photo': profile.avatarPhoto == null ? 'Not added yet' : 'Ready',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTokens.space16),
          decoration: BoxDecoration(
            color: AppTokens.success.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
            border: Border.all(
              color: AppTokens.success.withValues(alpha: 0.34),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppTokens.success),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: Text(
                  'Your required profile setup is ready. We will verify the canonical server profile once more before opening Discovery.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        ...rows.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 104,
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTokens.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingErrorView extends StatelessWidget {
  const OnboardingErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ErrorState(
        title: 'Could not load profile setup',
        message: message,
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTokens.error),
      ),
    );
  }
}

String _dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
