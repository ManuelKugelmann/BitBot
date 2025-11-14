#!/bin/bash
set -e

# Shared AI tool installation
# Used by workspace and config templates

echo "=== Installing AI Tools ==="

# Claude Code installed via devcontainer feature
# if ! command -v claude &> /dev/null; then
#     echo "Installing Claude Code..."
#     npm install -g @anthropic-ai/claude-code@latest || {
#         echo "⚠ Claude Code installation failed, continuing..."
#     }
# else
#     echo "✓ Claude Code already installed: $(claude --version 2>&1 | head -1 || echo 'unknown version')"
# fi

# Install Claude Flow if not already installed
if ! command -v claude-flow &> /dev/null; then
    echo "Installing Claude Flow (optional)..."
    npm install -g @anthropic-ai/claude-flow@latest || {
        echo "⚠ Claude Flow not available, skipping..."
    }
else
    echo "✓ Claude Flow already installed"
fi

# Install Open Code if not already installed
if ! command -v opencode &> /dev/null; then
    echo "Installing Open Code (optional)..."
    npm install -g @opencode/cli@latest || {
        echo "⚠ Open Code not available, skipping..."
    }
else
    echo "✓ Open Code already installed"
fi

echo "=== AI tools installation completed ==="
