import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class AppGradientScaffold extends StatelessWidget {
  const AppGradientScaffold({
    super.key,
    required this.child,
    this.safeArea = true,
  });

  final Widget child;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    return AppBackdrop(child: safeArea ? SafeArea(child: child) : child);
  }
}

/// Static, repaint-stable Midnight Aura atmosphere.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppTokens.appBackground),
        ),
        const RepaintBoundary(child: CustomPaint(painter: _AuraPainter())),
        const IgnorePointer(child: _Vignette()),
        child,
      ],
    );
  }
}

class _AuraPainter extends CustomPainter {
  const _AuraPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final longest = size.longestSide;
    _paintAura(
      canvas,
      center: Offset(size.width * 0.12, size.height * 0.18),
      radius: longest * 0.72,
      color: AppTokens.brandViolet.withValues(alpha: 0.16),
    );
    _paintAura(
      canvas,
      center: Offset(size.width * 0.94, size.height * 0.76),
      radius: longest * 0.62,
      color: AppTokens.brandRose.withValues(alpha: 0.12),
    );
  }

  void _paintAura(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(center, radius, [
        color,
        Colors.transparent,
      ]);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AuraPainter oldDelegate) => false;
}

class _Vignette extends StatelessWidget {
  const _Vignette();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, 0.05),
          radius: 1.12,
          colors: [Colors.transparent, Color(0x33000000), Color(0x99000000)],
          stops: [0, 0.68, 1],
        ),
      ),
    );
  }
}

enum GlassLevel { navigation, overlay, sheet }

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.level = GlassLevel.overlay,
    this.padding = const EdgeInsets.all(AppTokens.space16),
    this.radius = AppTokens.radiusLarge,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.applyBlur = true,
  });

  final Widget child;
  final GlassLevel level;
  final EdgeInsetsGeometry padding;
  final double radius;
  final BorderRadiusGeometry? borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool applyBlur;

  @override
  Widget build(BuildContext context) {
    final spec = _GlassSpec.forLevel(level);
    final highContrast = MediaQuery.highContrastOf(context);
    final corners = borderRadius ?? BorderRadius.circular(radius);
    final fill =
        backgroundColor ??
        (highContrast ? AppTokens.glassActive : spec.background);
    final edge =
        borderColor ?? (highContrast ? AppTokens.glassHighlight : spec.border);
    final surface = Material(
      type: MaterialType.transparency,
      child: Ink(
        padding: padding,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: corners,
          border: Border.all(color: edge),
          boxShadow: level == GlassLevel.sheet
              ? AppTokens.surfaceShadow()
              : null,
        ),
        child: child,
      ),
    );

    return ClipRRect(
      borderRadius: corners,
      child: applyBlur
          ? BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: spec.blur, sigmaY: spec.blur),
              child: surface,
            )
          : surface,
    );
  }
}

class _GlassSpec {
  const _GlassSpec({
    required this.background,
    required this.border,
    required this.blur,
  });

  final Color background;
  final Color border;
  final double blur;

  static _GlassSpec forLevel(GlassLevel level) => switch (level) {
    GlassLevel.navigation => const _GlassSpec(
      background: AppTokens.glassMedium,
      border: AppTokens.glassBorder,
      blur: AppTokens.blurNavigation,
    ),
    GlassLevel.overlay => const _GlassSpec(
      background: Color(0x14FFFFFF),
      border: Color(0x1FFFFFFF),
      blur: AppTokens.blurOverlay,
    ),
    GlassLevel.sheet => const _GlassSpec(
      background: Color(0x24FFFFFF),
      border: Color(0x29FFFFFF),
      blur: AppTokens.blurSheet,
    ),
  };
}

/// Compatibility button for screens outside DES-01.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTokens.ctaGradient,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        boxShadow: AppTokens.brandShadow(),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space24,
            vertical: AppTokens.space12,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Compatibility tag for screens outside DES-01.
class PillTag extends StatelessWidget {
  const PillTag({
    super.key,
    required this.label,
    this.color = AppTokens.brandViolet,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space12,
        vertical: AppTokens.space8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class AiInsightCard extends StatelessWidget {
  const AiInsightCard({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      applyBlur: false,
      backgroundColor: AppTokens.surfaceSolid,
      borderColor: AppTokens.glassBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppTokens.brandRose),
          ),
          const SizedBox(height: AppTokens.space4),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class SafetyBadge extends StatelessWidget {
  const SafetyBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.verified_user_rounded,
          color: AppTokens.success,
          size: 14,
        ),
        const SizedBox(width: AppTokens.space8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTokens.success),
        ),
      ],
    );
  }
}

class ChatBubbleGlass extends StatelessWidget {
  const ChatBubbleGlass({super.key, required this.text, required this.mine});

  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: GlassSurface(
          applyBlur: false,
          radius: AppTokens.radiusMedium,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space16,
            vertical: AppTokens.space12,
          ),
          backgroundColor: mine
              ? AppTokens.brandViolet.withValues(alpha: 0.20)
              : AppTokens.surfaceSolid,
          borderColor: mine
              ? AppTokens.brandViolet.withValues(alpha: 0.38)
              : AppTokens.glassBorder,
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTokens.textPrimary),
          ),
        ),
      ),
    );
  }
}
