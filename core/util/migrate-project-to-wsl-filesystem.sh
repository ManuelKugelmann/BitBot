#!/usr/bin/env bash
#
# BitBot Project Migration Helper
#
# Purpose: Move project from Windows filesystem to WSL for better performance
# Creates a junction/symlink at original location for Windows tool compatibility
#
# Usage: ./migrate-project.sh [source_path] [target_path]
#        ./migrate-project.sh (interactive mode)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_HOME="$(cd "$SCRIPT_DIR/../.." && pwd)"
export BITBOT_HOME

# Source helpers
# shellcheck source=./helpers.sh
source "${BITBOT_HOME}/core/util/helpers.sh"

# ============================================================================
# Configuration
# ============================================================================

# Default target location
DEFAULT_WSL_PROJECTS="$HOME/projects"

# ============================================================================
# Helper Functions
# ============================================================================

show_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   BitBot Project Migration Helper      ║${NC}"
    echo -e "${CYAN}║   Windows → WSL for Better Performance ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╗${NC}"
    echo ""
}

get_project_size() {
    local path="$1"
    du -sh "$path" 2>/dev/null | awk '{print $1}'
}

create_windows_junction() {
    # Create a Windows junction/symlink at the original location
    # This allows Windows tools to still access the project
    local wsl_path="$1"
    local win_path="$2"

    print_step "Creating Windows junction for tool compatibility..."

    # Convert WSL path to Windows path
    local win_target
    win_target=$(wslpath -w "$wsl_path" 2>/dev/null)

    if [[ -z "$win_target" ]]; then
        print_warning "Could not convert WSL path to Windows path"
        return 1
    fi

    # Remove trailing slashes
    win_target="${win_target%\\}"
    win_path="${win_path%\\}"

    # Create junction using Windows mklink via cmd.exe
    if cmd.exe /c "mklink /J \"$win_path\" \"$win_target\"" >/dev/null 2>&1; then
        print_success "Junction created: $win_path → $wsl_path"
        echo ""
        echo "Windows tools can now access the project at:"
        echo "  $win_path"
        echo ""
        return 0
    else
        print_warning "Failed to create Windows junction"
        echo ""
        echo "You can manually create it later with:"
        echo "  cmd.exe /c \"mklink /J \\\"$win_path\\\" \\\"$win_target\\\"\""
        echo ""
        return 1
    fi
}

# ============================================================================
# Main Migration Logic
# ============================================================================

migrate_project() {
    local source_path="$1"
    local target_base="$2"

    # Validate source exists
    if [[ ! -d "$source_path" ]]; then
        print_error "Source directory does not exist: $source_path"
        return 1
    fi

    # Get project name
    local project_name
    project_name=$(basename "$source_path")

    local target_path="${target_base}/${project_name}"

    # Check if source is on Windows mount
    if [[ ! "$source_path" =~ ^/mnt/[a-z]/ ]]; then
        print_warning "Source is not on Windows filesystem (/mnt/c, etc.)"
        echo "Source: $source_path"
        echo ""

        local should_continue
        should_continue=$(prompt_yes_no "Continue anyway?" "no")
        if [[ "$should_continue" != "yes" ]]; then
            echo "Migration cancelled"
            return 1
        fi
    fi

    # Check if target already exists
    if [[ -d "$target_path" ]]; then
        print_error "Target directory already exists: $target_path"
        return 1
    fi

    # Show migration plan
    echo ""
    echo -e "${CYAN}═══ Migration Plan ═══${NC}"
    echo ""
    echo "Source:      $source_path"
    echo "Target:      $target_path"
    echo "Size:        $(get_project_size "$source_path")"
    echo ""
    echo "Expected performance improvement:"
    echo "  - File operations:  3-4x faster"
    echo "  - Git operations:   2-3x faster"
    echo "  - Container builds: 3-4x faster"
    echo ""

    # Confirm migration
    local should_migrate
    should_migrate=$(prompt_yes_no "Proceed with migration?" "yes")

    if [[ "$should_migrate" != "yes" ]]; then
        echo ""
        echo "Migration cancelled"
        return 1
    fi

    # Create target base directory
    print_step "Creating target directory..."
    mkdir -p "$target_base"

    # Perform the move
    print_step "Moving project to WSL filesystem..."
    echo "This may take a few minutes for large projects..."
    echo ""

    if mv "$source_path" "$target_path"; then
        print_success "Project moved successfully!"
        echo ""
    else
        print_error "Failed to move project"
        return 1
    fi

    # Ask about creating junction
    echo ""
    echo -e "${BLUE}Optional: Windows Junction${NC}"
    echo ""
    echo "Note: Windows tools can access WSL files directly via:"
    # shellcheck disable=SC2028  # Backslashes intentional (Windows UNC path)
    echo "  \\\\wsl\$\\Ubuntu\\home\\...  (in File Explorer, VS Code, etc.)"
    echo ""
    echo "However, you can create a junction at the original Windows"
    echo "location if you have scripts/shortcuts pointing to the old path."
    echo ""

    local should_junction
    should_junction=$(prompt_yes_no "Create junction at old location?" "no")

    if [[ "$should_junction" == "yes" ]]; then
        # Convert source path to Windows format
        local win_source
        win_source=$(wslpath -w "$source_path" 2>/dev/null)

        if [[ -n "$win_source" ]]; then
            create_windows_junction "$target_path" "$win_source"
        else
            print_warning "Could not convert source path to Windows format"
        fi
    fi

    # Get Windows UNC path for reference
    local win_unc_path
    win_unc_path=$(wslpath -w "$target_path" 2>/dev/null || echo "")

    # Show completion message
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Migration Complete!                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "Your project is now at:"
    echo -e "  WSL:     ${GREEN}$target_path${NC}"
    if [[ -n "$win_unc_path" ]]; then
        echo -e "  Windows: ${GREEN}$win_unc_path${NC}"
    fi
    echo ""
    echo "Accessing from Windows tools:"
    echo "  - File Explorer: Open $win_unc_path"
    echo "  - VS Code: Open folder → paste WSL path or Windows UNC path"
    echo "  - Terminal: cd to WSL path directly"
    echo ""
    echo "Next steps:"
    echo "  1. Update IDE workspace settings (use new path)"
    echo "  2. Update any scripts referencing the old path"
    if [[ "$should_junction" == "yes" ]]; then
        echo "  3. Old Windows path still works via junction"
    fi
    echo ""

    return 0
}

# ============================================================================
# Interactive Mode
# ============================================================================

interactive_mode() {
    show_banner

    # Get current directory
    local current_dir
    current_dir=$(pwd -P)

    # Check if we're in a Windows mount
    if [[ ! "$current_dir" =~ ^/mnt/[a-z]/ ]]; then
        print_warning "Current directory is not on Windows filesystem"
        echo ""
        echo "Current: $current_dir"
        echo ""
        echo "This tool is designed to migrate projects from Windows"
        echo "filesystem (/mnt/c, etc.) to WSL filesystem for better"
        echo "performance with DevContainers."
        echo ""

        local should_continue
        should_continue=$(prompt_yes_no "Continue anyway?" "no")
        if [[ "$should_continue" != "yes" ]]; then
            echo "Exiting"
            return 0
        fi
    fi

    # Offer to migrate current directory
    echo ""
    echo "Current directory:"
    echo "  $current_dir"
    echo ""

    local migrate_current
    migrate_current=$(prompt_yes_no "Migrate current directory?" "yes")

    local source_path
    if [[ "$migrate_current" == "yes" ]]; then
        source_path="$current_dir"
    else
        # Ask for custom path
        echo ""
        echo -e "${BLUE}Enter source path to migrate:${NC}"
        read -r -p "> " source_path

        if [[ -z "$source_path" ]]; then
            print_error "No path provided"
            return 1
        fi

        # Expand path
        source_path=$(realpath "$source_path" 2>/dev/null || echo "$source_path")
    fi

    # Ask for target base directory
    echo ""
    echo -e "${BLUE}Target location:${NC}"
    echo ""
    echo "Default: $DEFAULT_WSL_PROJECTS"
    echo ""

    local use_default
    use_default=$(prompt_yes_no "Use default location?" "yes")

    local target_base
    if [[ "$use_default" == "yes" ]]; then
        target_base="$DEFAULT_WSL_PROJECTS"
    else
        echo ""
        echo "Enter target base directory:"
        read -r -p "> " target_base

        if [[ -z "$target_base" ]]; then
            print_error "No path provided"
            return 1
        fi
    fi

    # Perform migration
    migrate_project "$source_path" "$target_base"
}

# ============================================================================
# Main Entry Point
# ============================================================================

show_usage() {
    echo "Usage:"
    echo "  $0                     # Interactive mode"
    echo "  $0 <source> <target>   # Command line mode"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Interactive"
    echo "  $0 /mnt/c/Projects/MyApp ~/projects   # Move MyApp to ~/projects"
    echo ""
}

main() {
    # Validate arguments first (before platform check)
    # This allows usage info to be shown on any platform
    if [[ $# -ne 0 ]] && [[ $# -ne 2 ]]; then
        print_error "Invalid arguments"
        echo ""
        show_usage
        return 1
    fi

    # Check if running on WSL
    if ! grep -qi microsoft /proc/version 2>/dev/null; then
        print_error "This tool only runs on WSL"
        echo ""
        echo "This migration tool is designed for WSL environments where"
        echo "Windows filesystem mounts (/mnt/c) have performance issues."
        echo ""
        show_usage
        return 1
    fi

    # Parse arguments
    if [[ $# -eq 0 ]]; then
        # Interactive mode
        interactive_mode
    else
        # Command line mode (already validated as 2 args)
        migrate_project "$1" "$2"
    fi
}

# Run main function
main "$@"
