#!/bin/bash
#
# Example Usage: AI-Enhanced Error Handling with Auto-Fix
#
# Demonstrates all features of the enhanced error system:
#   • Curated help (instant)
#   • AI on request (?)
#   • Conversational AI (follow-up questions)
#   • Auto-fix (X)
#   • Multiple scenarios

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source required utilities
export BITBOT_HOME="$BITBOT_ROOT"
# shellcheck source=../../../core/util/helpers.sh
source "$BITBOT_ROOT/core/util/helpers.sh"
# shellcheck source=../../../core/util/curated-help.sh
source "$BITBOT_ROOT/core/util/curated-help.sh"
# shellcheck source=../../../core/util/auto-fix.sh
source "$BITBOT_ROOT/core/util/auto-fix.sh"

echo "=== AI-Enhanced Error Handling Examples ==="
echo ""

# ============================================================================
# Example 1: Docker Not Running (with auto-fix)
# ============================================================================

example_docker_not_running() {
    echo "Example 1: Docker daemon not running"
    echo "======================================"
    echo ""

    # Simulated check
    if ! docker ps &>/dev/null; then
        # Enhanced error with curated help + AI option + auto-fix
        print_error_with_ai_help \
            "Docker daemon not running" \
            "$HELP_DOCKER_DAEMON_NOT_RUNNING" \
            "Docker daemon startup troubleshooting" \
            "autofix_start_docker_daemon" \
            "What would you like to do?"

        local result=$?
        case $result in
            0)
                echo ""
                print_info "Continuing without Docker..."
                ;;
            1)
                echo ""
                print_info "Exiting - please fix Docker and retry"
                return 1
                ;;
            2)
                echo ""
                print_success "Auto-fix completed - rechecking Docker..."
                # Would re-run check here
                ;;
        esac
    else
        print_success "Docker is running"
    fi
}

# ============================================================================
# Example 2: Docker Not Installed (no auto-fix, but AI help available)
# ============================================================================

example_docker_not_installed() {
    echo "Example 2: Docker not installed"
    echo "================================"
    echo ""

    # Simulated check
    if ! command -v docker &>/dev/null; then
        # Enhanced error with curated help + AI option (no auto-fix for installation)
        print_error_with_ai_help \
            "Docker not found" \
            "$HELP_DOCKER_NOT_INSTALLED" \
            "Docker Desktop installation for Windows beginners" \
            "" \
            "Continue without Docker?"

        if [ $? -eq 0 ]; then
            echo ""
            print_warning "Continuing without Docker (limited functionality)"
        else
            echo ""
            print_info "Exiting - please install Docker and retry"
            return 1
        fi
    else
        print_success "Docker is installed"
    fi
}

# ============================================================================
# Example 3: WSL Not Enabled (with auto-fix that requires reboot)
# ============================================================================

example_wsl_not_enabled() {
    echo "Example 3: WSL not enabled"
    echo "=========================="
    echo ""

    # Simulated check
    if ! grep -q microsoft /proc/version 2>/dev/null; then
        # This would only work on Windows, showing for demonstration
        print_error_with_ai_help \
            "WSL not detected" \
            "$HELP_WSL_NOT_ENABLED" \
            "WSL installation and setup for Windows" \
            "autofix_enable_wsl" \
            "What would you like to do?"

        if [ $? -ne 0 ]; then
            print_info "WSL is required - exiting"
            return 1
        fi
    else
        print_success "WSL is enabled"
    fi
}

# ============================================================================
# Example 4: Git Not Installed (with auto-fix)
# ============================================================================

example_git_not_installed() {
    echo "Example 4: Git not installed (optional)"
    echo "========================================"
    echo ""

    # Simulated check
    if ! command -v git &>/dev/null; then
        print_error_with_ai_help \
            "Git not found" \
            "$HELP_GIT_NOT_INSTALLED" \
            "Git installation" \
            "autofix_install_git" \
            "Install Git now?"

        local result=$?
        if [ $result -eq 2 ]; then
            # Auto-fix succeeded, verify
            if command -v git &>/dev/null; then
                print_success "Git installed successfully"
            fi
        fi
    else
        print_success "Git is installed"
    fi
}

# ============================================================================
# Example 5: DevContainer Build Failed (complex troubleshooting)
# ============================================================================

example_devcontainer_failed() {
    echo "Example 5: DevContainer build failed"
    echo "====================================="
    echo ""

    # Simulated failure
    local build_failed=true

    if [ "$build_failed" = true ]; then
        print_error_with_ai_help \
            "DevContainer failed to build" \
            "$HELP_DEVCONTAINER_BUILD_FAILED" \
            "DevContainer build failure diagnosis and troubleshooting" \
            "autofix_clear_docker_cache" \
            "What would you like to do?"

        # User can:
        # - Type ? to get AI help
        # - Ask questions like "why does docker run out of memory?"
        # - Type X to clear Docker cache
        # - Type y to continue anyway
        # - Type N to exit
    fi
}

# ============================================================================
# Main Demo
# ============================================================================

echo "This demo shows 5 different error scenarios."
echo "For each, you can:"
echo "  • Press Enter to see curated help (instant)"
echo "  • Type '?' for AI assistance"
echo "  • Ask follow-up questions (conversational AI)"
echo "  • Type 'X' to auto-fix (where available)"
echo "  • Type 'y' to continue, 'N' to skip"
echo ""
echo "Press Ctrl+C to exit anytime"
echo ""
read -r -p "Press Enter to start demo..."
echo ""

# Run examples (comment out to test specific ones)

# Example 1: Docker daemon (has auto-fix)
# example_docker_not_running || true
# echo ""
# echo ""

# Example 2: Docker not installed (AI help, no auto-fix)
example_docker_not_installed || true
echo ""
echo ""

# Example 3: WSL (auto-fix requires reboot)
# example_wsl_not_enabled || true
# echo ""
# echo ""

# Example 4: Git (simple auto-fix)
# example_git_not_installed || true
# echo ""
# echo ""

# Example 5: DevContainer (complex troubleshooting + AI)
# example_devcontainer_failed || true
# echo ""
# echo ""

echo "=== Demo Complete ==="
echo ""
echo "Features demonstrated:"
echo "  ✓ Instant curated help (0ms response)"
echo "  ✓ Optional AI assistance (?)"
echo "  ✓ Conversational AI (follow-up questions)"
echo "  ✓ Auto-fix functionality (X)"
echo "  ✓ User control (y/N/?/X)"
echo ""
echo "This provides an excellent beginner experience:"
echo "  • Fast path: Just follow curated instructions"
echo "  • Stuck?: Ask AI for help"
echo "  • Need more info?: Have a conversation with AI"
echo "  • Want automation?: Let BitBot auto-fix"
