import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/liquid_ui.dart';
import '../../../shared/ui/midnight_components.dart';

class SettingsPageScaffold extends StatelessWidget {
  const SettingsPageScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientScaffold(
        child: Stack(
          children: [
            Positioned.fill(child: child),
            Positioned(
              left: AppTokens.space16,
              right: AppTokens.space16,
              top: AppTokens.space8,
              child: SettingsTopBar(title: title, onBack: onBack),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsTopBar extends StatelessWidget {
  const SettingsTopBar({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AppTopBar(
      key: const Key('settings-top-bar'),
      title: title,
      leading: GlassIconButton(
        icon: Icons.chevron_left_rounded,
        semanticLabel: 'Back',
        tooltip: 'Back',
        onPressed: onBack,
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.footer,
  });

  final String title;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppTokens.space8,
              bottom: AppTokens.space8,
            ),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppTokens.textSecondary),
            ),
          ),
          Material(
            color: AppTokens.surfaceSolid,
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                border: Border.all(color: AppTokens.glassBorder),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index < children.length - 1)
                      const Divider(
                        height: 1,
                        indent: 72,
                        color: AppTokens.glassBorder,
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: AppTokens.space8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8),
              child: footer,
            ),
          ],
        ],
      ),
    );
  }
}

class SettingsTile extends StatefulWidget {
  const SettingsTile({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.statusLabel,
    this.switchValue,
    this.onSwitchChanged,
    this.destructive = false,
    this.enabled = true,
    this.loading = false,
  }) : assert(
         switchValue == null || onTap == null,
         'A switch tile must not also be a navigation tile.',
       );

  final IconData leadingIcon;
  final String title;
  final String? subtitle;
  final FutureOr<void> Function()? onTap;
  final String? statusLabel;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final bool destructive;
  final bool enabled;
  final bool loading;

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  var _handlingTap = false;

  bool get _enabled =>
      widget.enabled &&
      !widget.loading &&
      !_handlingTap &&
      widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final destructive = widget.destructive;
    final enabled = widget.enabled && !widget.loading && !_handlingTap;
    final canToggle =
        widget.switchValue != null && enabled && widget.onSwitchChanged != null;
    final subtitle = widget.subtitle?.trim();
    final semanticsLabel = [
      if (destructive) 'Destructive action',
      widget.title,
      if (subtitle?.isNotEmpty == true) subtitle!,
      if (widget.statusLabel?.trim().isNotEmpty == true)
        widget.statusLabel!.trim(),
      if (widget.loading || _handlingTap) 'Loading',
    ].join(', ');

    return Semantics(
      container: true,
      button: widget.onTap != null,
      toggled: widget.switchValue,
      enabled: enabled,
      label: semanticsLabel,
      onTap: _enabled
          ? _handleTap
          : canToggle
          ? _handleSemanticToggle
          : null,
      excludeSemantics: true,
      child: InkWell(
        onTap: _enabled ? _handleTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 76),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space16,
              vertical: AppTokens.space12,
            ),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: AppTokens.minTouchTarget,
                  child: Center(
                    child: Icon(
                      widget.leadingIcon,
                      color: !enabled
                          ? AppTokens.textMuted
                          : destructive
                          ? AppTokens.error
                          : AppTokens.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.space8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: !enabled
                              ? AppTokens.textMuted
                              : destructive
                              ? AppTokens.error
                              : AppTokens.textPrimary,
                        ),
                      ),
                      if (subtitle?.isNotEmpty == true) ...[
                        const SizedBox(height: AppTokens.space4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: enabled
                                    ? AppTokens.textSecondary
                                    : AppTokens.textMuted,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.space8),
                _SettingsTileTrailing(
                  loading: widget.loading || _handlingTap,
                  enabled: enabled,
                  destructive: destructive,
                  statusLabel: widget.statusLabel,
                  switchValue: widget.switchValue,
                  onSwitchChanged:
                      widget.switchValue != null &&
                          enabled &&
                          widget.onSwitchChanged != null
                      ? widget.onSwitchChanged
                      : null,
                  showChevron: widget.onTap != null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap() async {
    final onTap = widget.onTap;
    if (onTap == null || !_enabled) return;
    setState(() => _handlingTap = true);
    try {
      await Future<void>.sync(onTap);
    } finally {
      if (mounted) setState(() => _handlingTap = false);
    }
  }

  void _handleSemanticToggle() {
    final value = widget.switchValue;
    final onChanged = widget.onSwitchChanged;
    if (value == null || onChanged == null || !widget.enabled) return;
    onChanged(!value);
  }
}

class _SettingsTileTrailing extends StatelessWidget {
  const _SettingsTileTrailing({
    required this.loading,
    required this.enabled,
    required this.destructive,
    required this.statusLabel,
    required this.switchValue,
    required this.onSwitchChanged,
    required this.showChevron,
  });

  final bool loading;
  final bool enabled;
  final bool destructive;
  final String? statusLabel;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox.square(
        dimension: AppTokens.minTouchTarget,
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (switchValue != null) {
      return SizedBox(
        height: AppTokens.minTouchTarget,
        child: Switch(value: switchValue!, onChanged: onSwitchChanged),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 136),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusLabel?.trim().isNotEmpty == true)
            Flexible(
              child: Text(
                statusLabel!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: destructive
                      ? AppTokens.error
                      : enabled
                      ? AppTokens.textSecondary
                      : AppTokens.textMuted,
                ),
              ),
            ),
          if (showChevron) ...[
            if (statusLabel?.trim().isNotEmpty == true)
              const SizedBox(width: AppTokens.space4),
            Icon(
              Icons.chevron_right_rounded,
              color: enabled ? AppTokens.textSecondary : AppTokens.textMuted,
            ),
          ],
        ],
      ),
    );
  }
}

class SettingsInlineMessage extends StatelessWidget {
  const SettingsInlineMessage({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: isError,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: AppTokens.iconCompact,
            color: isError ? AppTokens.error : AppTokens.textSecondary,
          ),
          const SizedBox(width: AppTokens.space8),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class AccountInfoSection extends StatelessWidget {
  const AccountInfoSection({super.key, required this.accountId});

  final int accountId;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Account information',
      children: [
        SettingsTile(
          key: const Key('account-reference'),
          leadingIcon: Icons.badge_outlined,
          title: 'Account reference',
          subtitle: 'Use this reference if you need help with your account.',
          statusLabel: '#$accountId',
        ),
        const SettingsTile(
          key: Key('account-sign-in-method'),
          leadingIcon: Icons.sms_outlined,
          title: 'Sign-in method',
          subtitle: 'Phone verification code',
          statusLabel: 'OTP',
        ),
      ],
    );
  }
}

class LogoutConfirmationSheet extends StatefulWidget {
  const LogoutConfirmationSheet({super.key});

  @override
  State<LogoutConfirmationSheet> createState() =>
      _LogoutConfirmationSheetState();
}

class _LogoutConfirmationSheetState extends State<LogoutConfirmationSheet> {
  var _closing = false;

  @override
  Widget build(BuildContext context) {
    return GlassSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTokens.glassHighlight,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space20),
          Text(
            'Sign out of Swipe?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTokens.space8),
          Text(
            'Your private session data will be removed from this device. '
            'You can sign in again with a verification code.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.space24),
          SecondaryActionButton(
            key: const Key('cancel-settings-logout'),
            label: 'Stay signed in',
            onPressed: _closing ? null : () => _close(false),
          ),
          const SizedBox(height: AppTokens.space8),
          TextButton.icon(
            key: const Key('confirm-settings-logout'),
            onPressed: _closing ? null : () => _close(true),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(
                AppTokens.standardButtonHeight,
              ),
              foregroundColor: AppTokens.error,
            ),
          ),
        ],
      ),
    );
  }

  void _close(bool confirmed) {
    if (_closing) return;
    setState(() => _closing = true);
    Navigator.pop(context, confirmed);
  }
}

class DeleteAccountConfirmation extends StatefulWidget {
  const DeleteAccountConfirmation({super.key});

  @override
  State<DeleteAccountConfirmation> createState() =>
      _DeleteAccountConfirmationState();
}

class _DeleteAccountConfirmationState extends State<DeleteAccountConfirmation> {
  var _closing = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppTokens.space20),
      child: GlassSurface(
        level: GlassLevel.sheet,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppTokens.error,
              size: AppTokens.iconProminent,
            ),
            const SizedBox(height: AppTokens.space12),
            Text(
              'Delete this account?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTokens.space8),
            const Text(
              'This is the final confirmation. Swipe has no restore flow for '
              'a deleted account.',
            ),
            const SizedBox(height: AppTokens.space20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: const Key('cancel-delete-account'),
                    onPressed: _closing ? null : () => _close(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppTokens.space8),
                Expanded(
                  child: FilledButton(
                    key: const Key('confirm-delete-account'),
                    onPressed: _closing ? null : () => _close(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.error,
                      foregroundColor: AppTokens.backgroundBase,
                      minimumSize: const Size.fromHeight(
                        AppTokens.standardButtonHeight,
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _close(bool confirmed) {
    if (_closing) return;
    setState(() => _closing = true);
    Navigator.pop(context, confirmed);
  }
}

class DeleteAccountProgressView extends StatelessWidget {
  const DeleteAccountProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Deleting account. Do not close the application.',
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppTokens.space16),
          Text('Deleting your account…', textAlign: TextAlign.center),
          SizedBox(height: AppTokens.space8),
          Text(
            'Keep Swipe open until the request finishes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}
