#!/bin/bash
set -e

# Shared development tool installation
# Used by templates that need additional dev tools

echo "=== Installing Development Tools ==="

# Git-delta for better diffs (no devcontainer feature available)
if ! command -v delta &> /dev/null; then
    echo "Installing git-delta..."
    GIT_DELTA_VERSION="0.18.2"
    wget -q "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_amd64.deb" -O /tmp/git-delta.deb
    dpkg -i /tmp/git-delta.deb || true
    rm /tmp/git-delta.deb

    if command -v delta &> /dev/null; then
        echo "✓ git-delta installed"
    fi
else
    echo "✓ git-delta already installed"
fi

# GitHub CLI installed via devcontainer feature
# Feature: ghcr.io/devcontainers/features/github-cli:1
# if ! command -v gh &> /dev/null; then
#     echo "Installing GitHub CLI..."
#     (type -p wget >/dev/null || (apt update && apt-get install wget -y)) \
#     && mkdir -p -m 755 /etc/apt/keyrings \
#     && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
#     && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
#     && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
#     && apt update \
#     && apt install gh -y
#
#     if command -v gh &> /dev/null; then
#         echo "✓ GitHub CLI installed"
#     fi
# else
#     echo "✓ GitHub CLI already installed: $(gh --version | head -1)"
# fi

echo "=== Development tools installation completed ==="
