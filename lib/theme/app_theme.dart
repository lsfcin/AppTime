import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF4F6EF7);
  static const primaryDark = Color(0xFF3A55D4);
  static const surfaceLight = Color(0xFFF7F8FC);
  static const surfaceDark = Color(0xFF1A1D2E);
  static const cardDark = Color(0xFF242740);
  static const success = Color(0xFF34D399);
  static const error = Color(0xFFF87171);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppRadius {
  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(16));
  static const xl = BorderRadius.all(Radius.circular(24));
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      error: AppColors.error,
    ).copyWith(
      primary: AppColors.primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      ),
    );
  }
}
