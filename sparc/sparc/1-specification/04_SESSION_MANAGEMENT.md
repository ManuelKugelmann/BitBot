# Session Management Specification

**Feature ID**: SPEC-04
**Priority**: P1 (Important)
**Status**: Approved
**Depends On**: SPEC-01 (Container Orchestration), SPEC-02 (Security Modes)
**Created**: 2025-10-20
**Last Updated**: 2025-10-20

---

## Executive Summary

tmux-based session management with auto-timestamped sessions and persistence across container restarts. Supports multiple parallel sessions per workspace with mode-specific contexts and seamless resumption.

**Key Decision (D-06)**: tmux with auto-timestamped sessions provides reliable session management without user complexity.

---

## 1. Session Architecture

### 1.1 Session Design Principles

**Auto-Timestamped Sessions**:
- Sessions created with timestamp: `2025-10-20_14-23-45`
- No user naming required (but supported)
- Automatic session detection and resumption
- Hidden complexity, simple user experience

**Mode-Specific Sessions**:
- Work container: Work-focused sessions
- Setup container: Infrastructure-focused sessions
- Independent session namespaces per mode
- Different tmux configurations per mode

### 1.2 Session Storage

```
.bitbot/sessions/
├── active/                     # Currently active sessions
│   ├── work-2025-10-20_14-23-45.json
│   └── setup-2025-10-20_15-30-12.json
├── detached/                   # Detached sessions
│   ├── work-2025-10-20_10-15-30.json
│   └── work-2025-10-19_16-45-22.json
└── tmux/                       # tmux session state
    ├── work-sessions.conf
    └── setup-sessions.conf
```

---

## 2. Session Lifecycle

### 2.1 Container Startup Session Flow

**Work Container Startup**:
```bash
#!/bin/bash
# /opt/bitbot/session-startup.sh

SESSION_DIR="/workspace/.bitbot/sessions"
MODE="${BITBOT_MODE:-work}"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

echo "=== BitBot Session Management ($MODE mode) ==="

# Check for existing detached sessions
DETACHED_SESSIONS=$(find "$SESSION_DIR/detached" -name "${MODE}-*.json" 2>/dev/null | wc -l)

if [ "$DETACHED_SESSIONS" -eq 0 ]; then
    # No existing sessions - create new one
    SESSION_NAME="${MODE}-${TIMESTAMP}"
    echo "Creating new session: $SESSION_NAME"

    tmux new-session -d -s "$SESSION_NAME" -c /workspace

    # Save session metadata
    cat > "$SESSION_DIR/active/${SESSION_NAME}.json" <<EOF
{
  "session_name": "$SESSION_NAME",
  "mode": "$MODE",
  "created": "$(date -Iseconds)",
  "last_accessed": "$(date -Iseconds)",
  "workspace_hash": "${WORKSPACE_HASH}",
  "tmux_session": "$SESSION_NAME"
}
EOF

elif [ "$DETACHED_SESSIONS" -eq 1 ]; then
    # Single detached session - auto-resume
    SESSION_FILE=$(find "$SESSION_DIR/detached" -name "${MODE}-*.json" | head -1)
    SESSION_NAME=$(basename "$SESSION_FILE" .json)

    echo "Resuming session: $SESSION_NAME"

    # Move from detached to active
    mv "$SESSION_FILE" "$SESSION_DIR/active/"

    # Update last accessed time
    jq '.last_accessed = now | strftime("%Y-%m-%dT%H:%M:%S%z")' \
       "$SESSION_DIR/active/${SESSION_NAME}.json" > \
       "$SESSION_DIR/active/${SESSION_NAME}.json.tmp" && \
       mv "$SESSION_DIR/active/${SESSION_NAME}.json.tmp" \
          "$SESSION_DIR/active/${SESSION_NAME}.json"

else
    # Multiple detached sessions - show menu
    echo "Multiple detached sessions found:"
    echo ""

    find "$SESSION_DIR/detached" -name "${MODE}-*.json" | while read -r session_file; do
        session_name=$(basename "$session_file" .json)
        created=$(jq -r '.created' "$session_file")
        echo "  $session_name (created: $created)"
    done

    echo ""
    echo "Options:"
    echo "  1. Resume a session (choose from list)"
    echo "  2. Create new session"
    echo "  3. List session details"
    echo ""
    read -p "Choice (1/2/3): " choice

    case "$choice" in
        1)
            # Interactive session selection
            select_session_interactive "$MODE"
            ;;
        2)
            # Create new session
            SESSION_NAME="${MODE}-${TIMESTAMP}"
            create_new_session "$SESSION_NAME"
            ;;
        3)
            # Show session details
            show_session_details "$MODE"
            select_session_interactive "$MODE"
            ;;
        *)
            echo "Invalid choice, creating new session"
            SESSION_NAME="${MODE}-${TIMESTAMP}"
            create_new_session "$SESSION_NAME"
            ;;
    esac
fi

echo "Session ready. Use 'bitbot done' to save and exit."
echo "=================================="
```

### 2.2 Session Resume Logic

**Interactive Session Selection**:
```bash
#!/bin/bash
# Function: select_session_interactive

select_session_interactive() {
    local mode="$1"
    local sessions=()

    # Build session array
    while IFS= read -r -d '' session_file; do
        session_name=$(basename "$session_file" .json)
        created=$(jq -r '.created' "$session_file")
        last_accessed=$(jq -r '.last_accessed' "$session_file")
        sessions+=("$session_name|$created|$last_accessed")
    done < <(find ".bitbot/sessions/detached" -name "${mode}-*.json" -print0)

    # Display sessions with context
    echo "Available sessions:"
    for i in "${!sessions[@]}"; do
        IFS='|' read -r name created accessed <<< "${sessions[$i]}"
        echo "  $((i+1)). $name"
        echo "     Created: $created"
        echo "     Last accessed: $accessed"
        echo ""
    done

    read -p "Select session (1-${#sessions[@]}): " selection

    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#sessions[@]}" ]; then
        selected_session=$(echo "${sessions[$((selection-1))]}" | cut -d'|' -f1)
        resume_session "$selected_session"
    else
        echo "Invalid selection"
        return 1
    fi
}
```

### 2.3 Session Save and Exit

**Session Save on Container Stop**:
```bash
#!/bin/bash
# /opt/bitbot/session-save.sh

save_active_sessions() {
    local mode="${BITBOT_MODE:-work}"

    # Find active sessions for this mode
    find ".bitbot/sessions/active" -name "${mode}-*.json" | while read -r session_file; do
        session_name=$(basename "$session_file" .json)

        if tmux has-session -t "$session_name" 2>/dev/null; then
            echo "Saving session: $session_name"

            # Update last accessed time
            jq '.last_accessed = now | strftime("%Y-%m-%dT%H:%M:%S%z")' \
               "$session_file" > "${session_file}.tmp" && \
               mv "${session_file}.tmp" "$session_file"

            # Move to detached
            mv "$session_file" ".bitbot/sessions/detached/"

            # Save tmux session state (optional, for advanced restoration)
            tmux capture-pane -t "$session_name" -p > \
                ".bitbot/sessions/tmux/${session_name}-capture.txt" 2>/dev/null || true
        fi
    done
}

# Run on container stop
trap save_active_sessions EXIT
```

---

## 3. tmux Configuration

### 3.1 BitBot tmux Config

**Work Mode tmux config** (`.bitbot/tmux/work.conf`):
```bash
# BitBot Work Mode tmux Configuration

# Prefix key
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Session settings
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# Status bar
set -g status-bg colour235
set -g status-fg colour250
set -g status-left '#[fg=colour76][BitBot Work] '
set -g status-left-length 20
set -g status-right '#[fg=colour244]%Y-%m-%d %H:%M #[fg=colour76]#{session_name}'
set -g status-right-length 50

# Window titles
setw -g window-status-current-format '#[fg=colour76,bold]#I:#W'
setw -g window-status-format '#[fg=colour244]#I:#W'

# Pane borders
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=colour76

# Key bindings
bind r source-file ~/.tmux.conf \\; display-message "Config reloaded"
bind | split-window -h
bind - split-window -v

# Mouse support
set -g mouse on

# BitBot specific bindings
bind B new-window -n "bitbot" "bitbot --help"
bind G new-window -n "git" "git status"
bind A new-window -n "ai" "claude-code"
```

**Setup Mode tmux config** (`.bitbot/tmux/setup.conf`):
```bash
# BitBot Setup Mode tmux Configuration

# Prefix key
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Status bar (different color for setup mode)
set -g status-bg colour52
set -g status-fg colour250
set -g status-left '#[fg=colour208][BitBot Setup] '
set -g status-left-length 20
set -g status-right '#[fg=colour244]%Y-%m-%d %H:%M #[fg=colour208]#{session_name}'

# Window titles (orange for setup)
setw -g window-status-current-format '#[fg=colour208,bold]#I:#W'
setw -g window-status-format '#[fg=colour244]#I:#W'

# Pane borders (orange for setup)
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=colour208

# BitBot Setup specific bindings
bind S new-window -n "setup-audit" "bitbot-audit-setup"
bind D new-window -n "devcontainer" "code .devcontainer/"
bind C new-window -n "compose" "code .bitbot/mcp/docker-compose.yml"
```

### 3.2 Session Templates

**Default Window Layout**:
```bash
#!/bin/bash
# /opt/bitbot/session-template.sh

setup_work_session() {
    local session_name="$1"

    # Main development window
    tmux new-window -t "$session_name:1" -n "main" -c /workspace

    # Git window
    tmux new-window -t "$session_name:2" -n "git" -c /workspace
    tmux send-keys -t "$session_name:2" "git status" Enter

    # AI assistant window (if configured)
    if command -v claude-code >/dev/null 2>&1; then
        tmux new-window -t "$session_name:3" -n "ai" -c /workspace
        tmux send-keys -t "$session_name:3" "claude-code" Enter
    fi

    # Logs/monitoring window
    tmux new-window -t "$session_name:4" -n "logs" -c /workspace
    tmux send-keys -t "$session_name:4" "tail -f .bitbot/logs/*.log" Enter

    # Select main window
    tmux select-window -t "$session_name:1"
}

setup_setup_session() {
    local session_name="$1"

    # Main setup window
    tmux new-window -t "$session_name:1" -n "setup" -c /setup/workspace

    # DevContainer editing
    tmux new-window -t "$session_name:2" -n "devcontainer" -c /setup/workspace/.devcontainer

    # Docker/Compose management
    tmux new-window -t "$session_name:3" -n "docker" -c /setup/workspace
    tmux send-keys -t "$session_name:3" "docker ps" Enter

    # Select main window
    tmux select-window -t "$session_name:1"
}
```

---

## 4. CLI Integration

### 4.1 Session Commands

**Inside Container Commands**:
```bash
#!/bin/bash
# bitbot session management (inside container)

case "${1:-attach}" in
    list)
        echo "Active sessions:"
        find .bitbot/sessions/active -name "*.json" | while read -r f; do
            name=$(basename "$f" .json)
            created=$(jq -r '.created' "$f")
            echo "  $name (created: $created)"
        done

        echo ""
        echo "Detached sessions:"
        find .bitbot/sessions/detached -name "*.json" | while read -r f; do
            name=$(basename "$f" .json)
            created=$(jq -r '.created' "$f")
            last_accessed=$(jq -r '.last_accessed' "$f")
            echo "  $name (created: $created, accessed: $last_accessed)"
        done
        ;;

    new)
        session_name="${BITBOT_MODE:-work}-$(date +%Y-%m-%d_%H-%M-%S)"
        if [ -n "$2" ]; then
            session_name="${BITBOT_MODE:-work}-$2"
        fi

        echo "Creating new session: $session_name"
        tmux new-session -d -s "$session_name" -c /workspace

        # Save session metadata
        mkdir -p .bitbot/sessions/active
        cat > ".bitbot/sessions/active/${session_name}.json" <<EOF
{
  "session_name": "$session_name",
  "mode": "${BITBOT_MODE:-work}",
  "created": "$(date -Iseconds)",
  "last_accessed": "$(date -Iseconds)",
  "workspace_hash": "${WORKSPACE_HASH}",
  "tmux_session": "$session_name",
  "user_named": $([ -n "$2" ] && echo "true" || echo "false")
}
EOF

        # Attach to new session
        tmux attach-session -t "$session_name"
        ;;

    attach)
        if [ -n "$2" ]; then
            # Attach to specific session
            session_name="$2"
            if [[ "$session_name" != *"-"* ]]; then
                # If no mode prefix, add current mode
                session_name="${BITBOT_MODE:-work}-$session_name"
            fi

            if tmux has-session -t "$session_name" 2>/dev/null; then
                tmux attach-session -t "$session_name"
            else
                echo "Session not found: $session_name"
                echo "Available sessions:"
                tmux list-sessions 2>/dev/null | sed 's/^/  /'
            fi
        else
            # Auto-attach logic
            current_sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep "^${BITBOT_MODE:-work}-" | wc -l)

            if [ "$current_sessions" -eq 1 ]; then
                # Single session - attach to it
                session_name=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep "^${BITBOT_MODE:-work}-")
                tmux attach-session -t "$session_name"
            elif [ "$current_sessions" -gt 1 ]; then
                # Multiple sessions - show selection
                echo "Multiple sessions available:"
                tmux list-sessions -F '#{session_name}: #{session_created}' 2>/dev/null | grep "^${BITBOT_MODE:-work}-"
                echo ""
                echo "Use: bitbot session attach <session-name>"
            else
                # No sessions - create default
                echo "No sessions found, creating new session"
                bitbot session new
            fi
        fi
        ;;

    kill)
        if [ -n "$2" ]; then
            session_name="$2"
            if [[ "$session_name" != *"-"* ]]; then
                session_name="${BITBOT_MODE:-work}-$session_name"
            fi

            if tmux has-session -t "$session_name" 2>/dev/null; then
                tmux kill-session -t "$session_name"
                rm -f ".bitbot/sessions/active/${session_name}.json"
                rm -f ".bitbot/sessions/detached/${session_name}.json"
                echo "Session killed: $session_name"
            else
                echo "Session not found: $session_name"
            fi
        else
            echo "Usage: bitbot session kill <session-name>"
        fi
        ;;

    *)
        echo "Usage: bitbot session {list|new [name]|attach [name]|kill <name>}"
        ;;
esac
```

### 4.2 Host-Level Session Management

**Host Commands**:
```bash
#!/bin/bash
# bitbot session management (from host)

case "$1" in
    sessions)
        # Show sessions across all workspaces
        for workspace in ~/.bitbot/workspaces/*/; do
            if [ -d "$workspace/sessions" ]; then
                workspace_name=$(basename "$workspace")
                echo "Workspace: $workspace_name"

                find "$workspace/sessions/active" -name "*.json" 2>/dev/null | while read -r f; do
                    name=$(basename "$f" .json)
                    mode=$(jq -r '.mode' "$f")
                    created=$(jq -r '.created' "$f")
                    echo "  [ACTIVE] $name ($mode, $created)"
                done

                find "$workspace/sessions/detached" -name "*.json" 2>/dev/null | while read -r f; do
                    name=$(basename "$f" .json)
                    mode=$(jq -r '.mode' "$f")
                    created=$(jq -r '.created' "$f")
                    echo "  [DETACHED] $name ($mode, $created)"
                done

                echo ""
            fi
        done
        ;;

    cleanup)
        # Clean up old detached sessions
        find ~/.bitbot/workspaces/*/sessions/detached -name "*.json" -mtime +7 | while read -r old_session; do
            session_name=$(basename "$old_session" .json)
            echo "Removing old session: $session_name"
            rm "$old_session"
        done
        ;;
esac
```

---

## 5. VS Code Integration

### 5.1 VS Code Terminal Sessions

**Integrated Terminal Detection**:
```bash
#!/bin/bash
# Detect if running in VS Code integrated terminal

if [ "$TERM_PROGRAM" = "vscode" ]; then
    # Running in VS Code integrated terminal
    # Use simpler session management
    echo "VS Code terminal detected - using integrated session management"

    # Don't auto-create tmux sessions in VS Code terminal
    # VS Code handles terminal persistence
    export BITBOT_VSCODE_MODE=true
else
    # Running in external terminal
    # Use full tmux session management
    start_tmux_session_management
fi
```

### 5.2 DevContainer Session Persistence

**VS Code DevContainer Persistence**:
```json
// .vscode/settings.json
{
  "terminal.integrated.cwd": "/workspace",
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "/bin/bash",
      "args": ["-l"],
      "env": {
        "BITBOT_VSCODE_MODE": "true"
      }
    },
    "bitbot-session": {
      "path": "/opt/bitbot/session-attach.sh",
      "args": [],
      "icon": "terminal"
    }
  }
}
```

---

## 6. Advanced Features

### 6.1 Session Tagging and Context

**AI-Assisted Session Tagging** (Future):
```bash
# AI suggests session names based on work context
bitbot session tag-suggest
# Output: "authentication-refactor" (based on recent file changes)

# Manual tagging
bitbot session tag "working-on-auth-bug"
```

**Session Context Preservation**:
```json
// Session metadata with context
{
  "session_name": "work-2025-10-20_14-23-45",
  "user_tag": "authentication-refactor",
  "ai_suggested_tag": "auth-system-changes",
  "context": {
    "files_modified": ["src/auth.py", "tests/test_auth.py"],
    "git_branch": "feature/auth-refactor",
    "last_command": "pytest tests/test_auth.py",
    "working_directory": "/workspace/src"
  }
}
```

### 6.2 Session Sharing and Collaboration

**Session Export/Import** (Future):
```bash
# Export session for sharing
bitbot session export work-feature-x > session-export.json

# Import session on different machine
bitbot session import session-export.json
```

---

## 7. Success Criteria

**Functional Requirements**:
- [ ] Auto-timestamped sessions created on container start
- [ ] Single detached session auto-resumes
- [ ] Multiple detached sessions show interactive menu
- [ ] Session state persists across container restarts
- [ ] Different tmux configs for work vs setup modes
- [ ] Session metadata tracked in JSON files

**Usability Requirements**:
- [ ] Simple session management commands
- [ ] Clear indication of current session and mode
- [ ] Easy switching between sessions
- [ ] VS Code integration works seamlessly

**Reliability Requirements**:
- [ ] Sessions never lost due to container restarts
- [ ] Session save/restore is atomic
- [ ] Corrupted session files don't break startup
- [ ] Session cleanup removes old sessions automatically

---

## 8. References

**Related Specifications**:
- SPEC-00: Architectural Decisions (D-06: Session management strategy)
- SPEC-01: Container Orchestration (session integration with containers)
- SPEC-02: Security Mode System (mode-specific sessions)
- SPEC-06: VS Code DevContainer Integration

**External References**:
- tmux documentation: https://github.com/tmux/tmux/wiki
- VS Code DevContainer terminals: https://code.visualstudio.com/docs/remote/containers

---

**Status**: **Approved**
**Implementation Priority**: P1 (Important for developer workflow)
**Next Steps**: Implement SPEC-05 (Cross-Platform CLI)