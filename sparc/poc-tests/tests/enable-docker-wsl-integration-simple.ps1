# Enable Docker Desktop WSL Integration for BitBot-Alpine
param([string]$DistroName = "BitBot-Alpine")

$ErrorActionPreference = "Stop"

Write-Host "`n=== Enable Docker Desktop WSL Integration ===" -ForegroundColor Cyan
Write-Host ""

# Check Docker Desktop
$dockerDesktop = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (-not (Test-Path $dockerDesktop)) {
    Write-Host "ERROR: Docker Desktop not found" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Docker Desktop found" -ForegroundColor Green

# Check BitBot-Alpine
$wslList = wsl --list --quiet 2>$null | ForEach-Object {
    $_ -replace '\x00', '' -replace '\r', '' -replace '\n', '' | Where-Object { $_.Trim() -ne '' }
} | Where-Object { $_ -ne '' }

if ($wslList -notcontains $DistroName) {
    Write-Host "ERROR: $DistroName not found" -ForegroundColor Red
    Write-Host "Install it first, then run this script again" -ForegroundColor Yellow
    exit 1
}
Write-Host "OK: $DistroName found" -ForegroundColor Green

# Find settings file
$settingsPath = "$env:APPDATA\Docker\settings-store.json"
if (-not (Test-Path $settingsPath)) {
    $settingsPath = "$env:APPDATA\Docker\settings.json"
}

if (-not (Test-Path $settingsPath)) {
    Write-Host "ERROR: Docker Desktop settings not found" -ForegroundColor Red
    Write-Host "Open Docker Desktop GUI once to create settings, then try again" -ForegroundColor Yellow
    exit 1
}
Write-Host "OK: Settings file found" -ForegroundColor Green
Write-Host "   $settingsPath" -ForegroundColor Gray

# Backup
$backupPath = "$settingsPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $settingsPath $backupPath
Write-Host "OK: Backup created" -ForegroundColor Green

# Read settings
try {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
} catch {
    Write-Host "ERROR: Failed to parse settings" -ForegroundColor Red
    exit 1
}

# Enable WSL 2 backend
if (-not $settings.PSObject.Properties['wslEngineEnabled']) {
    $settings | Add-Member -NotePropertyName "wslEngineEnabled" -NotePropertyValue $true -Force
}
$settings.wslEngineEnabled = $true

# Enable integration using IntegratedWslDistros array (the correct field!)
if (-not $settings.PSObject.Properties['IntegratedWslDistros']) {
    $settings | Add-Member -NotePropertyName "IntegratedWslDistros" -NotePropertyValue @() -Force
}

# Ensure enableIntegrationWithAdditionalDistros exists (but stays empty)
if (-not $settings.PSObject.Properties['enableIntegrationWithAdditionalDistros']) {
    $settings | Add-Member -NotePropertyName "enableIntegrationWithAdditionalDistros" -NotePropertyValue @{} -Force
}

$alreadyEnabled = $settings.IntegratedWslDistros -contains $DistroName

if ($alreadyEnabled) {
    Write-Host "INFO: $DistroName already enabled" -ForegroundColor Cyan
} else {
    $settings.IntegratedWslDistros += $DistroName
    Write-Host "OK: $DistroName enabled" -ForegroundColor Green
}

# Stop Docker Desktop FIRST (important - must stop before modifying settings)
if (-not $alreadyEnabled) {
    Write-Host ""
    Write-Host "Stopping Docker Desktop..." -ForegroundColor Yellow
    Start-Process -FilePath $dockerDesktop -ArgumentList "--quit" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    Write-Host "OK: Docker Desktop stopped" -ForegroundColor Green
}

# Save settings
if (-not $alreadyEnabled) {
    Write-Host ""
    Write-Host "Saving settings..." -ForegroundColor Yellow
    try {
        # Save as ASCII to avoid UTF8 BOM issues that break Docker Desktop
        $settings | ConvertTo-Json -Depth 32 | Set-Content $settingsPath -Encoding ASCII
        Write-Host "OK: Settings saved" -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to save settings" -ForegroundColor Red
        Copy-Item $backupPath $settingsPath -Force
        exit 1
    }

    # Start Docker Desktop
    Write-Host ""
    Write-Host "Starting Docker Desktop..." -ForegroundColor Yellow
    Write-Host "(This may take 20-30 seconds)" -ForegroundColor Gray
    Start-Process -FilePath $dockerDesktop -NoNewWindow
    Start-Sleep -Seconds 20

    Write-Host "OK: Docker Desktop started" -ForegroundColor Green
}

# Verify
Write-Host ""
Write-Host "Verifying integration..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$testResult = wsl -d $DistroName docker ps 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: $DistroName can access Docker!" -ForegroundColor Green
    Write-Host ""
    wsl -d $DistroName docker ps
} else {
    Write-Host "WARNING: $DistroName cannot access Docker yet" -ForegroundColor Yellow
    Write-Host "Wait 30 seconds and try: wsl -d $DistroName docker ps" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Cyan
Write-Host ""
