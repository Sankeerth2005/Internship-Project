# Vocal for Sanatan — 1.0.11 (16)

**Release date:** 17 August 2026  
**App version:** `1.0.11`  
**Version code:** `16`  
**Backend:** republish required (country-aware pincode rules; global distance ranking; no schema migration)

Deploy **backend first**, then the APK/AAB. Existing accounts, sessions, Google Sign-In, listings, and maps are unchanged.

---

## Play Console — release name

`1.0.11 (16) — Country postal codes, worldwide nearest-first discovery`

## Play Console — short notes (user-facing)

```
What's new in 1.0.11

• Postal codes now follow the selected country’s format (India 6 digits, US ZIP, UK, Canada, and more)
• Nearby, search, voice, AI Feed, and AI Chat show nearest matching businesses first, then farther ones — no 25 km cutoff
• You can keep scrolling to discover businesses in other cities, states, and countries
```

## Play Console — shorter option

```
1.0.11 — Country-specific postal codes, and nearest-first search worldwide with no 25 km limit.
```

---

## What this release contains (internal)

### Country-aware pincode / postal code
- Format validation uses the **selected address country** (ISO2), not GPS and not the phone calling code.
- India still requires exactly 6 digits.
- US ZIP / ZIP+4, UK postcode, Canadian postal code, and other country rules are centralized.
- Flutter `AppValidators.pincode` and backend `PincodeGuard` share the same rules.
- The 3–10 alphanumeric fallback is used only when there is no specific country rule.
- Geoapify existence check, debounce, latest-request-wins, 6-hour cache, state match, and fail-open are unchanged.
- CSC country/state/city cascade is unchanged.

### Global distance-based discovery
- The 25 km radius is **no longer a hard visibility filter** (not raised to 100/500 km either).
- All eligible matching businesses can appear; distance ranks them nearest → farther → other countries.
- Results stay paginated on the server (the app does not download the whole catalogue).
- Search = relevance filter, then distance ranking among matches.
- Voice search, AI Feed, and AI Chat use the same discovery ranking.
- Missing/invalid coordinates are ranked last; no fake default coordinates are assigned.
- User GPS is still the location source. If location is unavailable, existing non-distance ranking is used.

### Google
- Google Sign-In was not changed.

---

## Artifacts (built 17 August 2026)

| Artifact | Path |
|----------|------|
| Backend publish | `localink_be\publish_be` |
| Sideload APK (90.0 MB) | `localink_mobile\build\manager-deploy\vocal-for-sanatan-20260817-140439.apk` |
| Play Store AAB (71.0 MB) | `localink_mobile\build\manager-deploy\vocal-for-sanatan-20260817-140603.aab` |
| Release notes | `DEPLOYMENT_RELEASE_NOTES_1.0.11.md` |

Gradle outputs (same binaries):
- `localink_mobile\build\app\outputs\flutter-apk\app-release.apk`
- `localink_mobile\build\app\outputs\bundle\release\app-release.aab`

---

## Manager PC — backend deploy

1. Stop the running API (`dotnet localink_be.dll`).
2. Copy the **entire** folder `localink_be\publish_be` over:
   - `C:\VocalForSanatan\publish_be` **or**
   - `C:\VocalForSanatan\api`
3. Confirm `.env` sits next to `localink_be.dll`.
4. Start:

```powershell
$env:ASPNETCORE_ENVIRONMENT='Development'
$env:ASPNETCORE_URLS='http://0.0.0.0:5138'
dotnet localink_be.dll
```

5. If using ngrok: `.\deploy\Start-Ngrok.ps1`
6. Health check: `GET https://YOUR-API-HOST/health`

No database migration is required.

---

## Play Console — upload AAB

1. [Google Play Console](https://play.google.com/console) → Vocal for Sanatan
2. **Test and release** → Internal testing (recommended) or Production
3. **Create new release** → upload the `.aab`
4. Release name: `1.0.11 (16) — Country postal codes, worldwide nearest-first discovery`
5. Paste the short notes above → **Review** → **Start rollout**

---

## Smoke tests after deploy

1. Open app — must **not** show “App build is misconfigured”
2. Register/edit a business in India: `500035` accepted; `50003` rejected as not 6 digits
3. Select United Kingdom: a valid UK postcode is accepted; a 6-digit Indian pin is rejected
4. Nearby / home: businesses beyond 25 km can appear after nearer ones, via pagination
5. Search `hotel`: relevant hotels nearest first, then farther cities/countries
6. AI Feed and AI Chat recommend nearer matches first when location is on
7. Login / kill app / reopen still works

---

## Known limitation

This mobile build is pointed at the current `API_HOST` in the repo-root `.env`. If that host is a free ngrok URL and the tunnel changes, rebuild APK/AAB after updating `.env`. Prefer a stable host (`api.vocalforsanatan.com`) for production Play users.
