# Component Inventory: Localink Mobile App

## 1. Core Visual Tokens

### A. Theme Colors
The colors defined in `lib/core/theme/app_theme.dart` are:
*   `backgroundColor`: `Color(0xFF080706)` (Obsidian Black)
*   `surfaceColor`: `Color(0xFF141210)` (Charcoal Surface)
*   `inputFieldColor`: `Color(0xFF1A1816)` (Input fields)
*   `accentColor`: `Color(0xFFFF6B00)` (Saffron Orange)
*   `glowColor`: `Color(0xFFFF9F00)` (Solar Gold)
*   `textColor`: `Color(0xFFFFFFFF)`
*   `mutedTextColor`: `Color(0xFF9F9893)`
*   `borderColor`: `Color(0xFF25211F)`
*   `errorColor`: `Color(0xFFFF3333)`
*   `tricolorGreen`: `Color(0xFF2E7D32)`

*Note: As highlighted in the UI Audit, these tokens are frequently bypassed in favor of hardcoded hex values.*

### B. Typography (Inter & Serif)
*   Standard Font Family: `'Inter'` (defaults to system sans-serif due to missing configuration in `pubspec.yaml`).
*   Ornamental Serif Family: `'serif'` (used on `WelcomeScreen` for titles).

---

## 2. Reusable Widgets (Global / Shared)

### A. Input Fields
*   **[CustomTextField](file:///C:/Users/ANCHURU%20SANKEERTH/Internship-Project/localink_mobile/lib/features/auth/presentation/widgets/custom_text_field.dart):**
    *   *Usage:* Intended as a generic text field with custom toggleable password visibility.
    *   *Issues:* Currently neglected; login, signup, profile, and registration forms build their own text fields locally.

### B. Backgrounds
*   **[AnimatedAuthBackground](file:///C:/Users/ANCHURU%20SANKEERTH/Internship-Project/localink_mobile/lib/features/auth/presentation/widgets/animated_background.dart):**
    *   *Usage:* Provides an animated canvas with glowing colored blobs for authentication screens.
    *   *Issues:* Good reusability across login, signup, forgot password, OTP, and reset password.

---

## 3. Local & Screen-Specific Custom Widgets

### A. Custom Painters (Decorative Drawings)
*   **`WelcomeHeroPainter`:** Draws a radial sunset aura, temple silhouetted spires, gears, and an Om flag banner.
*   **`TempleHeaderPainter`:** Draws a matching saffron temple skyline in `admin_dashboard_screen.dart`.
*   **`EmblemPainter` & `EmblemSunPainter`:** Draws the orange sun emblem in the admin dashboard.
*   **`UserCardArtPainter`, `BusinessCardArtPainter`, `AdminCardArtPainter`:** Custom painters rendering detailed line-art decorations at the bottom of role selection cards on the welcome screen.
*   **`ParticleSystemPainter`:** An active floating golden particle system used in `SplashScreen`.

### B. Lists & Feed Cards
*   **Business Card (Home Screen):** Displays image banner, distance badge, favorite toggle, verification status badge, title, review count, rating stars, and call button.
*   **Favorite Card (Favorites Screen):** Horizontal list item with thumbnail, title, category, description, and quick-remove heart button.
*   **Recommendation Card (For You Feed Screen):** Features a clean image card with category/subcategory subtitle details.
*   **Business Dashboard Card (Business Owner Screen):** Lists registered businesses with statuses (Approved, Closure Pending, Temp Closed) and quick actions (View, Edit, Analytics, Temp Closure, Delete).

### C. Map Integrations
*   **MapLibreMap:** Configured with tile style `"https://tiles.openfreemap.org/styles/liberty"`. Used in `admin_heatmap_screen.dart` (for data pin heatmaps) and `business_registration_screen.dart` (for manual pin drop coordination).

### D. Dialogs & Bottom Sheets
*   **`VoiceSearchDialog`:** Triggers voice-to-text input microphone capture.
*   **`SortBottomSheet`:** Standard bottom list picker to sort by distance, reviews, or alphabetical order.
*   **`TemporaryClosureDialog`:** Dialog form to select closure duration (3, 7, 14, 30 days) and specify a mandatory reason.
*   **`RejectionDialog` / `DeletionDialog`:** Request forms containing text fields to write mandatory comments for admin reviews.

---

## 4. Duplicate Components & Refactoring Opportunities

| Duplicated Logic | Current Files | Refactored Solution |
| :--- | :--- | :--- |
| **Primary Action Buttons** | Welcome, Login, Signup, OTP, Business Dashboard | Create a single `PrimaryButton` widget supporting gradients, icon attachments, and loading indicators. |
| **Input Fields / InputDecoration** | Login, Signup, Profile, Registration | Consolidate under `CustomTextField` using the global `inputDecorationTheme` defined in `AppTheme.dart`. |
| **Phone Input with Country Code** | Signup, Registration | Extract to `PhoneInputField` widget containing the country dropdown picker and validation rules. |
| **Geocoding & Map Selection** | Signup, Registration, Profile | Build a reusable `LocationPicker` component containing geocoding, reverse geocoding, and map pin positioning. |
| **Template Custom Painters** | Splash Screen, Welcome Screen | Unify the floating gold particle systems under a single `ParticleOverlay` widget. |
