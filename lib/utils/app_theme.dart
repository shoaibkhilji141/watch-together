import 'package:flutter/material.dart';

class AppColors {
  // Shared
  static const Color goldAccent = Color(0xFFCBA869);

  // Dark Theme Colors (original app colors)
  static const Color darkBg = Color(0xFF0D0F14);
  static const Color darkSurface = Color(0xFF181C25);
  static const Color darkSurfaceAlt = Color(0xFF232835);
  static const Color darkText = Colors.white;
  static const Color darkTextAlt = Colors.white70;
  static const Color darkBorder = Color(0xFF2C3242);

  // Light Theme Colors
  static const Color lightBg = Color(0xFFF8F9FA); // Very light grey/white
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white
  static const Color lightSurfaceAlt =
      Color(0xFFE9ECEF); // Light grey for contrasting cards
  static const Color lightText =
      Color(0xFF1A1D20); // Very dark gray, almost black
  static const Color lightTextAlt = Color(0xFF495057); // Medium dark gray
  static const Color lightBorder = Color(0xFFDEE2E6); // Light gray border
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.goldAccent,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkText),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkText),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.darkText),
        bodyMedium: TextStyle(color: AppColors.darkTextAlt),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.goldAccent,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightText,
      ),
      iconTheme: const IconThemeData(color: AppColors.lightText),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.lightText),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.lightText),
        bodyMedium: TextStyle(color: AppColors.lightTextAlt),
      ),
    );
  }
}
