# Container BitBot Specification

**Feature ID**: SPEC-11
**Priority**: P1 (Important)
**Status**: Implemented
**Depends On**: SPEC-02 (Security Modes), SPEC-04 (Session Management)
**Created**: 2025-10-28
**Last Updated**: 2025-10-28

---

## Executive Summary

Container BitBot is the container-side companion to host-side BitBot, providing two-layer session management: tmux for terminal persistence and wrapper for Claude operations. It runs inside both work and config mode containers at `/usr/local/bitbot/`.

**Key Features**:
- **Layer 1 (tmux)**: Session persistence with smart launcher, start, and resume commands
- **Layer 2 (wrapper)**: Claude operations via IPC (restart/resume/compact/clear)
- Complete separation: tmux manages sessions, wrapper manages Claude
- Mode-aware operation (work vs config tools)

---

## 1. Architecture

### 1.1 Installation Location

**Container Path**: `/usr/local/bitbot/`

**Structure**:
```
/usr/local/bitbot/
├── bitbot                      # Main entry point
├── wrapper/                    # Wrapper scripts (pipe-based IPC)
│   ├── claude-wrapper.sh      # Main wrapper
│   ├── send-wrapper-command.sh # IPC command sender
│   └── watchdog.sh            # Stall detection
├── core/
│   ├── commands/               # Command implementations
│   │   └── start.sh           # Launch Claude via wrapper in tmux
│   └── util/
│       ├── helpers.sh         # Common utilities
│       └── tmux-utils.sh      # tmux operations
└── README.md
```

### 1.2 Build Configuration

Container BitBot is copied during build:

**Dockerfile**:
```dockerfile
# Copy container BitBot from source
COPY container/bitbot/ /usr/local/bitbot/
RUN chmod +x /usr/local/bitbot/bitbot
RUN chmod +x /usr/local/bitbot/core/commands/*.sh
RUN chmod +x /usr/local/bitbot/wrapper/*.sh
```

**PATH Setup**:
```dockerfile
ENV PATH="/usr/local/bitbot:${PATH}"
```

**Dependencies**:
```dockerfile
RUN apt-get update && apt-get install -y tmux && apt-get clean
```

---

## 2. Commands

### 2.1 Default (Smart Launcher)

**Usage**: `bitbot` (no arguments)

**Behavior**:
- **0 tmux sessions**: Offer launch mode choice (fresh/resume/custom)
- **1 tmux session**: Auto-resume that session
- **2+ tmux sessions**: Show menu, offer resume/new

**Architecture Flow**:
```
bitbot → detect sessions → route to start or resume
```

### 2.2 Start (New Session)

**Usage**: `bitbot start [args]`

**Behavior**:
1. Check wrapper and tmux availability
2. Create new tmux session with unique name
3. Execute wrapper directly: `tmux new-session -s name "wrapper claude [args]"`
4. No send-keys - wrapper exec'd as session command

**Architecture Flow**:
```
bitbot start → tmux new-session → wrapper → claude
```

**Example Output**:
```
BitBot - Start New Session

Creating new tmux session: claude-20251028-143052
Workspace: /workspace
Mode: work

[Claude Code interface appears]
```

### 2.3 Resume (Attach or Resume)

**Usage**:
- `bitbot resume` - Smart resume
- `bitbot resume <session-name>` - Resume specific session

**Behavior**:
- **0 tmux sessions**: Create new tmux with `wrapper claude --resume`
- **1 tmux session**: Auto-attach to that session
- **2+ tmux sessions**: Show menu for selection
- **After attach**: Warn if Claude process not detected

**Architecture Flow**:
```
bitbot resume (no sessions) → tmux new-session → wrapper claude --resume
bitbot resume (sessions exist) → tmux attach (wrapper already running)
```

**Example Output (no sessions)**:
```
BitBot - Resume Session

No unattached tmux sessions found
Creating new session with Claude --resume...

Claude will show its available sessions for you to select

Workspace: /workspace
Mode: work
Session: claude-20251028-143102

[Claude's session picker appears]
```

**Example Output (1 session)**:
```
BitBot - Resume Session

Found one session: claude-20251028-143052

Attaching to session 'claude-20251028-143052'...

[Attaches to existing tmux/wrapper/claude]
```

---

## 3. Two-Layer Architecture

Container BitBot separates concerns into two independent layers:

### 3.1 Layer 1: tmux (Session Persistence)

**Purpose**: Terminal session management (detach/reattach)

**Responsibilities**:
- Create tmux sessions with unique names
- Attach to existing sessions
- Detect available sessions
- Provide session persistence across terminal disconnections

**Commands**:
- `bitbot` - Smart launcher (detects sessions)
- `bitbot start` - Create new session
- `bitbot resume` - Attach to existing or create with `--resume`

**Implementation**:
- Uses `tmux new-session -s name "command"` (NOT send-keys)
- Wrapper exec'd directly as session command
- Single pane per session (no splitting within terminal)
- Multiple sessions possible across different terminals

**Key Point**: tmux layer only manages session lifecycle, not Claude operations

### 3.2 Layer 2: Wrapper (Claude Operations)

**Purpose**: Claude process management via IPC

**Location**: `/usr/local/bitbot/wrapper/`

**Components**:
- `claude-wrapper.sh` - Main wrapper, launches Claude
- `send-wrapper-command.sh` - IPC command sender
- `watchdog.sh` - Stall detection process

**Responsibilities**:
- Launch Claude Code with arguments
- Handle restart/resume/compact/clear via named pipe IPC
- Monitor Claude process for stalls
- Pass all arguments through to Claude

**IPC Commands** (used from inside Claude):
```bash
# Restart Claude
/usr/local/bitbot/wrapper/send-wrapper-command.sh restart

# Resume Claude session (Claude's own session management)
/usr/local/bitbot/wrapper/send-wrapper-command.sh resume

# Compact Claude context
/usr/local/bitbot/wrapper/send-wrapper-command.sh compact

# Clear Claude session
/usr/local/bitbot/wrapper/send-wrapper-command.sh clear
```

**Key Point**: Wrapper operations are completely independent of tmux

### 3.3 Complete Architecture Flow

**Starting new session**:
```
bitbot start
  ↓
Check wrapper & tmux availability
  ↓
tmux new-session -s claude-YYYYMMDD-HHMMSS "/usr/local/bitbot/wrapper/claude-wrapper.sh claude"
  ↓
Wrapper launches Claude
  ↓
User sees Claude interface
```

**Resuming session**:
```
bitbot resume
  ↓
Check for tmux sessions
  ↓
If sessions exist: tmux attach (wrapper+claude already running)
If no sessions: tmux new-session "/usr/local/bitbot/wrapper/claude-wrapper.sh claude --resume"
```

**Claude operations (inside running Claude)**:
```
send-wrapper-command.sh restart
  ↓
Named pipe IPC to wrapper process
  ↓
Wrapper restarts Claude
  ↓
No tmux involvement
```

### 3.4 Independence

**Critical**: The two layers are completely independent:
- tmux manages terminal session persistence (detach/reattach)
- Wrapper manages Claude operations (restart/resume/compact)
- No `tmux send-keys` usage anywhere
- Claude operations work identically whether in tmux or not

---

## 4. Mode-Specific Behavior

### 4.1 Work Mode

**Environment**:
- `BITBOT_MODE=work`
- Workspace mounted RW at `/workspace`
- `.devcontainer/` mounted RO (read-only)

**Available Commands**:
- `bitbot [args]` - Launch Claude Code

**Claude Code Configuration**:
- Work-focused tools enabled
- Git safety hooks active
- Infrastructure files read-only
- MCP services: code-focused

### 4.2 Config Mode

**Environment**:
- `BITBOT_MODE=config`
- Full workspace RW access
- No Docker inside (default)

**Available Commands**:
- Same as work mode (start, resume)

**Claude Code Configuration**:
- Infrastructure tools enabled
- Git safety hooks active
- Full filesystem access
- MCP services: config-focused

---

## 5. Integration with Host BitBot

### 5.1 Two-Layer Architecture

**Host-Side BitBot** (`/path/to/bitbot/`):
- Workspace initialization
- DevContainer launching
- VS Code integration
- Cross-platform routing

**Container-Side BitBot** (`/usr/local/bitbot/`):
- Session management
- Claude Code launching
- Workspace analysis
- Mode-specific utilities

### 5.2 Flow

```
User runs: bitbot work
  ↓
Host BitBot launches work container
  ↓
User in container terminal runs: bitbot
  ↓
Container BitBot launches Claude Code in tmux
  ↓
User works with Claude
  ↓
User detaches tmux (Ctrl+B D)
  ↓
Container keeps running
  ↓
User reconnects later: bitbot resume
  ↓
Resume same Claude session
```

---

## 6. Future Enhancements

### 6.1 Enhanced Session Selection (Inspiration)

**Reference**: https://github.com/TerminalGravity/cld-tmux/blob/main/cld

**Goal**: Improve session selection UX beyond Claude's built-in chooser

**Current Approach**:
- BitBot manages tmux sessions (Level 1)
- Claude manages conversation history (Level 2)
- `claude --resume` shows its own session picker

**Potential Enhancement**:
- fzf-based unified session picker
- Show both tmux sessions AND Claude sessions in one view
- Preview pane showing session metadata
- Fuzzy search across session names/dates
- Integration with existing tools like cld-tmux

**Decision**: Keep it simple for now, revisit when user feedback indicates need

### 6.2 Multi-Workspace Support

**Goal**: Work on multiple projects simultaneously

**Features**:
- Multiple containers (one per workspace)
- Session namespace by workspace
- Container-aware session switching
- Resource limits per workspace

### 6.3 Session Persistence

**Goal**: Survive container restarts

**Features**:
- Save session state to volume
- Restore sessions after container restart
- Workspace history tracking
- Session backup/restore

### 6.4 Collaborative Sessions

**Goal**: Pair programming with AI assistant

**Features**:
- tmux session sharing
- Multi-user attach
- Session recording/playback
- Audit trail

### 6.5 Resource Monitoring

**Goal**: Track and limit resource usage

**Features**:
- CPU/memory monitoring per session
- Token usage tracking (Claude API)
- Storage quota enforcement
- Alert on resource limits

---

## 7. Implementation Details

### 7.1 Utilities

**helpers.sh**:
```bash
# Color output
info()    { echo -e "${BLUE}$*${RESET}"; }
success() { echo -e "${GREEN}$*${RESET}"; }
warning() { echo -e "${YELLOW}$*${RESET}"; }
error()   { echo -e "${RED}$*${RESET}"; }

# Environment detection
get_bitbot_mode()  { echo "${BITBOT_MODE:-unknown}"; }
get_workspace()    { echo "${WORKSPACE:-/workspace}"; }
is_config_mode()   { [[ "${BITBOT_MODE}" == "config" ]]; }
```

**tmux-utils.sh**:
```bash
# tmux operations
tmux_available()          { command -v tmux >/dev/null 2>&1; }
list_claude_sessions()    { tmux list-sessions 2>/dev/null | grep "^claude-"; }
session_exists()          { tmux has-session -t "$1" 2>/dev/null; }
generate_session_name()   { echo "claude-$(date +%Y%m%d-%H%M)"; }
create_claude_session()   { tmux new-session -d -s "$1"; }
attach_session()          { tmux attach-session -t "$1"; }
```

### 7.2 Error Handling

**Prerequisites Check**:
```bash
# Check tmux availability
if ! tmux_available; then
    error "tmux is not available"
    echo ""
    echo "Please install tmux:"
    echo "  sudo apt-get install tmux"
    exit 1
fi

# Check Claude Code availability
if ! command -v claude >/dev/null 2>&1; then
    error "Claude Code is not installed"
    echo ""
    echo "Please install Claude Code:"
    echo "  npm install -g @anthropic-ai/claude-code"
    exit 1
fi
```

**Session Conflicts**:
```bash
# Avoid duplicate session names
session_name="$(generate_session_name)"
counter=1
while session_exists "$session_name"; do
    session_name="claude-$(date +%Y%m%d-%H%M)-${counter}"
    ((counter++))
done
```

---

## 8. Testing

### 8.1 Manual Test Cases

**Session Creation**:
- [ ] `bitbot start` creates new session
- [ ] Session name follows naming convention
- [ ] Claude Code launches successfully
- [ ] User can interact with Claude

**Session Resume**:
- [ ] `bitbot resume` lists existing sessions
- [ ] User can select and resume session
- [ ] Session state persists after resume
- [ ] Multiple sessions can coexist

**Default Launcher**:
- [ ] `bitbot` with no sessions creates new
- [ ] `bitbot` with sessions offers resume/new choice
- [ ] User can navigate menu correctly

**Mode-Specific**:
- [ ] `bitbot configure` works in config mode
- [ ] `bitbot configure` blocked in work mode
- [ ] Mode detection correct in both modes

### 8.2 Automated Tests

**Future** (`dev/tests/test-container-bitbot.sh`):
```bash
# Test session creation
test_session_creation() {
    local session=$(bitbot start --test-mode)
    assert_session_exists "$session"
    assert_claude_running_in_session "$session"
}

# Test session listing
test_session_listing() {
    create_test_sessions 3
    local output=$(bitbot resume --list)
    assert_session_count 3 "$output"
}

# Test mode detection
test_mode_detection() {
    export BITBOT_MODE=work
    assert_command_available "bitbot analyze"
    assert_command_blocked "bitbot configure"
}
```

---

## 9. Success Criteria

**Functional Requirements**:
- [x] Container BitBot accessible at `/usr/local/bitbot/`
- [x] Smart launcher detects and offers resume
- [x] tmux session creation and management
- [x] Claude Code launches in tmux
- [x] Mode-specific behavior (work vs config)
- [x] Workspace analysis functional

**Usability Requirements**:
- [x] Simple command syntax (`bitbot`, `bitbot start`, etc.)
- [x] Clear menu prompts and options
- [x] Human-readable session names
- [x] Helpful error messages
- [x] No complex configuration required

**Reliability Requirements**:
- [x] Sessions persist across terminal disconnect
- [x] Multiple sessions can run simultaneously
- [x] No session name conflicts
- [x] Graceful handling of missing prerequisites
- [x] Works in both work and config modes

---

## 10. References

**Related Specifications**:
- SPEC-02: Security Mode System (work vs config)
- SPEC-04: Session Management (hooks, not tmux)
- SPEC-07: AI Agent Integration (Claude Code)

**External References**:
- tmux manual: https://man.openbsd.org/tmux
- Claude Code CLI: https://docs.claude.com/en/docs/claude-code/cli

---

**Status**: **Implemented**
**Next Steps**: Add session persistence across container restarts
