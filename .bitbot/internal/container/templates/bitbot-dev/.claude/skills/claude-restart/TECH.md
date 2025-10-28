# Restart Skill - Technical Implementation

## Overview

Simple self-pkill approach: find Claude PID, kill it, exec restart command.

## How It Works

1. **Find Claude PID** - Walk up process tree from bash script to find "claude" process
2. **Detect Session ID** - Check most recent directory in `~/.claude/session-env/`
3. **Display Info** - Show mode, session ID, Claude PID
4. **Kill Process** - Send SIGTERM to Claude PID
5. **Wait** - 2 seconds for clean exit
6. **Clear Terminal** - Clear screen
7. **Exec Restart** - Replace script process with Claude command

## Session ID Detection

```bash
get_session_id() {
    local session_dir="$HOME/.claude/session-env"
    ls -t "$session_dir" 2>/dev/null | head -1
}
```

Finds most recently modified session directory (sorted by time).

## Claude PID Detection

```bash
find_claude_pid() {
    local pid=$$
    while [ $depth -lt 10 ] && [ $pid -gt 1 ]; do
        ppid=$(ps -p "$pid" -o ppid=)
        pname=$(ps -p "$ppid" -o comm=)
        if [ "$pname" = "claude" ]; then
            echo "$ppid"
            return 0
        fi
        pid=$ppid
    done
    return 1
}
```

Walks up parent chain max 10 levels looking for "claude" process.

## Restart Commands

- **Resume**: `claude --resume <session-id>`
- **Compact**: `claude -p --resume <session-id>`
- **Clear**: `claude`

## Exit Strategy

```bash
kill -TERM "$CLAUDE_PID"  # Graceful termination
sleep 2                    # Wait for exit
clear                      # Clear terminal
exec $RESTART_CMD          # Replace process
```

Using `exec` replaces the script process with Claude, ensuring clean restart without orphaned processes.

## Error Handling

- **No Claude process found**: Abort with error message
- **No session ID for resume/compact**: Abort with error, suggest `clear` mode
- **Kill fails**: Exit with error code

## Dependencies

- `ps` - Process listing
- `kill` - Send signals
- `clear` - Clear terminal
- `exec` - Replace process
- No tmux or hooks required

## File Structure

```
.claude/skills/restart/
├── SKILL.md              # Usage documentation
├── TECH.md               # This file (implementation details)
└── scripts/
    └── claude-restart.sh # Main restart script
```

## Optional Hook

SessionStart hook (`.claude/hooks/session-start.sh`) displays session ID at startup:

```bash
# Receives JSON with session_id
# Echoes: "Session ID: <uuid>"
```

Hook is optional - only for user visibility.
