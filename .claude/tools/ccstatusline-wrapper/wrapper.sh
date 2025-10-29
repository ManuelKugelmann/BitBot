#!/usr/bin/env bash
# ccstatusline-wrapper.sh - Intercept and store token usage from Claude Code
#
# This wrapper:
# 1. Receives JSON from Claude Code via stdin (same as ccstatusline)
# 2. Extracts token usage, context %, model info
# 3. Stores data in session-specific file
# 4. Passes JSON through to actual ccstatusline
#
# Usage in .claude/settings.json:
# {
#   "statusLine": {
#     "type": "command",
#     "command": ".claude/tools/ccstatusline-wrapper/wrapper.sh"
#   }
# }

set -euo pipefail

# Read JSON from stdin
JSON_DATA=$(cat)

# Storage location for session data
SESSION_DATA_DIR="${CLAUDE_PROJECT_DIR:-.}/.bitbot/session-data"
mkdir -p "$SESSION_DATA_DIR"

# Extract session ID from environment
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Store raw JSON for this session
RAW_FILE="$SESSION_DATA_DIR/${SESSION_ID}-raw.json"
echo "$JSON_DATA" > "$RAW_FILE"

# Extract and store key metrics (using jq if available, otherwise skip)
if command -v jq &>/dev/null; then
    METRICS_FILE="$SESSION_DATA_DIR/${SESSION_ID}-metrics.jsonl"

    # Extract key fields and append to JSONL
    echo "$JSON_DATA" | jq -c "{
        timestamp: \"$TIMESTAMP\",
        session_id: \"$SESSION_ID\",
        model: .model.display_name,
        context_pct: .context_percentage,
        tokens_input: .tokens.input,
        tokens_output: .tokens.output,
        tokens_cached: .tokens.cached,
        tokens_total: .tokens.total
    }" >> "$METRICS_FILE"

    # Also store latest metrics in easy-to-read file
    LATEST_FILE="$SESSION_DATA_DIR/${SESSION_ID}-latest.json"
    echo "$JSON_DATA" | jq "{
        timestamp: \"$TIMESTAMP\",
        session_id: \"$SESSION_ID\",
        model: .model.display_name,
        context_percentage: .context_percentage,
        tokens: .tokens,
        workspace: .workspace
    }" > "$LATEST_FILE"
fi

# Pass JSON through to actual ccstatusline (if installed)
if command -v ccstatusline &>/dev/null; then
    echo "$JSON_DATA" | ccstatusline
else
    # Fallback: Simple status line without ccstatusline
    if command -v jq &>/dev/null; then
        MODEL=$(echo "$JSON_DATA" | jq -r '.model.display_name // "unknown"')
        CONTEXT=$(echo "$JSON_DATA" | jq -r '.context_percentage // 0')
        echo "[$MODEL] Context: ${CONTEXT}%"
    else
        echo "[Claude Code]"
    fi
fi

# Optional: Trigger actions based on context usage
if command -v jq &>/dev/null; then
    CONTEXT_PCT=$(echo "$JSON_DATA" | jq -r '.context_percentage // 0')

    # Warn if context approaching 75% (150k tokens)
    if (( $(echo "$CONTEXT_PCT >= 75" | bc -l 2>/dev/null || echo 0) )); then
        # Store warning flag
        touch "$SESSION_DATA_DIR/${SESSION_ID}-high-context-warning"
    fi
fi
