# Container BitBot Pseudocode

**Component**: Container BitBot (runs inside containers)
**Source**: `container/bitbot/` directory
**Installed**: `/usr/local/bitbot/` inside containers
**Purpose**: AI agent assistance and session management inside devcontainers

---

## Overview

Container BitBot runs **inside** devcontainers to assist AI agents:
- Manage tmux sessions for Claude Code
- Resume unattached sessions
- Launch Claude Code with resume or interactive mode
- Provide workspace analysis and configuration helpers

```
Container Entry → Container BitBot → Session Management → Claude Code
```

**Transparent Behavior**: Same `bitbot` command works on host and in container
- **On Host**: `bitbot` orchestrates containers (enters/launches containers)
- **In Container**: `bitbot` manages sessions (starts/resumes Claude Code)

**Key Principle**: Simple bash scripts that help AI agents get started quickly in containers

---

## Main Entry Point

```pseudocode
FUNCTION bitbot(command, args):
    # /opt/bitbot/bitbot
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
            ERROR "Unknown command: " + command
            CALL show_help()
            EXIT 1
    END CASE
END FUNCTION
```

---

## Session Management

Container BitBot provides three commands for session management:

| Command             | Behavior                                              |
| ------------------- | ----------------------------------------------------- |
| `bitbot` (no args)  | Smart default: detect sessions, choose resume/launch mode |
| `bitbot start`      | Always create fresh tmux with fresh Claude (no prompts)   |
| `bitbot resume`     | Resume existing session or choose from list              |

### Default Command (No Arguments)

```pseudocode
FUNCTION default_command(args):
    # Smart session launcher with detection and choice
    # Called when: bitbot (no arguments)

    PRINT "BitBot - Claude Code Launcher"
    PRINT ""

    # Check for existing sessions
    SET existing_sessions = list_tmux_sessions()

    IF existing_sessions is not empty:
        PRINT "Found existing tmux sessions:"
        FOR EACH session IN existing_sessions:
            PRINT "  • " + session.name + " (created: " + session.created + ")"
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

### Start Command (Fresh Session)

```pseudocode
FUNCTION start_command(args):
    # Always create fresh tmux with fresh Claude (no prompts)
    # Called when: bitbot start

    PRINT "BitBot - Claude Code Launcher"
    PRINT ""

    # Always create fresh session (skip detection, skip prompts)
    CALL create_fresh_claude_session(args)
END FUNCTION
```

### Resume tmux Session

```pseudocode
FUNCTION resume_tmux_session(session_name):
    # Resume existing tmux session or choose from list

    SET sessions = list_tmux_sessions()

    IF sessions is empty:
        PRINT "No tmux sessions found"
        PRINT "Starting new session..."
        CALL create_new_claude_session()
        RETURN
    END IF

    # If session name provided, try to attach
    IF session_name is not empty:
        IF session_exists(session_name):
            EXECUTE "tmux attach-session -t " + session_name
            RETURN
        ELSE:
            ERROR "Session '" + session_name + "' not found"
            # Fall through to selection
        END IF
    END IF

    # Multiple sessions - let user choose
    IF length(sessions) == 1:
        # Only one session, attach to it
        EXECUTE "tmux attach-session -t " + sessions[0].name
    ELSE:
        # Multiple sessions - show menu
        CALL show_session_menu(sessions) → selected

        IF selected is not empty:
            EXECUTE "tmux attach-session -t " + selected
        END IF
    END IF
END FUNCTION
```

### Create Session Functions

```pseudocode
FUNCTION create_new_claude_session_with_choice(args):
    # Create new tmux session with launch mode choice
    # Used by default command (bitbot with no args)

    SET session_name = "claude-" + get_timestamp()
    SET mode = get_bitbot_mode()  # "work" or "config"

    PRINT "Creating new Claude Code session..."
    PRINT ""

    # Show launch mode choice
    CALL show_launch_mode_choice() → launch_mode

    CASE launch_mode OF:
        "resume":
            # Launch with --resume flag
            SET claude_cmd = "claude --resume"
            PRINT "Launching: claude --resume"

        "interactive":
            # Launch interactive mode
            SET claude_cmd = "claude"
            PRINT "Launching: claude (interactive)"

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
    PRINT "Workspace: /workspace"
    PRINT "Mode: " + mode
    PRINT "Session: " + session_name
    PRINT ""

    # Create tmux session and launch Claude
    EXECUTE "tmux new-session -s " + session_name + " -d"
    EXECUTE "tmux send-keys -t " + session_name + " '" + claude_cmd + "' C-m"

    # Wait a moment for session to start
    SLEEP 1

    # Attach to session
    EXECUTE "tmux attach-session -t " + session_name
END FUNCTION
```

```pseudocode
FUNCTION create_fresh_claude_session(args):
    # Create fresh tmux session with fresh Claude (no prompts)
    # Used by start command (bitbot start)

    SET session_name = "claude-" + get_timestamp()
    SET mode = get_bitbot_mode()  # "work" or "config"

    PRINT "Creating fresh Claude Code session..."
    PRINT ""

    # Always use fresh interactive Claude (no --resume)
    SET claude_cmd = "claude"

    # Show workspace info
    PRINT "Workspace: /workspace"
    PRINT "Mode: " + mode
    PRINT "Session: " + session_name
    PRINT ""

    # Create tmux session and launch Claude
    EXECUTE "tmux new-session -s " + session_name + " -d"
    EXECUTE "tmux send-keys -t " + session_name + " '" + claude_cmd + "' C-m"

    # Wait a moment for session to start
    SLEEP 1

    # Attach to session
    EXECUTE "tmux attach-session -t " + session_name
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

    PRINT "BitBot Helper - AI Agent Utilities"
    PRINT ""
    PRINT "Usage:"
    PRINT "  bitbot-helper <command> [options]"
    PRINT ""
    PRINT "Commands:"
    PRINT "  (default)     Smart launcher: detect sessions, choose launch mode"
    PRINT "  start         Always start fresh Claude in new tmux session"
    PRINT "  resume [name] Resume existing tmux session (or choose from list)"
    PRINT "  help          Show this help message"
    PRINT ""
    PRINT "Examples:"
    PRINT "  # Smart launcher (detects sessions, offers resume/new)"
    PRINT "  bitbot"
    PRINT ""
    PRINT "  # Always start fresh session with fresh Claude"
    PRINT "  bitbot start"
    PRINT ""
    PRINT "  # Resume existing session"
    PRINT "  bitbot resume"
    PRINT ""
    PRINT "  # Resume specific session"
    PRINT "  bitbot resume claude-20251022-1430"
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
└── core/                  # Mirrors outer bitbot core/ structure
    ├── commands/          # Command implementations
    │   ├── start.sh       # Start Claude session
    │   ├── resume.sh      # Resume tmux session
    │   ├── analyze.sh     # Workspace analysis
    │   ├── status.sh      # Status display
    │   └── configure.sh   # DevContainer configuration
    └── util/              # Shared utilities
        ├── helpers.sh     # Common helper functions
        └── tmux-utils.sh  # tmux session management
```

**Installed Structure** (`/usr/local/bitbot/` inside containers):
```
/usr/local/bitbot/
├── bitbot                 # Container entry point
├── README.md
└── core/
    ├── commands/
    └── util/
```

**Deployment**: Dockerfile copies during build:
```dockerfile
COPY container/bitbot/ /usr/local/bitbot/
RUN chmod +x /usr/local/bitbot/bitbot /usr/local/bitbot/core/commands/*.sh
ENV PATH="/usr/local/bitbot:${PATH}"
```

**Dependencies**:
- tmux (installed in container)
- Claude Code (installed in container)
- bash (standard)

**Environment Variables**:
- `WORKSPACE`: Workspace path (default: /workspace)
- `BITBOT_MODE`: Current mode (work/config)
- `BITBOT_SESSION_NAME`: Override default session naming

**Session Naming**:
- Format: `claude-YYYYMMDD-HHMM` (e.g., `claude-20251022-1430`)
- Allows multiple sessions
- Easy to identify and resume

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
