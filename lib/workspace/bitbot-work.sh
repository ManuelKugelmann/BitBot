#!/usr/bin/env bash
#
# BitBot Work Mode
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")"

source "${LIB_DIR}/util/helpers.sh"
source "${LIB_DIR}/util/detect.sh"
source "${LIB_DIR}/util/devcontainer.sh"
source "${LIB_DIR}/util/prerequisites.sh"

bitbot_work() {
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
        local count
        count=$(count_uncommitted_files "$workspace_path")
        echo "  Files modified: $count"
        echo "  Recommendation: Commit before changes"
        echo ""
    fi

    # Launch work mode
    launch_work_devcontainer "$workspace_path" "$use_vscode"
}

export -f bitbot_work
