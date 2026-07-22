import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFFFFFFFF); // Clean White Background
  static const Color surfaceColor = Color(0xFFF9F8F6); // Clean Warm Secondary Surface
  static const Color inputFieldColor = Color(0xFFF9F8F6); // Form field fill
  static const Color accentColor = Color(0xFFFF6600); // Vibrant Saffron Orange
  static const Color glowColor = Color(0xFFFF9E4F); // Soft Saffron Glow
  static const Color textColor = Color(0xFF1A1918); // Charcoal high-contrast text
  static const Color mutedTextColor = Color(0xFF5F5C58); // Muted copy text
  static const Color borderColor = Color(0xFFEAE8E3); // Clean grey borders
  static const Color errorColor = Color(0xFFE1251B); // Sharp validation red
  static const Color tricolorGreen = Color(0xFF1E824C); // Active/approved green

  static LinearGradient get futuristicGradient => const LinearGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF9F8F6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get primarySolarGradient => const LinearGradient(
        colors: [
          accentColor,
          glowColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static ThemeData get lightTheme {
    final lightColorScheme = ColorScheme.light(
      primary: accentColor,
      secondary: glowColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: textColor,
      onSurface: textColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: accentColor,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0.0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1A1918), size: 22.0),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF1A1918),
          fontSize: 18.0,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFieldColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: accentColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: errorColor, width: 2.0),
        ),
        labelStyle: const TextStyle(color: mutedTextColor, fontSize: 14.0),
        hintStyle: const TextStyle(color: Color(0xFF9F9B96), fontSize: 14.0),
        errorStyle: const TextStyle(color: errorColor, fontSize: 12.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)), // radius-xl
          textStyle: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 16.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF1A1918),
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Color(0xFF5F5C58),
          fontSize: 14.0,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 8.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        showDragHandle: true,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        disabledColor: const Color(0xFFF0EFEA),
        selectedColor: accentColor.withOpacity(0.12),
        secondarySelectedColor: glowColor.withOpacity(0.12),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: borderColor),
        ),
        labelStyle: const TextStyle(fontFamily: 'Inter', color: mutedTextColor, fontSize: 13.0),
        secondaryLabelStyle: const TextStyle(fontFamily: 'Inter', color: accentColor, fontSize: 13.0),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 4.0,
        shape: CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1918),
        actionTextColor: glowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 14.0,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.w800, color: Color(0xFF1A1918)),
        headlineLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700, color: Color(0xFF1A1918)),
        titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700, color: Color(0xFF1A1918)),
        bodyLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF1A1918)),
        bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400, color: Color(0xFF5F5C58)),
        bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: Color(0xFF9F9B96)),
        labelLarge: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}