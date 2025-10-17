#!/bin/bash
# BitBot Core - Shared container management logic
# Used by both bitbot.sh and bitbot.bat for consistent behavior

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Determine BITBOT_ROOT if not already set
if [[ -z "$BITBOT_ROOT" ]]; then
    if [[ -n "$BITBOT_HOME" ]]; then
        BITBOT_ROOT="$BITBOT_HOME"
    elif [[ -n "$WSL_DISTRO_NAME" ]] || [[ $(uname -r) == *microsoft* ]]; then
        # WSL2 default path
        BITBOT_ROOT="/mnt/c/BitBot"
    elif [[ "$OS" == "Windows_NT" ]] || [[ -n "$WINDIR" ]]; then
        # Windows default path (when called from PowerShell)
        BITBOT_ROOT="/mnt/c/BitBot"
    else
        # Native Linux - use script directory's parent
        BITBOT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    fi
fi

# Set CURRENT_DIR if not already set
if [[ -z "$CURRENT_DIR" ]]; then
    CURRENT_DIR=$(pwd)
fi

# Global variables
BITBOT_ROOT="${BITBOT_ROOT}"
CURRENT_DIR="${CURRENT_DIR}"

generate_workspace_hash() {
    # Generate a short hash from the workspace path
    echo "$CURRENT_DIR" | sha256sum | cut -c1-8 2>/dev/null || echo "$CURRENT_DIR" | shasum -a 256 | cut -c1-8
}

detect_platform() {
    # Detect the platform and set appropriate Docker requirements
    if [[ -n "$WSL_DISTRO_NAME" ]] || [[ $(uname -r) == *microsoft* ]]; then
        PLATFORM="wsl"
        DOCKER_TYPE="docker-desktop"
    elif [[ "$OS" == "Windows_NT" ]] || [[ -n "$WINDIR" ]]; then
        PLATFORM="windows"
        DOCKER_TYPE="docker-desktop"
    elif [[ "$(uname)" == "Darwin" ]]; then
        PLATFORM="macos"
        DOCKER_TYPE="docker-desktop"
    elif [[ "$(uname)" == "Linux" ]]; then
        PLATFORM="linux"
        DOCKER_TYPE="docker-engine"
    else
        PLATFORM="unknown"
        DOCKER_TYPE="unknown"
    fi
}

check_docker_desktop() {
    # Check if Docker Desktop is running (Windows/WSL/macOS)
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}[ERROR]${NC} Docker Desktop is not accessible."
        if [[ "$PLATFORM" == "wsl" ]]; then
            echo -e "${YELLOW}[INFO]${NC} Please ensure Docker Desktop is running and WSL2 integration is enabled."
            echo
            echo "Steps to fix:"
            echo "1. Start Docker Desktop on Windows"
            echo "2. Go to Settings > Resources > WSL Integration"
            echo "3. Enable integration with your WSL distribution"
            echo "4. Apply & Restart"
        elif [[ "$PLATFORM" == "macos" ]]; then
            echo -e "${YELLOW}[INFO]${NC} Please install and start Docker Desktop for Mac."
            echo
            echo "Steps to fix:"
            echo "1. Download Docker Desktop: https://docs.docker.com/desktop/mac/install/"
            echo "2. Install and start Docker Desktop"
            echo "3. Wait for Docker Desktop to complete initialization"
        else
            echo -e "${YELLOW}[INFO]${NC} Please start Docker Desktop."
        fi
        return 1
    fi
    
    # Get Docker info for validation
    local docker_context=$(docker context show 2>/dev/null || echo "")
    local docker_info=$(docker info 2>/dev/null || echo "")
    local docker_version=$(docker version --format '{{.Server.Os}}-{{.Server.Arch}}' 2>/dev/null || echo "")
    
    # Platform-specific Docker Desktop validation
    if [[ "$PLATFORM" == "wsl" ]]; then
        # For WSL, enforce Docker Desktop usage more strictly
        if [[ "$docker_info" == *"Docker Desktop"* ]] || [[ "$docker_context" == "desktop-linux" ]] || [[ "$docker_info" == *"docker-desktop"* ]] || [[ "$docker_version" == *"linux"* ]]; then
            echo -e "${GREEN}[SUCCESS]${NC} Docker Desktop detected and running"
            return 0
        else
            echo -e "${RED}[ERROR]${NC} Docker is running but not Docker Desktop"
            echo -e "${YELLOW}[REQUIRED]${NC} WSL must use Docker Desktop for BitBot compatibility"
            echo
            echo "Please:"
            echo "1. Ensure Docker Desktop is installed on Windows"
            echo "2. Enable WSL2 integration in Docker Desktop settings"
            echo "3. Restart your WSL terminal"
            return 1
        fi
    elif [[ "$PLATFORM" == "macos" ]]; then
        # For macOS, enforce Docker Desktop usage
        if [[ "$docker_info" == *"Docker Desktop"* ]] || [[ "$docker_context" == "desktop-linux" ]] || [[ "$docker_info" == *"docker-desktop"* ]] || [[ "$docker_info" == *"com.docker.docker"* ]]; then
            echo -e "${GREEN}[SUCCESS]${NC} Docker Desktop detected and running"
            return 0
        else
            echo -e "${RED}[ERROR]${NC} Docker is running but not Docker Desktop"
            echo -e "${YELLOW}[REQUIRED]${NC} macOS must use Docker Desktop for BitBot compatibility"
            echo
            echo "Please:"
            echo "1. Install Docker Desktop for Mac: https://docs.docker.com/desktop/mac/install/"
            echo "2. Uninstall any native Docker installations (brew, etc.)"
            echo "3. Start Docker Desktop and wait for initialization"
            return 1
        fi
    else
        # For Windows, just check if Docker Desktop is accessible
        if [[ "$docker_info" == *"Docker Desktop"* ]]; then
            echo -e "${GREEN}[SUCCESS]${NC} Docker Desktop detected and running"
        else
            echo -e "${GREEN}[SUCCESS]${NC} Docker is running"
        fi
        return 0
    fi
}

check_docker_engine() {
    # Check if Docker engine is running (Linux)
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}[ERROR]${NC} Docker engine is not accessible."
        
        echo -e "${YELLOW}[INFO]${NC} Please install and start Docker engine:"
        echo "1. Install Docker: https://docs.docker.com/engine/install/"
        echo "2. Start Docker service: sudo systemctl start docker"
        echo "3. Add user to docker group: sudo usermod -aG docker \$USER"
        echo "4. Restart your session or run: newgrp docker"
        return 1
    fi
    
    echo -e "${GREEN}[SUCCESS]${NC} Docker engine detected and running"
    return 0
}

check_docker() {
    detect_platform
    
    echo -e "${BLUE}[INFO]${NC} Platform: $PLATFORM, Docker type: $DOCKER_TYPE"
    
    case "$DOCKER_TYPE" in
        "docker-desktop")
            check_docker_desktop
            ;;
        "docker-engine")
            check_docker_engine
            ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown platform. Please ensure Docker is installed and running."
            return 1
            ;;
    esac
}

ensure_docker_context() {
    # For WSL and macOS, ensure we're using the correct Docker context
    if [[ "$PLATFORM" == "wsl" ]] || [[ "$PLATFORM" == "macos" ]]; then
        local current_context=$(docker context show 2>/dev/null || echo "default")
        if [[ "$current_context" != "default" ]] && [[ "$current_context" != "desktop-linux" ]]; then
            echo -e "${YELLOW}[INFO]${NC} Switching to default Docker context for Docker Desktop compatibility"
            docker context use default >/dev/null 2>&1 || true
        fi
    fi
}

start_mcp_services() {
    echo -e "${BLUE}[1/4]${NC} Checking MCP Services status..."
    
    if ! check_docker; then
        return 1
    fi
    
    ensure_docker_context
    
    # Check if MCP services are running
    if ! docker-compose -f "$BITBOT_ROOT/global/mcp/docker-compose.yml" ps --format "table {{.Name}}\t{{.Status}}" | grep -q "Up"; then
        echo -e "${YELLOW}[INFO]${NC} Starting MCP services..."
        cd "$BITBOT_ROOT/global/mcp"
        docker-compose up -d
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}[ERROR]${NC} Failed to start MCP services"
            return 1
        fi
        echo -e "${GREEN}[SUCCESS]${NC} MCP services started"
    else
        echo -e "${GREEN}[SUCCESS]${NC} MCP services already running"
    fi
    return 0
}

is_first_run() {
    # Check if this is the first time BitBot is run in this workspace
    if [[ ! -d "$CURRENT_DIR/.bitbot" ]]; then
        return 0  # First run
    fi
    return 1  # Not first run
}

has_devcontainer() {
    # Check if workspace has devcontainer configuration (indicates VS Code mode preference)
    if [[ -d "$CURRENT_DIR/.devcontainer" ]]; then
        return 0  # Has devcontainer
    fi
    return 1  # No devcontainer
}

is_container_running() {
    local workspace_hash=$(generate_workspace_hash)
    local container_name="bitbot-dev-$workspace_hash"
    
    if docker ps --format "table {{.Names}}" | grep -q "^$container_name$"; then
        return 0  # Container is running
    fi
    return 1  # Container not running
}

show_first_run_menu() {
    echo
    echo "=========================================="
    echo "  BitBot - First Run Setup"
    echo "  Workspace: $(basename "$CURRENT_DIR")"
    echo "=========================================="
    echo
    echo "How would you like to configure BitBot for this workspace?"
    echo
    echo "  [1] Generate VS Code DevContainer setup"
    echo "      - Creates .devcontainer and .bitbot folders"
    echo "      - Launch VS Code to 'Reopen in Container'"
    echo "      - Full VS Code development experience"
    echo
    echo "  [2] Direct Docker launch"
    echo "      - Creates .bitbot folder only"
    echo "      - Starts container immediately"
    echo "      - Command-line tmux development"
    echo
    echo "  [3] Exit"
    echo
    read -p "Choose an option [1-3]: " choice
    
    case "$choice" in
        "1")
            # Create devcontainer config and launch VS Code setup
            "$BITBOT_ROOT/global/setup-devcontainer.sh" "vscode"
            "$BITBOT_ROOT/global/launch-vscode.sh"
            return 1  # Exit main flow
            ;;
        "2") 
            # Create .bitbot folder only and continue with direct launch
            local workspace_hash=$(generate_workspace_hash)
            mkdir -p "$CURRENT_DIR/.bitbot"
            echo "$workspace_hash" > "$CURRENT_DIR/.bitbot/workspace-hash"
            echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$CURRENT_DIR/.bitbot/created"
            
            # Create workspace Dockerfile that references the base image
            cat > "$CURRENT_DIR/.bitbot/Dockerfile" << EOF
# BitBot Workspace Container
# Generated for workspace: $(basename "$CURRENT_DIR")
# Workspace hash: $workspace_hash

# Use the pre-built base image from devcontainer-base/Dockerfile.base
FROM bitbot-base:latest

# Add workspace-specific environment
ENV WORKSPACE_HASH=$workspace_hash
ENV CONTAINER_NAME=bitbot-dev-$workspace_hash

# Workspace metadata
LABEL workspace.hash="$workspace_hash"
LABEL workspace.name="$(basename "$CURRENT_DIR")"
LABEL workspace.created="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Default command
CMD ["tmux", "new-session", "-d", "-s", "main", "bitbot", "&&", "tmux", "attach-session", "-t", "main"]
EOF
            
            echo -e "${GREEN}[SUCCESS]${NC} BitBot workspace setup complete (.bitbot folder created)"
            return 0  # Continue with direct launch
            ;;
        "3")
            echo "Exiting BitBot setup."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            show_first_run_menu
            ;;
    esac
}

setup_workspace() {
    # Check if this is first run
    if is_first_run; then
        # First run - show setup menu
        show_first_run_menu
        return $?
    else
        # Not first run - check existing setup
        echo
        echo -e "${BLUE}[2/4]${NC} Existing BitBot workspace detected..."
        echo "Current directory: $CURRENT_DIR"
        
        # Check if devcontainer exists (indicates VS Code mode preference)
        if has_devcontainer; then
            echo -e "${BLUE}[INFO]${NC} DevContainer configuration found - launching VS Code mode"
            "$BITBOT_ROOT/global/launch-vscode.sh"
            return 1  # Exit main flow for VS Code
        else
            # Check if container is already running
            if is_container_running; then
                echo -e "${GREEN}[INFO]${NC} BitBot container already running - attaching to existing session"
                return 0  # Continue with attach to running container
            else
                echo -e "${BLUE}[INFO]${NC} Starting BitBot container"
                return 0  # Continue with direct launch
            fi
        fi
    fi
}


run_bitbot_standalone() {
    echo
    echo "========================================"
    echo "  BitBot - AI Development Environment"
    echo "========================================"
    echo
    
    # Run all steps
    if ! start_mcp_services; then
        return 1
    fi
    
    # Setup workspace (handles first-run mode selection)
    if ! setup_workspace; then
        # User chose VS Code mode, exit gracefully
        return 0
    fi
    
    # Launch Docker container and tmux sessions
    echo
    echo -e "${BLUE}[3/4]${NC} Launching Docker container..."
    if ! "$BITBOT_ROOT/global/launch-docker.sh"; then
        echo -e "${RED}[ERROR]${NC} Failed to launch Docker container"
        return 1
    fi
    
    echo
    echo -e "${GREEN}BitBot session ready!${NC} MCP services are running in the background."
    echo "To stop everything, run: docker-compose -f $BITBOT_ROOT/global/mcp/docker-compose.yml down"
}


# Main execution - always run standalone mode
run_bitbot_standalone