#!/usr/bin/env bash
#
# Test: BitBot User Flow - In-Container Commands
# Tests BitBot commands executed inside a running container
#
# This test uses 'script' command for output capture (no nested tmux)
#
# Usage:
#   test-user-flow-container-commands.sh [--no-cleanup]
#
# Options:
#   --no-cleanup: Skip cleanup (leave container/workspace for inspection)
#
# Requirements:
#   - Docker running
#   - devcontainer CLI available

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_DEV_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Parse command line arguments
SKIP_CLEANUP=false

for arg in "$@"; do
    case "$arg" in
        --no-cleanup)
            SKIP_CLEANUP=true
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: test-user-flow-container-commands.sh [--no-cleanup]"
            exit 1
            ;;
    esac
done

# Test environment
TEST_ENV="/tmp/bitbot-test-container-$$"
WORKSPACE_DIR="$TEST_ENV/workspace"
CONTAINER_NAME="bitbot-test-container-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

pass_count=0
fail_count=0

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    pass_count=$((pass_count + 1))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    fail_count=$((fail_count + 1))
}

test_info() {
    echo -e "${BLUE}ℹ INFO${NC}: $1"
}

test_warning() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
}

# Cleanup function
cleanup() {
    if [[ "$SKIP_CLEANUP" == "true" ]]; then
        echo ""
        echo -e "${YELLOW}⚠ WARN${NC}: Cleanup skipped (--no-cleanup flag)"
        echo -e "  Container and workspace left for inspection"
        echo -e "  Remember to clean up manually:"
        echo -e "    docker stop $CONTAINER_NAME 2>/dev/null || true"
        echo -e "    docker rm $CONTAINER_NAME 2>/dev/null || true"
        echo -e "    rm -rf $TEST_ENV"
        echo ""
        return
    fi

    test_info "Stopping and removing container..."
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true

    if [[ -d "$TEST_ENV" ]]; then
        test_info "Removing test environment..."
        rm -rf "$TEST_ENV"
    fi
}

trap cleanup EXIT

echo ""
echo "=== BitBot User Flow: In-Container Commands Test ==="
echo ""
echo "This test verifies BitBot commands work inside running containers"
echo "using 'script' command for output capture (no nested tmux)."
echo ""

# ============================================================================
# Prerequisites Check
# ============================================================================

echo "[Prerequisites] Checking requirements..."

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ FAIL${NC}: Docker not found"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}✗ FAIL${NC}: Docker not running"
    exit 1
fi

test_pass "Docker available and running"

# ============================================================================
# Setup: Create minimal test workspace
# ============================================================================

echo ""
echo "[Setup] Creating test workspace..."

mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# Create minimal devcontainer configuration
mkdir -p .devcontainer/bitbot

cat > .devcontainer/devcontainer.json <<'EOF'
{
  "name": "bitbot-test-container",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "mounts": [
    "source=${localWorkspaceFolder}/.devcontainer/bitbot,target=/usr/local/bitbot,type=bind,consistency=cached,readonly"
  ]
}
EOF

cat > .devcontainer/Dockerfile <<'EOF'
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    jq \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add BitBot to PATH (will be mounted at runtime)
ENV PATH="/usr/local/bitbot/core:${PATH}"

WORKDIR /workspace
EOF

# Copy BitBot container scripts to workspace
test_info "Copying BitBot container infrastructure..."
cp -r "$BITBOT_DEV_ROOT/container/bitbot/"* .devcontainer/bitbot/

test_pass "Test workspace created"

# ============================================================================
# Test 1: Build and start container
# ============================================================================

echo ""
echo "[Test 1] Building and starting container..."

# Build container directly with docker
test_info "Building container image..."
if docker build -t "$CONTAINER_NAME-image" .devcontainer/ 2>&1 | grep -qE "Successfully built|Successfully tagged"; then
    test_pass "Container image built"
else
    test_fail "Container image build failed"
    exit 1
fi

# Start container in detached mode
test_info "Starting container..."
if docker run -d \
    --name "$CONTAINER_NAME" \
    -v "$WORKSPACE_DIR/.devcontainer/bitbot:/usr/local/bitbot:ro" \
    -v "$WORKSPACE_DIR:/workspace" \
    -w /workspace \
    "$CONTAINER_NAME-image" \
    tail -f /dev/null >/dev/null 2>&1; then
    test_pass "Container started"
else
    test_fail "Container failed to start"
    exit 1
fi

# Wait for container to be fully ready
sleep 2

# ============================================================================
# Test 2: Verify BitBot available in container (using script command)
# ============================================================================

echo ""
echo "[Test 2] Verifying BitBot available in container..."

# Use 'script' command to capture output without nested sessions
output=$(docker exec "$CONTAINER_NAME" script -qec "which bitbot" /dev/null 2>&1 || echo "")

if echo "$output" | grep -q "/usr/local/bitbot/core/bitbot"; then
    test_pass "BitBot found in PATH inside container"
else
    test_fail "BitBot not found in container PATH"
    echo "Output: $output"
fi

# ============================================================================
# Test 3: Run bitbot --version (simple command test)
# ============================================================================

echo ""
echo "[Test 3] Running 'bitbot --version' in container..."

output=$(docker exec "$CONTAINER_NAME" script -qec "bitbot --version" /dev/null 2>&1)

if echo "$output" | grep -qE "BitBot|version"; then
    test_pass "bitbot --version executed successfully"
else
    test_fail "bitbot --version failed or produced unexpected output"
    echo "Output: $output"
fi

# ============================================================================
# Test 4: Run bitbot --help (verify commands available)
# ============================================================================

echo ""
echo "[Test 4] Running 'bitbot --help' in container..."

output=$(docker exec "$CONTAINER_NAME" script -qec "bitbot --help" /dev/null 2>&1)

if echo "$output" | grep -qE "Usage:|Commands:"; then
    test_pass "bitbot --help shows usage information"
else
    test_fail "bitbot --help output unexpected"
fi

# Check for expected commands
if echo "$output" | grep -q "work"; then
    test_pass "'work' command listed in help"
else
    test_warning "'work' command not found in help (may not be available yet)"
fi

# ============================================================================
# Test 5: Check BitBot directory structure in container
# ============================================================================

echo ""
echo "[Test 5] Verifying BitBot directory structure in container..."

# Check for core directory
output=$(docker exec "$CONTAINER_NAME" script -qec "ls -la /usr/local/bitbot/core" /dev/null 2>&1)

if echo "$output" | grep -q "bitbot"; then
    test_pass "Core BitBot files present in container"
else
    test_fail "Core BitBot files not found"
fi

# Check for wrapper directory
output=$(docker exec "$CONTAINER_NAME" script -qec "ls -la /usr/local/bitbot/wrapper" /dev/null 2>&1)

if echo "$output" | grep -qE "claude-wrapper|wrapper"; then
    test_pass "Wrapper infrastructure present in container"
else
    test_warning "Wrapper infrastructure not found (may not be mounted)"
fi

# ============================================================================
# Test 6: Test command execution without interactive input
# ============================================================================

echo ""
echo "[Test 6] Testing non-interactive command execution..."

# Create a simple test script in container
docker exec "$CONTAINER_NAME" bash -c 'cat > /tmp/test-script.sh << "SCRIPT"
#!/usr/bin/env bash
echo "Test script executed successfully"
echo "Working directory: $(pwd)"
echo "BitBot location: $(which bitbot || echo "not found")"
SCRIPT
chmod +x /tmp/test-script.sh'

output=$(docker exec "$CONTAINER_NAME" script -qec "/tmp/test-script.sh" /dev/null 2>&1)

if echo "$output" | grep -q "Test script executed successfully"; then
    test_pass "Script execution successful in container"
else
    test_fail "Script execution failed"
fi

# ============================================================================
# Test 7: Verify environment variables
# ============================================================================

echo ""
echo "[Test 7] Verifying PATH and environment in container..."

output=$(docker exec "$CONTAINER_NAME" script -qec "echo \$PATH" /dev/null 2>&1)

if echo "$output" | grep -q "/usr/local/bitbot/core"; then
    test_pass "BitBot in PATH environment variable"
else
    test_fail "BitBot not in PATH environment variable"
fi

# ============================================================================
# Test 8: Test output capture with multi-line command
# ============================================================================

echo ""
echo "[Test 8] Testing multi-line output capture..."

output=$(docker exec "$CONTAINER_NAME" script -qec "printf 'Line 1\nLine 2\nLine 3\n'" /dev/null 2>&1)

line_count=$(echo "$output" | grep -c "Line" || echo "0")

if [[ "$line_count" -eq 3 ]]; then
    test_pass "Multi-line output captured correctly ($line_count lines)"
else
    test_warning "Multi-line output may have issues (captured $line_count lines, expected 3)"
fi

# ============================================================================
# Test 9: Test command with exit codes
# ============================================================================

echo ""
echo "[Test 9] Testing exit code handling..."

# Test successful command
if docker exec "$CONTAINER_NAME" script -qec "exit 0" /dev/null >/dev/null 2>&1; then
    test_pass "Successful command exit code handled correctly"
else
    test_fail "Successful command exit code incorrect"
fi

# Test failing command
if docker exec "$CONTAINER_NAME" script -qec "exit 1" /dev/null >/dev/null 2>&1; then
    test_fail "Failing command reported success (should fail)"
else
    test_pass "Failing command exit code handled correctly"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "========================================"
echo "Test Results Summary"
echo "========================================"
echo -e "${GREEN}Passed: $pass_count${NC}"
echo -e "${RED}Failed: $fail_count${NC}"
echo "========================================"
echo ""

if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
