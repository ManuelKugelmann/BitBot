#!/bin/bash
# Workspace MCP Services Management Script
# Manages workspace-local MCP services that run alongside the dev container

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_MCP_DIR="$SCRIPT_DIR/mcp"
COMPOSE_FILE="$WORKSPACE_MCP_DIR/docker-compose.yml"

# Generate workspace hash for unique container names
if [ -n "$WORKSPACE_FOLDER" ]; then
    WORKSPACE_HASH=$(echo -n "$WORKSPACE_FOLDER" | sha256sum | cut -c1-8)
else
    WORKSPACE_HASH="default"
fi

export WORKSPACE_HASH
export TZ="${TZ:-UTC}"

usage() {
    echo "Usage: $0 {start|stop|restart|status|logs|clean}"
    echo ""
    echo "Commands:"
    echo "  start   - Start workspace MCP services"
    echo "  stop    - Stop workspace MCP services"
    echo "  restart - Restart workspace MCP services"
    echo "  status  - Show status of workspace MCP services"
    echo "  logs    - Show logs for workspace MCP services"
    echo "  clean   - Stop and remove workspace MCP services and volumes"
    echo ""
    echo "Environment variables:"
    echo "  WORKSPACE_FOLDER - Current workspace folder path"
    echo "  TZ              - Timezone (default: UTC)"
}

start_services() {
    echo "Starting workspace MCP services..."
    echo "Workspace hash: $WORKSPACE_HASH"
    
    cd "$WORKSPACE_MCP_DIR"
    docker-compose -f "$COMPOSE_FILE" up -d
    
    echo "Waiting for services to become healthy..."
    sleep 5
    
    echo "Workspace MCP services started:"
    echo "  Registry:  http://localhost:9080"
    echo "  Gateway:   http://localhost:9090"
    echo "  Network:   workspace-mcp-network"
}

stop_services() {
    echo "Stopping workspace MCP services..."
    cd "$WORKSPACE_MCP_DIR"
    docker-compose -f "$COMPOSE_FILE" down
    echo "Workspace MCP services stopped."
}

restart_services() {
    echo "Restarting workspace MCP services..."
    stop_services
    sleep 2
    start_services
}

show_status() {
    echo "Workspace MCP services status:"
    cd "$WORKSPACE_MCP_DIR"
    docker-compose -f "$COMPOSE_FILE" ps
}

show_logs() {
    echo "Workspace MCP services logs:"
    cd "$WORKSPACE_MCP_DIR"
    docker-compose -f "$COMPOSE_FILE" logs -f
}

clean_services() {
    echo "Cleaning workspace MCP services..."
    cd "$WORKSPACE_MCP_DIR"
    docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
    
    # Remove any dangling containers with our workspace hash
    echo "Removing containers with workspace hash: $WORKSPACE_HASH"
    docker ps -a --filter "name=workspace-.*-$WORKSPACE_HASH" -q | xargs -r docker rm -f
    
    echo "Workspace MCP services cleaned."
}

case "${1:-}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    clean)
        clean_services
        ;;
    *)
        usage
        exit 1
        ;;
esac