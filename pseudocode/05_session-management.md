# Session Management Pseudocode

**Component**: Session Management (tmux integration)
**Implements**: SPEC-04 (Session Management), SPEC-00 D-06
**Purpose**: Manage tmux sessions for resumability and context preservation

---

## Overview

```
Container Entry → Session Detection → [Resume | Create New] → tmux Session
                                          ↓
                              List Detached → Prompt Choice
```

**Decision**: tmux with auto-timestamped sessions, hidden from user

---

## Session Entry Point

```pseudocode
FUNCTION enter_session(container_name, options):
    # Called when attaching to container

    # Get session preference
    SET session_name = options["--session"] OR NULL
    SET non_interactive = options["--non-interactive"] OR false

    # List existing sessions
    CALL list_tmux_sessions(container_name) → sessions

    IF session_name is set:
        # Explicit session requested
        IF session_exists(container_name, session_name):
            CALL attach_tmux_session(container_name, session_name)
        ELSE:
            CALL create_tmux_session(container_name, session_name)
        END IF

    ELSE IF length(sessions) == 0:
        # No sessions: Create new
        CALL create_new_session(container_name, non_interactive)

    ELSE IF length(sessions) == 1:
        # One session: Auto-attach
        PRINT "[>] Attaching to session: " + sessions[0].name
        CALL attach_tmux_session(container_name, sessions[0].name)

    ELSE:
        # Multiple sessions: Prompt
        IF non_interactive:
            ERROR "Multiple sessions found. Specify with --session <name>"
            EXIT 1
        END IF

        CALL prompt_session_selection(sessions) → chosen

        IF chosen == "new":
            CALL create_new_session(container_name, non_interactive)
        ELSE:
            CALL attach_tmux_session(container_name, chosen.name)
        END IF
    END IF
END FUNCTION
```

---

## List tmux Sessions

```pseudocode
FUNCTION list_tmux_sessions(container_name) → session_list:
    # Get tmux sessions from container

    SET command = "docker exec " + container_name + " tmux ls -F '#{session_name}|#{session_created}|#{session_attached}' 2>/dev/null"
    EXECUTE command → output

    IF exit_code != 0:
        # No sessions or tmux not running
        RETURN empty_list
    END IF

    SET sessions = empty_list

    FOR EACH line IN split(output, "\n"):
        SPLIT line by "|" → name, created, attached

        SET session = {
            "name": name,
            "created": created,
            "attached": attached == "1",
            "timestamp": parse_session_timestamp(name)
        }

        APPEND session to sessions
    END FOR

    # Sort by timestamp (newest first)
    SORT sessions by timestamp DESC

    RETURN sessions
END FUNCTION
```

---

## Create New Session

```pseudocode
FUNCTION create_new_session(container_name, non_interactive):
    # Generate session name
    SET timestamp = current_timestamp_format()  # 2025-10-20_14-30-45
    SET session_name = timestamp

    # Optionally allow user to name/tag
    IF NOT non_interactive:
        PRINT ""
        PRINT "Creating new session"
        PRINT "Auto-generated name: " + session_name
        PRINT ""
        CALL prompt_text("Custom name (or Enter to use auto):", allow_empty=true) → custom_name

        IF custom_name is not empty:
            SET session_name = custom_name + "-" + timestamp
        END IF
    END IF

    PRINT "[>] Creating session: " + session_name

    # Create session metadata
    CALL save_session_metadata(container_name, session_name, {
        "created": current_iso8601_timestamp(),
        "mode": detect_current_mode(),
        "user": get_current_user()
    })

    # Create and attach
    CALL create_tmux_session(container_name, session_name)
END FUNCTION
```

---

## Prompt Session Selection

```pseudocode
FUNCTION prompt_session_selection(sessions) → chosen_session:
    PRINT ""
    PRINT "Available sessions:"
    PRINT ""

    SET choices = empty_list

    FOR i FROM 0 TO length(sessions) - 1:
        SET session = sessions[i]
        SET status = session.attached ? "[attached]" : "[detached]"
        SET age = format_age(session.created)

        PRINT "  " + (i + 1) + ") " + session.name + " " + status + " (" + age + ")"

        # Load metadata if available
        SET metadata = load_session_metadata(session.name)
        IF metadata:
            PRINT "     Last activity: " + metadata.last_activity
        END IF

        APPEND session to choices
    END FOR

    PRINT ""
    PRINT "  n) Create new session"
    PRINT ""

    CALL prompt_number("Select session (1-" + length(sessions) + " or 'n'):", min=1, max=length(sessions)) → choice

    IF choice == "n":
        RETURN "new"
    ELSE:
        RETURN choices[choice - 1]
    END IF
END FUNCTION
```

---

## tmux Operations

```pseudocode
FUNCTION create_tmux_session(container_name, session_name):
    # Create new tmux session

    SET command = "docker exec -it " + container_name +
                  " tmux new-session -s " + shell_escape(session_name)

    EXECUTE command

    IF exit_code != 0:
        ERROR "Failed to create tmux session"
        EXIT 1
    END IF
END FUNCTION

FUNCTION attach_tmux_session(container_name, session_name):
    # Attach to existing tmux session

    SET command = "docker exec -it " + container_name +
                  " tmux attach-session -t " + shell_escape(session_name)

    EXECUTE command

    IF exit_code != 0:
        ERROR "Failed to attach to session: " + session_name
        EXIT 1
    END IF
END FUNCTION

FUNCTION detach_tmux_session(container_name, session_name):
    # Detach from session (keep running)

    SET command = "docker exec " + container_name +
                  " tmux detach-client -s " + shell_escape(session_name)

    EXECUTE command
END FUNCTION

FUNCTION kill_tmux_session(container_name, session_name):
    # Kill session

    SET command = "docker exec " + container_name +
                  " tmux kill-session -t " + shell_escape(session_name)

    EXECUTE command

    IF exit_code == 0:
        PRINT "[+] Session killed: " + session_name

        # Clean up metadata
        CALL delete_session_metadata(container_name, session_name)
    ELSE:
        ERROR "Failed to kill session: " + session_name
    END IF
END FUNCTION
```

---

## Session Metadata Management

```pseudocode
FUNCTION save_session_metadata(container_name, session_name, metadata):
    # Save session metadata for context

    SET workspace_path = get_workspace_path_from_container(container_name)
    SET metadata_file = workspace_path + "/.bitbot/sessions/" + session_name + ".json"

    SET full_metadata = merge(metadata, {
        "session_name": session_name,
        "container": container_name,
        "last_activity": current_iso8601_timestamp()
    })

    CALL write_json(metadata_file, full_metadata)
END FUNCTION

FUNCTION load_session_metadata(session_name) → metadata OR NULL:
    SET metadata_file = WORKSPACE_PATH + "/.bitbot/sessions/" + session_name + ".json"

    IF file_exists(metadata_file):
        RETURN read_json(metadata_file)
    ELSE:
        RETURN NULL
    END IF
END FUNCTION

FUNCTION update_session_activity(session_name):
    # Update last activity timestamp

    SET metadata = load_session_metadata(session_name)

    IF metadata:
        SET metadata.last_activity = current_iso8601_timestamp()
        CALL save_session_metadata(CONTAINER_NAME, session_name, metadata)
    END IF
END FUNCTION

FUNCTION delete_session_metadata(container_name, session_name):
    SET workspace_path = get_workspace_path_from_container(container_name)
    SET metadata_file = workspace_path + "/.bitbot/sessions/" + session_name + ".json"

    IF file_exists(metadata_file):
        DELETE metadata_file
    END IF
END FUNCTION
```

---

## Session Listing (Host Command)

```pseudocode
FUNCTION list_sessions(flags, options):
    # Host command: bitbot list

    SET workspace_path = WORKSPACE_PATH
    SET workspace_hash = get_workspace_hash(workspace_path)

    # Find containers for this workspace
    SET work_container = "bitbot-work-" + workspace_hash
    SET setup_container = "bitbot-setup-" + workspace_hash

    PRINT "BitBot Sessions"
    PRINT "==============="
    PRINT ""

    # Work mode sessions
    IF container_exists(work_container):
        PRINT "[Work Mode]"
        CALL list_tmux_sessions(work_container) → sessions

        IF length(sessions) == 0:
            PRINT "  No sessions"
        ELSE:
            FOR EACH session IN sessions:
                SET status = session.attached ? "attached" : "detached"
                SET age = format_age(session.created)
                PRINT "  • " + session.name + " (" + status + ", " + age + ")"
            END FOR
        END IF
        PRINT ""
    END IF

    # Setup mode sessions
    IF container_exists(setup_container):
        PRINT "[Setup Mode]"
        CALL list_tmux_sessions(setup_container) → sessions

        IF length(sessions) == 0:
            PRINT "  No sessions"
        ELSE:
            FOR EACH session IN sessions:
                SET status = session.attached ? "attached" : "detached"
                SET age = format_age(session.created)
                PRINT "  • " + session.name + " (" + status + ", " + age + ")"
            END FOR
        END IF
        PRINT ""
    END IF
END FUNCTION
```

---

## Session History Persistence

```pseudocode
FUNCTION setup_bash_history_persistence(container_name, session_name):
    # Configure bash history per session

    SET workspace_path = get_workspace_path_from_container(container_name)
    SET history_dir = workspace_path + "/.bitbot/sessions/" + session_name + "/history"

    # Create history directory
    EXECUTE "docker exec " + container_name + " mkdir -p " + history_dir

    # Set HISTFILE environment variable
    SET histfile = history_dir + "/.bash_history"
    EXECUTE "docker exec " + container_name + " bash -c 'export HISTFILE=" + histfile + "'"

    PRINT "[i] History will be saved to: " + histfile
END FUNCTION
```

---

## Utility Functions

```pseudocode
FUNCTION parse_session_timestamp(session_name) → timestamp:
    # Extract timestamp from auto-generated session names
    # Format: 2025-10-20_14-30-45 or custom-2025-10-20_14-30-45

    SET pattern = "([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2})"
    MATCH pattern IN session_name → timestamp_str

    IF timestamp_str:
        RETURN parse_datetime(timestamp_str, format="%Y-%m-%d_%H-%M-%S")
    ELSE:
        RETURN NULL
    END IF
END FUNCTION

FUNCTION format_age(timestamp) → age_string:
    # Format timestamp as relative age (e.g., "2 hours ago")

    SET now = current_timestamp()
    SET diff = now - timestamp

    IF diff < 60:
        RETURN diff + " seconds ago"
    ELSE IF diff < 3600:
        RETURN (diff / 60) + " minutes ago"
    ELSE IF diff < 86400:
        RETURN (diff / 3600) + " hours ago"
    ELSE:
        RETURN (diff / 86400) + " days ago"
    END IF
END FUNCTION

FUNCTION current_timestamp_format() → formatted_string:
    # Generate timestamp for session names
    # Format: 2025-10-20_14-30-45

    SET now = current_datetime()
    RETURN format_datetime(now, "%Y-%m-%d_%H-%M-%S")
END FUNCTION

FUNCTION session_exists(container_name, session_name) → boolean:
    SET command = "docker exec " + container_name +
                  " tmux has-session -t " + shell_escape(session_name) + " 2>/dev/null"
    EXECUTE command

    RETURN exit_code == 0
END FUNCTION
```

---

## Implementation Notes

**Key Behaviors**:
- Auto-generated session names with timestamps
- Optional user-provided names/tags
- Single session: Auto-attach
- Multiple sessions: Prompt user
- Session metadata stored in `.bitbot/sessions/`
- Bash history per session

**Session Lifecycle**:
1. Create → Generate name → Save metadata → Launch tmux
2. Active → Update activity timestamp
3. Detach → Keep running in background
4. Resume → List → Prompt → Attach
5. Kill → Clean up metadata

**Metadata Tracking**:
- Created timestamp
- Last activity
- Mode (work/setup)
- User
- Custom tags/notes (future)

**User Experience**:
- Sessions are transparent (user doesn't need to know about tmux)
- Clear indication of session status (attached/detached)
- Age display for easy identification
- Context preservation across detach/attach

**Next Steps**:
- Implement first-run wizard (06_first-run.md)
- Implement UID synchronization (07_uid-sync.md)
