# Design Decisions: Vocal for Sanatan
Version 1.0.0 • Architectural & Visual Design Rationale

This document outlines the rationale behind the visual, structural, and technical decisions made for the Vocal for Sanatan application.

---

## 1. Visual Theme: Premium White & Primary Saffron-Orange

*   **Decision:** Move from a dark Obsidian-black backdrop to a high-brightness White Canvas (`#FFFFFF`), paired with Primary Orange (`#FF6600`) and Soft Saffron (`#FF9E4F`).
*   **Rationale:** 
    *   *Accessibility:* Light themes improve text readability and contrast in outdoor conditions (crucial for a local search app).
    *   *Trust & Quality:* A clean white layout feels open, modern, and trustworthy, aligning with the design language of Google Maps and Airbnb.
    *   *Cultural Resonance:* Saffron and orange colors provide a warm, energetic feel that represents community and connection without cluttering the screen.

---

## 2. Typography & Iconography Selection

### A. Font Choice: Inter
*   **Decision:** Enforce 'Inter' as the default font family, configured locally in `pubspec.yaml`.
*   **Rationale:** Inter is highly legible at small sizes, making it perfect for dense listings, address lines, and business operating hours. It also supports dynamic text scaling without breaking layouts.

### B. Icons: Material Symbols Rounded Only
*   **Decision:** Restrict all icons to the *Material Symbols Rounded* family.
*   **Rationale:** Soft, rounded icon edges match the curved corners of our cards and inputs, creating a cohesive, premium visual style.

---

## 3. Structural & Navigation Redesigns

### A. Swapping Chips for Autocomplete Dropdown
*   **Decision:** Replace the horizontal category scrolling chips on the Home Screen with a searchable autocomplete dropdown.
*   **Rationale:** Horizontal scrolling is slow and limits discovery. An autocomplete dropdown lets users quickly search through hundreds of subcategories with just a few keystrokes.

### B. Bottom Navigation Refactor: Profile to Community Hub
*   **Decision:** Remove the duplicate Profile tab from the bottom navigation shell, replacing it with a **Community Hub** (Support, Feedback, Complaints, Suggestions). Profile editing is moved to a settings icon in the Home dashboard.
*   **Rationale:** Decoupling basic discovery from support and feedback structures makes the app more utility-focused, helping users quickly find help or suggest community listings.

### C. Personalizing Listings with Owner Names
*   **Decision:** Display the Business Owner's full name on every list card, details page, and chat card.
*   **Rationale:** Showing the owner's name builds trust and personal connection, turning a cold business listing into a warm community contact.

---

## 4. Technical & API Decisions

*   **MapLibre GL Integration:** Used for map rendering because it is lightweight, supports custom offline vector tiles, and avoids expensive proprietary API fees.
*   **Geoapify API for Geocoding:** Selected for address validation and location lookups due to its reliability and seamless integration with our pincode verification backend.
*   **JSON API Responses in AI Chat:** Enforcing structured JSON outputs from the Llama assistant allows the app to render native interactive business cards inside chat bubbles, instead of displaying plain text recommendations.
