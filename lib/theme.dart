import 'package:flutter/material.dart';

/// Sonami dark theme — near-black canvas, indigo accent (Micro1-esque).
class SonamiTheme {
  static const bg = Color(0xFF0A0A0F);
  static const surface = Color(0xFF121218);
  static const card = Color(0xFF17171F);
  static const line = Color(0xFF26262F);
  static const text = Color(0xFFF2F2F5);
  static const muted = Color(0xFF9A9AA5);
  static const faint = Color(0xFF5C5C66);
  static const accent = Color(0xFF7C6CF5);
  static const accentDeep = Color(0xFF5A4BD6);

  static ThemeData get dark {
    final scheme = ColorScheme.dark(
      primary: accent,
      secondary: accent,
      surface: surface,
      error: const Color(0xFFE5484D),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: const TextStyle(color: faint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: text),
        bodySmall: TextStyle(color: muted),
      ),
    );
  }
}
