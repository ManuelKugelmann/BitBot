# DevContainer Mount Structure

**Status:** Implemented
**Last Updated:** 2025-10-28

## Overview

BitBot uses **mount-based architecture** for all infrastructure files. Nothing is copied to user workspaces except user-modifiable configuration.

## Design Principles

1. **Single Source of Truth** - All infrastructure files live in `$BITBOT_HOME`
2. **Readonly Mounts** - Infrastructure mounted readonly, prevents accidental modification
3. **Automatic Updates** - Update BitBot globally, all containers get new files
4. **Minimal Copying** - Only create runtime/config files in workspace
5. **Correct Home Directory** - Mount to `/root/` (container user is `root`)

## Container User

All BitBot containers use **`root`** as the remote user:

```json
{
  "remoteUser": "root"
}
```

**Home directory:** `/root/` (NOT `/home/bitbot/`)

**Rationale:**
- Default for Ubuntu base image
- Simplifies permissions (no UID/GID mapping)
- Standard for devcontainers
- Tools expect configs in `$HOME` (=/root/)

## Mount Categories

### 1. Global Infrastructure (from `$BITBOT_HOME`)

**Readonly mounts shared across all user workspaces:**

| Source (Host) | Target (Container) | Purpose |
|---------------|-------------------|---------|
| `$BITBOT_HOME/container/home/.tmux.conf` | `/root/.tmux.conf` | Tmux configuration |
| `$BITBOT_HOME/.bitbot/wrapper/` | `/opt/bitbot/wrapper/` | Wrapper scripts (IPC, watchdog) |

**Properties:**
- Readonly (`type=bind,readonly`)
- Same for all workspaces
- Updated by updating BitBot

### 2. Workspace Infrastructure

**Readonly mounts from user workspace:**

| Source (Host) | Target (Container) | Purpose |
|---------------|-------------------|---------|
| `${localWorkspaceFolder}/.devcontainer/bitbot/` | `/usr/local/bitbot/` | Container BitBot commands |
| `${localWorkspaceFolder}/.devcontainer/` | `/workspace/.devcontainer/` | DevContainer config (readonly view) |

**Properties:**
- Readonly
- Per-workspace (copied during `bitbot init`)
- Contains container-side BitBot commands

### 3. Workspace Data

**Read-write mounts for workspace files:**

| Source (Host) | Target (Container) | Purpose |
|---------------|-------------------|---------|
| `${localWorkspaceFolder}/` | `/workspace/` | User project files |

**Properties:**
- Read-write (`consistency=cached`)
- User's actual project

### 4. Per-Workspace Home Directories

**Read-write mounts for user dotfiles:**

| Source (Host) | Target (Container) | Purpose |
|---------------|-------------------|---------|
| `${localWorkspaceFolder}/.devcontainer/home/.claude/` | `/root/.claude/` | Claude Code config, sessions, hooks |
| `${localWorkspaceFolder}/.devcontainer/home/.claude-flow/` | `/root/.claude-flow/` | Claude Flow config |
| `${localWorkspaceFolder}/.devcontainer/home/.opencode/` | `/root/.opencode/` | OpenCode config |

**Properties:**
- Read-write (`consistency=cached`)
- Per-workspace (not shared)
- Allows workspace-specific AI tool configs

**Why per-workspace?**
- Different projects may need different Claude hooks
- Session history isolated per project
- MCP servers per project

## Complete Mount Structure

### base.devcontainer.json (All Templates)

```json
{
  "remoteUser": "root",
  "mounts": [
    "source=${localWorkspaceFolder}/.devcontainer/bitbot,target=/usr/local/bitbot,type=bind,readonly",
    "source=${localEnv:BITBOT_HOME}/container/home/.tmux.conf,target=/root/.tmux.conf,type=bind,readonly",
    "source=${localEnv:BITBOT_HOME}/.bitbot/wrapper,target=/opt/bitbot/wrapper,type=bind,readonly"
  ]
}
```

### bitbot-work Template (User Workspaces)

```json
{
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",
    "source=${localWorkspaceFolder}/.devcontainer,target=/workspace/.devcontainer,type=bind,readonly",
    "source=${localWorkspaceFolder}/.devcontainer/home/.claude,target=/root/.claude,type=bind,consistency=cached",
    "source=${localWorkspaceFolder}/.devcontainer/home/.claude-flow,target=/root/.claude-flow,type=bind,consistency=cached",
    "source=${localWorkspaceFolder}/.devcontainer/home/.opencode,target=/root/.opencode,type=bind,consistency=cached"
  ]
}
```

### BitBot Dev Container (Dogfooding)

```json
{
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",
    "source=${localWorkspaceFolder}/.devcontainer,target=/workspace/.devcontainer,type=bind,readonly",
    "source=${localWorkspaceFolder}/.devcontainer/home/.claude,target=/root/.claude,type=bind,consistency=cached",
    "source=${localWorkspaceFolder}/.devcontainer/home/.claude-flow,target=/root/.claude-flow,type=bind,consistency=cached",
    "source=${localWorkspaceFolder}/.devcontainer/home/.opencode,target=/root/.opencode,type=bind,consistency=cached",
    "source=${localWorkspaceFolder}/.bitbot/wrapper,target=/opt/bitbot/wrapper,type=bind,readonly"
  ]
}
```

**Note:** BitBot dev also mounts wrapper for testing (dogfooding).

## Directory Structure

### BitBot Installation ($BITBOT_HOME)

```
BitBot/
├── .bitbot/
│   └── wrapper/              → /opt/bitbot/wrapper/ (ro)
│       ├── claude-wrapper.sh
│       ├── watchdog.sh
│       └── send-wrapper-command.sh
└── container/
    ├── home/                  ← Global dotfiles (mounted)
    │   └── .tmux.conf        → /root/.tmux.conf (ro)
    └── templates/
        └── bitbot-work/      ← User template
```

### User Workspace

```
user-project/
├── .devcontainer/
│   ├── bitbot/               → /usr/local/bitbot/ (ro)
│   │   ├── bitbot            (container-side command)
│   │   └── core/
│   └── home/                 ← Per-workspace dotfiles (mounted)
│       ├── .claude/          → /root/.claude/ (rw)
│       │   ├── hooks/        (workspace-specific hooks)
│       │   └── settings.json
│       ├── .claude-flow/     → /root/.claude-flow/ (rw)
│       └── .opencode/        → /root/.opencode/ (rw)
├── .bitbot/
│   └── wrapper-runtime/      ← Runtime files (NOT mounted)
│       ├── pipes/
│       └── .wrapper-session-*.state
└── (user files)              → /workspace/ (rw)
```

### Container View

```
Container:
├── /root/                    ← Home directory
│   ├── .tmux.conf           (from $BITBOT_HOME/container/home/)
│   ├── .claude/             (from workspace/.devcontainer/home/)
│   ├── .claude-flow/        (from workspace/.devcontainer/home/)
│   └── .opencode/           (from workspace/.devcontainer/home/)
├── /workspace/              (from workspace root)
│   ├── .bitbot/
│   │   └── wrapper-runtime/ (local, not mounted)
│   └── .devcontainer/       (mounted readonly)
├── /usr/local/bitbot/       (from workspace/.devcontainer/bitbot/)
└── /opt/bitbot/
    └── wrapper/             (from $BITBOT_HOME/.bitbot/wrapper/)
```

## Benefits

✅ **No File Copying** - Infrastructure scripts never copied
✅ **Single Source** - Update BitBot once, all containers updated
✅ **Readonly Safety** - Users can't accidentally modify infrastructure
✅ **Clear Separation** - Global (readonly) vs workspace (read-write)
✅ **Correct Paths** - Files mounted where tools expect them (`/root/`)
✅ **Workspace Isolation** - Each project has own Claude config/sessions

## Migration Notes

### Changed in 2025-10-28

**Before (WRONG):**
- Mounted to `/home/bitbot/` (wrong home directory)
- Wrapper scripts copied to workspace
- `global/` directory at root (unclear grouping)

**After (CORRECT):**
- Mount to `/root/` (correct home for root user)
- Wrapper scripts mounted readonly from `$BITBOT_HOME`
- `container/home/` directory (clear grouping with container files)

### Affected Files

- `container/templates/shared/base.devcontainer.json`
- `container/templates/bitbot-work/devcontainer.json`
- `container/templates/bitbot-work/details.devcontainer.json`
- `.devcontainer/devcontainer.json` (BitBot dev)

## Testing

**Verify mounts work:**
```bash
# In container
ls -la /root/.tmux.conf          # Should exist (from $BITBOT_HOME)
ls -la /root/.claude/            # Should exist (from workspace)
ls -la /opt/bitbot/wrapper/      # Should exist (from $BITBOT_HOME)
which claude                     # Should work (in PATH)
```

**Verify readonly enforcement:**
```bash
# Should fail (readonly mount)
echo "test" >> /root/.tmux.conf
echo "test" >> /opt/bitbot/wrapper/claude-wrapper.sh

# Should succeed (read-write mount)
echo "test" >> /root/.claude/settings.local.json
```

## Related Documentation

- `sparc/0-research/WRAPPER_WATCHDOG.md` - Wrapper architecture
- `container/templates/shared/base.devcontainer.json` - Base mounts
- `CLAUDE.md` - Developer section (mount summary)

---

**Last Updated:** 2025-10-28
