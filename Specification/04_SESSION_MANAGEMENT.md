# Session Management Specification

**Feature ID**: SPEC-04
**Priority**: P0 (Critical - Blocking)
**Status**: Draft
**Depends On**: SPEC-01 (Container Orchestration), SPEC-02 (Security Modes)
**Created**: 2025-10-17
**Last Updated**: 2025-10-17

---

## Executive Summary

tmux-based session management for CLI and VS Code workflows. Supports multiple parallel sessions per workspace, session persistence across container restarts, and mode-specific session contexts.

**Key Design**: tmux sessions + named sessions per mode + persistence + multi-session support = reliable dev environment.

---

## 1. Architecture

### 1.1 Session Types

**Work Sessions**:
- Container: `bitbot-dev-${WORKSPACE_HASH}`
- Session naming: `work-main`, `work-${NAME}`
- Purpose: Normal development work
- Persistence: `.bitbot/sessions/work/`

**Setup Sessions**:
- Container: `bitbot-setup-${WORKSPACE_HASH}`
- Session naming: `setup-main`, `setup-${NAME}`
- Purpose: Infrastructure changes
- Persistence: `.bitbot/sessions/setup/`

### 1.2 Session Lifecycle

```
Container Start
  ↓
Load Persisted Sessions (.bitbot/sessions/)
  ↓
Restore tmux Sessions
  ↓
User Attaches to Session
  ↓
Work Happens
  ↓
Container Stop
  ↓
Save Session State
```

---

## 2. tmux Integration

### 2.1 Session Management

**Default session** (automatic on container start):
```bash
# Pseudocode
if mode == "work":
  tmux new-session -d -s "work-main" -c /workspace
elif mode == "setup":
  tmux new-session -d -s "setup-main" -c /setup/workspace
```

**Named sessions** (user-created):
```bash
# User creates additional sessions
bitbot session new feature-x      # Creates work-feature-x
bitbot session new infra-update   # Creates setup-infra-update (in setup mode)
```

**List sessions**:
```bash
bitbot session list
# Output:
# work-main (attached)
# work-feature-x (detached)
# work-bug-fix (detached)
```

**Attach to session**:
```bash
bitbot session attach feature-x   # Attaches to work-feature-x
bitbot session attach main         # Attaches to work-main
```

### 2.2 Session Configuration

**tmux config** (`.bitbot/setup/tmux.conf`):
```bash
# BitBot tmux configuration
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Session management
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# Mouse support
set -g mouse on

# History
set -g history-limit 50000

# Status bar
set -g status-style bg=colour235,fg=colour136
set -g status-left '[#{session_name}] '
set -g status-right '%Y-%m-%d %H:%M'

# Pane borders
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=colour136

# Resurrect support (session persistence)
run-shell ~/.tmux/plugins/tmux-resurrect/resurrect.tmux
set -g @resurrect-dir '.bitbot/sessions/${MODE}'
set -g @resurrect-capture-pane-contents 'on'
```

---

## 3. Session Persistence

### 3.1 Persistence Strategy

**State storage**:
```
.bitbot/sessions/
├── work/
│   ├── last.txt          # Last saved state
│   ├── tmux_resurrect_*.txt
│   └── session_metadata.json
└── setup/
    ├── last.txt
    ├── tmux_resurrect_*.txt
    └── session_metadata.json
```

**Session metadata**:
```json
{
  "sessions": [
    {
      "name": "work-main",
      "created": "2025-10-17T10:00:00Z",
      "last_attached": "2025-10-17T12:30:00Z",
      "windows": 3,
      "panes": 5,
      "working_directory": "/workspace"
    },
    {
      "name": "work-feature-x",
      "created": "2025-10-17T11:00:00Z",
      "last_attached": "2025-10-17T11:45:00Z",
      "windows": 2,
      "panes": 3,
      "working_directory": "/workspace/src"
    }
  ]
}
```

### 3.2 Save/Restore Process

**Auto-save** (periodic, every 15 minutes):
```bash
# Pseudocode
tmux_autosave() {
  while true:
    sleep 900  # 15 minutes
    save_all_sessions()
}
```

**Manual save**:
```bash
bitbot session save           # Save current session
bitbot session save --all     # Save all sessions
```

**Auto-restore** (on container start):
```bash
# Pseudocode
restore_sessions() {
  mode = env("BITBOT_MODE")
  sessions_dir = ".bitbot/sessions/${mode}"

  if exists "${sessions_dir}/last.txt":
    tmux_resurrect_restore("${sessions_dir}/last.txt")
    log("Restored ${mode} sessions from ${sessions_dir}")
  else:
    # Create default session
    create_default_session(mode)
}
```

**Manual restore**:
```bash
bitbot session restore        # Restore from last save
bitbot session restore --timestamp 2025-10-17-12-30  # Restore from specific save
```

---

## 4. Multi-Session Support

### 4.1 Concurrent Sessions

**Same container, multiple tmux sessions**:
```bash
# Terminal 1
bitbot work
tmux attach -t work-main

# Terminal 2 (same workspace)
bitbot work --attach feature-x
# Attaches to work-feature-x session in same container
```

**VS Code + CLI simultaneously**:
```bash
# Terminal
bitbot work

# VS Code
bitbot work --vscode
# Both attach to same container, different tmux sessions
```

**Work + Setup in parallel**:
```bash
# Terminal 1: Work mode
bitbot work

# Terminal 2: Setup mode (different container)
bitbot setup

# Both containers running, separate session namespaces
```

### 4.2 Session Isolation

**Per-mode session namespaces**:
- Work sessions: `work-*` (in work container)
- Setup sessions: `setup-*` (in setup container)
- No name collision between modes (different containers)

**Session listing per mode**:
```bash
# In work container
tmux ls
# work-main
# work-feature-x

# In setup container
tmux ls
# setup-main
# setup-infra
```

---

## 5. CLI Integration

### 5.1 Session Commands

**bitbot session new**:
```bash
bitbot session new <name>       # Create new session
bitbot session new feature-x    # Creates work-feature-x or setup-feature-x

# Options
--directory <path>              # Start in specific directory
--window <name>                 # Create initial window with name
```

**bitbot session list**:
```bash
bitbot session list             # List all sessions in current mode

# Output format
# NAME            CREATED              WINDOWS  ATTACHED
# work-main       2025-10-17 10:00     3        yes
# work-feature-x  2025-10-17 11:00     2        no
```

**bitbot session attach**:
```bash
bitbot session attach <name>    # Attach to existing session
bitbot session attach main      # Attach to work-main/setup-main

# Short form
bitbot attach <name>
```

**bitbot session kill**:
```bash
bitbot session kill <name>      # Kill session
bitbot session kill feature-x   # Kills work-feature-x or setup-feature-x

# Options
--save                          # Save before killing
--all                           # Kill all sessions (except current)
```

**bitbot session rename**:
```bash
bitbot session rename <old> <new>
bitbot session rename feature-x feature-y
```

### 5.2 Session Lifecycle Commands

**bitbot session save**:
```bash
bitbot session save             # Save current session
bitbot session save --all       # Save all sessions
bitbot session save --name <name>  # Save specific session
```

**bitbot session restore**:
```bash
bitbot session restore                      # Restore last save
bitbot session restore --timestamp <ts>     # Restore specific save
bitbot session restore --list               # List available saves
```

---

## 6. VS Code Integration

### 6.1 VS Code Remote Sessions

**VS Code terminal integration**:
- VS Code attaches to container
- Integrated terminal uses existing tmux session
- Or creates new VS Code-specific session

**Session naming for VS Code**:
```bash
# Automatic session for VS Code
work-vscode-1
work-vscode-2

# Or attach to existing
work-main (shared between CLI and VS Code terminal)
```

### 6.2 VS Code Launch Options

**Attach to existing session**:
```bash
bitbot work --vscode --attach main
# Opens VS Code, terminal attaches to work-main
```

**New VS Code session**:
```bash
bitbot work --vscode --session vscode-1
# Opens VS Code, creates work-vscode-1 session
```

---

## 7. AI Agent Session Management

### 7.1 Agent Sessions

**AI agent runs in session context**:
```bash
# User starts AI agent in session
bitbot work
tmux attach -t work-main

# Inside tmux session
claude-code "implement feature"
# AI agent sees session context, can create panes/windows
```

**Agent session awareness**:
- AI can detect current tmux session
- Can create new windows/panes within session
- Can run commands in background panes
- Respects session working directory

### 7.2 Agent Session Commands

**AI creates pane**:
```python
# Pseudocode for AI agent
def run_test_in_background():
  tmux("split-window", "-h")        # Create horizontal split
  tmux("send-keys", "pytest tests/", "C-m")  # Run tests
  tmux("select-pane", "-L")         # Return to original pane
```

**AI creates window**:
```python
def run_server():
  tmux("new-window", "-n", "server")  # Create window named "server"
  tmux("send-keys", "npm run dev", "C-m")
  tmux("select-window", "-t", "1")    # Return to original window
```

---

## 8. Session State Management

### 8.1 Session State Storage

**What gets saved**:
- Window layout and names
- Pane splits and sizes
- Working directories per pane
- Running processes (optional, via tmux-resurrect)
- Environment variables (per session)
- Command history (per pane)

**What doesn't get saved**:
- Actual process state (processes restart on restore)
- Terminal scrollback beyond tmux history limit
- Unsaved file buffers (vim/emacs)

### 8.2 State Files

**Session state file** (`.bitbot/sessions/work/last.txt`):
```
pane    0   1   :bash   1   :*  1   :/workspace  1 bash
pane    0   2   :vim    0   :-  1   :/workspace/src  1 vim src/main.py
window  0   1   1   :*  a1b2  :bash
window  0   2   0   :-  c3d4  :vim
state   0
```

**Metadata file** (`.bitbot/sessions/work/session_metadata.json`):
```json
{
  "last_save": "2025-10-17T12:30:00Z",
  "sessions": ["work-main", "work-feature-x"],
  "autosave_enabled": true,
  "autosave_interval_minutes": 15
}
```

---

## 9. Configuration

### 9.1 Session Configuration

**Global config** (`~/.bitbot/config.yml`):
```yaml
sessions:
  autosave: true
  autosave_interval_minutes: 15
  resurrect_pane_contents: true
  history_limit: 50000
  default_shell: /bin/zsh
  mouse_support: true
```

**Workspace config** (`.bitbot/config.yml`):
```yaml
sessions:
  # Override global settings for this workspace
  autosave_interval_minutes: 10

  # Default sessions to create
  default_sessions:
    - name: main
      windows:
        - name: editor
          directory: /workspace
        - name: terminal
          directory: /workspace
    - name: server
      windows:
        - name: dev-server
          directory: /workspace
          command: npm run dev
```

### 9.2 Per-Session Configuration

**Session-specific config** (in session):
```bash
# Set session-specific environment
tmux setenv -t work-main NODE_ENV development
tmux setenv -t work-main DEBUG true

# Set working directory for new windows
tmux set-option -t work-main default-path /workspace/src
```

---

## 10. Error Handling

### 10.1 Session Recovery

**Session lost** (container deleted):
```bash
# On next container start
bitbot work
# Auto-restores sessions from .bitbot/sessions/work/last.txt
# If restore fails, creates default session
```

**Corrupted session state**:
```bash
# Fallback to default session
if restore_failed:
  log_error("Failed to restore sessions, creating default")
  create_default_session(mode)
  backup_corrupted_state()
```

**Conflicting session names**:
```bash
# User tries to create existing session
bitbot session new main
# Error: Session 'work-main' already exists
# Use: bitbot session attach main
```

### 10.2 Container Restart Scenarios

**Clean shutdown**:
```bash
# User stops container
bitbot stop
  → Auto-save all sessions
  → Graceful shutdown
  → Next start restores sessions
```

**Unexpected shutdown**:
```bash
# Container killed/crashed
# Last autosave used (max 15 min old)
# May lose recent work since last autosave
```

**Forced recreation**:
```bash
# Container deleted and recreated
# Sessions restored from .bitbot/sessions/ (persisted on host)
# No data loss
```

---

## 11. Performance Considerations

### 11.1 Resource Usage

**Per session overhead**:
- tmux session: ~5MB RAM
- 10 sessions: ~50MB RAM
- Negligible CPU usage

**Session save/restore**:
- Save: <1 second per session
- Restore: <2 seconds for 10 sessions
- Autosave: Runs in background, no user impact

### 11.2 Limits

**Recommended limits**:
- Max sessions per container: 20
- Max windows per session: 10
- Max panes per window: 6
- History per pane: 50,000 lines

**Why limits**:
- Performance degradation with too many sessions
- tmux session list becomes unwieldy
- User cognitive load

---

## 12. Testing Strategy

### 12.1 Session Lifecycle Tests

- SL-01: Create default session on container start
- SL-02: Create new named session
- SL-03: Attach to existing session
- SL-04: Kill session
- SL-05: Rename session
- SL-06: List all sessions

### 12.2 Persistence Tests

- PS-01: Auto-save sessions every 15 minutes
- PS-02: Manual save session
- PS-03: Restore sessions on container start
- PS-04: Restore from specific timestamp
- PS-05: Handle corrupted session state

### 12.3 Multi-Session Tests

- MS-01: Multiple tmux sessions in same container
- MS-02: CLI + VS Code concurrent sessions
- MS-03: Work + Setup parallel sessions
- MS-04: Session isolation between modes

### 12.4 Integration Tests

- INT-01: VS Code terminal attaches to session
- INT-02: AI agent creates panes/windows
- INT-03: Session config respected
- INT-04: Session state persists across restarts

---

## 13. Success Criteria

**Functional**:
- [ ] Default session created on container start
- [ ] Users can create/attach/kill named sessions
- [ ] Sessions persist across container restarts
- [ ] Multiple concurrent sessions work
- [ ] VS Code integration works
- [ ] AI agents can manage sessions

**Reliability**:
- [ ] Auto-save every 15 minutes
- [ ] Session restore after crash (max 15 min loss)
- [ ] Corrupted state handled gracefully
- [ ] Session isolation per mode

**Usability**:
- [ ] Simple CLI commands (bitbot session ...)
- [ ] Clear session listing
- [ ] Fast save/restore (<2 seconds)
- [ ] Session state visible to user

---

## 14. Implementation Phases

**Phase 1: Basic Sessions**:
- Default session on container start
- tmux configuration
- Basic session commands (new, attach, list, kill)

**Phase 2: Persistence**:
- tmux-resurrect integration
- Auto-save mechanism
- Restore on container start
- Manual save/restore commands

**Phase 3: Multi-Session**:
- Named sessions
- Session isolation per mode
- Concurrent session support
- Session metadata tracking

**Phase 4: Integration**:
- VS Code session integration
- AI agent session awareness
- Configuration system
- Session templates

---

## 15. References

**Related Specifications**:
- SPEC-01: Container Orchestration (session per container)
- SPEC-02: Security Mode System (session isolation per mode)
- SPEC-05: Cross-Platform CLI (bitbot session commands)
- SPEC-06: VS Code Integration (VS Code sessions)
- SPEC-07: AI Agent Integration (agent session management)

**External Tools**:
- tmux: https://github.com/tmux/tmux
- tmux-resurrect: https://github.com/tmux-plugins/tmux-resurrect
- tmux Plugin Manager: https://github.com/tmux-plugins/tpm

**Research Sources**:
- User requirement: Session persistence across container restarts
- tmux best practices for container environments

---

**Status**: **Draft**
**Implementation Priority**: P0 (Blocking for user workflows)
**Next Steps**: SPEC-05 (Cross-Platform CLI)
