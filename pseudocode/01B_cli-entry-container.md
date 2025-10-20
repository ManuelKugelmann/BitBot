# CLI Entry Point - Container Pseudocode

**Component**: `/usr/local/bin/bitbot` (Container script)
**Implements**: SPEC-05 (Cross-Platform CLI), SPEC-09 (CLI UX)
**Purpose**: AI agent management and session operations inside container

---

## Overview

```
User Command (Container) → Parse Args → Detect Mode → Execute Command
                                           ↓
                        [AI Agent | done | list | session mgmt]
```

**Scope**: Container-side operations only (AI agents, sessions)
**Counterpart**: `01A_cli-entry-host.md` (host operations)

---

## Main Entry Point

```pseudocode
FUNCTION main(args):
    # Verify we're inside container
    IF NOT is_container_environment():
        ERROR "This command must be run inside BitBot container"
        PRINT "On host, use: bitbot work"
        EXIT 1
    END IF

    # Parse command line arguments
    CALL parse_arguments(args) → command, flags, options

    # Set up error handling
    CALL setup_error_handlers()

    # Detect current mode
    SET mode = get_env("BITBOT_MODE") OR "work"

    # Route to container commands
    CALL handle_container_commands(command, flags, options, mode)
END FUNCTION
```

---

## Container Detection

```pseudocode
FUNCTION is_container_environment() → boolean:
    # Check if running inside BitBot container

    # Check for container indicator file
    IF file_exists("/.dockerenv"):
        RETURN true
    END IF

    # Check for BitBot environment variable
    IF env_var_set("BITBOT_CONTAINER"):
        RETURN true
    END IF

    # Check if running inside devcontainer
    IF env_var_set("REMOTE_CONTAINERS") OR env_var_set("CODESPACES"):
        RETURN true
    END IF

    RETURN false
END FUNCTION
```

---

## Argument Parsing

```pseudocode
FUNCTION parse_arguments(args) → (command, flags, options):
    SET command = ""
    SET flags = empty_map
    SET options = empty_map

    # Parse flags and options
    FOR EACH arg IN args:
        IF arg starts_with("--"):
            # Long flag: --flag or --option=value
            IF arg contains "=":
                SPLIT arg by "=" → key, value
                SET options[key] = value
            ELSE:
                SET flags[arg] = true
            END IF
        ELSE IF arg starts_with("-"):
            # Short flag: -f
            SET flags[arg] = true
        ELSE:
            # Positional argument (command or agent name)
            IF command is empty:
                SET command = arg
            ELSE:
                # Additional positional args (agent parameters)
                APPEND arg to options["args"]
            END IF
        END IF
    END FOR

    RETURN (command, flags, options)
END FUNCTION
```

---

## Container Command Handling

```pseudocode
FUNCTION handle_container_commands(command, flags, options, mode):
    # Route commands for in-container operations

    SWITCH command:
        CASE "" OR NULL:
            # No command: launch default AI agent
            CALL launch_default_agent(mode, flags, options)

        CASE "done":
            # Review changes → commit → exit
            CALL done_workflow(mode)

        CASE "list":
            # List tmux sessions in this container
            CALL list_local_sessions()

        CASE "session":
            # Session management subcommands
            CALL manage_session(options)

        CASE "mode":
            # Show current mode info
            CALL show_mode_info(mode)

        CASE "status":
            # Show workspace status
            CALL show_workspace_status(mode)

        CASE "help":
            CALL show_container_help()

        DEFAULT:
            # Assume command is an agent name
            CALL launch_agent(command, flags, options)
    END SWITCH
END FUNCTION
```

---

## AI Agent Launch

```pseudocode
FUNCTION launch_default_agent(mode, flags, options):
    # Launch default configured AI agent

    # Load workspace config
    SET config = read_workspace_config()

    IF config.default_agent is NULL:
        PRINT "No default AI agent configured"
        PRINT ""
        PRINT "Available agents:"
        CALL list_available_agents()
        PRINT ""
        PRINT "Configure with: bitbot config set default_agent <name>"
        EXIT 1
    END IF

    SET agent_name = config.default_agent

    CALL launch_agent(agent_name, flags, options)
END FUNCTION

FUNCTION launch_agent(agent_name, flags, options):
    # Launch specific AI agent

    PRINT "[>] Launching " + agent_name + "..."

    # Check if agent is available
    IF NOT agent_exists(agent_name):
        ERROR "Agent not found: " + agent_name
        PRINT ""
        PRINT "Available agents:"
        CALL list_available_agents()
        EXIT 1
    END IF

    # Build agent command
    SET agent_cmd = build_agent_command(agent_name, flags, options)

    # Log agent launch
    CALL audit_log("agent_launch", {
        "agent": agent_name,
        "timestamp": current_iso8601_timestamp(),
        "mode": get_env("BITBOT_MODE")
    })

    # Execute agent
    EXECUTE agent_cmd

    # Agent exited
    PRINT ""
    PRINT "[i] Agent exited"
END FUNCTION
```

---

## Done Workflow

```pseudocode
FUNCTION done_workflow(mode):
    # Review changes → commit → exit

    PRINT "==================================="
    PRINT "  BitBot Done Workflow"
    PRINT "==================================="
    PRINT ""

    # Show changes
    PRINT "[>] Changes made in this session:"
    PRINT ""

    IF directory_exists(".git"):
        EXECUTE "git status --short"
        PRINT ""

        # Check if there are changes
        EXECUTE "git status --porcelain" → changes

        IF changes is empty:
            PRINT "[i] No changes to commit"
        ELSE:
            # Prompt for commit
            CALL prompt_yes_no("Commit these changes?", default="yes") → should_commit

            IF should_commit:
                CALL prompt_commit_message() → message

                EXECUTE "git add ."
                EXECUTE "git commit -m \"" + message + "\""

                IF exit_code == 0:
                    PRINT "[+] Changes committed"

                    # Prompt for push
                    CALL prompt_yes_no("Push to remote?", default="yes") → should_push

                    IF should_push:
                        EXECUTE "git push"

                        IF exit_code == 0:
                            PRINT "[+] Pushed to remote"
                        ELSE:
                            WARN "[!] Push failed (you can push manually later)"
                        END IF
                    END IF
                ELSE:
                    ERROR "[X] Commit failed"
                    RETURN
                END IF
            END IF
        END IF
    ELSE:
        PRINT "[i] No git repository found"
    END IF

    # Log done
    CALL audit_log("done_workflow", {
        "mode": mode,
        "timestamp": current_iso8601_timestamp()
    })

    PRINT ""
    CALL prompt_yes_no("Exit container?", default="yes") → should_exit

    IF should_exit:
        PRINT "[+] Goodbye!"
        EXIT 0
    END IF
END FUNCTION

FUNCTION prompt_commit_message() → message:
    PRINT "Commit message: "
    SET message = read_line_from_stdin()

    IF message is empty:
        SET message = "BitBot session changes"
    END IF

    RETURN message
END FUNCTION
```

---

## Session Management

```pseudocode
FUNCTION list_local_sessions():
    # List tmux sessions in current container

    PRINT "Active Sessions"
    PRINT "==============="
    PRINT ""

    EXECUTE "tmux ls -F '#{session_name}|#{session_created}|#{session_attached}' 2>/dev/null" → output

    IF exit_code != 0:
        PRINT "No active sessions"
        RETURN
    END IF

    FOR EACH line IN split(output, "\n"):
        SPLIT line by "|" → name, created, attached

        SET status = (attached == "1") ? "[attached]" : "[detached]"
        SET age = format_age(created)

        PRINT "  • " + name + " " + status + " (" + age + ")"
    END FOR
END FUNCTION

FUNCTION manage_session(options):
    # Session management subcommands

    SET subcommand = options["subcommand"] OR ""

    SWITCH subcommand:
        CASE "attach":
            SET session_name = options["name"]
            EXECUTE "tmux attach-session -t " + session_name

        CASE "detach":
            EXECUTE "tmux detach-client"

        CASE "kill":
            SET session_name = options["name"]
            EXECUTE "tmux kill-session -t " + session_name
            PRINT "[+] Session killed: " + session_name

        CASE "rename":
            SET old_name = options["old"]
            SET new_name = options["new"]
            EXECUTE "tmux rename-session -t " + old_name + " " + new_name
            PRINT "[+] Session renamed: " + old_name + " → " + new_name

        DEFAULT:
            ERROR "Unknown session subcommand: " + subcommand
            PRINT "Usage: bitbot session [attach|detach|kill|rename]"
            EXIT 2
    END SWITCH
END FUNCTION
```

---

## Agent Management

```pseudocode
FUNCTION list_available_agents():
    # List all available AI agents

    SET agents = []

    # Check for common agents
    IF command_exists("claude"):
        APPEND "claude" to agents
    END IF

    IF command_exists("aider"):
        APPEND "aider" to agents
    END IF

    IF command_exists("cursor"):
        APPEND "cursor" to agents
    END IF

    # Check for custom agents in workspace
    IF directory_exists(".bitbot/agents"):
        FOR EACH file IN list_files(".bitbot/agents"):
            IF is_executable(file):
                APPEND basename(file) to agents
            END IF
        END FOR
    END IF

    # Display
    IF length(agents) == 0:
        PRINT "  No agents found"
    ELSE:
        FOR EACH agent IN agents:
            PRINT "  • " + agent
        END FOR
    END IF
END FUNCTION

FUNCTION agent_exists(agent_name) → boolean:
    # Check if agent is available

    # Built-in agents
    IF command_exists(agent_name):
        RETURN true
    END IF

    # Custom agents
    IF file_exists(".bitbot/agents/" + agent_name):
        RETURN true
    END IF

    RETURN false
END FUNCTION

FUNCTION build_agent_command(agent_name, flags, options) → command:
    # Build command to launch agent

    SET command = [agent_name]

    # Add resume flag if configured
    IF options["--resume"]:
        APPEND "--resume" to command
    END IF

    # Add additional args
    IF options["args"] exists:
        FOR EACH arg IN options["args"]:
            APPEND arg to command
        END FOR
    END IF

    RETURN command
END FUNCTION
```

---

## Status Display

```pseudocode
FUNCTION show_mode_info(mode):
    # Show current mode information

    IF mode == "work":
        PRINT "╔══════════════════════════════════════╗"
        PRINT "║       BitBot Work Mode               ║"
        PRINT "╠══════════════════════════════════════╣"
        PRINT "║ Workspace:     Read-Write            ║"
        PRINT "║ .devcontainer: Read-Only             ║"
        PRINT "║ Docker socket: Not available         ║"
        PRINT "║ AI agents:     Enabled               ║"
        PRINT "╚══════════════════════════════════════╝"

    ELSE IF mode == "setup":
        PRINT "╔══════════════════════════════════════╗"
        PRINT "║       BitBot Setup Mode              ║"
        PRINT "╠══════════════════════════════════════╣"
        PRINT "║ Workspace:     Full access           ║"
        PRINT "║ .devcontainer: Modifiable            ║"
        PRINT "║ Docker socket: Approved              ║"
        PRINT "║ Changes:       Logged                ║"
        PRINT "╚══════════════════════════════════════╝"
    END IF
END FUNCTION

FUNCTION show_workspace_status(mode):
    # Show workspace status

    PRINT "Workspace Status"
    PRINT "================"
    PRINT ""

    # Basic info
    PRINT "Path: " + get_env("BITBOT_WORKSPACE")
    PRINT "Mode: " + mode
    PRINT ""

    # Git status
    IF directory_exists(".git"):
        PRINT "Git Status:"
        EXECUTE "git status --short"
        PRINT ""

        # Branch info
        EXECUTE "git branch --show-current" → branch
        PRINT "Branch: " + branch

        # Unpushed commits
        EXECUTE "git rev-list HEAD --not --remotes | wc -l" → unpushed
        IF unpushed > 0:
            PRINT "Unpushed commits: " + unpushed
        END IF
    ELSE:
        PRINT "Git: Not initialized"
    END IF

    PRINT ""
END FUNCTION
```

---

## Help Display

```pseudocode
FUNCTION show_container_help():
    PRINT "BitBot Container Commands"
    PRINT "========================="
    PRINT ""
    PRINT "AI Agents:"
    PRINT "  bitbot              Launch default AI agent"
    PRINT "  bitbot <agent>      Launch specific agent"
    PRINT "  bitbot done         Review changes and exit"
    PRINT ""
    PRINT "Session Management:"
    PRINT "  bitbot list         List active sessions"
    PRINT "  bitbot session attach <name>"
    PRINT "  bitbot session detach"
    PRINT "  bitbot session kill <name>"
    PRINT ""
    PRINT "Information:"
    PRINT "  bitbot mode         Show current mode"
    PRINT "  bitbot status       Show workspace status"
    PRINT "  bitbot help         Show this help"
    PRINT ""
    PRINT "Available agents:"
    CALL list_available_agents()
END FUNCTION
```

---

## Error Handling

```pseudocode
FUNCTION setup_error_handlers():
    # Trap signals
    TRAP SIGINT:
        PRINT "\n[!] Interrupted by user"
        EXIT 130

    TRAP SIGTERM:
        PRINT "\n[!] Terminated"
        EXIT 143

    TRAP ERR:
        PRINT "[X] Error on line " + LINE_NUMBER
        EXIT 1
END FUNCTION
```

---

## Utility Functions

```pseudocode
FUNCTION read_workspace_config() → config:
    SET config_file = ".bitbot/config.json"

    IF file_exists(config_file):
        RETURN read_json(config_file)
    ELSE:
        # Return defaults
        RETURN {
            "default_agent": NULL
        }
    END IF
END FUNCTION

FUNCTION format_age(timestamp) → age_string:
    SET now = current_timestamp()
    SET diff = now - timestamp

    IF diff < 60:
        RETURN diff + "s ago"
    ELSE IF diff < 3600:
        RETURN (diff / 60) + "m ago"
    ELSE IF diff < 86400:
        RETURN (diff / 3600) + "h ago"
    ELSE:
        RETURN (diff / 86400) + "d ago"
    END IF
END FUNCTION

FUNCTION prompt_yes_no(question, default) → string:
    IF default == "yes":
        PRINT question + " (Y/n): "
    ELSE:
        PRINT question + " (y/N): "
    END IF

    SET response = read_line_from_stdin()

    IF response is empty:
        RETURN default
    END IF

    SET response = lowercase(trim(response))

    IF response == "y" OR response == "yes":
        RETURN "yes"
    ELSE IF response == "n" OR response == "no":
        RETURN "no"
    ELSE:
        RETURN prompt_yes_no(question, default)
    END IF
END FUNCTION
```

---

## Implementation Notes

**Key Behaviors**:
- Runs only inside BitBot containers
- Manages AI agents and sessions
- Simplified command surface (no container management)
- Done workflow for git operations
- Session management via tmux

**Environment**:
- `BITBOT_CONTAINER=true` (indicator)
- `BITBOT_MODE=work|setup` (current mode)
- `BITBOT_WORKSPACE=/workspace` (workspace path)

**Agent Support**:
- Built-in: claude, aider, cursor, etc.
- Custom: `.bitbot/agents/` directory
- Configurable default agent

**Session Commands**:
- `bitbot` → Launch default agent
- `bitbot done` → Commit and exit workflow
- `bitbot list` → Show sessions
- `bitbot mode` → Show mode info
- `bitbot status` → Workspace status

**Next Steps**:
- Separate from host script implementation
- Install in container at build time
- Configure in devcontainer features
