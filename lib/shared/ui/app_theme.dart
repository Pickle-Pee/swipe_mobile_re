import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class AppTheme {
  static ThemeData light() {
    const textTheme = TextTheme(
      headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w300, color: AppTokens.textPrimary),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: AppTokens.textPrimary),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, color: AppTokens.textPrimary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppTokens.textPrimary),
      bodyLarge: TextStyle(fontSize: 16, color: AppTokens.textSecondary),
      bodyMedium: TextStyle(fontSize: 14, color: AppTokens.textSecondary),
      bodySmall: TextStyle(fontSize: 12, color: AppTokens.textMuted),
    );

    final colorScheme = const ColorScheme.dark(
      primary: AppTokens.blueSoft,
      secondary: AppTokens.pinkSoft,
      surface: AppTokens.surface,
      onPrimary: Colors.white,
      onSurface: AppTokens.textPrimary,
      error: Color(0xFFFF8FA0),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      dividerColor: AppTokens.border,
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppTokens.textMuted),
        filled: true,
        fillColor: AppTokens.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData dark() => light();
}
