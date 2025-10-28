# Session Management Specification

**Feature ID**: SPEC-04
**Priority**: P1 (Important)
**Status**: Implemented
**Depends On**: None (Claude Code native feature)
**Created**: 2025-10-20
**Last Updated**: 2025-10-28

---

## Executive Summary

Claude Code session tracking via hooks with session ID and PID management. Enables session-aware skills (restart, compact, resume) without additional infrastructure.

**Key Decision**: Leverage Claude Code's built-in session management instead of implementing custom tmux-based sessions.

---

## 1. Implementation Overview

### 1.1 Design Principles

**Session Tracking**:
- Use Claude Code's native session IDs (UUID format)
- Track Claude process PID for session control
- Store session state in `.bitbot/wrapper/` for inter-process communication
- No custom session persistence needed (Claude Code handles this)

**Hook-Based Architecture**:
- SessionStart: Capture session ID and PID at startup
- SessionEnd: Clean up session state files
- UserPromptSubmit: Optional hook for user interaction tracking
- Stop: Control continuous workflow behavior (do-not-stop feature)

### 1.2 Session State Storage

```
.bitbot/wrapper/
├── .wrapper-session-{PID}.state    # Session state for PID
├── .gitignore                       # Ignore all .wrapper-session-* files
└── DO-NOT-STOP.txt                  # Stop hook control file
```

**Session State Format** (`.wrapper-session-{PID}.state`):
```bash
SESSION_ID=4c02986e-41d4-4b5f-829a-b097ee844a8e
IS_RESUME=start     # or "resume"
START_TIME=1735410000
```

---

## 2. Hook Implementation

### 2.1 SessionStart Hook

**File**: `.bitbot/hooks/session-start.sh`

**Purpose**: Capture session ID and PID at Claude Code startup

**Inputs**:
- JSON via stdin with `session_id` and `is_resume` fields
- `CLAUDE_ENV_FILE` environment variable (provided by Claude Code)

**Outputs**:
- Exports `CLAUDE_SESSION_ID`, `CLAUDE_PID`, `CLAUDE_PROJECT_DIR` to env file
- Echoes session info: `SessionStart:{start|resume} - Session: {ID}, PID: {PID}`
- Creates `.bitbot/wrapper/.wrapper-session-{PID}.state` file

**Key Features**:
- Detects resume vs new session
- Finds Claude PID via process tree inspection
- Stores state for wrapper script access
- Validates it's being run by Claude Code (not standalone)

### 2.2 SessionEnd Hook

**File**: `.bitbot/hooks/session-end.sh`

**Purpose**: Clean up session state files when Claude exits

**Behavior**:
- Removes `.wrapper-session-{PID}.state` file for current session
- Cleans up old state files for non-running PIDs

### 2.3 Stop Hook (Do-Not-Stop)

**File**: `.bitbot/hooks/do-not-stop.sh`

**Purpose**: Enable continuous workflow automation

**Behavior**:
- Reads `.bitbot/DO-NOT-STOP.txt` for continuation instructions
- If file exists and not empty: continues with specified reason
- If file doesn't exist or empty: allows normal stop
- Prevents infinite loops with `stop_hook_active` check

**Control Files**:
- `.bitbot/DO-NOT-STOP.txt` - Global control (deprecated)
- `.bitbot/DONOTSTOP-{reason}.txt` - Session-specific control

### 2.4 Session Utilities

**File**: `.bitbot/hooks/session-utils.sh`

**Shared Functions**:
- `find_claude_pid()` - Locate Claude process PID
- `find_project_root()` - Locate BitBot project root
- `get_session_id()` - Read session ID from wrapper state

---

## 3. Skills Integration

### 3.1 claude-restart Skill

**Purpose**: Restart Claude Code session while maintaining context

**Modes**:
- `resume` (default) - Restart and resume session
- `compact` - Compact context before resuming (future)
- `clear` - Clear context and start fresh (future)

**Implementation**:
```bash
# Find current Claude PID
source .bitbot/hooks/session-utils.sh
CLAUDE_PID=$(find_claude_pid)

# Kill Claude process
kill $CLAUDE_PID

# Exec restart to launch new Claude
exec claude --resume $CLAUDE_SESSION_ID
```

### 3.2 claude-get-session-info Skill

**Purpose**: Shared utility for getting session ID and PID

**Usage**: Sourced by other skills needing session info

**Exports**:
- `CLAUDE_PID` - Current Claude process ID
- `SESSION_ID` - Current session UUID

### 3.3 Session-Aware Skills

Skills that use session info:
- `claude-restart` - Restart current session
- `claude-do-not-stop` - Enable automation for session
- `claude-allow-stop` - Disable automation for session

---

## 4. Configuration

### 4.1 Hook Registration

**File**: `.claude/settings.json`

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": ".bitbot/hooks/session-start.sh",
        "timeout": 5000
      }]
    }],
    "SessionEnd": [{
      "hooks": [{
        "type": "command",
        "command": ".bitbot/hooks/session-end.sh",
        "timeout": 5000
      }]
    }],
    "UserPromptSubmit": [{
      "hooks": [{
        "type": "command",
        "command": ".bitbot/hooks/user-prompt-submit.sh",
        "timeout": 10000
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": ".bitbot/hooks/do-not-stop.sh",
        "timeout": 5000
      }]
    }]
  },
  "permissions": {
    "allow": []
  }
}
```

### 4.2 Git Ignore

**File**: `.bitbot/wrapper/.gitignore`

```
# Ignore all wrapper session state files
.wrapper-session-*.state
```

**File**: `.bitbot/.gitignore`

```
# Session control files (per-user preference)
DO-NOT-STOP.txt
DONOTSTOP-*.txt
```

---

## 5. Process Flow

### 5.1 Session Startup Flow

```mermaid
graph TD
    A[Claude Code Starts] --> B{SessionStart Hook}
    B --> C[Read JSON from stdin]
    C --> D[Extract session_id]
    D --> E[Find Claude PID]
    E --> F[Check is_resume flag]
    F --> G{Resume?}
    G -->|Yes| H[Echo: SessionStart:resume]
    G -->|No| I[Echo: SessionStart:start]
    H --> J[Export env vars to CLAUDE_ENV_FILE]
    I --> J
    J --> K[Write wrapper state file]
    K --> L[Claude Code Ready]

    style A fill:#4a9eff,stroke:#333,stroke-width:2px
    style G fill:#ffa726,stroke:#333,stroke-width:2px,color:#333
    style L fill:#66bb6a,stroke:#333,stroke-width:2px,color:#333
```

### 5.2 Session Restart Flow

```mermaid
graph TD
    A[User: /claude-restart] --> B[claude-restart skill]
    B --> C[Source session-utils.sh]
    C --> D[Get CLAUDE_PID]
    D --> E[Get SESSION_ID from state]
    E --> F[Kill Claude process PID]
    F --> G[Exec: claude --resume SESSION_ID]
    G --> H[SessionStart hook triggered]
    H --> I[Session resumed with history]

    style A fill:#4a9eff,stroke:#333,stroke-width:2px
    style B fill:#ffa726,stroke:#333,stroke-width:2px,color:#333
    style I fill:#66bb6a,stroke:#333,stroke-width:2px,color:#333
```

### 5.3 Stop Hook (Do-Not-Stop) Flow

```mermaid
graph TD
    A[Claude finishes response] --> B{Stop Hook}
    B --> C{DO-NOT-STOP.txt exists?}
    C -->|No| D[Normal stop]
    C -->|Yes| E{File empty?}
    E -->|Yes| D
    E -->|No| F[Read continuation reason]
    F --> G{stop_hook_active check}
    G -->|Active| D
    G -->|Not Active| H[Continue with reason]
    H --> I[Claude continues working]

    style A fill:#4a9eff,stroke:#333,stroke-width:2px
    style C fill:#ffa726,stroke:#333,stroke-width:2px,color:#333
    style E fill:#ffa726,stroke:#333,stroke-width:2px,color:#333
    style G fill:#ffa726,stroke:#333,stroke-width:2px,color:#333
    style D fill:#66bb6a,stroke:#333,stroke-width:2px,color:#333
    style I fill:#66bb6a,stroke:#333,stroke-width:2px,color:#333
```

---

## 6. Future Enhancements

**Context Management**:
- Compact context before resume (reduce token usage)
- Clear context option (fresh start with session history)
- Auto-compact on low token budget

**Session Metadata**:
- Track session duration
- Log session activity (commands run, files modified)
- Session tagging/naming

**Multi-Session Support**:
- Parallel Claude sessions (different workspaces)
- Session switching
- Session list/management commands

---

## 7. Success Criteria

**Functional Requirements**:
- [x] Session ID captured at startup
- [x] Claude PID tracked via process tree
- [x] Session state persists in wrapper files
- [x] SessionEnd cleans up state files
- [x] claude-restart skill works reliably
- [x] Do-not-stop hook enables automation

**Usability Requirements**:
- [x] Hooks work silently in background
- [x] Session info displayed at startup
- [x] Skills can access session info via utilities
- [x] No user configuration required

**Reliability Requirements**:
- [x] Hooks validate they're run by Claude Code
- [x] State files use unique PIDs (no conflicts)
- [x] Failed hook doesn't break Claude startup
- [x] Old state files cleaned up automatically

---

## 8. References

**Related Specifications**:
- SPEC-00: Architectural Decisions
- SPEC-07: AI Agent Integration (Claude Code skills)

**External References**:
- Claude Code Hooks: https://docs.claude.com/en/docs/claude-code/hooks
- Claude Code Skills: https://docs.claude.com/en/docs/claude-code/skills

---

**Status**: **Implemented**
**Next Steps**: Add context management features (compact/clear)
