#!/bin/bash
# Demo: AI Helper Integration in BitBot Error Handlers
#
# This shows how to add AI-powered help to BitBot commands
# for absolute beginners with zero setup.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "=== BitBot AI Helper Demo ==="
echo ""

# Test 1: Direct AI query
echo "Test 1: Direct AI query"
echo "------------------------"
node "$BITBOT_ROOT/core/util/ai-helper/ai-helper.js" \
    "Docker installation" \
    "How do I install Docker on Windows?"
echo ""
echo ""

# Test 2: Using bash wrapper
echo "Test 2: Using bash wrapper"
echo "--------------------------"
export BITBOT_HOME="$BITBOT_ROOT"
source "$BITBOT_ROOT/core/util/ai-helper/ai-helper.sh"
ask_ai "WSL setup" "How do I enable WSL on Windows?"
echo ""
echo ""

# Test 3: Error handler integration example
echo "Test 3: Error Handler Example"
echo "------------------------------"
echo "Simulating Docker error..."
echo ""

# Example error handler (how it would look in bitbot commands)
check_docker_example() {
    if ! command -v docker &>/dev/null; then
        echo "✗ Docker not found"

        # AI-powered suggestion
        echo ""
        echo "💡 AI Assistant:"
        ask_ai "Docker not installed" "How to install Docker Desktop on Windows for beginners?"
        echo ""

        echo "Would you like to:"
        echo "  [1] Continue anyway"
        echo "  [2] Exit and install Docker"
        echo ""
        return 1
    fi

    echo "✓ Docker found"
}

check_docker_example || true
echo ""
echo ""

# Test 4: Rate limit fallback
echo "Test 4: Fallback Help (simulated rate limit)"
echo "---------------------------------------------"
# The helper automatically falls back to curated help if AI is rate-limited
ask_ai "devcontainer" "How do I set up DevContainers?"
echo ""
echo ""

echo "=== Demo Complete ==="
echo ""
echo "Key features:"
echo "  ✓ Zero setup - works immediately"
echo "  ✓ Tries free AI APIs first"
echo "  ✓ Falls back to curated help"
echo "  ✓ Perfect for absolute beginners"
echo ""
echo "Next steps:"
echo "  1. Integrate into core/global/first-run.sh"
echo "  2. Add to all error handlers"
echo "  3. Include Node.js in Alpine containers"
