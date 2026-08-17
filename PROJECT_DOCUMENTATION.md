# Vocal for Sanatan / Localink — Project Documentation

**Product:** Vocal for Sanatan (Localink)  
**Package ID:** `com.vocalforsanatan.app`  
**Marketing domain:** [vocalforsanatan.com](https://vocalforsanatan.com)  
**Repository:** Monorepo (`Internship-Project`)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [System Architecture](#2-system-architecture)
3. [Repository Structure](#3-repository-structure)
4. [Technology Stack](#4-technology-stack)
5. [Application Features](#5-application-features)
6. [User Roles & Routing](#6-user-roles--routing)
7. [Authentication](#7-authentication)
8. [Google Sign-In (Detailed)](#8-google-sign-in-detailed)
9. [Real-Time Communication (SignalR)](#9-real-time-communication-signalr)
10. [Backend API Overview](#10-backend-api-overview)
11. [Environment Configuration](#11-environment-configuration)
12. [Tools & Packages Reference](#12-tools--packages-reference)
13. [External Services & APIs](#13-external-services--apis)
14. [Local Development Setup](#14-local-development-setup)
15. [Build & Deployment](#15-build--deployment)
16. [Testing](#16-testing)
17. [Troubleshooting](#17-troubleshooting)

---

## 1. Executive Summary

**Vocal for Sanatan** (internally: **Localink**) is a local business discovery platform that connects consumers with community businesses. The product is delivered as a **three-part monorepo**:

| Component | Folder | Purpose |
|-----------|--------|---------|
| **Mobile App** | `localink_mobile/` | Flutter app for Android (Play Store) and iOS |
| **Backend API** | `localink_be/` | ASP.NET Core REST API + SignalR real-time layer |
| **Marketing Website** | `localink-website/` | Next.js site for landing, legal pages, and Play Store compliance |

**Key capabilities:** business search & discovery, maps, favorites, reviews, owner dashboards, admin tools, AI assistant (Groq), voice search, in-app chat, catalog management, analytics, and Google Sign-In.

---

## 2. System Architecture

```
┌─────────────────────────┐
│   Flutter Mobile App    │
│   (Android / iOS)       │
│   localink_mobile       │
└───────────┬─────────────┘
            │  HTTPS REST (Dio)
            │  WebSocket (SignalR)
            ▼
┌─────────────────────────┐       ┌──────────────────────┐
│   ASP.NET Core 8 API    │◄─────►│   SQL Server         │
│   localink_be           │       │   (LocalinkDb)       │
│   Port 5138 (local)     │       └──────────────────────┘
└───────────┬─────────────┘
            │
            │  External APIs
            ▼
┌───────────────────────────────────────────────────────┐
│ Google OAuth │ Geoapify │ Groq AI │ Currency API │ SMTP │
└───────────────────────────────────────────────────────┘

┌─────────────────────────┐
│   Next.js Website       │  (Marketing only — no API calls)
│   localink-website      │
│   Hosted on Vercel      │
└─────────────────────────┘
```

**Data flow (typical request):**

1. Mobile app sends authenticated request with JWT bearer token.
2. Backend validates token, queries SQL Server via Entity Framework Core.
3. Response returned as JSON (`{ success, data, message }` pattern).
4. Real-time events (notifications, chat) use SignalR hubs.

---

## 3. Repository Structure

```
Internship-Project/
├── .env.example              # Template for all environment variables
├── PROJECT_DOCUMENTATION.md  # This file
│
├── localink_mobile/          # Flutter mobile client
│   ├── lib/
│   │   ├── core/             # Config, auth, network, theme, validation
│   │   └── features/         # Feature modules (auth, business, admin, chat, ai, …)
│   ├── android/              # Android build config, signing, Gradle
│   ├── ios/                  # iOS build config
│   ├── scripts/              # PowerShell build scripts (APK, AAB)
│   └── test/                 # Unit & widget tests
│
├── localink_be/              # ASP.NET Core backend
│   ├── Controllers/          # REST API endpoints
│   ├── Services/             # Business logic
│   ├── Data/                 # EF Core DbContext & models
│   ├── Hubs/                 # SignalR hubs (chat, notifications)
│   ├── Models/               # DTOs, entities, enums
│   ├── deploy/               # Publish & ngrok scripts
│   └── Scripts/              # SQL migrations, smoke tests
│
└── localink-website/         # Next.js marketing site
    ├── src/app/              # App Router pages
    ├── src/components/       # Reusable UI components
    └── public/               # Static assets
```

---

## 4. Technology Stack

### Languages & Runtimes

| Technology | Version | Used in |
|------------|---------|---------|
| **Dart** | SDK ^3.12.2 | Mobile app |
| **Flutter** | Latest stable | Mobile framework |
| **C# / .NET** | 8.0 | Backend API |
| **TypeScript** | ^5.3 | Marketing website |
| **SQL Server** | Express / full | Database |

### Frameworks

| Framework | Component |
|-----------|-----------|
| Flutter + Riverpod | Mobile state management & UI |
| ASP.NET Core 8 | Backend REST API |
| Entity Framework Core 8 | ORM / database access |
| SignalR | Real-time notifications & chat |
| Next.js 15 | Marketing website (SSR/SSG) |
| Tailwind CSS | Website styling |

### Platforms & Hosting

| Platform | Purpose |
|----------|---------|
| **Google Play Store** | Android app distribution |
| **Vercel** | Website hosting |
| **GoDaddy** | Domain DNS (`vocalforsanatan.com`) |
| **ngrok** | Dev API tunnel (manager testing) |

---

## 5. Application Features

### Mobile App Features (`localink_mobile`)

| Feature | Module | Description |
|---------|--------|-------------|
| **Authentication** | `features/auth` | Email/password login, signup, Google Sign-In, OTP password reset |
| **Business Discovery** | `features/business` | Search, browse, map view, business details |
| **Favorites** | `features/business` | Save and manage favorite businesses |
| **Business Registration** | `features/business` | Owners register and manage their business |
| **Owner Dashboard** | `features/business` | Analytics, hours, photos, catalog for business owners |
| **Admin Dashboard** | `features/admin` | Platform management, approvals, heatmap, AI insights |
| **AI Assistant** | `features/ai` | Groq-powered business recommendations & chat |
| **Voice Search** | `features/business` | Speech-to-text business search |
| **In-App Chat** | `features/chat` | Real-time messaging between users and businesses |
| **Catalog Management** | `features/catalog` | Product/service catalog with currency conversion |
| **Profile & Settings** | `features/auth`, `features/profile` | User profile, change password, account deletion |
| **Offline Detection** | `core/network` | Connectivity banner when network unavailable |

### Backend Features (`localink_be`)

| Area | Controllers / Services |
|------|------------------------|
| Auth & sessions | `AuthController`, `AuthService` |
| User profiles | `UserController`, `UserService` |
| Business CRUD | `BusinessController`, `BusinessesController` |
| Categories & catalog | `CategoryController`, `CatalogController`, `SubcategoryController` |
| Reviews & favorites | `ReviewController`, `FavoritesController` |
| Location & geocoding | `BusinessLocationController`, `BusinessPincodeController` |
| Photos & uploads | `PhotoController`, `UploadStorageService` |
| AI & voice | `AIController`, `VoiceController`, `VoiceSearchController` |
| Chat | `ChatController`, `ChatHub` |
| Admin | `AdminController`, `AdminService` |
| Analytics | `AnalyticsController` |
| Currency | `CurrencyController` |
| Email | `EmailService` (MailKit) |
| Bulk import | `BulkImportService` (CSV/Excel) |

### Marketing Website (`localink-website`)

| Page | URL | Purpose |
|------|-----|---------|
| Landing | `/` | Product overview |
| Features | `/features` | Feature highlights |
| Business | `/business` | For business owners |
| About | `/about` | Company info |
| FAQ | `/faq` | Common questions |
| Contact | `/contact` | Contact form |
| Download | `/download` | App store links |
| Privacy Policy | `/privacy` | **Required by Google Play** |
| Terms of Service | `/terms` | Legal terms |
| Support | `/support` | **Required by Google Play** |
| Account Deletion | `/delete-account` | **Required by Google Play** |

---

## 6. User Roles & Routing

The app supports three primary account types. Routing is centralized in `localink_mobile/lib/core/auth/role_routes.dart`.

| API `userType` | Description | Default home route |
|----------------|-------------|-------------------|
| `admin` | Platform administrator | `/admin-dashboard` |
| `businessowner` | Business owner | `/business-dashboard` |
| `user` / `client` | Consumer / end user | `/home` |

**Post-login flow:**

1. User authenticates (email or Google).
2. If **new account** → `/continue-as` (choose Consumer or Business Owner experience).
3. If **existing account** → routed by role to the appropriate dashboard.

**Experience selection:** New users pick whether they want the consumer or business-owner experience. The backend validates and persists this via `select-experience` API.

---

## 7. Authentication

### Email / Password

| Step | Detail |
|------|--------|
| Register | `POST /api/v1/auth/register` — creates user with BCrypt-hashed password |
| Login | `POST /api/v1/auth/sessions` — returns JWT access token + refresh token |
| Refresh | `POST /api/v1/auth/refresh` — renews access token using refresh token |
| Logout | `POST /api/v1/auth/logout` — revokes refresh token |
| Forgot password | `POST /api/v1/auth/forgot-password` → OTP email → reset |

**Token storage (mobile):** JWT and refresh tokens stored in `flutter_secure_storage`.

**Token format:** JWT bearer tokens with claims for user ID, email, and account type. Configured via `JWT_SECRET_KEY`, `JWT_ISSUER`, `JWT_AUDIENCE` in `.env`.

### Session response shape

All successful auth endpoints return:

```json
{
  "success": true,
  "data": {
    "token": "<JWT access token>",
    "refreshToken": "<refresh token>",
    "expiresIn": 3600,
    "user": {
      "id": "123",
      "name": "John Doe",
      "email": "john@example.com",
      "userType": "user",
      "isNewUser": false
    }
  }
}
```

---

## 8. Google Sign-In (Detailed)

### Overview

Google Sign-In provides **passwordless login and signup** on the mobile app. Users tap **"Continue with Google"** (login) or **"Sign up with Google"** (signup). The app never stores Google passwords — it uses Google's OAuth flow and then issues our own JWT session tokens.

### Packages used

| Package | Platform | Purpose |
|---------|----------|---------|
| `google_sign_in` ^6.2.1 | Mobile (Flutter) | Google account picker + ID token |
| `Google.Apis.Auth` ^1.68.0 | Backend (.NET) | Validate Google ID tokens |
| `Microsoft.AspNetCore.Authentication.Google` ^8.0.7 | Backend (.NET) | Optional server-side Google OAuth |
| `flutter_secure_storage` | Mobile | Store JWT after sign-in |

### End-to-end flow

```
User taps "Continue with Google"
        │
        ▼
┌─────────────────────────┐
│  Flutter (google_sign_in)│  Opens Google account picker
│  GoogleSignInHelper      │  Scopes: email, profile, openid
└───────────┬─────────────┘
            │ Returns Google ID token (JWT)
            ▼
┌─────────────────────────┐
│  POST /api/v1/auth/google│  Body: { "idToken": "..." }
│  AuthRepository (Dio)   │
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│  AuthService             │  GoogleJsonWebSignature.ValidateAsync
│  Google.Apis.Auth        │  Checks email, name, picture, subject
└───────────┬─────────────┘
            │
     ┌──────┴──────┐
     │             │
  User exists   New user
     │             │
     │             └── Creates account (AccountType: "user",
     │                 AuthProvider: "google", profile picture)
     ▼
  Issue JWT + refresh token → store in secure storage → navigate home
```

### Key source files

| File | Purpose |
|------|---------|
| `localink_mobile/lib/core/auth/google_sign_in_helper.dart` | Google client setup + ID token fetch + error messages |
| `localink_mobile/lib/core/config/app_config.dart` | Reads `GOOGLE_WEB_CLIENT_ID` at build time |
| `localink_mobile/lib/features/auth/data/repositories/auth_repository.dart` | Calls `POST auth/google` |
| `localink_mobile/lib/features/auth/providers/auth_provider.dart` | Persists session after sign-in |
| `localink_mobile/lib/features/auth/presentation/screens/login_screen.dart` | "Continue with Google" button |
| `localink_mobile/lib/features/auth/presentation/screens/signup_screen.dart` | "Sign up with Google" button |
| `localink_mobile/android/app/build.gradle.kts` | Injects Web client ID into Android string resources |
| `localink_be/Services/Implementations/AuthService.cs` | `GoogleSignInAsync` — token validation + user creation |
| `localink_be/Controllers/AuthController.cs` | `POST google` endpoint |

### OAuth client configuration

Two types of OAuth clients are required in the **same Google Cloud project**:

| OAuth client type | How it is used |
|-------------------|----------------|
| **Web client** | Passed as `serverClientId` in Flutter so Google returns an ID token the backend can verify |
| **Android client(s)** | Matched automatically by package name + SHA-1 fingerprint (not passed in Dart code) |

**Android package name:** `com.vocalforsanatan.app`

**SHA-1 fingerprints (register in Google Cloud Console → Credentials):**

| Build type | SHA-1 |
|------------|-------|
| Play Store (App Signing cert) | `ED:D8:12:09:F5:16:C1:88:B4:64:82:56:1B:5A:C5:9A:B0:4F:49:F5` |
| Upload / local release keystore | `2D:A9:62:B5:59:B0:67:78:AE:2C:50:5D:04:37:02:F0:75:77:5D:5C` |
| Debug (`flutter run`) | `92:BB:BD:1C:6F:D4:B6:AF:57:FB:2C:AA:C3:F6:48:61:08:70:EB:C2` |

Create **one Android OAuth client per SHA-1** if needed. The Web client must **not** be replaced — keep using it as `GOOGLE_WEB_CLIENT_ID`.

### Mobile client setup (code)

```dart
GoogleSignIn(
  scopes: ['email', 'profile', 'openid'],
  serverClientId: GOOGLE_WEB_CLIENT_ID,  // Web OAuth client ID only
  signInOption: SignInOption.standard,
)
```

### Backend validation

**Endpoint:** `POST /api/v1/auth/google`

**Request:**
```json
{ "idToken": "<google-id-token-from-mobile>" }
```

**Validation steps (`AuthService.GoogleSignInAsync`):**

1. Read Google client IDs from configuration.
2. Validate ID token with `GoogleJsonWebSignature.ValidateAsync`.
3. Accept audiences: Web client, Android client, and optional explicit Web client ID.
4. Extract email, name, picture, and Google subject ID.

**User handling:**

| Scenario | Behavior |
|----------|----------|
| Email already registered | Log in existing user → return JWT (`isNewUser: false`) |
| New email | Auto-create user with `AuthProvider = "google"`, `AccountType = "user"` |
| First-time Google user | Response includes `isNewUser: true` → routed to Continue As screen |

### Build-time injection

Release builds read the root `.env` and inject Google client IDs at compile time:

1. PowerShell scripts read `GOOGLE_WEB_CLIENT_ID` from repo-root `.env`.
2. Pass as `--dart-define=GOOGLE_WEB_CLIENT_ID=...` to Flutter.
3. Write into `android/local.properties` for Gradle.
4. Gradle generates `R.string.default_web_client_id` for the native `google_sign_in` plugin.

```powershell
cd localink_mobile
.\scripts\build_from_env.ps1      # Manager APK
.\scripts\build_play_aab.ps1      # Play Store AAB
```

### Google Sign-In errors

| Error | Cause | Fix |
|-------|-------|-----|
| `ApiException: 10` (DEVELOPER_ERROR) | Package name or SHA-1 mismatch | Add Android OAuth client with correct SHA-1 in Google Cloud Console |
| Missing ID token | Wrong client ID used as `serverClientId` | Use **Web** client ID, not Android client ID |
| "Google authentication failed" | Backend rejected token | Ensure backend `GOOGLE_CLIENT_ID` matches Web client ID |
| User cancelled | User closed account picker | No action needed |

User-friendly error messages are implemented in `GoogleSignInHelper.friendlyError()`.

---

## 9. Real-Time Communication (SignalR)

The backend exposes two SignalR hubs for real-time features:

| Hub | Endpoint | Purpose |
|-----|----------|---------|
| `NotificationHub` | `/notifications` | Push notifications to users/admins |
| `ChatHub` | `/chat` | Real-time chat messages |

**Mobile client:** Uses `signalr_netcore` package. Connection authenticated via JWT passed as query string or header.

**Use cases:**
- Business approval notifications (admin → owner)
- New chat messages
- Dashboard live updates

---

## 10. Backend API Overview

**Base URL:** `https://<API_HOST>/api/v1/`  
**Swagger UI:** Available in Development at `/swagger`

### Auth endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/register` | Email registration |
| POST | `/auth/sessions` | Email login |
| POST | `/auth/google` | Google Sign-In |
| POST | `/auth/refresh` | Refresh access token |
| POST | `/auth/logout` | Revoke refresh token |
| POST | `/auth/forgot-password` | Send OTP |
| POST | `/auth/reset-password` | Reset with OTP |
| POST | `/auth/change-password` | Change password (authenticated) |
| POST | `/auth/select-experience` | Choose consumer vs owner experience |

### Core resource endpoints

| Resource | Base path |
|----------|-----------|
| Businesses | `/businesses`, `/business` |
| Categories | `/categories`, `/categories/{id}/subcategories` |
| Reviews | `/reviews` |
| Favorites | `/favorites` |
| Photos | `/business/{id}/photos` |
| Hours | `/business/{id}/hours` |
| Location | `/location` |
| Catalog | `/catalog` |
| Currency | `/currency` |
| AI | `/ai` |
| Voice / Search | `/voice`, `/search` |
| Chat | `/chat` |
| Admin | `/admin` |
| Analytics | `/analytics` |
| User profile | `/user` |
| Feedback | `/feedback` |
| Personalization | `/personalization` |

**Response pattern:**
```json
{ "success": true, "data": { ... } }
{ "success": false, "message": "Error description" }
```

---

## 11. Environment Configuration

There is **one** environment file for the entire monorepo:

```
Internship-Project/.env   (template: .env.example)
```

Do **not** create separate `.env` files inside `localink_mobile/` or `localink_be/`.

### Variable reference

| Variable | Used by | Purpose |
|----------|---------|---------|
| `API_HOST` | Mobile, Backend | Public API hostname (no scheme) |
| `API_USE_HTTPS` | Mobile | Whether mobile uses HTTPS |
| `API_ALLOW_INSECURE` | Mobile | Allow HTTP in release (LAN testing only) |
| `BACKEND_API_URL` | Scripts | Full backend URL with `/api` suffix |
| `CORS_ALLOWED_ORIGINS` | Backend | Allowed CORS origins (semicolon-separated) |
| `DB_CONNECTION_STRING` | Backend | SQL Server connection string |
| `JWT_SECRET_KEY` | Backend | JWT signing secret (min 32 chars) |
| `JWT_ISSUER` | Backend | JWT issuer claim |
| `JWT_AUDIENCE` | Backend | JWT audience claim |
| `JWT_EXPIRY_MINUTES` | Backend | Access token lifetime |
| `JWT_REFRESH_TOKEN_DAYS` | Backend | Refresh token lifetime |
| `GOOGLE_WEB_CLIENT_ID` | Mobile, Backend | Web OAuth client ID |
| `GOOGLE_CLIENT_ID` | Backend | Primary Google client (fallback) |
| `GOOGLE_CLIENT_SECRET` | Backend | Google OAuth secret |
| `GOOGLE_ANDROID_CLIENT_ID` | Backend | Android OAuth client (optional audience) |
| `GEOAPIFY_API_KEY` | Mobile, Backend | Geocoding / maps |
| `GROQ_API_KEY` | Backend | AI assistant (Groq LLM) |
| `CURRENCY_CONVERTER_API_KEY` | Backend | Currency conversion |
| `COUNTRY_CSC_API_KEY` | Backend | Country/state/city data |
| `EMAIL_HOST` | Backend | SMTP server |
| `EMAIL_PORT` | Backend | SMTP port |
| `EMAIL_USERNAME` | Backend | SMTP username |
| `EMAIL_PASSWORD` | Backend | SMTP password |
| `EMAIL_FROM` | Backend | Sender address |
| `ADMIN_EMAIL` | Backend | Admin notification recipient |
| `UPLOADS_PATH` | Backend | File upload directory |

---

## 12. Tools & Packages Reference

### Mobile — Production dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `go_router` | Navigation / routing |
| `dio` | HTTP API client |
| `google_sign_in` | Google OAuth |
| `flutter_secure_storage` | Secure token storage |
| `shared_preferences` | Local preferences |
| `json_annotation` | JSON model annotations |
| `maplibre_gl` | Maps |
| `geolocator` | GPS / location |
| `signalr_netcore` | Real-time (SignalR) |
| `connectivity_plus` | Network status |
| `speech_to_text` | Voice input |
| `flutter_tts` | Text-to-speech |
| `record` / `audioplayers` | Audio record & playback |
| `camera` / `image_picker` / `file_picker` | Media capture & upload |
| `cached_network_image` | Image caching |
| `fl_chart` | Charts / analytics UI |
| `intl` | Date/number formatting |
| `url_launcher` | External links |
| `permission_handler` | Device permissions |
| `sensors_plus` | Device sensors |
| `path_provider` / `cross_file` | File system |

### Mobile — Dev dependencies

| Package | Purpose |
|---------|---------|
| `flutter_test` | Unit & widget tests |
| `flutter_lints` | Lint rules |
| `build_runner` | Code generation |
| `json_serializable` | JSON serialization codegen |

### Backend — NuGet packages

| Package | Purpose |
|---------|---------|
| ASP.NET Core 8 | Web API framework |
| `Microsoft.EntityFrameworkCore` + SqlServer | ORM |
| `Microsoft.EntityFrameworkCore.SqlServer.NetTopologySuite` | Geo queries |
| `Microsoft.AspNetCore.Authentication.JwtBearer` | JWT auth |
| `Microsoft.AspNetCore.Authentication.Google` | Google OAuth |
| `Google.Apis.Auth` | Google ID token validation |
| `BCrypt.Net-Next` | Password hashing |
| `System.IdentityModel.Tokens.Jwt` | JWT tokens |
| `MailKit` / `MimeKit` | Email |
| `SixLabors.ImageSharp` | Image processing |
| `EPPlus` | Excel export |
| `CsvHelper` | CSV import/export |
| `DotNetEnv` | `.env` loading |
| `Newtonsoft.Json` | JSON |
| `Swashbuckle.AspNetCore` | Swagger / API docs |
| `NetTopologySuite` | Geographic data |
| `dotnet-ef` (CLI tool) | EF Core migrations |

### Website — npm packages

| Package | Purpose |
|---------|---------|
| `next` ^15 | React framework |
| `react` / `react-dom` ^18 | UI library |
| `typescript` | Type safety |
| `tailwindcss` | CSS framework |
| `postcss` / `autoprefixer` | CSS processing |
| `lucide-react` | Icons |
| `clsx` / `tailwind-merge` | CSS utilities |
| `eslint` + `eslint-config-next` | Linting |

### Build & DevOps tools

| Tool | Purpose |
|------|---------|
| PowerShell scripts | APK/AAB build, backend publish, ngrok |
| Gradle (Kotlin DSL) | Android builds |
| Flutter CLI | Mobile build & test |
| dotnet CLI | Backend build & run |
| npm | Website dependencies |
| Git / GitHub | Source control |
| ProGuard/R8 | Android release code shrinking |
| ngrok | Dev API tunnel |

---

## 13. External Services & APIs

| Service | Purpose | Config key |
|---------|---------|------------|
| **Google OAuth** | Sign-in (Web + Android clients) | `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_CLIENT_ID` |
| **Google Play Store** | Android distribution | Play Console |
| **Geoapify** | Geocoding, pincode validation, maps | `GEOAPIFY_API_KEY` |
| **Groq API** | AI assistant / business recommendations | `GROQ_API_KEY` |
| **Currency Converter API** | Multi-currency catalog | `CURRENCY_CONVERTER_API_KEY` |
| **Country State City API** | Location dropdown data | `COUNTRY_CSC_API_KEY` |
| **Gmail SMTP** | Transactional email (OTP, welcome) | `EMAIL_*` vars |
| **Vercel** | Website hosting | Vercel dashboard |
| **GoDaddy** | Domain DNS | GoDaddy DNS panel |
| **ngrok** | Dev API public tunnel | `Start-Ngrok.ps1` |
| **SQL Server** | Primary database | `DB_CONNECTION_STRING` |

---

## 14. Local Development Setup

### Prerequisites

| Tool | Install |
|------|---------|
| Flutter SDK | [flutter.dev](https://flutter.dev) |
| .NET 8 SDK | [dotnet.microsoft.com](https://dotnet.microsoft.com) |
| Node.js 20+ | [nodejs.org](https://nodejs.org) |
| SQL Server Express | LocalDB or SQLEXPRESS |
| Android Studio | For Android emulator / SDK |
| Git | Source control |

### Step 1 — Clone & configure environment

```powershell
git clone https://github.com/Sankeerth2005/Internship-Project.git
cd Internship-Project
copy .env.example .env
# Edit .env with your values (DB, Google, API keys)
```

### Step 2 — Start the backend

```powershell
cd localink_be
dotnet restore
dotnet run
# API runs at http://localhost:5138
# Swagger at http://localhost:5138/swagger
```

### Step 3 — Run the mobile app

```powershell
cd localink_mobile
flutter pub get
flutter run `
  --dart-define=API_HOST=127.0.0.1:5138 `
  --dart-define=API_USE_HTTPS=false `
  --dart-define=GOOGLE_WEB_CLIENT_ID=<your-web-client-id>.apps.googleusercontent.com
```

Set `GOOGLE_WEB_CLIENT_ID` in `android/local.properties` (or use `.\scripts\build_from_env.ps1`) so Gradle emits the native string resource.

### Step 4 — Run the website

```bash
cd localink-website
npm install
npm run dev
# Open http://localhost:3000
```

### Manager testing with ngrok

```powershell
cd localink_be
.\deploy\Publish-Backend.ps1 -CopyEnv
# Run published exe, then:
.\deploy\Start-Ngrok.ps1
# Update .env API_HOST with the printed ngrok host
```

---

## 15. Build & Deployment

### Mobile — Manager APK (sideload)

```powershell
cd localink_mobile
.\scripts\build_from_env.ps1
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Mobile — Play Store AAB

```powershell
cd localink_mobile
# Requires android/key.properties with signing keystore
.\scripts\build_play_aab.ps1
# Output: build/app/outputs/bundle/release/app-release.aab
```

**Required build defines:** `API_HOST`, `API_USE_HTTPS`, `GOOGLE_WEB_CLIENT_ID`, `GEOAPIFY_API_KEY`

Production builds should use a **stable HTTPS API host**. Free ngrok URLs change and will break Play Store installs.

### Backend — Manager server publish

```powershell
cd localink_be
.\deploy\Publish-Backend.ps1 -CopyEnv
# Output: localink_be/publish/manager/
# Run: .\localink_be.exe (with .env beside the DLL)
```

### Website — Vercel deployment

1. Push code to GitHub.
2. Import project in [Vercel](https://vercel.com).
3. Set **Root Directory** to `localink-website`.
4. Connect domain `vocalforsanatan.com` (GoDaddy DNS → Vercel).

See `localink-website/README.md` for full DNS setup.

### Google Play Console URLs

| Field | URL |
|-------|-----|
| Privacy policy | `https://vocalforsanatan.com/privacy` |
| Support | `https://vocalforsanatan.com/support` |
| Account deletion | `https://vocalforsanatan.com/delete-account` |

---

## 16. Testing

### Mobile tests

```powershell
cd localink_mobile
flutter test
```

Tests include role routing (`test/core/auth/role_routes_test.dart`) and widget tests.

### Backend smoke test

```powershell
cd localink_be
.\Scripts\e2e_api_smoke.ps1
```

### Manual test checklist

- [ ] Email registration and login
- [ ] Google Sign-In (login + new user signup)
- [ ] Password reset via OTP
- [ ] Business search and detail view
- [ ] Favorites add/remove
- [ ] Business owner registration and dashboard
- [ ] Admin dashboard and business approval
- [ ] AI assistant chat
- [ ] Voice search
- [ ] In-app chat (real-time)
- [ ] Offline banner when network disconnected
- [ ] Token refresh after access token expiry

---

## 17. Troubleshooting

### Mobile

| Issue | Solution |
|-------|----------|
| "App build is misconfigured" | Rebuild with `--dart-define=API_HOST=...` and `API_USE_HTTPS=true` |
| Google Sign-In error 10 | Register Android OAuth client with correct SHA-1 |
| Black screen on launch | Check `AppConfig.assertReleaseReady()` — missing dart-defines |
| API connection refused | Verify backend is running and `API_HOST` is correct |
| Maps not loading | Set `GEOAPIFY_API_KEY` in build defines |

### Backend

| Issue | Solution |
|-------|----------|
| Database connection failed | Check `DB_CONNECTION_STRING` in `.env` |
| JWT validation failed | Ensure `JWT_SECRET_KEY` matches between restarts |
| Google auth failed | Verify `GOOGLE_CLIENT_ID` matches Web client ID |
| CORS errors | Add origin to `CORS_ALLOWED_ORIGINS` |
| Uploads not persisting | Check `UPLOADS_PATH` exists and is writable |

### Website

| Issue | Solution |
|-------|----------|
| 404 on deploy | Set Vercel Root Directory to `localink-website` |
| Domain not resolving | Verify GoDaddy DNS A/CNAME records point to Vercel |

---

## Appendix — Quick Reference Card

```
Product:     Vocal for Sanatan (Localink)
Package:     com.vocalforsanatan.app
Domain:      vocalforsanatan.com
API prefix:  /api/v1/
Database:    SQL Server (LocalinkDb)
Auth:        JWT + Google Sign-In
Real-time:   SignalR (/notifications, /chat)
AI:          Groq API
Maps:        Geoapify + MapLibre GL
Env file:    Internship-Project/.env (single source of truth)
```

---

*Last updated: August 2026*
