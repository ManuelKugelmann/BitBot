# Helper Functions Pseudocode

**Component**: Common Utilities
**Script**: `scripts/lib/helpers.sh`
**Purpose**: Shared utility functions

---

## File System Helpers

```pseudocode
FUNCTION create_directory(path):
    IF NOT directory_exists(path):
        EXECUTE "mkdir -p " + path
    END IF
END FUNCTION

FUNCTION directory_exists(path) → boolean:
    RETURN execute_test("-d " + path)
END FUNCTION

FUNCTION file_exists(path) → boolean:
    RETURN execute_test("-f " + path)
END FUNCTION

FUNCTION command_exists(command) → boolean:
    EXECUTE "command -v " + command + " >/dev/null 2>&1"
    RETURN exit_code == 0
END FUNCTION
```

---

## JSON Helpers

```pseudocode
FUNCTION read_json(file_path) → object:
    IF command_exists("jq"):
        EXECUTE "jq '.' " + file_path
        RETURN parse_json(output)
    ELSE:
        # Fallback: basic parsing
        RETURN parse_json_basic(read_file(file_path))
    END IF
END FUNCTION

FUNCTION write_json(file_path, object):
    SET json_string = stringify_json(object)
    CALL write_file(file_path, json_string)
END FUNCTION

FUNCTION merge_configs(global_config_path, workspace_config_path) → object:
    # Merge two JSON configs: workspace overrides global
    # Returns merged config object
    # Simple top-level merge (no dependencies)

    # Check if workspace config exists
    IF NOT file_exists(workspace_config_path):
        # No workspace config - just return global
        RETURN read_json(global_config_path)
    END IF

    # Check if global config exists
    IF NOT file_exists(global_config_path):
        # No global config - just return workspace
        RETURN read_json(workspace_config_path)
    END IF

    # Both exist - manual merge (top-level only)
    CALL read_json(global_config_path) → global_cfg
    CALL read_json(workspace_config_path) → workspace_cfg

    # Manual merge: workspace overrides global (top-level keys)
    FOR EACH key IN workspace_cfg:
        SET global_cfg[key] = workspace_cfg[key]
    END FOR

    RETURN global_cfg
END FUNCTION

FUNCTION get_merged_workspace_config(workspace_path) → object:
    # Helper: Get merged config for a workspace
    # Merges global BitBot config with workspace config

    SET bitbot_install = get_bitbot_install_dir()
    SET global_config = bitbot_install + "/config.json"
    SET workspace_config = workspace_path + "/.bitbot/config.json"

    RETURN merge_configs(global_config, workspace_config)
END FUNCTION

FUNCTION update_workspace_config(workspace_path, key, value):
    # Update a specific key in workspace config
    # Used to save user preferences (e.g., skip git recommendations)

    SET config_path = workspace_path + "/.bitbot/config.json"

    # Read existing config
    IF file_exists(config_path):
        CALL read_json(config_path) → config
    ELSE:
        # Create minimal config if doesn't exist
        SET config = {
            "default_mode": "work",
            "workspace_name": basename(workspace_path)
        }
    END IF

    # Update the key
    SET config[key] = value

    # Write back to file
    CALL write_json(config_path, config)
END FUNCTION
```

---

## Path Helpers

```pseudocode
FUNCTION get_current_directory() → path:
    RETURN execute("pwd")
END FUNCTION

FUNCTION get_absolute_path(path) → absolute_path:
    EXECUTE "realpath " + path
    RETURN output
END FUNCTION

FUNCTION basename(path) → name:
    RETURN execute("basename " + path)
END FUNCTION

FUNCTION dirname(path) → directory:
    RETURN execute("dirname " + path)
END FUNCTION
```

---

## Prompt Helpers

```pseudocode
FUNCTION prompt_yes_no(question, default) → answer:
    # Display question with default indicator
    IF default == "yes":
        PRINT question + " (Y/n): "
    ELSE IF default == "no":
        PRINT question + " (y/N): "
    ELSE:
        PRINT question + " (y/n): "
    END IF

    # Read user input
    SET response = read_line()

    # Handle empty response (use default)
    IF response is empty:
        RETURN default
    END IF

    # Parse response
    SET response = lowercase(trim(response))

    IF response IN ["y", "yes"]:
        RETURN "yes"
    ELSE IF response IN ["n", "no"]:
        RETURN "no"
    ELSE:
        PRINT "[!] Invalid input, please enter 'y' or 'n'"
        RETURN prompt_yes_no(question, default)
    END IF
END FUNCTION

FUNCTION prompt_choice(question, choices, default_index) → choice_index:
    # Display question with numbered choices
    # Returns selected choice index (0-based)

    PRINT question
    PRINT ""

    # Display choices with numbers
    FOR i = 0 TO length(choices) - 1:
        SET number = i + 1
        SET choice = choices[i]

        IF i == default_index:
            PRINT "  " + number + ". " + choice + " (default)"
        ELSE:
            PRINT "  " + number + ". " + choice
        END IF
    END FOR

    PRINT ""
    PRINT "Choice [" + (default_index + 1) + "]: "

    # Read user input
    SET response = read_line()

    # Handle empty response (use default)
    IF response is empty:
        RETURN default_index
    END IF

    # Parse numeric response
    SET response = trim(response)
    SET number = parse_integer(response)

    # Validate choice
    IF number >= 1 AND number <= length(choices):
        RETURN number - 1  # Convert to 0-based index
    ELSE:
        PRINT "[!] Invalid choice, please enter a number between 1 and " + length(choices)
        RETURN prompt_choice(question, choices, default_index)
    END IF
END FUNCTION
```

---

## Color Output Helpers

```pseudocode
FUNCTION print_success(message):
    PRINT "[+] " + message
END FUNCTION

FUNCTION print_info(message):
    PRINT "[i] " + message
END FUNCTION

FUNCTION print_warning(message):
    PRINT "[!] " + message
END FUNCTION

FUNCTION print_error(message):
    PRINT "[X] " + message to stderr
END FUNCTION
```

---

## Timestamp Helpers

```pseudocode
FUNCTION current_timestamp() → string:
    RETURN iso8601_timestamp()
END FUNCTION

FUNCTION iso8601_timestamp() → string:
    EXECUTE "date -u +%Y-%m-%dT%H:%M:%SZ"
    RETURN output
END FUNCTION
```

---

## Implementation Notes

**Shared Library**: Used by all BitBot scripts

**MVP Scope**: Essential utilities only

**Future**:
- Logging helpers
- Error handling helpers
- Config parsing helpers
- Network helpers
