#!/usr/bin/env bash
#
# BitBot Config Mode
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"

source "${LIB_DIR}/util/helpers.sh"
source "${LIB_DIR}/util/detect.sh"
source "${LIB_DIR}/util/devcontainer.sh"
source "${LIB_DIR}/util/prerequisites.sh"

bitbot_config() {
    local workspace_path="$1"
    local use_vscode="${2:-false}"

    # Validate workspace
    if ! validate_workspace "$workspace_path"; then
        print_error "Invalid workspace"
        echo "Run: bitbot init"
        return 1
    fi

    # Git warning (non-blocking)
    if check_git_uncommitted "$workspace_path"; then
        print_warning "Uncommitted changes detected"
        echo "  Recommendation: Commit .devcontainer changes"
        echo ""
    fi

    # Launch config mode
    launch_config_devcontainer "$workspace_path" "$use_vscode"
}

export -f bitbot_config
