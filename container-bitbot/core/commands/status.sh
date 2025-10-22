#!/bin/bash
# Show container environment status

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREY='\033[0;90m'
RESET='\033[0m'

WORKSPACE="${WORKSPACE:-/workspace}"

show_status() {
    echo -e "${BLUE}BitBot Container Status${RESET}"
    echo ""

    # Mode detection
    show_mode

    # Container info
    show_container_details

    # Workspace info
    show_workspace_info

    # DevContainer config
    show_devcontainer_status

    # Tools
    show_available_tools
}

show_mode() {
    echo -e "${YELLOW}Mode:${RESET}"

    local mode="${BITBOT_MODE:-unknown}"

    if [[ "$mode" == "work" ]]; then
        echo -e "  ${GREEN}Work Mode${RESET}"
        echo "    • Application code: Read-Write"
        echo "    • .devcontainer: Read-Only"
        echo "    • Perfect for daily development"
    elif [[ "$mode" == "config" ]]; then
        echo -e "  ${BLUE}Config Mode${RESET}"
        echo "    • Application code: Read-Write"
        echo "    • .devcontainer: Read-Write"
        echo "    • Infrastructure configuration"
    else
        echo "  ℹ Mode not set (BITBOT_MODE environment variable)"
    fi

    echo ""
}

show_container_details() {
    echo -e "${YELLOW}Container:${RESET}"
    echo "  Hostname: $(hostname)"
    echo "  User: $(whoami) (UID: $(id -u), GID: $(id -g))"
    echo "  Shell: ${SHELL}"
    echo "  Home: ${HOME}"
    echo ""
}

show_workspace_info() {
    echo -e "${YELLOW}Workspace:${RESET}"
    echo "  Path: ${WORKSPACE}"

    if [[ -d "${WORKSPACE}/.git" ]]; then
        cd "${WORKSPACE}"
        local branch
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        echo "  Git: ${branch}"
    else
        echo "  Git: Not a repository"
    fi

    if [[ -d "${WORKSPACE}/.devcontainer" ]]; then
        echo "  .devcontainer: Present"
    else
        echo "  .devcontainer: Not found"
    fi

    if [[ -d "${WORKSPACE}/.bitbot" ]]; then
        echo "  .bitbot: Initialized"
    else
        echo "  .bitbot: Not initialized"
    fi

    echo ""
}

show_devcontainer_status() {
    echo -e "${YELLOW}DevContainer Configuration:${RESET}"

    if [[ -f "${WORKSPACE}/.devcontainer/devcontainer.json" ]]; then
        echo "  ✓ devcontainer.json found"

        # Check if writable
        if [[ -w "${WORKSPACE}/.devcontainer/devcontainer.json" ]]; then
            echo -e "  ${GREEN}✓ Read-Write access${RESET}"
        else
            echo -e "  ${YELLOW}ℹ Read-Only access${RESET}"
        fi
    else
        echo "  ⚠ devcontainer.json not found"
    fi

    if [[ -f "${WORKSPACE}/.devcontainer/Dockerfile" ]]; then
        echo "  ✓ Dockerfile found"
    fi

    echo ""
}

show_available_tools() {
    echo -e "${YELLOW}Available Tools:${RESET}"

    # Common dev tools
    local tools=("git" "node" "npm" "python3" "pip" "make" "docker" "curl" "wget")

    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            local version
            case "$tool" in
                node)
                    version=$(node --version 2>/dev/null || echo "")
                    ;;
                npm)
                    version=$(npm --version 2>/dev/null || echo "")
                    ;;
                python3)
                    version=$(python3 --version 2>/dev/null | cut -d' ' -f2 || echo "")
                    ;;
                git)
                    version=$(git --version 2>/dev/null | cut -d' ' -f3 || echo "")
                    ;;
                *)
                    version=$(${tool} --version 2>/dev/null | head -1 || echo "")
                    ;;
            esac
            echo "  ✓ ${tool} ${version}"
        fi
    done

    echo ""
}

# Run status display
show_status
