import 'package:flutter/material.dart';

/// Application theme configuration
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // Add dark theme if needed in the future
  // static ThemeData get darkTheme { ... }
}

