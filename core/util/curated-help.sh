#!/usr/bin/env bash
#
# BitBot Curated Help Library
#
# Component: Common Utilities
# Purpose: Pre-written help text for common errors (instant, covers 80% of cases)
#
# Usage: source this file, then use help_* variables
#

# shellcheck disable=SC2034  # Variables defined for external use via sourcing

# ============================================================================
# Docker Help
# ============================================================================

HELP_DOCKER_NOT_INSTALLED="Docker is required for BitBot DevContainers.

Install Docker Desktop:
  1. Download from: https://www.docker.com/products/docker-desktop
  2. Run installer (requires admin privileges)
  3. Enable WSL integration in Docker Desktop settings
  4. Restart and verify: docker --version

More info: https://docs.docker.com/desktop/install/windows-install/"

HELP_DOCKER_DAEMON_NOT_RUNNING="Docker daemon is not running.

Start Docker Desktop:
  • Windows: Search 'Docker Desktop' in Start menu and open it
  • macOS: Open Docker from Applications folder
  • Linux: sudo systemctl start docker

Docker takes ~30 seconds to initialize. Wait for the Docker icon to turn green.

Troubleshooting:
  • Check Docker Desktop is installed
  • Restart Docker Desktop
  • Check WSL integration is enabled (Settings → Resources → WSL Integration)"

HELP_DOCKER_PERMISSION_DENIED="Docker permission denied - your user needs to be in the 'docker' group.

Fix (requires re-login):
  1. Add user to docker group: sudo usermod -aG docker \$USER
  2. WSL: Run 'wsl --shutdown' in PowerShell, then restart WSL
  3. Linux: Log out and log back in
  4. Verify: docker ps

After fixing, re-run BitBot."

# ============================================================================
# WSL Help
# ============================================================================

HELP_WSL_NOT_ENABLED="Windows Subsystem for Linux (WSL) is required for BitBot.

Quick setup (PowerShell as Administrator):
  1. Run: wsl --install
  2. Restart your computer
  3. Complete Ubuntu setup (create username/password)
  4. Verify: wsl --list --verbose

Detailed guide:
  https://learn.microsoft.com/en-us/windows/wsl/install

Note: BitBot requires WSL 2. Check version with: wsl --list --verbose"

HELP_WSL_VERSION_1="WSL 1 detected - BitBot requires WSL 2.

Upgrade to WSL 2:
  1. Open PowerShell as Administrator
  2. Run: wsl --set-default-version 2
  3. Convert existing: wsl --set-version Ubuntu 2
  4. Verify: wsl --list --verbose (should show VERSION 2)

Why WSL 2? Better Docker performance and full Linux kernel support."

# ============================================================================
# Git Help
# ============================================================================

HELP_GIT_NOT_INSTALLED="Git is recommended for version control (optional but useful).

Install Git:
  • Windows: https://git-scm.com/download/win
    - Download installer
    - Use default options
    - Verify: git --version

  • Linux (WSL/Ubuntu):
    sudo apt update && sudo apt install git

After installing, configure:
  git config --global user.name \"Your Name\"
  git config --global user.email \"your.email@example.com\""

# ============================================================================
# DevContainer Help
# ============================================================================

HELP_DEVCONTAINER_CLI_NOT_INSTALLED="DevContainer CLI is required to build containers.

Install devcontainer CLI:
  1. Install Node.js: https://nodejs.org/ (LTS version)
  2. Install CLI: npm install -g @devcontainers/cli
  3. Verify: devcontainer --version

Note: VS Code Dev Containers extension also works.
  Install from: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers"

HELP_DEVCONTAINER_BUILD_FAILED="DevContainer failed to build.

Common causes:
  • Insufficient Docker memory
    → Increase in Docker Desktop: Settings → Resources → Memory (4GB+ recommended)

  • Network issues downloading images
    → Check internet connection
    → Try again (images cache locally)

  • Invalid devcontainer.json syntax
    → Check .devcontainer/devcontainer.json for errors
    → Validate JSON: https://jsonlint.com/

  • Docker cache corruption
    → Clear cache: docker system prune -a

Full logs: .bitbot/logs/devcontainer-error.log

Troubleshooting guide: https://code.visualstudio.com/docs/devcontainers/containers#_troubleshooting"

HELP_DEVCONTAINER_START_FAILED="DevContainer built successfully but failed to start.

Common causes:
  • Port already in use
    → Check: docker ps
    → Stop conflicting containers: docker stop <container-id>

  • Volume mount permissions
    → Check .devcontainer/devcontainer.json mounts
    → Ensure paths exist and are accessible

  • Resource limits
    → Check Docker Desktop resources
    → Close other containers: docker stop \$(docker ps -q)

  • Startup script errors
    → Check .devcontainer/Dockerfile and postCreateCommand
    → View container logs: docker logs <container-id>

Retry with: bitbot work"

# ============================================================================
# Node.js Help
# ============================================================================

HELP_NODEJS_NOT_INSTALLED="Node.js is required for AI assistance features (optional).

Install Node.js:
  • Windows/WSL: https://nodejs.org/ (download LTS version)

  • Linux (WSL/Ubuntu):
    # Via NodeSource repository (recommended)
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs

  • Alpine (in containers):
    apk add --no-cache nodejs npm

Verify installation: node --version

Note: Without Node.js, AI help falls back to curated messages (still useful!)."

# ============================================================================
# General Help
# ============================================================================

HELP_INTERNET_REQUIRED="This operation requires an internet connection.

Check your connection:
  • Open a browser and visit: https://google.com
  • Test connectivity: ping google.com
  • Check proxy/VPN settings

Once connected, run BitBot again."

HELP_ADMIN_REQUIRED="This operation requires administrator/root privileges.

Windows:
  • Right-click PowerShell → 'Run as Administrator'
  • Or use: Start-Process powershell -Verb runAs

Linux/WSL:
  • Use sudo: sudo <command>
  • Or switch to root: sudo -i

After running with admin rights, retry BitBot."

# ============================================================================
# Helper Function to Display Help
# ============================================================================

get_curated_help() {
    # Get curated help by name
    # Usage: get_curated_help <help_name>
    #
    # Example: get_curated_help "DOCKER_NOT_INSTALLED"

    local help_name="$1"
    local var_name="HELP_${help_name}"

    # Use indirect variable expansion to get help text
    echo "${!var_name}"
}
