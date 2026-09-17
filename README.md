# Vocal for Sanatan (Localink)

End-to-end monorepo for the live Play Store app **Vocal for Sanatan** (`com.vocalforsanatan.app`).

| Piece | Folder | Stack |
|-------|--------|--------|
| Mobile app | `localink_mobile/` | Flutter + Riverpod + GoRouter |
| Backend API | `localink_be/` | ASP.NET Core 8 + EF Core + SQL Server |
| Marketing site | `localink-website/` | Next.js → `https://vocalforsanatan.com` |

**Current mobile version:** `1.0.20+26`  
**Config:** one repo-root `.env` (see `.env.example`). Do **not** create separate `.env` files under mobile/backend.

---

## Repository layout

```
Internship-Project/
├── .env / .env.example          # single secrets source
├── localink_mobile/             # Flutter app (Play / sideload)
├── localink_be/                 # API + SQL scripts
├── localink-website/            # Marketing + /invite + App Links
└── tests/localink_be.ReferralTests/
```

---

## Features (high level)

- Auth: email/password + Google Sign-In, JWT refresh, User Agreement consent
- Discovery: nearby businesses, favorites, For You, AI assistant, voice
- Owners: business registration, catalog, analytics, chat
- Admin: approvals, heatmap
- **Referral & community recognition (1.0.18):** short 6-char codes (e.g. `K7M2NP`), invite links, WhatsApp/share, successful-registration attribution only, Bronze/Silver/Gold milestones
- **Business sharing & community recommendation:** share one business or a snapshot of favorites via opaque links (`/share/business/{token}`, `/share/collection/{token}`); recipients view read-only lists and save to their own favorites

---

## Prerequisites

- Flutter SDK (see `localink_mobile/pubspec.yaml` SDK constraint)
- .NET 8 SDK
- Node.js 20+ (website)
- SQL Server (manager/production)
- Android release signing: `localink_mobile/android/key.properties` + keystore

---

## Environment

Copy `.env.example` → `.env` at the **repo root**. Mobile release builds pass values as `--dart-define`. Backend reads the same file via DotNetEnv.

Important keys:

| Key | Used by |
|-----|---------|
| `API_HOST` / `API_USE_HTTPS` | Mobile |
| `GOOGLE_WEB_CLIENT_ID` | Mobile (Web OAuth client — not Android client ID) |
| `GEOAPIFY_API_KEY` | Mobile / backend |
| Connection string / JWT / email / Groq / currency | Backend |

---

## Backend

### Run locally

```powershell
cd localink_be
dotnet run
```

### Schema patches (production-safe)

Idempotent scripts under `localink_be/Scripts/`. Also applied at API startup when possible.

| Script | Purpose |
|--------|---------|
| `EnsureUserConsentColumn.sql` | `users.consent_accepted` |
| `EnsureReferralSchema.sql` | referral columns + `referral_history` |
| `EnsureBusinessShareSchema.sql` | `business_shares` + `business_share_items` |
| `DiagnoseSchemaGaps.sql` | read-only gap report |

**Before relying on referrals in production:** run `EnsureReferralSchema.sql` on the manager SQL database (or restart API and confirm no referral schema warnings).

### Publish for manager

```powershell
cd localink_be
.\deploy\Publish-Backend.ps1
# optional: .\deploy\Publish-Backend.ps1 -CopyEnv
```

Output: `localink_be/publish/manager/`

Copy to the manager host (e.g. `C:\VocalForSanatan\api`), place `.env` next to `localink_be.dll`, run the process, keep SQL scripts available under `Scripts/`.

### Referral API (server-authoritative)

- Optional `referralCode` on `POST /api/v1/auth/register` and `POST /api/v1/auth/google` (new users only)
- `GET /api/v1/referral/me` — code, link, successful count, achievement (no client count writes)
- Config section `Referral` in `appsettings.json` (milestones + invite base URL)

---

## Mobile

### Debug

```powershell
cd localink_mobile
flutter pub get
flutter run `
  --dart-define=API_HOST=127.0.0.1:5138 `
  --dart-define=API_USE_HTTPS=false `
  --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

### Sideload / manager APK

```powershell
cd localink_mobile
.\scripts\build_from_env.ps1
# smoke with debug signing:
.\scripts\build_from_env.ps1 -AllowDebugSigning
```

### Play Store AAB (release signing required)

```powershell
cd localink_mobile
.\scripts\build_play_aab.ps1
```

Outputs typically under `localink_mobile/build/app/outputs/` or `build/manager-deploy/`.

### Google Sign-In SHA-1 (OAuth clients)

Play installs use the **Play App Signing** cert (not the upload keystore).

| Build | SHA-1 |
|-------|-------|
| Play Store | `ED:D8:12:09:F5:16:C1:88:B4:64:82:56:1B:5A:C5:9A:B0:4F:49:F5` |
| Upload / local release | `2D:A9:62:B5:59:B0:67:78:AE:2C:50:5D:04:37:02:F0:75:77:5D:5C` |
| Debug | `92:BB:BD:1C:6F:D4:B6:AF:57:FB:2C:AA:C3:F6:48:61:08:70:EB:C2` |

### Referral UX

- Profile → **Refer & Support** → `/refer-support`
- Invite links: `https://vocalforsanatan.com/invite?code=K7M2NP` (legacy `VFS-…` still accepted)
- Deep links: `vocalforsanatan://invite?code=…` + HTTPS App Links
- A referral counts **only after successful registration** (not WhatsApp send / link open alone)

### Tests

```powershell
cd localink_mobile
flutter test
```

```powershell
dotnet test tests\localink_be.ReferralTests\localink_be.ReferralTests.csproj
```

---

## Website

```powershell
cd localink-website
npm install
npm run dev
```

Deploy: Vercel project with **Root Directory** = `localink-website`, domain `vocalforsanatan.com`.

Important public paths:

| Path | Purpose |
|------|---------|
| `/download` | Play Store |
| `/invite?code=` | Referral landing |
| `/privacy`, `/support`, `/delete-account` | Play Console URLs |
| `/.well-known/assetlinks.json` | Android App Links (Play signing SHA-256) |

---

## Release checklist (share polish / 1.0.20)

1. Confirm share schema + backend already live (from 1.0.19).
2. Deploy website share pages (Install Referrer `utm_source=share` + clearer post-install copy).
3. Build AAB with release signing (`1.0.20+26`).
4. Upload AAB to Play Console.
5. Smoke: install from Play with share referrer → open app → shared list; Save All; create business registration prefill.

### Play Console — short notes

```
What's new in 1.0.20

• After install from a share link, the app tries to restore the shared list (best-effort via Play Install Referrer)
• Shared collections: Save All + Already in Favorites
• New business registration pre-fills contact/address from your profile (editable; never overwrites what you type)
• Share links remain recommendations — not referral invites
```

---

## Roles (app homes)

| `userType` | Home |
|------------|------|
| `admin` | `/admin-dashboard` |
| `businessowner` | `/business-dashboard` |
| `user` / `client` | `/home` |

---

## Safety notes

- Never commit `.env`, `key.properties`, or keystore passwords.
- Do not recreate auth, users table, or parallel backends for new features — extend existing systems.
- Prefer additive SQL (`Ensure*.sql`) over destructive migrations.
