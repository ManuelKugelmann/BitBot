# BitBot Directory Structure

**Status:** Single Source of Truth
**Last Updated:** 2025-10-28

---

## Overview

Complete directory structure for BitBot workspaces, including mount points and permissions across different container modes.

---

## Host-Side Structure (Workspace)

```
user-workspace/
├── .bitbot/
│   ├── internal/                    ← Infrastructure files
│   │   ├── container/               ← Container infrastructure (committed)
│   │   │   ├── home/                (global dotfiles)
│   │   │   │   └── .tmux.conf
│   │   │   └── bitbot/              (container-side BitBot scripts)
│   │   │       └── core/
│   │   │           ├── commands/
│   │   │           └── util/
│   │   ├── global/                  ← Reserved (gitignored)
│   │   └── .version                 ← Infrastructure version
│   └── runtime/                     ← Runtime files (gitignored)
│       ├── pipes/                   (wrapper IPC named pipes)
│       └── sessions/                (session state files)
├── .devcontainer/
│   ├── bitbot/                      ← Container BitBot commands (copied during init)
│   │   ├── bitbot                   (main command)
│   │   └── core/
│   │       ├── commands/
│   │       └── util/
│   ├── home/                        ← Per-workspace AI configs
│   │   ├── .claude/
│   │   │   ├── hooks/
│   │   │   ├── settings.json
│   │   │   └── sessions/
│   │   ├── .claude-flow/
│   │   └── .opencode/
│   ├── devcontainer.json            ← Generated (base + details)
│   ├── details.devcontainer.json   ← Template-specific config
│   ├── Dockerfile
│   └── README.md
└── (project files)
```

### Key Directories

| Path | Purpose | Committed | Mount Access |
|------|---------|-----------|--------------|
| `.bitbot/internal/container/` | Infrastructure files | ✅ Yes | Container: RO |
| `.bitbot/internal/.version` | Version tracking | ✅ Yes | Container: RO |
| `.bitbot/internal/global/` | Reserved for future | ❌ No (gitignored) | - |
| `.bitbot/runtime/` | Runtime files (pipes, state) | ❌ No (gitignored) | Container: RW |
| `.devcontainer/bitbot/` | Container BitBot | ✅ Yes | Container: RO |
| `.devcontainer/home/` | AI tool configs | ✅ Yes | Container: RW |

---

## Container-Side Structure

### Base Structure (All Modes)

```
/
├── workspace/                       ← Workspace root
│   ├── .bitbot/
│   │   ├── internal/                ← Infrastructure (RO overlay)
│   │   │   └── container/
│   │   │       ├── home/
│   │   │       └── bitbot/
│   │   └── runtime/                 ← Runtime files (RW via workspace)
│   │       ├── pipes/
│   │       └── sessions/
│   ├── .devcontainer/               ← DevContainer config (RO overlay)
│   │   ├── home/                    ← AI configs (RW via workspace)
│   │   └── bitbot/                  ← Container BitBot (RO overlay)
│   └── (project files)              ← User files (RW)
├── root/                            ← Container home directory
│   ├── .tmux.conf                   ← From .bitbot/internal/container/home/
│   ├── .claude/                     ← From .devcontainer/home/.claude/
│   ├── .claude-flow/                ← From .devcontainer/home/.claude-flow/
│   └── .opencode/                   ← From .devcontainer/home/.opencode/
└── usr/local/bitbot/                ← Container BitBot commands
    ├── bitbot
    └── core/
```

---

## Mount Configuration by Mode

### Work Mode (bitbot-work)

**Purpose:** Production development, immutable infrastructure

**Mounts:**

| Source (Host) | Target (Container) | Type | Permission | Purpose |
|---------------|-------------------|------|------------|---------|
| `${localWorkspaceFolder}` | `/workspace` | bind | **RW** | User project files |
| `${localWorkspaceFolder}/.devcontainer` | `/workspace/.devcontainer` | bind | **RO** | DevContainer config overlay |
| `${localWorkspaceFolder}/.devcontainer/bitbot` | `/usr/local/bitbot` | bind | **RO** | Container BitBot commands |
| `${localWorkspaceFolder}/.bitbot/internal` | `/workspace/.bitbot/internal` | bind | **RO** | Infrastructure overlay |
| `${localWorkspaceFolder}/.bitbot/internal/container/home/.tmux.conf` | `/root/.tmux.conf` | bind | **RO** | Global tmux config |
| `${localWorkspaceFolder}/.devcontainer/home/.claude` | `/root/.claude` | bind | **RW** | Claude config |
| `${localWorkspaceFolder}/.devcontainer/home/.claude-flow` | `/root/.claude-flow` | bind | **RW** | Claude Flow config |
| `${localWorkspaceFolder}/.devcontainer/home/.opencode` | `/root/.opencode` | bind | **RW** | OpenCode config |

**Effective Permissions:**

```
/workspace/                          RW   (user files)
/workspace/.bitbot/internal/         RO   (infrastructure overlay - hidden)
/workspace/.bitbot/runtime/          RW   (via workspace mount)
/workspace/.devcontainer/            RO   (config overlay - hidden)
/workspace/.devcontainer/home/       RW   (via workspace mount - AI configs)
/usr/local/bitbot/                   RO   (container BitBot)
/root/.tmux.conf                     RO   (global config)
/root/.claude/                       RW   (AI config)
```

**Key Points:**
- Infrastructure files **readonly** - prevents accidental modification
- Runtime files **read-write** - wrapper can create pipes/state
- AI configs **read-write** - per-workspace settings
- User files **read-write** - normal development

---

### Config Mode (bitbot-config)

**Purpose:** DevContainer customization, infrastructure review

**Mounts:** Same as Work Mode **PLUS:**

| Source (Host) | Target (Container) | Type | Permission | Purpose |
|---------------|-------------------|------|------------|---------|
| `/var/run/docker.sock` | `/var/run/docker.sock` | bind | **RW** | Docker access for rebuilds |

**Effective Permissions:**

```
/workspace/                          RW   (user files)
/workspace/.bitbot/internal/         RO   (infrastructure overlay - hidden)
/workspace/.bitbot/runtime/          RW   (via workspace mount)
/workspace/.devcontainer/            RO   (config overlay - hidden)
/workspace/.devcontainer/home/       RW   (via workspace mount - AI configs)
/usr/local/bitbot/                   RO   (container BitBot)
/root/.tmux.conf                     RO   (global config)
/root/.claude/                       RW   (AI config)
/var/run/docker.sock                 RW   (Docker socket)
```

**Additional Capabilities:**
- Docker socket access for `docker` commands
- Can rebuild devcontainer from inside
- Same infrastructure restrictions as work mode
- User can edit `.devcontainer/` files via workspace mount (under RO overlay)

**Important:** Infrastructure files in `.bitbot/internal/` are still **readonly**. To modify:
1. Edit on host (outside container)
2. Or: Understand RO overlay hides host changes until container restart

---

### Dev Mode (bitbot-dev - BitBot Development)

**Purpose:** Developing BitBot itself (dogfooding)

**Mounts:** Same as Work Mode **PLUS:**

| Source (Host) | Target (Container) | Type | Permission | Purpose |
|---------------|-------------------|------|------------|---------|
| `${localWorkspaceFolder}/.bitbot/wrapper` | `/opt/bitbot/wrapper` | bind | **RO** | Test wrapper scripts |

**Effective Permissions:**

```
/workspace/                          RW   (BitBot source code)
/workspace/.bitbot/internal/         RO   (infrastructure overlay - hidden)
/workspace/.bitbot/runtime/          RW   (via workspace mount)
/workspace/.bitbot/wrapper/          RO   (wrapper testing - overlay)
/workspace/.devcontainer/            RO   (config overlay - hidden)
/workspace/.devcontainer/home/       RW   (via workspace mount - AI configs)
/usr/local/bitbot/                   RO   (container BitBot)
/root/.tmux.conf                     RO   (global config)
/root/.claude/                       RW   (AI config)
/opt/bitbot/wrapper/                 RO   (wrapper scripts for testing)
```

**Special Case:** BitBot Development

When developing BitBot itself, all files are **available read-write via the workspace mount**, but some are **hidden by readonly overlays**:

- `.bitbot/internal/` - RO overlay (edit on host, see changes after rebuild)
- `.devcontainer/` - RO overlay (edit on host, see changes after rebuild)
- `.bitbot/wrapper/` - RO overlay (edit on host, see changes after rebuild)

**To see changes in overlaid directories:**
1. Edit files via workspace path: `/workspace/.bitbot/internal/...`
2. Rebuild container to pick up changes
3. Or: Edit outside container, restart container

**Why overlays in dev mode?**
- Tests realistic behavior (infrastructure is RO in production)
- Prevents accidental modification during testing
- Forces intentional workflow for infrastructure changes

---

## Mount Strategy Comparison

### Summary Table

| Directory | Work Mode | Config Mode | Dev Mode | Via |
|-----------|-----------|-------------|----------|-----|
| `/workspace/` | **RW** | **RW** | **RW** | Workspace mount |
| `/workspace/.bitbot/internal/` | **RO** | **RO** | **RO** | Overlay mount |
| `/workspace/.bitbot/runtime/` | **RW** | **RW** | **RW** | Workspace mount |
| `/workspace/.devcontainer/` | **RO** | **RO** | **RO** | Overlay mount |
| `/workspace/.devcontainer/home/` | **RW** | **RW** | **RW** | Workspace mount |
| `/usr/local/bitbot/` | **RO** | **RO** | **RO** | Direct mount |
| `/root/.tmux.conf` | **RO** | **RO** | **RO** | Direct mount |
| `/root/.claude/` | **RW** | **RW** | **RW** | Direct mount |
| `/var/run/docker.sock` | ❌ | **RW** | ❌ | Direct mount |
| `/opt/bitbot/wrapper/` | ❌ | ❌ | **RO** | Direct mount |

**Legend:**
- **RW** - Read-Write
- **RO** - Readonly
- ❌ - Not mounted

---

## Understanding Overlays

### What is an Overlay Mount?

An overlay mount places a **readonly** layer on top of an existing **read-write** mount.

**Example:**
```json
{
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",  // RW
    "source=${localWorkspaceFolder}/.bitbot/internal,target=/workspace/.bitbot/internal,type=bind,readonly"  // RO overlay
  ]
}
```

**Result:**
- `/workspace/` is read-write (user can edit files)
- `/workspace/.bitbot/internal/` is readonly (overlay hides the RW path)

### Why Use Overlays?

**Benefits:**
1. **Selective Protection** - Protect specific subdirectories without affecting workspace
2. **Same Pattern as `.devcontainer/`** - Consistent with VS Code patterns
3. **Prevents Accidents** - Users can't accidentally modify infrastructure inside container

**Trade-off:**
- Files under overlay path can't be modified from inside container
- Must edit on host or outside container to see changes

---

## Git Configuration

### Workspace .gitignore

```gitignore
# BitBot runtime files (never commit)
/.bitbot/runtime/

# BitBot reserved (never commit)
/.bitbot/internal/global/
```

### Workspace .gitattributes

```gitattributes
# Line endings for infrastructure scripts
.bitbot/internal/**/*.sh text eol=lf
.devcontainer/**/*.sh text eol=lf
```

### What Gets Committed

| Path | Committed | Reason |
|------|-----------|--------|
| `.bitbot/internal/container/` | ✅ Yes | Infrastructure for Codespaces |
| `.bitbot/internal/.version` | ✅ Yes | Version tracking |
| `.bitbot/runtime/` | ❌ No | Temporary runtime files |
| `.bitbot/internal/global/` | ❌ No | Reserved for future |
| `.devcontainer/` | ✅ Yes | DevContainer config |
| `.devcontainer/home/` | ✅ Yes | AI tool configs (per-workspace) |

---

## Access Patterns

### From Inside Container (Work Mode)

**Read Infrastructure:**
```bash
# ✅ Works - infrastructure is readable
cat /workspace/.bitbot/internal/container/home/.tmux.conf
cat /usr/local/bitbot/core/commands/help.sh
```

**Modify Infrastructure:**
```bash
# ❌ Fails - readonly overlay
echo "test" >> /workspace/.bitbot/internal/container/home/.tmux.conf
# Error: Read-only file system

# ✅ Workaround - exit container, edit on host
exit
# On host:
vim .bitbot/internal/container/home/.tmux.conf
# Re-enter container to see changes
```

**Runtime Files:**
```bash
# ✅ Works - read-write via workspace mount
echo "test" > /workspace/.bitbot/runtime/test.txt
mkdir -p /workspace/.bitbot/runtime/pipes
mkfifo /workspace/.bitbot/runtime/pipes/test.pipe
```

### From Host (Always)

```bash
# ✅ All files are read-write on host (before entering container)
vim .bitbot/internal/container/home/.tmux.conf
vim .devcontainer/devcontainer.json
vim .devcontainer/home/.claude/settings.json

# Host bitbot commands sync infrastructure before starting container
bitbot work     # Syncs .bitbot/internal/container/ from $BITBOT_HOME
bitbot config   # Syncs .bitbot/internal/container/ from $BITBOT_HOME
```

---

## Update Workflows

### Local Environment

**Automatic Sync:**
```bash
# User runs bitbot command
bitbot work

# Command flow:
# 1. Sync infrastructure
rsync -a --delete "$BITBOT_HOME/container/" ".bitbot/internal/container/"

# 2. Start container
devcontainer up

# Container starts with latest infrastructure (readonly)
```

**Manual Update:**
```bash
# Re-run init to force sync
bitbot init
# 🔄 Workspace already initialized
# 📦 Updating infrastructure from BitBot v0.2.0...
# ✅ Infrastructure synced
```

### Codespaces

**No Host Commands:**
- User opens workspace in Codespaces
- No `bitbot` command runs
- Uses committed `.bitbot/internal/container/` files
- Everything works (self-contained)

**Manual Update (Future):**
```bash
# Download latest infrastructure from release
bitbot update-workspace
# Or: Commit updated files from local environment
```

---

## Template Differences

### bitbot-work (User Workspaces)

**Features:**
- Claude Code, AI tools
- Shared home folders (`.claude/`, `.opencode/`)
- Infrastructure readonly
- No Docker socket

**Use Case:** Production AI-assisted development

### bitbot-config (Configuration)

**Features:**
- Same as work mode
- PLUS: Docker socket access
- Config tools (YAML, JSON editors)
- Can rebuild devcontainer

**Use Case:** DevContainer customization, package installation

### bitbot-dev (BitBot Development)

**Features:**
- Same as work mode
- PLUS: Wrapper scripts mounted for testing
- MinGW, build tools
- Infrastructure overlays (testing production behavior)

**Use Case:** Developing BitBot itself (dogfooding)

### bitbot-base (Minimal)

**Features:**
- Core only
- No AI tools
- Infrastructure readonly
- Minimal footprint

**Use Case:** Lightweight containers, custom builds

---

## Path Resolution

### Container Paths

| Container Path | Resolves To | Permission |
|----------------|-------------|------------|
| `/workspace/` | Host: `./` | RW |
| `/workspace/.bitbot/internal/` | Overlay: `.bitbot/internal/` | RO |
| `/workspace/.bitbot/runtime/` | Host: `.bitbot/runtime/` | RW |
| `/workspace/.devcontainer/` | Overlay: `.devcontainer/` | RO |
| `/usr/local/bitbot/` | Host: `.devcontainer/bitbot/` | RO |
| `/root/.tmux.conf` | Host: `.bitbot/internal/container/home/.tmux.conf` | RO |
| `/root/.claude/` | Host: `.devcontainer/home/.claude/` | RW |

### Symbolic Links

No symbolic links are used in the mount strategy. All paths are direct bind mounts.

---

## Troubleshooting

### "Read-only file system" Error

**Problem:** Trying to modify infrastructure inside container

```bash
vim /workspace/.bitbot/internal/container/home/.tmux.conf
# Error: Read-only file system
```

**Solution:** Edit on host or exit container

```bash
# Option 1: Exit container, edit on host
exit
vim .bitbot/internal/container/home/.tmux.conf

# Option 2: Edit in another terminal (outside container)
# On host in another terminal:
vim .bitbot/internal/container/home/.tmux.conf

# Restart container to see changes
```

### Changes Not Visible After Edit

**Problem:** Edited file on host, but container shows old content

**Cause:** Readonly overlay was mounted before edit

**Solution:** Restart container

```bash
# Exit and re-enter container
exit
bitbot work
```

### Docker Socket Permission Denied

**Problem:** `docker` commands fail in work mode

```bash
docker ps
# Cannot connect to the Docker daemon
```

**Cause:** Docker socket not mounted in work mode

**Solution:** Enter config mode

```bash
exit
bitbot config
# Now docker commands work
```

---

## Related Documentation

- `sparc/1-specification/12_MOUNT_STRUCTURE.md` - Original mount design
- `sparc/1-specification/13_CODESPACES_INFRASTRUCTURE.md` - Codespaces strategy
- `CLAUDE.md` - Project instructions (references this file)
- Template README files - Template-specific documentation

---

**Last Updated:** 2025-10-28
**Status:** Single Source of Truth for directory structure
