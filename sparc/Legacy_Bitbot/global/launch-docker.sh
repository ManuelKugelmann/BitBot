#!/bin/bash
# BitBot Docker Launch and Tmux Attachment Script
# Handles container startup and tmux session management

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

ensure_docker_context() {
    # Detect platform for Docker context management
    local platform=""
    if [[ -n "$WSL_DISTRO_NAME" ]] || [[ $(uname -r) == *microsoft* ]]; then
        platform="wsl"
    elif [[ "$(uname)" == "Darwin" ]]; then
        platform="macos"
    fi
    
    # For WSL and macOS, ensure we're using the correct Docker context
    if [[ "$platform" == "wsl" ]] || [[ "$platform" == "macos" ]]; then
        local current_context=$(docker context show 2>/dev/null || echo "default")
        if [[ "$current_context" != "default" ]] && [[ "$current_context" != "desktop-linux" ]]; then
            echo -e "${YELLOW}[INFO]${NC} Switching to default Docker context for Docker Desktop compatibility"
            docker context use default >/dev/null 2>&1 || true
        fi
    fi
}

ensure_base_image() {
    local base_image="bitbot-base:latest"
    
    # Check if base image exists
    if ! docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^$base_image$"; then
        echo -e "${BLUE}[INFO]${NC} Building base image: $base_image"
        
        # Build the base image from devcontainer-base/Dockerfile.base
        if docker build -t "$base_image" -f "$BITBOT_ROOT/devcontainer-base/Dockerfile.base" "$BITBOT_ROOT"; then
            echo -e "${GREEN}[SUCCESS]${NC} Base image built"
            return 0
        else
            echo -e "${RED}[ERROR]${NC} Failed to build base image"
            return 1
        fi
    else
        echo -e "${GREEN}[INFO]${NC} Base image already exists"
        return 0
    fi
}

build_workspace_image() {
    local workspace_hash="$1"
    local dockerfile_path="$CURRENT_DIR/.bitbot/Dockerfile"
    local image_name="bitbot-workspace-$workspace_hash"
    
    if [[ ! -f "$dockerfile_path" ]]; then
        echo -e "${RED}[ERROR]${NC} Workspace Dockerfile not found at $dockerfile_path"
        echo "Run BitBot setup first to create workspace configuration"
        return 1
    fi
    
    # Ensure base image exists first
    if ! ensure_base_image; then
        return 1
    fi
    
    echo -e "${BLUE}[INFO]${NC} Building workspace image: $image_name"
    
    # Build the workspace-specific image
    if docker build -t "$image_name" -f "$dockerfile_path" "$BITBOT_ROOT"; then
        echo -e "${GREEN}[SUCCESS]${NC} Workspace image built"
        return 0
    else
        echo -e "${RED}[ERROR]${NC} Failed to build workspace image"
        return 1
    fi
}

start_container() {
    local workspace_hash="$1"
    local container_name="bitbot-dev-$workspace_hash"
    local image_name="bitbot-workspace-$workspace_hash"
    
    echo -e "${BLUE}[INFO]${NC} Starting container: $container_name"
    
    # Check if container already exists for this workspace
    if docker ps -a --format "table {{.Names}}" | grep -q "^$container_name$"; then
        if docker ps --format "table {{.Names}}" | grep -q "^$container_name$"; then
            echo -e "${GREEN}[INFO]${NC} Container already running"
            return 0
        else
            echo -e "${YELLOW}[INFO]${NC} Starting existing container"
            docker start "$container_name"
            return 0
        fi
    fi
    
    # Build workspace image if it doesn't exist
    if ! docker images --format "table {{.Repository}}" | grep -q "^$image_name$"; then
        if ! build_workspace_image "$workspace_hash"; then
            return 1
        fi
    fi
    
    # Start new container using workspace image directly
    echo -e "${BLUE}[INFO]${NC} Workspace mount: $CURRENT_DIR -> /workspace"
    
    # Create network if it doesn't exist
    docker network create devcontainer-base_default >/dev/null 2>&1 || true
    
    # Use MSYS_NO_PATHCONV to prevent Git Bash path conversion
    export MSYS_NO_PATHCONV=1
    docker run -d \
        --name "$container_name" \
        --hostname "bitbot-dev" \
        -v "$CURRENT_DIR:/workspace" \
        -v "$CURRENT_DIR/.bitbot:/workspace/.bitbot" \
        -e "WORKSPACE_HASH=$workspace_hash" \
        -e "TZ=${TZ:-UTC}" \
        --network="devcontainer-base_default" \
        "$image_name"
    unset MSYS_NO_PATHCONV
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Failed to start container"
        return 1
    fi
    
    echo -e "${GREEN}[SUCCESS]${NC} Container started"
    return 0
}

launch_tmux_session() {
    local container_name="$1"
    
    echo -e "${BLUE}[INFO]${NC} Launching BitBot session in container: $container_name"
    
    # Wait for container to be ready
    sleep 3
    
    # Execute internal bitbot script to create and attach to first session
    docker exec -it "$container_name" bash -c "bitbot"
}

attach_to_existing_session() {
    local container_name="$1"
    
    echo -e "${BLUE}[INFO]${NC} Attaching to existing BitBot session in: $container_name"
    
    # Execute internal bitbot script to attach to first session
    docker exec -it "$container_name" bash -c "bitbot attach"
}

# Main execution
WORKSPACE_HASH=$(generate_workspace_hash)
CONTAINER_NAME="bitbot-dev-$WORKSPACE_HASH"

echo "========================================"
echo "  BitBot Docker Launch"
echo "  Container: $CONTAINER_NAME"
echo "========================================"

# Ensure proper Docker context
ensure_docker_context

# Check if container is already running
if docker ps --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    # Container exists and is running - attach to existing session
    attach_to_existing_session "$CONTAINER_NAME"
else
    # Start container and launch new tmux session
    if start_container "$WORKSPACE_HASH"; then
        launch_tmux_session "$CONTAINER_NAME"
    else
        echo -e "${RED}[ERROR]${NC} Failed to start container"
        exit 1
    fi
fi