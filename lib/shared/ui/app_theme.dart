import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData midnight() {
    const textTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 36,
        height: 40 / 36,
        fontWeight: FontWeight.w700,
        color: AppTokens.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        height: 32 / 28,
        fontWeight: FontWeight.w700,
        color: AppTokens.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        color: AppTokens.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 22 / 17,
        fontWeight: FontWeight.w600,
        color: AppTokens.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        height: 21 / 15,
        fontWeight: FontWeight.w500,
        color: AppTokens.textSecondary,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        height: 21 / 15,
        fontWeight: FontWeight.w500,
        color: AppTokens.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: AppTokens.textMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        height: 18 / 15,
        fontWeight: FontWeight.w600,
        color: AppTokens.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        color: AppTokens.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: AppTokens.textMuted,
      ),
    );

    const colorScheme = ColorScheme.dark(
      primary: AppTokens.brandRose,
      onPrimary: AppTokens.textPrimary,
      secondary: AppTokens.brandViolet,
      onSecondary: AppTokens.textPrimary,
      surface: AppTokens.surfaceSolid,
      onSurface: AppTokens.textPrimary,
      error: AppTokens.error,
      onError: AppTokens.backgroundBase,
    );

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppTokens.backgroundBase,
      canvasColor: AppTokens.backgroundBase,
      disabledColor: AppTokens.textMuted,
      textTheme: textTheme,
      iconTheme: const IconThemeData(
        color: AppTokens.textSecondary,
        size: AppTokens.iconStandard,
      ),
      primaryIconTheme: const IconThemeData(
        color: AppTokens.textPrimary,
        size: AppTokens.iconStandard,
      ),
      dividerColor: AppTokens.glassBorder,
      splashColor: AppTokens.glassActive,
      highlightColor: AppTokens.glassLow,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTokens.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          height: 28 / 22,
          fontWeight: FontWeight.w600,
          color: AppTokens.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: AppTokens.textPrimary,
          size: AppTokens.iconStandard,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.backgroundElevated,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppTokens.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppTokens.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(
            color: AppTokens.brandViolet,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTouchTarget,
            AppTokens.standardButtonHeight,
          ),
          foregroundColor: AppTokens.textPrimary,
          backgroundColor: AppTokens.surfaceSolid,
          disabledForegroundColor: AppTokens.textMuted,
          disabledBackgroundColor: AppTokens.backgroundElevated,
          elevation: 0,
          textStyle: textTheme.labelLarge,
          shape: roundedShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTouchTarget,
            AppTokens.standardButtonHeight,
          ),
          foregroundColor: AppTokens.textPrimary,
          disabledForegroundColor: AppTokens.textMuted,
          side: const BorderSide(color: AppTokens.glassBorder),
          textStyle: textTheme.labelLarge,
          shape: roundedShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minTouchTarget,
            AppTokens.minTouchTarget,
          ),
          foregroundColor: AppTokens.textPrimary,
          disabledForegroundColor: AppTokens.textMuted,
          textStyle: textTheme.labelLarge,
          shape: roundedShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppTokens.minTouchTarget),
          foregroundColor: AppTokens.textPrimary,
          disabledForegroundColor: AppTokens.textMuted,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppTokens.glassActive,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppTokens.textPrimary
                : AppTokens.textMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppTokens.surfaceSolid,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          side: const BorderSide(color: AppTokens.glassBorder),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppTokens.brandRose,
        linearTrackColor: AppTokens.glassLow,
        circularTrackColor: AppTokens.glassLow,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTokens.surfaceSolid,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppTokens.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          side: const BorderSide(color: AppTokens.glassBorder),
        ),
      ),
    );
  }

  static ThemeData light() => midnight();

  static ThemeData dark() => midnight();
}
