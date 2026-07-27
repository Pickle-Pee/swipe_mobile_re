import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/tokens.dart';
import '../../../shared/ui/liquid_ui.dart';
import '../../../shared/ui/midnight_components.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.stepLabel,
    this.fillBody = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final String? stepLabel;
  final bool fillBody;

  @override
  Widget build(BuildContext context) {
    final topBar = AuthTopBar(
      title: 'Swipe',
      onBack: onBack,
      stepLabel: stepLabel,
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: AppTokens.space8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppTokens.space24),
        Expanded(child: child),
      ],
    );
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppGradientScaffold(
        child: fillBody
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.space16,
                      AppTokens.space12,
                      AppTokens.space16,
                      0,
                    ),
                    child: topBar,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.space20,
                        AppTokens.space32,
                        AppTokens.space20,
                        AppTokens.space24,
                      ),
                      child: content,
                    ),
                  ),
                ],
              )
            : CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.space16,
                      AppTokens.space12,
                      AppTokens.space16,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(child: topBar),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.space20,
                      AppTokens.space32,
                      AppTokens.space20,
                      AppTokens.space24,
                    ),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      child: content,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.stepLabel,
  });

  final String title;
  final VoidCallback? onBack;
  final String? stepLabel;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      level: GlassLevel.overlay,
      radius: AppTokens.radiusPill,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space8,
        vertical: AppTokens.space4,
      ),
      child: Row(
        children: [
          if (onBack != null)
            GlassIconButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Back',
              tooltip: 'Back',
              onPressed: onBack,
            )
          else
            const SizedBox.square(dimension: AppTokens.minTouchTarget),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SizedBox(
            width: 72,
            child: stepLabel == null
                ? const SizedBox.square(dimension: AppTokens.minTouchTarget)
                : Text(
                    stepLabel!,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
          ),
        ],
      ),
    );
  }
}

class AuthFormPanel extends StatelessWidget {
  const AuthFormPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.space20),
      decoration: BoxDecoration(
        color: AppTokens.surfaceTranslucent,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: AppTokens.glassBorder),
        boxShadow: AppTokens.surfaceShadow(),
      ),
      child: child,
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Error: $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTokens.space12),
        decoration: BoxDecoration(
          color: AppTokens.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(color: AppTokens.error.withValues(alpha: 0.42)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: AppTokens.iconCompact,
              color: AppTokens.error,
            ),
            const SizedBox(width: AppTokens.space8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTokens.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpInput extends StatelessWidget {
  const OtpInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
    this.errorText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'Six-digit verification code',
      child: TextField(
        key: const Key('otp-input'),
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        maxLength: 6,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          letterSpacing: 10,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: 'Verification code',
          hintText: '000000',
          counterText: '',
          errorText: errorText,
        ),
      ),
    );
  }
}

class ResendCodeControl extends StatelessWidget {
  const ResendCodeControl({
    super.key,
    required this.secondsRemaining,
    required this.loading,
    required this.onResend,
  });

  final int secondsRemaining;
  final bool loading;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final canResend = secondsRemaining == 0 && !loading && onResend != null;
    final label = secondsRemaining == 0
        ? 'Send code again'
        : 'Send again in $secondsRemaining s';
    return Semantics(
      liveRegion: secondsRemaining == 0,
      button: canResend,
      enabled: canResend,
      label: label,
      child: TextButton(
        key: const Key('resend-code'),
        onPressed: canResend ? onResend : null,
        child: Text(label),
      ),
    );
  }
}
