# Claude Code Environment Variables

Research on environment variable scoping and best practices in Claude Code.

## Key Findings

### CLAUDE_ENV_FILE Scope

**CLAUDE_ENV_FILE is EXCLUSIVE to SessionStart hooks**

- Only available when SessionStart hook is invoked
- NOT available to:
  - Status line commands
  - Other hook types
  - Bash commands (even though they can read variables written to it)
  - Any other Claude Code contexts

**Source**: [Claude Code Hooks Documentation](https://docs.claude.com/en/docs/claude-code/hooks.md)

### Status Line Context

**Status line commands receive data ONLY via JSON stdin**, not environment variables:

- `session_id` - Unique session identifier
- `transcript_path` - Session transcript file location
- `workspace` - Current and project directories
- `model` - AI model information
- `context_percentage` - Current context usage
- `tokens` - Token usage statistics

**Source**: [Claude Code Status Line Documentation](https://docs.claude.com/en/docs/claude-code/statusline.md)

### Standard Practices

Based on official documentation:

1. **SessionStart hooks**: Write to `$CLAUDE_ENV_FILE`
   - Variables become available to bash commands in session
   - Use for dependency setup, environment configuration
   - Example: `echo 'export NODE_ENV=production' >> "$CLAUDE_ENV_FILE"`

2. **Status line commands**: Parse JSON from stdin
   - Extract `session_id` for session-specific operations
   - No direct env var write capability
   - Must use alternative storage if needed

3. **Cross-context data sharing**: Use files
   - Status line → Tools: Per-session files
   - Tools can source session-specific env files
   - Example: `.bitbot/session-env/<session-id>.env`

## BitBot Implementation

### SessionStart Hook

**Location**: `container/templates/bitbot-base/.claude/hooks/session-start.sh`

**What it does**:
- Receives session JSON via stdin
- Extracts `session_id`
- Writes to `$CLAUDE_ENV_FILE`:
  - `CLAUDE_SESSION_ID` - Makes session ID available to all bash commands
  - `CLAUDE_PROJECT_DIR` - Project root directory
  - `CLAUDE_PID` - Claude process ID (for restart/management)

**Why this works**:
- SessionStart hook has access to `$CLAUDE_ENV_FILE`
- Variables written here are sourced by Claude Code for all bash commands
- Standard practice per official docs

### Status Line Wrapper

**Location**: `.claude/scripts/ccstatusline-wrapper/wrapper.sh`

**What it does**:
- Receives status JSON via stdin
- Extracts `context_percentage` and `session_id`
- Writes to `.bitbot/session-env/<session-id>.env`
- Passes through to ccstatusline

**Why per-session files**:
- Status line commands do NOT have access to `$CLAUDE_ENV_FILE`
- Must use alternative storage mechanism
- Session-specific files prevent multi-session conflicts
- Atomic writes (tmp + mv) prevent race conditions

**How tools use it**:
```bash
# In skill or tool script
if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
    SESSION_ENV=".bitbot/session-env/${CLAUDE_SESSION_ID}.env"
    [ -f "$SESSION_ENV" ] && source "$SESSION_ENV"
fi

# Now CLAUDE_CONTEXT_PCT is available
echo "Context: ${CLAUDE_CONTEXT_PCT}%"
```

## Why This Architecture?

### Problem
Status line commands can't write to `$CLAUDE_ENV_FILE` (not available in that context).

### Solution
1. SessionStart hook writes `CLAUDE_SESSION_ID` to `$CLAUDE_ENV_FILE` (available to all bash)
2. Status line wrapper writes context % to `.bitbot/session-env/<session-id>.env`
3. Tools source session file using `$CLAUDE_SESSION_ID` from step 1

### Benefits
- Clean separation of concerns
- No env var conflicts between sessions
- Atomic writes prevent corruption
- Pure bash implementation (fast)
- Follows Claude Code best practices

## Alternative Approaches Considered

### ❌ Using $CLAUDE_ENV_FILE in status line
**Why not**: Not available in status line context per documentation

### ❌ Global env file (not per-session)
**Why not**: Multi-session conflicts, race conditions

### ❌ Complex JSON storage
**Why not**: Overkill for simple key-value data, requires jq

### ✅ Per-session env files (chosen approach)
**Why yes**: Simple, fast, safe, follows bash conventions

## References

- [Claude Code Hooks Documentation](https://docs.claude.com/en/docs/claude-code/hooks.md)
- [Claude Code Status Line Documentation](https://docs.claude.com/en/docs/claude-code/statusline.md)
- [Claude Code Hooks Guide](https://docs.claude.com/en/docs/claude-code/hooks-guide.md)
