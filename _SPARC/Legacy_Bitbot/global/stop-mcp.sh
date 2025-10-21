#!/bin/bash
# Stop MCP Services (Linux)
# This script stops all MCP services using docker-compose

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo ""
echo "========================================="
echo "   Stopping MCP Services (Linux)"
echo "========================================="
echo ""

# Navigate to the correct directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Use BITBOT_HOME if set, otherwise use relative path
if [[ -n "$BITBOT_HOME" ]]; then
    MCP_DIR="$BITBOT_HOME/global/mcp"
else
    MCP_DIR="$SCRIPT_DIR/mcp"
fi

log_info "Script directory: $SCRIPT_DIR"
log_info "MCP services directory: $MCP_DIR"

# Check if Docker is accessible
if ! command -v docker &> /dev/null; then
    log_error "Docker command not found"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_warning "Cannot connect to Docker daemon"
    log_info "Services may already be stopped or Docker is not running"
    exit 0
fi

log_success "Docker is accessible"

# Navigate to MCP services directory
if [[ ! -d "$MCP_DIR" ]]; then
    log_error "MCP services directory not found: $MCP_DIR"
    exit 1
fi

cd "$MCP_DIR"

# Show current status
log_info "Current service status:"
docker-compose ps

echo ""

# Stop services
log_info "Stopping MCP services..."
if docker-compose stop; then
    log_success "MCP services stopped successfully!"
else
    log_error "Error stopping services"
    exit 1
fi

# Ask about removing containers
echo ""
read -p "🗑️  Remove containers completely? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Removing containers..."
    if docker-compose down; then
        log_success "Containers removed"
    else
        log_warning "Error removing containers"
    fi
fi

echo ""
log_success "MCP services have been stopped."
log_info "Use start-mcp.sh to start them again."