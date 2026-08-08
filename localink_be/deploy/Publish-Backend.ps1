# Publish localink_be for the manager server (folder run + free ngrok).
# No IIS, no Cloudflare, no reverse proxy — ngrok is the public edge.
#
# Usage:
#   .\deploy\Publish-Backend.ps1
#   .\deploy\Publish-Backend.ps1 -OutputDir "C:\VocalForSanatan\api" -CopyEnv

param(
    [string]$Configuration = "Release",
    [string]$OutputDir = "",
    [string]$Runtime = "win-x64",
    [switch]$CopyEnv
)

$ErrorActionPreference = "Stop"
$BeRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $BeRoot "localink_be.csproj"))) {
    $BeRoot = $PSScriptRoot
    if (-not (Test-Path (Join-Path $BeRoot "localink_be.csproj"))) {
        throw "Run this script from localink_be\deploy or ensure localink_be.csproj is reachable."
    }
}

$RepoRoot = Split-Path -Parent $BeRoot
$RootEnv = Join-Path $RepoRoot ".env"
$RootEnvExample = Join-Path $RepoRoot ".env.example"

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $BeRoot "publish\manager"
}

Write-Host "==> Publishing localink_be ($Configuration / $Runtime)" -ForegroundColor Cyan
Write-Host "    Project : $BeRoot"
Write-Host "    Output  : $OutputDir"
Write-Host "    Env src : $RootEnv"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

dotnet publish (Join-Path $BeRoot "localink_be.csproj") `
    -c $Configuration `
    -r $Runtime `
    --self-contained false `
    -o $OutputDir

if (Test-Path $RootEnvExample) {
    Copy-Item $RootEnvExample (Join-Path $OutputDir ".env.example") -Force
}

$envOut = Join-Path $OutputDir ".env"
if ($CopyEnv) {
    if (-not (Test-Path $RootEnv)) {
        throw "Cannot -CopyEnv: missing repo-root .env at $RootEnv"
    }
    Copy-Item $RootEnv $envOut -Force
    Write-Host "Copied root .env → $envOut" -ForegroundColor Yellow
} elseif (-not (Test-Path $envOut)) {
    Write-Host "No .env in output yet. Copy repo-root .env next to localink_be.dll." -ForegroundColor Yellow
}

$sqlScript = Join-Path $BeRoot "Scripts\EnsureRefreshTokensTable.sql"
if (Test-Path $sqlScript) {
    $scriptsOut = Join-Path $OutputDir "Scripts"
    New-Item -ItemType Directory -Force -Path $scriptsOut | Out-Null
    Copy-Item $sqlScript (Join-Path $scriptsOut "EnsureRefreshTokensTable.sql") -Force
}

Write-Host ""
Write-Host "Publish complete." -ForegroundColor Green
Write-Host ""
Write-Host "Manager PC runbook (ngrok FREE, no IIS):" -ForegroundColor Yellow
Write-Host "  1. Copy publish folder to C:\VocalForSanatan\api"
Write-Host "  2. Place the SINGLE root .env next to localink_be.dll"
Write-Host "  3. In a terminal:"
Write-Host "       `$env:ASPNETCORE_ENVIRONMENT='Development'   # or Production"
Write-Host "       `$env:ASPNETCORE_URLS='http://0.0.0.0:5138'"
Write-Host "       dotnet localink_be.dll"
Write-Host "  4. In a second terminal:  .\deploy\Start-Ngrok.ps1"
Write-Host "  5. Put the ngrok https HOST into root .env (API_HOST / BACKEND_API_URL) and rebuild the APK"
Write-Host "  6. Verify:  GET https://YOUR.ngrok-free.app/health"
Write-Host ""
Write-Host "GoDaddy: use for website / APK download forwarding only."
Write-Host "Free ngrok cannot serve api.vocalforsanatan.com (custom domains need paid ngrok)."
Write-Host ""
