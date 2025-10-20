# Installation & Distribution Specification

**Feature ID**: SPEC-10
**Priority**: P0 (Critical - Blocking)
**Status**: Draft (Design complete, implementation pending)
**Depends On**: SPEC-05 (Cross-Platform CLI), SPEC-09 (CLI UX & Onboarding)
**Created**: 2025-10-17
**Last Updated**: 2025-10-20

---

## Executive Summary

Installation and distribution strategy for BitBot across Linux, macOS, and Windows. Multiple installation methods (script, package managers, manual). Automatic updates and uninstallation.

**Key Design**: Install script + package managers + manual download + auto-update + security verification = accessible and secure installation.

---

## Part A: Installation Methods

### A1. Quick Install (Recommended)

**One-line installation**:
```bash
curl -fsSL https://bitbot.sh/install.sh | bash
```

**Windows**:
```powershell
iwr -useb https://bitbot.sh/install.ps1 | iex
```

**Custom options**:
```bash
# Custom install directory
BITBOT_INSTALL_DIR=/usr/local/bitbot curl -fsSL https://bitbot.sh/install.sh | bash

# Specific version
BITBOT_VERSION=v1.0.0 curl -fsSL https://bitbot.sh/install.sh | bash

# Non-interactive
BITBOT_NONINTERACTIVE=1 curl -fsSL https://bitbot.sh/install.sh | bash
```

### A2. Package Managers

**Homebrew (macOS/Linux)**:
```bash
brew tap bitbot-dev/bitbot
brew install bitbot
```

**APT (Debian/Ubuntu)**:
```bash
# Add repository
curl -fsSL https://bitbot.sh/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/bitbot.gpg
echo "deb [signed-by=/usr/share/keyrings/bitbot.gpg] https://apt.bitbot.sh stable main" | \
  sudo tee /etc/apt/sources.list.d/bitbot.list

# Install
sudo apt update
sudo apt install bitbot
```

**Chocolatey (Windows)**:
```powershell
choco install bitbot
```

**Scoop (Windows)**:
```powershell
scoop bucket add bitbot https://github.com/bitbot-dev/scoop-bucket
scoop install bitbot
```

**winget (Windows)**:
```powershell
winget install BitBot.BitBot
```

### A3. Manual Download

**GitHub Releases**:
```bash
# Download from https://github.com/bitbot-dev/bitbot/releases
wget https://github.com/bitbot-dev/bitbot/releases/download/v1.0.0/bitbot-linux-amd64.tar.gz

# Extract and install
tar -xzf bitbot-linux-amd64.tar.gz
sudo mv bitbot /opt/bitbot
sudo ln -s /opt/bitbot/bin/bitbot /usr/local/bin/bitbot

# Run first-time setup
bitbot
```

**Offline installation**:
```bash
# 1. Download on internet-connected machine
wget https://github.com/bitbot-dev/bitbot/releases/download/v1.0.0/bitbot-linux-amd64.tar.gz
wget https://github.com/bitbot-dev/bitbot/releases/download/v1.0.0/CHECKSUMS.txt

# 2. Verify checksum
sha256sum -c CHECKSUMS.txt --ignore-missing

# 3. Transfer to offline machine via USB/network
# 4. Extract and install (as above)
```

---

## Part B: Installation Locations

### B1. Linux/macOS Structure

```
/opt/bitbot/                    # Main installation (system-wide)
├── bin/
│   ├── bitbot                  # Main executable
│   ├── bitbot-core.sh          # Core bash implementation
│   ├── uninstall.sh            # Uninstaller
│   └── update.sh               # Update script
├── lib/
│   ├── vscode-devcontainer-utils.sh  # Helper utilities
│   └── container-utils.sh
├── templates/                  # Built-in workspace templates
│   ├── python/
│   ├── node/
│   ├── rust/
│   └── ...
├── config/
│   └── default-config.yml      # Default configuration
└── version                     # Installed version

/usr/local/bin/bitbot           # Symlink to /opt/bitbot/bin/bitbot

~/.bitbot/                      # User data (per-user)
├── config.yml                  # User configuration
├── templates/                  # Custom templates
├── first-run                   # First-run marker
├── last-update-check           # Last update check timestamp
└── backups/                    # Backup directory
```

### B2. Windows Structure

**Native Windows files**:
```
C:\Program Files\BitBot\
├── bitbot.exe                  # Windows launcher (forwards to WSL)
├── bitbot-installer.exe        # MSI installer
├── wsl-install.ps1             # WSL installation script
└── uninstall.exe               # Uninstaller
```

**WSL implementation** (inside WSL):
```
/opt/bitbot/                    # Same structure as Linux
├── bin/
│   ├── bitbot
│   ├── bitbot-core.sh
│   └── ...
└── ...

~/.bitbot/                      # User data (WSL user)
```

**Windows user data**:
```
%USERPROFILE%\.bitbot\          # Windows-side config (optional)
└── config.yml                  # Can override WSL config
```

### B3. BitBot-Alpine Integration

**When using BitBot-Alpine**:
```
# Installation in BitBot-Alpine distro
wsl -d BitBot-Alpine bash -c "curl -fsSL https://bitbot.sh/install.sh | bash"

# Structure inside BitBot-Alpine:
/opt/bitbot/                    # BitBot installation
~/.bitbot/                      # User data

# WSL interop for Windows tools
# BitBot can call cmd.exe, devcontainer.cmd, code.exe via WSL interop
```

---

## Part C: Install Script Implementation

### C1. Install Script Flow

**Script URL**: https://bitbot.sh/install.sh

**Flow**:
```
Detect Platform (Linux/macOS/Windows-WSL)
  ↓
Check Prerequisites (Docker, Docker Compose, WSL2 on Windows)
  ↓
Prompt for Installation Options (directory, version)
  ↓
Download BitBot Archive (GitHub Releases)
  ↓
Verify Checksum & GPG Signature
  ↓
Extract to Installation Directory
  ↓
Create Symlinks
  ↓
Install Global MCP Services (optional)
  ↓
Run First-Time Setup (SPEC-09)
  ↓
Success Message with Next Steps
```

### C2. Install Script (install.sh)

**Key sections**:
```bash
#!/usr/bin/env bash
set -e

BITBOT_VERSION="${BITBOT_VERSION:-latest}"
BITBOT_INSTALL_DIR="${BITBOT_INSTALL_DIR:-/opt/bitbot}"
BITBOT_NONINTERACTIVE="${BITBOT_NONINTERACTIVE:-0}"

# Detect platform
detect_platform() {
  case "$(uname -s)" in
    Linux*)   echo "linux" ;;
    Darwin*)  echo "macos" ;;
    *)        echo "unknown" ;;
  esac
}

# Check prerequisites
check_prerequisites() {
  echo "Checking prerequisites..."

  # Docker
  if ! command -v docker &>/dev/null; then
    error "Docker not found"
    echo "Install: https://www.docker.com/products/docker-desktop"
    exit 1
  fi

  # Docker running
  if ! docker ps &>/dev/null 2>&1; then
    error "Docker is not running. Please start Docker Desktop."
    exit 1
  fi

  # Docker Compose
  if ! docker compose version &>/dev/null 2>&1; then
    error "Docker Compose not found (usually bundled with Docker)"
    exit 1
  fi

  success "Prerequisites OK"
}

# Download BitBot
download_bitbot() {
  local version="$1"
  local platform="$2"

  # Resolve 'latest' to actual version
  if [[ "$version" == "latest" ]]; then
    version=$(curl -s https://api.github.com/repos/bitbot-dev/bitbot/releases/latest | \
              grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
  fi

  local url="https://github.com/bitbot-dev/bitbot/releases/download/${version}/bitbot-${platform}-amd64.tar.gz"

  echo "Downloading BitBot ${version}..."
  curl -fsSL "$url" -o /tmp/bitbot.tar.gz

  # Download checksums
  curl -fsSL "https://github.com/bitbot-dev/bitbot/releases/download/${version}/CHECKSUMS.txt" \
    -o /tmp/bitbot-checksums.txt
}

# Verify integrity
verify_download() {
  echo "Verifying download..."

  cd /tmp
  sha256sum -c bitbot-checksums.txt --ignore-missing

  if [[ $? -ne 0 ]]; then
    error "Checksum verification failed"
    exit 1
  fi

  success "Verification OK"
}

# Extract and install
install_bitbot() {
  echo "Installing to ${BITBOT_INSTALL_DIR}..."

  # Create directory
  sudo mkdir -p "$BITBOT_INSTALL_DIR"

  # Extract
  sudo tar -xzf /tmp/bitbot.tar.gz -C "$BITBOT_INSTALL_DIR" --strip-components=1

  # Create symlink
  sudo ln -sf "${BITBOT_INSTALL_DIR}/bin/bitbot" /usr/local/bin/bitbot

  # Make executable
  sudo chmod +x "${BITBOT_INSTALL_DIR}/bin/"*

  # Cleanup
  rm /tmp/bitbot.tar.gz /tmp/bitbot-checksums.txt

  success "Installation complete"
}

# Install global MCP services (optional)
install_global_mcp() {
  if [[ "$BITBOT_NONINTERACTIVE" == "1" ]]; then
    return
  fi

  echo ""
  read -p "Install global MCP services? (git-safety, filesystem) [Y/n]: " response

  if [[ "$response" =~ ^[Nn]$ ]]; then
    return
  fi

  echo "Installing global MCP services..."

  sudo mkdir -p /opt/bitbot/global-mcp
  sudo cp -r "${BITBOT_INSTALL_DIR}/services/mcp"/* /opt/bitbot/global-mcp/

  # Start services
  cd /opt/bitbot/global-mcp
  sudo docker compose up -d

  success "MCP services started"
}

# Main installation
main() {
  echo "======================================"
  echo "  BitBot Installer"
  echo "======================================"
  echo ""

  PLATFORM=$(detect_platform)

  if [[ "$PLATFORM" == "unknown" ]]; then
    error "Unsupported platform: $(uname -s)"
    exit 1
  fi

  check_prerequisites
  download_bitbot "$BITBOT_VERSION" "$PLATFORM"
  verify_download
  install_bitbot
  install_global_mcp

  echo ""
  echo "======================================"
  echo "  ✓ BitBot installed successfully!"
  echo "======================================"
  echo ""
  echo "Run:  bitbot"
  echo "Help: bitbot help"
  echo "Docs: https://docs.bitbot.dev"
  echo ""
}

main
```

### C3. Windows Install Script (install.ps1)

**PowerShell installer**:
```powershell
# install.ps1 - BitBot Windows Installer

$ErrorActionPreference = "Stop"

$BitBotVersion = if ($env:BITBOT_VERSION) { $env:BITBOT_VERSION } else { "latest" }

Write-Host "======================================"
Write-Host "  BitBot Windows Installer"
Write-Host "======================================"
Write-Host ""

# Check WSL2
Write-Host "Checking prerequisites..." -ForegroundColor Cyan

if (!(Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ WSL2 not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install WSL2:" -ForegroundColor Yellow
    Write-Host "  wsl --install"
    Write-Host ""
    Write-Host "Then re-run this installer."
    exit 1
}

# Check Docker
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install Docker Desktop:" -ForegroundColor Yellow
    Write-Host "  https://www.docker.com/products/docker-desktop"
    exit 1
}

# Test Docker
try {
    docker ps | Out-Null
} catch {
    Write-Host "❌ Docker not running. Start Docker Desktop." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Prerequisites OK" -ForegroundColor Green
Write-Host ""

# Install in WSL
Write-Host "Installing BitBot in WSL..." -ForegroundColor Cyan

$installCmd = "curl -fsSL https://bitbot.sh/install.sh | BITBOT_VERSION=$BitBotVersion bash"
wsl bash -c $installCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Installation failed" -ForegroundColor Red
    exit 1
}

# Install Windows launcher
Write-Host "Installing Windows launcher..." -ForegroundColor Cyan

$bitbotExe = "$env:ProgramFiles\BitBot\bitbot.exe"
$bitbotDir = Split-Path $bitbotExe

# Create directory
if (!(Test-Path $bitbotDir)) {
    New-Item -ItemType Directory -Path $bitbotDir -Force | Out-Null
}

# Download bitbot.exe (forwards to WSL)
Invoke-WebRequest -Uri "https://github.com/bitbot-dev/bitbot/releases/download/$BitBotVersion/bitbot.exe" `
  -OutFile $bitbotExe

# Add to PATH
$envPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($envPath -notlike "*$bitbotDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$envPath;$bitbotDir", "Machine")
    $env:Path = "$env:Path;$bitbotDir"
}

Write-Host "✓ Windows launcher installed" -ForegroundColor Green
Write-Host ""

Write-Host "======================================"
Write-Host "  ✓ BitBot installed successfully!"
Write-Host "======================================"
Write-Host ""
Write-Host "Run:  bitbot"
Write-Host "Help: bitbot help"
Write-Host "Docs: https://docs.bitbot.dev"
Write-Host ""
```

---

## Part D: Package Manager Integration

### D1. Homebrew Formula

**Repository**: https://github.com/bitbot-dev/homebrew-bitbot

**Formula** (`bitbot.rb`):
```ruby
class Bitbot < Formula
  desc "AI-Assisted Development Environment"
  homepage "https://bitbot.dev"
  url "https://github.com/bitbot-dev/bitbot/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "abc123..."
  license "MIT"

  depends_on "docker"
  depends_on "docker-compose"

  def install
    # Install to prefix
    prefix.install Dir["*"]

    # Create symlink
    bin.install_symlink prefix/"bin/bitbot"
  end

  def post_install
    # Create user directory
    (var/"bitbot").mkpath

    # Start global MCP services (optional)
    ohai "Starting global MCP services..."
    system "docker", "compose", "-f", "#{prefix}/global-mcp/docker-compose.yml", "up", "-d"
  rescue
    opoo "Could not start MCP services (Docker may not be running)"
  end

  def caveats
    <<~EOS
      BitBot has been installed!

      Run 'bitbot' to get started.

      Documentation: https://docs.bitbot.dev
    EOS
  end

  test do
    system "#{bin}/bitbot", "version"
  end
end
```

### D2. APT Package

**Package structure**:
```
bitbot_1.0.0_amd64.deb
├── opt/bitbot/
│   ├── bin/
│   ├── lib/
│   ├── templates/
│   └── version
├── usr/local/bin/bitbot -> /opt/bitbot/bin/bitbot
└── DEBIAN/
    ├── control             # Package metadata
    ├── postinst            # Post-installation script
    ├── prerm               # Pre-removal script
    └── postrm              # Post-removal script
```

**control file**:
```
Package: bitbot
Version: 1.0.0
Section: devel
Priority: optional
Architecture: amd64
Depends: docker.io (>= 20.10), docker-compose (>= 2.0)
Maintainer: BitBot Team <team@bitbot.dev>
Description: AI-Assisted Development Environment
 BitBot provides secure AI-assisted development environments
 with workspace isolation, MCP services, and AI agent integration.
```

**postinst script**:
```bash
#!/bin/bash
set -e

# Create user directory template
mkdir -p /etc/skel/.bitbot

# Start global MCP services
if systemctl is-active --quiet docker; then
  cd /opt/bitbot/global-mcp
  docker-compose up -d || true
fi

echo "BitBot installed. Run 'bitbot' to get started."
```

### D3. Chocolatey Package

**Package structure**:
```
bitbot.1.0.0.nupkg
├── tools/
│   ├── chocolateyinstall.ps1    # Install script
│   ├── chocolateyuninstall.ps1  # Uninstall script
│   └── bitbot.exe
└── bitbot.nuspec
```

**nuspec file**:
```xml
<?xml version="1.0"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>bitbot</id>
    <version>1.0.0</version>
    <title>BitBot</title>
    <authors>BitBot Team</authors>
    <description>AI-Assisted Development Environment with workspace isolation and AI agent integration</description>
    <projectUrl>https://bitbot.dev</projectUrl>
    <licenseUrl>https://github.com/bitbot-dev/bitbot/blob/main/LICENSE</licenseUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <tags>development docker ai containers devcontainer</tags>
    <dependencies>
      <dependency id="docker-desktop" version="4.0.0" />
    </dependencies>
  </metadata>
</package>
```

**chocolateyinstall.ps1**:
```powershell
$ErrorActionPreference = 'Stop'

$packageName = 'bitbot'
$url = 'https://github.com/bitbot-dev/bitbot/releases/download/v1.0.0/bitbot-windows.zip'
$checksum = 'ABC123...'
$checksumType = 'sha256'

# Install to Program Files
$installDir = Join-Path $env:ProgramFiles $packageName
Install-ChocolateyZipPackage $packageName $url $installDir -checksum $checksum -checksumType $checksumType

# Add to PATH
Install-ChocolateyPath $installDir

# Install in WSL
$env:BITBOT_NONINTERACTIVE = "1"
wsl bash -c "curl -fsSL https://bitbot.sh/install.sh | bash"

Write-Host "BitBot installed! Run 'bitbot' to get started." -ForegroundColor Green
```

---

## Part E: Updates & Versioning

### E1. Version Checking

**Check for updates**:
```bash
bitbot version --check

# Output:
# BitBot v1.0.0
# Latest version: v1.1.0
# Update available! Run: bitbot update
```

**Automatic update check** (on startup, once per day):
```bash
# In bitbot-core.sh
check_for_updates() {
  local last_check=$(cat ~/.bitbot/last-update-check 2>/dev/null || echo 0)
  local now=$(date +%s)

  # Check once per day
  if (( now - last_check < 86400 )); then
    return
  fi

  # Fetch latest version
  local latest=$(curl -s https://api.github.com/repos/bitbot-dev/bitbot/releases/latest | \
                 grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

  if [[ -n "$latest" && "$latest" != "$BITBOT_VERSION" ]]; then
    echo ""
    echo "⚠️  Update available: $latest (current: $BITBOT_VERSION)"
    echo "   Run: bitbot update"
    echo ""
  fi

  echo "$now" > ~/.bitbot/last-update-check
}
```

### E2. Self-Update

**Update command**:
```bash
bitbot update

# Or specific version
bitbot update --version v1.1.0

# Or force update (skip checks)
bitbot update --force
```

**Update implementation**:
```bash
bitbot_update() {
  local version="${1:-latest}"
  local force="${2:-false}"

  echo "======================================"
  echo "  BitBot Update"
  echo "======================================"
  echo ""

  # Check current version
  local current="$BITBOT_VERSION"

  # Resolve latest
  if [[ "$version" == "latest" ]]; then
    version=$(curl -s https://api.github.com/repos/bitbot-dev/bitbot/releases/latest | \
              grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
  fi

  if [[ "$current" == "$version" && "$force" != "true" ]]; then
    echo "Already on latest version: $version"
    return
  fi

  echo "Updating from $current to $version..."

  # Backup current installation
  local backup="/opt/bitbot.backup.$(date +%Y%m%d-%H%M%S)"
  echo "Creating backup: $backup"
  sudo cp -r /opt/bitbot "$backup"

  # Download new version
  local platform=$(detect_platform)
  local url="https://github.com/bitbot-dev/bitbot/releases/download/${version}/bitbot-${platform}-amd64.tar.gz"

  echo "Downloading $version..."
  curl -fsSL "$url" -o /tmp/bitbot-update.tar.gz

  # Verify checksum
  curl -fsSL "https://github.com/bitbot-dev/bitbot/releases/download/${version}/CHECKSUMS.txt" \
    -o /tmp/bitbot-checksums.txt

  cd /tmp
  sha256sum -c bitbot-checksums.txt --ignore-missing

  if [[ $? -ne 0 ]]; then
    echo "❌ Checksum verification failed"
    rm /tmp/bitbot-update.tar.gz /tmp/bitbot-checksums.txt
    exit 1
  fi

  # Extract
  echo "Installing..."
  sudo tar -xzf /tmp/bitbot-update.tar.gz -C /opt/bitbot --strip-components=1

  # Cleanup
  rm /tmp/bitbot-update.tar.gz /tmp/bitbot-checksums.txt

  # Restart MCP services
  if [ -f /opt/bitbot/global-mcp/docker-compose.yml ]; then
    echo "Restarting MCP services..."
    cd /opt/bitbot/global-mcp
    sudo docker compose restart
  fi

  echo ""
  echo "✓ Updated to $version"
  echo "  Backup: $backup"
  echo ""
}
```

### E3. Rollback

**Rollback to previous version**:
```bash
bitbot rollback

# Lists available backups
# Allows selection and restoration
```

**Rollback implementation**:
```bash
bitbot_rollback() {
  echo "Available backups:"
  echo ""

  local backups=($(ls -d /opt/bitbot.backup.* 2>/dev/null | sort -r))

  if [ ${#backups[@]} -eq 0 ]; then
    echo "No backups found"
    return 1
  fi

  for i in "${!backups[@]}"; do
    echo "  $((i+1)). ${backups[$i]##*/}"
  done

  echo ""
  read -p "Select backup to restore [1-${#backups[@]}]: " selection

  if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#backups[@]} ]; then
    echo "Invalid selection"
    return 1
  fi

  local backup="${backups[$((selection-1))]}"

  echo "Restoring from: $backup"

  # Stop services
  if [ -f /opt/bitbot/global-mcp/docker-compose.yml ]; then
    cd /opt/bitbot/global-mcp
    sudo docker compose down
  fi

  # Backup current (in case rollback fails)
  sudo mv /opt/bitbot "/opt/bitbot.pre-rollback.$(date +%Y%m%d-%H%M%S)"

  # Restore
  sudo cp -r "$backup" /opt/bitbot

  # Restart services
  if [ -f /opt/bitbot/global-mcp/docker-compose.yml ]; then
    cd /opt/bitbot/global-mcp
    sudo docker compose up -d
  fi

  echo "✓ Rollback complete"
}
```

---

## Part F: Uninstallation

### F1. Uninstall Command

**Complete removal**:
```bash
bitbot uninstall

# Interactive prompts:
# - Stop all containers? [Y/n]
# - Remove global MCP services? [Y/n]
# - Remove user data (~/.bitbot)? [y/N]
```

**Non-interactive**:
```bash
# Remove everything including user data
bitbot uninstall --full --yes

# Keep user data
bitbot uninstall --yes
```

### F2. Uninstall Script

**Implementation** (`bin/uninstall.sh`):
```bash
#!/usr/bin/env bash

set -e

REMOVE_USER_DATA="${1:-false}"

echo "======================================"
echo "  BitBot Uninstaller"
echo "======================================"
echo ""

# Stop all BitBot containers
echo "Stopping BitBot containers..."
docker ps -a --filter "label=bitbot" --format "{{.ID}}" | xargs -r docker rm -f

# Stop global MCP services
if [ -f /opt/bitbot/global-mcp/docker-compose.yml ]; then
  echo "Stopping global MCP services..."
  cd /opt/bitbot/global-mcp
  sudo docker compose down
fi

# Remove installation
echo "Removing installation..."
sudo rm -rf /opt/bitbot
sudo rm -f /usr/local/bin/bitbot

# Remove user data (if requested)
if [[ "$REMOVE_USER_DATA" == "true" ]]; then
  echo "Removing user data..."
  rm -rf ~/.bitbot
fi

echo ""
echo "✓ BitBot uninstalled"
echo ""

if [[ "$REMOVE_USER_DATA" != "true" ]]; then
  echo "User data preserved in ~/.bitbot"
  echo "To remove: rm -rf ~/.bitbot"
fi
```

### F3. Package Manager Uninstall

**Homebrew**:
```bash
brew uninstall bitbot
brew untap bitbot-dev/bitbot

# Cleanup (optional)
rm -rf ~/.bitbot
```

**APT**:
```bash
sudo apt remove bitbot
sudo rm /etc/apt/sources.list.d/bitbot.list

# Cleanup (optional)
rm -rf ~/.bitbot
```

**Chocolatey**:
```powershell
choco uninstall bitbot

# Cleanup WSL installation
wsl bash -c "/opt/bitbot/bin/uninstall.sh"

# Cleanup (optional)
Remove-Item -Recurse -Force "$env:USERPROFILE\.bitbot"
```

---

## Part G: Docker Images

### G1. Published Images

**Docker Hub registry**:
```
bitbot/devcontainer:latest
bitbot/devcontainer:1.0.0
bitbot/devcontainer:1.0
bitbot/devcontainer:1

bitbot/setup-container:latest
bitbot/setup-container:1.0.0

bitbot/mcp-filesystem:latest
bitbot/mcp-git-safety:latest
bitbot/mcp-discovery:latest
```

**Image pull**:
```bash
# Automatic pull on first use
bitbot work
# → Pulls bitbot/devcontainer:latest if not present

# Manual pull
docker pull bitbot/devcontainer:1.0.0
docker pull bitbot/mcp-git-safety:latest
```

### G2. Multi-Platform Builds

**Build for all platforms**:
```bash
# Setup buildx
docker buildx create --name bitbot-builder --use

# Build multi-platform images
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t bitbot/devcontainer:1.0.0 \
  -t bitbot/devcontainer:latest \
  --push \
  -f containers/devcontainer/Dockerfile \
  .
```

**Supported platforms**:
- `linux/amd64` (Intel/AMD x86_64)
- `linux/arm64` (ARM64, Apple Silicon via Docker Desktop)

### G3. Image Registry Strategy

**Primary**: Docker Hub (public)
```
docker.io/bitbot/*
```

**Mirror**: GitHub Container Registry (backup)
```
ghcr.io/bitbot-dev/*
```

**Enterprise**: Private registry support
```
# Custom registry via config
bitbot config --registry registry.company.com/bitbot
```

---

## Part H: Security & Verification

### H1. Checksums

**Generate checksums** (release process):
```bash
# Generate SHA256 checksums for all release artifacts
sha256sum bitbot-*.tar.gz bitbot-*.zip > CHECKSUMS.txt
```

**Verify download**:
```bash
# Download checksums
curl -fsSL https://github.com/bitbot-dev/bitbot/releases/download/v1.0.0/CHECKSUMS.txt \
  -o CHECKSUMS.txt

# Verify
sha256sum -c CHECKSUMS.txt --ignore-missing

# Expected output:
# bitbot-linux-amd64.tar.gz: OK
```

### H2. GPG Signatures

**Sign releases** (maintainer):
```bash
# Sign release archive
gpg --detach-sign --armor bitbot-linux-amd64.tar.gz

# Creates: bitbot-linux-amd64.tar.gz.asc
```

**Verify signature** (user):
```bash
# Download public key
curl -fsSL https://bitbot.sh/gpg.key | gpg --import

# Download signature
curl -fsSL https://github.com/bitbot-dev/bitbot/releases/download/v1.0.0/bitbot-linux-amd64.tar.gz.asc \
  -o bitbot.tar.gz.asc

# Verify
gpg --verify bitbot.tar.gz.asc bitbot-linux-amd64.tar.gz

# Expected output:
# Good signature from "BitBot Release <releases@bitbot.dev>"
```

### H3. HTTPS-Only Distribution

**All download URLs use HTTPS**:
- ✅ `https://bitbot.sh/install.sh`
- ✅ `https://github.com/bitbot-dev/bitbot/releases`
- ✅ `https://apt.bitbot.sh`
- ❌ `http://bitbot.sh` (redirects to HTTPS)

**Install script verification**:
```bash
# Install script fails on HTTP
curl -fsSL http://bitbot.sh/install.sh | bash
# → Error: HTTPS required for security
```

---

## Part I: Distribution Channels

### I1. GitHub Releases

**Release assets**:
```
bitbot-v1.0.0-linux-amd64.tar.gz
bitbot-v1.0.0-linux-arm64.tar.gz
bitbot-v1.0.0-macos-amd64.tar.gz
bitbot-v1.0.0-macos-arm64.tar.gz
bitbot-v1.0.0-windows-amd64.zip
bitbot-setup-v1.0.0.msi
CHECKSUMS.txt
*.asc (GPG signatures)
CHANGELOG.md
```

**Release notes template**:
```markdown
# BitBot v1.0.0

## What's New
- Feature 1: Description
- Feature 2: Description

## Bug Fixes
- Fix 1: Description
- Fix 2: Description

## Breaking Changes
- Change 1: Description and migration guide

## Installation

Quick install:
\`\`\`bash
curl -fsSL https://bitbot.sh/install.sh | bash
\`\`\`

Or download manually:
- [Linux (x64)](link)
- [macOS (Apple Silicon)](link)
- [Windows (MSI)](link)

See [Installation Guide](https://docs.bitbot.dev/install) for details.
```

### I2. Official Website

**Download page** (https://bitbot.dev/download):
```
BitBot v1.0.0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Quick Install
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Linux/macOS:
  curl -fsSL https://bitbot.sh/install.sh | bash

Windows (PowerShell):
  iwr -useb https://bitbot.sh/install.ps1 | iex

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Platform Downloads
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Linux
  • x64      [Download .tar.gz] [Checksum] [GPG]
  • ARM64    [Download .tar.gz] [Checksum] [GPG]

macOS
  • Intel           [Download .tar.gz] [Checksum] [GPG]
  • Apple Silicon   [Download .tar.gz] [Checksum] [GPG]

Windows
  • MSI Installer   [Download .msi] [Checksum] [GPG]
  • ZIP Archive     [Download .zip] [Checksum] [GPG]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Package Managers
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Homebrew:     brew install bitbot-dev/bitbot/bitbot
APT:          sudo apt install bitbot
Chocolatey:   choco install bitbot
Scoop:        scoop install bitbot
winget:       winget install BitBot.BitBot

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Docker Images
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

docker pull bitbot/devcontainer:latest
docker pull bitbot/setup-container:latest
```

### I3. Documentation Site

**Installation guide** (https://docs.bitbot.dev/install):
- Quick start
- Platform-specific instructions
- Troubleshooting
- Manual installation
- Offline installation
- Enterprise deployment

---

## Part J: Testing Strategy

### J1. Installation Tests

**Test matrix**:
| Test ID | Platform    | Method           | Expected Result          |
|---------|-------------|------------------|--------------------------|
| IN-01   | Ubuntu      | Quick install    | Successful installation  |
| IN-02   | Ubuntu      | APT              | Successful installation  |
| IN-03   | macOS Intel | Quick install    | Successful installation  |
| IN-04   | macOS ARM   | Homebrew         | Successful installation  |
| IN-05   | Windows 11  | PowerShell       | Successful installation  |
| IN-06   | Windows 11  | Chocolatey       | Successful installation  |
| IN-07   | All         | Offline install  | Works without internet   |
| IN-08   | All         | Custom directory | Respects BITBOT_INSTALL_DIR |

### J2. Update Tests

| Test ID | Scenario                   | Expected Result                |
|---------|----------------------------|--------------------------------|
| UP-01   | Check for updates          | Detects new version            |
| UP-02   | Update to latest           | Successful update              |
| UP-03   | Update to specific version | Installs specified version     |
| UP-04   | Backup created             | Backup in /opt/bitbot.backup.* |
| UP-05   | Config preserved           | ~/.bitbot intact after update  |
| UP-06   | Rollback after failed update | Restores previous version    |

### J3. Uninstall Tests

| Test ID | Scenario                | Expected Result                      |
|---------|-------------------------|--------------------------------------|
| UN-01   | Complete uninstall      | All files removed                    |
| UN-02   | Containers stopped      | No BitBot containers running         |
| UN-03   | User data preserved     | ~/.bitbot intact (unless --full)     |
| UN-04   | User data removed       | ~/.bitbot removed (with --full)      |
| UN-05   | Package manager uninstall | Clean removal via brew/apt/choco   |

### J4. Security Tests

| Test ID | Scenario            | Expected Result                    |
|---------|---------------------|------------------------------------|
| SE-01   | Checksum valid      | Installation succeeds              |
| SE-02   | Checksum invalid    | Installation fails with clear error |
| SE-03   | GPG signature valid | Verification succeeds              |
| SE-04   | HTTP install        | Redirects to HTTPS or fails        |
| SE-05   | MITM detection      | Checksum mismatch detected         |

---

## Part K: Success Criteria

**Functional**:
- [ ] Install script works on all platforms (Linux, macOS, Windows)
- [ ] Package managers functional (Homebrew, APT, Chocolatey, winget)
- [ ] Docker images published and multi-platform
- [ ] Updates work reliably with rollback support
- [ ] Uninstall removes everything (with user data option)

**Security**:
- [ ] SHA256 checksums for all downloads
- [ ] GPG signatures for releases
- [ ] HTTPS-only distribution
- [ ] Prerequisites checked before installation

**Usability**:
- [ ] One-line install command
- [ ] Clear installation instructions
- [ ] Fast installation (<2 minutes on broadband)
- [ ] Actionable error messages
- [ ] First-run wizard launches automatically (SPEC-09)

**Reliability**:
- [ ] Checksums prevent corrupted installations
- [ ] Backups created before updates
- [ ] Rollback mechanism works
- [ ] No data loss during updates

---

## Part L: Implementation Phases

**Phase 1: Basic Installation** (MVP):
- [ ] Install script (Linux/macOS)
- [ ] Manual download/extract
- [ ] Docker images published to Docker Hub
- [ ] Basic uninstall script

**Phase 2: Package Managers**:
- [ ] Homebrew formula
- [ ] APT repository setup
- [ ] Chocolatey package
- [ ] Scoop manifest
- [ ] winget manifest

**Phase 3: Windows Support**:
- [ ] PowerShell install script
- [ ] Windows .exe launcher (forwards to WSL)
- [ ] MSI installer
- [ ] WSL integration
- [ ] BitBot-Alpine WSL uninstall script
- [ ] Full Windows uninstaller (removes Alpine + launchers)

**Phase 4: Updates & Maintenance**:
- [ ] Version checking (daily)
- [ ] Self-update command
- [ ] Automatic backups
- [ ] Rollback mechanism
- [ ] Configuration migration

**Phase 5: Security & Polish**:
- [ ] GPG signing automation
- [ ] Checksum generation
- [ ] HTTPS enforcement
- [ ] Multi-platform Docker builds
- [ ] Release automation (CI/CD)

---

## Part M: References

**Related Specifications**:
- SPEC-05: Cross-Platform CLI (executable structure)
- SPEC-09: CLI UX & Onboarding (first-run experience)

**External Resources**:
- Homebrew formula guidelines: https://docs.brew.sh/Formula-Cookbook
- Debian packaging guide: https://www.debian.org/doc/manuals/maint-guide/
- Chocolatey creation guide: https://docs.chocolatey.org/en-us/create/create-packages
- Windows installer best practices: https://docs.microsoft.com/en-us/windows/win32/msi/

**Industry Standards**:
- Semantic versioning: https://semver.org/
- GPG signing: https://gnupg.org/
- SHA256 checksums for verification

---

**Status**: **Draft** (Design complete, implementation pending)
**Implementation Priority**: P0 (Critical - Blocking for distribution)
**Current Phase**: Planning
**Next Steps**: Implement Phase 1 (Basic Installation)

**Consolidated From**:
- Claude_Specification/10_INSTALLATION_DISTRIBUTION.md (primary source - comprehensive coverage)
