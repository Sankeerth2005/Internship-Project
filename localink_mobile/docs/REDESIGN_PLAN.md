# Redesign & Implementation Plan: Localink Mobile App

## 1. Objectives & Goals
The objective of this redesign plan is to elevate the **Localink Mobile App** from a functional prototype with ad-hoc styling overrides to a premium, accessible, and robust production-ready application.

### Key Goals
1.  **Visual Unification:** Harmonize orange accents and background shades using strict design token bounds.
2.  **Code Optimization:** Eliminate redundant widgets, form configurations, and custom painter implementations.
3.  **State Completeness:** Enforce standard skeleton loaders, error retry routes, and contextual empty feed indicators.
4.  **Accessibility Compliance:** Achieve WCAG 2.1 AA ratings (targeting contrast ratios of 4.5:1 and proper button semantics).
5.  **Navigation Flow Integrity:** Resolve back gesture traps and build fluid page transition animations.

---

## 2. Phased Implementation Roadmap

### Phase 1: Foundation & Design Tokens
*   **Action Items:**
    1.  Clean up `lib/core/theme/app_theme.dart`. Restrict saffron/orange accents to `AppTheme.accentColor` (`0xFFFF6B00`) and solar gold to `AppTheme.glowColor` (`0xFFFF9F00`). Eliminate all hardcoded inline color variants.
    2.  Define spacing constants (`AppSpacing.xs` = 4, `sm` = 8, `md` = 16, `lg` = 24, `xl` = 32) inside a dedicated class or theme extension.
    3.  Configure `'Inter'` font family assets inside `pubspec.yaml` to prevent fallback rendering differences across platforms.
*   **Verification:** Ensure no compiler warnings in `app_theme.dart` and verify standard typography configurations.

### Phase 2: Refactoring Inputs & Forms
*   **Action Items:**
    1.  Rebuild `CustomTextField` to support custom styles, validations, suffix/prefix icons, and input formatters while complying with the global theme.
    2.  Refactor `login_screen.dart`, `signup_screen.dart`, `profile_screen.dart`, and `business_registration_screen.dart` to use the unified `CustomTextField`.
    3.  Create a shared `PhoneInputField` containing country-flag picker and validation rules.
*   **Verification:** Execute unit tests on inputs. Validate email, phone, and pincode patterns.

### Phase 3: Global Component Standardization
*   **Action Items:**
    1.  Create a reusable `PrimaryCTAButton` that handles gradients, pill-shapes, loading indicators, and tactile haptic feedback callbacks.
    2.  Consolidate floating golden particle custom painters (`ParticleSystemPainter`) into a single reusable backdrop widget.
    3.  Build a standard `StatusBadge` widget for approved/pending tags.
*   **Verification:** Verify all screens render the identical button styling.

### Phase 4: State Feedback & Animation Polish
*   **Action Items:**
    1.  Design premium skeleton loading widgets (shimmer effect) for listings feed, analytics boards, and detail views.
    2.  Create engaging empty states (illustration + action buttons) for favorites and search feeds.
    3.  Introduce slide/fade transitions on tab selection within `MainShell` to smooth out page jumps.
    4.  Add subtle scale animation feedback when role selection cards are tapped on the welcome page.
*   **Verification:** Simulate offline network requests to test loading skeletons and check empty state widgets.

### Phase 5: Navigation & Accessibility Adjustments
*   **Action Items:**
    1.  Modify `PopScope` on `home_screen.dart` to permit double-tap exits rather than blocking back gestures completely.
    2.  Unify `/profile` and `/owner-profile` navigation stack layers to ensure a clean back route.
    3.  Add double-action confirm popups for destructive logout and deletion actions.
    4.  Wrap critical custom paint elements and custom gestural selectors in Flutter `Semantics` tags.
*   **Verification:** Run contrast analyzer checks on the shell tab labels and verify screen reader speech announcements on custom cards.

---

## 3. Verification & Testing Strategy
*   **Automated Verification:**
    *   Execute `flutter test` to ensure registration, profile fields, and validation logic remain unbroken.
*   **Visual & Manual Checks:**
    *   Audit color contrast on both iOS and Android.
    *   Verify edge-to-edge system transparent colors function correctly without text cut-offs.
