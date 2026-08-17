# Shared release builder for localink_mobile (APK or Play Store AAB).
# Prefer build_from_env.ps1 or build_play_aab.ps1 — do not omit dart-defines.
#
# Examples:
#   .\scripts\build_release.ps1 -ApiHost "api.vocalforsanatan.com" -Target appbundle
#   .\scripts\build_release.ps1 -ApiHost "xxxx.ngrok-free.dev" -Target apk -AllowEphemeralHost
#   .\scripts\build_release.ps1 -ApiHost "192.168.1.10:5138" -UseHttps:$false -AllowInsecure -Target apk

param(
    [Parameter(Mandatory = $true)]
    [string]$ApiHost,

    [ValidateSet("apk", "appbundle")]
    [string]$Target = "apk",

    [bool]$UseHttps = $true,

    [switch]$AllowInsecure,

    [switch]$AllowDebugSigning,

    # Required for Play Store / public builds that use a temporary ngrok host.
    [switch]$AllowEphemeralHost,

    [string]$GeoapifyApiKey = "",

    [string]$GoogleWebClientId = "",

    # Optional — only used to reject accidental Android-client / Web-client swaps.
    [string]$GoogleAndroidClientId = ""
)

$ErrorActionPreference = "Stop"
$MobileRoot = Split-Path -Parent $PSScriptRoot
Set-Location $MobileRoot

if ([string]::IsNullOrWhiteSpace($ApiHost)) {
    throw "ApiHost is required (ngrok host, api.vocalforsanatan.com, or LAN host:port)."
}

$normalizedHost = $ApiHost.Trim().ToLowerInvariant()
$isLocal =
    $normalizedHost.StartsWith("127.0.0.1") -or
    $normalizedHost.StartsWith("localhost") -or
    $normalizedHost.StartsWith("10.0.2.2")
$isEphemeral =
    $normalizedHost -match '\.ngrok(-free)?\.(app|dev)$' -or
    $normalizedHost -match '\.loca\.lt$' -or
    $normalizedHost -match '\.trycloudflare\.com$'

if ($isLocal) {
    throw "Refuse to ship a release pointed at localhost ($ApiHost). Pass a public API_HOST."
}

if (-not $UseHttps -and -not $AllowInsecure) {
    throw "Release builds require -UseHttps:`$true (or -AllowInsecure for temporary LAN testing)."
}

if ($Target -eq "appbundle" -and $isEphemeral -and -not $AllowEphemeralHost) {
    throw "Play Store AAB refuses ephemeral host '$ApiHost'.`nSet a stable production host (API_HOST=api.vocalforsanatan.com) after DNS is configured,`nor pass -AllowEphemeralHost only for a temporary emergency Play upload."
}

if ([string]::IsNullOrWhiteSpace($GeoapifyApiKey)) {
    Write-Host "WARNING: GEOAPIFY_API_KEY is empty - maps/geocode features will fail." -ForegroundColor Yellow
}
if ([string]::IsNullOrWhiteSpace($GoogleWebClientId)) {
    throw "GOOGLE_WEB_CLIENT_ID is required for release builds (Web OAuth client, not Android)."
}
if (-not [string]::IsNullOrWhiteSpace($GoogleAndroidClientId) -and
    $GoogleWebClientId.Trim().Equals($GoogleAndroidClientId.Trim(), [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "GOOGLE_WEB_CLIENT_ID must be the Web OAuth client ID, not GOOGLE_ANDROID_CLIENT_ID."
}

$defines = @(
    "API_HOST=$ApiHost",
    "API_USE_HTTPS=$($UseHttps.ToString().ToLowerInvariant())"
)

if ($AllowInsecure -or -not $UseHttps) {
    $defines += "API_ALLOW_INSECURE=true"
}

if (-not [string]::IsNullOrWhiteSpace($GeoapifyApiKey)) {
    $defines += "GEOAPIFY_API_KEY=$GeoapifyApiKey"
}
$defines += "GOOGLE_WEB_CLIENT_ID=$GoogleWebClientId"
if (-not [string]::IsNullOrWhiteSpace($GoogleAndroidClientId)) {
    $defines += "GOOGLE_ANDROID_CLIENT_ID=$GoogleAndroidClientId"
}

$dartDefineArgs = @()
foreach ($d in $defines) {
    $dartDefineArgs += "--dart-define=$d"
}

$keyProps = Join-Path $MobileRoot "android\key.properties"
if ($AllowDebugSigning -or -not (Test-Path $keyProps)) {
    $env:ALLOW_DEBUG_RELEASE_SIGNING = "true"
    Write-Host "Using debug signing (set android/key.properties for store builds)." -ForegroundColor Yellow
} elseif ($Target -eq "appbundle") {
    Write-Host "Using release signing from android/key.properties" -ForegroundColor Green
}

# Gradle reads GOOGLE_WEB_CLIENT_ID for R.string.default_web_client_id (resValue).
# Dart --dart-define alone does not populate that native string resource.
$env:GOOGLE_WEB_CLIENT_ID = $GoogleWebClientId
if (-not [string]::IsNullOrWhiteSpace($GoogleAndroidClientId)) {
    $env:GOOGLE_ANDROID_CLIENT_ID = $GoogleAndroidClientId
}
$localProps = Join-Path $MobileRoot "android\local.properties"
$lines = @()
if (Test-Path $localProps) {
    $lines = Get-Content -LiteralPath $localProps | Where-Object {
        $_ -notmatch '^\s*GOOGLE_WEB_CLIENT_ID\s*=' -and
        $_ -notmatch '^\s*GOOGLE_ANDROID_CLIENT_ID\s*='
    }
}
$lines += "GOOGLE_WEB_CLIENT_ID=$GoogleWebClientId"
if (-not [string]::IsNullOrWhiteSpace($GoogleAndroidClientId)) {
    $lines += "GOOGLE_ANDROID_CLIENT_ID=$GoogleAndroidClientId"
}
# UTF-8 without BOM — a BOM breaks the first key in local.properties on some JDKs.
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($localProps, @($lines), $utf8NoBom)
Write-Host "Injected GOOGLE_WEB_CLIENT_ID into android/local.properties for native resValue" -ForegroundColor Green

Write-Host "==> Building release $Target" -ForegroundColor Cyan
Write-Host "    API_HOST      = $ApiHost"
Write-Host "    API_USE_HTTPS = $UseHttps"
Write-Host "    defines       = $($defines -join ', ')"

flutter pub get
if ($Target -eq "appbundle") {
    flutter build appbundle --release @dartDefineArgs
} else {
    flutter build apk --release @dartDefineArgs
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outDir = Join-Path $MobileRoot "build\manager-deploy"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

if ($Target -eq "appbundle") {
    $artifact = Join-Path $MobileRoot "build\app\outputs\bundle\release\app-release.aab"
    if (-not (Test-Path $artifact)) {
        throw "AAB not found at $artifact"
    }
    $dest = Join-Path $outDir "vocal-for-sanatan-$stamp.aab"
    Copy-Item $artifact $dest -Force
    Write-Host ""
    Write-Host "AAB ready: $dest" -ForegroundColor Green
    Write-Host "Upload this file in Play Console (Production or Internal testing)."
} else {
    $artifact = Join-Path $MobileRoot "build\app\outputs\flutter-apk\app-release.apk"
    if (-not (Test-Path $artifact)) {
        throw "APK not found at $artifact"
    }
    $dest = Join-Path $outDir "vocal-for-sanatan-$stamp.apk"
    Copy-Item $artifact $dest -Force
    Write-Host ""
    Write-Host "APK ready: $dest" -ForegroundColor Green
}

$scheme = if ($UseHttps) { 'https' } else { 'http' }
Write-Host "Install/test against: ${scheme}://$ApiHost"
Write-Host ""
Write-Host "Manual smoke tests:" -ForegroundColor Yellow
Write-Host "  1. Open app → login (must NOT show 'App build is misconfigured')"
Write-Host "  2. Kill app → reopen → still logged in"
Write-Host "  3. Browse home / business detail"
Write-Host "  4. Profile → display currency list loads"
Write-Host "  5. Logout → must require login again"
Write-Host ""
