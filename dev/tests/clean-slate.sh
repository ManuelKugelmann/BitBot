#!/usr/bin/env bash
#
# BitBot Clean Slate Script
# Resets the testing environment to a fresh state
#
# Usage:
#   ./clean-slate.sh                    # Interactive prompts
#   ./clean-slate.sh --full             # Clean everything without prompts
#   ./clean-slate.sh --keep-containers  # Keep Docker containers
#   ./clean-slate.sh --stop-docker-only # Only stop Docker

set -uo pipefail

# Parse arguments
FULL=false
KEEP_CONTAINERS=false
STOP_DOCKER_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --full)
            FULL=true
            shift
            ;;
        --keep-containers)
            KEEP_CONTAINERS=true
            shift
            ;;
        --stop-docker-only)
            STOP_DOCKER_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--full] [--keep-containers] [--stop-docker-only]"
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

if [[ "$KEEP_CONTAINERS" == "true" ]]; then
    echo "  ✓ Containers kept (--keep-containers flag)"
else
    if command -v docker &>/dev/null; then
        # Check if Docker is still running
        if docker ps &>/dev/null 2>&1; then
            echo "  Docker is still running, waiting for shutdown..."
            sleep 3

            # Try again
            if docker ps &>/dev/null 2>&1; then
                echo "  Removing BitBot containers..."
                docker ps -a --filter "name=bitbot-" --format '{{.Names}}' | xargs -r docker rm -f 2>/dev/null || true

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
fi

# ============================================================================
# 3. Clean Test Workspace
# ============================================================================

echo ""
echo "[3/5] Cleaning test workspace..."

TEST_WORKSPACE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-workspace"

if [[ -d "${TEST_WORKSPACE}/.bitbot" ]]; then
    echo "  Removing ${TEST_WORKSPACE}/.bitbot..."
    rm -rf "${TEST_WORKSPACE}/.bitbot" 2>/dev/null || true
    echo "  ✓ Test workspace .bitbot removed"
else
    echo "  ✓ No .bitbot folder in test workspace"
fi

# ============================================================================
# 4. Clean BitBot Global Config
# ============================================================================

echo ""
echo "[4/5] Cleaning BitBot global config..."

BITBOT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "${BITBOT_ROOT}/config.json" ]]; then
    if [[ "$FULL" == "true" ]]; then
        REMOVE_CONFIG="y"
    else
        read -p "  Remove global config.json? (y/N): " REMOVE_CONFIG
    fi

    if [[ "$REMOVE_CONFIG" == "y" || "$REMOVE_CONFIG" == "Y" ]]; then
        rm -f "${BITBOT_ROOT}/config.json" 2>/dev/null || true
        echo "  ✓ Global config removed"
    else
        echo "  ✓ Global config kept"
    fi
else
    echo "  ✓ No global config found"
fi

# ============================================================================
# 5. Clean DevContainer CLI (if standalone)
# ============================================================================

echo ""
echo "[5/5] DevContainer CLI..."

if command -v npm &>/dev/null; then
    # Check if standalone devcontainer CLI is installed
    if npm list -g @devcontainers/cli 2>/dev/null | grep -q "@devcontainers/cli"; then
        if [[ "$FULL" == "true" ]]; then
            REMOVE_CLI="y"
        else
            read -p "  Remove standalone devcontainer CLI? (y/N): " REMOVE_CLI
        fi

        if [[ "$REMOVE_CLI" == "y" || "$REMOVE_CLI" == "Y" ]]; then
            echo "  Uninstalling @devcontainers/cli..."
            npm uninstall -g @devcontainers/cli 2>/dev/null || true
            echo "  ✓ DevContainer CLI uninstalled"
        else
            echo "  ✓ DevContainer CLI kept"
        fi
    else
        echo "  ✓ Standalone CLI not installed"
    fi
else
    echo "  - npm not found, skipping CLI check"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "=== Clean Slate Complete ==="
echo ""
echo "Environment reset:"
echo "  ✓ Docker stopped"

if [[ "$KEEP_CONTAINERS" != "true" ]]; then
    echo "  ✓ DevContainers removed"
else
    echo "  - Containers kept"
fi

echo "  ✓ Test workspace cleaned"
echo "  ✓ Global config handled"
echo "  ✓ DevContainer CLI handled"
echo ""
echo "Ready for fresh testing!"
echo ""
echo "Next steps:"
echo "  1. cd $(dirname "${BASH_SOURCE[0]}")"
echo "  2. ./run-tests.sh         # Run automated tests"
echo "  3. Or test manually:      ../bitbot version"
echo ""
