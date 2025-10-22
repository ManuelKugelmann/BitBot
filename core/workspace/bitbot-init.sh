#!/usr/bin/env bash
#
# BitBot Workspace Initialization
#
# Component: Workspace Initialization (bitbot init)
# Purpose: Initialize a new BitBot workspace in current directory
#

set -euo pipefail

# Source utilities
# shellcheck source=../util/helpers.sh
source "${BITBOT_HOME}/core/util/helpers.sh"
# shellcheck source=../util/git.sh
source "${BITBOT_HOME}/core/util/git.sh"
# shellcheck source=../util/detect.sh
source "${BITBOT_HOME}/core/util/detect.sh"
# shellcheck source=../util/devcontainer.sh
source "${BITBOT_HOME}/core/util/devcontainer.sh"

# ============================================================================
# Main Initialization Function
# ============================================================================

bitbot_init() {
    # Initialize BitBot workspace in current directory

    local workspace_path
    workspace_path=$(get_current_directory)

    # Check if already initialized
    if [[ -d "${workspace_path}/.bitbot" ]]; then
        print_error "Workspace already initialized"
        echo ""
        echo "Found existing .bitbot/ directory in:"
        echo "  $workspace_path"
        echo ""
        echo "To reinitialize, first remove .bitbot/:"
        echo "  \$ rm -rf .bitbot/"
        echo "  \$ bitbot init"
        echo ""
        echo "Or just launch work mode:"
        echo "  \$ bitbot work"
        echo ""
        return 1
    fi

    print_step "Initializing BitBot workspace: $workspace_path"
    echo ""

    # Git push recommendation - first step before any changes
    recommend_git_push_before_init "$workspace_path"

    # Git safety checks
    check_git_safety "$workspace_path"

    # Create workspace structure
    create_workspace_structure "$workspace_path"

    # Create/copy .devcontainer if needed
    setup_devcontainer "$workspace_path"

    # Launch config mode
    echo ""
    echo "Launching config mode..."
    echo ""
    echo "Config mode runs BitBot AI agent in a devcontainer optimized for devcontainer setup."
    echo "The AI provides guidance and help to configure your .devcontainer."
    echo "Close VS Code or terminal when finished."
    echo ""

    # Launch config mode
    launch_config_devcontainer "$workspace_path"
}

# ============================================================================
# Create Workspace Structure
# ============================================================================

create_workspace_structure() {
    # Create minimal .bitbot structure
    local workspace_path="$1"

    echo "Creating workspace structure..."

    # Create directories
    create_directory "${workspace_path}/.bitbot"
    create_directory "${workspace_path}/.bitbot/local"
    create_directory "${workspace_path}/.bitbot/internal"
    create_directory "${workspace_path}/.bitbot/internal/local"

    print_success "Created .bitbot/"
    print_success "Created .bitbot/local/"
    print_success "Created .bitbot/internal/"
    print_success "Created .bitbot/internal/local/"

    # Create config.json
    local workspace_name
    workspace_name=$(get_basename "$workspace_path")
    local timestamp
    timestamp=$(current_timestamp)

    create_config_json "${workspace_path}/.bitbot/config.json" \
        "default_mode" "work" \
        "workspace_name" "$workspace_name" \
        "skip_push_recommendation" "false" \
        "skip_safety_checks" "false" \
        "created_at" "$timestamp"

    print_success "Created .bitbot/config.json"

    # Create config mode devcontainer.json
    create_config_mode_devcontainer "$workspace_path"

    # Update .gitignore
    update_gitignore "$workspace_path"

    echo ""
    echo "Workspace configuration:"
    echo "  Name: $workspace_name"
    echo "  Default mode: work"
    echo ""
}

# ============================================================================
# Config Mode DevContainer Setup
# ============================================================================

create_config_mode_devcontainer() {
    # Create workspace-specific config mode devcontainer.json
    local workspace_path="$1"

    local bitbot_install
    bitbot_install=$(get_bitbot_install_dir)
    local config_devcontainer="${workspace_path}/.bitbot/internal/devcontainer.json"

    # Create minimal config devcontainer.json
    # References global Dockerfile, mounts this workspace
    cat > "$config_devcontainer" <<EOF
{
  "name": "$(get_basename "$workspace_path")-config",
  "build": {
    "dockerfile": "\${env:BITBOT_HOME}/config-devcontainer/Dockerfile"
  },
  "workspaceMount": "source=\${localWorkspaceFolder},target=/workspace,type=bind",
  "workspaceFolder": "/workspace",
  "remoteEnv": {
    "HISTFILE": "/workspace/.bitbot/internal/local/.bash_history"
  },
  "postCreateCommand": "mkdir -p /workspace/.bitbot/internal/local",
  "remoteUser": "vscode",
  "updateRemoteUserUID": true,
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {}
  }
}
EOF

    print_success "Created config mode devcontainer"
}

# ============================================================================
# .devcontainer Setup
# ============================================================================

setup_devcontainer() {
    # Create or use existing .devcontainer
    local workspace_path="$1"

    local devcontainer_path="${workspace_path}/.devcontainer"

    if [[ ! -d "$devcontainer_path" ]]; then
        # Copy base template from global BitBot installation
        print_step "Creating base .devcontainer from template..."

        local bitbot_install
        bitbot_install=$(get_bitbot_install_dir)
        local template_path="${bitbot_install}/templates/workspace"

        if [[ -d "$template_path" ]]; then
            cp -r "$template_path" "$devcontainer_path"
            print_success "Created .devcontainer/ from template"
        else
            # Fallback: Create minimal devcontainer.json
            create_minimal_devcontainer "$workspace_path"
        fi
    else
        print_info "Found existing .devcontainer/"
        echo "    AI agent can help you review and adjust it in config mode"
    fi

    echo ""
    print_success "Workspace initialized"
}

create_minimal_devcontainer() {
    # Create minimal .devcontainer if template not found
    local workspace_path="$1"

    create_directory "${workspace_path}/.devcontainer"

    # Create minimal devcontainer.json
    cat > "${workspace_path}/.devcontainer/devcontainer.json" <<EOF
{
  "name": "$(get_basename "$workspace_path")-work",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "mounts": [
    "source=\${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",
    "source=\${localWorkspaceFolder}/.devcontainer,target=/workspace/.devcontainer,type=bind,readonly"
  ],
  "remoteEnv": {
    "HISTFILE": "/workspace/.bitbot/local/.bash_history"
  },
  "postCreateCommand": "mkdir -p /workspace/.bitbot/local",
  "remoteUser": "vscode",
  "updateRemoteUserUID": true,
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {}
  }
}
EOF

    print_success "Created minimal .devcontainer/"
}

# ============================================================================
# .gitignore Update
# ============================================================================

update_gitignore() {
    # Add .bitbot/local/ and .bitbot/internal/local/ to .gitignore
    local workspace_path="$1"

    # Only update if git repo exists
    if [[ ! -d "${workspace_path}/.git" ]]; then
        return 0
    fi

    local gitignore_path="${workspace_path}/.gitignore"
    local needs_update=false

    # Check if entries already exist
    if [[ -f "$gitignore_path" ]]; then
        if ! grep -q ".bitbot/local/" "$gitignore_path" 2>/dev/null; then
            needs_update=true
        fi
        if ! grep -q ".bitbot/internal/local/" "$gitignore_path" 2>/dev/null; then
            needs_update=true
        fi
    else
        needs_update=true
    fi

    if [[ "$needs_update" == "true" ]]; then
        # Append or create .gitignore
        {
            echo ""
            echo "# BitBot local runtime data"
            echo ".bitbot/local/"
            echo ".bitbot/internal/local/"
        } >> "$gitignore_path"

        print_success "Added .bitbot/local/ and .bitbot/internal/local/ to .gitignore"
    fi
}

# Export function for use by main script
export -f bitbot_init
