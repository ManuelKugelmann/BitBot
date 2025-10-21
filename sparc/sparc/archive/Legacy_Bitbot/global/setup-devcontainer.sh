#!/bin/bash
# BitBot DevContainer Setup Script
# Creates .devcontainer configuration with workspace-specific settings

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

create_workspace_dockerfile() {
    local workspace_hash="$1"
    
    echo -e "${BLUE}[INFO]${NC} Creating workspace-specific Dockerfile..."
    
    # Create .bitbot folder 
    mkdir -p "$CURRENT_DIR/.bitbot"
    
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

    echo -e "${GREEN}[SUCCESS]${NC} Workspace Dockerfile created at .bitbot/Dockerfile"
    return 0
}

create_devcontainer_config() {
    local workspace_hash="$1"
    local launch_mode="${2:-}"
    local container_name="bitbot-dev-$workspace_hash"
    
    echo -e "${BLUE}[INFO]${NC} Creating .devcontainer configuration..."
    echo "Workspace: $(basename "$CURRENT_DIR")"
    echo "Container: $container_name"
    echo "Hash: $workspace_hash"
    if [[ -n "$launch_mode" ]]; then
        echo "Launch mode: $launch_mode"
    fi
    
    # Create workspace Dockerfile first
    create_workspace_dockerfile "$workspace_hash"
    
    # Create .devcontainer directory
    mkdir -p "$CURRENT_DIR/.devcontainer"
    
    # Copy template from devcontainer-base and customize
    cp "$BITBOT_ROOT/devcontainer-base/devcontainer.json" "$CURRENT_DIR/.devcontainer/devcontainer.json"
    
    # Replace template variables with actual values
    sed -i "s|\${WORKSPACE_HASH}|$workspace_hash|g" "$CURRENT_DIR/.devcontainer/devcontainer.json"
    sed -i "s|\"dockerComposeFile\": \"./docker-compose.yml\"|\"dockerComposeFile\": \"$BITBOT_ROOT/devcontainer-base/docker-compose.yml\"|g" "$CURRENT_DIR/.devcontainer/devcontainer.json"
    
    # Update devcontainer to use workspace Dockerfile instead of base
    sed -i "s|\"service\": \"dotnet-dev\"|\"build\": {\"dockerfile\": \"../.bitbot/Dockerfile\", \"context\": \"$BITBOT_ROOT\"}|g" "$CURRENT_DIR/.devcontainer/devcontainer.json"
    
    # Store workspace metadata
    echo "$workspace_hash" > "$CURRENT_DIR/.bitbot/workspace-hash"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$CURRENT_DIR/.bitbot/created"
    
    echo -e "${GREEN}[SUCCESS]${NC} DevContainer configuration created!"
    echo -e "${BLUE}[INFO]${NC} BitBot workspace tracking enabled (.bitbot folder created)"
    return 0
}

# Removed launch mode persistence - only check container running status

# Main execution
WORKSPACE_HASH=$(generate_workspace_hash)
LAUNCH_MODE="${1:-}"  # Optional parameter for launch mode

create_devcontainer_config "$WORKSPACE_HASH" "$LAUNCH_MODE"

# Output container info for calling script
echo "CONTAINER_NAME=bitbot-dev-$WORKSPACE_HASH"
echo "WORKSPACE_HASH=$WORKSPACE_HASH"
if [[ -n "$LAUNCH_MODE" ]]; then
    echo "LAUNCH_MODE=$LAUNCH_MODE"
fi