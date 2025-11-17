import 'package:flutter/material.dart';

/// Centralized theme configuration using Material 3.
/// Accent: #00FFC6 (neon cyan)
const Color neonCyan = Color(0xFF00FFC6);

final ColorScheme _lightScheme = ColorScheme.fromSeed(
  seedColor: neonCyan,
  brightness: Brightness.light,
  primary: neonCyan,
  secondary: Colors.grey.shade700,
  surface: Colors.black,
);

final ColorScheme _darkScheme = ColorScheme.fromSeed(
  seedColor: neonCyan,
  brightness: Brightness.dark,
  primary: neonCyan,
  secondary: Colors.grey.shade400,
  surface: Colors.black,
);

TextTheme _textTheme = const TextTheme(
  headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.2),
  titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
  bodyMedium: TextStyle(color: Colors.white70),
);

ThemeData buildLightTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: _lightScheme,
      scaffoldBackgroundColor: Colors.black,
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonCyan,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: neonCyan, width: 1.5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );

ThemeData buildDarkTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: _darkScheme,
      scaffoldBackgroundColor: Colors.black,
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonCyan,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: neonCyan, width: 1.5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
