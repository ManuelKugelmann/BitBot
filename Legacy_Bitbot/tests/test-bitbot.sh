#!/bin/bash
# BitBot Test Suite
# Validates script syntax, Docker files, and core functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Configuration
BITBOT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_WORKSPACE="$BITBOT_ROOT/tests/test-workspace"

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}  ✓${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}  ✗${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_info() {
    echo -e "${BLUE}  →${NC} $1"
}

validate_script_syntax() {
    local script="$1"
    local name="$2"
    
    if [[ ! -f "$script" ]]; then
        log_fail "$name: file not found"
        return 1
    fi
    
    if bash -n "$script" 2>/dev/null; then
        log_pass "$name: syntax valid"
    else
        log_fail "$name: syntax error"
        return 1
    fi
}

validate_dockerfile() {
    local dockerfile="$1"
    local name="$2"
    
    if [[ ! -f "$dockerfile" ]]; then
        log_fail "$name: file not found"
        return 1
    fi
    
    # Basic Dockerfile validation
    if grep -q "^FROM " "$dockerfile" && grep -q "^WORKDIR " "$dockerfile"; then
        log_pass "$name: basic structure valid"
    else
        log_fail "$name: missing FROM or WORKDIR"
        return 1
    fi
    
    # Check timezone support
    if grep -q "ARG TZ" "$dockerfile" && grep -q "ENV TZ" "$dockerfile"; then
        log_pass "$name: timezone support present"
    else
        log_fail "$name: missing timezone support"
        return 1
    fi
}

validate_compose_file() {
    local compose_file="$1"
    local name="$2"
    
    if [[ ! -f "$compose_file" ]]; then
        log_fail "$name: file not found"
        return 1
    fi
    
    # Use docker-compose to validate syntax
    local compose_dir=$(dirname "$compose_file")
    cd "$compose_dir"
    
    if timeout 10 docker-compose -f "$(basename "$compose_file")" config --quiet 2>/dev/null; then
        log_pass "$name: compose syntax valid"
        cd "$BITBOT_ROOT"
    else
        log_fail "$name: compose syntax error"
        cd "$BITBOT_ROOT"
        return 1
    fi
}

create_test_workspace() {
    log_test "Creating test workspace"
    
    # Clean and create test workspace
    rm -rf "$TEST_WORKSPACE"
    mkdir -p "$TEST_WORKSPACE"
    cd "$TEST_WORKSPACE"
    
    # Create a sample project
    cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "description": "Test project for BitBot",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Test passed\""
  }
}
EOF

    cat > index.js << 'EOF'
console.log('Hello from BitBot test workspace!');
EOF

    cat > README.md << 'EOF'
# Test Project

This is a test project for validating BitBot functionality.
EOF

    log_pass "Test workspace created at $TEST_WORKSPACE"
}

test_devcontainer_generation() {
    log_test "Testing devcontainer generation"
    
    cd "$TEST_WORKSPACE"
    
    # Simulate devcontainer creation
    export BITBOT_ROOT="$BITBOT_ROOT"
    export CURRENT_DIR="$TEST_WORKSPACE"
    
    # Test the setup script
    if [[ -f "$BITBOT_ROOT/global/setup-devcontainer.sh" ]]; then
        if timeout 30 bash "$BITBOT_ROOT/global/setup-devcontainer.sh" docker 2>/dev/null; then
            log_pass "DevContainer setup script executed successfully"
            
            if [[ -f ".devcontainer/devcontainer.json" ]]; then
                log_pass "DevContainer configuration created"
                
                # Validate JSON syntax
                if python3 -m json.tool .devcontainer/devcontainer.json >/dev/null 2>&1 || \
                   node -e "JSON.parse(require('fs').readFileSync('.devcontainer/devcontainer.json', 'utf8'))" 2>/dev/null; then
                    log_pass "DevContainer JSON syntax valid"
                else
                    log_fail "DevContainer JSON syntax invalid"
                fi
                
                # Check for .bitbot folder creation
                if [[ -d ".bitbot" ]]; then
                    log_pass "BitBot workspace tracking folder created"
                    
                    # Check for expected files in .bitbot folder
                    if [[ -f ".bitbot/workspace-hash" && -f ".bitbot/created" ]]; then
                        log_pass "BitBot workspace metadata files created"
                    else
                        log_fail "BitBot workspace metadata files missing"
                    fi
                else
                    log_fail "BitBot workspace tracking folder not created"
                fi
            else
                log_fail "DevContainer configuration not created"
            fi
        else
            log_fail "DevContainer setup script failed"
        fi
    else
        log_fail "DevContainer setup script not found"
    fi
    
    cd "$BITBOT_ROOT"
}

test_mcp_services() {
    log_test "Testing MCP services (dry run)"
    
    # Test global MCP services
    if [[ -f "$BITBOT_ROOT/global/mcp/docker-compose.yml" ]]; then
        cd "$BITBOT_ROOT/global/mcp"
        
        # Test if services can be listed
        if timeout 10 docker-compose config --services 2>/dev/null | grep -q "mcp-registry"; then
            log_pass "Global MCP services defined correctly"
        else
            log_fail "Global MCP services configuration invalid"
        fi
        
        cd "$BITBOT_ROOT"
    else
        log_fail "Global MCP docker-compose.yml not found"
    fi
    
    # Test workspace MCP services
    if [[ -f "$BITBOT_ROOT/devcontainer-base/bitbot/mcp/docker-compose.yml" ]]; then
        cd "$BITBOT_ROOT/devcontainer-base/bitbot/mcp"
        
        if timeout 10 docker-compose config --services 2>/dev/null | grep -q "workspace-mcp-registry"; then
            log_pass "Workspace MCP services defined correctly"
        else
            log_fail "Workspace MCP services configuration invalid"
        fi
        
        cd "$BITBOT_ROOT"
    else
        log_fail "Workspace MCP docker-compose.yml not found"
    fi
}

test_workspace_mounting() {
    log_test "Testing workspace mounting consistency"
    
    cd "$TEST_WORKSPACE"
    
    # Create a test file to verify mounting
    echo "BitBot workspace mount test" > workspace-mount-test.txt
    
    # Test that environment variables are set correctly for Docker launch
    export BITBOT_ROOT="$BITBOT_ROOT"
    export CURRENT_DIR="$TEST_WORKSPACE"
    
    # Simulate the environment setup that launch-docker.sh does
    cd "$BITBOT_ROOT/devcontainer-base"
    export WORKSPACE_FOLDER="$TEST_WORKSPACE"
    export WORKSPACE_HASH="test-hash"
    export TZ="${TZ:-UTC}"
    
    # Test that docker-compose config works with our environment
    if timeout 10 docker-compose config --quiet 2>/dev/null; then
        log_pass "Docker compose configuration valid with workspace mount"
        
        # Check that the workspace folder variable is properly set
        if docker-compose config 2>/dev/null | grep -q "$TEST_WORKSPACE"; then
            log_pass "Workspace folder correctly referenced in compose config"
        else
            log_fail "Workspace folder not found in compose config"
        fi
    else
        log_fail "Docker compose configuration invalid with workspace variables"
    fi
    
    cd "$BITBOT_ROOT"
}

test_functional_workflow() {
    log_test "Testing functional workflow"
    
    cd "$TEST_WORKSPACE"
    
    # Test BitBot entry script execution (dry run)
    export BITBOT_DRY_RUN=1
    
    if timeout 30 bash "$BITBOT_ROOT/global/bitbot" 2>&1 | grep -q "BitBot"; then
        log_pass "BitBot entry script executes successfully"
    else
        log_fail "BitBot entry script execution failed"
    fi
    
    unset BITBOT_DRY_RUN
    cd "$BITBOT_ROOT"
}

# Main test execution
main() {
    echo -e "${BLUE}================================"
    echo "BitBot Test Suite"
    echo "================================${NC}"
    echo "BitBot Root: $BITBOT_ROOT"
    echo ""
    
    # 1. Script Syntax Validation
    echo -e "${BLUE}=== Script Syntax Validation ===${NC}"
    validate_script_syntax "$BITBOT_ROOT/global/bitbot" "Global BitBot entry script"
    validate_script_syntax "$BITBOT_ROOT/global/bitbot-core.sh" "BitBot core script"
    validate_script_syntax "$BITBOT_ROOT/global/start-mcp.sh" "MCP start script"
    validate_script_syntax "$BITBOT_ROOT/global/stop-mcp.sh" "MCP stop script"
    validate_script_syntax "$BITBOT_ROOT/global/setup-devcontainer.sh" "DevContainer setup"
    validate_script_syntax "$BITBOT_ROOT/devcontainer-base/bitbot/bitbot" "Container BitBot script"
    validate_script_syntax "$BITBOT_ROOT/devcontainer-base/bitbot/workspace-mcp.sh" "Workspace MCP script"
    echo ""
    
    # 2. Docker File Validation  
    echo -e "${BLUE}=== Docker File Validation ===${NC}"
    validate_dockerfile "$BITBOT_ROOT/devcontainer-base/Dockerfile.base" "DevContainer base"
    validate_dockerfile "$BITBOT_ROOT/shared/registry/Dockerfile" "MCP Registry"
    validate_dockerfile "$BITBOT_ROOT/shared/simple-mcp/Dockerfile" "Simple MCP"
    echo ""
    
    # 3. Docker Compose Validation
    echo -e "${BLUE}=== Docker Compose Validation ===${NC}"
    validate_compose_file "$BITBOT_ROOT/devcontainer-base/docker-compose.yml" "DevContainer compose"
    validate_compose_file "$BITBOT_ROOT/global/mcp/docker-compose.yml" "Global MCP compose"
    validate_compose_file "$BITBOT_ROOT/devcontainer-base/bitbot/mcp/docker-compose.yml" "Workspace MCP compose"
    echo ""
    
    # 3.5. DevContainer Template Validation
    echo -e "${BLUE}=== DevContainer Template Validation ===${NC}"
    log_test "DevContainer template file exists"
    if [[ -f "$BITBOT_ROOT/devcontainer-base/devcontainer.json" ]]; then
        log_pass "DevContainer template found"
        
        # Validate template JSON syntax
        if python3 -m json.tool "$BITBOT_ROOT/devcontainer-base/devcontainer.json" >/dev/null 2>&1 || \
           node -e "JSON.parse(require('fs').readFileSync('$BITBOT_ROOT/devcontainer-base/devcontainer.json', 'utf8'))" 2>/dev/null; then
            log_pass "DevContainer template JSON syntax valid"
        else
            log_fail "DevContainer template JSON syntax invalid"
        fi
        
        # Check for required template variables
        if grep -q '${WORKSPACE_HASH}' "$BITBOT_ROOT/devcontainer-base/devcontainer.json"; then
            log_pass "DevContainer template contains workspace hash variable"
        else
            log_fail "DevContainer template missing workspace hash variable"
        fi
    else
        log_fail "DevContainer template not found"
    fi
    echo ""
    
    # 4. Test Workspace Creation
    echo -e "${BLUE}=== Test Workspace ===${NC}"
    create_test_workspace
    echo ""
    
    # 5. DevContainer Generation
    echo -e "${BLUE}=== DevContainer Generation ===${NC}"
    test_devcontainer_generation
    echo ""
    
    # 6. MCP Services
    echo -e "${BLUE}=== MCP Services ===${NC}"
    test_mcp_services
    echo ""
    
    # 7. Workspace Mounting
    echo -e "${BLUE}=== Workspace Mounting ===${NC}"
    test_workspace_mounting
    echo ""
    
    # 8. Functional Workflow
    echo -e "${BLUE}=== Functional Workflow ===${NC}"
    test_functional_workflow
    echo ""
    
    # Cleanup
    echo -e "${BLUE}=== Cleanup ===${NC}"
    log_test "Cleaning up test workspace"
    rm -rf "$TEST_WORKSPACE"
    log_pass "Test workspace removed"
    echo ""
    
    # Results
    echo -e "${BLUE}================================"
    echo "Test Results"
    echo "================================${NC}"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed! BitBot is ready for use.${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed. Please review the output above.${NC}"
        return 1
    fi
}

# Check if Docker is available before running tests
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Docker not found. Some tests will be skipped.${NC}"
fi

# Run tests
main "$@"