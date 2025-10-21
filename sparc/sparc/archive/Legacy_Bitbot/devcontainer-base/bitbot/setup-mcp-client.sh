#!/bin/bash
# MCP Client Setup Script
# Discovers available MCP services and configures Claude Code

set -e

echo "🔍 Setting up MCP client..."

# Configuration
REGISTRY_URL="${MCP_REGISTRY_URL:-http://mcp-registry:8080}"
CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-/home/node/.claude}"
MCP_CONFIG_FILE="$CLAUDE_CONFIG_DIR/mcp.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log with colors
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

# Check if MCP registry is accessible
check_registry() {
    log_info "Checking MCP registry connectivity..."
    
    if curl -s --connect-timeout 5 "$REGISTRY_URL/health" > /dev/null; then
        log_success "MCP registry is accessible at $REGISTRY_URL"
        return 0
    else
        log_warning "MCP registry not accessible at $REGISTRY_URL"
        return 1
    fi
}

# Discover available MCP services
discover_services() {
    log_info "Discovering available MCP services..."
    
    local services_response
    services_response=$(curl -s --connect-timeout 10 "$REGISTRY_URL/services" 2>/dev/null || echo '{"services": {}, "count": 0}')
    
    # Parse the response
    local service_count
    service_count=$(echo "$services_response" | jq -r '.count // 0' 2>/dev/null || echo "0")
    
    if [ "$service_count" -gt 0 ]; then
        log_success "Found $service_count MCP services"
        echo "$services_response" | jq -r '.services | keys[]' 2>/dev/null || echo ""
        return 0
    else
        log_warning "No MCP services found"
        return 1
    fi
}

# Test individual service connectivity
test_service_connectivity() {
    local service_name="$1"
    log_info "Testing connectivity to $service_name..."
    
    # Get service details
    local service_info
    service_info=$(curl -s --connect-timeout 5 "$REGISTRY_URL/services/$service_name" 2>/dev/null || echo '{}')
    
    # Extract IP address from networks
    local service_ip
    service_ip=$(echo "$service_info" | jq -r '.networks[0].ip // empty' 2>/dev/null)
    
    if [ -n "$service_ip" ]; then
        # Try to ping the service
        if curl -s --connect-timeout 3 "http://$service_ip:3000/health" > /dev/null 2>&1; then
            log_success "$service_name is responding at $service_ip"
            return 0
        elif curl -s --connect-timeout 3 "http://$service_ip:8000/health" > /dev/null 2>&1; then
            log_success "$service_name is responding at $service_ip:8000"
            return 0
        else
            log_warning "$service_name is not responding to health checks"
            return 1
        fi
    else
        log_warning "Could not determine IP address for $service_name"
        return 1
    fi
}

# Generate Claude Code MCP configuration
generate_mcp_config() {
    log_info "Generating Claude Code MCP configuration..."
    
    # Ensure config directory exists
    mkdir -p "$CLAUDE_CONFIG_DIR"
    
    # Get services from registry
    local services_response
    services_response=$(curl -s --connect-timeout 10 "$REGISTRY_URL/services" 2>/dev/null || echo '{"services": {}}')
    
    # Start building MCP configuration
    local mcp_config='{
  "mcpServers": {}
}'
    
    # Add each discovered service
    local services
    services=$(echo "$services_response" | jq -r '.services | keys[]' 2>/dev/null || echo "")
    
    if [ -n "$services" ]; then
        for service in $services; do
            log_info "Adding $service to MCP configuration..."
            
            # Get service capabilities
            local capabilities
            capabilities=$(curl -s --connect-timeout 5 "$REGISTRY_URL/capabilities/$service" 2>/dev/null || echo '{}')
            
            # For now, add a basic configuration for each service
            # This would need to be customized based on the actual MCP protocol requirements
            mcp_config=$(echo "$mcp_config" | jq --arg service "$service" \
                '.mcpServers[$service] = {
                    "command": "node",
                    "args": ["-e", "console.log(\"MCP bridge for " + $service + "\")"],
                    "env": {}
                }')
        done
        
        # Write configuration file
        echo "$mcp_config" | jq . > "$MCP_CONFIG_FILE"
        log_success "MCP configuration written to $MCP_CONFIG_FILE"
    else
        log_warning "No services found to configure"
        # Create minimal config
        echo '{"mcpServers": {}}' | jq . > "$MCP_CONFIG_FILE"
    fi
}

# Create MCP test commands
create_test_commands() {
    log_info "Creating MCP test commands..."
    
    # Create mcp-test command
    cat > /home/node/scripts/mcp-test << 'EOF'
#!/bin/bash
# MCP Test Command
# Test connectivity to MCP services

case "$1" in
    "ping")
        echo "🏓 Testing MCP connectivity..."
        curl -s http://simple-mcp:3000/ping | jq . 2>/dev/null || echo "❌ Ping failed"
        ;;
    "echo")
        shift
        message="$*"
        if [ -z "$message" ]; then
            message="Hello from devcontainer"
        fi
        echo "📣 Testing echo with message: $message"
        curl -s -X POST http://simple-mcp:3000/echo \
            -H "Content-Type: application/json" \
            -d "{\"message\":\"$message\"}" | jq . 2>/dev/null || echo "❌ Echo failed"
        ;;
    "services")
        echo "🔍 Available MCP services:"
        curl -s http://mcp-registry:8080/services | jq -r '.services | keys[] // "No services found"' 2>/dev/null
        ;;
    "status")
        echo "📊 MCP Service Status:"
        curl -s http://mcp-registry:8080/health | jq . 2>/dev/null || echo "❌ Registry not accessible"
        ;;
    *)
        echo "Usage: mcp-test [ping|echo <message>|services|status]"
        echo "Examples:"
        echo "  mcp-test ping              - Test basic connectivity"
        echo "  mcp-test echo Hello        - Test echo service"
        echo "  mcp-test services          - List available services"
        echo "  mcp-test status            - Show registry status"
        ;;
esac
EOF

    chmod +x /home/node/scripts/mcp-test
    log_success "Created mcp-test command"
}

# Main setup function
main() {
    echo "🚀 MCP Client Setup Starting..."
    echo "Registry URL: $REGISTRY_URL"
    echo "Config Directory: $CLAUDE_CONFIG_DIR"
    echo ""
    
    # Check if registry is available
    if check_registry; then
        # Discover and test services
        if discover_services; then
            # Test connectivity to each service
            local services
            services=$(curl -s "$REGISTRY_URL/services" | jq -r '.services | keys[]' 2>/dev/null || echo "")
            
            for service in $services; do
                test_service_connectivity "$service"
            done
            
            # Generate configuration
            generate_mcp_config
        else
            log_warning "No services discovered, creating minimal configuration"
            generate_mcp_config
        fi
    else
        log_warning "MCP registry not available, creating offline configuration"
        mkdir -p "$CLAUDE_CONFIG_DIR"
        echo '{"mcpServers": {}}' | jq . > "$MCP_CONFIG_FILE"
    fi
    
    # Create test commands
    create_test_commands
    
    echo ""
    log_success "MCP client setup complete!"
    echo ""
    echo "💡 Try these commands:"
    echo "  mcp-test ping      - Test basic connectivity"
    echo "  mcp-test services  - List available services"
    echo "  claude             - Start Claude Code with MCP support"
    echo ""
}

# Run main function
main "$@"