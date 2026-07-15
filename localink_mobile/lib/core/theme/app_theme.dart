import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF080706); // Rich Obsidian Black
  static const Color surfaceColor = Color(0xFF141210); // Warm Charcoal Surface
  static const Color inputFieldColor = Color(0xFF1A1816); // Input fields
  static const Color accentColor = Color(0xFFFF6B00); // Vibrant Saffron Orange
  static const Color glowColor = Color(0xFFFF9F00); // Solar Gold Glow
  static const Color tricolorGreen = Color(0xFF2E7D32); // National Green Accent
  static const Color textColor = Color(0xFFFFFFFF); // High-contrast text
  static const Color mutedTextColor = Color(0xFF9F9893); // Warm Muted Gray
  static const Color borderColor = Color(0xFF25211F); // Clean warm borders
  static const Color errorColor = Color(0xFFFF3333); // Sharp error red

  // Sleek gradient for cards and overlays
  static LinearGradient get futuristicGradient => const LinearGradient(
        colors: [
          Color(0xFF1A1816),
          Color(0xFF0F0E0D),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Saffron to Gold solar gradient for primary actions
  static LinearGradient get primarySolarGradient => const LinearGradient(
        colors: [
          accentColor,
          glowColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: glowColor,
        surface: surfaceColor,
        error: errorColor,
        onSurface: textColor,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w800, // Thicker font weight for modern headers
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded edges
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFieldColor,
        labelStyle: const TextStyle(color: mutedTextColor, fontSize: 14),
        hintStyle: const TextStyle(color: mutedTextColor, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
