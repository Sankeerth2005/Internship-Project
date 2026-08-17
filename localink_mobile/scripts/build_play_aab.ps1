# Build a Play Store AAB from the repo-root .env (requires release signing).
# Usage (from localink_mobile or repo root):
#   .\scripts\build_play_aab.ps1
#   .\scripts\build_play_aab.ps1 -AllowEphemeralHost   # temporary ngrok only
#   .\scripts\build_play_aab.ps1 -ApiHost "api.vocalforsanatan.com"

param(
    [string]$EnvFile = "",
    [string]$ApiHost = "",
    [switch]$AllowEphemeralHost
)

$ErrorActionPreference = "Stop"
$MobileRoot = Split-Path -Parent $PSScriptRoot
$RepoRoot = Split-Path -Parent $MobileRoot

if ([string]::IsNullOrWhiteSpace($EnvFile)) {
    $EnvFile = Join-Path $RepoRoot ".env"
}

$keyProps = Join-Path $MobileRoot "android\key.properties"
if (-not (Test-Path $keyProps)) {
    throw "Missing android/key.properties. Copy android/key.properties.example and fill release signing secrets before Play upload."
}

& (Join-Path $PSScriptRoot "build_from_env.ps1") `
    -EnvFile $EnvFile `
    -Target appbundle `
    -ApiHostOverride $ApiHost `
    -AllowEphemeralHost:$AllowEphemeralHost
