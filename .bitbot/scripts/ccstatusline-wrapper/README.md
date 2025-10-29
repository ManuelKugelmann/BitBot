# ccstatusline Wrapper

Extracts context % from Claude Code status line and makes it available to tools via session-specific environment file.

## What It Does

1. Receives JSON from Claude Code status line (via stdin)
2. Extracts `context_percentage` and `session_id`
3. Stores in `.bitbot/session-env/<session-id>.env`
4. Passes through to ccstatusline (if installed)

## Why Per-Session Files?

**CLAUDE_ENV_FILE is ONLY available to SessionStart hooks**, not to status line commands or other contexts. Status line commands receive data via JSON stdin only.

Therefore, we use session-specific files that tools can source:

```
.bitbot/session-env/
├── abc-123.env          # Session abc-123 environment
└── def-456.env          # Session def-456 environment
```

## Setup

Edit `.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": ".bitbot/scripts/ccstatusline-wrapper/wrapper.sh"
  }
}
```

## Usage in Tools/Skills

Tools must source the session-specific env file:

```bash
# Source session environment (if available)
if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
    SESSION_ENV="${CLAUDE_PROJECT_DIR:-.}/.bitbot/session-env/${CLAUDE_SESSION_ID}.env"
    [ -f "$SESSION_ENV" ] && source "$SESSION_ENV"
fi

# Now variable is available
echo "Current context: ${CLAUDE_CONTEXT_PCT}%"

# Check if nearing limit
if (( $(echo "$CLAUDE_CONTEXT_PCT >= 75" | bc -l) )); then
    echo "Consider compacting context"
fi
```

**Note**: `CLAUDE_SESSION_ID` is available because the SessionStart hook writes it to `$CLAUDE_ENV_FILE`, which IS available to bash commands.

## Requirements

- **None** - Uses pure bash regex for extraction
- **ccstatusline** (optional) - For enhanced status line display

Without ccstatusline, shows simple `[Claude] Context: XX%` output.

## Technical Details

**Why not use `$CLAUDE_ENV_FILE` directly?**

- `CLAUDE_ENV_FILE` is exclusive to SessionStart hooks
- Status line commands don't have access to it
- Per-session files are the standard practice for sharing data from status line to other contexts

**Atomicity:**

The wrapper uses atomic writes (`tmp + mv`) to prevent race conditions when multiple status updates occur simultaneously.

**Cleanup:**

- **Automatic**: SessionEnd hook removes session env file when session ends normally
- **Manual**: `.claude/scripts/cleanup-old-sessions.sh` removes files older than 7 days (for crashed sessions)

## See Also

- `sparc/0-research/CCSTATUSLINE_SETUP.md` - ccstatusline setup guide
- `.claude/skills/claude-restart-compact/` - Context compaction skill
- [Claude Code Hooks Documentation](https://docs.claude.com/en/docs/claude-code/hooks.md) - Official docs on environment variables
