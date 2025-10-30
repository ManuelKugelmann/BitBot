# Wrapper System Architecture

**Purpose**: Enable Claude Code to autonomously monitor and manage its own context.

**Location**: `/container/bitbot/wrapper/` (copied to `.bitbot/internal/container/bitbot/wrapper/` during init)

---

## System Overview

BitBot's wrapper infrastructure consists of two independent wrappers that work together:

```
┌─────────────────────────────────────────────────────────────┐
│                    Claude Code Process                      │
│                                                             │
│  ┌──────────────────────┐      ┌─────────────────────────┐ │
│  │  Status Line Output  │      │   Skills & Tools        │ │
│  │  (JSON every 1-2s)   │      │   (read context %)      │ │
│  └──────────┬───────────┘      └──────────┬──────────────┘ │
│             │                             │                │
└─────────────┼─────────────────────────────┼────────────────┘
              │                             │
              ↓                             ↓
    ┌─────────────────────┐       ┌─────────────────────────┐
    │  statusline-wrapper │       │   claude-wrapper.sh     │
    │     /wrapper.sh     │       │   (process wrapper)     │
    │  (status line cmd)  │       │                         │
    └─────────┬───────────┘       └──────────┬──────────────┘
              │                              │
              ↓                              ↓
      ┌──────────────────┐         ┌─────────────────────────┐
      │  Session Env     │         │   Named Pipe            │
      │  .bitbot/        │         │   .bitbot/tmp/pipes/    │
      │  session-env/    │         │   claude-<PID>.pipe     │
      │  <session>.env   │         │                         │
      └──────────────────┘         └─────────────────────────┘
              ↑                              ↑
              │                              │
              └──────────────┬───────────────┘
                            │
                    ┌───────────────────┐
                    │  Skills Source    │
                    │  Env & Send Cmds  │
                    └───────────────────┘
```

**Data Flow:**
1. **Monitor**: `statusline-wrapper` extracts context % → writes to session env file
2. **Decide**: Skills source env file → check context threshold
3. **Act**: Skills send command to `claude-wrapper` pipe → trigger compact/restart
4. **Execute**: `claude-wrapper` kills Claude → runs compaction → restarts with resume

---

## Wrapper 1: claude-wrapper.sh

**Type**: Process wrapper (wraps Claude Code execution)

**Purpose**: Provide control interface for restarting/compacting Claude from within

**Location**: `/container/bitbot/wrapper/claude-wrapper.sh`

### Features

- **Named Pipe Control**: Creates pipe at `.bitbot/tmp/pipes/claude-<PID>.pipe`
- **Command Handler**: Processes commands from skills/tools
- **Session Management**: Handles restart with resume/compact/clear modes
- **Watchdog Integration**: Starts stall detection monitor
- **Context Compaction**: Runs `/compact` command before resuming

### Commands

| Command | Format | Action |
|---------|--------|--------|
| `exit` | `echo "exit" > $WRAPPER_PIPE` | Gracefully exit Claude |
| `restart` | `echo "restart <session-id>" > $WRAPPER_PIPE` | Kill + resume session |
| `compact` | `echo "compact <session-id> [prompt]" > $WRAPPER_PIPE` | Kill + compact + resume |
| `clear` | `echo "clear" > $WRAPPER_PIPE` | Kill + fresh start |
| `session` | `echo "session <session-id>" > $WRAPPER_PIPE` | Notify session ID (from hook) |

### Environment Variables Set

- `WRAPPER_PIPE` - Path to control pipe (available to Claude & children)
- `WRAPPER_PID` - Wrapper process PID
- `CLAUDE_PID` - Claude Code process PID

### Usage

```bash
# Launch Claude with wrapper
claude-wrapper.sh [claude-args...]

# From within Claude (e.g., in a skill):
echo "compact $CLAUDE_SESSION_ID" > "$WRAPPER_PIPE"
```

### Restart Modes

**Resume Mode** (`restart`):
- Kills Claude process
- Restarts with `--resume <session-id>`
- Continues previous conversation

**Compact Mode** (`compact`):
- Kills Claude process
- Runs compaction: sends `/compact` command to session
- Restarts with `--resume <session-id>`
- Reduces context usage while preserving conversation

**Clear Mode** (`clear`):
- Kills Claude process
- Restarts without session argument
- Fresh session (loses conversation history)

### Compaction Process

```bash
# 1. Kill Claude
kill -TERM $CLAUDE_PID

# 2. Run compaction (300s timeout)
claude -p --resume "$session_id" << EOF
{"type":"user","message":{"role":"user","content":[{"type":"text","text":"/compact"}]}}
{"type":"user","message":{"role":"user","content":[{"type":"text","text":"Concise summary:"}]}}
EOF

# 3. Restart with resume
exec claude --resume "$session_id"
```

---

## Wrapper 2: statusline-wrapper/wrapper.sh

**Type**: Status line command (receives JSON from Claude)

**Purpose**: Extract context % and make it available to skills/tools

**Location**: `/container/bitbot/wrapper/statusline-wrapper/wrapper.sh`

### Features

- **Pure Bash JSON Parsing**: No external dependencies (jq, grep, sed)
- **Session-Specific Storage**: One env file per session
- **Atomic Writes**: Uses tmp + mv for safe concurrent access
- **Passthrough**: Forwards JSON to `ccstatusline` for display

### Data Extracted

- `CLAUDE_CONTEXT_PCT` - Current context percentage (0-100)
- `CLAUDE_SESSION_ID` - Current session ID

### Output

Writes to: `.bitbot/session-env/<session-id>.env`

```bash
# Claude Code session environment
# Auto-generated by statusline-wrapper
# Session: abc123-def456-...
export CLAUDE_CONTEXT_PCT='67.5'
export CLAUDE_SESSION_ID='abc123-def456-...'
```

### Usage in Skills

```bash
#!/usr/bin/env bash
# Example skill that reads context %

# Source session environment
if [ -n "$CLAUDE_SESSION_ID" ]; then
    ENV_FILE="${CLAUDE_PROJECT_DIR}/.bitbot/session-env/${CLAUDE_SESSION_ID}.env"
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
    fi
fi

# Check context threshold
if (( $(echo "$CLAUDE_CONTEXT_PCT > 85" | bc -l) )); then
    echo "Context at ${CLAUDE_CONTEXT_PCT}% - triggering compaction"
    echo "compact $CLAUDE_SESSION_ID" > "$WRAPPER_PIPE"
fi
```

### Configuration

Add to `.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/workspace/.bitbot/internal/container/bitbot/wrapper/statusline-wrapper/wrapper.sh"
  }
}
```

### Technical Details

**Pure Bash Regex Extraction:**
```bash
# Extract session_id
if [[ "$JSON_DATA" =~ \"session_id\":\"([^\"]+)\" ]]; then
    SESSION_ID="${BASH_REMATCH[1]}"
fi

# Extract context percentage
if [[ "$JSON_DATA" =~ \"context_percentage\":([0-9.]+) ]]; then
    CONTEXT_PCT="${BASH_REMATCH[1]}"
fi
```

**Atomic File Write:**
```bash
TMP_FILE="${ENV_FILE}.tmp.$$"
cat > "$TMP_FILE" << EOF
export CLAUDE_CONTEXT_PCT='$CONTEXT_PCT'
export CLAUDE_SESSION_ID='$SESSION_ID'
EOF
mv "$TMP_FILE" "$ENV_FILE"  # Atomic rename
```

---

## How They Work Together

### Scenario: Autonomous Context Compaction

**1. Continuous Monitoring (statusline-wrapper)**
```
Every 1-2 seconds:
  Claude generates status line JSON
    ↓
  statusline-wrapper extracts context %
    ↓
  Writes to .bitbot/session-env/<session>.env
```

**2. Threshold Detection (Skills)**
```
Skill execution:
  Source session env file
    ↓
  Check: CLAUDE_CONTEXT_PCT > threshold?
    ↓
  If true: Send command to wrapper pipe
```

**3. Compaction Execution (claude-wrapper)**
```
Command received via pipe:
  Kill Claude process
    ↓
  Run /compact command on session
    ↓
  Restart with --resume <session-id>
    ↓
  Conversation continues with reduced context
```

### Example: claude-restart Skill

```bash
#!/usr/bin/env bash
# claude-restart skill - Trigger compact on high context

set -euo pipefail

# Get project root
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-.}"

# Source session environment
ENV_FILE="$PROJECT_ROOT/.bitbot/session-env/${CLAUDE_SESSION_ID}.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# Check context percentage
THRESHOLD=${CLAUDE_RESTART_THRESHOLD:-85}

if (( $(echo "$CLAUDE_CONTEXT_PCT > $THRESHOLD" | bc -l) )); then
    echo "Context at ${CLAUDE_CONTEXT_PCT}% (threshold: ${THRESHOLD}%)"
    echo "Triggering compaction and restart..."

    # Send compact command to wrapper
    if [ -n "${WRAPPER_PIPE:-}" ] && [ -p "$WRAPPER_PIPE" ]; then
        echo "compact $CLAUDE_SESSION_ID" > "$WRAPPER_PIPE"
    else
        echo "Error: Wrapper pipe not available"
        exit 1
    fi
else
    echo "Context at ${CLAUDE_CONTEXT_PCT}% (threshold: ${THRESHOLD}%)"
    echo "No compaction needed"
fi
```

---

## Session Environment Files

**Location**: `.bitbot/session-env/<session-id>.env`

**Lifecycle**:
- Created by `statusline-wrapper` every 1-2 seconds
- Cleaned up by `session-start` hook (all files deleted aggressively)
- Cleaned up by `session-end` hook (removes all files)
- Self-healing: Active sessions recreate files automatically

**Why Aggressive Cleanup**:
- Files recreated every 1-2 seconds by status line wrapper
- Safe to delete all files (including current session)
- Prevents accumulation of stale session data
- No need for manual cleanup scripts

**Properties**:
- Ephemeral (runtime only)
- Gitignored (`.gitignore` entry)
- Session-specific (one file per session ID)
- Atomic writes (safe for concurrent access)

---

## Integration Points

### SessionStart Hook

```bash
# Set environment variables for skills
export CLAUDE_PID="<pid>"
export CLAUDE_SESSION_ID="<session-id>"

# Notify wrapper of session ID
if [ -n "${WRAPPER_PIPE:-}" ] && [ -p "$WRAPPER_PIPE" ]; then
    echo "session $CLAUDE_SESSION_ID" > "$WRAPPER_PIPE"
fi

# Clean up old session env files (aggressive)
rm -f "$PROJECT_ROOT/.bitbot/session-env"/*.env 2>/dev/null || true
```

### SessionEnd Hook

```bash
# Clean up session environment files (aggressive)
rm -f "$PROJECT_ROOT/.bitbot/session-env"/*.env 2>/dev/null || true
rmdir "$PROJECT_ROOT/.bitbot/session-env" 2>/dev/null || true
```

### Skills

Skills can:
1. Source session env file to read `CLAUDE_CONTEXT_PCT`
2. Send commands to `$WRAPPER_PIPE` to trigger actions
3. Access `CLAUDE_PID` and `CLAUDE_SESSION_ID` from environment

---

## Directory Structure

```
/container/bitbot/wrapper/          # Repository (source of truth)
├── claude-wrapper.sh               # Process wrapper
├── statusline-wrapper/
│   └── wrapper.sh                  # Status line wrapper
└── watchdog.sh                     # Stall detection monitor

.bitbot/internal/container/bitbot/  # Workspace copy (from bitbot init)
└── wrapper/                        # Copied from /container/bitbot/wrapper/
    ├── claude-wrapper.sh
    ├── statusline-wrapper/
    │   └── wrapper.sh
    └── watchdog.sh

.bitbot/session-env/                # Runtime data (ephemeral)
├── <session-id-1>.env              # Session 1 environment
└── <session-id-2>.env              # Session 2 environment

.bitbot/tmp/pipes/                  # Control pipes (ephemeral)
└── claude-<PID>.pipe               # Named pipe for commands
```

---

## Benefits

**Autonomous Context Management**:
- Claude monitors own context usage
- Automatically compacts when threshold reached
- No manual intervention required
- Prevents context exhaustion mid-task

**Self-Healing**:
- Session env files recreated every 1-2 seconds
- Aggressive cleanup on session start/end
- No stale data accumulation

**Simple Integration**:
- Pure bash (no external dependencies)
- Skills just source env file and send pipe commands
- Works with existing Claude Code infrastructure

**Flexibility**:
- Skills can customize threshold
- Custom compaction prompts supported
- Manual trigger via skills
- Multiple modes: resume, compact, clear

---

## See Also

- `sparc/0-research/WRAPPER_INTEGRATION.md` - Wrapper integration research
- `sparc/0-research/CLAUDE_CODE_ENV_VARS.md` - Environment variable scope
- `sparc/0-research/CCSTATUSLINE_SETUP.md` - Status line setup guide
- `sparc/3-architecture/01-directory-structure.md` - Directory structure
- `.claude/skills/claude-restart/` - Restart skill implementation
