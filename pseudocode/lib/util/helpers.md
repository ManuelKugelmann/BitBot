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
