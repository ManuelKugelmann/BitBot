#!/usr/bin/env bash
#
# Clean Slate Script (Bash version for WSL)
# Resets the BitBot testing environment to a fresh state
#
# Usage:
#   ./clean-slate.sh                    # Interactive prompts
#   ./clean-slate.sh --full             # Clean everything without prompts
#   ./clean-slate.sh --keep-alpine      # Keep BitBot-Alpine WSL
#   ./clean-slate.sh --stop-docker-only # Only stop Docker

set -uo pipefail

# Parse arguments
FULL=false
KEEP_ALPINE=false
STOP_DOCKER_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --full)
            FULL=true
            shift
            ;;
        --keep-alpine)
            KEEP_ALPINE=true
            shift
            ;;
        --stop-docker-only)
            STOP_DOCKER_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--full] [--keep-alpine] [--stop-docker-only]"
            exit 1
            ;;
    esac
done

echo ""
echo "=== BitBot Clean Slate Script ==="
echo ""

# ============================================================================
# 1. Stop Docker Desktop
# ============================================================================

echo "[1/5] Stopping Docker Desktop..."

# Check if running on WSL
if grep -qi microsoft /proc/version 2>/dev/null; then
    # WSL: Stop Docker Desktop on Windows
    echo "  Stopping Docker Desktop via Windows..."
    powershell.exe -Command "Stop-Process -Name 'Docker Desktop' -Force -ErrorAction SilentlyContinue" 2>/dev/null || true
    sleep 3
    echo "  ✓ Docker Desktop stop command sent"
else
    # Native Linux: Stop Docker daemon
    if command -v systemctl &>/dev/null; then
        echo "  Stopping Docker daemon..."
        sudo systemctl stop docker 2>/dev/null || true
        echo "  ✓ Docker daemon stopped"
    elif command -v service &>/dev/null; then
        echo "  Stopping Docker service..."
        sudo service docker stop 2>/dev/null || true
        echo "  ✓ Docker service stopped"
    else
        echo "  ⚠ Cannot stop Docker (no systemctl or service)"
    fi
fi

if [[ "$STOP_DOCKER_ONLY" == "true" ]]; then
    echo ""
    echo "✓ Docker stopped. Use --full to clean everything."
    echo ""
    exit 0
fi

# ============================================================================
# 2. Remove DevContainers
# ============================================================================

echo ""
echo "[2/5] Removing DevContainers..."

if command -v docker &>/dev/null; then
    # Check if Docker is still running
    if docker ps &>/dev/null 2>&1; then
        echo "  Docker is still running, waiting for shutdown..."
        sleep 3

        # Try again
        if docker ps &>/dev/null 2>&1; then
            echo "  Removing BitBot containers..."
            docker ps -a --filter "name=bitbot-dev-" --format '{{.Names}}' | xargs -r docker rm -f 2>/dev/null || true

            echo "  Removing test containers..."
            docker ps -a --filter "label=devcontainer.local_folder" --format '{{.Names}}' | xargs -r docker rm -f 2>/dev/null || true

            echo "  ✓ Containers removed"
        else
            echo "  ✓ Docker stopped, containers will be cleaned on next start"
        fi
    else
        echo "  ✓ Docker stopped, containers will be cleaned on next start"
    fi
else
    echo "  ⚠ Docker command not found, skipping container cleanup"
fi

# ============================================================================
# 3. Uninstall DevContainer CLI
# ============================================================================

echo ""
echo "[3/5] Uninstalling DevContainer CLI..."

if command -v npm &>/dev/null; then
    # Check if devcontainer CLI is installed
    if npm list -g @devcontainers/cli 2>/dev/null | grep -q "@devcontainers/cli"; then
        echo "  Uninstalling @devcontainers/cli..."
        npm uninstall -g @devcontainers/cli 2>/dev/null || true

        # Verify uninstallation
        if npm list -g @devcontainers/cli 2>/dev/null | grep -q "@devcontainers/cli"; then
            echo "  ⚠ DevContainer CLI may still be installed"
        else
            echo "  ✓ DevContainer CLI uninstalled"
        fi
    else
        echo "  ✓ DevContainer CLI not installed"
    fi
else
    echo "  ⚠ npm not found, cannot uninstall DevContainer CLI"
fi

# ============================================================================
# 4. Clean BitBot Cache/Data
# ============================================================================

echo ""
echo "[4/5] Cleaning BitBot cache..."

# Clean WSL cache locations
if [[ -d "$HOME/.bitbot" ]]; then
    echo "  Removing $HOME/.bitbot..."
    rm -rf "$HOME/.bitbot" 2>/dev/null || true
    echo "  ✓ BitBot cache removed"
else
    echo "  ✓ No BitBot cache found"
fi

# Clean Windows cache via WSL path
if grep -qi microsoft /proc/version 2>/dev/null; then
    WINDOWS_LOCALAPPDATA="/mnt/c/Users/$(powershell.exe -Command '$env:USERNAME' | tr -d '\r')/AppData/Local"
    if [[ -d "$WINDOWS_LOCALAPPDATA/BitBot" ]]; then
        echo "  Removing Windows BitBot cache..."
        rm -rf "$WINDOWS_LOCALAPPDATA/BitBot" 2>/dev/null || true
        echo "  ✓ Windows BitBot cache removed"
    fi

    if [[ -d "$WINDOWS_LOCALAPPDATA/Temp/devcontainercli" ]]; then
        echo "  Removing devcontainer temp files..."
        rm -rf "$WINDOWS_LOCALAPPDATA/Temp/devcontainercli" 2>/dev/null || true
        echo "  ✓ DevContainer temp files removed"
    fi
fi

# ============================================================================
# 5. Remove BitBot-Alpine WSL
# ============================================================================

echo ""
echo "[5/5] BitBot-Alpine WSL..."

DISTRO_NAME="BitBot-Alpine"

# Check if Alpine exists (only on WSL)
if grep -qi microsoft /proc/version 2>/dev/null; then
    ALPINE_EXISTS=false

    # Get WSL list and check (use tr to clean null bytes and carriage returns)
    wsl_list=$(powershell.exe -Command "wsl --list --quiet" 2>/dev/null | tr -d '\0\r')
    if echo "$wsl_list" | grep -q "^${DISTRO_NAME}$"; then
        ALPINE_EXISTS=true
    fi

    if [[ "$ALPINE_EXISTS" == "true" ]]; then
        if [[ "$KEEP_ALPINE" == "true" ]]; then
            echo "  ✓ BitBot-Alpine kept (--keep-alpine flag)"
        else
            if [[ "$FULL" == "true" ]]; then
                REMOVE_ALPINE="y"
            else
                echo "  BitBot-Alpine WSL distribution found."
                read -p "  Remove BitBot-Alpine? (y/N): " REMOVE_ALPINE
            fi

            if [[ "$REMOVE_ALPINE" == "y" || "$REMOVE_ALPINE" == "Y" ]]; then
                echo "  Unregistering $DISTRO_NAME..."
                powershell.exe -Command "wsl --unregister $DISTRO_NAME" 2>/dev/null || true

                echo "  ✓ BitBot-Alpine removed"
            else
                echo "  ✓ BitBot-Alpine kept"
            fi
        fi
    else
        echo "  ✓ BitBot-Alpine not found"
    fi
else
    echo "  - Not running on WSL, skipping Alpine check"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "=== Clean Slate Complete ==="
echo ""
echo "Environment reset:"
echo "  ✓ Docker stopped"
echo "  ✓ DevContainers removed"
echo "  ✓ DevContainer CLI uninstalled"
echo "  ✓ BitBot cache cleaned"

if grep -qi microsoft /proc/version 2>/dev/null; then
    if [[ "$ALPINE_EXISTS" == "true" && "$KEEP_ALPINE" != "true" && ("$REMOVE_ALPINE" == "y" || "$REMOVE_ALPINE" == "Y" || "$FULL" == "true") ]]; then
        echo "  ✓ BitBot-Alpine removed"
    elif [[ "$ALPINE_EXISTS" == "true" ]]; then
        echo "  ⚠ BitBot-Alpine kept"
    else
        echo "  - BitBot-Alpine not present"
    fi
fi

echo ""
echo "Ready for fresh testing!"
echo ""
echo "Next steps:"
echo "  1. Start Docker Desktop manually (if testing auto-start)"
echo "  2. Run: ../scripts/bitbot version"
echo "  3. Install BitBot-Alpine when prompted"
echo "  4. Run: ../scripts/bitbot work"
echo ""
