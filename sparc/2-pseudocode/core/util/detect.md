# Workspace Detection Pseudocode

**Component**: Workspace Discovery
**Implements**: SPEC-09 Part B (Workspace Discovery), TODO.md Item 3
**Purpose**: Find or initialize BitBot workspace based on current working directory

---

## Overview

```
bitbot command → Detect workspace → Prompt if needed → Return workspace path
                        ↓
        [CWD | Parent | Initialize New]
```

**Decision**: CWD first, then parent with prompt, else initialize

---

## Main Detection Function

```pseudocode
FUNCTION detect_workspace() → workspace_path OR NULL:
    # MVP: CWD only, no parent search

    SET cwd = get_current_directory()

    IF directory_exists(cwd + "/.bitbot"):
        PRINT "[i] Using workspace: " + cwd
        RETURN cwd
    END IF

    # No workspace found in CWD
    RETURN NULL
END FUNCTION
```

---

## Initialize Workspace (MVP: Minimal)

```pseudocode
FUNCTION initialize_workspace_in(path):
    PRINT "[>] Initializing BitBot workspace: " + path

    # Create minimal .bitbot structure
    CALL create_directory(path + "/.bitbot")
    CALL create_directory(path + "/.bitbot/state")

    # Create config.json (workspace configuration)
    SET config = {
        "default_mode": "work",
        "workspace_name": basename(path)
    }

    CALL write_json(path + "/.bitbot/config.json", config)

    PRINT "[+] Workspace initialized"
    PRINT ""

    # Always launch config mode to configure .devcontainer
    PRINT "Launching config mode to configure workspace..."
    PRINT "(Use config mode to create/modify .devcontainer for bitbot)"
    PRINT ""

    # Launch config mode (will create .bitbot/internal/devcontainer.json)
    CALL launch_mode("config", empty_flags, empty_options)
END FUNCTION
```

---

## Path Resolution

```pseudocode
FUNCTION resolve_path(path) → absolute_path:
    # Expand ~ to home directory
    IF path starts_with("~"):
        SET path = HOME_DIR + substring(path, 1)
    END IF

    # Convert relative to absolute
    IF NOT path starts_with("/"):
        SET path = get_current_directory() + "/" + path
    END IF

    # Resolve symlinks
    SET resolved = readlink_canonicalize(path)

    RETURN resolved
END FUNCTION

FUNCTION get_parent_directory(path) → parent_path:
    # Remove trailing slash
    SET path = trim_trailing_slash(path)

    # Get parent
    SET parent = dirname(path)

    RETURN parent
END FUNCTION
```

---

## Validation

```pseudocode
FUNCTION validate_workspace(workspace_path) → boolean:
    # Check .bitbot exists
    IF NOT directory_exists(workspace_path + "/.bitbot"):
        RETURN false
    END IF

    # Check metadata.json
    IF NOT file_exists(workspace_path + "/.bitbot/metadata.json"):
        WARN "[!] Workspace missing metadata.json (may be corrupted)"
        RETURN true  # Allow but warn
    END IF

    # Validate metadata structure
    SET metadata = read_json(workspace_path + "/.bitbot/metadata.json")

    IF metadata["version"] is NULL:
        WARN "[!] Invalid metadata.json (missing version)"
        RETURN false
    END IF

    RETURN true
END FUNCTION
```

---

## Edge Case Handling

```pseudocode
FUNCTION handle_edge_cases(path) → normalized_path:
    # Edge Case 1: Symlinks
    SET resolved = resolve_symlinks(path)

    # Edge Case 2: Multiple .bitbot in hierarchy
    # Already handled by checking CWD first, then parent

    # Edge Case 3: Temporary filesystem
    IF is_temporary_filesystem(resolved):
        WARN "[!] Workspace on temporary filesystem (/tmp, /dev/shm)"
        WARN "    Data may be lost on reboot"
        PRINT ""
    END IF

    # Edge Case 4: Different filesystem/mount
    # No special handling needed

    # Edge Case 5: Permission issues
    IF NOT is_writable(resolved):
        ERROR "Workspace directory not writable: " + resolved
        EXIT 1
    END IF

    RETURN resolved
END FUNCTION

FUNCTION is_temporary_filesystem(path) → boolean:
    RETURN path starts_with("/tmp") OR
           path starts_with("/dev/shm") OR
           path starts_with("/var/tmp")
END FUNCTION
```

---

## Workspace Walk-Up Search

```pseudocode
FUNCTION find_workspace_in_hierarchy(start_path) → path OR NULL:
    # Walk up directory tree looking for .bitbot/

    SET current = start_path
    SET visited = empty_set

    WHILE current != "/" AND current not in visited:
        ADD current to visited

        IF directory_exists(current + "/.bitbot"):
            RETURN current
        END IF

        SET current = get_parent_directory(current)
    END WHILE

    # Not found
    RETURN NULL
END FUNCTION
```

---

## Prompt Utilities

```pseudocode
FUNCTION prompt_yes_no(question, default) → string:
    # Display question with default indicator
    IF default == "yes":
        PRINT question + " (Y/n): "
    ELSE IF default == "no":
        PRINT question + " (y/N): "
    ELSE:
        PRINT question + " (y/n): "
    END IF

    # Read user input
    SET response = read_line_from_stdin()

    # Handle empty response (use default)
    IF response is empty OR response == "\n":
        RETURN default
    END IF

    # Normalize response
    SET response = lowercase(trim(response))

    IF response == "y" OR response == "yes":
        RETURN "yes"
    ELSE IF response == "n" OR response == "no":
        RETURN "no"
    ELSE:
        PRINT "[!] Invalid input, please enter 'y' or 'n'"
        RETURN prompt_yes_no(question, default)
    END IF
END FUNCTION
```

---

## Implementation Notes

**Key Behaviors**:
1. Check CWD for .bitbot directory
2. Workspace found → use it
3. No workspace → return NULL (caller prompts for init)

**Edge Cases**:
- Symlinks: Follow to canonical path
- Permission issues: Error and exit 1
- Missing config.json: Warn but continue

**Error Handling**:
- No .devcontainer during init → error + exit 4
- Permission denied → error + exit 1
