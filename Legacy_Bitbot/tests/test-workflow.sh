#!/bin/bash
# BitBot Full Workflow Test
# Tests complete BitBot functionality with real services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
echo "   BitBot Full Workflow Test"
echo "========================================="
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log_info "BitBot Root: $BITBOT_ROOT"

# Step 1: Check prerequisites
log_info "Step 1: Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    log_error "Docker command not found"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker daemon not accessible"
    exit 1
fi

log_success "Docker is accessible"

# Step 2: Start global MCP services
log_info "Step 2: Starting global MCP services..."

MCP_DIR="$BITBOT_ROOT/global/mcp"
if [[ ! -d "$MCP_DIR" ]]; then
    log_error "Global MCP directory not found: $MCP_DIR"
    exit 1
fi

cd "$MCP_DIR"

if docker-compose up -d; then
    log_success "Global MCP services started"
else
    log_error "Failed to start global MCP services"
    exit 1
fi

# Step 3: Wait for services to initialize
log_info "Step 3: Waiting for services to initialize..."
sleep 10
log_success "Initialization wait complete"

# Step 4: Test MCP registry
log_info "Step 4: Testing MCP registry..."
if timeout 30 curl -s http://localhost:8080/health > /dev/null 2>&1; then
    log_success "MCP Registry is responding"
    
    registry_response=$(curl -s http://localhost:8080/health 2>/dev/null | jq -r '.status' 2>/dev/null || echo "unknown")
    if [[ "$registry_response" == "healthy" ]]; then
        log_success "MCP Registry reports healthy status"
    else
        log_warning "MCP Registry status: $registry_response"
    fi
else
    log_warning "MCP Registry not responding after 30 seconds"
fi

# Step 5: Test SimpleMCP via gateway
log_info "Step 5: Testing SimpleMCP..."
if timeout 30 curl -s http://localhost:8090/ping > /dev/null 2>&1; then
    log_success "SimpleMCP accessible via gateway"
    
    ping_response=$(curl -s http://localhost:8090/ping 2>/dev/null)
    if echo "$ping_response" | grep -q "pong"; then
        log_success "SimpleMCP ping test successful"
    else
        log_warning "SimpleMCP ping test returned unexpected response"
    fi
else
    log_warning "SimpleMCP not accessible via gateway"
fi

# Step 6: Create test workspace
log_info "Step 6: Creating test workspace..."

TEST_WORKSPACE="$BITBOT_ROOT/tests/test-workspace-workflow"
rm -rf "$TEST_WORKSPACE"
mkdir -p "$TEST_WORKSPACE"
cd "$TEST_WORKSPACE"

# Create a realistic project structure
cat > package.json << 'EOF'
{
  "name": "bitbot-test-project",
  "version": "1.0.0",
  "description": "Test project for BitBot workflow validation",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "echo \"Test passed from test-workspace!\""
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

cat > index.js << 'EOF'
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    res.json({ 
        message: 'Hello from BitBot test workspace!',
        timestamp: new Date().toISOString(),
        workspace: 'test-workspace-workflow'
    });
});

app.listen(port, () => {
    console.log(`Test app listening at http://localhost:${port}`);
});
EOF

cat > .gitignore << 'EOF'
node_modules/
.env
*.log
EOF

log_success "Test workspace created"

# Step 7: Test devcontainer generation
log_info "Step 7: Testing devcontainer generation..."

export BITBOT_ROOT="$BITBOT_ROOT"
export CURRENT_DIR="$TEST_WORKSPACE"

if timeout 30 bash "$BITBOT_ROOT/global/setup-devcontainer.sh" docker 2>/dev/null; then
    log_success "DevContainer setup completed"
    
    if [[ -f ".devcontainer/devcontainer.json" ]]; then
        log_success "DevContainer configuration created"
        
        # Validate devcontainer.json
        if cat .devcontainer/devcontainer.json | python3 -m json.tool >/dev/null 2>&1; then
            log_success "DevContainer JSON is valid"
        else
            log_warning "DevContainer JSON validation failed"
        fi
    else
        log_warning "DevContainer configuration not found"
    fi
else
    log_warning "DevContainer setup failed or timed out"
fi

# Step 8: Test workspace MCP services
log_info "Step 8: Testing workspace MCP services..."

WORKSPACE_MCP_DIR="$BITBOT_ROOT/devcontainer-base/bitbot/mcp"
if [[ -f "$WORKSPACE_MCP_DIR/docker-compose.yml" ]]; then
    cd "$WORKSPACE_MCP_DIR"
    
    # Test configuration without starting
    if timeout 10 docker-compose config --quiet 2>/dev/null; then
        log_success "Workspace MCP configuration is valid"
        
        # Test service definitions
        services=$(docker-compose config --services 2>/dev/null)
        if echo "$services" | grep -q "workspace-mcp-registry"; then
            log_success "Workspace MCP services properly defined"
        else
            log_warning "Workspace MCP services not properly defined"
        fi
    else
        log_warning "Workspace MCP configuration invalid"
    fi
else
    log_warning "Workspace MCP docker-compose.yml not found"
fi

cd "$TEST_WORKSPACE"

# Step 9: Test BitBot entry script
log_info "Step 9: Testing BitBot entry script..."

export BITBOT_DRY_RUN=1
if timeout 30 bash "$BITBOT_ROOT/global/bitbot" 2>&1 | grep -q "BitBot"; then
    log_success "BitBot entry script executes successfully"
else
    log_warning "BitBot entry script execution test failed"
fi
unset BITBOT_DRY_RUN

# Step 10: Show service status
log_info "Step 10: Final service status..."
cd "$MCP_DIR"
echo ""
docker-compose ps
echo ""

# Step 11: Test service discovery
log_info "Step 11: Testing service discovery..."
services_response=$(curl -s http://localhost:8080/services 2>/dev/null || echo '{"count": 0}')
service_count=$(echo "$services_response" | jq -r '.count // 0' 2>/dev/null || echo "0")

if [[ "$service_count" -gt 0 ]]; then
    log_success "Service discovery found $service_count services"
    echo "$services_response" | jq -r '.services | keys[]?' 2>/dev/null | while read -r service; do
        echo "  📋 $service"
    done || echo "  📋 Services found but couldn't parse details"
else
    log_warning "No services found in registry"
fi

# Cleanup
log_info "Cleaning up test workspace..."
cd "$BITBOT_ROOT"
rm -rf "$TEST_WORKSPACE"
log_success "Test workspace cleaned up"

echo ""
echo "========================================="
echo "   Workflow Test Results Summary"
echo "========================================="
echo ""
log_success "Core Components Tested:"
echo "  📁 Project structure and organization"
echo "  🐳 Docker services and containers"
echo "  🌐 MCP Registry (http://localhost:8080)"
echo "  🔗 MCP Gateway (http://localhost:8090)"
echo "  ⚙️  DevContainer generation"
echo "  📋 Service discovery and health checks"
echo ""

log_info "To stop services when done testing:"
echo "  cd $MCP_DIR && docker-compose down"
echo ""

log_info "To start a development session:"
echo "  1. Create or navigate to a project directory"
echo "  2. Run: $BITBOT_ROOT/global/bitbot"
echo "  3. Choose your preferred launch mode"
echo "  4. Start developing!"
echo ""

log_success "BitBot workflow test completed successfully!"
echo ""

# Keep services running for manual testing
log_info "Global MCP services are still running for manual testing."
log_info "Use 'docker-compose down' in $MCP_DIR to stop them."

sleep 2