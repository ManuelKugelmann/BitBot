#!/bin/bash
# BitBot VS Code Launch Script
# Provides instructions and optional automatic VS Code launch for devcontainers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Required environment variables
if [[ -z "$BITBOT_ROOT" ]] || [[ -z "$CURRENT_DIR" ]]; then
    echo -e "${RED}[ERROR]${NC} Required environment variables not set"
    echo "BITBOT_ROOT and CURRENT_DIR must be exported by calling script"
    exit 1
fi

generate_workspace_hash() {
    # Generate a short hash from the workspace path
    echo "$CURRENT_DIR" | sha256sum | cut -c1-8 2>/dev/null || echo "$CURRENT_DIR" | shasum -a 256 | cut -c1-8
}

show_manual_instructions() {
    echo "Manual VS Code Setup:"
    echo "1. Open this workspace in VS Code"
    echo "2. Press Ctrl+Shift+P (Cmd+Shift+P on Mac)"
    echo "3. Type 'Dev Containers: Reopen in Container'"
    echo "4. VS Code will build and start your BitBot environment"
    echo "5. Once ready, open terminal and run: tmux-session.sh interactive"
}

try_automatic_launch() {
    if command -v code >/dev/null 2>&1; then
        echo -e "${BLUE}[INFO]${NC} Launching VS Code with DevContainer automatically..."
        
        # Use --remote-container to open directly in devcontainer
        if code --remote-container "$CURRENT_DIR" >/dev/null 2>&1; then
            echo -e "${GREEN}[SUCCESS]${NC} VS Code opened in DevContainer mode"
            echo "VS Code will automatically build and start the BitBot environment"
            return 0
        else
            echo -e "${YELLOW}[WARNING]${NC} --remote-container failed, trying regular launch..."
            code "$CURRENT_DIR"
            echo -e "${GREEN}[SUCCESS]${NC} VS Code opened with workspace"
            echo "Next step: Use the 'Dev Containers: Reopen in Container' command in VS Code"
            return 0
        fi
    else
        echo -e "${YELLOW}[WARNING]${NC} VS Code 'code' command not found"
        echo "Please install VS Code command line tools or open VS Code manually"
        return 1
    fi
}

show_vscode_menu() {
    local workspace_hash="$1"
    local container_name="bitbot-dev-$workspace_hash"
    
    echo
    echo "=========================================="
    echo "  BitBot VS Code Setup Complete"
    echo "=========================================="
    echo
    echo "Workspace: $(basename "$CURRENT_DIR")"
    echo "Container: $container_name"
    echo "Hash: $workspace_hash"
    echo
    
    # Check if VS Code CLI is available
    if command -v code >/dev/null 2>&1; then
        echo "VS Code will be launched automatically with DevContainer support."
        echo "This will open VS Code and immediately start building the BitBot environment."
        echo
        read -p "Launch VS Code now? [Y/n]: " launch_choice
        
        case "$launch_choice" in
            "n"|"N"|"no"|"No"|"NO")
                echo
                echo "Skipping automatic launch. Use manual instructions below:"
                show_manual_instructions
                ;;
            *)
                echo
                if ! try_automatic_launch; then
                    echo
                    echo "Falling back to manual instructions:"
                    show_manual_instructions
                fi
                ;;
        esac
    else
        echo -e "${YELLOW}[INFO]${NC} VS Code CLI not detected. Using manual setup:"
        echo
        show_manual_instructions
    fi
}

show_devcontainer_info() {
    local workspace_hash="$1"
    
    echo
    echo "DevContainer Configuration Details:"
    echo "=================================="
    echo "Config file: $CURRENT_DIR/.devcontainer/devcontainer.json"
    echo "Docker Compose: $BITBOT_ROOT/devcontainer-base/docker-compose.yml"
    echo "Service: dotnet-dev"
    echo "Container name: bitbot-dev-$workspace_hash"
    echo "Workspace folder: /workspace"
    echo "Post-create command: tmux-session.sh interactive"
}

# Main execution
WORKSPACE_HASH=$(generate_workspace_hash)

# Verify devcontainer config exists
if [[ ! -f "$CURRENT_DIR/.devcontainer/devcontainer.json" ]]; then
    echo -e "${RED}[ERROR]${NC} DevContainer configuration not found"
    echo "Run setup-devcontainer.sh first to create the configuration"
    exit 1
fi

# Show VS Code options
show_vscode_menu "$WORKSPACE_HASH"

# Show additional info
show_devcontainer_info "$WORKSPACE_HASH"

echo
echo -e "${GREEN}[INFO]${NC} Ready for VS Code DevContainer development!"
echo "The container will use workspace-specific naming for proper isolation."