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
    # MVP: Simple CWD → parent (auto-use) → return NULL

    # Step 1: Check current directory
    SET cwd = get_current_directory()

    IF directory_exists(cwd + "/.bitbot"):
        PRINT "[i] Using workspace: " + cwd
        RETURN cwd
    END IF

    # Step 2: Check parent directory (auto-use if found)
    SET parent = get_parent_directory(cwd)

    IF parent != "/" AND directory_exists(parent + "/.bitbot"):
        PRINT "[i] Using parent workspace: " + parent
        PRINT "[i] (Current dir: " + cwd + ")"
        RETURN parent
    END IF

    # Step 3: No workspace found
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

    # Create metadata.json
    SET metadata = {
        "version": "1.0",
        "created": current_iso8601_timestamp(),
        "workspace_hash": generate_hash(path)
    }

    CALL write_json(path + "/.bitbot/metadata.json", metadata)

    # Check for existing .devcontainer
    IF NOT directory_exists(path + "/.devcontainer"):
        ERROR "No .devcontainer found. Please create one manually or copy from a template."
        PRINT "Example: cp -r ~/.bitbot/templates/default/.devcontainer ."
        EXIT 4
    END IF

    PRINT "[+] Workspace initialized"
    PRINT "[i] Run 'bitbot work' to start"
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

## Implementation Notes (MVP Simplified)

**Key Behaviors**:
1. CWD takes priority over parent
2. Parent workspace **automatically used** (no prompt)
3. No workspace found → return NULL (caller handles init)

**Simplifications for MVP**:
- Removed non-interactive mode (future feature)
- Removed workspace prompts (auto-use parent)
- Removed `--workspace` flag (future feature)
- Minimal `.bitbot/` structure (metadata.json only)
- No template wizard (requires existing .devcontainer)

**Edge Cases**:
- Symlinks: Follow to canonical path
- Multiple .bitbot: Use closest (CWD > parent)
- Permission issues: Error and exit 1
- Corrupted metadata: Warn but continue

**Error Handling**:
- No .devcontainer during init → error + exit 4
- Permission denied → error + exit 1

**Next Steps**:
- Container launch (03_container-launch.md)
- First-run simplified (06_first-run.md)
