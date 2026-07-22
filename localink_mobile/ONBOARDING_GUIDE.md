# Onboarding Experience: Vocal for Sanatan
Version 1.0.0 • Onboarding Flow, Progression & Screen Sequences

This document outlines the user onboarding experience, designed to minimize friction while establishing app value and trust.

---

## 1. Onboarding Progression & Screen Sequences

The onboarding flow is presented as a horizontal slide-through deck (using a standard page indicator at the bottom).

```
+-------------------------------------------------------+
|  [Skip]                                               |
|                                                       |
|                     Vector Art                        |
|                                                       |
|                 Discover Local Trust                  |
|          Find verified businesses, owners,            |
|          and professionals nearby.                    |
|                                                       |
|                   (o  o  o  o)                        |
|                                                       |
|                   [ Continue ]                        |
+-------------------------------------------------------+
```

### Screen 1: Discovery & Purpose
*   **Visual Backdrop:** Minimalist line art animation depicting a local marketplace.
*   **Headline:** *"Discover Local Trust"*
*   **Description:** *"Connect with verified local businesses, organizations, and professionals in your neighborhood, backed by personal owner accountability."*

### Screen 2: Direct, Fee-Free Communication
*   **Visual Backdrop:** Vector art illustrating a direct phone link and map route.
*   **Headline:** *"Direct and Fee-Free"*
*   **Description:** *"Get directions and call owners directly with zero middleman commissions or hidden transaction costs."*

### Screen 3: Conversational AI Assistant
*   **Visual Backdrop:** Abstract illustration of a chat interface emitting structured cards.
*   **Headline:** *"Meet Your AI Local Guide"*
*   **Description:** *"Search using natural voice commands or chat with our Llama-powered AI assistant to get instant recommendations as interactive cards."*

### Screen 4: Community Support & Feedback
*   **Visual Backdrop:** Silhouette illustration of hands joined, showing feedback and support tickets.
*   **Headline:** *"Empower Your Community"*
*   **Description:** *"Save favorites, share local discoveries, request new listings, and directly submit feedback or complaints to improve your neighborhood."*

---

## 2. Friction Reductions & Skip Actions

*   **Persistent Skip Button:** A "Skip Onboarding" button is anchored to the top-right corner of all slide screens, allowing users to enter the Home Screen instantly without navigating the deck.
*   **Frictionless Entry:** Consumers can search, browse, and read listings anonymously. Authentication is required only for active community features (e.g. favoriting, writing reviews, submitting suggestions, or listing a business).

---

## 3. Interactive Role Selection

After completing onboarding (or tapping Skip), unauthenticated users are directed to the **Welcome Screen** featuring three interactive role selection cards:

1.  **Consumer Card:** *"Explore Varanasi"* (Accesses standard user discovery features).
2.  **Merchant Card:** *"List My Business"* (Navigates to Merchant Signup/Login).
3.  **Moderator Card (Hidden Admin Entrance):** Access to the admin dashboard is hidden from the main screen to prevent clutter. To reveal the admin entrance, users must triple-tap the app logo header.
*   **Interactions:** Selecting a card triggers a scale bounce (`curve-overshoot`), updating the selection border with a saffron gradient and a subtle haptic click.
