#!/bin/bash
# Test: Docker Desktop WSL Integration
# Purpose: Verify Docker settings.json modification
# Run from: wsl -d BitBot-Alpine /path/to/test-docker-integration.sh

set -e

echo ""
echo "=========================================="
echo " Test: Docker Desktop WSL Integration"
echo "=========================================="
echo ""

# Detect Windows username
WIN_USER="${USER}"
if [ -z "$WIN_USER" ]; then
    WIN_USER=$(ls /mnt/c/Users | grep -v "Public\|Default" | head -n1)
fi

if [ -z "$WIN_USER" ]; then
    echo "[X] FAIL: Cannot detect Windows username"
    exit 1
fi

echo "[1/6] Environment check..."
echo "  Windows User: $WIN_USER"

SETTINGS="/mnt/c/Users/${WIN_USER}/AppData/Roaming/Docker/settings.json"

if [ ! -f "$SETTINGS" ]; then
    echo "  [!] WARN: Docker Desktop not installed"
    echo "  Expected: $SETTINGS"
    echo ""
    echo "=========================================="
    echo " Test Result: SKIPPED (No Docker Desktop)"
    echo "=========================================="
    echo ""
    exit 0
fi

echo "  [+] Docker settings found: $SETTINGS"

echo ""
echo "[2/6] Checking jq availability..."
if ! command -v jq >/dev/null 2>&1; then
    echo "  [X] FAIL: jq not found"
    exit 1
fi
echo "  [+] jq available ($(jq --version))"

echo ""
echo "[3/6] Backing up current settings..."
BACKUP="/tmp/docker-settings-test-backup-$(date +%s).json"
cp "$SETTINGS" "$BACKUP"
if [ ! -f "$BACKUP" ]; then
    echo "  [X] FAIL: Backup creation failed"
    exit 1
fi
echo "  [+] Backup created: $BACKUP"

echo ""
echo "[4/6] Checking current integration status..."
CURRENT=$(jq -r '.enableIntegrationWithDistro["BitBot-Alpine"] // "not set"' "$SETTINGS" 2>/dev/null)
echo "  Current value: $CURRENT"

echo ""
echo "[5/6] Running enable-docker-integration.sh..."
echo "=========================================="
/opt/bitbot/lib/enable-docker-integration.sh
SCRIPT_EXIT=$?
echo "=========================================="

if [ $SCRIPT_EXIT -ne 0 ]; then
    echo "  [X] FAIL: Script exited with code $SCRIPT_EXIT"
    exit 1
fi
echo "  [+] Script completed successfully"

echo ""
echo "[6/6] Validating integration enabled..."
NEW_VALUE=$(jq -r '.enableIntegrationWithDistro["BitBot-Alpine"]' "$SETTINGS" 2>/dev/null)

if [ "$NEW_VALUE" != "true" ]; then
    echo "  [X] FAIL: Integration not enabled"
    echo "  Expected: true"
    echo "  Actual: $NEW_VALUE"
    exit 1
fi
echo "  [+] Integration enabled correctly"

echo ""
echo "  Backup: $BACKUP"
echo "  Restore: cp $BACKUP $SETTINGS"
echo ""

echo "=========================================="
echo " Test Result: PASS"
echo "=========================================="
echo ""
echo "Docker Desktop integration configured successfully!"
echo ""
echo "IMPORTANT: Restart Docker Desktop for changes to take effect"
echo ""

exit 0
