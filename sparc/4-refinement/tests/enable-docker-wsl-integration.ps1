# Enable Docker Desktop WSL Integration for BitBot-Alpine
# This script automatically enables BitBot-Alpine in Docker Desktop settings

param(
    [string]$DistroName = "BitBot-Alpine"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Enable Docker Desktop WSL Integration ===" -ForegroundColor Cyan
Write-Host ""

# Check if Docker Desktop is installed
$dockerDesktop = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (-not (Test-Path $dockerDesktop)) {
    Write-Host "✗ Docker Desktop not found at: $dockerDesktop" -ForegroundColor Red
    Write-Host "  Please install Docker Desktop first" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Docker Desktop found" -ForegroundColor Green

# Check if BitBot-Alpine exists
Write-Host ""
Write-Host "Checking if $DistroName exists..." -ForegroundColor Yellow

$wslList = wsl --list --quiet 2>$null | ForEach-Object {
    $cleaned = $_ -replace '\x00', '' -replace '\r', '' -replace '\n', ''
    $cleaned.Trim()
} | Where-Object { $_ -ne '' }

if ($wslList -notcontains $DistroName) {
    Write-Host "✗ $DistroName WSL distribution not found" -ForegroundColor Red
    Write-Host "  Please install $DistroName first" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Available WSL distributions:" -ForegroundColor White
    $wslList | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    exit 1
}

Write-Host "✓ $DistroName found" -ForegroundColor Green

# Locate Docker Desktop settings file
Write-Host ""
Write-Host "Locating Docker Desktop settings..." -ForegroundColor Yellow

# Try both possible settings file names (settings-store.json is newer)
$settingsPath = "$env:APPDATA\Docker\settings-store.json"
if (-not (Test-Path $settingsPath)) {
    $settingsPath = "$env:APPDATA\Docker\settings.json"
}

if (-not (Test-Path $settingsPath)) {
    Write-Host "✗ Docker Desktop settings not found" -ForegroundColor Red
    Write-Host "  Checked:" -ForegroundColor Gray
    Write-Host "    - $env:APPDATA\Docker\settings-store.json" -ForegroundColor Gray
    Write-Host "    - $env:APPDATA\Docker\settings.json" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Docker Desktop may not be initialized yet" -ForegroundColor Yellow
    Write-Host "  Please start Docker Desktop GUI at least once, then run this script again" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Settings file found: $settingsPath" -ForegroundColor Green

# Backup settings
Write-Host ""
Write-Host "Creating backup..." -ForegroundColor Yellow

$backupPath = "$settingsPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $settingsPath $backupPath
Write-Host "✓ Backup created: $backupPath" -ForegroundColor Green

# Read and parse settings
Write-Host ""
Write-Host "Reading Docker Desktop settings..." -ForegroundColor Yellow

try {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
} catch {
    Write-Host "✗ Failed to parse settings.json" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Gray
    exit 1
}

Write-Host "✓ Settings parsed successfully" -ForegroundColor Green

# Check and enable WSL 2 backend
Write-Host ""
Write-Host "Checking WSL 2 backend..." -ForegroundColor Yellow

if (-not $settings.wslEngineEnabled) {
    Write-Host "  Enabling WSL 2 backend..." -ForegroundColor Gray
    $settings | Add-Member -NotePropertyName "wslEngineEnabled" -NotePropertyValue $true -Force
}

Write-Host "✓ WSL 2 backend enabled" -ForegroundColor Green

# Enable integration with additional distros
Write-Host ""
Write-Host "Configuring WSL integration..." -ForegroundColor Yellow

# Ensure the property exists
if (-not $settings.PSObject.Properties['enableIntegrationWithAdditionalDistros']) {
    $settings | Add-Member -NotePropertyName "enableIntegrationWithAdditionalDistros" -NotePropertyValue @{} -Force
}

# Check current status
$currentlyEnabled = $settings.enableIntegrationWithAdditionalDistros.PSObject.Properties.Name -contains $DistroName

if ($currentlyEnabled -and $settings.enableIntegrationWithAdditionalDistros.$DistroName -eq $true) {
    Write-Host "✓ $DistroName is already enabled" -ForegroundColor Green
    $alreadyEnabled = $true
} else {
    Write-Host "  Enabling $DistroName..." -ForegroundColor Gray

    # Add or update the distro setting
    if ($settings.enableIntegrationWithAdditionalDistros.PSObject.Properties.Name -contains $DistroName) {
        $settings.enableIntegrationWithAdditionalDistros.$DistroName = $true
    } else {
        $settings.enableIntegrationWithAdditionalDistros | Add-Member -NotePropertyName $DistroName -NotePropertyValue $true -Force
    }

    Write-Host "✓ $DistroName enabled" -ForegroundColor Green
    $alreadyEnabled = $false
}

# Write updated settings
if (-not $alreadyEnabled) {
    Write-Host ""
    Write-Host "Saving updated settings..." -ForegroundColor Yellow

    try {
        $settings | ConvertTo-Json -Depth 32 | Set-Content $settingsPath -Encoding UTF8
        Write-Host "✓ Settings saved" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to save settings" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Restoring backup..." -ForegroundColor Yellow
        Copy-Item $backupPath $settingsPath -Force
        exit 1
    }
}

# Restart Docker Desktop to apply changes
if (-not $alreadyEnabled) {
    Write-Host ""
    Write-Host "Restarting Docker Desktop..." -ForegroundColor Yellow
    Write-Host "  This may take 20-30 seconds..." -ForegroundColor Gray
    Write-Host ""

    # Quit Docker Desktop gracefully
    Start-Process -FilePath $dockerDesktop -ArgumentList "--quit" -NoNewWindow -Wait -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3

    # Start Docker Desktop
    Start-Process -FilePath $dockerDesktop -NoNewWindow

    Write-Host "  Waiting for Docker Desktop to start..." -ForegroundColor Gray
    Start-Sleep -Seconds 10

    # Wait for Docker to be ready
    $timeout = 60
    $elapsed = 0

    while ($elapsed -lt $timeout) {
        try {
            $result = docker ps 2>&1
            if ($LASTEXITCODE -eq 0) {
                break
            }
        } catch {
            # Continue waiting
        }
        Start-Sleep -Seconds 2
        $elapsed += 2
        Write-Host "." -NoNewline -ForegroundColor Gray
    }

    Write-Host ""

    if ($elapsed -lt $timeout) {
        Write-Host "✓ Docker Desktop restarted successfully" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Docker Desktop is starting (may need more time)" -ForegroundColor Yellow
    }
}

# Verify integration
Write-Host ""
Write-Host "Verifying WSL integration..." -ForegroundColor Yellow

Start-Sleep -Seconds 5

$testResult = wsl -d $DistroName docker ps 2>&1
$testExitCode = $LASTEXITCODE

if ($testExitCode -eq 0) {
    Write-Host "✓ $DistroName can access Docker!" -ForegroundColor Green
    Write-Host ""
    Write-Host "WSL integration output:" -ForegroundColor White
    wsl -d $DistroName docker ps
} else {
    Write-Host "WARNING: $DistroName cannot access Docker yet" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Error message:" -ForegroundColor White
    Write-Host "  $testResult" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Wait 30 seconds for Docker Desktop to fully initialize" -ForegroundColor Gray
    Write-Host "  2. Terminate and restart the WSL distro:" -ForegroundColor Gray
    Write-Host "     wsl --terminate $DistroName" -ForegroundColor Gray
    Write-Host "     wsl -d $DistroName docker ps" -ForegroundColor Gray
    Write-Host "  3. If still failing, manually check Docker Desktop settings:" -ForegroundColor Gray
    Write-Host "     Settings → Resources → WSL Integration" -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host ""

if ($alreadyEnabled) {
    Write-Host "✓ $DistroName was already enabled" -ForegroundColor Green
} else {
    Write-Host "✓ $DistroName integration enabled" -ForegroundColor Green
    Write-Host "✓ Settings saved to: $settingsPath" -ForegroundColor Green
    Write-Host "✓ Backup created: $backupPath" -ForegroundColor Green
    Write-Host "✓ Docker Desktop restarted" -ForegroundColor Green
}

if ($testExitCode -eq 0) {
    Write-Host "✓ Integration verified - Docker is accessible!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now use BitBot:" -ForegroundColor White
    Write-Host "  cd test-windows-launch\tests" -ForegroundColor Gray
    Write-Host "  ..\scripts\bitbot.ps1 work" -ForegroundColor Gray
} else {
    Write-Host "WARNING: Integration needs verification (see troubleshooting above)" -ForegroundColor Yellow
}

Write-Host ""
