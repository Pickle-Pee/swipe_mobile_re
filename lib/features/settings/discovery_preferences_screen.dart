import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/midnight_components.dart';
import '../discovery/application/discovery_providers.dart';
import '../discovery/domain/discovery_preferences.dart';
import '../profile/domain/profile_models.dart';
import 'application/discovery_preferences_providers.dart';
import 'presentation/discovery_preferences_components.dart';
import 'presentation/settings_components.dart';

enum _UnsavedPreferencesChoice { discard, keepEditing }

class DiscoveryPreferencesScreen extends ConsumerStatefulWidget {
  const DiscoveryPreferencesScreen({super.key});

  @override
  ConsumerState<DiscoveryPreferencesScreen> createState() =>
      _DiscoveryPreferencesScreenState();
}

class _DiscoveryPreferencesScreenState
    extends ConsumerState<DiscoveryPreferencesScreen> {
  final _minimumAge = TextEditingController();
  final _maximumAge = TextEditingController();
  var _canPop = false;
  DiscoveryPreferences? _syncedPreferences;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _minimumAge.dispose();
    _maximumAge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryPreferencesControllerProvider);
    _scheduleControllerSync(state);
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_requestExit());
      },
      child: SettingsPageScaffold(
        title: 'Discovery preferences',
        onBack: () => unawaited(_requestExit()),
        child: Stack(
          children: [
            Positioned.fill(child: _body(state)),
            if (state.loadStatus == PreferencesLoadStatus.ready)
              Positioned(
                left: AppTokens.space16,
                right: AppTokens.space16,
                bottom: AppTokens.space8,
                child: SafeArea(
                  top: false,
                  child: PreferencesSaveBar(
                    dirty: state.isDirty,
                    saving: state.isSaving,
                    canSave: state.canSave,
                    onSave: () => unawaited(_save()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(DiscoveryPreferencesState state) {
    if (state.loadStatus == PreferencesLoadStatus.initial ||
        state.loadStatus == PreferencesLoadStatus.loading) {
      return ListView(
        key: const Key('discovery-preferences-loading'),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space20,
          104,
          AppTokens.space20,
          AppTokens.space40,
        ),
        children: const [
          SkeletonLoader(height: 220),
          SizedBox(height: AppTokens.space16),
          SkeletonLoader(height: 320),
        ],
      );
    }
    if (state.loadStatus == PreferencesLoadStatus.error) {
      return ListView(
        key: const Key('discovery-preferences-error'),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space20,
          112,
          AppTokens.space20,
          AppTokens.space40,
        ),
        children: [
          ErrorState(
            title: 'Preferences unavailable',
            message:
                'Swipe could not load the saved preferences for this '
                'account. Discovery has not been changed.',
            actionLabel: 'Retry',
            onAction: () => unawaited(_retryStoredPreferences()),
          ),
        ],
      );
    }

    return ListView(
      key: const Key('discovery-preferences-list'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space20,
        104,
        AppTokens.space20,
        132,
      ),
      children: [
        const SettingsInlineMessage(
          message:
              'Saved choices are applied as real filters on the next '
              'Discovery request.',
        ),
        const SizedBox(height: AppTokens.space16),
        AgeRangeControl(
          minimumController: _minimumAge,
          maximumController: _maximumAge,
          hasExplicitRange:
              state.draft.minAge.trim().isNotEmpty ||
              state.draft.maxAge.trim().isNotEmpty,
          onMinimumChanged: ref
              .read(discoveryPreferencesControllerProvider.notifier)
              .updateMinimumAge,
          onMaximumChanged: ref
              .read(discoveryPreferencesControllerProvider.notifier)
              .updateMaximumAge,
          onUseAutomatic: _useAutomaticAge,
          enabled: !state.isSaving,
          errorText: state.validationMessage,
        ),
        const SizedBox(height: AppTokens.space24),
        _catalogContent(state),
        if (state.saveError != null) ...[
          const SizedBox(height: AppTokens.space16),
          const SettingsInlineMessage(
            key: Key('preferences-save-error'),
            message:
                'Preferences were not saved. Your complete draft is still '
                'available so you can retry.',
            isError: true,
          ),
        ],
      ],
    );
  }

  Widget _catalogContent(DiscoveryPreferencesState state) {
    switch (state.catalogStatus) {
      case PreferencesCatalogStatus.initial:
      case PreferencesCatalogStatus.loading:
        return const Column(
          key: Key('preferences-catalog-loading'),
          children: [
            SkeletonLoader(height: 160),
            SizedBox(height: AppTokens.space8),
            SkeletonLoader(height: 160),
          ],
        );
      case PreferencesCatalogStatus.error:
        return SettingsSection(
          key: const Key('preferences-catalog-error'),
          title: 'Profile preferences',
          footer: TextButton(
            onPressed: () => unawaited(
              ref
                  .read(discoveryPreferencesControllerProvider.notifier)
                  .ensureCatalogLoaded(),
            ),
            child: const Text('Retry preference choices'),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(AppTokens.space16),
              child: SettingsInlineMessage(
                message:
                    'Profile preference choices could not be loaded. '
                    'You can still save age-only changes.',
                isError: true,
              ),
            ),
          ],
        );
      case PreferencesCatalogStatus.ready:
        final groups = <Widget>[];
        for (final key in DiscoveryPreferences.attributeKeys) {
          final options = state.catalog.optionsFor(key);
          if (options.isEmpty) continue;
          groups.add(
            PreferenceOptionGroup(
              attributeKey: key,
              title: profileAttributeLabel(key),
              options: options,
              selectedValue: state.draft.filters.valueFor(key),
              enabled: !state.isSaving,
              onSelected: (value) => ref
                  .read(discoveryPreferencesControllerProvider.notifier)
                  .updateAttribute(key, value),
            ),
          );
        }
        if (groups.isEmpty) {
          return const SettingsInlineMessage(
            message:
                'The backend returned no supported profile preference '
                'choices.',
          );
        }
        return SettingsSection(
          key: const Key('preferences-option-groups'),
          title: 'Profile preferences',
          footer: const Text(
            'Any omits that query parameter. Selected labels are the canonical '
            'values from the backend catalog.',
          ),
          children: groups,
        );
    }
  }

  Future<void> _load() async {
    await ref
        .read(discoveryPreferencesControllerProvider.notifier)
        .ensureLoaded();
    if (!mounted) return;
    _syncControllers(ref.read(discoveryPreferencesControllerProvider).saved);
  }

  Future<void> _retryStoredPreferences() async {
    await ref
        .read(discoveryPreferencesControllerProvider.notifier)
        .retryStoredPreferences();
    if (!mounted) return;
    final state = ref.read(discoveryPreferencesControllerProvider);
    if (state.loadStatus == PreferencesLoadStatus.ready) {
      _syncControllers(state.saved);
    }
  }

  void _useAutomaticAge() {
    _minimumAge.clear();
    _maximumAge.clear();
    final controller = ref.read(
      discoveryPreferencesControllerProvider.notifier,
    );
    controller.updateMinimumAge('');
    controller.updateMaximumAge('');
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await ref
        .read(discoveryPreferencesControllerProvider.notifier)
        .save();
    if (!saved || !mounted) return;
    await ref.read(discoveryControllerProvider.notifier).load(refresh: true);
    if (!mounted) return;
    final discovery = ref.read(discoveryControllerProvider);
    final message = discovery.status == DiscoveryStatus.error
        ? 'Preferences saved, but Discovery could not refresh. Retry there '
              'when your connection returns.'
        : 'Preferences saved and Discovery refreshed.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestExit() async {
    final state = ref.read(discoveryPreferencesControllerProvider);
    if (state.isSaving) return;
    if (!state.isDirty) {
      _leave();
      return;
    }
    final choice = await showDialog<_UnsavedPreferencesChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        key: const Key('unsaved-preferences-dialog'),
        backgroundColor: AppTokens.surfaceSolid,
        title: const Text('Discard preference changes?'),
        content: const Text('Your unsaved draft has not changed Discovery.'),
        actions: [
          TextButton(
            key: const Key('keep-editing-preferences'),
            onPressed: () =>
                Navigator.pop(context, _UnsavedPreferencesChoice.keepEditing),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            key: const Key('discard-preference-changes'),
            onPressed: () =>
                Navigator.pop(context, _UnsavedPreferencesChoice.discard),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (!mounted || choice != _UnsavedPreferencesChoice.discard) return;
    ref.read(discoveryPreferencesControllerProvider.notifier).discardDraft();
    _leave();
  }

  void _scheduleControllerSync(DiscoveryPreferencesState state) {
    if (state.loadStatus != PreferencesLoadStatus.ready ||
        state.isDirty ||
        _syncedPreferences == state.saved) {
      return;
    }
    _syncedPreferences = state.saved;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncControllers(state.saved);
    });
  }

  void _syncControllers(DiscoveryPreferences preferences) {
    _syncedPreferences = preferences;
    _minimumAge.text = preferences.minAge?.toString() ?? '';
    _maximumAge.text = preferences.maxAge?.toString() ?? '';
  }

  void _leave() {
    if (_canPop || !mounted) return;
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(Routes.settings);
      }
    });
  }
}
