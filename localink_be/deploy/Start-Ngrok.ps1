# Start free ngrok tunnel to localink_be (no IIS / no Cloudflare / no reverse proxy).
# Prerequisites: ngrok installed + authtoken already configured (ngrok config add-authtoken ...)
#
# Usage (manager PC via AnyDesk):
#   1. Start API:  ASPNETCORE_URLS=http://0.0.0.0:5138  dotnet localink_be.dll
#   2. Run:        .\deploy\Start-Ngrok.ps1
#   3. Copy the https host into repo-root .env:
#        BACKEND_API_URL=https://YOUR-DEV-DOMAIN.ngrok-free.app/api
#        API_HOST=YOUR-DEV-DOMAIN.ngrok-free.app
#        API_USE_HTTPS=true
#        API_ALLOW_INSECURE=false
#   4. Rebuild mobile:  ..\localink_mobile\scripts\build_from_env.ps1
#
# GoDaddy domain (vocalforsanatan.com) cannot point at free ngrok as a real API host.
# Free plan only allows your assigned *.ngrok-free.app / *.ngrok-free.dev domain.
# Use GoDaddy for marketing / Play Store / APK download forwarding only.

param(
    [int]$Port = 5138,
    [string]$NgrokPath = "ngrok"
)

$ErrorActionPreference = "Stop"

Write-Host "Starting ngrok FREE tunnel -> http://127.0.0.1:$Port" -ForegroundColor Cyan
Write-Host "Keep this window open. Mobile/API public URL = the https://*.ngrok-free.* host shown below."
Write-Host ""
Write-Host "Reminder:" -ForegroundColor Yellow
Write-Host "  - Free ngrok = 1 assigned dev domain only (NOT api.vocalforsanatan.com)."
Write-Host "  - Custom GoDaddy hostnames on ngrok require a paid ngrok plan + DNS CNAME."
Write-Host "  - No IIS / Cloudflare needed: ngrok talks directly to the API on :$Port."
Write-Host ""

& $NgrokPath http $Port --request-header-add "ngrok-skip-browser-warning:1"
