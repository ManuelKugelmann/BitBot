#!/usr/bin/env bash
# claude-inspect-context-size.sh - Display current context usage and provide recommendations
#
# This script helps Claude understand and manage its context usage by:
# 1. Reading current context % from session env file
# 2. Displaying context status with color-coded warnings
# 3. Providing actionable recommendations based on context level
#
# Dependencies:
# - BitBot wrapper infrastructure (.bitbot/session-env/<session-id>.env)
# - ccstatusline or statusline-wrapper to populate session data
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

# Determine status and color
if [ "$CONTEXT_INT" -lt 50 ]; then
    STATUS="🟢 GOOD"
    COLOR="\033[32m"  # Green
    RECOMMENDATION="Context usage is healthy. Continue working normally."
elif [ "$CONTEXT_INT" -lt 70 ]; then
    STATUS="🟡 MODERATE"
    COLOR="\033[33m"  # Yellow
    RECOMMENDATION="Context usage is moderate. Consider compacting after completing current task."
elif [ "$CONTEXT_INT" -lt 85 ]; then
    STATUS="🟠 HIGH"
    COLOR="\033[33m"  # Yellow/Orange
    RECOMMENDATION="Context usage is high. Plan to compact soon to avoid context exhaustion."
else
    STATUS="🔴 CRITICAL"
    COLOR="\033[31m"  # Red
    RECOMMENDATION="Context usage is critical! Compact now or risk running out of context mid-task."
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

# Provide context management options
if [ "$CONTEXT_INT" -ge 70 ]; then
    echo "═══════════════════════════════════════════════════════════════"
    echo "Context Management Options:"
    echo ""
    echo "1. Compact now (recommended if at critical level):"
    echo "   Use: /claude-restart-compact skill"
    echo ""
    echo "2. Finish current task then compact:"
    echo "   Complete your work, then use /claude-restart-compact"
    echo ""
    echo "3. Manual compaction:"
    echo "   Type: /compact"
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
