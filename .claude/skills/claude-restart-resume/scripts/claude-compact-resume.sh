#!/usr/bin/env bash
# claude-compact-resume.sh - Trigger compact restart via wrapper
# Usage: claude-compact-resume.sh <session-id>
#
# Supports custom compaction prompts to guide what context to preserve.
#
# Environment variables:
#   COMPACT_PROMPT - Custom prompt to guide compaction (optional)
#
# This script sends "compact" command to wrapper, which will:
# 1. Kill current Claude
# 2. Run compaction with optional prompt
# 3. Resume the session

set -euo pipefail

SESSION_ID="${1:-}"
CUSTOM_PROMPT="${COMPACT_PROMPT:-}"

if [[ -z "$SESSION_ID" ]]; then
    echo "Error: Session ID required"
    echo "Usage: claude-compact-resume.sh <session-id>"
    exit 1
fi

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           Compacting Context at Natural Breakpoint           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Session ID: $SESSION_ID"

if [[ -n "$CUSTOM_PROMPT" ]]; then
    echo "Compaction Guidance: $CUSTOM_PROMPT"
    echo ""
    echo "Wrapper will:"
    echo "  1. Kill current Claude"
    echo "  2. Run: /compact $CUSTOM_PROMPT"
    echo "  3. Resume with compact history"
else
    echo "Compaction Guidance: (default)"
    echo ""
    echo "Wrapper will:"
    echo "  1. Kill current Claude"
    echo "  2. Run: /compact"
    echo "  3. Resume with compact history"
fi

echo ""
echo "Sending compact command to wrapper..."

# Send compact command to wrapper
# Wrapper is in /opt/bitbot/wrapper/ when running in container
SEND_CMD="/opt/bitbot/wrapper/send-wrapper-command.sh"

if [[ -f "$SEND_CMD" ]]; then
    # Send compact command with session ID and optional prompt
    if [[ -n "$CUSTOM_PROMPT" ]]; then
        exec "$SEND_CMD" compact "$SESSION_ID" "$CUSTOM_PROMPT"
    else
        exec "$SEND_CMD" compact "$SESSION_ID"
    fi
else
    echo "Error: Wrapper not found at $SEND_CMD"
    echo "Are you running inside BitBot container?"
    exit 1
fi
