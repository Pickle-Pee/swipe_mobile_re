import 'package:flutter/material.dart';

class AppTokens {
  const AppTokens._();

  static const Color bgTop = Color(0xFF151329);
  static const Color bgBottom = Color(0xFF0A0A14);
  static const Color surface = Color(0x1AFFFFFF);
  static const Color surfaceStrong = Color(0x26FFFFFF);
  static const Color border = Color(0x24FFFFFF);

  static const Color textPrimary = Color(0xFFF4F3FF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textMuted = Color(0x80FFFFFF);

  static const Color pinkSoft = Color(0xFFFFB3D9);
  static const Color pink = Color(0xFFFF8CCB);
  static const Color violet = Color(0xFFC9A5FF);
  static const Color blueSoft = Color(0xFF7DB9E8);
  static const Color cyan = Color(0xFFA2D5F2);
  static const Color mint = Color(0xFFA2E8CB);

  static const double radiusXs = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 28;

  static const double blurSm = 10;
  static const double blurMd = 16;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  static const LinearGradient appBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [pink, violet, blueSoft],
  );

  static const LinearGradient coolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blueSoft, cyan],
  );

  static List<BoxShadow> glowShadow([Color color = pinkSoft]) {
    return [
      BoxShadow(color: color.withOpacity(0.3), blurRadius: 28, spreadRadius: -2),
    ];
  }
}
