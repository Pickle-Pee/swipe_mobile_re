import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class AppGradientScaffold extends StatelessWidget {
  const AppGradientScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTokens.appBackground),
      child: SafeArea(child: child),
    );
  }
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppTokens.radiusLg,
    this.borderColor = AppTokens.border,
    this.backgroundColor = AppTokens.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppTokens.blurSm, sigmaY: AppTokens.blurSm),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTokens.ctaGradient,
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppTokens.glowShadow(AppTokens.violet),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
      ),
    );
  }
}

class PillTag extends StatelessWidget {
  const PillTag({super.key, required this.label, this.color = AppTokens.blueSoft});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
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
      backgroundColor: AppTokens.pinkSoft.withOpacity(0.09),
      borderColor: AppTokens.pinkSoft.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTokens.pinkSoft, fontSize: 13)),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(color: AppTokens.textSecondary, fontSize: 13)),
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
        Icon(Icons.verified_user_rounded, color: AppTokens.mint, size: 14),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppTokens.mint, fontSize: 11)),
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
    final color = mine ? AppTokens.blueSoft.withOpacity(0.2) : AppTokens.surfaceStrong;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: GlassSurface(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          backgroundColor: color,
          borderColor: mine ? AppTokens.blueSoft.withOpacity(0.45) : AppTokens.border,
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ),
    );
  }
}
