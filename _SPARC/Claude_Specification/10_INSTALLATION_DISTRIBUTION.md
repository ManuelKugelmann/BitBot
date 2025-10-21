# Installation & Distribution Specification

**Feature ID**: SPEC-10
**Priority**: P0 (Critical - Blocking)
**Status**: Draft
**Depends On**: SPEC-05 (Cross-Platform CLI), SPEC-09 (First-Run Experience)
**Created**: 2025-10-17
**Last Updated**: 2025-10-17

---

## Executive Summary

Installation and distribution strategy for BitBot across Linux, macOS, and Windows. Multiple installation methods (script, package managers, manual). Automatic updates and uninstallation.

**Key Design**: Install script + package managers + manual download + auto-update = accessible installation.

---

## 1. Architecture

### 1.1 Installation Methods

**Quick install** (recommended):
```bash
curl -fsSL https://bitbot.sh/install.sh | bash
```

**Package managers**:
- Linux: apt, yum, pacman, snap
- macOS: Homebrew
- Windows: Chocolatey, Scoop, winget

**Manual download**:
- GitHub releases
- Direct download from website

### 1.2 Installation Locations

**Linux/macOS**:
```
/opt/bitbot/                    # Main installation
├── bin/
│   ├── bitbot                  # Main executable
│   ├── bitbot-core.sh
│   └── ...
├── lib/
│   └── ...
├── templates/
│   └── ...
└── config/
    └── default-config.yml

/usr/local/bin/bitbot          # Symlink to /opt/bitbot/bin/bitbot

~/.bitbot/                      # User data
├── config.yml
├── templates/
└── first-run-complete
```

**Windows**:
```
C:\Program Files\BitBot\
├── bitbot.exe                  # Windows launcher
└── wsl-install.ps1

# In WSL:
/opt/bitbot/                    # Bash implementation
~/.bitbot/                      # User data
```

---

## 2. Quick Install Script

### 2.1 Install Script Flow

**Script** (https://bitbot.sh/install.sh):
```bash
#!/usr/bin/env bash

set -e

BITBOT_VERSION="${BITBOT_VERSION:-latest}"
BITBOT_INSTALL_DIR="${BITBOT_INSTALL_DIR:-/opt/bitbot}"

echo "Installing BitBot..."

# Detect platform
detect_platform() {
  case "$(uname -s)" in
    Linux*)   echo "linux" ;;
    Darwin*)  echo "macos" ;;
    *)        echo "unknown" ;;
  esac
}

PLATFORM=$(detect_platform)

# Check prerequisites
check_prerequisites() {
  if ! command -v docker &>/dev/null; then
    echo "Error: Docker not found"
    echo "Install: https://www.docker.com/products/docker-desktop"
    exit 1
  fi

  if ! docker ps &>/dev/null; then
    echo "Error: Docker not running"
    exit 1
  fi
}

# Download and extract
download_bitbot() {
  local version="$1"
  local url="https://github.com/bitbot-dev/bitbot/releases/download/${version}/bitbot-${PLATFORM}.tar.gz"

  echo "Downloading BitBot ${version}..."
  curl -fsSL "$url" -o /tmp/bitbot.tar.gz

  echo "Extracting to ${BITBOT_INSTALL_DIR}..."
  sudo mkdir -p "$BITBOT_INSTALL_DIR"
  sudo tar -xzf /tmp/bitbot.tar.gz -C "$BITBOT_INSTALL_DIR"
  rm /tmp/bitbot.tar.gz
}

# Create symlink
create_symlink() {
  echo "Creating symlink..."
  sudo ln -sf "${BITBOT_INSTALL_DIR}/bin/bitbot" /usr/local/bin/bitbot
}

# Install global MCP services
install_mcp_services() {
  echo "Installing global MCP services..."

  sudo mkdir -p /opt/bitbot/global-mcp
  sudo cp -r "${BITBOT_INSTALL_DIR}/services/mcp" /opt/bitbot/global-mcp/

  # Start global MCP services
  cd /opt/bitbot/global-mcp
  docker-compose up -d
}

# Main installation
main() {
  echo "BitBot Installer"
  echo "================"
  echo ""

  check_prerequisites
  download_bitbot "$BITBOT_VERSION"
  create_symlink
  install_mcp_services

  echo ""
  echo "✓ BitBot installed successfully!"
  echo ""
  echo "Run: bitbot"
  echo "Help: bitbot help"
  echo "Docs: https://docs.bitbot.dev"
}

main
```

### 2.2 Installation Options

**Custom install directory**:
```bash
BITBOT_INSTALL_DIR=/usr/local/bitbot curl -fsSL https://bitbot.sh/install.sh | bash
```

**Specific version**:
```bash
BITBOT_VERSION=v1.0.0 curl -fsSL https://bitbot.sh/install.sh | bash
```

**Offline installation**:
```bash
# Download manually
wget https://github.com/bitbot-dev/bitbot/releases/download/v1.0.0/bitbot-linux.tar.gz

# Install
tar -xzf bitbot-linux.tar.gz
sudo mv bitbot /opt/bitbot
sudo ln -s /opt/bitbot/bin/bitbot /usr/local/bin/bitbot
```

---

## 3. Package Manager Installation

### 3.1 Homebrew (macOS)

**Tap and install**:
```bash
brew tap bitbot-dev/bitbot
brew install bitbot
```

**Homebrew formula** (`bitbot.rb`):
```ruby
class Bitbot < Formula
  desc "AI-Assisted Development Environment"
  homepage "https://bitbot.dev"
  url "https://github.com/bitbot-dev/bitbot/archive/v1.0.0.tar.gz"
  sha256 "abc123..."
  license "MIT"

  depends_on "docker"

  def install
    prefix.install Dir["*"]
    bin.install_symlink prefix/"bin/bitbot"
  end

  def post_install
    # Start global MCP services
    system "docker-compose", "-f", "#{prefix}/global-mcp/docker-compose.yml", "up", "-d"
  end

  test do
    system "#{bin}/bitbot", "version"
  end
end
```

### 3.2 APT (Debian/Ubuntu)

**Add repository**:
```bash
# Add GPG key
curl -fsSL https://bitbot.sh/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/bitbot.gpg

# Add repository
echo "deb [signed-by=/usr/share/keyrings/bitbot.gpg] https://apt.bitbot.sh stable main" | \
  sudo tee /etc/apt/sources.list.d/bitbot.list

# Install
sudo apt update
sudo apt install bitbot
```

**Package structure** (`.deb`):
```
bitbot_1.0.0_amd64.deb
├── opt/bitbot/
├── usr/local/bin/bitbot -> /opt/bitbot/bin/bitbot
└── DEBIAN/
    ├── control
    ├── postinst       # Post-installation script
    └── prerm          # Pre-removal script
```

### 3.3 Chocolatey (Windows)

**Install**:
```powershell
choco install bitbot
```

**Package** (`bitbot.nuspec`):
```xml
<?xml version="1.0"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>bitbot</id>
    <version>1.0.0</version>
    <title>BitBot</title>
    <authors>BitBot Team</authors>
    <description>AI-Assisted Development Environment</description>
    <projectUrl>https://bitbot.dev</projectUrl>
    <licenseUrl>https://github.com/bitbot-dev/bitbot/blob/main/LICENSE</licenseUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <dependencies>
      <dependency id="docker-desktop" version="4.0.0" />
    </dependencies>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
```

---

## 4. Windows Installation

### 4.1 Windows Installer

**MSI installer** (bitbot-setup.msi):
- Installs `bitbot.exe` to `C:\Program Files\BitBot\`
- Adds to PATH
- Checks for WSL2
- Installs bash scripts in WSL
- Creates Start Menu shortcuts

**Installation steps**:
```
1. Welcome screen
2. License agreement
3. Installation location
4. Prerequisite checks:
   - Docker Desktop installed
   - WSL2 installed
5. Install bitbot.exe
6. Install bash scripts in WSL
7. Add to PATH
8. Completion
```

### 4.2 WSL2 Integration

**Automatic WSL setup**:
```powershell
# install.ps1 (run during Windows installation)

# Check WSL2
if (!(Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Host "Installing WSL2..."
    wsl --install
}

# Install BitBot in WSL
Write-Host "Installing BitBot in WSL..."
wsl -e bash -c "curl -fsSL https://bitbot.sh/install.sh | bash"

Write-Host "✓ BitBot installed!"
```

---

## 5. Docker Images

### 5.1 Published Images

**Docker Hub**:
```
bitbot/devcontainer:latest
bitbot/setup-container:latest
bitbot/mcp-filesystem:latest
bitbot/mcp-git-safety:latest
bitbot/mcp-discovery:latest
```

**Image versioning**:
```
bitbot/devcontainer:1.0.0
bitbot/devcontainer:1.0
bitbot/devcontainer:1
bitbot/devcontainer:latest
```

### 5.2 Image Build

**Multi-platform images**:
```bash
# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t bitbot/devcontainer:1.0.0 \
  -t bitbot/devcontainer:latest \
  --push \
  .
```

---

## 6. Updates & Versioning

### 6.1 Version Checking

**Check for updates**:
```bash
bitbot version --check

# Output:
# BitBot v1.0.0
# Latest version: v1.1.0
# Update available! Run: bitbot update
```

**Automatic check** (on startup, once per day):
```bash
# Check last update check
last_check=$(cat ~/.bitbot/last-update-check 2>/dev/null || echo 0)
now=$(date +%s)

if (( now - last_check > 86400 )); then
  # Check for updates
  latest=$(curl -s https://api.github.com/repos/bitbot-dev/bitbot/releases/latest | jq -r .tag_name)

  if [[ "$latest" != "$BITBOT_VERSION" ]]; then
    echo "Update available: $latest (current: $BITBOT_VERSION)"
    echo "Run: bitbot update"
  fi

  echo "$now" > ~/.bitbot/last-update-check
fi
```

### 6.2 Update Process

**Self-update**:
```bash
bitbot update

# Or
bitbot update --version v1.1.0

# Steps:
# 1. Download new version
# 2. Backup current installation
# 3. Extract new version
# 4. Migrate configuration
# 5. Restart services
# 6. Verify installation
```

**Update script**:
```bash
bitbot_update() {
  local version="${1:-latest}"

  echo "Updating BitBot to ${version}..."

  # Backup current
  sudo cp -r /opt/bitbot "/opt/bitbot.backup.$(date +%Y%m%d)"

  # Download new version
  download_bitbot "$version"

  # Migrate config
  migrate_config

  # Restart MCP services
  cd /opt/bitbot/global-mcp
  docker-compose restart

  echo "✓ Updated to ${version}"
  echo "Backup: /opt/bitbot.backup.$(date +%Y%m%d)"
}
```

---

## 7. Uninstallation

### 7.1 Uninstall Script

**Complete removal**:
```bash
bitbot uninstall

# Or manual:
/opt/bitbot/bin/uninstall.sh

# Steps:
# 1. Stop all containers
# 2. Remove workspace containers
# 3. Remove global MCP services
# 4. Remove installation directory
# 5. Remove user data (optional)
# 6. Remove symlink
```

**Uninstall script** (`bin/uninstall.sh`):
```bash
#!/usr/bin/env bash

echo "Uninstalling BitBot..."

# Stop all BitBot containers
docker ps -a --filter "label=bitbot" --format "{{.ID}}" | xargs -r docker rm -f

# Stop global MCP services
if [ -f /opt/bitbot/global-mcp/docker-compose.yml ]; then
  cd /opt/bitbot/global-mcp
  docker-compose down
fi

# Remove installation
sudo rm -rf /opt/bitbot
sudo rm -f /usr/local/bin/bitbot

# Ask about user data
read -p "Remove user data (~/.bitbot)? [y/N]: " response
if [[ "$response" =~ ^[Yy]$ ]]; then
  rm -rf ~/.bitbot
  echo "✓ User data removed"
fi

echo "✓ BitBot uninstalled"
```

### 7.2 Package Manager Uninstall

**Homebrew**:
```bash
brew uninstall bitbot
brew untap bitbot-dev/bitbot
```

**APT**:
```bash
sudo apt remove bitbot
sudo rm /etc/apt/sources.list.d/bitbot.list
```

**Chocolatey**:
```powershell
choco uninstall bitbot
```

---

## 8. Distribution Channels

### 8.1 GitHub Releases

**Release assets**:
```
bitbot-v1.0.0-linux-amd64.tar.gz
bitbot-v1.0.0-linux-arm64.tar.gz
bitbot-v1.0.0-macos-amd64.tar.gz
bitbot-v1.0.0-macos-arm64.tar.gz
bitbot-v1.0.0-windows-amd64.zip
bitbot-setup-v1.0.0.msi
CHECKSUMS.txt
CHANGELOG.md
```

**Release process**:
1. Tag release: `git tag v1.0.0`
2. Build artifacts for all platforms
3. Generate checksums
4. Create GitHub release
5. Upload assets
6. Publish release notes

### 8.2 Official Website

**Download page** (https://bitbot.dev/download):
```
BitBot v1.0.0

Quick Install:
  curl -fsSL https://bitbot.sh/install.sh | bash

Platform Downloads:
  • Linux (x64)     [Download] [Checksum]
  • Linux (ARM64)   [Download] [Checksum]
  • macOS (Intel)   [Download] [Checksum]
  • macOS (Apple Silicon) [Download] [Checksum]
  • Windows         [Download MSI] [Checksum]

Package Managers:
  • Homebrew:     brew install bitbot-dev/bitbot/bitbot
  • APT:          sudo apt install bitbot
  • Chocolatey:   choco install bitbot

Docker Images:
  • bitbot/devcontainer:latest
  • bitbot/setup-container:latest
```

---

## 9. Verification & Security

### 9.1 Checksums

**Verify download**:
```bash
# Download checksums
curl -fsSL https://github.com/bitbot-dev/bitbot/releases/download/v1.0.0/CHECKSUMS.txt -o CHECKSUMS.txt

# Verify
sha256sum -c CHECKSUMS.txt --ignore-missing

# Expected:
# bitbot-v1.0.0-linux-amd64.tar.gz: OK
```

### 9.2 GPG Signatures

**Signed releases**:
```bash
# Download signature
curl -fsSL https://github.com/bitbot-dev/bitbot/releases/download/v1.0.0/bitbot-v1.0.0-linux-amd64.tar.gz.sig -o bitbot.tar.gz.sig

# Import public key
curl -fsSL https://bitbot.sh/gpg.key | gpg --import

# Verify
gpg --verify bitbot.tar.gz.sig bitbot-v1.0.0-linux-amd64.tar.gz

# Expected:
# Good signature from "BitBot Release <releases@bitbot.dev>"
```

---

## 10. Testing Strategy

### 10.1 Installation Tests

- IN-01: Quick install script works on Linux
- IN-02: Quick install script works on macOS
- IN-03: Homebrew installation works
- IN-04: APT installation works
- IN-05: Windows MSI installer works
- IN-06: Offline installation works

### 10.2 Update Tests

- UP-01: Version check detects new version
- UP-02: Self-update completes successfully
- UP-03: Configuration migrated after update
- UP-04: Containers continue to work after update

### 10.3 Uninstall Tests

- UN-01: Uninstall removes all files
- UN-02: Containers stopped and removed
- UN-03: User data optionally preserved
- UN-04: Package manager uninstall clean

---

## 11. Success Criteria

**Functional**:
- [ ] Install script works on all platforms
- [ ] Package managers functional
- [ ] Docker images published
- [ ] Updates work reliably
- [ ] Uninstall removes everything

**Security**:
- [ ] Checksums provided
- [ ] GPG signatures for releases
- [ ] Install script from HTTPS only
- [ ] Prerequisites checked

**Usability**:
- [ ] One-line install command
- [ ] Clear installation instructions
- [ ] Fast installation (<2 minutes)
- [ ] Good error messages

---

## 12. Implementation Phases

**Phase 1: Basic Installation**:
- Install script (Linux/macOS)
- Manual download/extract
- Docker images published
- Basic uninstall

**Phase 2: Package Managers**:
- Homebrew formula
- APT repository
- Chocolatey package
- Package manager uninstall

**Phase 3: Windows Support**:
- Windows .exe launcher
- MSI installer
- WSL integration
- PowerShell install script

**Phase 4: Updates & Maintenance**:
- Version checking
- Self-update mechanism
- Configuration migration
- Release automation

---

## 13. References

**Related Specifications**:
- SPEC-05: Cross-Platform CLI (executable structure)
- SPEC-09: First-Run Experience (post-install wizard)

**External Resources**:
- Homebrew formula guidelines
- Debian packaging guide
- Windows installer best practices

**Research Sources**:
- Industry standard installation patterns
- User feedback on installation complexity

---

**Status**: **Draft**
**Implementation Priority**: P0 (Blocking for distribution)
**Next Steps**: Implementation begins
