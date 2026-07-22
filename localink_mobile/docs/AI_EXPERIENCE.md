# AI Experience: Vocal for Sanatan
Version 1.0.0 • Conversational Design, Interface Dynamics & Structured Outputs

This document defines the user experience, layout properties, and API formatting guidelines for the AI Assistant panel.

---

## 1. Conversational Interface Dynamics

The AI Assistant is designed to feel like an intelligent, welcoming local guide.

*   **Typewriter Streaming:** Text responses stream character-by-character (fading opacity from `0.0` to `1.0` in chunks of 3 characters over `20ms` intervals). This gives the interface a responsive, real-time feel.
*   **Pulsing Typing Wave:** While the backend processes the query, a floating capsule displays three golden dots pulsing in a smooth wave pattern.
*   **Conversation History:** Chat threads are grouped by date (e.g., *"Today"*, *"Yesterday"*, *"Varanasi Discovery"*). A settings gear at the top-right allows clearing history or exporting logs.

---

## 2. Interactive Business Cards in Chat

The assistant does not output plain text recommendations. All businesses suggested by the AI are rendered as interactive, tapable cards embedded directly inside the chat flow.

```
+-------------------------------------------------------+
|  Gupta Medicos (Varanasi)                   [★ Save]  |
|  Vijay Gupta, Owner                                   |
|  ⭐ 4.8 (120 reviews) • 400m away • Open Now          |
|                                                       |
|  +-------------------------------------------------+  |
|  |  [Call Owner]  |  [Directions]  |  [Share Card] |  |
|  +-------------------------------------------------+  |
+-------------------------------------------------------+
```

### Supported Actions on AI Cards
*   **Call Owner:** Instantly triggers the device dialer.
*   **Directions:** Opens local map coordinates using GoRouter navigation.
*   **Share Card:** Opens the native OS share sheet populated with the store's deep link.
*   **Bookmark:** Saves the business to the user's local Favorites tab (triggering a gold-star confetti burst).

---

## 3. Dynamic Prompting & Smart Follow-Ups

*   **Suggested Prompts:** On opening a blank chat, the screen displays 4 pill-shaped prompt cards based on location, weather, and time of day:
    *   *Morning:* `"Find breakfast spots open now in Varanasi"`
    *   *Rainy Day:* `"Indoor activities in Varanasi"`
*   **Smart Follow-Up Questions:** Below every completed AI text response, the app fades in 3 follow-up suggestions (e.g. *"Show reviews for Gupta Medicos"*, *"Are there other pharmacies closer?"*, *"What are their operating hours?"*).

---

## 4. Backend System Prompt Configuration

To return structured interactive cards, the AI API system prompt instructs the Llama/GPT model to output responses in a strict JSON schema:

```json
{
  "text_response": "I found a highly-rated pharmacy near you in Varanasi:",
  "has_business_cards": true,
  "recommended_businesses": [
    {
      "businessId": 204,
      "businessName": "Gupta Medicos",
      "ownerName": "Vijay Gupta",
      "averageRating": 4.8,
      "reviewCount": 120,
      "city": "Varanasi",
      "distance": "400m",
      "status": "Approved",
      "isOpen": true
    }
  ],
  "follow_up_prompts": [
    "Show hours for Gupta Medicos",
    "Find organic grocers nearby"
  ]
}
```
The mobile application parses this JSON response, renders the `text_response` string, builds the `AppBusinessCard` widgets for items in `recommended_businesses`, and displays the `follow_up_prompts` pills at the bottom of the conversation feed.
