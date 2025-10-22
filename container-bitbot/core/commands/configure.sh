#!/bin/bash
# Configure devcontainer (config mode only)

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREY='\033[0;90m'
RESET='\033[0m'

WORKSPACE="${WORKSPACE:-/workspace}"

configure_devcontainer() {
    echo -e "${BLUE}DevContainer Configuration Assistant${RESET}"
    echo ""

    # Check mode
    check_config_mode

    # Show current config
    show_current_config

    # Provide recommendations
    provide_recommendations

    # Show next steps
    show_next_steps
}

check_config_mode() {
    local mode="${BITBOT_MODE:-unknown}"

    if [[ "$mode" != "config" ]]; then
        echo -e "${YELLOW}⚠ Warning: Not in config mode${RESET}"
        echo "  This command is designed for config mode"
        echo "  Current mode: ${mode}"
        echo ""
        echo "  In work mode, .devcontainer is read-only"
        echo "  Switch to config mode to edit: bitbot config"
        echo ""
        read -p "Continue anyway? (y/N) " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
        echo ""
    fi
}

show_current_config() {
    echo -e "${YELLOW}Current Configuration:${RESET}"

    if [[ -f "${WORKSPACE}/.devcontainer/devcontainer.json" ]]; then
        echo "  ✓ devcontainer.json exists"

        # Check if writable
        if [[ -w "${WORKSPACE}/.devcontainer/devcontainer.json" ]]; then
            echo -e "  ${GREEN}✓ Writable (can be modified)${RESET}"
        else
            echo -e "  ${RED}⚠ Read-only (work mode?)${RESET}"
        fi

        # Show key fields
        if command -v jq &>/dev/null; then
            local name image
            name=$(jq -r '.name // "not set"' "${WORKSPACE}/.devcontainer/devcontainer.json" 2>/dev/null || echo "error")
            image=$(jq -r '.image // .build.dockerfile // "not set"' "${WORKSPACE}/.devcontainer/devcontainer.json" 2>/dev/null || echo "error")

            echo "  Name: ${name}"
            echo "  Image/Dockerfile: ${image}"
        fi
    else
        echo "  ⚠ devcontainer.json not found"
        echo "  Create one in: ${WORKSPACE}/.devcontainer/"
    fi

    if [[ -f "${WORKSPACE}/.devcontainer/Dockerfile" ]]; then
        echo "  ✓ Dockerfile exists"
    fi

    echo ""
}

provide_recommendations() {
    echo -e "${YELLOW}Recommendations:${RESET}"

    # Detect project type and suggest features
    if [[ -f "${WORKSPACE}/package.json" ]]; then
        echo "  Node.js Project Detected:"
        echo "    • Add 'ghcr.io/devcontainers/features/node' feature"
        echo "    • Configure Node.js version in devcontainer.json"
        echo "    • Consider adding 'postCreateCommand': 'npm install'"
    fi

    if [[ -f "${WORKSPACE}/requirements.txt" ]] || [[ -f "${WORKSPACE}/pyproject.toml" ]]; then
        echo "  Python Project Detected:"
        echo "    • Add 'ghcr.io/devcontainers/features/python' feature"
        echo "    • Configure Python version in devcontainer.json"
        echo "    • Consider adding 'postCreateCommand': 'pip install -r requirements.txt'"
    fi

    if [[ -f "${WORKSPACE}/go.mod" ]]; then
        echo "  Go Project Detected:"
        echo "    • Add 'ghcr.io/devcontainers/features/go' feature"
        echo "    • Configure Go version in devcontainer.json"
        echo "    • Consider adding 'postCreateCommand': 'go mod download'"
    fi

    if [[ -d "${WORKSPACE}/.git" ]]; then
        echo "  Git Repository:"
        echo "    • Consider adding git feature for credentials"
        echo "    • Add git extensions in customizations.vscode.extensions"
    fi

    # Generic recommendations
    echo ""
    echo "  General Recommendations:"
    echo "    • Set 'remoteUser' to match host user (for permissions)"
    echo "    • Use 'features' for language runtimes instead of manual apt-get"
    echo "    • Add VS Code extensions in 'customizations.vscode.extensions'"
    echo "    • Use 'postCreateCommand' for initial setup (npm install, etc.)"

    echo ""
}

show_next_steps() {
    echo -e "${YELLOW}Next Steps:${RESET}"
    echo "  1. Edit devcontainer.json:"
    echo "     ${GREY}nano ${WORKSPACE}/.devcontainer/devcontainer.json${RESET}"
    echo ""
    echo "  2. Test configuration:"
    echo "     ${GREY}Exit container and rebuild:${RESET}"
    echo "     ${GREY}bitbot work${RESET}"
    echo ""
    echo "  3. Commit changes:"
    echo "     ${GREY}git add .devcontainer/${RESET}"
    echo "     ${GREY}git commit -m 'Update devcontainer configuration'${RESET}"
    echo ""
    echo "  4. For VS Code users:"
    echo "     ${GREY}bitbot vscode${RESET}"
    echo ""
}

# Run configuration assistant
configure_devcontainer
