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
FUNCTION detect_workspace(options) → workspace_path OR NULL:
    # Future: --workspace flag to override detection
    # MVP: Simple CWD → parent → initialize flow

    # Step 1: Check current directory
    SET cwd = get_current_directory()

    IF directory_exists(cwd + "/.bitbot"):
        PRINT "[i] Using workspace: " + cwd
        RETURN cwd
    END IF

    # Step 2: Check parent directory
    SET parent = get_parent_directory(cwd)

    IF parent != "/" AND directory_exists(parent + "/.bitbot"):
        # Found in parent, prompt user
        CALL prompt_use_parent_workspace(parent, cwd, options) → use_parent

        IF use_parent:
            RETURN parent
        ELSE:
            # User chose to create new workspace in CWD
            CALL initialize_workspace_in(cwd, options)
            RETURN cwd
        END IF
    END IF

    # Step 3: No workspace found
    CALL prompt_initialize_workspace(cwd, options) → should_initialize

    IF should_initialize:
        CALL initialize_workspace_in(cwd, options)
        RETURN cwd
    ELSE:
        # User declined, exit
        RETURN NULL
    END IF
END FUNCTION
```

---

## Prompt: Use Parent Workspace

```pseudocode
FUNCTION prompt_use_parent_workspace(parent_path, cwd, options) → boolean:
    # Non-interactive mode: always use parent
    IF options["--non-interactive"]:
        PRINT "[i] Using parent workspace (non-interactive): " + parent_path
        RETURN true
    END IF

    PRINT ""
    PRINT "Found BitBot workspace in parent directory:"
    PRINT "  " + parent_path
    PRINT ""
    PRINT "Current directory:"
    PRINT "  " + cwd
    PRINT ""

    CALL prompt_yes_no("Use parent workspace?", default="yes") → response

    RETURN response == "yes"
END FUNCTION
```

---

## Prompt: Initialize Workspace

```pseudocode
FUNCTION prompt_initialize_workspace(cwd, options) → boolean:
    # Non-interactive mode: fail
    IF options["--non-interactive"]:
        ERROR "No workspace found. Run 'bitbot init' to create one."
        RETURN false
    END IF

    PRINT ""
    PRINT "No BitBot workspace found."
    PRINT ""
    PRINT "Initialize workspace in current directory?"
    PRINT "  " + cwd
    PRINT ""

    CALL prompt_yes_no("Initialize?", default="yes") → response

    RETURN response == "yes"
END FUNCTION
```

---

## Initialize Workspace

```pseudocode
FUNCTION initialize_workspace_in(path, options):
    PRINT "[>] Initializing BitBot workspace in: " + path

    # Create .bitbot directory structure
    CALL create_directory(path + "/.bitbot")
    CALL create_directory(path + "/.bitbot/logs")
    CALL create_directory(path + "/.bitbot/sessions")
    CALL create_directory(path + "/.bitbot/state")
    CALL create_directory(path + "/.bitbot/mcp")

    # Create metadata.json
    SET metadata = {
        "version": "1.0",
        "created": current_iso8601_timestamp(),
        "workspace_name": basename(path),
        "workspace_hash": generate_hash(path),
        "default_mode": "work",
        "default_agent": null
    }

    CALL write_json(path + "/.bitbot/metadata.json", metadata)

    # Check for existing .devcontainer
    IF directory_exists(path + "/.devcontainer"):
        PRINT "[i] Found existing .devcontainer, keeping it"
    ELSE:
        PRINT "[>] No .devcontainer found"

        # Launch workspace setup wizard (SPEC-08)
        CALL workspace_setup_wizard(path, options)
    END IF

    PRINT "[+] Workspace initialized successfully"

    # Log initialization
    CALL audit_log("workspace_init", {
        "path": path,
        "timestamp": current_iso8601_timestamp()
    })
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

## Workspace Hash Generation

```pseudocode
FUNCTION generate_hash(path) → hash_string:
    # Generate short hash for container naming
    # Format: first 8 chars of SHA256(absolute_path)

    SET absolute = resolve_path(path)
    SET sha256 = sha256_hash(absolute)
    SET short_hash = substring(sha256, 0, 8)

    RETURN short_hash
END FUNCTION
```

---

## Implementation Notes

**Key Behaviors**:
1. CWD takes priority over parent
2. Parent workspace requires user confirmation (interactive mode)
3. No workspace found → prompt to initialize
4. Non-interactive mode: use parent if found, else fail

**Future Feature**: `--workspace <path>` flag to override auto-detection

**Edge Cases Handled**:
- Symlinks: Follow and resolve to canonical path
- Multiple .bitbot in hierarchy: Use closest (CWD > parent)
- Temporary filesystem: Warn but allow
- Different filesystem: Allow (no special handling)
- Permission issues: Error and exit

**Error Handling**:
- No workspace in non-interactive → error + exit 4
- Permission denied → error + exit 1
- Corrupted metadata → warn but continue

**Next Steps**:
- Implement container launch (03_container-launch.md)
- Implement workspace initialization wizard (part of 06_first-run.md)
