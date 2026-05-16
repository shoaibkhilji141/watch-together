import 'package:flutter/material.dart';

class AppPalette {
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color gold;
  final Color goldLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color error;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.gold,
    required this.goldLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    this.error = const Color(0xFFE57373),
  });

  factory AppPalette.of(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return const AppPalette(
        bg: Color(0xFFF8F9FA),
        surface: Color(0xFFFFFFFF),
        surfaceAlt: Color(0xFFE9ECEF),
        gold: Color(0xFFCBA869),
        goldLight: Color(0xFFE8C98A),
        textPrimary: Color(0xFF1A1D20),
        textSecondary: Color(0xFF495057),
        border: Color(0xFFDEE2E6),
        error: Color(0xFFD32F2F),
      );
    }
    return const AppPalette(
      bg: Color(0xFF0D0F14),
      surface: Color(0xFF161A23),
      surfaceAlt: Color(0xFF1C2130),
      gold: Color(0xFFCBA869),
      goldLight: Color(0xFFE8C98A),
      textPrimary: Color(0xFFF0EDE6),
      textSecondary: Color(0xFF8A8FA0),
      border: Color(0xFF2A2F3E),
    );
  }
}
