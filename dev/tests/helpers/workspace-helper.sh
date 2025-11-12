#!/usr/bin/env bash
#
# Workspace Helper
# Provides test workspace creation and cleanup utilities
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/helpers/workspace-helper.sh"
#
#   # Basic workspace
#   workspace=$(create_test_workspace "my-test")
#   cd "$workspace"
#   # ... run tests ...
#   cleanup_test_workspace "$workspace"
#
#   # With automatic cleanup
#   workspace=$(create_test_workspace "my-test" --auto-cleanup)
#   # Cleanup happens automatically on exit
#
#   # Pre-init workspace (git repo, no .devcontainer)
#   workspace=$(setup_pre_init_workspace "my-test")
#
#   # Post-init workspace (with .devcontainer structure)
#   workspace=$(setup_post_init_workspace "my-test")
#

# ============================================================================
# Global Variables
# ============================================================================

# Track workspaces for cleanup
declare -a WORKSPACE_CLEANUP_LIST=()

# Original directory (before creating workspace)
WORKSPACE_ORIGINAL_DIR=""

# ============================================================================
# Core Workspace Functions
# ============================================================================

# Create a test workspace
# Usage: workspace=$(create_test_workspace "test-name" [--auto-cleanup])
# Returns: Path to created workspace
create_test_workspace() {
    local test_name="${1:-test}"
    local auto_cleanup=false

    # Check for --auto-cleanup flag
    if [[ "${2:-}" == "--auto-cleanup" ]]; then
        auto_cleanup=true
    fi

    # Create unique workspace path
    local workspace="/tmp/bitbot-${test_name}-$$"

    # Save original directory
    if [[ -z "$WORKSPACE_ORIGINAL_DIR" ]]; then
        WORKSPACE_ORIGINAL_DIR="$(pwd)"
    fi

    # Create workspace directory
    mkdir -p "$workspace"

    # Add to cleanup list
    WORKSPACE_CLEANUP_LIST+=("$workspace")

    # Setup auto-cleanup trap if requested
    if [[ "$auto_cleanup" == "true" ]]; then
        trap 'cleanup_all_workspaces' EXIT INT TERM
    fi

    echo "$workspace"
}

# Cleanup a test workspace
# Usage: cleanup_test_workspace "/path/to/workspace"
cleanup_test_workspace() {
    local workspace="$1"

    if [[ -z "$workspace" ]]; then
        echo "Warning: cleanup_test_workspace called with empty path" >&2
        return 1
    fi

    if [[ ! "$workspace" =~ ^/tmp/bitbot- ]]; then
        echo "Error: Refusing to delete non-test workspace: $workspace" >&2
        return 1
    fi

    if [[ -d "$workspace" ]]; then
        # Change to safe directory before removing
        cd /tmp 2>/dev/null || cd / 2>/dev/null || true
        rm -rf "$workspace"
    fi

    # Remove from cleanup list
    local new_list=()
    for ws in "${WORKSPACE_CLEANUP_LIST[@]}"; do
        if [[ "$ws" != "$workspace" ]]; then
            new_list+=("$ws")
        fi
    done
    WORKSPACE_CLEANUP_LIST=("${new_list[@]}")
}

# Cleanup all tracked workspaces
# Usage: cleanup_all_workspaces
cleanup_all_workspaces() {
    for workspace in "${WORKSPACE_CLEANUP_LIST[@]}"; do
        cleanup_test_workspace "$workspace"
    done
    WORKSPACE_CLEANUP_LIST=()
}

# ============================================================================
# Workspace Setup Functions
# ============================================================================

# Setup a pre-init workspace (git repo, no .devcontainer)
# Usage: workspace=$(setup_pre_init_workspace "test-name" [--auto-cleanup])
# Returns: Path to workspace
setup_pre_init_workspace() {
    local test_name="${1:-test}"
    local auto_cleanup_flag="${2:-}"

    # Create basic workspace
    local workspace
    workspace=$(create_test_workspace "$test_name" "$auto_cleanup_flag")

    # Initialize git repo
    (
        cd "$workspace"
        git init -q
        git config user.email "test@bitbot.local"
        git config user.name "BitBot Test"

        # Create initial commit (some tests expect this)
        echo "# Test Project" > README.md
        git add README.md
        git commit -q -m "Initial commit" 2>/dev/null || true
    )

    echo "$workspace"
}

# Setup a post-init workspace (with .devcontainer structure)
# Usage: workspace=$(setup_post_init_workspace "test-name" [--auto-cleanup])
# Returns: Path to workspace
setup_post_init_workspace() {
    local test_name="${1:-test}"
    local auto_cleanup_flag="${2:-}"

    # Start with pre-init workspace
    local workspace
    workspace=$(setup_pre_init_workspace "$test_name" "$auto_cleanup_flag")

    # Ensure BITBOT_HOME is set
    if [[ -z "${BITBOT_HOME:-}" ]]; then
        echo "Error: BITBOT_HOME not set. Cannot setup post-init workspace." >&2
        return 1
    fi

    # Create .devcontainer structure
    (
        cd "$workspace"

        # Create directories
        mkdir -p .devcontainer/bitbot
        mkdir -p .bitbot/internal/container/home
        mkdir -p .bitbot/internal/global/.claude

        # Copy devcontainer template files (bitbot-work as default)
        if [[ -f "${BITBOT_HOME}/container/templates/bitbot-work/devcontainer.json" ]]; then
            cp "${BITBOT_HOME}/container/templates/bitbot-work/devcontainer.json" .devcontainer/
        fi

        if [[ -f "${BITBOT_HOME}/container/templates/bitbot-work/Dockerfile" ]]; then
            cp "${BITBOT_HOME}/container/templates/bitbot-work/Dockerfile" .devcontainer/
        fi

        # Copy BitBot container scripts
        if [[ -d "${BITBOT_HOME}/container/bitbot" ]]; then
            cp -r "${BITBOT_HOME}/container/bitbot/"* .devcontainer/bitbot/
        fi

        # Create mount source files
        if [[ -f "${BITBOT_HOME}/container/templates/bitbot-base/home/.tmux.conf" ]]; then
            cp "${BITBOT_HOME}/container/templates/bitbot-base/home/.tmux.conf" \
               .bitbot/internal/container/home/.tmux.conf
        fi

        # Create placeholder Claude files
        touch .bitbot/internal/global/.claude/CLAUDE.md
        echo '{}' > .bitbot/internal/global/.claude/settings.json
        echo '{}' > .bitbot/internal/global/.claude/.credentials.json
    )

    echo "$workspace"
}

# ============================================================================
# Environment Setup
# ============================================================================

# Setup test environment variables
# Usage: setup_test_environment
setup_test_environment() {
    # Set BITBOT_HOME if not already set
    if [[ -z "${BITBOT_HOME:-}" ]]; then
        # Try to detect from script location
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
        export BITBOT_HOME="$script_dir"
    fi

    # Unset CI variables for interactive tests (if needed)
    # Note: Call unset_ci_environment separately if testing interactive mode
}

# Unset CI environment variables (for interactive prompt testing)
# Usage: unset_ci_environment
unset_ci_environment() {
    unset CI
    unset GITHUB_ACTIONS
    unset GITLAB_CI
    unset JENKINS_URL
    unset TRAVIS
    unset CIRCLECI
}

# Restore CI environment (if it was set)
# Usage: restore_ci_environment
restore_ci_environment() {
    if [[ "${CI_WAS_SET:-}" == "true" ]]; then
        export CI="true"
    fi
}

# ============================================================================
# Utility Functions
# ============================================================================

# Get BitBot root directory
# Usage: bitbot_root=$(get_bitbot_root)
get_bitbot_root() {
    if [[ -n "${BITBOT_HOME:-}" ]]; then
        echo "$BITBOT_HOME"
    else
        # Try to detect from script location
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
        echo "$script_dir"
    fi
}

# Get BitBot command path
# Usage: bitbot_cmd=$(get_bitbot_command)
get_bitbot_command() {
    local bitbot_root
    bitbot_root=$(get_bitbot_root)
    echo "${bitbot_root}/core/bitbot"
}

# Export functions for use in subshells
export -f create_test_workspace
export -f cleanup_test_workspace
export -f cleanup_all_workspaces
export -f setup_pre_init_workspace
export -f setup_post_init_workspace
export -f setup_test_environment
export -f unset_ci_environment
export -f restore_ci_environment
export -f get_bitbot_root
export -f get_bitbot_command
