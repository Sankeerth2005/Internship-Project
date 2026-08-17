# Vocal for Sanatan — 1.0.10 (15)

**Release date:** 17 August 2026  
**App version:** `1.0.10`  
**Version code:** `15`  
**Backend:** republish required (review validation error logging; no schema migration)

Deploy **backend first**, then the APK/AAB. Existing accounts, sessions, Google Sign-In, listings, and maps are unchanged.

---

## Play Console — release name

`1.0.10 (15) — Country flags, review submit, safer bottom buttons`

## Play Console — short notes (user-facing)

```
What's new in 1.0.10

• Business details now show the business’s registered country flag
• Submitting a review shows a clear message if text is too short
• Bottom buttons (Next Step, Save, Continue) sit above the Android navigation bar
```

## Play Console — shorter option

```
1.0.10 — Registered-country flags on business details, clearer review validation, and bottom action buttons raised above the system navigation bar.
```

---

## What this release contains (internal)

### Business country flag
- Business Details no longer shows a hardcoded India tricolor.
- Flag is resolved from the stored business phone country code (and country name for legacy / shared calling codes such as +1).
- If country cannot be determined, no flag is shown (India is not assumed).

### Review submit
- Backend still requires comment length 5–1000 when a comment is sent.
- The app now surfaces the actual field error instead of “One or more validation errors occurred.”
- Empty / short reviews show “Please enter your review” (or the 5-character hint) before the API call.

### Bottom action buttons
- Pinned CTAs (including Edit Business **Next Step**) respect the device bottom safe-area inset.
- Applies to business registration, admin tabs, chat composer, and related sheets.
- Screens that already used SafeArea were left unchanged.

### Google
- Google Sign-In was not changed.

---

## Artifacts (built 17 August 2026)

| Artifact | Path |
|----------|------|
| Backend publish | `localink_be\publish_be` |
| Sideload APK (90.0 MB) | `localink_mobile\build\manager-deploy\vocal-for-sanatan-20260817-115227.apk` |
| Play Store AAB (70.9 MB) | `localink_mobile\build\manager-deploy\vocal-for-sanatan-20260817-115342.aab` |
| Release notes | `DEPLOYMENT_RELEASE_NOTES_1.0.10.md` |

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
4. Release name: `1.0.10 (15) — Country flags, review submit, safer bottom buttons`
5. Paste the short notes above → **Review** → **Start rollout**

---

## Smoke tests after deploy

1. Open app — must **not** show “App build is misconfigured”
2. Business details: India `+91` shows 🇮🇳; another country shows its own flag; no India default for unknown
3. Review: short text shows a clear message; valid 5+ character review submits
4. Edit Business Details → Profile: **Next Step** sits above the system navigation bar
5. Login / kill app / reopen still works

---

## Known limitation

This mobile build is pointed at the current `API_HOST` in the repo-root `.env`. If that host is a free ngrok URL and the tunnel changes, rebuild APK/AAB after updating `.env`. Prefer a stable host (`api.vocalforsanatan.com`) for production Play users.
