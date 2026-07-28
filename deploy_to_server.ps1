# Deployment Script for VocalForSanatan Backend
# This script deploys the publish_be folder to your server

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerIP,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$RemotePath,  # e.g., "C:\inetpub\VocalForSanatan" or "/home/username/VocalForSanatan"
    
    [Parameter(Mandatory=$false)]
    [string]$Password = "",  # Leave empty to use SSH key
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 22
)

# Local paths
$localPublishPath = "localink_be\publish_be"
$localEnvPath = "localink_be\.env"

# Remote paths
$remotePublishPath = "$RemotePath\publish_be"
$remoteUploadsPath = "$RemotePath\Uploads"

Write-Host "=== VocalForSanatan Backend Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Validate local paths exist
if (-not (Test-Path $localPublishPath)) {
    Write-Host "ERROR: Local publish_be folder not found at: $localPublishPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $localEnvPath)) {
    Write-Host "WARNING: Local .env file not found at: $localEnvPath" -ForegroundColor Yellow
    Write-Host "Make sure to configure environment variables on the server!" -ForegroundColor Yellow
}

# Create SSH command
if ($Password -eq "") {
    $sshCommand = "ssh -p $Port $Username@$ServerIP"
} else {
    # Use sshpass if password is provided (requires sshpass installation)
    $sshCommand = "sshpass -p '$Password' ssh -p $Port $Username@$ServerIP"
}

Write-Host "Step 1: Creating remote directory structure..." -ForegroundColor Green
$createDirsCommand = @"
mkdir -p `"$RemotePath`"
mkdir -p `"$remoteUploadsPath`"
"@

if ($OperatingSystem -eq "Windows") {
    $createDirsCommand = @"
if (-not (Test-Path `"$RemotePath`")) { New-Item -ItemType Directory -Path `"$RemotePath`" -Force }
if (-not (Test-Path `"$remoteUploadsPath`")) { New-Item -ItemType Directory -Path `"$remoteUploadsPath`" -Force }
"@
}

Invoke-Expression "$sshCommand `"$createDirsCommand`""

Write-Host "Step 2: Uploading publish_be folder..." -ForegroundColor Green

if ($OperatingSystem -eq "Windows") {
    # Use WinSCP or similar for Windows
    Write-Host "Please manually copy the publish_be folder to: $remotePublishPath" -ForegroundColor Yellow
    Write-Host "Or use WinSCP/FileZilla to upload the folder" -ForegroundColor Yellow
} else {
    # Use rsync for Linux/Mac
    $rsyncCommand = "rsync -avz --progress $localPublishPath/ $Username@$ServerIP`:$remotePublishPath/"
    Invoke-Expression $rsyncCommand
}

Write-Host "Step 3: Setting up Uploads folder permissions..." -ForegroundColor Green
$setPermissionsCommand = @"
chmod 755 `"$remoteUploadsPath`"
"@

Invoke-Expression "$sshCommand `"$setPermissionsCommand`""

Write-Host "Step 4: Uploading .env file (if exists)..." -ForegroundColor Green
if (Test-Path $localEnvPath) {
    if ($OperatingSystem -eq "Windows") {
        Write-Host "Please manually copy .env file to: $RemotePath\.env" -ForegroundColor Yellow
    } else {
        $uploadEnvCommand = "scp -P $Port $localEnvPath $Username@$ServerIP`:$RemotePath\.env"
        Invoke-Expression $uploadEnvCommand
    }
}

Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. SSH into your server: ssh $Username@$ServerIP" -ForegroundColor White
Write-Host "2. Navigate to: $RemotePath" -ForegroundColor White
Write-Host "3. Ensure .NET 8.0 runtime is installed: dotnet --version" -ForegroundColor White
Write-Host "4. Test the application: cd publish_be && dotnet localink_be.dll" -ForegroundColor White
Write-Host "5. Configure as a service (see deploy_service.ps1 or deploy_service.sh)" -ForegroundColor White
Write-Host ""
Write-Host "Uploads folder location: $remoteUploadsPath" -ForegroundColor Cyan