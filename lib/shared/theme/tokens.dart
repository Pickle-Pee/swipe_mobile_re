import 'package:flutter/material.dart';

/// Semantic values for the Midnight Aura Glass visual language.
///
/// Legacy aliases remain at the bottom of the class while screens outside the
/// DES-01 scope are migrated incrementally.
class AppTokens {
  const AppTokens._();

  // Semantic palette.
  static const Color backgroundBase = Color(0xFF090A0F);
  static const Color backgroundElevated = Color(0xFF11131B);
  static const Color surfaceSolid = Color(0xFF171923);
  static const Color surfaceTranslucent = Color(0xE6171923);

  static const Color glassLow = Color(0x0FFFFFFF);
  static const Color glassMedium = Color(0x1AFFFFFF);
  static const Color glassActive = Color(0x29FFFFFF);
  static const Color glassBorder = Color(0x24FFFFFF);
  static const Color glassHighlight = Color(0x42FFFFFF);

  static const Color textPrimary = Color(0xFFF7F7FA);
  static const Color textSecondary = Color(0xADF7F7FA);
  static const Color textMuted = Color(0x70F7F7FA);

  static const Color brandRose = Color(0xFFFF4F7B);
  static const Color brandViolet = Color(0xFF8B6CFF);
  static const Color success = Color(0xFF62D7A8);
  static const Color warning = Color(0xFFFFBF69);
  static const Color error = Color(0xFFFF6B7A);

  static const Color shadow = Color(0xB3000000);
  static const Color scrim = Color(0xCC000000);

  // Spacing.
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;

  // Geometry.
  static const double radiusSmall = 12;
  static const double radiusMedium = 18;
  static const double radiusLarge = 26;
  static const double radiusXLarge = 32;
  static const double radiusPill = 999;

  static const double minTouchTarget = 48;
  static const double standardButtonHeight = 56;
  static const double iconCompact = 18;
  static const double iconStandard = 22;
  static const double iconNavigation = 24;
  static const double iconProminent = 28;

  // Glass metrics.
  static const double blurNavigation = 18;
  static const double blurOverlay = 12;
  static const double blurSheet = 24;

  // Motion.
  static const Duration motionPress = Duration(milliseconds: 140);
  static const Duration motionTab = Duration(milliseconds: 200);
  static const Duration motionContent = Duration(milliseconds: 220);
  static const Duration motionCard = Duration(milliseconds: 300);

  // Layout.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: space20,
    vertical: space16,
  );
  static const EdgeInsets compactScreenPadding = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space12,
  );
  static const double floatingNavigationClearance = 104;

  // Brand and atmosphere gradients.
  static const LinearGradient appBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundElevated, backgroundBase],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [brandRose, Color(0xFFA45CFF)],
  );

  static const LinearGradient missingMediaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF211724), Color(0xFF151423), backgroundElevated],
  );

  static List<BoxShadow> surfaceShadow() => const [
    BoxShadow(
      color: Color(0x80000000),
      blurRadius: 28,
      spreadRadius: -12,
      offset: Offset(0, 14),
    ),
  ];

  static List<BoxShadow> brandShadow() => const [
    BoxShadow(
      color: Color(0x40FF4F7B),
      blurRadius: 22,
      spreadRadius: -8,
      offset: Offset(0, 10),
    ),
  ];

  // Compatibility aliases for screens outside DES-01.
  static const Color bgTop = backgroundElevated;
  static const Color bgMid = backgroundBase;
  static const Color bgBottom = backgroundBase;
  static const Color secondary = textPrimary;
  static const Color border = glassBorder;
  static const Color surface = glassMedium;
  static const Color surfaceStrong = surfaceTranslucent;
  static const Color pinkSoft = brandRose;
  static const Color pink = brandRose;
  static const Color violet = brandViolet;
  static const Color blueSoft = brandViolet;
  static const Color cyan = textSecondary;
  static const Color mint = success;
  static const double radiusXs = radiusSmall;
  static const double radiusMd = radiusMedium;
  static const double radiusLg = radiusLarge;
  static const double blurSm = blurOverlay;
  static const double blurMd = blurNavigation;
  static const LinearGradient coolGradient = missingMediaGradient;

  static List<BoxShadow> glowShadow([Color color = brandRose]) => [
    BoxShadow(
      color: color.withValues(alpha: 0.20),
      blurRadius: 22,
      spreadRadius: -8,
      offset: const Offset(0, 10),
    ),
  ];
}
