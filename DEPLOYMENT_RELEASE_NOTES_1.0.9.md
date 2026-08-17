# Vocal for Sanatan — 1.0.9 (14)

**Release date:** 14 August 2026  
**App version:** `1.0.9`  
**Version code:** `14`  
**Backend:** republish required (register/profile/business phone & location validation)

Deploy **backend first**, then the APK/AAB. Existing accounts, sessions, Google Sign-In, and stored addresses are unchanged.

---

## Play Console — release name

`1.0.9 (14) — Faster signup, role selection, location pickers`

## Play Console — short notes (user-facing)

```
What's new in 1.0.9

• Faster signup — only name, country, phone, email, and password
• After sign-in, choose User or Business Owner (new and existing accounts)
• Searchable country, state, and city pickers that handle large lists
• More reliable phone and pincode checks (no refresh needed after a correction)
• Address details can be completed in Profile or when listing a business
```

## Play Console — shorter option

```
1.0.9 — Shorter signup, role selection after login, searchable location pickers, and more reliable phone/pincode validation.
```

---

## What this release contains (internal)

### Signup
- Reduced from 4 steps to 2 (identity + password).
- Account type, state, city, street, and pincode are no longer collected at signup.
- New accounts are created as `user`. Role is chosen after login.
- Country picker remains so phone country-code validation still works.

### Role selection
- New and existing users see **Continue As** after interactive login or Google sign-in.
- Choosing Business Owner does not create a second account.
- Owners without a listing are sent to business registration.
- Cold start still restores the last chosen experience. Admin still skips Continue As.

### Location / nearest businesses
- Nearby / For You still uses **device GPS**, not the signup address.
- Owner map pin + country/state/city/pincode remain required on **business registration**.
- Profile address can be completed later in Edit Profile.

### Validation & UI
- Country-aware phone validation (frontend + backend).
- Pincode: latest input wins; correcting an invalid pin no longer requires an app restart.
- Searchable location sheets with lazy loading (no nested dropdown boxes).
- Country → State → City cascade clears stale child values.

### Google
- Google Sign-In / Sign-Up implementation was not changed.
- After a successful Google result, the app now routes to role selection.

---

## Artifacts (built 14 August 2026)

| Artifact | Path |
|----------|------|
| Backend publish | `localink_be\publish_be` |
| Sideload APK (90.0 MB) | `localink_mobile\build\manager-deploy\vocal-for-sanatan-20260814-195317.apk` |
| Play Store AAB (70.9 MB) | `localink_mobile\build\manager-deploy\vocal-for-sanatan-20260814-195418.aab` |
| Release notes | `DEPLOYMENT_RELEASE_NOTES_1.0.9.md` |

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

No database migration is required. Existing user addresses stay intact. New signups may have empty state/city/pincode until profile or business setup.

---

## Play Console — upload AAB

1. [Google Play Console](https://play.google.com/console) → Vocal for Sanatan
2. **Test and release** → Internal testing (recommended) or Production
3. **Create new release** → upload the `.aab`
4. Release name: `1.0.9 (14) — Faster signup, role selection, location pickers`
5. Paste the short notes above → **Review** → **Start rollout**

---

## Smoke tests after deploy

1. Open app — must **not** show “App build is misconfigured”
2. Existing email login → Continue As → User / Owner
3. New email signup (2 steps) → login → Continue As
4. Google existing account → same Google success → Continue As
5. Correct an invalid pincode to a valid one without restarting
6. Search country/state/city; city search (e.g. `Hyd`) works
7. Home / For You nearby still uses GPS
8. Business registration still requires map pin + location
9. Kill app → reopen → still logged in on last chosen experience

---

## Known limitation

This mobile build is pointed at the current `API_HOST` in the repo-root `.env`. If that host is a free ngrok URL and the tunnel changes, rebuild APK/AAB after updating `.env`. Prefer a stable host (`api.vocalforsanatan.com`) for production Play users.
