---
name: restart
description: Restart Claude Code session to reload new skills, manage context, or start fresh. Use when skills have been added/modified, when needing to compact/clear context, or to reload configuration changes.
---

# Restart Claude Code Session

Terminates the current Claude Code session and restarts it with options for resuming, compacting context, or starting fresh.

## When to Use

**Model-Invoked (Automatic):**
- After creating or modifying skills (skills only load at session start)
- When user requests to "restart Claude" or "reload skills"
- When user wants to compact or clear context via restart
- After significant configuration changes that require reload

**User-Invoked (Manual):**
- User types `/restart` to restart with resume
- User types `/restart compact` for context management
- User types `/restart clear` for fresh start

## Restart Modes

### 1. Resume Mode (Default)

Quick restart that preserves conversation history.

**Usage:**
```bash
.claude/skills/restart/scripts/restart.sh resume
```

**Behavior:**
- Detects current session ID automatically
- Exits Claude gracefully
- Restarts with `--resume <session-id>`
- Conversation history is preserved
- New skills and configuration are loaded

**Use cases:**
- Reload newly added skills
- Apply configuration changes
- Quick restart without losing context

### 2. Compact Mode

Exit for context management, then resume.

**Usage:**
```bash
.claude/skills/restart/scripts/restart.sh compact
```

**Behavior:**
- Detects current session ID
- Exits Claude and starts in print mode (`-p`)
- User can run `/compact` to summarize and free tokens
- After compacting, manually resume with provided command
- Conversation history is preserved but compacted

**Use cases:**
- Context window is filling up
- Want to compact before continuing work
- Need to free up tokens for large operations

**Workflow:**
1. Script restarts Claude in `-p` mode
2. Run `/compact` to compress context
3. Resume with: `claude --resume <session-id>`

### 3. Clear Mode

Start completely fresh with no history.

**Usage:**
```bash
.claude/skills/restart/scripts/restart.sh clear
```

**Behavior:**
- Exits Claude gracefully
- Restarts without `--resume` flag
- New session ID is created
- All conversation history is cleared
- Fresh context window

**Use cases:**
- Starting a new task unrelated to current work
- Context is too polluted to be useful
- Want a clean slate
- After completing a major phase of work

## Automatic vs Manual Restart

### In Tmux (Automatic)

When running in a tmux session, restart is fully automated:

- Script detects tmux environment
- Sends restart command to current pane
- Exits Claude
- Claude automatically restarts with specified mode

**Advantages:**
- Seamless experience
- No manual intervention needed
- Fast turnaround

### Outside Tmux (Manual)

When not in tmux, semi-manual process:

- Script displays the restart command
- Exits Claude after user confirmation
- User manually runs the displayed command

**Advantages:**
- Works in any terminal environment
- User has full control over timing

## Session ID Detection

The script automatically detects the current session ID by:

1. Checking `~/.claude/session-env/` directory
2. Finding the most recently modified session directory
3. Using that directory name as the session ID

**Fallback behavior:**
- If session ID cannot be detected
- Script automatically falls back to `clear` mode
- User is notified of the fallback

## Technical Details

**Session Storage:**
- Sessions stored in `~/.claude/session-env/<session-id>/`
- Session ID is a UUID (e.g., `2ea18c2c-a994-46a3-8f5a-d287ffd7dbd1`)
- Most recent session by modification time is considered current

**Exit Mechanism:**
- Script uses `exit 0` to terminate Claude cleanly
- No force kill or SIGTERM signals
- Allows Claude to save state properly

**Tmux Integration:**
- Detects tmux via `$TMUX` environment variable
- Uses `tmux send-keys` to queue restart command
- Command executes after Claude exits

## Example Usage

**Quick restart to load new skills:**
```bash
.claude/skills/restart/scripts/restart.sh
# or
.claude/skills/restart/scripts/restart.sh resume
```

**Restart for context management:**
```bash
.claude/skills/restart/scripts/restart.sh compact
```

**Fresh start:**
```bash
.claude/skills/restart/scripts/restart.sh clear
```

## Important Notes

- Script requires bash shell
- Automatically handles line endings (LF for bash)
- Works in WSL and native Linux environments
- Session detection works across all environments
- Cannot restart from within Docker containers (use host)

## Workflow Integration

**After creating skills:**
1. Create or modify skill in `.claude/skills/`
2. Run restart skill to reload
3. New skill is immediately available

**For context management:**
1. Run restart with `compact` mode
2. Use `/compact` in print mode
3. Resume with preserved but compacted context

**Between major work phases:**
1. Complete current work phase
2. Commit changes
3. Run restart with `clear` mode
4. Start fresh for next phase
