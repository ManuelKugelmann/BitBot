# Git Utilities Pseudocode

**Component**: Git utilities
**Script**: `lib/util/git.sh`
**Purpose**: Git status checking and recommendations

---

## Overview

Reusable git utility functions for:
- Checking git repository status
- Recommending git setup (init, remote, push)
- Providing skip options for all recommendations

---

## Git Push Recommendation

```pseudocode
FUNCTION recommend_git_push_before_init(workspace_path):
    # Show git recommendations before initialization
    # BitBot will create files and AI agent will modify .devcontainer
    # Recommend git setup and pushing current state first

    # Check if recommendation is disabled in config
    # From lib/util/helpers.md
    CALL get_merged_workspace_config(workspace_path) → config
    IF config.skip_push_recommendation == true:
        # User has disabled git push recommendations - skip silently
        RETURN
    END IF

    IF NOT command_exists("git"):
        # Git not installed - skip silently
        RETURN
    END IF

    # Check if this is a git repository
    IF NOT directory_exists(workspace_path + "/.git"):
        # Not a git repo - recommend creating one
        PRINT "┌─────────────────────────────────────────────────────────┐"
        PRINT "│ ℹ️  RECOMMENDATION: Initialize git repository           │"
        PRINT "└─────────────────────────────────────────────────────────┘"
        PRINT ""
        PRINT "BitBot AI agent will modify files in this workspace."
        PRINT "Git helps you track and revert changes if needed."
        PRINT ""
        PRINT "Recommended steps:"
        PRINT "  $ git init"
        PRINT "  $ git add ."
        PRINT "  $ git commit -m \"Initial commit\""
        PRINT "  $ git remote add origin <url>"
        PRINT "  $ git push -u origin main"
        PRINT ""

        SET choices = ["Exit and set up git", "Skip this time", "Skip permanently (update config)"]
        CALL prompt_choice("What would you like to do?", choices, 0) → choice
        PRINT ""

        IF choice == 0:
            # Exit so user can set up git
            PRINT "Please set up git and run 'bitbot init' again."
            EXIT 0
        ELSE IF choice == 2:
            # Skip permanently - update workspace config
            CALL update_workspace_config(workspace_path, "skip_push_recommendation", true)
            PRINT "  ✓ Updated .bitbot/config.json to skip git push recommendations"
            PRINT ""
        END IF
        # choice == 1: Skip this time - just continue

        RETURN
    END IF

    # Check if there's a remote configured
    EXECUTE "cd " + workspace_path + " && git remote -v" → remotes
    IF remotes == "":
        # No remote - recommend adding one
        PRINT "┌─────────────────────────────────────────────────────────┐"
        PRINT "│ ℹ️  RECOMMENDATION: Add git remote                      │"
        PRINT "└─────────────────────────────────────────────────────────┘"
        PRINT ""
        PRINT "No git remote configured. Adding a remote allows you to:"
        PRINT "  • Back up your work to a remote server"
        PRINT "  • Easily revert AI agent changes if needed"
        PRINT "  • Collaborate with others"
        PRINT ""
        PRINT "Recommended steps:"
        PRINT "  $ git remote add origin <url>"
        PRINT "  $ git push -u origin main"
        PRINT ""

        SET choices = ["Exit and add remote", "Skip this time", "Skip permanently (update config)"]
        CALL prompt_choice("What would you like to do?", choices, 0) → choice
        PRINT ""

        IF choice == 0:
            # Exit so user can add remote
            PRINT "Please add a remote and run 'bitbot init' again."
            EXIT 0
        ELSE IF choice == 2:
            # Skip permanently - update workspace config
            CALL update_workspace_config(workspace_path, "skip_push_recommendation", true)
            PRINT "  ✓ Updated .bitbot/config.json to skip git push recommendations"
            PRINT ""
        END IF
        # choice == 1: Skip this time - just continue

        RETURN
    END IF

    # Show git status
    EXECUTE "cd " + workspace_path + " && git status" → status_output

    # Check if there are unpushed commits or uncommitted changes
    SET has_changes = (status_output contains "ahead" OR status_output contains "modified:" OR status_output contains "Untracked")

    IF has_changes:
        PRINT "┌─────────────────────────────────────────────────────────┐"
        PRINT "│ ⚠️  RECOMMENDATION: Push to remote before init          │"
        PRINT "└─────────────────────────────────────────────────────────┘"
        PRINT ""
        PRINT "BitBot will create .bitbot/ and .devcontainer files."
        PRINT "AI agent will then modify your .devcontainer configuration."
        PRINT "Push your current state first to easily revert if needed."
        PRINT ""

        # Show current git status
        PRINT status_output
        PRINT ""

        PRINT "Recommended steps:"
        PRINT "  $ git add .         # Stage changes (if needed)"
        PRINT "  $ git commit -m \"...\" # Commit (if needed)"
        PRINT "  $ git push          # Push to remote"
        PRINT ""

        SET choices = ["Exit and push changes", "Skip this time", "Skip permanently (update config)"]
        CALL prompt_choice("What would you like to do?", choices, 0) → choice
        PRINT ""

        IF choice == 0:
            # Exit so user can push
            PRINT "Please push your changes and run 'bitbot init' again."
            EXIT 0
        ELSE IF choice == 2:
            # Skip permanently - update workspace config
            CALL update_workspace_config(workspace_path, "skip_push_recommendation", true)
            PRINT "  ✓ Updated .bitbot/config.json to skip git push recommendations"
            PRINT ""
        END IF
        # choice == 1: Skip this time - just continue
    END IF
END FUNCTION
```

---

## Git Safety Checks (During Init)

```pseudocode
FUNCTION check_git_safety(workspace_path):
    # Check git status and warn about uncommitted changes and secrets
    # Non-blocking - warns but doesn't prevent initialization

    # Check if safety checks are disabled in config
    # From lib/util/helpers.md
    CALL get_merged_workspace_config(workspace_path) → config
    IF config.skip_safety_checks == true:
        # User has disabled git safety checks - skip silently
        RETURN
    END IF

    IF NOT command_exists("git"):
        # Git not installed - skip
        RETURN
    END IF

    # Check if this is a git repository
    SET git_dir = workspace_path + "/.git"
    IF NOT directory_exists(git_dir):
        # Already handled by recommend_git_push_before_init
        RETURN
    END IF

    # Check git status
    EXECUTE "cd " + workspace_path + " && git status --porcelain" → status_output

    IF status_output != "":
        # Has uncommitted changes (only shown if user skipped push recommendation)
        PRINT "[!] Git repository has uncommitted changes"
        PRINT ""
        EXECUTE "cd " + workspace_path + " && git status --short" → short_status
        PRINT short_status
        PRINT ""
        PRINT "    Recommendation: Commit or stash changes before AI work"
        PRINT "    This allows you to easily revert AI changes if needed."
        PRINT ""
    END IF

    # Check if there's a remote
    EXECUTE "cd " + workspace_path + " && git remote -v" → remotes

    IF remotes != "":
        # Generic warning about AI agents and secrets (applies to all repos with remotes)
        PRINT "┌─────────────────────────────────────────────────────────┐"
        PRINT "│ ⚠️  AI AGENT SAFETY WARNING                             │"
        PRINT "└─────────────────────────────────────────────────────────┘"
        PRINT ""
        PRINT "  WARNING: AI agents may accidentally commit secrets:"
        PRINT "    • API keys, tokens, passwords"
        PRINT "    • Environment variables (.env files)"
        PRINT "    • SSH keys, certificates"
        PRINT "    • Database credentials"
        PRINT ""
        PRINT "  Recommendations:"
        PRINT "    1. Review ALL changes before committing/pushing"
        PRINT "    2. Use .gitignore for sensitive files"
        PRINT "    3. Consider using git-secrets or similar tools"
        PRINT "    4. Never commit credentials - use environment variables"
        PRINT ""

        SET choices = ["Exit and review .gitignore", "Skip this time", "Skip permanently (update config)"]
        CALL prompt_choice("What would you like to do?", choices, 1) → choice  # Default to "Skip this time"
        PRINT ""

        IF choice == 0:
            # Exit so user can review .gitignore
            PRINT "Please review your .gitignore and run the command again."
            EXIT 0
        ELSE IF choice == 2:
            # Skip permanently - update workspace config
            CALL update_workspace_config(workspace_path, "skip_safety_checks", true)
            PRINT "  ✓ Updated .bitbot/config.json to skip safety warnings"
            PRINT ""
        END IF
        # choice == 1: Skip this time - just continue
    END IF
END FUNCTION
```

---

## Implementation Notes

**Key Features**:
- All recommendations have 3-choice prompts:
  1. **Exit and fix** (default) - Exit so user can fix the issue
  2. **Skip this time** - Continue without fixing (one-time skip)
  3. **Skip permanently** - Update workspace config to never ask again
- Instructions only - no git automation
- Reusable across different BitBot commands
- **Config-based permanent skip** - Can be disabled via config or prompt

**Config-Based Skip Options**:
Both functions check merged config (workspace overrides global) before running:

- `skip_push_recommendation` - Permanently disable push recommendations
- `skip_safety_checks` - Permanently disable safety warnings

**Config locations**:
- Global: `{BITBOT_INSTALL}/config.json` - Affects all workspaces
- Workspace: `.bitbot/config.json` - Affects only this workspace (overrides global)

**Config merge** (via `get_merged_workspace_config()`):
- Simple top-level merge (workspace overrides global)
- No external dependencies required
- Workspace settings take precedence over global settings

**Example config.json**:
```json
{
  "skip_push_recommendation": false,
  "skip_safety_checks": false
}
```

**Usage**:
- `recommend_git_push_before_init()` - Called at start of workspace init, work, config
- `check_git_safety()` - Called after git push recommendation
  - Shows uncommitted changes warning (if any)
  - Shows generic AI agent safety warning (if repo has remote)
  - Both warnings have 3-choice prompts with permanent skip option
- Both functions are non-destructive and provide clear guidance
