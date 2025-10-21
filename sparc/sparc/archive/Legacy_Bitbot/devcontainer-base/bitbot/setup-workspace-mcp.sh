#!/bin/bash
# Setup script for workspace MCP services
# This script initializes workspace-local MCP services when the container starts

set -e

echo "Setting up workspace MCP services..."

# Check if we're in a dev container
if [ "$DEVCONTAINER" != "true" ]; then
    echo "Not running in a dev container, skipping workspace MCP setup."
    exit 0
fi

# Check if workspace has MCP services configuration
WORKSPACE_MCP_CONFIG="/workspace/.mcp-services"

if [ ! -d "$WORKSPACE_MCP_CONFIG" ]; then
    echo "No workspace MCP services configuration found at $WORKSPACE_MCP_CONFIG"
    echo "Creating default workspace MCP configuration..."
    
    mkdir -p "$WORKSPACE_MCP_CONFIG/services"
    
    cat > "$WORKSPACE_MCP_CONFIG/docker-compose.yml" << 'EOF'
# Workspace-specific MCP services
# This file extends the base workspace MCP services with project-specific services

version: '3.8'

networks:
  workspace-mcp-network:
    external: true
    name: devcontainer-base_workspace-mcp-network

services:
  # Add your workspace-specific MCP services here
  # Example:
  # my-workspace-service:
  #   build: ./services/my-service
  #   container_name: "my-workspace-service-${WORKSPACE_HASH:-default}"
  #   networks:
  #     - workspace-mcp-network
  #   environment:
  #     - WORKSPACE_MODE=true
  #     - REGISTRY_URL=http://workspace-mcp-registry:8080
EOF

    cat > "$WORKSPACE_MCP_CONFIG/README.md" << 'EOF'
# Workspace MCP Services

This directory contains workspace-local MCP (Model Context Protocol) services that run alongside your development container.

## Structure

- `docker-compose.yml` - Workspace-specific MCP services configuration
- `services/` - Directory for custom MCP service implementations

## Usage

Workspace MCP services are managed automatically by the dev container. You can also manage them manually:

```bash
# From inside the dev container
workspace-mcp start    # Start workspace MCP services
workspace-mcp stop     # Stop workspace MCP services  
workspace-mcp status   # Check status
workspace-mcp logs     # View logs

# Or use aliases
workspace-mcp-status   # Check service registry
workspace-mcp-ping     # Test connectivity
```

## Ports

Workspace MCP services use different ports to avoid conflicts with global services:

- Registry: http://localhost:9080 (vs global 8080)
- Gateway: http://localhost:9090 (vs global 8090)

## Adding Custom Services

1. Create your service in `services/my-service/`
2. Add the service configuration to `docker-compose.yml`
3. Restart workspace MCP services: `workspace-mcp restart`

Your services will automatically register with the workspace MCP registry.
EOF

    echo "Created workspace MCP configuration at $WORKSPACE_MCP_CONFIG"
fi

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
    echo "Docker CLI not available, cannot manage workspace MCP services."
    exit 1
fi

# Check if Docker daemon is accessible
if ! docker info >/dev/null 2>&1; then
    echo "Docker daemon not accessible, cannot manage workspace MCP services."
    exit 1
fi

echo "Workspace MCP setup complete."
echo "Use 'workspace-mcp start' to start workspace-local MCP services."