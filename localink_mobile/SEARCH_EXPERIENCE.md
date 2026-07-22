# Search Experience: Vocal for Sanatan
Version 1.0.0 • Search UI, Architecture & Matching Engine

This document defines the interface and matching specifications for the search experience in Vocal for Sanatan.

---

## 1. Google Maps-Like Unified Search Interface

The search bar is located at the top of the Home Screen, acting as the primary entry point for discovery.

```
+--------------------------------------------------------------+
|  (<-)  Search stores, owners, categories...      (Mic) (Geo) |
+--------------------------------------------------------------+
```

### Key Interactions
1.  **Tap to Expand:** Tapping the search input expands the field to cover the header, opening a sliding suggestions list.
2.  **Voice Search:** Tapping the microphone icon (`Mic`) opens `VoiceSearchDialog`, displaying a pulsing wave visualization while translating speech to text.
3.  **Active Geolocation:** Tapping the target icon (`Geo`) fetches the user's current GPS coordinates, instantly prioritizing listings closest to them.

---

## 2. Multi-Tier Search Query Resolution

The search matching engine must support query lookups across multiple parameters:

*   **Business Details:** Matches against the `Business Name` or `Description`.
*   **Owner Details:** Matches against the `Owner Name` (e.g. searching *"Rajesh"* returns *"Rajesh's Hardware"*).
*   **Categories & Subcategories:** Typing *"car"* matches *"Car Services"*, *"Automotive"*, or *"Car Wash"*.
*   **Detailed Address Layers:** Filters down to `Street`, `Cross Road`, `Area`, `Zone`, `Pincode`, `City`, `State`, and nearby `Landmarks`.
*   **Partial Matches & Autocomplete:** Displays matching results instantly after typing 2 characters, highlighting matching substrings in bold saffron orange.

---

## 3. Typo Correction & Match Logic

To ensure a smooth search experience, the matching engine utilizes a two-step validation process:
1.  **Fuzzy Matching (Levenshtein Distance):** Corrects minor typos (e.g. typing *"Hartware"* auto-corrects to suggest *"Hardware"*).
2.  **Typo-Correction Banner:** Displays a clean notification banner below the search bar: *"Showing results for Varanasi. Search instead for Varanassi?"*

---

## 4. Suggested Filters & Recent History

*   **Recent Searches:** Displays the user's last 5 searches as tags with a trailing `Close` icon for quick deletion.
*   **Popular & Trending Searches:** Lists hot searches in the area (e.g., *"Organic Milk near Varanasi"*, *"Ac Repair"*).
*   **Predictive Suggested Filters:** Generates dynamic filters based on the query:
    *   If query is *"restaurant"*, suggested filters display: `[ Open Now ]`, `[ 4.5+ Stars ]`, `[ Pure Veg ]`.
    *   If query is *"carpenter"*, suggested filters display: `[ Home Service ]`, `[ Highly Rated ]`.

---

## 5. Handling Empty Search Results

If a search yields 0 matches, the interface displays an active recovery view:
*   **Explanation:** *"No pharmacies found on Cross Road."*
*   **Suggested Actions:**
    *   A primary button to *"Clear Filters"*.
    *   A card proposing *"Search in surrounding pincodes"* (expanding search radius from 5km to 15km).
    *   A list of *"Popular Categories"* (quick links to health, daily services).
    *   A link to *"Ask AI"* to suggest fallback providers.

---

## 6. Search Analytics & Performance

*   **Search Latency Target:** All local suggestions, autocompletes, and history lookups must resolve in under **100ms** from local DB cache files.
*   **Admin Search Analytics:** The app captures anonymous search telemetry (e.g., *popular unserved search queries* or *common search zones*). This data populates the admin heatmap dashboard to identify local demand gaps.
