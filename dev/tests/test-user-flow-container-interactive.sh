#!/usr/bin/env bash
#
# Test: BitBot User Flow - Interactive Container Tests
# Tests interactive prompts and wizards inside containers using expect
#
# Usage:
#   test-user-flow-container-interactive.sh [--no-cleanup]
#
# Options:
#   --no-cleanup: Skip cleanup (leave container/workspace for inspection)
#
# Requirements:
#   - Docker running
#   - expect installed

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
            echo "Usage: test-user-flow-container-interactive.sh [--no-cleanup]"
            exit 1
            ;;
    esac
done

# Test environment
TEST_ENV="/tmp/bitbot-test-interactive-$$"
WORKSPACE_DIR="$TEST_ENV/workspace"
CONTAINER_NAME="bitbot-test-interactive-$$"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"



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
echo "=== BitBot User Flow: Interactive Container Test (Expect) ==="
echo ""
echo "This test verifies interactive prompts work inside containers"
echo "using expect for automation (better than tmux for complex interactions)."
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

if ! command -v expect &> /dev/null; then
    echo -e "${RED}✗ FAIL${NC}: expect not found"
    echo ""
    echo "Install expect:"
    echo "  Ubuntu/Debian: sudo apt-get install expect"
    echo "  macOS:         brew install expect"
    echo "  Alpine:        apk add expect"
    exit 1
fi

test_pass "expect available"

# ============================================================================
# Setup: Create minimal test workspace
# ============================================================================

echo ""
echo "[Setup] Creating test workspace..."

mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# Create minimal devcontainer configuration
mkdir -p .devcontainer

cat > .devcontainer/Dockerfile <<'EOF'
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
EOF

test_pass "Test workspace created"

# ============================================================================
# Setup: Build and start container
# ============================================================================

echo ""
echo "[Setup] Building and starting container..."

test_info "Building container image..."
if docker build -t "$CONTAINER_NAME-image" .devcontainer/ >/dev/null 2>&1; then
    test_pass "Container image built"
else
    test_fail "Container image build failed"
    exit 1
fi

test_info "Starting container..."
if docker run -d \
    --name "$CONTAINER_NAME" \
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
# Run Expect Tests
# ============================================================================

echo ""
echo "[Expect Tests] Running interactive tests in container..."
echo ""

# Run the expect script
EXPECT_SCRIPT="$SCRIPT_DIR/test-user-flow-container-interactive.exp"

if [[ ! -f "$EXPECT_SCRIPT" ]]; then
    echo -e "${RED}✗ FAIL${NC}: Expect script not found: $EXPECT_SCRIPT"
    exit 1
fi

# Run expect script and capture results
if expect "$EXPECT_SCRIPT" "$CONTAINER_NAME"; then
    echo ""
    test_pass "All expect tests passed"
    exit_code=0
else
    echo ""
    test_fail "Some expect tests failed"
    exit_code=1
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "========================================"
echo "Interactive Container Test Complete"
echo "========================================"
echo ""

if [[ $exit_code -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
else
    echo -e "${RED}✗ Some tests failed${NC}"
fi

echo ""

exit $exit_code
