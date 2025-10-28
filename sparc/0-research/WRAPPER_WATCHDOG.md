# Claude Wrapper & Watchdog

Pipe-based wrapper for Claude Code with automatic stall detection and restart.

## Components

### claude-wrapper.sh
Main wrapper that launches Claude with pipe-based IPC control.

**Features:**
- Named pipe at `.bitbot/wrapper/pipes/claude-<PID>.pipe`
- Commands: `exit`, `restart`, `compact`, `clear`
- Automatic watchdog launch (if enabled)
- Session state tracking

**Usage:**
```bash
.bitbot/wrapper/claude-wrapper.sh [claude-args...]

# Disable watchdog
BITBOT_WATCHDOG=false .bitbot/wrapper/claude-wrapper.sh
```

### watchdog.sh
Monitors Claude process health and triggers restart on stall.

**Monitors:**
- **Type A (Infinite Loop):** Sustained high CPU (>95% for 5+ minutes)
- **Type B (API Timeout):** Session file staleness (warning-only)
- **Type C (I/O Deadlock):** Uninterruptible sleep (D state) for 60+ seconds
- Process existence and responsiveness
- Pipe health

**Configuration:**
Edit variables at top of `watchdog.sh`:
- `CHECK_INTERVAL=30` - Check every 30s
- `CPU_THRESHOLD=95` - High CPU threshold (%)
- `HIGH_CPU_DURATION=300` - Max high CPU time (seconds)
- `LOW_CPU_THRESHOLD=5` - Idle CPU threshold (%)
- `SESSION_UPDATE_TIMEOUT=300` - Session file update timeout
- `IO_BLOCK_DURATION=60` - Max time in D state (seconds)

**Auto-start:**
Watchdog launches automatically when:
1. Running under wrapper
2. Session detected
3. `BITBOT_WATCHDOG` not set to `false`

### send-wrapper-command.sh
Send control commands to running wrapper.

**Usage:**
```bash
# Exit Claude
send-wrapper-command.sh exit

# Restart with session resume
send-wrapper-command.sh restart [session-id]

# Compact and restart
send-wrapper-command.sh compact <session-id>

# Fresh restart
send-wrapper-command.sh clear
```

## Integration

### Session Hooks
`session-start.sh` posts session ID to wrapper state file:
- `.bitbot/wrapper/.wrapper-session-<PID>.state`
- Contains: SESSION_ID, IS_RESUME, START_TIME

### Environment Variables
- `WRAPPER_PIPE` - Path to control pipe (set by wrapper)
- `WRAPPER_PID` - Wrapped process PID (set by wrapper)
- `CLAUDE_PID` - Same as WRAPPER_PID
- `BITBOT_WATCHDOG` - Enable/disable watchdog (default: true)

## Testing

Run test suite:
```bash
dev/tests/test-wrapper.sh
```

**Test coverage:**
- Pipe creation/cleanup
- Command parsing
- Exit command
- Environment variable export
- Syntax validation

## Files

```
.bitbot/wrapper/
├── claude-wrapper.sh           # Main wrapper
├── watchdog.sh                 # Health monitor
├── send-wrapper-command.sh     # Control helper
├── README.md                   # This file
├── pipes/                      # Runtime (gitignored)
│   ├── claude-<PID>.pipe      # Control pipe
│   └── claude-<PID>.ready     # Ready marker
├── .wrapper-session-*.state   # Session state (gitignored)
└── .watchdog-*.state          # Watchdog state (gitignored)
```

## Status

- ✅ Wrapper fully functional
- ✅ All 10 tests passing
- ✅ Watchdog with Type A/C detection complete
- ✅ Type C (I/O deadlock) detection implemented
- ✅ Integrated into BitBot container startup
- ⏳ Needs real-world testing (Type B/C)

## BitBot Integration

The wrapper is automatically installed during `bitbot init` and used by container BitBot:

**During `bitbot init`:**
- Wrapper scripts copied from BitBot to workspace `.bitbot/wrapper/`
- Scripts become available in container at `/workspace/.bitbot/wrapper/`

**During `bitbot start`:**
- Container BitBot checks for `.bitbot/wrapper/claude-wrapper.sh`
- If present: Launches Claude via wrapper (no tmux required)
- If absent: Falls back to tmux-based launch

**Advantages:**
- No tmux dependency (wrapper handles restart internally)
- Automatic watchdog monitoring (Type A/C stall detection)
- Session preservation across restarts
- User-customizable per workspace

**Disabling Watchdog:**
```bash
# In container shell before launching:
export BITBOT_WATCHDOG=false
bitbot start
```

## Next Steps

1. Test watchdog stall detection in real scenarios
2. Create Claude skills for wrapper-based restart commands
3. Add Type B (API timeout) detection
4. Validate false positive rates in production
