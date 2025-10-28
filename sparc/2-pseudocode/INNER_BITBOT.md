# Container BitBot Pseudocode

**Component**: Container BitBot (runs inside containers)
**Source**: `container/bitbot/` directory
**Installed**: `/usr/local/bitbot/` inside containers
**Purpose**: AI agent assistance and session management inside devcontainers

---

## Overview

Container BitBot runs **inside** devcontainers with a layered architecture:

**Layer 1 (tmux)**: Session persistence
- Manage tmux sessions (create/attach)
- Smart launcher with session detection
- Detach/reattach capability
- Session naming: `bitbot-YYYYMMDD-HHMM`

**Layer 2 (wrapper)**: AI tool operations
- Launch Claude via wrapper
- Handle restart/resume/compact via IPC
- Process monitoring and watchdog

```
Container Entry → Container BitBot → tmux layer → wrapper layer → Claude Code
```

**Two-Layer Architecture**:
- **tmux**: Session management (bitbot commands)
- **wrapper**: AI tool operations (IPC commands)
- Complete independence between layers

**Future: Router Layer** (planned)
- Pre-wrapper routing to different AI tools
- Support for Claude, OpenCode, and other AI assistants
- Tool selection based on mode or user preference
- Wrapper becomes tool-agnostic

**Key Principle**: Separation of concerns - tmux for sessions, wrapper for AI tools

---

## Main Entry Point

```pseudocode
FUNCTION bitbot(command, args):
    # /usr/local/bitbot/bitbot
    # Main router for container bitbot commands
    # Mirrors outer bitbot structure (bitbot + core/)

    SET script_dir = get_script_directory()
    SET bitbot_container_home = script_dir

    # Source utilities
    SOURCE bitbot_container_home + "/core/util/helpers.sh"

    CASE command OF:
        "start":
            CALL start_claude_session(args)
        "resume":
            CALL resume_tmux_session(args)
        "help":
            CALL show_help()
        DEFAULT:
            # No command - use smart default launcher
            CALL default_command(args)
    END CASE
END FUNCTION
```

---

## Two-Layer Architecture

Container BitBot uses two completely independent layers:

### Layer 1: tmux (Session Persistence)

**Purpose**: Terminal session management

**Responsibilities**:
- Create tmux sessions: `tmux new-session -s name "command"`
- Attach to existing sessions: `tmux attach-session -t name`
- Detect available sessions
- Session naming: `bitbot-YYYYMMDD-HHMMSS`

**Key Points**:
- Uses `tmux new-session` with command parameter (NOT send-keys)
- Wrapper exec'd directly as the session command
- Single pane per session (no splitting within terminal)
- Multiple sessions possible across different terminals

### Layer 2: Wrapper (Claude Operations)

**Purpose**: Claude process management via IPC

**Location**: `/usr/local/bitbot/wrapper/`

**Components**:
- `claude-wrapper.sh` - Launch Claude with arguments
- `send-wrapper-command.sh` - Send IPC commands
- `watchdog.sh` - Monitor for stalls

**Responsibilities**:
- Launch Claude: `wrapper claude [args]`
- Handle IPC commands: restart, resume, compact, clear
- Monitor Claude process
- Named pipe communication: `/tmp/claude-wrapper-*.pipe`

**Key Points**:
- Completely independent of tmux
- IPC commands work whether in tmux or not
- No `tmux send-keys` usage anywhere

### Commands

Container BitBot provides three commands for session management:

| Command             | Behavior                                                                          |
| ------------------- | --------------------------------------------------------------------------------- |
| `bitbot` (no args)  | Smart default: 1 session=auto-resume, 2+ sessions=offer resume/new               |
| `bitbot start`      | Always create fresh tmux with fresh Claude (no prompts)                           |
| `bitbot resume`     | Intelligent: 0 tmux=new tmux+claude --resume, 1=auto-attach, 2+=menu            |

### Default Command (No Arguments)

```pseudocode
FUNCTION default_command(args):
    # Smart session launcher with detection and auto-selection
    # Called when: bitbot (no arguments)

    PRINT "BitBot - Claude Code Launcher"
    PRINT ""

    # Check for existing sessions
    SET existing_sessions = list_tmux_sessions()
    SET session_count = count(existing_sessions)

    # Single session - auto-resume (no menu)
    IF session_count == 1:
        SET single_session = existing_sessions[0]
        PRINT "Found one session: " + single_session.name
        PRINT ""
        PRINT "Auto-resuming..."
        PRINT ""
        CALL resume_tmux_session(single_session.name)
        RETURN
    END IF

    # Multiple sessions - show list and offer resume/new
    IF session_count > 1:
        PRINT "Found existing tmux sessions:"
        FOR EACH session IN existing_sessions:
            SET info = get_session_info(session.name)
            PRINT "  • " + info
        END FOR
        PRINT ""

        # Offer to resume
        CALL prompt_resume_or_new() → choice

        IF choice == "resume":
            CALL resume_tmux_session()
            RETURN
        END IF
    END IF

    # No existing sessions or user wants new session with launch mode choice
    CALL create_new_claude_session_with_choice(args)
END FUNCTION
```

### Start Command (New Session)

```pseudocode
FUNCTION start_command(args):
    # Always create new tmux session with wrapper
    # Called when: bitbot start [args]

    SET wrapper_script = "/usr/local/bitbot/wrapper/claude-wrapper.sh"
    SET session_name = "bitbot-" + current_timestamp()  # bitbot-YYYYMMDD-HHMMSS
    SET mode = get_bitbot_mode()
    SET workspace = get_workspace()

    PRINT "BitBot - Start New Session"
    PRINT ""

    # Check wrapper availability
    IF NOT file_exists(wrapper_script) OR NOT is_executable(wrapper_script):
        ERROR "Wrapper not found or not executable"
        PRINT ""
        PRINT "Expected location: " + wrapper_script
        PRINT ""
        PRINT "Check Dockerfile includes:"
        PRINT "  COPY container/bitbot/wrapper/ /usr/local/bitbot/wrapper/"
        PRINT "  RUN chmod +x /usr/local/bitbot/wrapper/*.sh"
        EXIT 1
    END IF

    # Check tmux availability
    IF NOT tmux_available():
        ERROR "tmux is not available"
        PRINT ""
        PRINT "Please install tmux:"
        PRINT "  apt-get update && apt-get install -y tmux"
        EXIT 1
    END IF

    INFO "Creating new tmux session: " + session_name
    INFO "Workspace: " + workspace
    INFO "Mode: " + mode
    PRINT ""

    # Create tmux session with wrapper as command (NO send-keys)
    EXEC "tmux new-session -s " + session_name + " '" + wrapper_script + " claude " + args + "'"
END FUNCTION
```

### Resume Command (Attach or Create)

```pseudocode
FUNCTION resume_tmux_session(session_name):
    # Smart resume: attach to existing or create new with claude --resume
    # Called when: bitbot resume [session-name]

    PRINT "BitBot - Resume Session"
    PRINT ""

    SET sessions = list_tmux_sessions()
    SET session_count = count(sessions)

    # No tmux sessions - create new with wrapper claude --resume
    IF session_count == 0:
        INFO "No unattached tmux sessions found"
        INFO "Creating new session with Claude --resume..."
        PRINT ""
        CALL create_tmux_with_wrapper_resume()
        RETURN
    END IF

    # Session name provided - try to attach directly
    IF session_name is not empty:
        IF session_exists(session_name):
            CALL resume_tmux_with_check(session_name)
            RETURN
        ELSE:
            ERROR "Session '" + session_name + "' not found"
            PRINT ""
            PRINT "Available sessions:"
            FOR EACH session IN sessions:
                PRINT "  • " + session.name
            END FOR
            EXIT 1
        END IF
    END IF

    # Single session - auto-attach (no menu)
    IF session_count == 1:
        SET single_session = sessions[0]
        PRINT "Found one session: " + single_session.name
        PRINT ""
        CALL resume_tmux_with_check(single_session.name)
        RETURN
    END IF

    # Multiple sessions - show menu
    CALL show_session_menu(sessions) → selected

    IF selected is not empty:
        PRINT ""
        CALL resume_tmux_with_check(selected)
    ELSE:
        PRINT "Cancelled"
        EXIT 0
    END IF
END FUNCTION
```

### Resume Helper Functions

```pseudocode
FUNCTION resume_tmux_with_check(session_name):
    # Attach to tmux session with Claude running check

    PRINT "Attaching to session '" + session_name + "'..."
    PRINT ""

    # Check if Claude is still running
    IF NOT check_claude_running(session_name):
        WARNING "Note: Claude Code appears to have exited in this session"
        PRINT ""
        PRINT "  To resume your Claude session:"
        PRINT "    claude --resume"
        PRINT ""
    END IF

    EXECUTE "tmux attach-session -t " + session_name
END FUNCTION
```

```pseudocode
FUNCTION check_claude_running(session_name) → boolean:
    # Check if Claude is running in tmux session

    # Get PIDs of all panes in session
    SET pids = EXECUTE_CAPTURE "tmux list-panes -t " + session_name + " -F '#{pane_pid}'"

    IF pids is empty:
        RETURN false
    END IF

    # Check if any process tree contains 'claude'
    FOR EACH pid IN pids:
        # Check main process
        SET cmd = EXECUTE_CAPTURE "ps -o command= -p " + pid
        IF cmd contains "claude":
            RETURN true
        END IF

        # Check child processes
        SET children = EXECUTE_CAPTURE "pgrep -P " + pid
        FOR EACH child_pid IN children:
            SET child_cmd = EXECUTE_CAPTURE "ps -o command= -p " + child_pid
            IF child_cmd contains "claude":
                RETURN true
            END IF
        END FOR
    END FOR

    RETURN false
END FUNCTION
```

```pseudocode
FUNCTION create_tmux_with_wrapper_resume():
    # Create new tmux session with wrapper claude --resume
    # Used when no tmux sessions exist but user wants to resume Claude

    SET wrapper_script = "/usr/local/bitbot/wrapper/claude-wrapper.sh"
    SET session_name = "claude-" + get_timestamp()
    SET mode = get_bitbot_mode()
    SET workspace = get_workspace()

    INFO "Claude will show its available sessions for you to select"
    PRINT ""

    # Show workspace info
    INFO "Workspace: " + workspace
    INFO "Mode: " + mode
    INFO "Session: " + session_name
    PRINT ""

    # Check wrapper availability
    IF NOT file_exists(wrapper_script) OR NOT is_executable(wrapper_script):
        ERROR "Wrapper not found or not executable"
        PRINT ""
        PRINT "Expected location: " + wrapper_script
        EXIT 1
    END IF

    SUCCESS "Creating session..."
    PRINT ""

    # Create tmux session with wrapper claude --resume (NO send-keys)
    EXEC "tmux new-session -s " + session_name + " '" + wrapper_script + " claude --resume'"
END FUNCTION
```

### Create Session Functions

```pseudocode
FUNCTION create_new_claude_session_with_choice(args):
    # Create new tmux session with launch mode choice
    # Used by default command (bitbot with no args)

    SET wrapper_script = "/usr/local/bitbot/wrapper/claude-wrapper.sh"
    SET session_name = "claude-" + get_timestamp()
    SET mode = get_bitbot_mode()  # "work" or "config"
    SET workspace = get_workspace()

    PRINT ""
    INFO "Creating new Claude Code session..."
    PRINT ""

    # Show launch mode choice
    CALL show_launch_mode_choice() → launch_mode

    CASE launch_mode OF:
        "resume":
            # Launch with --resume flag
            SET claude_cmd = "claude --resume"
            INFO "Launching: claude --resume"

        "interactive":
            # Launch interactive mode
            SET claude_cmd = "claude"
            INFO "Launching: claude (interactive)"

        "custom":
            # Ask for custom command
            PROMPT "Enter Claude command: " → custom_cmd
            SET claude_cmd = custom_cmd

        DEFAULT:
            # Default to interactive
            SET claude_cmd = "claude"
    END CASE

    # Show workspace info
    PRINT ""
    INFO "Workspace: " + workspace
    INFO "Mode: " + mode
    INFO "Session: " + session_name
    PRINT ""

    SUCCESS "Creating session..."
    PRINT ""

    # Create tmux session with wrapper command (NO send-keys)
    SET wrapper_cmd = wrapper_script + " " + claude_cmd
    EXEC "tmux new-session -s " + session_name + " '" + wrapper_cmd + "'"
END FUNCTION
```

---

## Helper Functions

### List tmux Sessions

```pseudocode
FUNCTION list_tmux_sessions() → array:
    # Get list of tmux sessions

    IF NOT command_exists("tmux"):
        RETURN empty_array
    END IF

    # Execute tmux list-sessions
    SET output = EXECUTE_CAPTURE "tmux list-sessions 2>/dev/null"

    IF exit_code != 0:
        RETURN empty_array
    END IF

    # Parse output into session info
    SET sessions = []

    FOR EACH line IN output.split_lines():
        # Format: session_name: windows (created timestamp)
        PARSE line → name, windows, created
        ADD {name: name, windows: windows, created: created} TO sessions
    END FOR

    RETURN sessions
END FUNCTION
```

### Show Launch Mode Choice

```pseudocode
FUNCTION show_launch_mode_choice() → string:
    # Ask user how to launch Claude

    PRINT "How would you like to launch Claude Code?"
    PRINT ""
    PRINT "  1) Resume previous session    (--resume)"
    PRINT "  2) Interactive mode           (default)"
    PRINT "  3) Custom command"
    PRINT ""
    PROMPT "Choice (1-3) [2]: " → choice

    IF choice is empty:
        choice = "2"
    END IF

    CASE choice OF:
        "1":
            RETURN "resume"
        "2":
            RETURN "interactive"
        "3":
            RETURN "custom"
        DEFAULT:
            RETURN "interactive"
    END CASE
END FUNCTION
```

### Prompt Resume or New

```pseudocode
FUNCTION prompt_resume_or_new() → string:
    # Ask if user wants to resume existing or create new

    PRINT "Would you like to:"
    PRINT "  1) Resume existing session"
    PRINT "  2) Create new session"
    PRINT ""
    PROMPT "Choice (1-2) [1]: " → choice

    IF choice is empty OR choice == "1":
        RETURN "resume"
    ELSE:
        RETURN "new"
    END IF
END FUNCTION
```

### Show Session Menu

```pseudocode
FUNCTION show_session_menu(sessions) → string:
    # Display session menu and get selection

    PRINT "Select session to resume:"
    PRINT ""

    SET index = 1
    FOR EACH session IN sessions:
        PRINT "  " + index + ") " + session.name + " (" + session.windows + " windows)"
        index = index + 1
    END FOR

    PRINT "  0) Cancel"
    PRINT ""
    PROMPT "Choice: " → choice

    IF choice == "0" OR choice is empty:
        RETURN empty_string
    END IF

    SET selected_index = parse_int(choice)

    IF selected_index > 0 AND selected_index <= length(sessions):
        RETURN sessions[selected_index - 1].name
    ELSE:
        ERROR "Invalid choice"
        RETURN empty_string
    END IF
END FUNCTION
```

---

## Help Display

```pseudocode
FUNCTION show_help():
    # Show help message

    PRINT "BitBot - Container Session Management"
    PRINT ""
    PRINT "Usage:"
    PRINT "  bitbot [command] [options]"
    PRINT ""
    PRINT "Commands:"
    PRINT "  (default)     Smart launcher with auto-selection"
    PRINT "                • 0 sessions: offer launch mode (fresh/resume/custom)"
    PRINT "                • 1 session: auto-resume that session"
    PRINT "                • 2+ sessions: offer resume/new choice"
    PRINT ""
    PRINT "  start         Always start fresh Claude in new tmux session"
    PRINT "                • No prompts, no session detection"
    PRINT "                • Creates: bitbot-YYYYMMDD-HHMM"
    PRINT ""
    PRINT "  resume [name] Intelligent resume with Claude detection"
    PRINT "                • 0 tmux: create new tmux with 'claude --resume'"
    PRINT "                • 1 session: auto-attach with Claude check"
    PRINT "                • 2+ sessions: show menu"
    PRINT "                • Warns if Claude has exited"
    PRINT ""
    PRINT "  help          Show this help message"
    PRINT ""
    PRINT "Examples:"
    PRINT "  # Smart launcher (auto-selects when 1 session)"
    PRINT "  bitbot"
    PRINT ""
    PRINT "  # Always start fresh"
    PRINT "  bitbot start"
    PRINT ""
    PRINT "  # Intelligent resume (handles tmux + Claude sessions)"
    PRINT "  bitbot resume"
    PRINT ""
    PRINT "  # Resume specific session"
    PRINT "  bitbot resume bitbot-20251028-1430"
    PRINT ""
    PRINT "Two-Level Session Management:"
    PRINT "  Level 1: tmux sessions (managed by BitBot)"
    PRINT "  Level 2: Claude sessions (managed by 'claude --resume')"
    PRINT ""
    PRINT "Environment:"
    PRINT "  WORKSPACE     Workspace path (default: /workspace)"
    PRINT "  BITBOT_MODE   Current mode (work/config)"
    PRINT ""
END FUNCTION
```

---

## Container Entrypoint Integration

**Automatic Launch on Container Start**:

```pseudocode
# In container entrypoint script (e.g., /usr/local/bitbot/entrypoint.sh)

FUNCTION container_entrypoint():
    # Called when container starts

    # Show welcome message
    CALL print_bitbot_logo()

    PRINT "BitBot Container Ready"
    PRINT ""

    # Check for existing tmux sessions
    SET sessions = list_tmux_sessions()

    IF sessions is not empty:
        PRINT "Found existing tmux sessions:"
        FOR EACH session IN sessions:
            PRINT "  • " + session.name
        END FOR
        PRINT ""
        PRINT "To resume: bitbot resume"
        PRINT "To start new: bitbot start"
    ELSE:
        PRINT "No existing sessions found"
        PRINT ""
        PRINT "To start Claude Code: bitbot start"
    END IF

    PRINT ""
    PRINT "Type 'bitbot help' for more commands"
    PRINT ""

    # Drop to shell
    EXECUTE "$SHELL"
END FUNCTION
```

---

## Implementation Notes

**Source Structure** (`container/bitbot/`):
```
container/bitbot/
├── bitbot                 # Main entry point (mirrors outer bitbot)
├── README.md              # Container BitBot documentation
├── core/                  # Mirrors outer bitbot core/ structure
│   ├── commands/          # Command implementations
│   │   ├── default.sh     # Smart launcher (auto-select, launch mode choice)
│   │   ├── start.sh       # Start fresh Claude session
│   │   └── resume.sh      # Intelligent resume (tmux + Claude detection)
│   └── util/              # Shared utilities
│       ├── helpers.sh     # Common helper functions
│       └── tmux-utils.sh  # tmux session management
└── wrapper/               # Wrapper scripts (IPC, watchdog)
    ├── claude-wrapper.sh  # Main wrapper (pipe-based IPC)
    ├── watchdog.sh        # Process monitor
    └── send-wrapper-command.sh  # Command sender
```

**Installed Structure** (`/usr/local/bitbot/` inside containers):
```
/usr/local/bitbot/
├── bitbot                 # Container entry point
├── README.md
├── core/
│   ├── commands/
│   └── util/
└── wrapper/               # Wrapper scripts (part of container BitBot)
    ├── claude-wrapper.sh
    ├── watchdog.sh
    └── send-wrapper-command.sh
```

**Deployment**: Copied to `.devcontainer/bitbot/` during `bitbot init`, then mounted:
```json
{
  "mounts": [
    "source=${localWorkspaceFolder}/.devcontainer/bitbot,target=/usr/local/bitbot,type=bind,readonly"
  ]
}
```

**Permissions**: Set during copy:
```bash
chmod +x .devcontainer/bitbot/bitbot
chmod +x .devcontainer/bitbot/core/commands/*.sh
chmod +x .devcontainer/bitbot/wrapper/*.sh
```

**Dependencies**:
- Claude Code (required, installed in container)
- bash (required, standard)
- tmux (optional, installed in container for fallback mode)
- Wrapper (optional, mounted from `$BITBOT_HOME/sparc/5-completion/`)

**Wrapper Integration**:
- **Source**: `$BITBOT_HOME/sparc/5-completion/claude-wrapper.sh`
- **Mount**: `/opt/bitbot/wrapper/claude-wrapper.sh` in container
- **Configuration**: devcontainer.json mount in workspace
- **Features**: Named pipe IPC, watchdog process, stall detection
- **Status**: Optional but preferred (makes tmux optional)

**Environment Variables**:
- `WORKSPACE`: Workspace path (default: /workspace)
- `BITBOT_MODE`: Current mode (work/config)
- `BITBOT_SESSION_NAME`: Override default session naming (tmux only)
- `BITBOT_HOME`: Host BitBot installation path (for wrapper mount)

**Session Naming (tmux mode)**:
- Format: `bitbot-YYYYMMDD-HHMM` (e.g., `bitbot-20251028-1430`)
- Allows multiple sessions
- Easy to identify and resume
- Not used in wrapper mode (single instance)

---

## Future Enhancements

**Post-MVP**:
- [ ] Session persistence across container restarts
- [ ] Claude command history
- [ ] Automatic session recovery
- [ ] Session sharing between modes
- [ ] Custom session templates
- [ ] Integration with MCP services

**Advanced Features**:
- [ ] Multiple Claude instances in different tmux windows
- [ ] Session recording/playback
- [ ] Automated workspace setup based on analysis
- [ ] AI-driven configuration recommendations
