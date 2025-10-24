#!/bin/bash
# Analyze workspace tech stack and structure

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREY='\033[0;90m'
RESET='\033[0m'

WORKSPACE="${WORKSPACE:-/workspace}"

analyze_workspace() {
    echo -e "${BLUE}Analyzing workspace: ${WORKSPACE}${RESET}"
    echo ""

    # Project detection
    detect_project_type

    # Git status
    check_git_status

    # Dependencies
    detect_dependencies

    # Build system
    detect_build_system

    # Container info
    show_container_info
}

detect_project_type() {
    echo -e "${YELLOW}Project Type:${RESET}"

    local detected=false

    # Node.js
    if [[ -f "${WORKSPACE}/package.json" ]]; then
        echo "  ✓ Node.js project (package.json found)"
        detected=true
    fi

    # Python
    if [[ -f "${WORKSPACE}/requirements.txt" ]] || [[ -f "${WORKSPACE}/pyproject.toml" ]]; then
        echo "  ✓ Python project (requirements.txt or pyproject.toml found)"
        detected=true
    fi

    # Go
    if [[ -f "${WORKSPACE}/go.mod" ]]; then
        echo "  ✓ Go project (go.mod found)"
        detected=true
    fi

    # Rust
    if [[ -f "${WORKSPACE}/Cargo.toml" ]]; then
        echo "  ✓ Rust project (Cargo.toml found)"
        detected=true
    fi

    # Java/Maven
    if [[ -f "${WORKSPACE}/pom.xml" ]]; then
        echo "  ✓ Java/Maven project (pom.xml found)"
        detected=true
    fi

    # Java/Gradle
    if [[ -f "${WORKSPACE}/build.gradle" ]] || [[ -f "${WORKSPACE}/build.gradle.kts" ]]; then
        echo "  ✓ Java/Gradle project (build.gradle found)"
        detected=true
    fi

    if [[ "$detected" == "false" ]]; then
        echo "  ℹ No specific project type detected"
    fi

    echo ""
}

check_git_status() {
    echo -e "${YELLOW}Git Status:${RESET}"

    if [[ -d "${WORKSPACE}/.git" ]]; then
        cd "${WORKSPACE}"

        # Branch
        local branch
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        echo "  Branch: ${branch}"

        # Uncommitted changes
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            echo -e "  ${RED}⚠ Uncommitted changes detected${RESET}"
        else
            echo "  ✓ Working directory clean"
        fi

        # Unpushed commits
        local unpushed
        unpushed=$(git rev-list HEAD --not --remotes 2>/dev/null | wc -l || echo "0")
        if [[ "$unpushed" -gt 0 ]]; then
            echo -e "  ${YELLOW}⚠ ${unpushed} unpushed commit(s)${RESET}"
        else
            echo "  ✓ Up to date with remote"
        fi
    else
        echo "  ℹ Not a git repository"
    fi

    echo ""
}

detect_dependencies() {
    echo -e "${YELLOW}Dependencies:${RESET}"

    # Node.js
    if [[ -f "${WORKSPACE}/package.json" ]]; then
        if [[ -d "${WORKSPACE}/node_modules" ]]; then
            echo "  ✓ node_modules installed"
        else
            echo "  ⚠ node_modules not found (run: npm install)"
        fi
    fi

    # Python
    if [[ -f "${WORKSPACE}/requirements.txt" ]]; then
        echo "  ℹ Python requirements.txt found"
        echo "    Run: pip install -r requirements.txt"
    fi

    # Go
    if [[ -f "${WORKSPACE}/go.mod" ]]; then
        echo "  ℹ Go modules found"
        echo "    Run: go mod download"
    fi

    echo ""
}

detect_build_system() {
    echo -e "${YELLOW}Build System:${RESET}"

    # Make
    if [[ -f "${WORKSPACE}/Makefile" ]]; then
        echo "  ✓ Makefile found"
    fi

    # npm scripts
    if [[ -f "${WORKSPACE}/package.json" ]]; then
        echo "  ✓ npm scripts available (npm run)"
    fi

    # Cargo
    if [[ -f "${WORKSPACE}/Cargo.toml" ]]; then
        echo "  ✓ Cargo build system"
    fi

    # Maven
    if [[ -f "${WORKSPACE}/pom.xml" ]]; then
        echo "  ✓ Maven build system"
    fi

    # Gradle
    if [[ -f "${WORKSPACE}/build.gradle" ]] || [[ -f "${WORKSPACE}/build.gradle.kts" ]]; then
        echo "  ✓ Gradle build system"
    fi

    echo ""
}

show_container_info() {
    echo -e "${YELLOW}Container Environment:${RESET}"
    echo "  User: $(whoami)"
    echo "  UID: $(id -u)"
    echo "  GID: $(id -g)"
    echo "  Shell: ${SHELL}"
    echo "  PWD: ${PWD}"
    echo ""
}

# Run analysis
analyze_workspace
