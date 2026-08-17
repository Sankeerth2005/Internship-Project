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

$buildArgs = @{
    ApiHost           = $ApiHost
    Target            = "apk"
    UseHttps          = $UseHttps
    GeoapifyApiKey    = $GeoapifyApiKey
    GoogleWebClientId = $GoogleWebClientId
    AllowEphemeralHost = $true
}

if ($AllowInsecure) { $buildArgs.AllowInsecure = $true }
if ($AllowDebugSigning) { $buildArgs.AllowDebugSigning = $true }

& (Join-Path $PSScriptRoot "build_release.ps1") @buildArgs
