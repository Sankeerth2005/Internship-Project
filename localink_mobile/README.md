# Localink Mobile

Flutter client for **Vocal for Sanatan / Localink**.

## Config (single `.env` at repo root)

There is **one** env file for the whole monorepo:

`Internship-Project/.env`  (template: `.env.example`)

Do **not** create `localink_mobile/.env` or `localink_be/.env`.

Mobile release builds read the root `.env` and pass values as `--dart-define`:

```powershell
cd localink_mobile
.\scripts\build_from_env.ps1
# optional manager smoke APK with debug signing:
.\scripts\build_from_env.ps1 -AllowDebugSigning
```

Required root keys for mobile: `API_HOST`, `API_USE_HTTPS`, `GOOGLE_WEB_CLIENT_ID` (or `GOOGLE_CLIENT_ID`), `GEOAPIFY_API_KEY`.

## Local debug run

```powershell
cd localink_mobile
flutter pub get
flutter run `
  --dart-define=API_HOST=127.0.0.1:5138 `
  --dart-define=API_USE_HTTPS=false `
  --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

Production / public builds must use `https://api.vocalforsanatan.com` (`API_HOST=api.vocalforsanatan.com`, `API_USE_HTTPS=true`). Currency conversion uses `CURRENCY_CONVERTER_API_KEY` on the backend.

## Architecture

| Layer | Location |
|--------|----------|
| Feature UI | `lib/features/*/presentation` |
| Repositories | `lib/features/*/data/repositories` |
| Shared theme / validators | `lib/core/theme`, `lib/core/validation` |
| Role routing | `lib/core/auth/role_routes.dart` |

## Tests

```bash
cd localink_mobile
flutter test
```

## Roles

| API `userType` | App home |
|----------------|----------|
| `admin` | `/admin-dashboard` |
| `businessowner` | `/business-dashboard` |
| `client` | `/home` |
