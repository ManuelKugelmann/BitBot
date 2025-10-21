#!/bin/bash
# Start MCP Services (Linux)
# This script starts all MCP services using docker-compose

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
echo "   Starting MCP Services (Linux)"
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

# Check if we're on Linux
if [[ ! -f "/proc/version" ]]; then
    log_warning "This script is designed for Linux environments"
    log_info "For Windows, use the .bat scripts instead"
fi

# Check if Docker is accessible
if ! command -v docker &> /dev/null; then
    log_error "Docker command not found"
    log_info "Make sure Docker Desktop is running and WSL2 integration is enabled"
    exit 1
fi

# Test Docker connectivity
if ! docker info &> /dev/null; then
    log_error "Cannot connect to Docker daemon"
    log_info "Ensure Docker is running and accessible"
    log_info "For Docker Desktop: check that the daemon is started"
    exit 1
fi

log_success "Docker is accessible"

# Navigate to MCP services directory
if [[ ! -d "$MCP_DIR" ]]; then
    log_error "MCP services directory not found: $MCP_DIR"
    exit 1
fi

cd "$MCP_DIR"

# Check if .env file exists
if [[ ! -f ".env" ]]; then
    if [[ -f ".env.example" ]]; then
        log_warning "No .env file found, copying from .env.example"
        cp ".env.example" ".env"
        log_success "Created .env file - edit it with your API keys if needed"
    else
        log_error "No .env or .env.example file found"
        log_info "Please create a .env file with your configuration"
        exit 1
    fi
fi

# Start MCP services
log_info "Starting MCP services..."
echo ""

if docker-compose up -d; then
    log_success "MCP services started successfully!"
else
    log_error "Failed to start MCP services"
    log_info "Check the error messages above for details"
    exit 1
fi

echo ""
log_info "Service endpoints:"
echo "  🌐 MCP Registry: http://localhost:8080"
echo "  🔗 MCP Gateway: http://localhost:8090"
echo ""

# Wait for services to initialize
log_info "Waiting for services to initialize..."
sleep 5

# Check service health
log_info "Checking service health..."

# Check registry health
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    log_success "MCP Registry is responding"
else
    log_warning "MCP Registry may not be ready yet (this is normal on first start)"
fi

# Check SimpleMCP via gateway
if curl -s http://localhost:8090 > /dev/null 2>&1; then
    log_success "SimpleMCP is accessible via gateway"
else
    log_warning "SimpleMCP may not be ready yet"
fi

# Show service status
echo ""
log_info "Service status:"
docker-compose ps

echo ""
log_success "MCP services are running!"
echo ""
log_info "Quick commands:"
echo "  docker-compose logs    - View service logs"
echo "  docker-compose stop    - Stop services"
echo "  docker-compose down    - Stop and remove containers"
echo ""
log_info "Ready to use! You can now start a devcontainer."

# Keep script running for a moment to show output
sleep 2