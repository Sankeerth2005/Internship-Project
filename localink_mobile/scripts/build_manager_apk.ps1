# Build a manager-server test APK for localink_mobile.
# Usage (from localink_mobile):
#   .\scripts\build_manager_apk.ps1 -ApiHost "xxxx.ngrok-free.dev"
#   .\scripts\build_manager_apk.ps1 -ApiHost "api.vocalforsanatan.com"
#   .\scripts\build_manager_apk.ps1 -ApiHost "192.168.1.10:5138" -UseHttps:$false -AllowInsecure

param(
    [Parameter(Mandatory = $true)]
    [string]$ApiHost,

    [bool]$UseHttps = $true,

    [switch]$AllowInsecure,

    [switch]$AllowDebugSigning,

    [string]$GeoapifyApiKey = "",

    [string]$GoogleWebClientId = ""
)

$ErrorActionPreference = "Stop"
$MobileRoot = Split-Path -Parent $PSScriptRoot
Set-Location $MobileRoot

if ([string]::IsNullOrWhiteSpace($ApiHost)) {
    throw "ApiHost is required (ngrok host, api.vocalforsanatan.com, or LAN host:port)."
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
if (-not [string]::IsNullOrWhiteSpace($GoogleWebClientId)) {
    $defines += "GOOGLE_WEB_CLIENT_ID=$GoogleWebClientId"
}

$dartDefineArgs = @()
foreach ($d in $defines) {
    $dartDefineArgs += "--dart-define=$d"
}

if ($AllowDebugSigning -or -not (Test-Path (Join-Path $MobileRoot "android\key.properties"))) {
    $env:ALLOW_DEBUG_RELEASE_SIGNING = "true"
    Write-Host "Using debug signing for this manager test APK (set key.properties for store builds)." -ForegroundColor Yellow
}

Write-Host "==> Building release APK" -ForegroundColor Cyan
Write-Host "    API_HOST      = $ApiHost"
Write-Host "    API_USE_HTTPS = $UseHttps"
Write-Host "    defines       = $($defines -join ', ')"

flutter pub get
flutter build apk --release @dartDefineArgs

$apk = Join-Path $MobileRoot "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apk)) {
    throw "APK not found at $apk"
}

$outDir = Join-Path $MobileRoot "build\manager-deploy"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$dest = Join-Path $outDir "vocal-for-sanatan-$stamp.apk"
Copy-Item $apk $dest -Force

Write-Host ""
Write-Host "APK ready: $dest" -ForegroundColor Green
Write-Host "Install on a device that can reach: $([string]::Concat($(if ($UseHttps) {'https'} else {'http'}), '://', $ApiHost))"
Write-Host ""
Write-Host "Manual smoke tests:" -ForegroundColor Yellow
Write-Host "  1. Open app → login"
Write-Host "  2. Kill app → reopen → still logged in"
Write-Host "  3. Browse home / business detail"
Write-Host "  4. Profile → display currency list loads all FX currencies"
Write-Host "  5. Logout → must require login again"
Write-Host ""
