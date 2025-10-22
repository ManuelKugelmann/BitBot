#!/bin/bash
set -e

echo "=== Installing Fallback Tools ==="

# This script installs tools not available via devcontainer features
# or provides alternative installations when features fail

# Install Claude Flow manually if feature is not enabled
if ! command -v claude-flow &> /dev/null; then
    echo "Installing Claude Flow (fallback)..."
    npm install -g @anthropic-ai/claude-flow@latest || {
        echo "⚠ Claude Flow not available via npm, skipping..."
    }
fi

# Install Open Code manually if feature is not enabled
if ! command -v opencode &> /dev/null; then
    echo "Installing Open Code (fallback)..."
    npm install -g @opencode/cli@latest || {
        echo "⚠ Open Code not available via npm, skipping..."
    }
fi

# Install additional development tools
echo "Installing additional tools..."

# Git-delta for better diffs
if ! command -v delta &> /dev/null; then
    echo "Installing git-delta..."
    GIT_DELTA_VERSION="0.18.2"
    wget -q "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_amd64.deb" -O /tmp/git-delta.deb
    dpkg -i /tmp/git-delta.deb || true
    rm /tmp/git-delta.deb
fi

# GitHub CLI (if not already installed)
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI..."
    (type -p wget >/dev/null || (apt update && apt-get install wget -y)) \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt update \
    && apt install gh -y
fi

echo "=== Fallback installations completed ==="
