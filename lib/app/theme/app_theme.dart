import 'package:flutter/material.dart';

abstract final class AppTokens {
  static const primary = Color(0xFF253B80);
  static const accent = Color(0xFF0D9488);
  static const background = Color(0xFFF6F8FC);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const double s1 = 4, s2 = 8, s3 = 12, s4 = 16, s6 = 24, s8 = 32;
  static const double radius = 16;
  static const mobile = 600.0, desktop = 1024.0;
}

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppTokens.primary,
    brightness: brightness,
    primary: dark ? const Color(0xFFB9C8FF) : AppTokens.primary,
    secondary: dark ? const Color(0xFF65D6CA) : AppTokens.accent,
    surface: dark ? const Color(0xFF182235) : Colors.white,
    error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFB91C1C),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF101827) : AppTokens.background,
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: BorderSide(color: dark ? scheme.outlineVariant : AppTokens.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
  );
}
