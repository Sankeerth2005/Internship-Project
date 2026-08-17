# Build release APK/AAB from the SINGLE repo-root .env file.
# Usage (from localink_mobile or repo root):
#   .\scripts\build_from_env.ps1
#   .\scripts\build_from_env.ps1 -Target appbundle -AllowEphemeralHost
#   .\scripts\build_from_env.ps1 -AllowDebugSigning
#   .\scripts\build_from_env.ps1 -EnvFile "C:\path\to\.env"

param(
    [string]$EnvFile = "",
    [ValidateSet("apk", "appbundle")]
    [string]$Target = "apk",
    [string]$ApiHostOverride = "",
    [switch]$AllowDebugSigning,
    [switch]$AllowEphemeralHost
)

$ErrorActionPreference = "Stop"
$MobileRoot = Split-Path -Parent $PSScriptRoot
$RepoRoot = Split-Path -Parent $MobileRoot

if ([string]::IsNullOrWhiteSpace($EnvFile)) {
    $EnvFile = Join-Path $RepoRoot ".env"
}

if (-not (Test-Path $EnvFile)) {
    throw "Missing .env at '$EnvFile'. Copy .env.example to the repo root and fill production values."
}

function Get-DotEnvValue {
    param([string]$Path, [string]$Key)
    $line = Get-Content -LiteralPath $Path | Where-Object {
        $_ -match ("^\s*" + [regex]::Escape($Key) + "\s*=")
    } | Select-Object -First 1
    if (-not $line) { return "" }
    $value = ($line -split "=", 2)[1].Trim()
    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
    }
    return $value
}

$apiHost = $ApiHostOverride
if ([string]::IsNullOrWhiteSpace($apiHost)) {
    $apiHost = Get-DotEnvValue -Path $EnvFile -Key "API_HOST"
}
if ([string]::IsNullOrWhiteSpace($apiHost)) {
    $backendUrl = Get-DotEnvValue -Path $EnvFile -Key "BACKEND_API_URL"
    if (-not [string]::IsNullOrWhiteSpace($backendUrl)) {
        try {
            $uri = [Uri]$backendUrl
            $apiHost = if ($uri.IsDefaultPort) { $uri.Host } else { "$($uri.Host):$($uri.Port)" }
            if ([string]::IsNullOrWhiteSpace((Get-DotEnvValue -Path $EnvFile -Key "API_USE_HTTPS"))) {
                $script:inferredHttps = ($uri.Scheme -eq "https")
            }
        } catch {
            throw "BACKEND_API_URL is not a valid URL: $backendUrl"
        }
    }
}

if ([string]::IsNullOrWhiteSpace($apiHost)) {
    throw "Set API_HOST (preferred) or BACKEND_API_URL in the root .env"
}

$useHttpsRaw = Get-DotEnvValue -Path $EnvFile -Key "API_USE_HTTPS"
$useHttps = if (-not [string]::IsNullOrWhiteSpace($useHttpsRaw)) {
    $useHttpsRaw -match "^(1|true|yes)$"
} elseif ($null -ne $inferredHttps) {
    [bool]$inferredHttps
} else {
    $true
}

$allowInsecureRaw = Get-DotEnvValue -Path $EnvFile -Key "API_ALLOW_INSECURE"
$allowInsecure = $allowInsecureRaw -match "^(1|true|yes)$"

$geo = Get-DotEnvValue -Path $EnvFile -Key "GEOAPIFY_API_KEY"
$googleWeb = Get-DotEnvValue -Path $EnvFile -Key "GOOGLE_WEB_CLIENT_ID"
if ([string]::IsNullOrWhiteSpace($googleWeb)) {
    $googleWeb = Get-DotEnvValue -Path $EnvFile -Key "GOOGLE_CLIENT_ID"
}
$googleAndroid = Get-DotEnvValue -Path $EnvFile -Key "GOOGLE_ANDROID_CLIENT_ID"

$buildArgs = @{
    ApiHost               = $apiHost
    Target                = $Target
    UseHttps              = $useHttps
    GeoapifyApiKey        = $geo
    GoogleWebClientId     = $googleWeb
    GoogleAndroidClientId = $googleAndroid
}

if ($allowInsecure -or -not $useHttps) {
    $buildArgs.AllowInsecure = $true
}
if ($AllowDebugSigning) {
    $buildArgs.AllowDebugSigning = $true
}
if ($AllowEphemeralHost) {
    $buildArgs.AllowEphemeralHost = $true
}

Write-Host "==> Building $Target from env file: $EnvFile" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "build_release.ps1") @buildArgs
