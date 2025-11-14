#!/bin/bash
# Enable Docker Desktop WSL Integration for BitBot-Alpine
#
# Modifies Docker Desktop settings.json to enable WSL integration
# Must run from inside WSL (needs access to Windows filesystem via /mnt/c)
#
# Usage: wsl -d BitBot-Alpine /opt/bitbot/lib/enable-docker-integration.sh

set -e

echo "Enabling Docker Desktop WSL integration for BitBot-Alpine..."
echo ""

# Detect Windows username
WIN_USER="${USER}"
if [ -z "$WIN_USER" ]; then
    # Fallback: try to get from /mnt/c/Users
    WIN_USER=$(ls /mnt/c/Users | grep -v "Public\|Default" | head -n1)
fi

if [ -z "$WIN_USER" ]; then
    echo "Error: Cannot detect Windows username"
    exit 1
fi

# Docker Desktop settings path
SETTINGS="/mnt/c/Users/${WIN_USER}/AppData/Roaming/Docker/settings.json"

# Check if Docker Desktop is installed
if [ ! -f "$SETTINGS" ]; then
    echo "Error: Docker Desktop settings not found"
    echo "Expected: $SETTINGS"
    echo ""
    echo "Is Docker Desktop installed?"
    exit 1
fi

echo "Found Docker Desktop settings:"
echo "  $SETTINGS"
echo ""

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq not found. Installing..."
    apk add --no-cache jq || { echo "Failed to install jq"; exit 1; }
fi

# Backup settings
BACKUP="/tmp/docker-settings-backup-$(date +%s).json"
cp "$SETTINGS" "$BACKUP"
echo "Backup created: $BACKUP"
echo ""

# Enable WSL integration for BitBot-Alpine
echo "Enabling integration..."

# Create enableIntegrationWithDistro object if it doesn't exist, then set BitBot-Alpine to true
jq '.enableIntegrationWithDistro = (.enableIntegrationWithDistro // {}) | .enableIntegrationWithDistro["BitBot-Alpine"] = true' \
    "$SETTINGS" > /tmp/settings.json

# Verify the change was made
if jq -e '.enableIntegrationWithDistro["BitBot-Alpine"] == true' /tmp/settings.json >/dev/null 2>&1; then
    mv /tmp/settings.json "$SETTINGS"
    echo "✓ Docker WSL integration enabled for BitBot-Alpine"
    echo ""
    echo "IMPORTANT: Restart Docker Desktop for changes to take effect"
    echo ""
else
    echo "Error: Failed to modify settings"
    rm /tmp/settings.json
    exit 1
fi

# Show current integration status
echo "Current WSL integrations:"
jq -r '.enableIntegrationWithDistro | to_entries[] | "  - \(.key): \(.value)"' "$SETTINGS" 2>/dev/null || echo "  (none configured)"
echo ""
