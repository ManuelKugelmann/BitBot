# install-bitbot-wsl.ps1 - Install dedicated minimal WSL distro for BitBot

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==================================" -ForegroundColor Cyan
Write-Host " BitBot WSL Installer"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$distroName = "BitBot-Alpine"
$installPath = "$env:LOCALAPPDATA\WSL\$distroName"
$alpineVersion = "3.19"
$alpineUrl = "https://dl-cdn.alpinelinux.org/alpine/v$alpineVersion/releases/x86_64/alpine-minirootfs-$alpineVersion.1-x86_64.tar.gz"
$tempFile = "$env:TEMP\alpine-bitbot.tar.gz"

# Check if already installed
Write-Host "[>] Checking for existing installation..." -ForegroundColor Cyan

# Get list and clean up null bytes and whitespace
$wslList = wsl --list --quiet | ForEach-Object { $_.Trim() -replace '\x00', '' }
$existing = $wslList | Where-Object { $_ -eq $distroName }

if ($existing) {
    Write-Host "[!] $distroName already exists" -ForegroundColor Yellow
    Write-Host ""
    $uninstall = Read-Host "Uninstall and reinstall? (y/N)"

    if ($uninstall -eq "y" -or $uninstall -eq "Y") {
        Write-Host "[>] Uninstalling $distroName..." -ForegroundColor Cyan
        wsl --unregister $distroName
        Write-Host "[+] Uninstalled" -ForegroundColor Green
    } else {
        Write-Host "[i] Keeping existing installation" -ForegroundColor Gray
        exit 0
    }
}

# Download Alpine rootfs
Write-Host ""
Write-Host "[>] Downloading Alpine Linux rootfs..." -ForegroundColor Cyan
Write-Host "[i] Source: $alpineUrl" -ForegroundColor Gray

try {
    Invoke-WebRequest -Uri $alpineUrl -OutFile $tempFile -UseBasicParsing
    Write-Host "[+] Downloaded $('{0:N2}' -f ((Get-Item $tempFile).Length / 1MB)) MB" -ForegroundColor Green
} catch {
    Write-Host "[X] Download failed: $_" -ForegroundColor Red
    exit 1
}

# Import as WSL distro
Write-Host ""
Write-Host "[>] Importing as WSL distro..." -ForegroundColor Cyan
Write-Host "[i] Name: $distroName" -ForegroundColor Gray
Write-Host "[i] Location: $installPath" -ForegroundColor Gray

try {
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    wsl --import $distroName $installPath $tempFile --version 2

    if ($LASTEXITCODE -ne 0) {
        throw "wsl --import failed with exit code $LASTEXITCODE"
    }

    Write-Host "[+] Import successful" -ForegroundColor Green
} catch {
    Write-Host "[X] Import failed: $_" -ForegroundColor Red
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    exit 1
}

# Clean up
Remove-Item $tempFile -ErrorAction SilentlyContinue

# Configure BitBot WSL
Write-Host ""
Write-Host "[>] Configuring BitBot environment..." -ForegroundColor Cyan

# Install packages directly (more reliable than piping script)
Write-Host "[i] Installing essential packages..." -ForegroundColor Gray
wsl -d $distroName sh -c "apk add --no-cache bash git docker-cli nodejs npm curl ca-certificates"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] Package installation failed" -ForegroundColor Red
    exit 1
}

Write-Host "[+] Base packages installed" -ForegroundColor Green

# Install devcontainers CLI
Write-Host "[i] Installing @devcontainers/cli..." -ForegroundColor Gray
wsl -d $distroName sh -c "npm install -g @devcontainers/cli"

if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] @devcontainers/cli installed" -ForegroundColor Green
} else {
    Write-Host "[!] @devcontainers/cli installation may have failed" -ForegroundColor Yellow
}

# Set bash as default shell
Write-Host "[i] Setting bash as default shell..." -ForegroundColor Gray
wsl -d $distroName sh -c "sed -i 's|/bin/ash|/bin/bash|' /etc/passwd"

Write-Host "[+] Configuration complete" -ForegroundColor Green

# List all WSL distros
Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host " Installation Complete"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installed WSL distros:" -ForegroundColor Yellow
wsl --list --verbose

Write-Host ""
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  wsl -d $distroName" -ForegroundColor White
Write-Host "  wsl -d $distroName bash" -ForegroundColor White
Write-Host ""
Write-Host "[i] This distro is dedicated to BitBot" -ForegroundColor Gray
Write-Host "[i] Docker Desktop will NOT interfere with it" -ForegroundColor Gray
