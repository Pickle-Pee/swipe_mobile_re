import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/liquid_ui.dart';
import '../../../shared/ui/midnight_components.dart';
import '../../profile/domain/profile_models.dart';

class AgeRangeControl extends StatelessWidget {
  const AgeRangeControl({
    super.key,
    required this.minimumController,
    required this.maximumController,
    required this.hasExplicitRange,
    required this.onMinimumChanged,
    required this.onMaximumChanged,
    required this.onUseAutomatic,
    required this.enabled,
    this.errorText,
  });

  final TextEditingController minimumController;
  final TextEditingController maximumController;
  final bool hasExplicitRange;
  final ValueChanged<String> onMinimumChanged;
  final ValueChanged<String> onMaximumChanged;
  final VoidCallback onUseAutomatic;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('age-range-control'),
      padding: const EdgeInsets.all(AppTokens.space20),
      decoration: BoxDecoration(
        color: AppTokens.surfaceSolid,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(
          color: errorText == null
              ? AppTokens.glassBorder
              : AppTokens.error.withValues(alpha: 0.56),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cake_outlined, color: AppTokens.textSecondary),
              const SizedBox(width: AppTokens.space8),
              Expanded(
                child: Text(
                  'Age range',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (hasExplicitRange)
                TextButton(
                  key: const Key('age-range-automatic'),
                  onPressed: enabled ? onUseAutomatic : null,
                  child: const Text('Automatic'),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.space8),
          Text(
            'Enter both ages, or leave both empty to use the backend range '
            'based on your age. The backend defines 18 as the minimum and '
            'does not expose an upper bound.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppTokens.space16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackFields =
                  constraints.maxWidth < 320 ||
                  MediaQuery.textScalerOf(context).scale(16) > 20.8;
              final fields = [
                _AgeField(
                  key: const Key('minimum-age-field'),
                  controller: minimumController,
                  label: 'Minimum age',
                  textInputAction: TextInputAction.next,
                  enabled: enabled,
                  onChanged: onMinimumChanged,
                ),
                _AgeField(
                  key: const Key('maximum-age-field'),
                  controller: maximumController,
                  label: 'Maximum age',
                  textInputAction: TextInputAction.done,
                  enabled: enabled,
                  onChanged: onMaximumChanged,
                ),
              ];
              if (stackFields) {
                return Column(
                  children: [
                    fields.first,
                    const SizedBox(height: AppTokens.space12),
                    fields.last,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: fields.first),
                  const SizedBox(width: AppTokens.space12),
                  Expanded(child: fields.last),
                ],
              );
            },
          ),
          if (errorText != null) ...[
            const SizedBox(height: AppTokens.space8),
            Semantics(
              liveRegion: true,
              child: Text(
                errorText!,
                key: const Key('age-range-error'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTokens.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AgeField extends StatelessWidget {
  const _AgeField({
    super.key,
    required this.controller,
    required this.label,
    required this.textInputAction,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      autofillHints: const [],
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Automatic',
        helperText: '18 or older',
      ),
      onChanged: onChanged,
    );
  }
}

class PreferenceOptionGroup extends StatelessWidget {
  const PreferenceOptionGroup({
    super.key,
    required this.attributeKey,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    required this.enabled,
  });

  final String attributeKey;
  final String title;
  final List<ProfileAttributeOption> options;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selectedIsCurrent =
        selectedValue == null ||
        options.any((option) => option.description == selectedValue);
    final displayedOptions = [
      if (!selectedIsCurrent)
        ProfileAttributeOption(
          name: 'saved_unavailable',
          description: selectedValue!,
        ),
      ...options,
    ];
    return Padding(
      key: ValueKey<String>('preference-group-$attributeKey'),
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppTokens.space4),
          Text(
            'Choose one option or Any.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppTokens.space12),
          Wrap(
            spacing: AppTokens.space8,
            runSpacing: AppTokens.space8,
            children: [
              ChoiceChip(
                key: ValueKey<String>('preference-$attributeKey-any'),
                label: const Text('Any'),
                selected: selectedValue == null,
                onSelected: enabled ? (_) => onSelected(null) : null,
              ),
              for (final option in displayedOptions)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 284),
                  child: ChoiceChip(
                    key: ValueKey<String>(
                      'preference-$attributeKey-${option.name}',
                    ),
                    label: Text(
                      option.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: selectedValue == option.description,
                    onSelected: enabled
                        ? (_) => onSelected(option.description)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class PreferencesSaveBar extends StatelessWidget {
  const PreferencesSaveBar({
    super.key,
    required this.dirty,
    required this.saving,
    required this.canSave,
    required this.onSave,
  });

  final bool dirty;
  final bool saving;
  final bool canSave;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      key: const Key('preferences-save-bar'),
      level: GlassLevel.navigation,
      applyBlur: false,
      radius: AppTokens.radiusLarge,
      padding: const EdgeInsets.all(AppTokens.space12),
      child: PrimaryActionButton(
        key: const Key('save-discovery-preferences'),
        label: saving
            ? 'Saving preferences'
            : dirty
            ? 'Save preferences'
            : 'Preferences saved',
        loading: saving,
        onPressed: canSave ? onSave : null,
      ),
    );
  }
}
