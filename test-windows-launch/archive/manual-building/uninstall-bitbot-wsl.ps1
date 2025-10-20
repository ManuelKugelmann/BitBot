# uninstall-bitbot-wsl.ps1 - Remove BitBot WSL distro

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==================================" -ForegroundColor Cyan
Write-Host " BitBot WSL Uninstaller"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$distroName = "BitBot-Alpine"
$installPath = "$env:LOCALAPPDATA\WSL\$distroName"

# Check if installed
Write-Host "[>] Checking for BitBot WSL..." -ForegroundColor Cyan

# Get list and clean up null bytes and whitespace
$wslList = wsl --list --quiet | ForEach-Object { $_.Trim() -replace '\x00', '' }
$existing = $wslList | Where-Object { $_ -eq $distroName }

if (-not $existing) {
    Write-Host "[i] $distroName not found in WSL list" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Installed distros:" -ForegroundColor Yellow
    wsl --list --verbose
    Write-Host ""
    Write-Host "[i] If you see $distroName above, try:" -ForegroundColor Gray
    Write-Host "    wsl --unregister $distroName" -ForegroundColor White
    exit 0
}

Write-Host "[!] Found: $distroName" -ForegroundColor Yellow
Write-Host ""

# Confirm
$confirm = Read-Host "Uninstall $distroName? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "[i] Cancelled" -ForegroundColor Gray
    exit 0
}

Write-Host ""

# Unregister from WSL
Write-Host "[>] Unregistering WSL distro..." -ForegroundColor Cyan
wsl --unregister $distroName

if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] WSL distro unregistered" -ForegroundColor Green
} else {
    Write-Host "[X] Failed to unregister (exit code $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}

# Remove directory
if (Test-Path $installPath) {
    Write-Host "[>] Removing installation directory..." -ForegroundColor Cyan
    try {
        Remove-Item -Recurse -Force $installPath -ErrorAction Stop
        Write-Host "[+] Directory removed: $installPath" -ForegroundColor Green
    } catch {
        Write-Host "[!] Could not remove directory: $_" -ForegroundColor Yellow
        Write-Host "[i] You may need to delete manually: $installPath" -ForegroundColor Gray
    }
}

# Show remaining distros
Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host " Uninstall Complete"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Remaining WSL distros:" -ForegroundColor Yellow
wsl --list --verbose
Write-Host ""
Write-Host "[i] To reinstall: .\install-bitbot-wsl.ps1" -ForegroundColor Gray
