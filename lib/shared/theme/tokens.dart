import 'package:flutter/material.dart';

class AppTokens {
  // Temporary base palette (Codex later replaces with /redesign/style tokens).
  // Keep it LIGHT and soft.

  static const Color bg = Color(0xFFF7F7FB);
  static const Color surface = Color(0xFFFFFFFF);

  // Brand-ish placeholders (will be replaced by redesign tokens)
  static const Color electricBlue = Color(0xFF4A7DFF);
  static const Color neonMagenta = Color(0xFFD94BFF);
  static const Color softPink = Color(0xFFFF6FB1);

  static const double radiusLg = 24;
  static const double radiusMd = 16;

  static const double blurMd = 14;

  static LinearGradient brandGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricBlue, neonMagenta, softPink],
  );
}
