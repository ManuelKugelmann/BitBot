#!/bin/bash
#
# Test script for bitbot.exe launcher
# Runs various test cases and verifies behavior
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================"
echo "Testing BitBot Windows Launcher"
echo "========================================"
echo

# Check if launcher.exe exists
if [ ! -f "launcher.exe" ]; then
    echo "✗ launcher.exe not found. Run build.sh first."
    exit 1
fi

# Check if launcher.cmd exists
if [ ! -f "launcher.cmd" ]; then
    echo "✗ launcher.cmd not found"
    exit 1
fi

# Test 1: No arguments
echo "Test 1: No arguments"
echo "─────────────────────────────────────"
OUTPUT=$(cmd.exe /c launcher.exe 2>&1)
echo "$OUTPUT"

if echo "$OUTPUT" | grep -q "No arguments provided"; then
    echo "✓ Test 1 passed"
else
    echo "✗ Test 1 failed: Expected 'No arguments provided'"
    exit 1
fi
echo

# Test 2: With arguments
echo "Test 2: With arguments (test arg1 arg2 --flag)"
echo "─────────────────────────────────────"
OUTPUT=$(cmd.exe /c "launcher.exe test arg1 arg2 --flag" 2>&1)
echo "$OUTPUT"

if echo "$OUTPUT" | grep -q "test" && \
   echo "$OUTPUT" | grep -q "arg1" && \
   echo "$OUTPUT" | grep -q "arg2" && \
   echo "$OUTPUT" | grep -qF -- "--flag"; then
    echo "✓ Test 2 passed"
else
    echo "✗ Test 2 failed: Arguments not passed correctly"
    exit 1
fi
echo

# Test 3: Exit code
echo "Test 3: Exit code propagation"
echo "─────────────────────────────────────"
cmd.exe /c launcher.exe > /dev/null 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ Test 3 passed (exit code: $EXIT_CODE)"
else
    echo "✗ Test 3 failed: Expected exit code 0, got $EXIT_CODE"
    exit 1
fi
echo

echo "========================================"
echo "✓ All tests passed!"
echo "========================================"
