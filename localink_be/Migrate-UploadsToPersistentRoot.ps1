<#
.SYNOPSIS
  Migrates legacy Vocal for Sanatan / Localink upload files into the persistent
  root C:\VocalForSanatan\uploads so DB paths like /uploads/... keep working.

.DESCRIPTION
  Copies (does not delete) files from common legacy locations into the target,
  preserving relative structure under uploads\ (businesses, avatars, catalogs,
  reviews, audio, misc, etc.).

  Safe to re-run: existing destination files are skipped unless -Force is set.

.EXAMPLE
  .\Migrate-UploadsToPersistentRoot.ps1
.EXAMPLE
  .\Migrate-UploadsToPersistentRoot.ps1 -DeployRoot "C:\inetpub\VocalForSanatan" -Force
#>
[CmdletBinding()]
param(
    [string]$TargetRoot = "C:\VocalForSanatan\uploads",
    [string]$DeployRoot = "",
    [switch]$Force,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        if ($WhatIf) {
            Write-Host "[WhatIf] Create directory $Path"
        } else {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
    }
}

function Copy-TreePreserve([string]$SourceRoot, [string]$Label) {
    if (-not (Test-Path -LiteralPath $SourceRoot)) {
        Write-Host "SKIP (missing): $Label -> $SourceRoot"
        return @{ Copied = 0; Skipped = 0; Missing = $true }
    }

    $copied = 0
    $skipped = 0
    $files = Get-ChildItem -LiteralPath $SourceRoot -Recurse -File -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $rel = $file.FullName.Substring($SourceRoot.TrimEnd('\', '/').Length).TrimStart('\', '/')
        $dest = Join-Path $TargetRoot $rel
        $destDir = Split-Path -Parent $dest
        Ensure-Dir $destDir

        if ((Test-Path -LiteralPath $dest) -and -not $Force) {
            $skipped++
            continue
        }

        if ($WhatIf) {
            Write-Host "[WhatIf] Copy $Label\$rel"
        } else {
            Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
        }
        $copied++
    }

    Write-Host "OK: $Label — copied $copied, skipped existing $skipped (from $SourceRoot)"
    return @{ Copied = $copied; Skipped = $skipped; Missing = $false }
}

Write-Host "=== Vocal for Sanatan upload migration ==="
Write-Host "Target: $TargetRoot"
Ensure-Dir $TargetRoot
foreach ($sub in @("businesses", "avatars", "catalogs", "reviews", "audio", "misc")) {
    Ensure-Dir (Join-Path $TargetRoot $sub)
}

# Candidate legacy roots. Each should be an "uploads" folder whose children
# mirror what DB relative paths expect after the /uploads/ prefix.
$candidates = [System.Collections.Generic.List[object]]::new()

$candidates.Add(@{ Label = "C:\VocalForSanatan\uploads (already target — no-op scan)"; Path = $TargetRoot; IsTarget = $true })
$candidates.Add(@{ Label = "C:\LocalinkUploads\uploads"; Path = "C:\LocalinkUploads\uploads"; IsTarget = $false })
$candidates.Add(@{ Label = "C:\LocalinkUploads"; Path = "C:\LocalinkUploads"; IsTarget = $false })
$candidates.Add(@{ Label = "C:\inetpub\wwwroot\uploads"; Path = "C:\inetpub\wwwroot\uploads"; IsTarget = $false })

if (-not [string]::IsNullOrWhiteSpace($DeployRoot)) {
    $candidates.Add(@{ Label = "Deploy wwwroot\uploads"; Path = (Join-Path $DeployRoot "wwwroot\uploads"); IsTarget = $false })
    $candidates.Add(@{ Label = "Deploy wwwroot\Uploads"; Path = (Join-Path $DeployRoot "wwwroot\Uploads"); IsTarget = $false })
    $candidates.Add(@{ Label = "Deploy uploads"; Path = (Join-Path $DeployRoot "uploads"); IsTarget = $false })
}

# Auto-discover recent publish folders under common parents
$searchParents = @(
    "C:\VocalForSanatan",
    "C:\inetpub",
    "C:\Services",
    "C:\Apps",
    "D:\VocalForSanatan"
)
foreach ($parent in $searchParents) {
    if (-not (Test-Path -LiteralPath $parent)) { continue }
    Get-ChildItem -LiteralPath $parent -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $wwwUploads = Join-Path $_.FullName "wwwroot\uploads"
        if (Test-Path -LiteralPath $wwwUploads) {
            $candidates.Add(@{
                Label = "Discovered $($_.Name)\wwwroot\uploads"
                Path = $wwwUploads
                IsTarget = $false
            })
        }
    }
}

$totalCopied = 0
$totalSkipped = 0
$seen = @{}

foreach ($c in $candidates) {
    $full = [System.IO.Path]::GetFullPath($c.Path)
    if ($c.IsTarget) {
        Write-Host "INFO: Target already set — leave files in place at $full"
        continue
    }
    if ($seen.ContainsKey($full.ToLowerInvariant())) { continue }
    $seen[$full.ToLowerInvariant()] = $true

    # If someone pointed LocalinkUploads (without \uploads) but content is already
    # under businesses/, copy as-is. If it contains an uploads\ child, prefer that.
    $source = $full
    $nested = Join-Path $full "uploads"
    if ((Test-Path -LiteralPath $nested) -and -not (Test-Path -LiteralPath (Join-Path $full "businesses"))) {
        $source = $nested
    }

    $result = Copy-TreePreserve -SourceRoot $source -Label $c.Label
    if (-not $result.Missing) {
        $totalCopied += $result.Copied
        $totalSkipped += $result.Skipped
    }
}

Write-Host ""
Write-Host "=== Done ==="
Write-Host "Copied: $totalCopied  |  Skipped existing: $totalSkipped"
Write-Host ""
Write-Host "Next steps on the manager server:"
Write-Host "  1. Confirm IIS / Windows service identity can Read+Write $TargetRoot"
Write-Host "  2. Set env UPLOADS_PATH=$TargetRoot (or leave appsettings default)"
Write-Host "  3. Restart the API process"
Write-Host "  4. Smoke-test: GET https://<api-host>/uploads/businesses/<known-file>"
Write-Host "  5. Only after verifying, optionally archive/delete old wwwroot\uploads folders"
