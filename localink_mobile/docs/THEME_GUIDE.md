# Theme Guide: Localink Mobile App
Version 2.0.0 • ThemeData Mapping Specifications

This document outlines how to translate the token parameters specified in `DESIGN_SYSTEM.md` into Flutter's global `ThemeData` properties. Enforcing these definitions directly in `AppTheme.dart` makes styling automatic and removes the need for inline overrides.

---

## 1. ThemeData Base Mapping

### A. ColorScheme Mapping (White Base & Saffron Accents)
Flutter's `ColorScheme` is mapped to the token hex values as follows:
```dart
final ColorScheme lightColorScheme = ColorScheme.light(
  primary: const Color(0xFFFF6600),       // color-primary
  secondary: const Color(0xFFFF9E4F),     // color-accent-saffron
  surface: const Color(0xFFF9F8F6),       // color-bg-secondary
  background: const Color(0xFFFFFFFF),    // color-bg-primary
  error: const Color(0xFFE1251B),          // color-error
  onPrimary: const Color(0xFFFFFFFF),
  onSecondary: const Color(0xFF1A1918),
  onSurface: const Color(0xFF1A1918),     // color-text-high
  onBackground: const Color(0xFF1A1918),  // color-text-high
  onError: const Color(0xFFFFFFFF),
);
```

### B. Scaffold & Base Properties
```dart
final ThemeData appThemeData = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: lightColorScheme,
  scaffoldBackgroundColor: const Color(0xFFFFFFFF), // color-bg-primary
  primaryColor: const Color(0xFFFF6600),             // color-primary
  fontFamily: 'Inter',                               // font family
);
```

---

## 2. Global Component Themes Mapping

### A. AppBar Theme
```dart
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
```

### B. Input Field InputDecoration Theme
Standardizes all form text input styles globally:
```dart
inputDecorationTheme: InputDecorationTheme(
  filled: true,
  fillColor: const Color(0xFFF9F8F6), // color-bg-secondary
  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12.0), // radius-md
    borderSide: const BorderSide(color: Color(0xFFEAE8E3)), // color-border-subtle
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12.0),
    borderSide: const BorderSide(color: Color(0xFFEAE8E3)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12.0),
    borderSide: const BorderSide(color: Color(0xFFFF6600), width: 2.0), // border-width-thick
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12.0),
    borderSide: const BorderSide(color: Color(0xFFE1251B)),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12.0),
    borderSide: const BorderSide(color: Color(0xFFE1251B), width: 2.0),
  ),
  labelStyle: const TextStyle(color: Color(0xFF5F5C58), fontSize: 14.0),
  hintStyle: const TextStyle(color: Color(0xFF9F9B96), fontSize: 14.0),
  errorStyle: const TextStyle(color: Color(0xFFE1251B), fontSize: 12.0),
),
```

### C. Dialogs & Bottom Sheets Themes
```dart
dialogTheme: DialogTheme(
  backgroundColor: const Color(0xFFFFFFFF),
  elevation: 16.0, // elevation-high
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)), // radius-lg
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
  elevation: 8.0, // elevation-medium
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)), // radius-lg
  ),
  showDragHandle: true,
),
```

### D. Card & Chip Themes
```dart
cardTheme: CardTheme(
  color: const Color(0xFFF9F8F6), // color-bg-secondary
  elevation: 0.0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16.0), // radius-lg
    side: const BorderSide(color: Color(0xFFEAE8E3)), // color-border-subtle
  ),
),

chipTheme: ChipThemeData(
  backgroundColor: const Color(0xFFF9F8F6),
  disabledColor: const Color(0xFFF0EFEA),
  selectedColor: const Color(0xFFFF6600).withOpacity(0.12),
  secondarySelectedColor: const Color(0xFFFF9E4F).withOpacity(0.12),
  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20.0), // radius-round
    side: const BorderSide(color: Color(0xFFEAE8E3)),
  ),
  labelStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xFF5F5C58), fontSize: 13.0),
  secondaryLabelStyle: const TextStyle(fontFamily: 'Inter', color: Color(0xFFFF6600), fontSize: 13.0),
),
```

### E. Floating Action Button & Snackbar Themes
```dart
floatingActionButtonTheme: const FloatingActionButtonThemeData(
  backgroundColor: Color(0xFFFF6600),
  foregroundColor: Color(0xFFFFFFFF),
  elevation: 4.0,
  shape: CircleBorder(),
),

snackBarTheme: SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  backgroundColor: const Color(0xFF1A1918), // dark neutral fill for floating popups
  actionTextColor: const Color(0xFFFF9E4F),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // radius-md
  contentTextStyle: const TextStyle(
    fontFamily: 'Inter',
    color: Color(0xFFFFFFFF),
    fontSize: 14.0,
  ),
),
```

---

## 3. Typography Scale Configuration

All text styling defaults to these typography tokens:
```dart
textTheme: const TextTheme(
  displayLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.w800, color: Color(0xFF1A1918)),
  headlineLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700, color: Color(0xFF1A1918)),
  titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700, color: Color(0xFF1A1918)),
  bodyLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF1A1918)),
  bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400, color: Color(0xFF5F5C58)),
  bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: Color(0xFF9F9B96)),
  labelLarge: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
),
```

---

## 4. Fonts and Icon Enforcements

To complete the design system setup:
1.  **Configure Inter in `pubspec.yaml`:**
    ```yaml
    flutter:
      fonts:
        - family: Inter
          fonts:
            - asset: assets/fonts/Inter-Regular.ttf
            - asset: assets/fonts/Inter-Medium.ttf
              weight: 500
            - asset: assets/fonts/Inter-SemiBold.ttf
              weight: 600
            - asset: assets/fonts/Inter-Bold.ttf
              weight: 700
            - asset: assets/fonts/Inter-ExtraBold.ttf
              weight: 800
    ```
2.  **Icon Fonts Configuration:**
    The project relies on `'Material Symbols Rounded'` to maintain soft visual boundaries.
    ```yaml
        - family: MaterialSymbolsRounded
          fonts:
            - asset: assets/fonts/MaterialSymbolsRounded.ttf
    ```
    This font must be loaded locally or resolved via the `material_symbols_icons` dependency wrapper. In our widget definitions, all icons are hardcoded to the rounded version variant (e.g., `Icons.Rounded.Search` or `MaterialSymbols.search_rounded`).
