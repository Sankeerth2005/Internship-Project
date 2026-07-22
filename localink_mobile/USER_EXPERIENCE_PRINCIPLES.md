# User Experience Principles: Vocal for Sanatan
Version 1.0.0 • Interaction Philosophies & Quality Benchmarks

This document outlines the interactive behavioral guidelines for all screens in the Vocal for Sanatan app, guaranteeing a world-class, premium product feel.

---

## 1. Emotional Target: How Users Should Feel
*   **Reassured:** The app feels solid, secure, and trust-verified. There are no sudden layout shifts, silent crashes, or confusing loops.
*   **Empowered:** Finding local details or registering a storefront feels fast, clear, and successful.
*   **Connected:** The platform emphasizes human details (displaying Business Owner names on cards), establishing a warm community environment rather than a cold catalog.

---

## 2. Navigation Architecture
*   **Flat hierarchy:** Essential entry routes are docked to the persistent floating bottom navigation shell. High-level modules must be reachable within a single tap.
*   **Predictive back routes:** Back gestures must step backward along the user's historical breadcrumbs, never trapping the user or dropping them into loop stack locks.
*   **Contextual preservation:** When switching tabs (e.g. from Home search results to Chat and back), the state (scrolled position, inputs, filters) remains preserved.

---

## 3. Information Grouping & Hierarchy
*   **Immediate Scanning:** Critical information (such as Business Name, Owner Name, Rating, and Open/Closed status) occupies the top layer of visual hierarchy on cards and detail grids.
*   **Progressive Disclosure:** Minor technical details (payment methods accepted, facilities lists, registration dates) remain collapsed or placed at lower sections, revealing themselves only as the user scrolls or interacts.
*   **Visual Balance:** Clean borders and soft grid margins prevent "content congestion." We use whitespace to isolate interactive elements rather than heavy dark separators.

---

## 4. Interaction Consistency
*   **Tactile Feedback:** Every touch event must trigger a proportional micro-interaction (e.g., standard button press scale-down factor of `0.96`, gold star favorite bounce).
*   **Predictable Anchors:** Tapping action prompts (e.g. Call, Directions, Share) triggers native OS overlays (the device dialer, system share dialog, or native maps directions route) without custom middle pages.

---

## 5. Forms Experience
*   **Inline Validation:** Inputs validate dynamically as the user types (with a `500ms` debounce to avoid flashing errors prematurely). We do not block the screen with error modals.
*   **Smart Focus Order:** Forms automatically advance the cursor to the next logical input field. Pincodes trigger asynchronous city lookups with transparent loading overlays.
*   **Helpful Context:** Floating placeholder hints slide upward when the field is focused, keeping the form layout stable and compact.

---

## 6. Visual States Handling

### A. Loading States (Skeleton Shimmers)
*   Do not block interactions with fullscreen gray overlays unless it is a blocking transaction (e.g., submitting payment or registration).
*   Use skeleton shimmers that match the final shape of the text lines, cards, and pictures, fading smoothly into view once the network returns data.

### B. Empty States (Alternative Suggestions)
*   An empty state is an opportunity, not a dead end. Every empty view (e.g. empty search or empty favorites) must provide:
    *   An explanation of why the screen is empty.
    *   Alternative categories or suggested keywords.
    *   A primary CTA button directing the user to explore active sections.

### C. Error States (Actionable Retry Paths)
*   Errors must never display raw server stack trace strings or generic "Exception occurred" text.
*   Explain the error in simple terms (e.g., *"Cannot reach the local listing database"*).
*   Provide a clear retry button and, where possible, activate an offline-cached read mode for previously loaded listings.

### D. Success Celebrations (Tactile Micro-Rewards)
*   Important events (such as business approval, profile update, or review submitted) should trigger micro-rewards:
    *   A clean green check animation.
    *   A brief haptic pulse.
    *   For major accomplishments (like shop registration success), a brief burst of saffron star confetti.

---

## 7. Frictionless Onboarding
*   **Anonymous Search Path:** Consumers can search, browse, and read listings without registering. Auth wall triggers only when trying to favorite, comment, or register a business.
*   **Simplified Signups:** Registration processes require minimal inputs, using pincode auto-lookups and phone confirmation pins to speed up verification.

---

## 8. Trust Verification Systems
*   **Personalization:** Showing owner names prominently on all listing cards removes anonymity.
*   **Audit trails:** Business owners can see the verification status of their registration (Approved, Pending, Correction Required) with direct feedback comments from admin moderators.
