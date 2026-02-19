import 'package:flutter/material.dart';

class AppTokens {
  const AppTokens._();

  // --- Figma base (theme.css) ---
  static const Color bgTop = Color(0xFF11111C); // ~ (17,17,28)
  static const Color bgMid = Color(0xFF151521); // ~ (21,21,33)
  static const Color bgBottom = Color(0xFF211D2B); // ~ (33,29,43)

  // oklch(0.95 0.0058 264.53) -> sRGB exact ≈ #ECEEF2
  static const Color secondary = Color(
    0xFFECEEF2,
  ); // --secondary (converted from OKLCH)

  static const Color border = Color(0x1A000000); // rgba(0,0,0,0.1) = 0x1A

  // Surfaces (Figma is white-based)
  static const Color surface = Color(0xB3FFFFFF); // ~70% white
  static const Color surfaceStrong = Color(0xD9FFFFFF); // ~85% white

  // Text
  static const Color textPrimary = Color(0xFF030213); // --primary
  static const Color textSecondary = Color(0xFF717182); // --muted-foreground
  static const Color textMuted = Color(0xFF9A9AA6);

  // --- Figma chart palette (theme.css OKLCH -> sRGB exact) ---
  // --chart-1: oklch(0.646 0.222 41.116)  -> #F54900
  // --chart-2: oklch(0.6   0.118 184.704) -> #009689
  // --chart-3: oklch(0.398 0.07  227.392) -> #104E64
  // --chart-4: oklch(0.828 0.189 84.429)  -> #FFB900
  // --chart-5: oklch(0.769 0.188 70.08)   -> #FE9A00
  static const Color chart1 = Color(0xFFF54900);
  static const Color chart2 = Color(0xFF009689);
  static const Color chart3 = Color(0xFF104E64);
  static const Color chart4 = Color(0xFFFFB900);
  static const Color chart5 = Color(0xFFFE9A00);

  // --- Your brand accents (keep for CTA / highlights) ---
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

  // Base background gradient (Figma-like)
  static const LinearGradient appBackground = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [bgTop, bgMid, bgBottom],
  );

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  // CTA can stay vivid
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
      BoxShadow(
        color: color.withOpacity(0.22),
        blurRadius: 28,
        spreadRadius: -2,
      ),
    ];
  }
}
