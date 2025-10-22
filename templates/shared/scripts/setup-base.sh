#!/bin/bash
set -e

# Shared base setup for all BitBot devcontainer templates
# This script handles common setup tasks that all templates need

echo "=== BitBot Base Setup ==="

# Ensure shared home folders exist with correct permissions
echo "✓ Setting up shared home folders..."
mkdir -p /home/bitbot/.claude
mkdir -p /home/bitbot/.claude-flow
mkdir -p /home/bitbot/.opencode
chmod 755 /home/bitbot/.claude
chmod 755 /home/bitbot/.claude-flow
chmod 755 /home/bitbot/.opencode

# Verify base tools are available
echo "✓ Verifying base tools..."
if command -v node &> /dev/null; then
    echo "  Node.js: $(node --version)"
else
    echo "  ⚠ Node.js not found"
fi

if command -v git &> /dev/null; then
    echo "  Git: $(git --version | head -1)"
else
    echo "  ⚠ Git not found"
fi

echo "=== Base setup completed ==="
