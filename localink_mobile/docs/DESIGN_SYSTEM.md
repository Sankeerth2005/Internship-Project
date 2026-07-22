# Design System: Localink Mobile App
Version 2.0.0 • Single Source of Truth

This document serves as the absolute specification for the Localink design system. All visual elements, layout configurations, and component behaviors must adhere to these tokens to ensure a premium, minimal, and consistent user interface.

---

## 1. Core Foundations & Design Tokens

### A. Colors (Premium White & Orange Palette)
Our color system is built around a clean, high-brightness white background, accented by a modern primary orange and a soft saffron tone.

| Token Name | Hex Code | Usage | Role |
| :--- | :--- | :--- | :--- |
| `color-bg-primary` | `#FFFFFF` | Main application background (Scaffold). | Neutral |
| `color-bg-secondary` | `#F9F8F6` | Secondary cards, lists, and field fills. | Neutral |
| `color-bg-tertiary` | `#F0EFEA` | Inactive states, disabled buttons. | Neutral |
| `color-primary` | `#FF6600` | Primary action colors, active tab highlights. | Brand |
| `color-accent-saffron`| `#FF9E4F` | Soft saffron accent for tags, glowing borders. | Brand |
| `color-border-subtle` | `#EAE8E3` | Thin separators, inactive form outlines. | Neutral |
| `color-border-active` | `#FF6600` | Input focus indicator, selected outline. | Neutral |
| `color-text-high` | `#1A1918` | Heading text, primary titles. | Typography |
| `color-text-medium` | `#5F5C58` | Subheadings, body copy, descriptions. | Typography |
| `color-text-low` | `#9F9B96` | Inline captions, disabled text labels. | Typography |
| `color-error` | `#E1251B` | Validation errors, destructive warnings. | System |
| `color-success` | `#1E824C` | Positive validations, completed notifications. | System |
| `color-warning` | `#F39C12` | Temporary states, pending verifications. | System |

---

### B. Spacing (4dp Grid)
All dimensions, margins, paddings, and gaps must align to the 4dp grid system.

*   `space-xs` (4dp): Micro spacing (gap between inline icon and text).
*   `space-sm` (8dp): Small element gap (between labels and input fields).
*   `space-md` (12dp): Card content padding, minor section spacing.
*   `space-lg` (16dp): Default screen margins, inner container padding.
*   `space-xl` (24dp): Large vertical spacing between layout components.
*   `space-xxl` (32dp): Section headers clearance.

---

### C. Typography
*   **Default Font:** Sans-serif: `'Inter'` (clean, minimal, premium).
*   **Icon Font Family:** `'Material Symbols Rounded'` (enforces rounded icons for uniform soft appearance).

| Token | Size (SP) | Weight | Line Height | Case | Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `font-h1` | 32pt | 800 (ExtraBold)| 1.2 | Normal | Screen main title / Hero |
| `font-h2` | 24pt | 700 (Bold) | 1.3 | Normal | Section headings |
| `font-title` | 18pt | 700 (Bold) | 1.35 | Normal | Cards, list headers |
| `font-body-bold` | 14pt | 600 (SemiBold) | 1.4 | Normal | Focus items, body highlight |
| `font-body` | 14pt | 400 (Regular) | 1.4 | Normal | Description blocks, normal text |
| `font-caption` | 12pt | 500 (Medium) | 1.45 | Normal | Meta info, helper captions |
| `font-button` | 15pt | 700 (Bold) | 1.0 | Uppercase | Buttons CTA text |

---

### D. Radii (Borders Curve Scale)
Soft, premium rounded curves are applied to all container interfaces:
*   `radius-sm` (8dp): Chips, small input buttons.
*   `radius-md` (12dp): Input text fields, tiny buttons.
*   `radius-lg` (16dp): Bottom-sheets corners, main cards, dialogs.
*   `radius-xl` (24dp): Floating bottom navigation, custom pill buttons.
*   `radius-round` (999dp): Pill tags, circular avatars.

---

### E. Elevations & Borders
To maintain a modern, flat, premium layout, we minimize heavy drop shadows. Elevate components using subtle blurs and border outlines.

*   `elevation-none`: Border outline with no drop shadow.
*   `elevation-low`: `0px 4px 12px rgba(26, 25, 24, 0.05)` (Default card elevation).
*   `elevation-medium`: `0px 8px 24px rgba(26, 25, 24, 0.08)` (Floating menus, bottom sheets).
*   `elevation-high`: `0px 12px 32px rgba(26, 25, 24, 0.12)` (Dialog overlays).
*   `border-width-thin`: `1.0dp` (standard boundaries).
*   `border-width-thick`: `2.0dp` (focus indicator boundaries).

---

## 2. Reusable Component Design Tokens

### A. Buttons
*   **Primary CTA Button:** Pill shape (`radius-xl`), background color `color-primary`, text color `#FFFFFF` (`font-button`), height `48dp`, padding `16dp horizontal`.
*   **Secondary CTA Button:** Pill shape (`radius-xl`), transparent background, border outline `color-primary` (`border-width-thin`), text color `color-primary` (`font-button`), height `48dp`.

### B. Cards
*   **Standard Container Card:** Curved corners (`radius-lg`), background fill `color-bg-secondary`, outline border `color-border-subtle`, elevation `elevation-low`.

### C. Dialogs & Bottom Sheets
*   **Dialogs:** Centered overlays, curved (`radius-lg`), background `#FFFFFF`, border outline `color-border-subtle`, elevation `elevation-high`. Padding `24dp` on all sides.
*   **Bottom Sheets:** Top-rounded curve overlay (`radius-lg` top-left, top-right), background `#FFFFFF`, margin `16dp horizontal` and `8dp bottom` (floating card design) or edge-to-edge docking.

### D. Form Inputs & Dropdowns
*   **Input Box:** Height `52dp`, filled background `color-bg-secondary`, corner curve `radius-md`, border border `color-border-subtle` (`border-width-thin`).
    *   *Focus State:* Border matches `color-primary` (`border-width-thick`), label label matches `color-primary`.
    *   *Error State:* Border matches `color-error` (`border-width-thick`), error text uses `color-error` (`font-caption`).

### E. Search Bars
*   **Search Box:** Height `48dp`, filled background `color-bg-secondary`, rounded shape `radius-round`, leading icon `Icons.Rounded.Search` (`color-text-medium`), trailing actions `Icons.Rounded.Mic` (`color-primary`).

### F. Bottom Navigation & App Bars
*   **App Bar:** Height `56dp`, background `#FFFFFF`, leading navigation icon `Icons.Rounded.ArrowBackIosNew` (`color-text-high`), center title (`font-title` in `color-text-high`).
*   **Bottom Navigation Bar:** Height `72dp`, floating design with `16dp margins`, corner radius `radius-xl`, glassmorphic blur background `#FFFFFF` at `0.85 opacity`, border `color-border-subtle`, active highlights match `color-primary`.

---

## 3. Interactive Feedback & State Tokens

*   **Loading State:** Replaced by high-fidelity shimmers. Skeleton frames match the target component geometry (using `color-bg-secondary` as base and `color-bg-tertiary` as shimmering highlight).
*   **Empty State:** Illustrated centered layout. Material Symbol icon `Icons.Rounded.Inbox` (enlarged `48dp`, color `color-text-low`), title `color-text-medium` (`font-title`), descriptive paragraph (`font-body`), primary action redirect button below.
*   **Error State:** Centered layout. Icon `Icons.Rounded.Error` (`48dp`, `color-error`), title `color-text-high` (`font-title`), message (`font-body`), retry button (`Secondary CTA Button` style).
*   **Success State:** Full screen overlay or inline card. Centered green icon `Icons.Rounded.CheckCircle` (`color-success`, `64dp`), title `color-text-high` (`font-h2`), sub-info (`font-body`), Auto-navigates after 1500ms duration.

---

## 4. Accessibility & Layout Responsiveness

### A. Accessibility
*   **Tap Targets:** Minimum tactile touch dimension must be `48dp` x `48dp` for all clickable items.
*   **Contrast Check:** All body copy text must yield a contrast ratio of at least `4.5:1` against the white scaffold or secondary card background.
*   **Focus Indicator:** Focused text fields must display a border stroke of `2dp` (`border-width-thick`) using the active brand color `color-primary`.

### B. Responsive Layout Breakpoints
*   **Mobile:** `< 600dp` width. Grid columns: 4. Screen margins: `16dp`.
*   **Tablet:** `600dp` to `960dp` width. Grid columns: 8. Screen margins: `24dp`.
*   **Desktop:** `> 960dp` width. Grid columns: 12. Screen margins: `32dp`. Form cards constrained to a maximum width of `560dp`.
