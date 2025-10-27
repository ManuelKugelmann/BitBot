# ccstatusline Setup for BitBot Multi-Agent Workflows

## Overview

ccstatusline is a beautiful, customizable statusline for Claude Code that displays real-time information including git worktree status - essential for multi-agent workflows where each Claude instance works in isolated worktrees.

## Why ccstatusline for BitBot?

| Feature | Benefit for Multi-Agent Work |
|---------|------------------------------|
| **Git Worktree Widget** | Shows which isolated workspace you're in |
| **Git Branch Display** | See current branch at a glance |
| **Session Cost Tracking** | Monitor API usage across instances |
| **Model Display** | Know which Claude model is active |
| **Custom Commands** | Extend with project-specific info |

## Installation

ccstatusline requires no global installation. Execute directly using package managers:

```bash
# Using npm
npx ccstatusline@latest

# Using Bun (faster, recommended on Windows)
bunx ccstatusline@latest

# Using Yarn
yarn dlx ccstatusline@latest

# Using pnpm
pnpm dlx ccstatusline@latest
```

## Quick Setup

```bash
# Run interactive TUI configuration
bunx ccstatusline@latest

# Configure your widgets:
# 1. Git Branch
# 2. Git Worktree ⭐ (IMPORTANT for multi-agent)
# 3. Model Name
# 4. Session Cost
# 5. Current Working Directory
# 6. Git Changes

# Select "Install to Claude Code" from menu
```

## Configuration Storage

According to official documentation and testing:

**Primary Location**: `~/.config/ccstatusline/settings.json`

**Claude Code Integration**: `~/.claude/settings.json`
```json
{
  "statusLine": "bunx ccstatusline@latest"
}
```

**Override**: Set `CLAUDE_CONFIG_DIR` environment variable
```bash
export CLAUDE_CONFIG_DIR=/custom/path/to/.claude
```

## Worktree Widget Display

When using `.claude/tools/worktree-manager.sh`:

**Main Worktree**:
```
🌳 main (+2)
```
Indicates main repository with 2 linked worktrees

**Linked Worktree**:
```
🌿 claude-20251025-214500
```
Shows you're in an isolated worktree with timestamp

**No Worktrees**:
```
(widget not shown)
```

## Integration with BitBot Worktree Workflow

### Workflow Example

1. **Create isolated worktree**:
   ```bash
   .claude/tools/worktree-manager.sh create
   cd ~/.bitbot-worktrees/claude-20251025-214500
   ```

2. **Start Claude Code** - statusline shows:
   ```
   trunk 🌿 claude-20251025-214500 │ Sonnet │ ~/bitbot-work/... │ $0.023
   ```

3. **Always know your context**:
   - Which branch you're on
   - Which worktree (isolated workspace)
   - Which model you're using
   - Current cost of session

4. **Sync with main branch**:
   ```bash
   .claude/tools/worktree-manager.sh sync
   ```

5. **Create PR and clean up**:
   ```bash
   git push && gh pr create
   .claude/tools/worktree-manager.sh clean
   ```

## Recommended Widget Configuration

### Line 1: Essential Context
- Git Branch
- Git Worktree ⭐
- Model Name
- Current Working Directory
- Session Cost

### Line 2: Metrics (Optional)
- Token counts (Input/Output/Cached)
- Context usage percentage
- Block timer
- Session clock

### Line 3: Custom (Optional)
- Custom text (e.g., project name)
- Custom command output
- Git changes count

## Available Widgets

**Git Information**:
- Git Branch
- Git Worktree ⭐
- Git Changes

**Session Info**:
- Model Name
- Session Cost
- Session Clock
- Block Timer

**Context Metrics**:
- Token counts (Input, Output, Cached, Total)
- Context Length
- Context Percentage
- Terminal Width

**Location**:
- Current Working Directory
- Version
- Output Style

**Custom**:
- Custom Text (supports emoji)
- Custom Command (shell command output)

**Structural**:
- Separator (|, -, comma, space)
- Flex Separator (fills space)

## Powerline Support

Enable beautiful arrow separators:

1. ccstatusline will prompt to install Powerline fonts
2. Accept installation for enhanced visuals
3. Enable Powerline mode in TUI settings
4. Configure arrow styles and colors

## Multi-Line Support

ccstatusline supports multiple independent status lines with different widgets and formatting for each line.

## Global Formatting Options

- Default Padding
- Default Separator
- Inherit Colors
- Global Bold
- Override Foreground/Background colors

## Package Manager Comparison

| Manager | Speed | Recommendation |
|---------|-------|----------------|
| **npm** | Slow | Universal, works everywhere |
| **Bun** | Fast | **Recommended for Windows** |
| **Yarn** | Medium | If already using Yarn |
| **pnpm** | Medium | If already using pnpm |

**Tip**: On Windows, use Bun (`bunx`) for significantly faster startup times.

## Troubleshooting

### Statusline not showing

```bash
# Check Claude Code settings
cat ~/.claude/settings.json | grep statusLine

# Test ccstatusline directly
bunx ccstatusline@latest

# Verify config exists
cat ~/.config/ccstatusline/settings.json
```

### Slow startup

- **Solution**: Use Bun instead of npm
- Change from `npx ccstatusline@latest` to `bunx ccstatusline@latest`
- Update in `~/.claude/settings.json`

### Worktree not showing

- Ensure you're in a git worktree
- Check with: `git worktree list`
- Verify Git Worktree widget is enabled in ccstatusline config

### Wrong directory displayed

- Check current worktree: `git worktree list`
- Verify you're in correct directory: `pwd`
- Switch worktrees if needed: `cd ~/.bitbot-worktrees/<worktree-name>`

## Configuration File Location

**Primary Config**:
```
~/.config/ccstatusline/settings.json
```

This is where ccstatusline stores its configuration after you use the interactive TUI.

**Claude Code Integration**:
```
~/.claude/settings.json
```

This tells Claude Code to use ccstatusline for the statusline.

## Example Configuration

See `sparc/0-research/CCSTATUSLINE_CONFIG_EXAMPLE.json` for a complete configuration with worktree widget enabled.

**To use the example config:**
```bash
# Backup existing config
cp ~/.config/ccstatusline/settings.json ~/.config/ccstatusline/settings.json.backup

# Copy example config
cp sparc/0-research/CCSTATUSLINE_CONFIG_EXAMPLE.json ~/.config/ccstatusline/settings.json
```

**Line 1 widgets** (essential context):
- Git Branch (blue)
- Git Worktree (magenta) ⭐
- Model Name (cyan)
- Current Working Directory (green)
- Session Cost (yellow)

**Line 2 widgets** (metrics):
- Context Length
- Input Tokens
- Output Tokens
- Cached Tokens
- Context Percentage

## Integration with Container Templates

For BitBot container templates (workspace mode):

1. **Host Level**: Configure ccstatusline on host
   ```bash
   bunx ccstatusline@latest
   ```

2. **Container Level**: Mount `~/.config/ccstatusline` (if needed)
   ```json
   "mounts": [
     "source=${localEnv:HOME}/.config/ccstatusline,target=/home/vscode/.config/ccstatusline,type=bind"
   ]
   ```

3. **Global Settings**: Already mounted via BitBot global config system

## References

- [ccstatusline GitHub](https://github.com/sirmalloc/ccstatusline)
- [Claude Code Statusline Docs](https://docs.claude.com/en/docs/claude-code/statusline)
- [BitBot Worktree Manager](/.claude/tools/worktree-manager.sh)
- [BitBot Worktree Workflow](/.claude/CLAUDE.md#git-worktree-workflow)
