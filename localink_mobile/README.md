# Localink Mobile

Flutter client for **Vocal for Sanatan / Localink**.

## Config (single `.env` at repo root)

There is **one** env file for the whole monorepo:

`Internship-Project/.env`  (template: `.env.example`)

Do **not** create `localink_mobile/.env` or `localink_be/.env`.

Mobile release builds read the root `.env` and pass values as `--dart-define`.
**Never** upload a Play Store build without these defines — the app will show “App build is misconfigured”.

```powershell
cd localink_mobile
# Manager / sideload APK:
.\scripts\build_from_env.ps1
# optional manager smoke APK with debug signing:
.\scripts\build_from_env.ps1 -AllowDebugSigning

# Play Store AAB (requires android/key.properties):
.\scripts\build_play_aab.ps1
# temporary ngrok-only emergency Play upload:
.\scripts\build_play_aab.ps1 -AllowEphemeralHost
```

Required root keys for mobile: `API_HOST`, `API_USE_HTTPS`, `GOOGLE_WEB_CLIENT_ID` (or `GOOGLE_CLIENT_ID`), `GEOAPIFY_API_KEY`.

`GOOGLE_WEB_CLIENT_ID` must be the **Web** OAuth client (same project as Android clients). Do not pass an Android client ID here.

### Google Sign-In (Android / Play Store)

Error `ApiException: 10` (`DEVELOPER_ERROR`) means package name + signing SHA-1 do not match an Android OAuth client in that Google Cloud project. Play Store installs are signed with the **Play App Signing** cert, not the upload keystore.

| Build | Package | SHA-1 to register |
|-------|---------|-------------------|
| Play Store | `com.vocalforsanatan.app` | `ED:D8:12:09:F5:16:C1:88:B4:64:82:56:1B:5A:C5:9A:B0:4F:49:F5` |
| Local release / upload key | same | `2D:A9:62:B5:59:B0:67:78:AE:2C:50:5D:04:37:02:F0:75:77:5D:5C` |
| Debug (`flutter run`) | same | `92:BB:BD:1C:6F:D4:B6:AF:57:FB:2C:AA:C3:F6:48:61:08:70:EB:C2` |

Create one Android OAuth client per SHA-1 if needed. Leave the existing Web client unchanged and keep using it as `GOOGLE_WEB_CLIENT_ID` / `serverClientId`.

## Local debug run

```powershell
cd localink_mobile
flutter pub get
flutter run `
  --dart-define=API_HOST=127.0.0.1:5138 `
  --dart-define=API_USE_HTTPS=false `
  --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

Also set `GOOGLE_WEB_CLIENT_ID` in `android/local.properties` (or use `.\scripts\build_from_env.ps1`) so Gradle can emit `R.string.default_web_client_id`.

Production / public builds should use a **stable** HTTPS API host (`API_HOST=api.vocalforsanatan.com`, `API_USE_HTTPS=true`) once DNS exists. Until then, Play uploads that point at free ngrok will break when the tunnel URL changes. Currency conversion uses `CURRENCY_CONVERTER_API_KEY` on the backend.

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
