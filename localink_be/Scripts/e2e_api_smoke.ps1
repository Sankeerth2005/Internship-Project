# End-to-end API smoke tests against a running localink_be instance.
# Usage:
#   .\scripts\e2e_api_smoke.ps1
#   .\scripts\e2e_api_smoke.ps1 -BaseUrl "https://api.vocalforsanatan.com"
#   .\scripts\e2e_api_smoke.ps1 -BaseUrl "https://xxxx.ngrok-free.dev"

param(
    [string]$BaseUrl = "http://127.0.0.1:5138"
)

$ErrorActionPreference = "Stop"
$BaseUrl = $BaseUrl.TrimEnd("/")
$script:passed = 0
$script:failed = 0

function Assert-Http {
    param(
        [string]$Name,
        [string]$Method = "GET",
        [string]$Path,
        [hashtable]$Headers = @{},
        [object]$Body = $null,
        [int[]]$ExpectStatus = @(200),
        [scriptblock]$BodyCheck = $null
    )
    $uri = "$BaseUrl$Path"
    # Free ngrok shows an interstitial HTML page unless this header is present.
    if (-not $Headers.ContainsKey("ngrok-skip-browser-warning")) {
        $Headers["ngrok-skip-browser-warning"] = "1"
    }
    try {
        $params = @{
            Uri             = $uri
            Method          = $Method
            Headers         = $Headers
            UseBasicParsing = $true
            TimeoutSec      = 30
        }
        if ($null -ne $Body) {
            $params.ContentType = "application/json"
            $params.Body = ($Body | ConvertTo-Json -Depth 8 -Compress)
        }
        $resp = Invoke-WebRequest @params
        $code = [int]$resp.StatusCode
        $ok = $ExpectStatus -contains $code
        if ($ok -and $BodyCheck) {
            $ok = & $BodyCheck $resp.Content
        }
        if ($ok) {
            Write-Host ("PASS  {0} ({1})" -f $Name, $code) -ForegroundColor Green
            $script:passed++
        } else {
            $snippet = $resp.Content
            if ($snippet.Length -gt 200) { $snippet = $snippet.Substring(0, 200) }
            Write-Host ("FAIL  {0} status={1} body={2}" -f $Name, $code, $snippet) -ForegroundColor Red
            $script:failed++
        }
    } catch {
        $code = $null
        if ($_.Exception.Response) {
            $code = [int]$_.Exception.Response.StatusCode
        }
        if ($null -ne $code -and ($ExpectStatus -contains $code)) {
            Write-Host ("PASS  {0} ({1} expected-error)" -f $Name, $code) -ForegroundColor Green
            $script:passed++
        } else {
            Write-Host ("FAIL  {0} - {1}" -f $Name, $_.Exception.Message) -ForegroundColor Red
            $script:failed++
        }
    }
}

Write-Host ("E2E API smoke against {0}" -f $BaseUrl) -ForegroundColor Cyan

Assert-Http -Name "GET /health" -Path "/health" -BodyCheck { param($c) $c -match "Healthy|healthy|ok" }
Assert-Http -Name "GET /health/ready" -Path "/health/ready" -ExpectStatus @(200, 503)

Assert-Http -Name "GET categories" -Path "/api/v1/categories"
Assert-Http -Name "GET businesses discovery" -Path "/api/v1/businesses?page=1&pageSize=5"

Assert-Http -Name "Login validation empty" -Method POST -Path "/api/v1/auth/sessions" `
    -Body @{ email = ""; password = "" } `
    -ExpectStatus @(400, 401, 422)

Assert-Http -Name "Login bad credentials" -Method POST -Path "/api/v1/auth/sessions" `
    -Body @{ email = "nobody@example.com"; password = "WrongPass1!" } `
    -ExpectStatus @(400, 401)

Assert-Http -Name "Register validation weak" -Method POST -Path "/api/v1/auth/register" `
    -Body @{
        name           = "A"
        email          = "bad"
        password       = "123"
        phone          = "1"
        accountType    = "client"
    } -ExpectStatus @(400, 422)

Assert-Http -Name "Google auth without token" -Method POST -Path "/api/v1/auth/google" `
    -Body @{ idToken = "" } -ExpectStatus @(400, 401, 422)

Assert-Http -Name "Forgot password validation" -Method POST -Path "/api/v1/auth/forgot-password" `
    -Body @{ email = "not-an-email" } -ExpectStatus @(400, 422)

Assert-Http -Name "Unauthorized profile" -Path "/api/v1/user/profile" -ExpectStatus @(401)

Write-Host ""
Write-Host ("Passed: {0}  Failed: {1}" -f $script:passed, $script:failed) -ForegroundColor $(if ($script:failed -eq 0) { "Green" } else { "Red" })
if ($script:failed -gt 0) { exit 1 }
