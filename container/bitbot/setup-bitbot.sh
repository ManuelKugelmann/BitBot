#!/bin/sh
# BitBot Alpine Setup Script
# Runs once after WSL distro import to configure BitBot-Alpine environment
#
# Usage: Called automatically by install-bitbot.cmd after wsl --import
#   OR manually: wsl -d BitBot-Alpine sh /path/to/setup-bitbot.sh

set -e  # Exit on error

echo ""
echo "========================================="
echo " BitBot Alpine Setup"
echo "========================================="
echo ""

# Check if running inside Alpine
if [ ! -f /etc/alpine-release ]; then
    echo "Error: This script must run inside Alpine Linux"
    exit 1
fi

# Install essential packages
echo "[>] Installing essential packages..."
apk add --no-cache \
    bash \
    git \
    docker-cli \
    nodejs \
    npm \
    curl \
    ca-certificates \
    jq \
    || { echo "[X] Package installation failed"; exit 1; }

echo "[+] Base packages installed"
echo ""

# Install @devcontainers/cli
echo "[>] Installing @devcontainers/cli..."
npm install -g @devcontainers/cli 2>&1 | grep -v "npm WARN" || true

if command -v devcontainer >/dev/null 2>&1; then
    echo "[+] @devcontainers/cli installed ($(devcontainer --version))"
else
    echo "[!] @devcontainers/cli installation may have failed"
fi
echo ""

# Set up BitBot directories
echo "[>] Setting up BitBot directories..."
mkdir -p /opt/bitbot/bin /opt/bitbot/lib
echo "[+] Directories created: /opt/bitbot/{bin,lib}"
echo ""

# Configure bash as default shell
echo "[>] Configuring bash as default shell..."
if ! grep -q "/bin/bash" /etc/passwd 2>/dev/null; then
    # Update root user to use bash
    sed -i 's|:/bin/ash|:/bin/bash|g' /etc/passwd 2>/dev/null || true
    echo "[+] Bash set as default shell"
else
    echo "[i] Bash already configured"
fi
echo ""

# Enable Docker Desktop integration
echo "[>] Enabling Docker Desktop integration..."
DOCKER_SCRIPT="/opt/bitbot/lib/enable-docker-integration.sh"

if [ -f "$DOCKER_SCRIPT" ]; then
    # Script already exists (mounted or copied)
    bash "$DOCKER_SCRIPT" || echo "[!] Docker integration setup skipped (may need manual configuration)"
else
    # Download from BitBot repository or skip
    echo "[i] Docker integration script not found"
    echo "[i] You can enable Docker integration later by running:"
    echo "    wsl -d BitBot-Alpine /opt/bitbot/lib/enable-docker-integration.sh"
fi
echo ""

# Display completion message
echo "========================================="
echo " ✓ BitBot Alpine Setup Complete"
echo "========================================="
echo ""
echo "Installed:"
echo "  - bash, git, docker-cli"
echo "  - nodejs, npm"
echo "  - @devcontainers/cli"
echo "  - curl, ca-certificates, jq"
echo ""
echo "Next steps:"
echo "  1. Restart Docker Desktop (if running)"
echo "  2. Run: bitbot work"
echo ""
