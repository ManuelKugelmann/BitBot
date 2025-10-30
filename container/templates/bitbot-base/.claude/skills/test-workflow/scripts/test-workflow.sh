#!/usr/bin/env bash
# test-workflow.sh - BitBot standard test workflow
# Usage: test-workflow.sh <file>

set -euo pipefail

FILE="${1:-}"

if [[ -z "$FILE" ]]; then
    echo "Error: No file specified"
    echo "Usage: test-workflow.sh <file>"
    exit 1
fi

if [[ ! -f "$FILE" ]]; then
    echo "Error: File not found: $FILE"
    exit 1
fi

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              BitBot Test Workflow                             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "File: $FILE"
echo ""

# Step 1: Fix line endings and check syntax
echo "[1/2] Fix line endings + check syntax..."
if .claude/skills/fix-line-endings-check-bash/scripts/fix-line-endings-check-bash.sh "$FILE"; then
    echo "  ✓ Line endings fixed, syntax OK"
else
    echo "  ✗ Syntax errors found"
    echo ""
    echo "Next steps:"
    echo "  1. Review syntax errors above"
    echo "  2. Fix errors in $FILE"
    echo "  3. Re-run: test-workflow.sh $FILE"
    exit 1
fi

echo ""

# Step 2: Run tests if it's a test file
if [[ "$FILE" == *"/test-"* ]] || [[ "$FILE" == *"-test.sh" ]]; then
    echo "[2/2] Running tests with timeout..."
    if .claude/skills/run-with-timeout/scripts/run-with-timeout.sh 60 "$FILE"; then
        echo ""
        echo "✓ All tests passed!"
    else
        echo ""
        echo "✗ Tests failed or timed out"
        echo ""
        echo "Next steps:"
        echo "  1. Review test failures above"
        echo "  2. Fix failing tests"
        echo "  3. Re-run: test-workflow.sh $FILE"
        exit 1
    fi
else
    echo "[2/2] Not a test file, skipping test execution"
    echo "  (Test files should match: */test-* or *-test.sh)"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              Workflow Complete - Ready to Commit              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "File is ready:"
echo "  - Line endings: LF ✓"
echo "  - Syntax: Valid ✓"
if [[ "$FILE" == *"/test-"* ]] || [[ "$FILE" == *"-test.sh" ]]; then
    echo "  - Tests: Passing ✓"
fi
echo ""
echo "Next: Commit your changes"
echo "  git add $FILE"
echo "  git commit -m \"Your commit message\""
