import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'liquid_ui.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: GlassSurface(
        level: GlassLevel.overlay,
        radius: AppTokens.radiusPill,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space8,
          vertical: AppTokens.space4,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppTokens.space4),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space12,
                ),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      AppTokens.space20,
      AppTokens.space12,
      AppTokens.space20,
      AppTokens.space24,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      level: GlassLevel.sheet,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppTokens.radiusXLarge),
      ),
      padding: padding,
      child: SafeArea(top: false, child: child),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.selected = false,
    this.tooltip,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool selected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      enabled: onPressed != null,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        selected: selected,
        label: semanticLabel,
        onTap: onPressed,
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: AppTokens.minTouchTarget,
          child: IconButton(
            onPressed: onPressed,
            tooltip: tooltip,
            style: IconButton.styleFrom(
              backgroundColor: selected
                  ? AppTokens.glassActive
                  : AppTokens.glassLow,
              foregroundColor: selected
                  ? AppTokens.textPrimary
                  : AppTokens.textSecondary,
            ),
            icon: Icon(icon, size: AppTokens.iconStandard),
          ),
        ),
      ),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final button = _PressScale(
      enabled: enabled,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: loading ? '$label in progress' : label,
        onTap: enabled ? onPressed : null,
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppTokens.standardButtonHeight,
            minWidth: AppTokens.minTouchTarget,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: enabled ? AppTokens.ctaGradient : null,
              color: enabled ? null : AppTokens.backgroundElevated,
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              boxShadow: enabled ? AppTokens.brandShadow() : null,
            ),
            child: ElevatedButton(
              onPressed: enabled ? onPressed : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(
                  AppTokens.minTouchTarget,
                  AppTokens.standardButtonHeight,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space20,
                ),
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: const StadiumBorder(),
              ),
              child: _ActionContent(label: label, icon: icon, loading: loading),
            ),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class SecondaryActionButton extends StatelessWidget {
  const SecondaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final highContrast = MediaQuery.highContrastOf(context);
    final button = _PressScale(
      enabled: enabled,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: loading ? '$label in progress' : label,
        onTap: enabled ? onPressed : null,
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppTokens.standardButtonHeight,
            minWidth: AppTokens.minTouchTarget,
          ),
          child: OutlinedButton(
            onPressed: enabled ? onPressed : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(
                AppTokens.minTouchTarget,
                AppTokens.standardButtonHeight,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space20,
              ),
              backgroundColor: enabled
                  ? AppTokens.surfaceTranslucent
                  : AppTokens.backgroundElevated,
              side: BorderSide(
                color: highContrast
                    ? AppTokens.glassHighlight
                    : AppTokens.glassBorder,
              ),
              shape: const StadiumBorder(),
            ),
            child: _ActionContent(label: label, icon: icon, loading: loading),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _ActionContent extends StatelessWidget {
  const _ActionContent({
    required this.label,
    required this.icon,
    required this.loading,
  });

  final String label;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppTokens.space8),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppTokens.iconStandard),
          const SizedBox(width: AppTokens.space8),
        ],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class InterestChip extends StatelessWidget {
  const InterestChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 152),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space12,
        vertical: AppTokens.space8,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surfaceTranslucent,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: AppTokens.glassBorder),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppTokens.textPrimary),
      ),
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.label = 'Verified'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: const Icon(
        Icons.verified_rounded,
        size: AppTokens.iconStandard,
        color: AppTokens.success,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.nightlight_round,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _StateSurface(
      icon: icon,
      iconColor: AppTokens.brandViolet,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return _StateSurface(
      icon: Icons.wifi_off_rounded,
      iconColor: AppTokens.error,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class _StateSurface extends StatelessWidget {
  const _StateSurface({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(AppTokens.space24),
      decoration: BoxDecoration(
        color: AppTokens.surfaceSolid,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(color: AppTokens.glassBorder),
        boxShadow: AppTokens.surfaceShadow(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: iconColor),
          const SizedBox(height: AppTokens.space16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTokens.space8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.space20),
          SecondaryActionButton(
            label: actionLabel,
            onPressed: onAction,
            expanded: false,
          ),
        ],
      ),
    );
  }
}

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.radius = AppTokens.radiusMedium,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTokens.backgroundElevated,
              AppTokens.surfaceSolid,
              AppTokens.backgroundElevated,
            ],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppTokens.glassLow),
        ),
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, required this.enabled});

  final Widget child;
  final bool enabled;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
      onPointerUp: widget.enabled ? (_) => _setPressed(false) : null,
      onPointerCancel: widget.enabled ? (_) => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: reduceMotion ? Duration.zero : AppTokens.motionPress,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }
}
