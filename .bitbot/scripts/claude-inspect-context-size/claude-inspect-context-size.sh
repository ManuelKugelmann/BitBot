#!/usr/bin/env bash
# claude-inspect-context-size.sh - Intelligent context management advisor
#
# This script helps Claude make intelligent decisions about context compaction by:
# 1. Reading current context % from session env file
# 2. Analyzing work state and identifying natural break points
# 3. Providing strategic recommendations for work continuation optimization
# 4. Generating compaction prompts that preserve critical context
#
# Philosophy: Context management is about work continuation, not just thresholds.
# Compact at natural break points with clear instructions for resumption.
#
# Dependencies:
# - BitBot wrapper infrastructure (.bitbot/session-env/<session-id>.env)
# - statusline-wrapper to populate session data
#
# Usage:
#   claude-inspect-context-size.sh

set -euo pipefail

# Find project root
find_project_root() {
    local dir="$PWD"
    local max_depth=10
    local depth=0

    while [ $depth -lt $max_depth ]; do
        if [ -d "$dir/.bitbot" ]; then
            echo "$dir"
            return 0
        fi
        if [ "$dir" = "/" ]; then
            break
        fi
        dir="$(dirname "$dir")"
        depth=$((depth + 1))
    done

    echo "$PWD"
    return 1
}

PROJECT_ROOT=$(find_project_root)

# Source session environment if available
if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
    ENV_FILE="$PROJECT_ROOT/.bitbot/session-env/${CLAUDE_SESSION_ID}.env"
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
    else
        echo "❌ Error: Session env file not found: $ENV_FILE"
        echo ""
        echo "This skill requires BitBot wrapper infrastructure."
        echo "Ensure statusline-wrapper is configured in .claude/settings.json"
        exit 1
    fi
else
    echo "❌ Error: CLAUDE_SESSION_ID not set"
    echo ""
    echo "This skill requires BitBot infrastructure."
    echo "Run from a BitBot container with sessionStart hook enabled."
    exit 1
fi

# Get context percentage (default to 0 if not set)
CONTEXT_PCT="${CLAUDE_CONTEXT_PCT:-0}"

# Convert to integer for comparison
CONTEXT_INT=$(printf "%.0f" "$CONTEXT_PCT")

# Determine status and provide intelligent recommendations
if [ "$CONTEXT_INT" -lt 50 ]; then
    STATUS="🟢 HEALTHY"
    COLOR="\033[32m"  # Green
    RECOMMENDATION="Context usage is healthy. Continue working normally.

Look for natural break points to compact:
- After completing a major feature or fix
- After test suite passes
- After documentation updates
- Before starting a new complex task"

elif [ "$CONTEXT_INT" -lt 70 ]; then
    STATUS="🟡 MODERATE"
    COLOR="\033[33m"  # Yellow
    RECOMMENDATION="Context usage is moderate. Plan for compaction at next break point.

GOOD break points:
✓ Tests passing + code committed
✓ Feature complete + documented
✓ Bug fixed + verified
✓ Before starting new implementation phase

BAD break points:
✗ Mid-implementation
✗ Tests failing
✗ Debugging in progress
✗ Uncommitted changes"

elif [ "$CONTEXT_INT" -lt 85 ]; then
    STATUS="🟠 HIGH"
    COLOR="\033[33m"  # Yellow/Orange
    RECOMMENDATION="Context usage is high. Prioritize finding a break point soon.

Strategy:
1. Complete current atomic task (fix, feature, test)
2. Commit working code
3. Prepare continuation instructions
4. Compact with detailed resumption prompt

If context approaching 90%:
- Stop current work at safe point
- Commit what's working
- Compact NOW with clear next steps"

else
    STATUS="🔴 CRITICAL"
    COLOR="\033[31m"  # Red
    RECOMMENDATION="Context CRITICAL! Find immediate break point or compact NOW.

IMMEDIATE ACTION:
1. If tests passing: Commit + compact with continuation plan
2. If mid-work: Save state, commit WIP, compact with recovery instructions
3. If debugging: Note current hypothesis, compact with debug context

DO NOT:
- Start new complex tasks
- Continue without compaction plan
- Risk context exhaustion mid-critical-work"

fi

RESET="\033[0m"

# Display context information
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              Context Usage Report                             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
printf "${COLOR}Status:${RESET}      %s\n" "$STATUS"
printf "${COLOR}Context:${RESET}     %.1f%%\n" "$CONTEXT_PCT"
echo "Session:     $CLAUDE_SESSION_ID"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "Recommendation:"
echo ""
echo "$RECOMMENDATION"
echo ""

# Provide intelligent compaction guidance
if [ "$CONTEXT_INT" -ge 60 ]; then
    echo "═══════════════════════════════════════════════════════════════"
    echo "Compaction Strategy:"
    echo ""
    echo "Effective compaction requires work continuation instructions."
    echo "Instead of just running /compact, provide context about:"
    echo ""
    echo "  • What was just completed"
    echo "  • What remains to be done"
    echo "  • Critical decisions or findings"
    echo "  • Next specific steps"
    echo ""
    echo "Example compaction prompts:"
    echo ""
    echo "  /compact Completed user auth feature (tests passing, committed)."
    echo "           Next: Implement password reset flow. Start with email"
    echo "           template design, then backend endpoint."
    echo ""
    echo "  /compact Fixed bug in data parser (root cause: null handling)."
    echo "           Next: Add comprehensive null safety tests across parser"
    echo "           module. Check edge cases in spec doc."
    echo ""
    echo "  /compact Implemented 3/5 API endpoints. Remaining: DELETE user,"
    echo "           PATCH profile. All endpoints follow RESTful pattern in"
    echo "           routes.js. Auth middleware tested and working."
    echo ""
fi

# Provide advanced options
if [ "$CONTEXT_INT" -ge 70 ]; then
    echo "═══════════════════════════════════════════════════════════════"
    echo "Compaction Tools:"
    echo ""
    echo "1. With continuation prompt (RECOMMENDED):"
    echo "   /compact <brief summary of state + next steps>"
    echo ""
    echo "2. Via skill (for programmatic compaction):"
    echo "   /claude-restart-compact"
    echo ""
    echo "3. Pipe command (from scripts):"
    echo "   echo 'compact \$CLAUDE_SESSION_ID <prompt>' > \$WRAPPER_PIPE"
    echo ""
fi

# Show available wrapper commands if wrapper is active
if [ -n "${WRAPPER_PIPE:-}" ] && [ -p "$WRAPPER_PIPE" ]; then
    echo "═══════════════════════════════════════════════════════════════"
    echo "Available Wrapper Commands:"
    echo ""
    echo "  - compact: Compact context and resume"
    echo "  - restart: Restart without compaction"
    echo "  - clear:   Fresh start (loses history)"
    echo ""
    echo "Skills can send commands via: echo 'command \$CLAUDE_SESSION_ID' > \$WRAPPER_PIPE"
    echo ""
fi

exit 0
