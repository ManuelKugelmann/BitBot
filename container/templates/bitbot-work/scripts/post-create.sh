#!/bin/bash
set -e

echo "=== BitBot Workspace Post-Create Setup ==="

# Run shared base setup
if [ -f "/workspace/.devcontainer/shared/scripts/setup-base.sh" ]; then
    bash /workspace/.devcontainer/shared/scripts/setup-base.sh
elif [ -f "../shared/scripts/setup-base.sh" ]; then
    bash ../shared/scripts/setup-base.sh
fi

# Verify AI tools
echo "✓ Checking AI tools..."
if command -v claude &> /dev/null; then
    echo "  Claude Code: $(claude --version 2>&1 | head -1 || echo 'installed')"
else
    echo "  ⚠ Claude Code not found"
fi

# Run fallback installations if needed
if [ -f ".devcontainer/scripts/install-fallbacks.sh" ]; then
    echo "✓ Running fallback installations..."
    bash .devcontainer/scripts/install-fallbacks.sh
elif [ -f "../shared/scripts/install-ai-tools.sh" ]; then
    bash ../shared/scripts/install-ai-tools.sh
fi

# Optional: Install additional dev tools
# Uncomment to enable:
# if [ -f "../shared/scripts/install-dev-tools.sh" ]; then
#     bash ../shared/scripts/install-dev-tools.sh
# fi

echo "=== Setup completed successfully! ==="
echo ""
echo "BitBot Workspace ready."
echo "- Claude Code: AI-powered development"
echo "- Shared configs: /home/bitbot/{.claude,.claude-flow,.opencode}"
