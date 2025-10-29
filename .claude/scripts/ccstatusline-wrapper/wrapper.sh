#!/usr/bin/env bash
# ccstatusline-wrapper.sh - Extract context % and pass through to ccstatusline
#
# This wrapper:
# 1. Receives JSON from Claude Code via stdin
# 2. Extracts context_percentage
# 3. Updates CLAUDE_CONTEXT_PCT in $CLAUDE_ENV_FILE
# 4. Passes JSON through to ccstatusline
#
# Usage in .claude/settings.json:
# {
#   "statusLine": {
#     "type": "command",
#     "command": ".claude/scripts/ccstatusline-wrapper/wrapper.sh"
#   }
# }

set -euo pipefail

# Read JSON from stdin
JSON_DATA=$(cat)

# Extract context percentage (pure bash - no external tools needed)
# Match: "context_percentage":XX.XX
if [[ "$JSON_DATA" =~ \"context_percentage\":([0-9.]+) ]]; then
    CONTEXT_PCT="${BASH_REMATCH[1]}"
else
    CONTEXT_PCT="0"
fi

# Update env file (fast - single sed + append)
if [ -n "${CLAUDE_ENV_FILE:-}" ] && [ -n "$CONTEXT_PCT" ]; then
    sed -i '/^export CLAUDE_CONTEXT_PCT=/d' "$CLAUDE_ENV_FILE" 2>/dev/null || true
    echo "export CLAUDE_CONTEXT_PCT='$CONTEXT_PCT'" >> "$CLAUDE_ENV_FILE"
fi

# Pass through to ccstatusline
if command -v ccstatusline &>/dev/null; then
    echo "$JSON_DATA" | ccstatusline
else
    # Simple fallback
    echo "[Claude] Context: ${CONTEXT_PCT}%"
fi
