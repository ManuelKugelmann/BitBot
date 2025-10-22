#!/usr/bin/env bash
#
# Stop Docker Desktop for Testing
# This script stops Docker Desktop and prevents auto-restart

set -uo pipefail

echo ""
echo "=== Stopping Docker Desktop for Testing ==="
echo ""

# Method 1: Use Docker Desktop CLI to quit
echo "[1/3] Sending quit command via Docker Desktop CLI..."

if [[ -f "/mnt/c/Program Files/Docker/Docker/Docker Desktop.exe" ]]; then
    # Docker Desktop has a --quit command
    powershell.exe -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe' -ArgumentList '--quit' -NoNewWindow -Wait -ErrorAction SilentlyContinue" 2>/dev/null || true
    echo "  ✓ Quit command sent"
else
    echo "  ⚠ Docker Desktop.exe not found at default path"
fi

sleep 3

# Method 2: Stop all Docker processes
echo ""
echo "[2/3] Stopping Docker processes..."

processes=(
    "Docker Desktop"
    "com.docker.backend"
    "com.docker.proxy"
    "vpnkit"
    "com.docker.dev-envs"
    "docker"
    "dockerd"
)

for proc in "${processes[@]}"; do
    powershell.exe -Command "Get-Process -Name '$proc' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue" 2>/dev/null || true
done

echo "  ✓ Processes stopped"

sleep 2

# Method 3: Stop Docker services
echo ""
echo "[3/3] Stopping Docker services..."

services=(
    "com.docker.service"
    "docker"
)

for svc in "${services[@]}"; do
    powershell.exe -Command "Stop-Service -Name '$svc' -Force -ErrorAction SilentlyContinue" 2>/dev/null || true
done

echo "  ✓ Services stopped"

# Wait for full shutdown
echo ""
echo "Waiting 5 seconds for complete shutdown..."
sleep 5

# Verify Docker is stopped
echo ""
echo "=== Verification ==="
echo ""

if docker ps &>/dev/null 2>&1; then
    echo "⚠ Docker appears to still be running"
    echo "  docker ps succeeded - Docker Desktop may have auto-restarted"
    echo ""
    echo "Trying more aggressive shutdown..."

    # Kill with taskkill
    powershell.exe -Command "taskkill /F /IM 'Docker Desktop.exe'" 2>/dev/null || true
    powershell.exe -Command "taskkill /F /IM 'com.docker.backend.exe'" 2>/dev/null || true

    sleep 3

    if docker ps &>/dev/null 2>&1; then
        echo "  ✗ Docker still running - auto-restart may be enabled in Docker Desktop settings"
        echo ""
        echo "To disable auto-start:"
        echo "  1. Open Docker Desktop Settings"
        echo "  2. General → Uncheck 'Start Docker Desktop when you log in'"
        echo "  3. Resources → Uncheck 'Auto-start Docker Desktop'"
    else
        echo "  ✓ Docker stopped after aggressive kill"
        echo ""
        echo "✓ Ready for testing Docker auto-start!"
    fi
else
    echo "✓ Docker is STOPPED (docker ps fails)"
    echo ""
    docker_error=$(docker ps 2>&1 | head -1)
    echo "Error message from docker ps:"
    echo "  $docker_error"
    echo ""
    echo "✓ Ready for testing Docker auto-start!"
fi

echo ""
echo "=== Next Steps ==="
echo ""
echo "Now test Docker auto-start:"
echo "  cd test-windows-launch/tests"
echo "  ../scripts/bitbot work"
echo ""
echo "Expected behavior:"
echo "  Starting Docker..."
echo "  Waiting for Docker to start..."
echo "  .......... 10s.......... 20s.......... 30s......"
echo "  ✓ Docker is ready (took Xs)"
echo ""
