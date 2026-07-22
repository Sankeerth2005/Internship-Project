# Micro-Interactions Guide: Vocal for Sanatan
Version 1.0.0 • Micro-Interaction & Animation Specifications

This document outlines the visual specifications, curves, and triggers for interactive elements in Vocal for Sanatan, ensuring a fluid experience.

---

## 1. Action Element Interactions

### A. Button Press
*   **Trigger:** On pointer down (touch start).
*   **Behavior:** Animated scale down from `1.0` to `0.96` over `100ms` using `Curves.easeOutCubic`.
*   **Release:** Animated scale back from `0.96` to `1.0` over `150ms` using `Curves.elasticOut`.
*   **Haptic Profile:** Gentle, low-amplitude click vibration on release.

### B. Favorite Heart / Star Bounce
*   **Trigger:** Tapping the favorite icon button.
*   **Aesthetic Behavior:**
    1.  *Unselected to Selected:* Icon scales down to `0.4` scale, changes color to gold (`#FF9E4F`), then expands up to `1.3` scale before settling back to `1.0` using `Curves.easeOutBack` over `300ms`.
    2.  *Selected to Unselected:* Icon fades and scales down to `0.8`, changing color back to grey outline over `150ms` using `Curves.easeInCubic`.
*   **Delight Confetti:** Selecting triggers a small burst of saffron particle lines shooting outward from the icon boundary.

---

## 2. Search & Navigation Elements

### A. Autocomplete Search Dropdown Expansion
*   **Trigger:** Tapping the search bar field.
*   **Behavior:** The search container expands to fill the header space over `250ms` using `Curves.easeInOutCubic`.
*   **List Items:** Suggested search matches fade and slide upward sequentially (`index * 30ms` delay) with opacity fading from `0.0` to `1.0`.

### B. Floating Bottom Navigation Bar
*   **Trigger:** Tapping a navigation icon.
*   **Active Indicator:** A horizontal saffron capsule outline behind the icon expands and shifts to outline the new active icon over `200ms` using `Curves.easeOutCubic`.
*   **Icon Jump:** The selected icon jumps upward by `4dp` and settles back over `150ms`.

### C. Pull to Refresh Loop
*   **Trigger:** Swiping down at the top of a scroll list.
*   **Aesthetic Behavior:** The saffron circular loader follows the drag distance, spinning slowly. Once it passes the threshold (`64dp`), it snaps into a continuous rotation. On release, it pulses once before snapping back upward.

---

## 3. Cards & Lists Motion

### A. Card Lift & Hover
*   **Trigger:** Touch drag or pointer hover over business/category cards.
*   **Behavior:** The border color changes from light grey (`#EAE8E3`) to soft saffron (`#FF9E4F`) over `150ms`, while card elevation increases from `elevation-low` to `elevation-medium` (raising visually by `2dp`).

### B. Hero Transition
*   **Trigger:** Tapping a business list item card.
*   **Behavior:** The thumbnail image stretches and morphs into the full-width header banner of the destination details page.
*   **Transition Specs:** Duration `300ms`, interpolation path set to `Curves.easeInOutCubic`.

---

## 4. Modal Overlays & Alerts

### A. Dialog Entries
*   **Trigger:** Administrative rejection prompt or store deletion warning.
*   **Behavior:** The dialog scales up from `0.85` to `1.0` while fading in over `250ms` using `Curves.easeOutBack`. Background dim opacity fades from `0.0` to `0.4` over the same duration.

### B. Floating Bottom Sheets
*   **Trigger:** Category filter picker or temporary closure configuration.
*   **Behavior:** Slides up from the bottom boundary to dock at the lower portion of the screen.
*   **Transition Specs:** Duration `280ms`, animation curve `Curves.easeOutCubic`.

---

## 5. Shimmer Skeleton Loading Cycles
*   **Base Color:** `#F9F8F6` (Secondary Background).
*   **Highlight Color:** `#EAE8E3` (Subtle Border Gray).
*   **Loop Period:** `1500ms` infinite cycle.
*   **Aesthetic Sweep:** A diagonal gradient band (angled at `-30` degrees) sweeps from left to right across the card geometry. Skeletons must match the target card radii (`radius-lg`).
