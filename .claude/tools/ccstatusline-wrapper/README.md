# ccstatusline Wrapper

Intercepts Claude Code's status line JSON to store token usage and context data for use by other tools.

## What It Does

1. **Receives JSON** from Claude Code (same format as ccstatusline)
2. **Extracts metrics**: token usage, context %, model info
3. **Stores data** in `.bitbot/session-data/`
4. **Passes through** to actual ccstatusline (if installed)

## Files Created

```
.bitbot/session-data/
├── <session-id>-raw.json          # Latest raw JSON from Claude
├── <session-id>-metrics.jsonl     # Append-only metrics log
├── <session-id>-latest.json       # Latest extracted metrics
└── <session-id>-high-context-warning  # Flag file when context >75%
```

## Setup

Edit `.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": ".claude/tools/ccstatusline-wrapper/wrapper.sh"
  }
}
```

## Data Format

**Latest metrics** (`.bitbot/session-data/<session-id>-latest.json`):

```json
{
  "timestamp": "2025-10-29T23:45:00Z",
  "session_id": "abc-123",
  "model": "Claude 3.5 Sonnet",
  "context_percentage": 72.5,
  "tokens": {
    "input": 95000,
    "output": 50000,
    "cached": 0,
    "total": 145000
  },
  "workspace": {
    "current_dir": "/mnt/c/Projects/BitBot"
  }
}
```

## Use Cases

**Check current context usage:**
```bash
jq '.context_percentage' .bitbot/session-data/$CLAUDE_SESSION_ID-latest.json
```

**Get token counts:**
```bash
jq '.tokens' .bitbot/session-data/$CLAUDE_SESSION_ID-latest.json
```

**Check if high context warning:**
```bash
[ -f .bitbot/session-data/$CLAUDE_SESSION_ID-high-context-warning ] && echo "High context!"
```

**View metrics history:**
```bash
cat .bitbot/session-data/$CLAUDE_SESSION_ID-metrics.jsonl | jq .
```

## Requirements

- **jq**: For JSON parsing (optional but recommended)
- **ccstatusline**: For actual status line display (optional)

Without jq, wrapper stores raw JSON only.
Without ccstatusline, shows simple fallback status.

## See Also

- `sparc/0-research/CCSTATUSLINE_SETUP.md` - ccstatusline setup guide
- Claude Code status line documentation
