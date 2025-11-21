#!/usr/bin/env bash
#
# BitBot Config Mode
#

set -euo pipefail

source "${BITBOT_HOME}/core/util/helpers.sh"
source "${BITBOT_HOME}/core/util/detect.sh"
source "${BITBOT_HOME}/core/util/devcontainer.sh"
source "${BITBOT_HOME}/core/util/prerequisites.sh"

bitbot_config() {
    local workspace_path="$1"
    local use_vscode="${2:-false}"

    # Validate workspace
    if ! validate_workspace "$workspace_path"; then
        print_error "Invalid workspace"
        echo "Run: bitbot init"
        return 1
    fi

    # Sync infrastructure before launching
    sync_workspace_infrastructure "$workspace_path"

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
