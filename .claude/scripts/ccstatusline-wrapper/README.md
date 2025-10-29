# ccstatusline Wrapper

Dead-simple wrapper that extracts context % from Claude Code and makes it available to all tools.

## What It Does

1. Receives JSON from Claude Code status line
2. Extracts `context_percentage`
3. Updates `CLAUDE_CONTEXT_PCT` in `$CLAUDE_ENV_FILE`
4. Passes through to ccstatusline (if installed)

Fast and lightweight - no file I/O, just updates env var and passes through.

## Setup

Edit `.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": ".claude/scripts/ccstatusline-wrapper/wrapper.sh"
  }
}
```

## Usage in Tools/Skills

```bash
# Variable automatically available (sourced by Claude Code)
echo "Current context: ${CLAUDE_CONTEXT_PCT}%"

# Check if nearing limit
if (( $(echo "$CLAUDE_CONTEXT_PCT >= 75" | bc -l) )); then
    echo "Consider compacting context"
fi
```

## Requirements

- **None** - Uses pure bash regex for extraction
- **ccstatusline** (optional) - For enhanced status line display

Without ccstatusline, shows simple `[Claude] Context: XX%` output.

## See Also

- `sparc/0-research/CCSTATUSLINE_SETUP.md` - ccstatusline setup guide
- `.claude/skills/claude-restart-compact/` - Context compaction skill
