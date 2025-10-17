#!/bin/bash
# Test Runner for BitBot
# Runs all test suites and provides summary

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL_PASSED=0
TOTAL_FAILED=0

echo "========================================"
echo "BitBot Test Runner"
echo "========================================"
echo ""

# Run main test suite
echo "Running main test suite..."
if bash "$SCRIPT_DIR/test-bitbot.sh"; then
    echo "✅ Main test suite PASSED"
    MAIN_RESULT="PASSED"
else
    echo "❌ Main test suite FAILED"
    MAIN_RESULT="FAILED"
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi
echo ""

# Run workflow test if requested
if [[ "$1" == "--with-workflow" || "$1" == "-w" ]]; then
    echo "Running workflow test..."
    if bash "$SCRIPT_DIR/test-workflow.sh"; then
        echo "✅ Workflow test PASSED"
        WORKFLOW_RESULT="PASSED"
    else
        echo "❌ Workflow test FAILED"
        WORKFLOW_RESULT="FAILED"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
    echo ""
fi

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo "Main Test Suite: $MAIN_RESULT"
if [[ -n "$WORKFLOW_RESULT" ]]; then
    echo "Workflow Test: $WORKFLOW_RESULT"
fi
echo ""

if [[ $TOTAL_FAILED -eq 0 ]]; then
    echo "🎉 All tests PASSED!"
    echo ""
    echo "BitBot is ready for use. You can:"
    echo "  • Run './global/bitbot' in any project directory"
    echo "  • Use './global/start-mcp.sh' to start MCP services"
    echo "  • Test with './tests/test-workflow.sh' for full validation"
    exit 0
else
    echo "💥 Some tests FAILED!"
    echo ""
    echo "Please review the output above and fix any issues."
    exit 1
fi