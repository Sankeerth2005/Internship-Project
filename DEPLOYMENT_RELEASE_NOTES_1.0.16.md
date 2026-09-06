# Vocal for Sanatan — 1.0.16 (21)

**Release date:** 31 August 2026  
**App version:** `1.0.16`  
**Version code:** `21`  
**Backend:** **new publish required** — mandatory User Agreement consent is now account-level and enforced on every auth / session restore.

---

## Play Console — release name

`1.0.16 (21) — Mandatory User Agreement consent`

## Play Console — short notes (user-facing)

```
What's new in 1.0.16

• User Agreement & Consent is now required before using the app
• Consent is saved to your account (not only on this device)
• Closing the app without agreeing will show Consent again after login
• Works the same for email/password and Google sign-in
```

---

## Why this release

Previously, consent lived mainly in **local device storage**. A new user could create an account, see Consent, close the app without agreeing, then log in again and reach **Choose Role** / the app.

This release makes consent **mandatory and persistent on the user account**.

---

## What changed

### Backend
- New column: `users.consent_accepted` (`BIT NOT NULL`, default `0`)
- Login / Google / refresh responses include `user.consentAccepted`
- New endpoint: `POST /api/v1/auth/accept-consent` (authenticated)
- JWT claim `consent_accepted` updated when consent is accepted
- `ConsentMiddleware` blocks non-admin authenticated API access until consent is accepted (auth routes remain allowed)
- Startup auto-ensures the column; script also shipped: `Scripts/EnsureUserConsentColumn.sql`

### Mobile
- Auth navigation uses **backend** `consentAccepted` on every login, Google sign-in, and session refresh
- Flow: Login → Consent (if not accepted) → Choose Role → App
- Accepting consent calls the backend and refreshes tokens

### Database
- **Migration required:** add `consent_accepted` to `users`
- Idempotent script: `localink_be/Scripts/EnsureUserConsentColumn.sql`
- Also applied automatically on API startup when the column is missing
- Existing users default to **not consented** until they explicitly agree (by design)

---

## Manager deploy steps

1. Stop the running API (`dotnet localink_be.dll` / terminal).
2. Copy `localink_be\publish\manager\*` → manager API folder (e.g. `C:\VocalForSanatan\api`).
   - Keep the existing `.env` next to `localink_be.dll` (do not overwrite with a blank one).
3. Optional but recommended: run `Scripts\EnsureUserConsentColumn.sql` on the manager SQL database.
4. Start API again:
   ```powershell
   $env:ASPNETCORE_ENVIRONMENT='Production'   # or Development
   $env:ASPNETCORE_URLS='http://0.0.0.0:5138'
   dotnet localink_be.dll
   ```
5. Confirm ngrok / public URL still matches root `.env` `API_HOST`.
6. Upload the **AAB** to Play Console (Internal testing or Production).
7. Sideload the **APK** for quick manager/device smoke tests if needed.

---

## Smoke test checklist

1. New email signup → login → **Consent** → Accept → Choose Role → Home.
2. New account → Consent → **close app without accepting** → reopen → login → **Consent again** (must not skip to Choose Role).
3. Repeat close/login without accepting → Consent still enforced.
4. Accept consent once → kill app → reopen / session restore → **no Consent** → app continues normally.
5. Google sign-in on a new (or non-consented) account → Consent before Choose Role.
6. After accept, browse home / business detail / profile (APIs must not return `CONSENT_REQUIRED`).

---

## Artifacts (built 31 August 2026)

| Artifact | Path |
|----------|------|
| Backend publish | `localink_be\publish\manager` |
| Sideload APK (90.4 MB) | `localink_mobile\build\manager-deploy\vocal-for-sanatan-20260831-211024.apk` |
| Play Store AAB (71.3 MB) | `localink_mobile\build\manager-deploy\vocal-for-sanatan-20260831-211156.aab` |
| App version YAML | `localink_mobile\pubspec.yaml` → `1.0.16+21` |
| Release notes | `DEPLOYMENT_RELEASE_NOTES_1.0.16.md` |
| Consent SQL | `localink_be\Scripts\EnsureUserConsentColumn.sql` (also under publish `Scripts\`) |

---

## Notes

- API_HOST in this build is the current **ngrok** host from repo-root `.env`. Rebuild APK/AAB if the tunnel URL changes.
- Do **not** auto-set `consent_accepted = 1` for existing users unless product owners explicitly approve a one-time backfill.
