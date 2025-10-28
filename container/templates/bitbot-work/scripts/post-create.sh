#!/bin/bash
set -e

echo "=== BitBot Workspace Post-Create Setup ==="

# Verify AI tools
echo "✓ Checking AI tools..."
if command -v claude &> /dev/null; then
    echo "  Claude Code: $(claude --version 2>&1 | head -1 || echo 'installed')"
else
    echo "  ⚠ Claude Code not found"
fi

# Run AI tool installations if needed
if [ -f "/workspace/.devcontainer/scripts/install-fallbacks.sh" ]; then
    echo "✓ Running AI tool installations..."
    bash /workspace/.devcontainer/scripts/install-fallbacks.sh
fi

echo "=== Setup completed successfully! ==="
echo ""
echo "BitBot Workspace ready."
echo "- Claude Code: AI-powered development"
echo "- Shared configs: /root/{.claude,.claude-flow,.opencode}"
