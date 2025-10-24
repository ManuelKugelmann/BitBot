# Claude Code Configuration and Data Files

## Overview

Claude Code uses a hierarchical configuration system with files in multiple locations. Understanding which files to version control and which to keep local is essential for team collaboration.

---

## Configuration Files

### Global User Settings

**Location:** `~/.claude/settings.json`

**Purpose:** Global preferences that apply to all projects

**Version Control:** ❌ Keep local (typically in dotfiles repo, not project repos)

**Contents:**
- Global preferences (e.g., `alwaysThinkingEnabled`)
- Status line configuration
- Model selection defaults
- Terminal appearance settings

**Example:**
```json
{
  "alwaysThinkingEnabled": false,
  "statusLine": {
    "type": "command",
    "command": "npx -y ccstatusline@latest",
    "padding": 0
  }
}
```

---

### Project Settings (Shared)

**Location:** `.claude/settings.json` (in project root)

**Purpose:** Team-shared configuration checked into source control

**Version Control:** ✅ **Commit to repository**

**Contents:**
- Custom tools and auto-approval settings
- Project-specific permissions (allow/deny rules)
- Hooks (event-triggered scripts)
- Project-specific environment variables
- MCP server configurations
- Output styles

**Example:**
```json
{
  "tools": [
    {
      "name": "fix-line-endings",
      "description": "Fix CRLF to LF line endings",
      "command": ".claude/tools/fix-line-endings.sh",
      "autoApprove": true,
      "args": {
        "files": {
          "type": "array",
          "description": "File paths to fix",
          "required": true
        }
      }
    }
  ],
  "permissions": {
    "allow": [
      ".claude/tools/**"
    ]
  }
}
```

---

### Project Settings (Local)

**Location:** `.claude/settings.local.json` (in project root)

**Purpose:** Personal preferences and experimentation (overrides shared settings)

**Version Control:** ❌ Keep local (auto-ignored by git)

**Contents:**
- Personal tool overrides
- Local-only environment variables
- Experimental settings
- Machine-specific configurations

---

### Project Tools

**Location:** `.claude/tools/` (in project root)

**Purpose:** Custom scripts and tools for the project

**Version Control:** ✅ **Commit to repository**

**Contents:**
- Shell scripts referenced by tools in settings.json
- Project-specific automation
- Build/test helpers

---

### Enterprise Settings

**Location:** System paths (macOS: `/Library/Application Support/ClaudeCode/`)

**Purpose:** IT/DevOps-managed policies

**Version Control:** ❌ Deployed separately

**Contents:**
- Organization-wide policies
- Enforced security settings
- Managed MCP servers

---

## Memory Files (CLAUDE.md)

Memory files contain instructions and preferences that Claude loads automatically.

### Hierarchy (precedence order)

1. **Enterprise level** (organization): System directories
2. **Project level** (team): `./CLAUDE.md` or `./.claude/CLAUDE.md`
3. **User level** (personal): `~/.claude/CLAUDE.md`
4. **Local project** (deprecated): `./CLAUDE.local.md`

**Version Control:**
- Project-level CLAUDE.md: ✅ **Commit**
- User-level CLAUDE.md: ❌ Keep local (dotfiles)
- Local CLAUDE.local.md: ❌ Keep local (deprecated)

**Contents:**
- Code style guidelines
- Common commands
- Project architecture details
- Coding standards
- Personal tooling shortcuts

---

## Session and Runtime Data

**Location:** `~/.claude/`

**Version Control:** ❌ Never commit

| File/Directory | Purpose | Sensitive |
|----------------|---------|-----------|
| `.credentials.json` | Authentication tokens | ⚠️ Yes |
| `history.jsonl` | Command history across all projects | No |
| `projects/` | Per-project metadata (named by path hash) | No |
| `session-env/` | Session-specific environment (UUIDs) | No |
| `todos/` | Session todo lists (UUIDs) | No |
| `shell-snapshots/` | Shell state snapshots | No |
| `file-history/` | File edit history (per-project) | No |
| `debug/` | Debug logs | No |
| `statsig/` | Analytics/telemetry | No |

---

## Data Storage Summary

### What Gets Stored Locally

1. **Configuration** - Settings, tools, permissions
2. **Memory** - Instructions and preferences (CLAUDE.md files)
3. **Session Data** - History, todos, snapshots (retained up to 30 days for commercial users)
4. **Credentials** - Authentication tokens

### What Gets Sent to Anthropic

1. **Prompts** - Your messages to Claude
2. **Code Context** - Files and changes Claude analyzes
3. **Execution Results** - Command outputs
4. **Telemetry** - Usage analytics (can be disabled)

---

## Recommended .gitignore

Add to your project's `.gitignore`:

```gitignore
# Claude Code local settings
.claude/settings.local.json

# Claude Code session data (if accidentally created in project)
.claude/session-*
.claude/todos/
.claude/history.jsonl
```

---

## Recommended Dotfiles

Include in your personal dotfiles repo:

```
~/.claude/settings.json    # Global preferences
~/.claude/CLAUDE.md        # Personal memory
```

Exclude (sensitive/session):

```
~/.claude/.credentials.json
~/.claude/history.jsonl
~/.claude/projects/
~/.claude/session-env/
~/.claude/todos/
~/.claude/shell-snapshots/
~/.claude/file-history/
~/.claude/debug/
~/.claude/statsig/
```

---

## Team Collaboration Best Practices

### DO Commit

✅ `.claude/settings.json` - Shared project configuration
✅ `.claude/tools/` - Project tools and scripts
✅ `CLAUDE.md` - Project memory and guidelines

### DON'T Commit

❌ `.claude/settings.local.json` - Personal preferences
❌ `~/.claude/` contents - User-specific data
❌ Credentials or sensitive data

### Migration Checklist

When setting up Claude Code on a new project:

1. Copy `.claude/settings.json` from similar project or create new
2. Add project-specific tools to `.claude/tools/`
3. Create `CLAUDE.md` with project guidelines
4. Add `.claude/settings.local.json` to `.gitignore`
5. Test tools with `--dry-run` before auto-approving

---

## Configuration Hierarchy

Settings are loaded in this order (later overrides earlier):

1. **Enterprise settings** (system-wide, IT-managed)
2. **User settings** (`~/.claude/settings.json`)
3. **Project settings** (`.claude/settings.json`)
4. **Local settings** (`.claude/settings.local.json`)

This allows enterprise policies to be enforced while permitting team and individual customization.

---

## References

- [Official Settings Documentation](https://docs.claude.com/en/docs/claude-code/settings.md)
- [Memory Documentation](https://docs.claude.com/en/docs/claude-code/memory.md)
- [Data Usage Policy](https://docs.claude.com/en/docs/claude-code/data-usage.md)
- [Configuration Files Map](https://docs.claude.com/en/docs/claude-code/claude_code_docs_map.md)
