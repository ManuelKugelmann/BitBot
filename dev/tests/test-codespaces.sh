#!/usr/bin/env bash
#
# GitHub Codespaces Quick Test
# Tests BitBot functionality that works in Codespaces (without Docker-in-Docker)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

pass_count=0
fail_count=0
skip_count=0

echo ""
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  BitBot Codespaces Quick Test         ║${NC}"
echo -e "${CYAN}║  (Tests container bitbot scripts)     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}ℹ Note: Codespaces already runs .devcontainer${NC}"
echo -e "${BLUE}  This test validates container/bitbot scripts${NC}"
echo ""

test_pass() {
    echo -e "${GREEN}✓${NC} $1"
    pass_count=$((pass_count + 1))
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
    fail_count=$((fail_count + 1))
}

test_skip() {
    echo -e "${YELLOW}⊘${NC} $1"
    skip_count=$((skip_count + 1))
}

# Detect if running in Codespaces
if [[ -n "${CODESPACES:-}" ]] || [[ -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]]; then
    echo -e "${BLUE}ℹ Running in GitHub Codespaces${NC}"
    IN_CODESPACES=true
else
    echo -e "${YELLOW}⚠ Not running in Codespaces (testing locally)${NC}"
    IN_CODESPACES=false
fi
echo ""

# Test 1: Environment Detection
echo -e "${BLUE}═══ Test 1: Environment ═══${NC}"
echo ""

if [[ "$IN_CODESPACES" == true ]]; then
    test_pass "Detected GitHub Codespaces environment"
else
    test_skip "Not in Codespaces (local environment)"
fi

if [[ -d "$BITBOT_ROOT/.devcontainer" ]]; then
    test_pass "DevContainer config exists"
else
    test_fail "DevContainer config missing"
fi

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    test_pass "Node.js installed: $NODE_VERSION"
else
    test_fail "Node.js not found"
fi

echo ""

# Test 2: BitBot CLI
echo -e "${BLUE}═══ Test 2: BitBot CLI ═══${NC}"
echo ""

if [[ -f "$BITBOT_ROOT/bitbot" ]]; then
    test_pass "BitBot launcher exists"
else
    test_fail "BitBot launcher not found"
fi

if [[ -x "$BITBOT_ROOT/bitbot" ]]; then
    test_pass "BitBot launcher is executable"
else
    test_fail "BitBot launcher not executable"
fi

if timeout 5 "$BITBOT_ROOT/bitbot" --version &> /tmp/bitbot-version.txt; then
    VERSION=$(head -1 /tmp/bitbot-version.txt)
    test_pass "BitBot version: $VERSION"
else
    test_fail "BitBot --version failed or timed out"
fi

if timeout 5 "$BITBOT_ROOT/bitbot" help &> /dev/null; then
    test_pass "BitBot help command works"
else
    test_fail "BitBot help command failed or timed out"
fi

echo ""

# Test 3: Docker Availability
echo -e "${BLUE}═══ Test 3: Docker (Limited in Codespaces) ═══${NC}"
echo ""

if command -v docker &> /dev/null; then
    test_pass "Docker CLI installed"

    if docker info &> /dev/null; then
        test_pass "Docker daemon accessible"
    else
        test_skip "Docker daemon not accessible (expected in Codespaces)"
    fi
else
    test_skip "Docker not available (expected in Codespaces)"
fi

if [[ -S /var/run/docker.sock ]]; then
    test_pass "Docker socket exists"
else
    test_skip "Docker socket not available (expected in Codespaces)"
fi

echo ""

# Test 4: Container BitBot Scripts
echo -e "${BLUE}═══ Test 4: Container BitBot Scripts ═══${NC}"
echo ""

CONTAINER_BITBOT="$BITBOT_ROOT/container/bitbot"

if [[ -f "$CONTAINER_BITBOT/bitbot" ]]; then
    test_pass "Container bitbot launcher exists"
else
    test_fail "Container bitbot launcher missing"
fi

if [[ -x "$CONTAINER_BITBOT/bitbot" ]]; then
    test_pass "Container bitbot is executable"
else
    test_fail "Container bitbot not executable"
fi

if "$CONTAINER_BITBOT/bitbot" help &> /dev/null; then
    test_pass "Container bitbot help works"
else
    test_fail "Container bitbot help failed"
fi

# Test container commands
for cmd in analyze configure status; do
    if [[ -x "$CONTAINER_BITBOT/core/commands/${cmd}.sh" ]]; then
        test_pass "Container command ${cmd}.sh is executable"
    else
        test_fail "Container command ${cmd}.sh not executable"
    fi
done

echo ""

# Test 5: Run Subset of Test Suite
echo -e "${BLUE}═══ Test 5: Quick Unit Tests ═══${NC}"
echo ""

# Run tests that don't require Docker
if [[ -x "$SCRIPT_DIR/test-bitbot-commands.sh" ]]; then
    if "$SCRIPT_DIR/test-bitbot-commands.sh" &> /dev/null; then
        test_pass "BitBot commands test passed"
    else
        test_fail "BitBot commands test failed"
    fi
else
    test_skip "BitBot commands test not found"
fi

if [[ -x "$SCRIPT_DIR/test-platform-detection.sh" ]]; then
    if "$SCRIPT_DIR/test-platform-detection.sh" &> /dev/null; then
        test_pass "Platform detection test passed"
    else
        test_fail "Platform detection test failed"
    fi
else
    test_skip "Platform detection test not found"
fi

if [[ -x "$SCRIPT_DIR/test-container-bitbot.sh" ]]; then
    if "$SCRIPT_DIR/test-container-bitbot.sh" &> /dev/null; then
        test_pass "Container BitBot test passed"
    else
        test_fail "Container BitBot test failed"
    fi
else
    test_skip "Container BitBot test not found"
fi

echo ""

# Test 6: Claude Code (if available)
echo -e "${BLUE}═══ Test 6: Claude Code Integration ═══${NC}"
echo ""

if command -v claude-code &> /dev/null; then
    test_pass "Claude Code CLI installed"
elif command -v claude &> /dev/null; then
    test_pass "Claude CLI installed"
else
    test_skip "Claude Code not installed"
fi

if [[ -d "$HOME/.claude" ]]; then
    test_pass "Claude config directory exists"
else
    test_skip "Claude config directory not found"
fi

echo ""

# Summary
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          Test Summary                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Passed:  ${GREEN}$pass_count${NC}"
echo -e "  Failed:  ${RED}$fail_count${NC}"
echo -e "  Skipped: ${YELLOW}$skip_count${NC}"
echo ""

if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  BitBot works in Codespaces! ✓        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""

    if [[ "$IN_CODESPACES" == true ]]; then
        echo -e "${YELLOW}Note: Some features require Docker-in-Docker:${NC}"
        echo "  • bitbot work (start work container)"
        echo "  • bitbot config (start config container)"
        echo "  • Full integration tests"
        echo ""
        echo "These are tested in GitHub Actions CI."
    fi

    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  Some tests failed ✗                  ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi
