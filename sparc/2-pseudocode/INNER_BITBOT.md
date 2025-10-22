# Container BitBot Pseudocode

**Component**: Container BitBot (runs inside containers)
**Source**: `container-bitbot/` directory
**Installed**: `/opt/bitbot/` inside containers
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
        "analyze":
            CALL analyze_workspace()
        "status":
            CALL show_status()
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

### Start Claude Session

```pseudocode
FUNCTION start_claude_session(args):
    # Launch Claude Code in tmux session with choice

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

    # No existing sessions or user wants new session
    CALL create_new_claude_session(args)
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

### Create New Claude Session

```pseudocode
FUNCTION create_new_claude_session(args):
    # Create new tmux session with Claude Code

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

## Workspace Analysis

```pseudocode
FUNCTION analyze_workspace():
    # Analyze workspace tech stack and structure
    # See existing implementation in templates/base/bitbot/commands/analyze.sh

    PRINT "Analyzing workspace: /workspace"
    PRINT ""

    CALL detect_project_type()
    CALL check_git_status()
    CALL detect_dependencies()
    CALL show_container_info()
END FUNCTION
```

---

## Status Display

```pseudocode
FUNCTION show_status():
    # Show container environment status
    # See existing implementation in templates/base/bitbot/commands/status.sh

    PRINT "BitBot Container Status"
    PRINT ""

    CALL show_mode()
    CALL show_container_details()
    CALL show_workspace_info()
    CALL show_devcontainer_status()
    CALL show_tmux_sessions()
END FUNCTION

FUNCTION show_tmux_sessions():
    # Add to status display

    PRINT "tmux Sessions:"

    SET sessions = list_tmux_sessions()

    IF sessions is empty:
        PRINT "  No active sessions"
    ELSE:
        FOR EACH session IN sessions:
            PRINT "  • " + session.name + " (" + session.windows + " windows)"
        END FOR
    END IF

    PRINT ""
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
    PRINT "  start         Start Claude Code in tmux session"
    PRINT "  resume [name] Resume tmux session (or choose from list)"
    PRINT "  analyze       Analyze workspace tech stack"
    PRINT "  status        Show container environment status"
    PRINT "  help          Show this help message"
    PRINT ""
    PRINT "Examples:"
    PRINT "  # Start Claude Code (with launch mode choice)"
    PRINT "  bitbot-helper start"
    PRINT ""
    PRINT "  # Resume existing session"
    PRINT "  bitbot-helper resume"
    PRINT ""
    PRINT "  # Resume specific session"
    PRINT "  bitbot-helper resume claude-20251022-1430"
    PRINT ""
    PRINT "  # Analyze workspace"
    PRINT "  bitbot-helper analyze"
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
# In container entrypoint script (e.g., /opt/bitbot/entrypoint.sh)

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
        PRINT "To resume: bitbot-helper resume"
        PRINT "To start new: bitbot-helper start"
    ELSE:
        PRINT "No existing sessions found"
        PRINT ""
        PRINT "To start Claude Code: bitbot-helper start"
        PRINT "To analyze workspace: bitbot-helper analyze"
    END IF

    PRINT ""
    PRINT "Type 'bitbot-helper help' for more commands"
    PRINT ""

    # Drop to shell
    EXECUTE "$SHELL"
END FUNCTION
```

---

## Implementation Notes

**Source Structure** (`container-bitbot/`):
```
container-bitbot/
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

**Installed Structure** (`/opt/bitbot/` inside containers):
```
/opt/bitbot/
├── bitbot                 # Container entry point
├── README.md
└── core/
    ├── commands/
    └── util/
```

**Deployment**: Dockerfile copies during build:
```dockerfile
COPY container-bitbot/ /opt/bitbot/
RUN chmod +x /opt/bitbot/bitbot /opt/bitbot/core/commands/*.sh
ENV PATH="/opt/bitbot:${PATH}"
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
