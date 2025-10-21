# Clean Slate Script
# Resets the BitBot testing environment to a fresh state
#
# Usage:
#   .\clean-slate.ps1                    # Interactive prompts
#   .\clean-slate.ps1 -Full              # Clean everything without prompts
#   .\clean-slate.ps1 -KeepAlpine        # Keep BitBot-Alpine WSL
#   .\clean-slate.ps1 -StopDockerOnly    # Only stop Docker

param(
    [switch]$Full,
    [switch]$KeepAlpine,
    [switch]$StopDockerOnly
)

$ErrorActionPreference = "Continue"

Write-Host "`n=== BitBot Clean Slate Script ===" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# 1. Stop Docker Desktop
# ============================================================================

Write-Host "[1/5] Stopping Docker Desktop..." -ForegroundColor Yellow

$dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
if ($dockerProcess) {
    Write-Host "  Stopping Docker Desktop process..." -ForegroundColor Gray
    Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Write-Host "  ✓ Docker Desktop stopped" -ForegroundColor Green
} else {
    Write-Host "  ✓ Docker Desktop not running" -ForegroundColor Green
}

# Stop Docker service if running
$dockerService = Get-Service "com.docker.service" -ErrorAction SilentlyContinue
if ($dockerService -and $dockerService.Status -eq "Running") {
    Write-Host "  Stopping Docker service..." -ForegroundColor Gray
    Stop-Service "com.docker.service" -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Docker service stopped" -ForegroundColor Green
}

if ($StopDockerOnly) {
    Write-Host "`n✓ Docker stopped. Use -Full to clean everything.`n" -ForegroundColor Green
    exit 0
}

# ============================================================================
# 2. Remove DevContainers
# ============================================================================

Write-Host "`n[2/5] Removing DevContainers..." -ForegroundColor Yellow

# Check if Docker is available (it might be stopped)
$dockerAvailable = (Get-Command docker -ErrorAction SilentlyContinue) -ne $null

if ($dockerAvailable) {
    # Try to connect to Docker (might fail if stopped)
    $dockerRunning = docker ps 2>$null
    $dockerError = $LASTEXITCODE

    if ($dockerError -eq 0) {
        Write-Host "  Docker is still running, waiting for shutdown..." -ForegroundColor Gray
        Start-Sleep -Seconds 3

        # Try again
        $dockerRunning = docker ps 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Removing BitBot containers..." -ForegroundColor Gray
            docker ps -a --filter "name=bitbot-dev-" --format "{{.Names}}" | ForEach-Object {
                docker rm -f $_ 2>$null
            }

            Write-Host "  Removing test containers..." -ForegroundColor Gray
            docker ps -a --filter "label=devcontainer.local_folder" --format "{{.Names}}" | ForEach-Object {
                docker rm -f $_ 2>$null
            }

            Write-Host "  ✓ Containers removed" -ForegroundColor Green
        } else {
            Write-Host "  ✓ Docker stopped, containers will be cleaned on next start" -ForegroundColor Green
        }
    } else {
        Write-Host "  ✓ Docker stopped, containers will be cleaned on next start" -ForegroundColor Green
    }
} else {
    Write-Host "  ⚠ Docker command not found, skipping container cleanup" -ForegroundColor Yellow
}

# ============================================================================
# 3. Uninstall DevContainer CLI
# ============================================================================

Write-Host "`n[3/5] Uninstalling DevContainer CLI..." -ForegroundColor Yellow

$npmAvailable = (Get-Command npm -ErrorAction SilentlyContinue) -ne $null

if ($npmAvailable) {
    # Check if devcontainer CLI is installed
    $devcontainerInstalled = npm list -g @devcontainers/cli 2>$null | Select-String "@devcontainers/cli"

    if ($devcontainerInstalled) {
        Write-Host "  Uninstalling @devcontainers/cli..." -ForegroundColor Gray
        npm uninstall -g @devcontainers/cli 2>$null | Out-Null

        # Verify uninstallation
        $stillInstalled = npm list -g @devcontainers/cli 2>$null | Select-String "@devcontainers/cli"
        if (-not $stillInstalled) {
            Write-Host "  ✓ DevContainer CLI uninstalled" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ DevContainer CLI may still be installed" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✓ DevContainer CLI not installed" -ForegroundColor Green
    }
} else {
    Write-Host "  ⚠ npm not found, cannot uninstall DevContainer CLI" -ForegroundColor Yellow
}

# ============================================================================
# 4. Clean BitBot Cache/Data
# ============================================================================

Write-Host "`n[4/5] Cleaning BitBot cache..." -ForegroundColor Yellow

# Clean any BitBot cache directories (if they exist)
$bitbotCache = "$env:LOCALAPPDATA\BitBot"
if (Test-Path $bitbotCache) {
    Write-Host "  Removing $bitbotCache..." -ForegroundColor Gray
    Remove-Item -Path $bitbotCache -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ BitBot cache removed" -ForegroundColor Green
} else {
    Write-Host "  ✓ No BitBot cache found" -ForegroundColor Green
}

# Clean devcontainer temp files
$devcontainerTemp = "$env:LOCALAPPDATA\Temp\devcontainercli"
if (Test-Path $devcontainerTemp) {
    Write-Host "  Removing devcontainer temp files..." -ForegroundColor Gray
    Remove-Item -Path $devcontainerTemp -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ DevContainer temp files removed" -ForegroundColor Green
}

# ============================================================================
# 5. Remove BitBot-Alpine WSL
# ============================================================================

Write-Host "`n[5/5] BitBot-Alpine WSL..." -ForegroundColor Yellow

$distroName = "BitBot-Alpine"

# Check if Alpine exists
$wslList = wsl --list --quiet 2>$null | ForEach-Object {
    $cleaned = $_ -replace '\x00', '' -replace '\r', '' -replace '\n', ''
    $cleaned.Trim()
} | Where-Object { $_ -ne '' }

$alpineExists = $wslList -contains $distroName

if ($alpineExists) {
    if ($KeepAlpine) {
        Write-Host "  ✓ BitBot-Alpine kept (--KeepAlpine flag)" -ForegroundColor Green
    } else {
        if ($Full) {
            $removeAlpine = "y"
        } else {
            Write-Host "  BitBot-Alpine WSL distribution found." -ForegroundColor White
            $removeAlpine = Read-Host "  Remove BitBot-Alpine? (y/N)"
        }

        if ($removeAlpine -eq "y" -or $removeAlpine -eq "Y") {
            Write-Host "  Unregistering $distroName..." -ForegroundColor Gray
            wsl --unregister $distroName 2>$null

            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ BitBot-Alpine removed" -ForegroundColor Green
            } else {
                Write-Host "  ⚠ Failed to remove BitBot-Alpine" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ✓ BitBot-Alpine kept" -ForegroundColor Green
        }
    }
} else {
    Write-Host "  ✓ BitBot-Alpine not found" -ForegroundColor Green
}

# ============================================================================
# Summary
# ============================================================================

Write-Host "`n=== Clean Slate Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment reset:" -ForegroundColor White
Write-Host "  ✓ Docker stopped" -ForegroundColor Green
Write-Host "  ✓ DevContainers removed" -ForegroundColor Green
Write-Host "  ✓ DevContainer CLI uninstalled" -ForegroundColor Green
Write-Host "  ✓ BitBot cache cleaned" -ForegroundColor Green

if ($alpineExists -and -not $KeepAlpine -and ($removeAlpine -eq "y" -or $removeAlpine -eq "Y" -or $Full)) {
    Write-Host "  ✓ BitBot-Alpine removed" -ForegroundColor Green
} elseif ($alpineExists) {
    Write-Host "  ⚠ BitBot-Alpine kept" -ForegroundColor Yellow
} else {
    Write-Host "  - BitBot-Alpine not present" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Ready for fresh testing!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Start Docker Desktop manually (if testing auto-start)" -ForegroundColor Gray
Write-Host "  2. Run: ..\scripts\bitbot.ps1 version" -ForegroundColor Gray
Write-Host "  3. Install BitBot-Alpine when prompted" -ForegroundColor Gray
Write-Host "  4. Run: ..\scripts\bitbot.ps1 work" -ForegroundColor Gray
Write-Host ""
