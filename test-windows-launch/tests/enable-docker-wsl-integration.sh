#!/usr/bin/env bash
#
# Enable Docker Desktop WSL Integration for BitBot-Alpine
# Wrapper script that calls the PowerShell version

set -uo pipefail

DISTRO_NAME="${1:-BitBot-Alpine}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS_SCRIPT="$SCRIPT_DIR/enable-docker-wsl-integration.ps1"

echo ""
echo "=== Enable Docker Desktop WSL Integration ==="
echo ""

# Check if running on WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "✗ This script must be run from WSL"
    exit 1
fi

# Convert to Windows path
PS_SCRIPT_WIN=$(wslpath -w "$PS_SCRIPT")

echo "Calling PowerShell script to enable integration..."
echo ""

# Call PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "$PS_SCRIPT_WIN" -DistroName "$DISTRO_NAME"

exit_code=$?

echo ""
if [[ $exit_code -eq 0 ]]; then
    echo "✓ Script completed successfully"
else
    echo "✗ Script failed with exit code: $exit_code"
fi

exit $exit_code
