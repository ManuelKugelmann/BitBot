#!/usr/bin/env bash
#
# BitBot Workspace Detection
#
# Component: Workspace Discovery
# Purpose: Find or validate BitBot workspace based on current directory
#
# Usage: source this file from other scripts
#

# Source helpers (if not already sourced)
if [[ -z "${BITBOT_HELPERS_LOADED:-}" ]]; then
    # shellcheck source=./helpers.sh
    source "${BITBOT_HOME}/core/util/helpers.sh"
    BITBOT_HELPERS_LOADED=1
fi

# ============================================================================
# Workspace Detection
# ============================================================================

detect_workspace() {
    # MVP: Check CWD only (no parent search)
    # Returns workspace path if found, or empty string if not found

    local cwd
    cwd=$(get_current_directory)

    if is_workspace_initialized "$cwd"; then
        echo "$cwd"
        return 0
    fi

    # No workspace found in CWD
    return 1
}

is_workspace_initialized() {
    # Check if directory has .bitbot/ (is a BitBot workspace)
    local path="$1"

    [[ -d "${path}/.bitbot" ]]
}

# ============================================================================
# Workspace Validation
# ============================================================================

validate_workspace() {
    # Check if workspace is valid
    # MVP: Just check .bitbot exists (no metadata.json requirement)
    local workspace_path="$1"

    # Check .bitbot exists
    if ! directory_exists "${workspace_path}/.bitbot"; then
        print_error "Not a BitBot workspace: ${workspace_path}"
        print_info "Missing .bitbot/ directory"
        return 1
    fi

    # Optional: Check config.json exists (warn if missing)
    if ! file_exists "${workspace_path}/.bitbot/config.json"; then
        print_warning "Workspace missing config.json (may need re-initialization)"
    fi

    return 0
}

# ============================================================================
# Path Resolution Helpers
# ============================================================================

resolve_workspace_path() {
    # Resolve and normalize workspace path
    # Handles: ~, relative paths, symlinks
    local path="$1"

    # Expand ~ to home directory
    if [[ "$path" =~ ^\~ ]]; then
        path="${HOME}${path:1}"
    fi

    # Get absolute path
    path=$(get_absolute_path "$path")

    # Check if on temporary filesystem (warn)
    if is_temporary_filesystem "$path"; then
        print_warning "Workspace on temporary filesystem: $path"
        print_warning "Data may be lost on reboot"
        echo ""
    fi

    # Check writable
    if [[ ! -w "$path" ]]; then
        print_error "Workspace directory not writable: $path"
        return 1
    fi

    echo "$path"
    return 0
}

is_temporary_filesystem() {
    # Check if path is on a temporary filesystem
    local path="$1"

    case "$path" in
        /tmp/*|/dev/shm/*|/var/tmp/*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================================================
# Future: Parent Directory Search (MVP: Not Implemented)
# ============================================================================

# find_workspace_in_hierarchy() {
#     # Walk up directory tree looking for .bitbot/
#     # Future feature: Not in MVP
#     local current="$1"
#
#     while [[ "$current" != "/" ]]; do
#         if [[ -d "${current}/.bitbot" ]]; then
#             echo "$current"
#             return 0
#         fi
#         current=$(dirname "$current")
#     done
#
#     return 1
# }
