#!/usr/bin/env bash
#
# Test: BitBot User Flow - Interactive Container Tests
# Tests interactive prompts and wizards inside containers using tmux
#
# Usage:
#   test-user-flow-container-interactive.sh [--no-cleanup]
#
# Options:
#   --no-cleanup: Skip cleanup (leave container/workspace for inspection)
#
# Requirements:
#   - Docker running
#   - tmux installed

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
SESSION_NAME="bitbot-test-interactive-$$"

# Source test framework and tmux helper
source "${SCRIPT_DIR}/helpers/test-framework.sh"
source "${SCRIPT_DIR}/helpers/tmux-test-helper.sh"

# Cleanup function
cleanup() {
    if [[ "$SKIP_CLEANUP" == "true" ]]; then
        echo ""
        echo -e "${YELLOW}⚠ WARN${NC}: Cleanup skipped (--no-cleanup flag)"
        echo -e "  Container and workspace left for inspection"
        echo -e "  Remember to clean up manually:"
        echo -e "    tmux kill-session -t $SESSION_NAME 2>/dev/null || true"
        echo -e "    docker stop $CONTAINER_NAME 2>/dev/null || true"
        echo -e "    docker rm $CONTAINER_NAME 2>/dev/null || true"
        echo -e "    rm -rf $TEST_ENV"
        echo ""
        return
    fi

    echo ""
    echo "Cleaning up test environment..."

    # Kill tmux session
    tmux_test_kill "$SESSION_NAME"

    # Stop container
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true

    # Remove test directory
    if [[ -d "$TEST_ENV" ]]; then
        rm -rf "$TEST_ENV"
    fi
}

trap cleanup EXIT

test_suite_begin "BitBot User Flow: Interactive Container Test (Tmux)"

echo ""
echo "This test verifies interactive prompts work inside containers"
echo "using tmux for automation."
echo ""

# ============================================================================
# Prerequisites Check
# ============================================================================

test_section "Prerequisites Check"

if ! command -v docker &> /dev/null; then
    test_fail "Docker not found"
    exit 1
fi

if ! docker info &> /dev/null; then
    test_fail "Docker not running"
    exit 1
fi

test_pass "Docker available and running"

if ! command -v tmux &> /dev/null; then
    test_fail "tmux not found (required for interactive testing)"
    echo ""
    echo "Install tmux:"
    echo "  Ubuntu/Debian: sudo apt-get install tmux"
    echo "  macOS:         brew install tmux"
    echo "  Alpine:        apk add tmux"
    exit 1
fi

test_pass "tmux available"

# ============================================================================
# Setup: Create minimal test workspace
# ============================================================================

test_section "Setup Test Workspace"

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

test_section "Build and Start Container"

if docker build -t "$CONTAINER_NAME-image" .devcontainer/ >/dev/null 2>&1; then
    test_pass "Container image built"
else
    test_fail "Container image build failed"
    exit 1
fi

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
sleep 1

# ============================================================================
# Test 1: Interactive prompt - Yes/No question
# ============================================================================

test_section "Test 1: Yes/No Prompt"

tmux_test_start "$SESSION_NAME" "docker exec -it $CONTAINER_NAME bash"
sleep 0.5

tmux_test_send_keys "$SESSION_NAME" "read -p 'Continue? (y/n): ' answer && echo \"You answered: \$answer\""
tmux_test_send_enter "$SESSION_NAME"

if tmux_test_wait_for "$SESSION_NAME" "Continue?" 5; then
    test_pass "Prompt displayed"

    tmux_test_send_keys "$SESSION_NAME" "y"
    tmux_test_send_enter "$SESSION_NAME"

    if tmux_test_wait_for "$SESSION_NAME" "You answered: y" 3; then
        test_pass "Input processed correctly"
    else
        test_fail "Answer not processed"
    fi
else
    test_fail "Prompt not displayed"
fi

# ============================================================================
# Test 2: Interactive prompt - Number selection
# ============================================================================

test_section "Test 2: Number Selection Prompt"

tmux_test_send_keys "$SESSION_NAME" "echo 'Select an option:' && echo '[1] Option One' && echo '[2] Option Two' && echo '[3] Option Three' && read -p 'Enter choice (1-3): ' choice && echo \"You selected: \$choice\""
tmux_test_send_enter "$SESSION_NAME"

if tmux_test_wait_for "$SESSION_NAME" "Select an option:" 3; then
    test_pass "Menu displayed"

    if tmux_test_wait_for "$SESSION_NAME" "Option One" 2; then
        test_pass "Options listed"
    fi

    if tmux_test_wait_for "$SESSION_NAME" "Enter choice" 2; then
        test_pass "Selection prompt shown"

        tmux_test_send_keys "$SESSION_NAME" "2"
        tmux_test_send_enter "$SESSION_NAME"

        if tmux_test_wait_for "$SESSION_NAME" "You selected: 2" 3; then
            test_pass "Selection processed correctly"
        else
            test_fail "Selection not processed"
        fi
    else
        test_fail "Selection prompt not shown"
    fi
else
    test_fail "Menu not displayed"
fi

# ============================================================================
# Test 3: Multi-step wizard flow
# ============================================================================

test_section "Test 3: Multi-Step Wizard Flow"

# Create wizard script in container
tmux_test_send_keys "$SESSION_NAME" "cat > /tmp/wizard.sh <<'WIZARD'
echo '=== Setup Wizard ==='
echo ''
read -p 'Step 1 - Enter name: ' name
echo \"Hello, \$name!\"
echo ''
read -p 'Step 2 - Select mode (dev/prod): ' mode
echo \"Mode: \$mode\"
echo ''
read -p 'Step 3 - Confirm (y/n): ' confirm
if [ \"\$confirm\" = 'y' ]; then
    echo 'Setup complete!'
else
    echo 'Setup cancelled'
fi
WIZARD"
tmux_test_send_enter "$SESSION_NAME"
sleep 0.5

tmux_test_send_keys "$SESSION_NAME" "bash /tmp/wizard.sh"
tmux_test_send_enter "$SESSION_NAME"

if tmux_test_wait_for "$SESSION_NAME" "Setup Wizard" 3; then
    test_pass "Wizard started"

    if tmux_test_wait_for "$SESSION_NAME" "Step 1 - Enter name:" 2; then
        test_pass "Step 1 prompt shown"

        tmux_test_send_keys "$SESSION_NAME" "TestUser"
        tmux_test_send_enter "$SESSION_NAME"

        if tmux_test_wait_for "$SESSION_NAME" "Hello, TestUser!" 3; then
            test_pass "Step 1 input processed"

            if tmux_test_wait_for "$SESSION_NAME" "Step 2 - Select mode" 2; then
                test_pass "Step 2 prompt shown"

                tmux_test_send_keys "$SESSION_NAME" "dev"
                tmux_test_send_enter "$SESSION_NAME"

                if tmux_test_wait_for "$SESSION_NAME" "Mode: dev" 3; then
                    test_pass "Step 2 input processed"

                    if tmux_test_wait_for "$SESSION_NAME" "Step 3 - Confirm" 2; then
                        test_pass "Step 3 prompt shown"

                        tmux_test_send_keys "$SESSION_NAME" "y"
                        tmux_test_send_enter "$SESSION_NAME"

                        if tmux_test_wait_for "$SESSION_NAME" "Setup complete!" 3; then
                            test_pass "Wizard completed successfully"
                        else
                            test_fail "Wizard completion message not shown"
                        fi
                    else
                        test_fail "Step 3 prompt not shown"
                    fi
                else
                    test_fail "Step 2 not processed"
                fi
            else
                test_fail "Step 2 prompt not shown"
            fi
        else
            test_fail "Step 1 not processed"
        fi
    else
        test_fail "Step 1 prompt not shown"
    fi
else
    test_fail "Wizard not started"
fi

# ============================================================================
# Test 4: Pattern matching in output
# ============================================================================

test_section "Test 4: Pattern Matching"

tmux_test_send_keys "$SESSION_NAME" "echo 'Checking BitBot version...' && echo 'BitBot version: 1.0.0-test' && echo 'Install location: /usr/local/bitbot'"
tmux_test_send_enter "$SESSION_NAME"

if tmux_test_wait_for "$SESSION_NAME" "version: 1.0.0-test" 3; then
    test_pass "Version pattern matched"
else
    test_fail "Version pattern not found"
fi

if tmux_test_wait_for "$SESSION_NAME" "location: /usr/local/bitbot" 2; then
    test_pass "Location pattern matched"
else
    test_fail "Location pattern not found"
fi

# ============================================================================
# Test 5: Quick Response Test
# ============================================================================

test_section "Test 5: Quick Response Test"

tmux_test_send_keys "$SESSION_NAME" "read -p 'Quick prompt: ' answer && echo \"Got: \$answer\""
tmux_test_send_enter "$SESSION_NAME"

if tmux_test_wait_for "$SESSION_NAME" "Quick prompt:" 3; then
    test_pass "Quick prompt shown"

    tmux_test_send_keys "$SESSION_NAME" "fast"
    tmux_test_send_enter "$SESSION_NAME"

    if tmux_test_wait_for "$SESSION_NAME" "Got: fast" 3; then
        test_pass "Quick response processed"
    else
        test_fail "Quick response not processed"
    fi
else
    test_fail "Quick prompt not shown"
fi

# ============================================================================
# Cleanup session
# ============================================================================

tmux_test_send_keys "$SESSION_NAME" "exit"
tmux_test_send_enter "$SESSION_NAME"

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
