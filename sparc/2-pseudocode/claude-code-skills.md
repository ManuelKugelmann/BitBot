# Claude Code Skills Pseudocode

**Purpose**: Session-aware skills for Claude Code
**Location**: `.claude/skills/`
**Status**: Implemented

---

## Overview

Skills that leverage session tracking to provide restart, automation control, and context management capabilities.

---

## claude-restart Skill

**File**: `.claude/skills/claude-restart/`
**Purpose**: Restart Claude Code session while maintaining context

### SKILL.md

```yaml
---
name: claude-restart
description: Restart Claude Code session to reload skills or manage context. Use after modifying skills, when context is fragmented, or when Claude becomes unresponsive.
---
```

### Scripts

**restart.sh** (main script):

```bash
#!/usr/bin/env bash
# Restart Claude Code session

MODE = "${1:-resume}"  # resume (default), compact, clear

# Validate mode
IF MODE not in [resume, compact, clear]:
    ERROR: "Invalid mode. Use: resume, compact, or clear"
    EXIT 1

# Source session utilities
SCRIPT_DIR = directory_of_this_script
SOURCE "$SCRIPT_DIR/../claude-get-session-info/scripts/get-session-info.sh"

# Get session info (sets CLAUDE_PID and SESSION_ID)
get_session_info

IF CLAUDE_PID empty:
    ERROR: "Cannot find Claude process PID"
    EXIT 1

IF SESSION_ID empty:
    ERROR: "Cannot find session ID"
    EXIT 1

# Kill Claude process
ECHO "Restarting Claude (mode: $MODE)..."
kill $CLAUDE_PID

# Wait for process to die
SLEEP 0.5

# Determine restart command based on mode
CASE MODE:
    "resume":
        # Resume with full context
        RESTART_CMD = "claude --resume $SESSION_ID"

    "compact":
        # Compact context before resuming (future)
        RESTART_CMD = "claude --compact --resume $SESSION_ID"

    "clear":
        # Clear context and start fresh (future)
        RESTART_CMD = "claude --clear --resume $SESSION_ID"

# Exec restart (replaces current process)
exec $RESTART_CMD
```

**compact-resume.sh** (future):

```bash
#!/usr/bin/env bash
# Compact context then resume

# Call main restart script with compact mode
exec "$(dirname "$0")/restart.sh" compact
```

### Usage Patterns

```
User: "/claude-restart"
    → Skill invoked
    → Restarts with full context (resume mode)

User: "reload skills"
    → Claude decides to use claude-restart
    → Skills reloaded after restart

User: "compact context"
    → Claude uses compact-resume.sh (future)
    → Context summarized, then resumed
```

---

## claude-get-session-info Skill

**File**: `.claude/skills/claude-get-session-info/`
**Purpose**: Shared utility for getting session ID and PID

### SKILL.md

```yaml
---
name: claude-get-session-info
description: Shared utility script for getting Claude PID and Session ID. Source this in other scripts to access CLAUDE_PID and SESSION_ID variables.
---
```

### Scripts

**get-session-info.sh** (sourced by other skills):

```bash
#!/usr/bin/env bash
# Shared utility for session info
# Usage: source this file, then call get_session_info

# Find project root
FUNCTION find_project_root():
    CURRENT_DIR = pwd

    WHILE CURRENT_DIR != "/":
        IF directory_exists("$CURRENT_DIR/.bitbot"):
            RETURN CURRENT_DIR

        IF directory_exists("$CURRENT_DIR/.claude"):
            RETURN CURRENT_DIR

        CURRENT_DIR = parent_directory(CURRENT_DIR)

    RETURN pwd

# Find Claude PID
FUNCTION find_claude_pid():
    CURRENT_PID = $$

    WHILE CURRENT_PID != 1:
        PROCESS_NAME = get_process_name(CURRENT_PID)

        IF PROCESS_NAME contains "claude":
            RETURN CURRENT_PID

        CURRENT_PID = get_parent_pid(CURRENT_PID)

    RETURN empty

# Get session info from wrapper state
FUNCTION get_session_info():
    # Export for caller
    export CLAUDE_PID=$(find_claude_pid)

    # Export SESSION_ID from environment (set by session-start hook)
    IF CLAUDE_SESSION_ID exists:
        export SESSION_ID = CLAUDE_SESSION_ID
    ELSE:
        export SESSION_ID = empty
```

**Usage in other skills**:

```bash
#!/usr/bin/env bash
# Another skill that needs session info

SOURCE "../claude-get-session-info/scripts/get-session-info.sh"
get_session_info

IF CLAUDE_PID empty OR SESSION_ID empty:
    ERROR: "Cannot get session info"
    EXIT 1

# Use CLAUDE_PID and SESSION_ID
# ...
```

---

## claude-do-not-stop Skill

**File**: `.claude/skills/claude-do-not-stop/`
**Purpose**: Enable continuous workflow automation

### SKILL.md

```yaml
---
name: claude-do-not-stop
description: Enable Stop hook automation for continuous multi-phase workflows. Use when working until finished, implementing multiple tasks sequentially, running test-fix-commit loops, or workflows requiring automatic continuation. User can invoke with /claude-do-not-stop [reason].
---
```

### Scripts

**do-not-stop.sh**:

```bash
#!/usr/bin/env bash
# Enable automation

REASON = "$1"

IF REASON empty:
    REASON = "Continue working. Check TODO list and implement the next pending task."

# Find project root
PROJECT_ROOT = find_project_root()
CONTROL_FILE = "$PROJECT_ROOT/.bitbot/DO-NOT-STOP.txt"

# Create directory if needed
mkdir -p "$(dirname "$CONTROL_FILE")"

# Write reason to control file
ECHO "$REASON" > "$CONTROL_FILE"

ECHO "✓ Automation enabled"
ECHO "  Reason: $REASON"
ECHO ""
ECHO "To disable: /claude-allow-stop"

EXIT 0
```

### Usage

```
User: "/claude-do-not-stop"
    → Default reason: "Continue working. Check TODO list..."
    → Creates DO-NOT-STOP.txt
    → Claude continues after each response

User: "/claude-do-not-stop implement all tests"
    → Custom reason: "implement all tests"
    → Claude continues with that context
```

---

## claude-allow-stop Skill

**File**: `.claude/skills/claude-allow-stop/`
**Purpose**: Disable continuous workflow automation

### SKILL.md

```yaml
---
name: claude-allow-stop
description: Disable Stop hook automation to allow normal completion. Use when asking questions, discussing approaches, working interactively, brainstorming, or workflows requiring back-and-forth conversation. User can invoke with /claude-allow-stop.
---
```

### Scripts

**allow-stop.sh**:

```bash
#!/usr/bin/env bash
# Disable automation

# Find project root
PROJECT_ROOT = find_project_root()
CONTROL_FILE = "$PROJECT_ROOT/.bitbot/DO-NOT-STOP.txt"

# Remove control file
IF file_exists("$CONTROL_FILE"):
    DELETE "$CONTROL_FILE"
    ECHO "✓ Automation disabled"
    ECHO "  Claude will stop normally after responses"
ELSE:
    ECHO "ℹ Automation was already disabled"

EXIT 0
```

### Usage

```
User: "/claude-allow-stop"
    → Deletes DO-NOT-STOP.txt
    → Claude stops normally
    → User must manually provide prompts
```

---

## Generic Skills (Not Session-Specific)

### check-bash Skill

**Purpose**: Validate bash script syntax

```bash
#!/usr/bin/env bash
# Check bash syntax without executing

FILE = "$1"

IF FILE empty OR NOT file_exists(FILE):
    ERROR: "Usage: check-bash <file.sh>"
    EXIT 1

# Check syntax
bash -n "$FILE"

IF exit_code == 0:
    ECHO "✓ Syntax OK: $FILE"
    EXIT 0
ELSE:
    ECHO "✗ Syntax errors in: $FILE"
    EXIT 1
```

### fix-line-endings Skill

**Purpose**: Convert CRLF to LF line endings

```bash
#!/usr/bin/env bash
# Fix line endings (CRLF → LF)

FILE = "$1"

IF FILE empty OR NOT file_exists(FILE):
    ERROR: "Usage: fix-line-endings <file>"
    EXIT 1

# Fix line endings
IF command dos2unix exists:
    dos2unix "$FILE"
ELSE:
    # Fallback using sed
    sed -i 's/\r$//' "$FILE"

ECHO "✓ Fixed line endings: $FILE"
EXIT 0
```

### fix-line-endings-check-bash Skill

**Purpose**: Fix line endings AND check bash syntax (combined)

```bash
#!/usr/bin/env bash
# Fix line endings then check syntax

FILE = "$1"

IF FILE empty OR NOT file_exists(FILE):
    ERROR: "Usage: fix-line-endings-check-bash <file.sh>"
    EXIT 1

# Get skill directory
SKILLS_DIR = parent_directory(this_script, 3)  # Up to .claude/skills/

# Fix line endings
"$SKILLS_DIR/fix-line-endings/scripts/fix-line-endings.sh" "$FILE"
FIX_EXIT = exit_code

# Check syntax
"$SKILLS_DIR/check-bash/scripts/check-bash.sh" "$FILE"
CHECK_EXIT = exit_code

# Report results
IF FIX_EXIT == 0 AND CHECK_EXIT == 0:
    ECHO "✓ Line endings fixed and syntax OK: $FILE"
    EXIT 0
ELSE:
    IF FIX_EXIT != 0:
        ECHO "✗ Failed to fix line endings: $FILE"
    IF CHECK_EXIT != 0:
        ECHO "✗ Syntax errors: $FILE"
    EXIT 1
```

### run-with-timeout Skill

**Purpose**: Execute commands with timeout protection

```bash
#!/usr/bin/env bash
# Run command with timeout

TIMEOUT_SECONDS = "$1"
shift
COMMAND = "$@"

IF TIMEOUT_SECONDS empty OR COMMAND empty:
    ERROR: "Usage: run-with-timeout <seconds> <command>"
    EXIT 1

# Run with timeout
timeout $TIMEOUT_SECONDS $COMMAND

EXIT_CODE = exit_code

IF EXIT_CODE == 124:
    ECHO "✗ Command timed out after ${TIMEOUT_SECONDS}s"
    EXIT 124
ELSE:
    EXIT $EXIT_CODE
```

---

## Skill Discovery

**How Claude finds skills**:

```
1. Claude Code starts
2. Scans .claude/skills/ directory
3. Reads each SKILL.md file
4. Extracts name and description
5. Makes skills available for invocation

User: "restart claude"
    → Claude matches description: "Restart Claude Code session"
    → Invokes claude-restart skill

User: "fix bash syntax"
    → Claude matches description: "Check bash script syntax"
    → Invokes check-bash skill
```

**Skill naming convention**:
- `claude-*` = Claude Code session-aware skills
- `fix-*` = File fixing/formatting skills
- `check-*` = Validation skills
- `run-*` = Execution utilities

---

## Skill Configuration

**No configuration needed** - skills are auto-discovered from:
```
.claude/skills/
├── claude-restart/SKILL.md
├── claude-get-session-info/SKILL.md
├── claude-do-not-stop/SKILL.md
├── claude-allow-stop/SKILL.md
├── check-bash/SKILL.md
├── fix-line-endings/SKILL.md
├── fix-line-endings-check-bash/SKILL.md
└── run-with-timeout/SKILL.md
```

**No allow list required** - skills are automatically trusted

**Permissions** handled by settings.json (hooks only):
```json
{
  "permissions": {
    "allow": []
  }
}
```

---

## Success Criteria

**Session Skills**:
- [x] claude-restart works reliably
- [x] claude-get-session-info provides correct PID/session ID
- [x] claude-do-not-stop enables automation
- [x] claude-allow-stop disables automation

**Utility Skills**:
- [x] check-bash validates syntax correctly
- [x] fix-line-endings converts CRLF→LF
- [x] fix-line-endings-check-bash combines both operations
- [x] run-with-timeout prevents hanging commands

**Usability**:
- [x] Skills auto-discovered by Claude
- [x] Clear descriptions help Claude choose right skill
- [x] Skills fail gracefully with helpful errors
- [x] Skills work without user configuration

---

## Future Skills

**Context Management**:
```bash
# claude-compact skill
Compact context and show token savings

# claude-clear skill
Clear context completely (fresh start)
```

**Session Management**:
```bash
# claude-list-sessions skill
List all active Claude sessions

# claude-switch-session skill
Switch between Claude sessions
```

**Workspace Analysis**:
```bash
# analyze-workspace skill
Show project structure, dependencies, git status

# suggest-tasks skill
AI-suggested tasks based on workspace analysis
```
