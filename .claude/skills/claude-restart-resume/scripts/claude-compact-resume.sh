#!/usr/bin/env bash
# claude-compact-resume.sh - Compact context and resume session
# Usage: claude-compact-resume.sh <session-id> [compaction-prompt]
#
# Supports custom compaction prompts to guide what context to preserve.
#
# Environment variables:
#   COMPACT_PROMPT - Custom prompt to guide compaction (optional)
#
# Example:
#   export COMPACT_PROMPT="Preserve TODO state and architectural decisions"
#   claude-compact-resume.sh abc123

set -euo pipefail

SESSION_ID="${1:-}"
CUSTOM_PROMPT="${2:-${COMPACT_PROMPT:-}}"

if [[ -z "$SESSION_ID" ]]; then
    echo "Error: Session ID required"
    echo "Usage: claude-compact-resume.sh <session-id> [prompt]"
    exit 1
fi

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           Compacting Context at Natural Breakpoint           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Session ID: $SESSION_ID"

if [[ -n "$CUSTOM_PROMPT" ]]; then
    echo "Compaction Guidance: $CUSTOM_PROMPT"
else
    echo "Compaction Guidance: (default)"
fi

echo ""
echo "This will:"
echo "  1. Summarize recent conversation"
echo "  2. Free up tokens for continued work"
echo "  3. Preserve task context and state"
echo "  4. Resume with compact history"
echo ""

# Build claude command with compaction
if [[ -n "$CUSTOM_PROMPT" ]]; then
    # Resume with custom compaction prompt passed as argument
    echo "Executing: claude --resume $SESSION_ID --compact \"$CUSTOM_PROMPT\""
    echo ""

    exec claude --resume "$SESSION_ID" --compact "$CUSTOM_PROMPT"
else
    # Standard compact+resume
    echo "Executing: claude --resume $SESSION_ID --compact"
    echo ""

    exec claude --resume "$SESSION_ID" --compact
fi
