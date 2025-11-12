#!/bin/bash
#
# BitBot VS Code Launcher
# Launches VS Code attached to work container
#
# Usage: bitbot vscode

set -e

# Get script directory (core/workspace/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source utilities
source "$BITBOT_ROOT/core/util/helpers.sh"
source "$BITBOT_ROOT/core/util/prerequisites.sh"

# Main function
bitbot_vscode() {
    print_header "Launching VS Code"

    # Validate prerequisites
    validate_prerequisites "vscode"

    # Get workspace path (should be CWD)
    WORKSPACE_PATH="$PWD"

    # Check if workspace is initialized
    if [[ ! -d "$WORKSPACE_PATH/.bitbot" ]]; then
        print_error "Workspace not initialized in: $WORKSPACE_PATH"
        echo ""
        echo "Run 'bitbot init' first to initialize this workspace."
        exit 4
    fi

    # Check if VS Code is installed
    if ! command -v code &> /dev/null; then
        print_error "VS Code not found"
        echo ""
        echo "Please install Visual Studio Code:"
        echo "  https://code.visualstudio.com/"
        exit 1
    fi

    # Check if Dev Containers extension is installed
    if ! code --list-extensions 2>/dev/null | grep -q "ms-vscode-remote.remote-containers"; then
        print_warning "Dev Containers extension not detected"
        echo ""
        echo "Installing Dev Containers extension..."
        code --install-extension ms-vscode-remote.remote-containers
        echo ""
        echo "Extension installed. Please restart VS Code if it's running."
        sleep 2
    fi

    # Launch VS Code in the workspace
    print_info "Opening workspace in VS Code..."
    echo ""
    echo "Workspace: $WORKSPACE_PATH"
    echo ""

    # Detect platform for path conversion
    local platform
    platform=$(detect_platform 2>/dev/null || echo "linux")

    # VS Code will automatically detect .devcontainer and prompt to reopen in container
    if command -v code &> /dev/null; then
        code "$WORKSPACE_PATH"
    elif command -v code.exe &> /dev/null; then
        # On WSL, convert path to Windows format for code.exe
        if [[ "$platform" == "wsl" ]]; then
            local windows_path
            windows_path=$(convert_wsl_to_windows_path "$WORKSPACE_PATH")
            code.exe "$windows_path"
        else
            code.exe "$WORKSPACE_PATH"
        fi
    else
        print_error "VS Code 'code' command not found"
        exit 1
    fi

    echo ""
    print_success "VS Code launched"
    echo ""
    echo "If prompted, click 'Reopen in Container' to start the devcontainer."
    echo ""
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bitbot_vscode "$@"
fi
