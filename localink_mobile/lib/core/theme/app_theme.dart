import 'package:flutter/material.dart';

/// Shared saffron design tokens — prefer these over per-screen `_Tok` classes.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.glow,
    required this.background,
    required this.surface,
    required this.border,
    required this.charcoal,
    required this.medText,
    required this.mutedText,
    required this.error,
    required this.success,
  });

  final Color primary;
  final Color glow;
  final Color background;
  final Color surface;
  final Color border;
  final Color charcoal;
  final Color medText;
  final Color mutedText;
  final Color error;
  final Color success;

  static const light = AppPalette(
    primary: Color(0xFFFF6600),
    glow: Color(0xFFFF9E4F),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF9F8F6),
    border: Color(0xFFEAE8E3),
    charcoal: Color(0xFF1A1918),
    medText: Color(0xFF5F5C58),
    mutedText: Color(0xFF9F9B96),
    error: Color(0xFFE1251B),
    success: Color(0xFF1E824C),
  );

  @override
  AppPalette copyWith({
    Color? primary,
    Color? glow,
    Color? background,
    Color? surface,
    Color? border,
    Color? charcoal,
    Color? medText,
    Color? mutedText,
    Color? error,
    Color? success,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      glow: glow ?? this.glow,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      charcoal: charcoal ?? this.charcoal,
      medText: medText ?? this.medText,
      mutedText: mutedText ?? this.mutedText,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      charcoal: Color.lerp(charcoal, other.charcoal, t)!,
      medText: Color.lerp(medText, other.medText, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

class AppTheme {
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFF9F8F6);
  static const Color inputFieldColor = Color(0xFFF9F8F6);
  static const Color accentColor = Color(0xFFFF6600);
  static const Color glowColor = Color(0xFFFF9E4F);
  static const Color textColor = Color(0xFF1A1918);
  static const Color mutedTextColor = Color(0xFF5F5C58);
  static const Color softMutedTextColor = Color(0xFF9F9B96);
  static const Color borderColor = Color(0xFFEAE8E3);
  static const Color errorColor = Color(0xFFE1251B);
  static const Color tricolorGreen = Color(0xFF1E824C);

  // Spacing (4dp grid)
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double spaceXxl = 32;

  // Radii
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusRound = 999;

  static LinearGradient get futuristicGradient => const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF9F8F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get primarySolarGradient => const LinearGradient(
        colors: [accentColor, glowColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static AppPalette paletteOf(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? AppPalette.light;

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
      extensions: const <ThemeExtension<dynamic>>[AppPalette.light],
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0.0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1A1918), size: 22.0),
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1918),
          fontSize: 18.0,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFieldColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: accentColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: errorColor, width: 2.0),
        ),
        labelStyle: const TextStyle(color: mutedTextColor, fontSize: 14.0),
        hintStyle: const TextStyle(color: softMutedTextColor, fontSize: 14.0),
        errorStyle: const TextStyle(color: errorColor, fontSize: 12.0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
          textStyle: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          elevation: 0,
          shadowColor: accentColor.withValues(alpha: 0.35),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundColor,
        elevation: 16.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        titleTextStyle: const TextStyle(
          color: textColor,
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: mutedTextColor,
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
        selectedColor: accentColor.withValues(alpha: 0.12),
        secondarySelectedColor: glowColor.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: borderColor),
        ),
        labelStyle: const TextStyle(color: mutedTextColor, fontSize: 13.0),
        secondaryLabelStyle: const TextStyle(color: accentColor, fontSize: 13.0),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 4.0,
        shape: CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textColor,
        actionTextColor: glowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14.0,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.w800, color: textColor),
        headlineLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700, color: textColor),
        titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700, color: textColor),
        bodyLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: textColor),
        bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400, color: mutedTextColor),
        bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: softMutedTextColor),
        labelLarge: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
