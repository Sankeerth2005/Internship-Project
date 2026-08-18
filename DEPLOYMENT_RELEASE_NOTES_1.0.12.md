# Vocal for Sanatan — 1.0.12 (17)

**Release date:** 18 August 2026  
**App version:** `1.0.12`  
**Version code:** `17`  
**Backend:** republish produced for the manager folder; **no backend code or schema changes** in this cut.

Deploy APK/AAB after this mobile UI build. Existing accounts, sessions, Google Sign-In, listings, maps, and APIs are unchanged.

---

## Play Console — release name

`1.0.12 (17) — Form fields, Profile Health, and responsive layout fixes`

## Play Console — short notes (user-facing)

```
What's new in 1.0.12

• State and City fields no longer overlap their labels
• Profile Health 100% ring is fully visible on the Business Suite
• Long business names, emails, and addresses stay inside cards on smaller phones
```

## Play Console — shorter option

```
1.0.12 — Clearer forms, a complete Profile Health ring, and tighter layouts on small screens.
```

---

## What this release contains (internal)

### Form fields
- Searchable Country/State/City fields keep the floating label separate from the hint/value.
- Registration, profile, signup, and Hours phone-code fields share the same decoration fix.
- Phone country-code display stays compact (`+91`); the picker still shows the country name.

### Business Suite
- Profile Health indicator is constrained so the full circle and centered percentage are visible.
- Hero card, analytics grid, and AppBar no longer fight for space on narrow widths.
- Analytics KPI cards drop to one column under ~340px.

### Overflow / responsiveness
- Home, favorites, reviews, AI feed, analytics, and action buttons ellipsize long text.
- Registration stepper, hours rows, and bottom CTAs scale down instead of overflowing.
- Home pagination scrolls horizontally on small screens.

### Unchanged
- API endpoints, Geoapify, CSC country/state/city, auth, Google Sign-In, and discovery ranking.

---

## Artifacts (built 18 August 2026)

| Artifact | Path |
|----------|------|
| Backend publish | `localink_be\publish_be` |
| Sideload APK (90.0 MB) | `localink_mobile\build\manager-deploy\vocal-for-sanatan-20260818-231116.apk` |
| Play Store AAB (71.0 MB) | `localink_mobile\build\manager-deploy\vocal-for-sanatan-20260818-231239.aab` |
| Release notes | `DEPLOYMENT_RELEASE_NOTES_1.0.12.md` |

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

No database migration is required. Backend source did not change in 1.0.12; republish is for a matching manager folder.

---

## Play Console — upload AAB

1. [Google Play Console](https://play.google.com/console) → Vocal for Sanatan
2. **Test and release** → Internal testing (recommended) or Production
3. **Create new release** → upload the `.aab`
4. Release name: `1.0.12 (17) — Form fields, Profile Health, and responsive layout fixes`
5. Paste the short notes above → **Review** → **Start rollout**

---

## Smoke tests after deploy

1. Open app — must **not** show “App build is misconfigured”
2. List New Business → Map: State shows `State *` above `Select state` (no overlap)
3. City shows `City *` above `Select state first` / `Select city` (no overlap)
4. Business Suite: Profile Health ring is a complete circle; `100%` is centered
5. Long business name and email stay inside the orange card
6. Login / kill app / reopen still works

---

## Known limitation

This mobile build is pointed at the current `API_HOST` in the repo-root `.env`. If that host is a free ngrok URL and the tunnel changes, rebuild APK/AAB after updating `.env`. Prefer a stable host (`api.vocalforsanatan.com`) for production Play users.
