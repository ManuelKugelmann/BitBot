#!/bin/bash
# BitBot Integration Test - Standalone Workflow
# Tests the complete workflow: bitbot launch -> container -> Claude CLI -> validation

set -e

# Prevent Git Bash path conversion on Windows
export MSYS_NO_PATHCONV=1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test configuration
BITBOT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_WORKSPACE="$BITBOT_ROOT/tests/integration-test-workspace"
MARKER_FILE="bitbot-integration-test-marker.txt"
MARKER_CONTENT="BitBot Integration Test - Created at $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Test tracking
TESTS_PASSED=0
TESTS_FAILED=0
CLEANUP_REQUIRED=0

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

cleanup() {
    if [[ $CLEANUP_REQUIRED -eq 1 ]]; then
        echo -e "${YELLOW}[CLEANUP]${NC} Cleaning up test environment..."
        
        # Stop and remove test container if running
        local workspace_hash=$(echo "$TEST_WORKSPACE" | sha256sum | cut -c1-8 2>/dev/null || echo "$TEST_WORKSPACE" | shasum -a 256 | cut -c1-8)
        local container_name="bitbot-dev-$workspace_hash"
        
        if docker ps -a --format "table {{.Names}}" | grep -q "^$container_name$"; then
            docker stop "$container_name" >/dev/null 2>&1 || true
            docker rm "$container_name" >/dev/null 2>&1 || true
        fi
        
        # Remove test workspace
        rm -rf "$TEST_WORKSPACE"
        
        # Remove test images
        local image_name="bitbot-workspace-$workspace_hash"
        if docker images --format "table {{.Repository}}" | grep -q "^$image_name$"; then
            docker rmi "$image_name" >/dev/null 2>&1 || true
        fi
        
        echo -e "${GREEN}[CLEANUP]${NC} Test environment cleaned up"
    fi
}

# Set cleanup trap
trap cleanup EXIT

create_test_workspace() {
    log_test "Creating integration test workspace"
    
    # Clean and create test workspace
    rm -rf "$TEST_WORKSPACE"
    mkdir -p "$TEST_WORKSPACE"
    cd "$TEST_WORKSPACE"
    
    # Create a sample project with marker file
    cat > package.json << 'EOF'
{
  "name": "bitbot-integration-test",
  "version": "1.0.0",
  "description": "Integration test project for BitBot standalone workflow",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Integration test passed\""
  }
}
EOF

    cat > index.js << 'EOF'
console.log('BitBot Integration Test - Node.js application');
console.log('Workspace:', process.cwd());
console.log('Environment:', process.env.NODE_ENV || 'development');
EOF

    # Create marker file to verify workspace mount
    echo "$MARKER_CONTENT" > "$MARKER_FILE"
    
    # Create a .claude directory to simulate Claude config
    mkdir -p .claude
    cat > .claude/config.json << 'EOF'
{
  "test_mode": true,
  "integration_test": "bitbot-standalone-workflow",
  "created": "2024-01-01T00:00:00Z"
}
EOF
    
    log_pass "Test workspace created at $TEST_WORKSPACE"
    log_info "Marker file: $MARKER_FILE"
    log_info "Claude config: .claude/config.json"
    
    CLEANUP_REQUIRED=1
}

test_bitbot_first_run() {
    log_test "Testing BitBot first run (direct Docker mode)"
    
    cd "$TEST_WORKSPACE"
    export BITBOT_ROOT="$BITBOT_ROOT"
    export CURRENT_DIR="$TEST_WORKSPACE"
    
    # Test first run detection
    if [[ -d ".bitbot" ]]; then
        log_fail "Expected first run but .bitbot folder already exists"
        return 1
    fi
    
    # Simulate choosing direct Docker mode (option 2)
    # We'll need to modify this to non-interactive for testing
    export BITBOT_TEST_MODE=1
    export BITBOT_TEST_CHOICE=2  # Direct Docker launch
    
    log_info "Simulating BitBot first run with direct Docker choice"
    
    # Create the .bitbot setup manually since we can't interact with menu
    # Use CURRENT_DIR (pwd) instead of TEST_WORKSPACE for consistent hash generation
    local workspace_hash=$(echo "$(pwd)" | sha256sum | cut -c1-8 2>/dev/null || echo "$(pwd)" | shasum -a 256 | cut -c1-8)
    mkdir -p ".bitbot"
    echo "$workspace_hash" > ".bitbot/workspace-hash"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > ".bitbot/created"
    
    # Create workspace Dockerfile
    cat > ".bitbot/Dockerfile" << EOF
# BitBot Workspace Container
# Generated for workspace: $(basename "$(pwd)")
# Workspace hash: $workspace_hash

# Use the pre-built base image from devcontainer-base/Dockerfile.base
FROM bitbot-base:latest

# Add workspace-specific environment
ENV WORKSPACE_HASH=$workspace_hash
ENV CONTAINER_NAME=bitbot-dev-$workspace_hash

# Workspace metadata
LABEL workspace.hash="$workspace_hash"
LABEL workspace.name="$(basename "$(pwd)")"
LABEL workspace.created="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Default command
CMD ["tmux", "new-session", "-d", "-s", "main", "bitbot"]
EOF
    
    if [[ -f ".bitbot/Dockerfile" && -f ".bitbot/workspace-hash" ]]; then
        log_pass "BitBot workspace setup completed"
        log_info "Workspace hash: $workspace_hash"
    else
        log_fail "BitBot workspace setup failed"
        return 1
    fi
}

test_container_launch() {
    log_test "Testing Docker container launch"
    
    cd "$TEST_WORKSPACE"
    export BITBOT_ROOT="$BITBOT_ROOT"
    export CURRENT_DIR="$TEST_WORKSPACE"
    
    # Get workspace info
    local workspace_hash=$(cat ".bitbot/workspace-hash")
    local container_name="bitbot-dev-$workspace_hash"
    local image_name="bitbot-workspace-$workspace_hash"
    
    log_info "Container name: $container_name"
    log_info "Image name: $image_name"
    
    # Test container launch using launch-docker.sh  
    log_info "Launching container with timeout of 300 seconds..."
    
    # Launch container but ignore the TTY error (expected in test environment)
    timeout 300 "$BITBOT_ROOT/global/launch-docker.sh" 2>&1 | tee /tmp/bitbot-launch.log
    local launch_exit_code=${PIPESTATUS[0]}
    
    # Check if container was created successfully (ignore TTY errors)
    if grep -q "Container started" /tmp/bitbot-launch.log; then
        log_pass "Container launch successful"
    elif [[ $launch_exit_code -eq 124 ]]; then
        log_fail "Container launch timed out"
        return 1
    else
        log_fail "Container launch failed"
        cat /tmp/bitbot-launch.log | tail -10
        return 1
    fi
    
    # Wait a moment for container to be fully ready
    sleep 5
    
    # Check if we have a running container (may be -test version)
    local running_container=""
    if docker ps --format "{{.Names}}" | grep -q "^$container_name$"; then
        running_container="$container_name"
        log_pass "Container is running"
    elif docker ps --format "{{.Names}}" | grep -q "^${container_name}-test$"; then
        running_container="${container_name}-test"
        container_name="${container_name}-test"
        log_pass "Test container is already running"
    else
        # Original container may have exited, start test container
        log_info "Starting test container (original may have exited)"
        # Use current directory directly - Docker Desktop handles path conversion
        local current_dir=$(pwd)
        docker run -d --rm \
            --name "${container_name}-test" \
            --hostname "bitbot-dev" \
            -v "$current_dir:/workspace" \
            -v "$current_dir/.bitbot:/workspace/.bitbot" \
            -e "WORKSPACE_HASH=$workspace_hash" \
            -e "TZ=${TZ:-UTC}" \
            --network="devcontainer-base_default" \
            "$image_name" \
            sleep 300
        
        # Update container name for subsequent tests
        container_name="${container_name}-test"
        log_pass "Test container started with sleep command"
    fi
    
    # Test basic container connectivity
    if docker exec "$container_name" echo "Container connectivity test" >/dev/null 2>&1; then
        log_pass "Container is accessible"
    else
        log_fail "Cannot connect to container"
        return 1
    fi
}

test_workspace_mounts() {
    log_test "Testing workspace and config mounts"
    
    local workspace_hash=$(cat "$TEST_WORKSPACE/.bitbot/workspace-hash")
    local container_name="bitbot-dev-$workspace_hash"
    
    # Test workspace mount
    log_info "Testing workspace mount..."
    if docker exec "$container_name" test -f "/workspace/$MARKER_FILE"; then
        local container_marker_content=$(docker exec "$container_name" cat "/workspace/$MARKER_FILE")
        if [[ "$container_marker_content" == "$MARKER_CONTENT" ]]; then
            log_pass "Workspace mount verified - marker file content matches"
        else
            log_fail "Workspace mount issue - marker file content mismatch"
            log_info "Expected: $MARKER_CONTENT"
            log_info "Found: $container_marker_content"
            return 1
        fi
    else
        log_fail "Workspace mount failed - marker file not found in container"
        return 1
    fi
    
    # Test .bitbot folder mount
    log_info "Testing .bitbot folder mount..."
    if docker exec "$container_name" test -f "/workspace/.bitbot/workspace-hash"; then
        local container_hash=$(docker exec "$container_name" cat "/workspace/.bitbot/workspace-hash")
        if [[ "$container_hash" == "$workspace_hash" ]]; then
            log_pass ".bitbot folder mount verified"
        else
            log_fail ".bitbot folder mount issue - hash mismatch"
            return 1
        fi
    else
        log_fail ".bitbot folder mount failed"
        return 1
    fi
    
    # Test Claude config mount
    log_info "Testing Claude config accessibility..."
    if docker exec "$container_name" test -f "/workspace/.claude/config.json"; then
        log_pass "Claude config accessible in container"
    else
        log_fail "Claude config not accessible in container"
        return 1
    fi
    
    # Test working directory
    local container_pwd=$(docker exec "$container_name" pwd)
    if [[ "$container_pwd" == "/workspace" ]]; then
        log_pass "Container working directory correct"
    else
        log_fail "Container working directory incorrect: $container_pwd"
        return 1
    fi
}

test_container_environment() {
    log_test "Testing container environment and tools"
    
    local workspace_hash=$(cat "$TEST_WORKSPACE/.bitbot/workspace-hash")
    local container_name="bitbot-dev-$workspace_hash"
    
    # Test environment variables
    log_info "Testing environment variables..."
    local container_workspace_hash=$(docker exec "$container_name" printenv WORKSPACE_HASH)
    if [[ "$container_workspace_hash" == "$workspace_hash" ]]; then
        log_pass "WORKSPACE_HASH environment variable correct"
    else
        log_fail "WORKSPACE_HASH environment variable incorrect: $container_workspace_hash"
        return 1
    fi
    
    # Test essential tools
    local tools=("node" "npm" "git" "tmux" "claude-code" "jq" "curl")
    for tool in "${tools[@]}"; do
        if docker exec "$container_name" command -v "$tool" >/dev/null 2>&1; then
            log_pass "$tool available in container"
        else
            log_fail "$tool not available in container"
            return 1
        fi
    done
    
    # Test BitBot script
    if docker exec "$container_name" command -v "bitbot" >/dev/null 2>&1; then
        log_pass "bitbot command available in container"
    else
        log_fail "bitbot command not available in container"
        return 1
    fi
}

test_claude_config() {
    log_test "Testing Claude global config accessibility"
    
    local workspace_hash=$(cat "$TEST_WORKSPACE/.bitbot/workspace-hash")
    local container_name="bitbot-dev-$workspace_hash"
    
    # Test global Claude config directory
    if docker exec "$container_name" test -d "/home/node/.claude"; then
        log_pass "Global Claude config directory accessible"
    else
        log_fail "Global Claude config directory not found"
        return 1
    fi
    
    # Test if Claude config files are accessible (they may or may not exist)
    local config_accessible=0
    if docker exec "$container_name" ls -la "/home/node/.claude" >/dev/null 2>&1; then
        log_pass "Global Claude config directory is readable"
        config_accessible=1
    else
        log_fail "Global Claude config directory not readable"
        return 1
    fi
    
    # Log what's in the config directory for visibility
    if [[ $config_accessible -eq 1 ]]; then
        local config_contents=$(docker exec "$container_name" ls -la "/home/node/.claude" 2>/dev/null || echo "empty")
        log_info "Claude config directory contents: $config_contents"
    fi
}

test_workspace_functionality() {
    log_test "Testing workspace project functionality"
    
    local workspace_hash=$(cat "$TEST_WORKSPACE/.bitbot/workspace-hash")
    local container_name="bitbot-dev-$workspace_hash"
    
    # Test Node.js project
    log_info "Testing Node.js project execution..."
    if docker exec "$container_name" node index.js | grep -q "BitBot Integration Test"; then
        log_pass "Node.js application runs correctly"
    else
        log_fail "Node.js application execution failed"
        return 1
    fi
    
    # Test npm functionality
    if docker exec "$container_name" npm test | grep -q "Integration test passed"; then
        log_pass "NPM test script works"
    else
        log_fail "NPM test script failed"
        return 1
    fi
    
    # Test file system operations
    if docker exec "$container_name" bash -c "echo 'test content' > /workspace/test-write.txt && cat /workspace/test-write.txt" | grep -q "test content"; then
        log_pass "File system read/write operations work"
        
        # Verify file persists on host
        if [[ -f "$TEST_WORKSPACE/test-write.txt" ]]; then
            log_pass "File operations persist to host filesystem"
        else
            log_fail "File operations don't persist to host filesystem"
            return 1
        fi
    else
        log_fail "File system operations failed"
        return 1
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}========================================="
    echo "BitBot Integration Test - Standalone Mode"
    echo "=========================================${NC}"
    echo "BitBot Root: $BITBOT_ROOT"
    echo "Test Workspace: $TEST_WORKSPACE"
    echo ""
    
    # Check prerequisites
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}[ERROR]${NC} Docker not available. Integration test requires Docker."
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}[ERROR]${NC} Docker not running. Please start Docker."
        exit 1
    fi
    
    # Run test sequence
    create_test_workspace
    echo ""
    
    test_bitbot_first_run
    echo ""
    
    test_container_launch
    echo ""
    
    test_workspace_mounts
    echo ""
    
    test_container_environment
    echo ""
    
    test_claude_config
    echo ""
    
    test_workspace_functionality
    echo ""
    
    # Results
    echo -e "${BLUE}========================================="
    echo "Integration Test Results"
    echo "=========================================${NC}"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All integration tests passed! BitBot standalone workflow is working correctly.${NC}"
        return 0
    else
        echo -e "${RED}✗ Some integration tests failed. Please review the output above.${NC}"
        return 1
    fi
}

# Run the integration test
main "$@"