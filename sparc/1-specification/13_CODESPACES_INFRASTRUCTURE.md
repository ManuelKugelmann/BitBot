# Codespaces Infrastructure Strategy

**Status:** Planning
**Date:** 2025-10-28
**Related:** Mount Structure (12), Workspace Management (08)

---

## Problem Statement

BitBot currently mounts global infrastructure from `$BITBOT_HOME`:

```json
"source=${localEnv:BITBOT_HOME}/container/home/.tmux.conf,target=/root/.tmux.conf,type=bind,readonly"
```

**Issue:** In GitHub Codespaces, `$BITBOT_HOME` doesn't exist, causing:
- Missing global files (`.tmux.conf`, wrapper scripts)
- Container still works, but features are degraded
- No automatic updates from BitBot installation

**Goal:** Make BitBot workspaces fully functional in Codespaces while maintaining auto-update capability locally.

---

## Requirements

### Functional Requirements

1. **Codespaces Compatibility**
   - Workspace must be self-contained
   - No dependency on `$BITBOT_HOME` environment variable
   - Global infrastructure files available in container

2. **Local Auto-Update**
   - When BitBot is updated locally, workspaces should use latest infrastructure
   - No manual sync required for local development

3. **Unified Configuration**
   - Same `devcontainer.json` works in both environments
   - No environment-specific configuration files

4. **Version Tracking**
   - Detect infrastructure version mismatches
   - Inform user when update available

### Non-Functional Requirements

1. **Performance** - No significant overhead for sync operations
2. **Storage** - Minimal duplication (symlinks locally, copies in Codespaces)
3. **Simplicity** - Clear directory structure, easy to understand

---

## Proposed Solution: `.bitbot/internal/` Directory

### Key Insight

**The Strategy:** Update on host, mount readonly in container (same pattern as `.devcontainer/`):

1. **On `bitbot init`:** Copy `$BITBOT_HOME/container` → `.bitbot/internal/container/` (committed to git)
2. **Before container starts:** `initializeCommand` syncs updates from `$BITBOT_HOME/container` (host-side)
   - Local: Syncs if `$BITBOT_HOME` exists
   - Codespaces: Skips (no `$BITBOT_HOME`), uses committed copies
3. **Container mounts:** `.bitbot/internal/` as readonly overlay (just like `.devcontainer/`)
4. **Container uses:** Files from `/workspace/.bitbot/internal/container/` (guaranteed to exist)

**Result:** Same devcontainer.json works everywhere, auto-updates locally, self-contained in Codespaces!

**Mount Permissions:**
- All mounts are **readonly** - infrastructure is immutable inside container
- Updates happen on **host side** via `initializeCommand`
- Same pattern as `.devcontainer/` directory

### Directory Structure

**Host (Workspace):**
```
user-workspace/
├── .bitbot/
│   ├── internal/
│   │   └── container/               ← Working copies (committed to git)
│   │       ├── home/
│   │       │   └── .tmux.conf
│   │       └── bitbot/
│   │           └── core/
│   └── wrapper-runtime/             ← Session files (not mounted)
├── .devcontainer/
│   ├── bitbot/                      ← Container BitBot commands
│   └── home/                        ← Per-workspace AI configs
└── (project files)
```

**Container:**
```
/
├── workspace/
│   ├── .bitbot/
│   │   └── internal/                ← Mounted readonly (overlay on workspace)
│   │       └── container/
│   │           ├── home/
│   │           └── bitbot/
│   └── (project files)
├── root/
│   └── .tmux.conf                   ← Mounted from workspace/.bitbot/internal/container/home/.tmux.conf
└── usr/local/bitbot/                ← Container BitBot commands
```

**Key Points:**
- `/workspace/.bitbot/internal/` - Readonly mount (same pattern as `.devcontainer/`)
- All infrastructure files readonly inside container
- Updates happen on host side via `initializeCommand`

### Mount Configuration: Dual-Mode Strategy

BitBot uses **different mount strategies** for work vs config modes:

#### Work Mode (bitbot-work) - Readonly Infrastructure

**Purpose:** Production use, immutable infrastructure

**Mounts:**
```json
{
  "initializeCommand": "bash -c 'if [ -n \"$BITBOT_HOME\" ] && [ -d \"$BITBOT_HOME/container\" ]; then rsync -a --delete \"$BITBOT_HOME/container/\" \"${localWorkspaceFolder}/.bitbot/internal/container/\"; fi'",

  "mounts": [
    "source=${localWorkspaceFolder}/.bitbot/internal,target=/workspace/.bitbot/internal,type=bind,readonly",
    "source=${localWorkspaceFolder}/.bitbot/internal/container/home/.tmux.conf,target=/root/.tmux.conf,type=bind,readonly"
  ],

  "postAttachCommand": "/usr/local/bitbot/core/util/check-updates.sh"
}
```

**Behavior:**
- ✅ `.bitbot/internal/` **readonly** - can't accidentally modify infrastructure
- ✅ `initializeCommand` syncs updates from `$BITBOT_HOME` (host-side, before container starts)
- ✅ `postAttachCommand` checks for pending updates, informs user
- ⚠️ Changes require entering config mode: `bitbot config`

#### Config Mode (bitbot-config) - Read-Write Infrastructure

**Purpose:** DevContainer customization, infrastructure updates

**Mounts:**
```json
{
  "initializeCommand": "bash -c 'if [ -n \"$BITBOT_HOME\" ] && [ -d \"$BITBOT_HOME/container\" ]; then rsync -a --delete \"$BITBOT_HOME/container/\" \"${localWorkspaceFolder}/.bitbot/internal/container/\"; fi'",

  "mounts": [
    "source=${localWorkspaceFolder}/.bitbot/internal/container,target=/workspace/.bitbot/internal/container,type=bind,consistency=cached",
    "source=${localWorkspaceFolder}/.bitbot/internal/container/home/.tmux.conf,target=/root/.tmux.conf,type=bind,readonly",
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
  ],

  "postAttachCommand": "/usr/local/bitbot/core/util/sync-and-notify.sh"
}
```

**Behavior:**
- ✅ `.bitbot/internal/container/` **read-write** - can customize infrastructure
- ✅ `initializeCommand` syncs updates from `$BITBOT_HOME` (same as work mode)
- ✅ `postAttachCommand` informs user about applied updates
- ✅ Docker socket available for rebuilding devcontainer
- ✅ User can edit Dockerfiles, add packages, customize

**Key Differences:**

| Aspect | Work Mode | Config Mode |
|--------|-----------|-------------|
| `.bitbot/internal/` mount | **Readonly** | **Read-write** (only `container/` subdirectory) |
| Purpose | Production development | Infrastructure customization |
| Infrastructure updates | Host-side only (initializeCommand) | Host-side + user edits |
| User notification | "Updates available, enter config mode" | "Updates applied" |
| Docker socket | ❌ Not mounted | ✅ Mounted (for rebuilds) |

**Result:**
- ✅ Work mode: Safe, immutable infrastructure
- ✅ Config mode: Flexible, customizable infrastructure
- ✅ Both modes: Auto-sync from `$BITBOT_HOME` on startup
- ✅ Codespaces: Works in both modes (uses committed copies)

---

## Implementation Details

### 1. `bitbot init` - Setup Infrastructure

**File:** `core/workspace/bitbot-init.sh`

```bash
#!/bin/bash
# Setup .bitbot/internal/ during workspace initialization

setup_internal_infrastructure() {
    local workspace="$1"

    echo "📦 Setting up workspace infrastructure..."

    # Create directory structure
    mkdir -p "$workspace/.bitbot/internal"/{global,container,wrapper}

    # Detect environment
    if [ -n "$BITBOT_HOME" ] && [ -d "$BITBOT_HOME" ]; then
        echo "🔗 Local environment detected - creating update link"
        setup_local_infrastructure "$workspace"
    else
        echo "☁️  Standalone/Codespaces mode - copying files"
        setup_standalone_infrastructure "$workspace"
    fi

    # Copy version file
    echo "$(bitbot --version)" > "$workspace/.bitbot/internal/.version"
}

setup_local_infrastructure() {
    local workspace="$1"

    # Initial copy of infrastructure
    # Updates will be synced automatically by initializeCommand
    cp -r "$BITBOT_HOME/container/home" "$workspace/.bitbot/internal/container/"
    cp -r "$BITBOT_HOME/container/bitbot" "$workspace/.bitbot/internal/container/"

    echo "✅ Infrastructure copied (will auto-update via initializeCommand)"
}

setup_standalone_infrastructure() {
    local workspace="$1"

    # Copy infrastructure (initializeCommand will skip updates)
    cp -r "$BITBOT_HOME/container/home" "$workspace/.bitbot/internal/container/"
    cp -r "$BITBOT_HOME/container/bitbot" "$workspace/.bitbot/internal/container/"

    echo "✅ Infrastructure copied (standalone mode - manual updates)"
}
```

### 2. Git Configuration

**File:** `.gitignore` (workspace root)

```gitignore
# BitBot infrastructure
/.bitbot/wrapper-runtime/        # Session files (never commit)
```

**File:** `.gitattributes` (workspace root)

```gitattributes
# Ensure line endings for infrastructure scripts
.bitbot/internal/**/*.sh text eol=lf
```

**What Gets Committed:**
- ✅ `.bitbot/internal/container/` - Infrastructure copies (for Codespaces)
- ✅ `.bitbot/internal/.version` - Version tracking
- ❌ `.bitbot/wrapper-runtime/` - Session state (temporary)

---

## Behavior Matrix

| Environment | `$BITBOT_HOME` | `initializeCommand` | `.bitbot/internal/` |
|-------------|----------------|---------------------|---------------------|
| **Local WSL/Linux** | ✅ Exists | Syncs updates to workspace | Mounted readonly |
| **GitHub Codespaces** | ❌ Missing | Skips (no-op) | Uses committed copies, mounted readonly |
| **Cloned repo (no BitBot)** | ❌ Missing | Skips (no-op) | Uses committed copies, mounted readonly |

---

## Update Workflows

### Scenario 1: Local User Updates BitBot

```bash
# User updates BitBot
cd $BITBOT_HOME
git pull
./install.sh

# Next time they open workspace:
code .  # VS Code opens devcontainer

# Before container starts (initializeCommand):
# Syncs $BITBOT_HOME/container → workspace/.bitbot/internal/container/
# (Happens silently on host, no output in terminal)

# Container starts with latest infrastructure
```

### Scenario 2: User Opens Workspace in Codespaces

```bash
# User clicks "Open in Codespaces"
# Codespaces builds container

# initializeCommand runs but skips (no $BITBOT_HOME)
# Container uses committed .bitbot/internal/container/ files
# Everything works - infrastructure was committed to repo
```

### Scenario 3: Manual Infrastructure Update (Host-side)

```bash
# User wants to manually update infrastructure in existing workspace

# Option 1: Re-run bitbot init (safe, non-destructive)
bitbot init
# 🔄 Workspace already initialized
# 📦 Updating infrastructure from BitBot v0.2.0...
# ✅ Infrastructure updated
# ℹ️  Restart containers to apply: bitbot work

# Option 2: Direct sync (advanced)
rsync -a --delete "$BITBOT_HOME/container/" ".bitbot/internal/container/"
```

### Scenario 4: Config Mode Update Workflow

```bash
# User enters config mode to apply infrastructure updates
bitbot config

# In config container:
# postAttachCommand runs:
# ℹ️  Infrastructure updates applied from BitBot v0.2.0
# ℹ️  Changes in .bitbot/internal/container/:
#     - home/.tmux.conf (updated)
#     - bitbot/core/util/sync-and-notify.sh (new file)
#
# ⚠️  Review changes before committing:
#     git diff .bitbot/internal/

# User reviews and commits
git add .bitbot/internal/
git commit -m "Update BitBot infrastructure to v0.2.0"

# Exit config mode
exit  # or Ctrl+D

# Re-enter work mode with updates
bitbot work
```

---

## Migration Path

### Phase 1: Add `.bitbot/internal/` Support (v0.1.0)

1. Update `base.devcontainer.json` mounts to use `.bitbot/internal/`
2. Add `setup_internal_infrastructure()` to `bitbot init`
3. Add `sync-infrastructure.sh` to container scripts
4. Update documentation

**Impact:**
- New workspaces: Works in Codespaces immediately
- Existing workspaces: Continue using old mounts (still work locally)

### Phase 2: Migrate Existing Workspaces (v0.2.0)

Add `bitbot migrate-infrastructure` command:

```bash
bitbot migrate-infrastructure
# 🔄 Migrating workspace to .bitbot/internal/ structure...
# ✅ Migration complete
# ℹ️  Workspace now compatible with GitHub Codespaces
```

### Phase 3: Remove Legacy Mounts (v0.3.0)

Remove `${localEnv:BITBOT_HOME}` mounts entirely.

---

## Testing Strategy

### Test Cases

#### TC1: Fresh Init (Local)
```bash
cd /tmp/test-workspace
bitbot init
# Verify: .bitbot/internal/global/ is symlink
# Verify: .bitbot/internal/container/ has files
ls -la .bitbot/internal/global/container  # Should show symlink
ls -la .bitbot/internal/container/home/.tmux.conf  # Should exist
```

#### TC2: Fresh Init (Codespaces Simulation)
```bash
cd /tmp/test-codespaces
unset BITBOT_HOME
bitbot init
# Verify: .bitbot/internal/global/ doesn't exist
# Verify: .bitbot/internal/container/ has files
ls -la .bitbot/internal/global/  # Should not exist
ls -la .bitbot/internal/container/home/.tmux.conf  # Should exist
```

#### TC3: Container Startup Sync (Local)
```bash
# Start container
devcontainer.cmd build --workspace-folder .
devcontainer.cmd exec --workspace-folder . bash

# Inside container:
ls -la /root/.tmux.conf  # Should exist (mounted)
cat /workspace/.bitbot/internal/.version  # Should show current version
```

#### TC4: Version Update Detection
```bash
# Update BitBot
cd $BITBOT_HOME
echo "0.2.0" > .version

# Restart container
# Should see: "Infrastructure update available: 0.1.0 → 0.2.0"
```

#### TC5: GitHub Codespaces
```bash
# Open in Codespaces (manual test)
# Verify: Container starts successfully
# Verify: /root/.tmux.conf exists
# Verify: /opt/bitbot/wrapper/ exists
# Verify: No error messages about missing mounts
```

---

## Alternatives Considered

### Alternative 1: Environment-Specific Config Files

Create separate `devcontainer.json` files:
- `devcontainer.json` - Local (uses `$BITBOT_HOME`)
- `devcontainer.codespaces.json` - Codespaces (uses copies)

**Rejected:** Requires maintenance of two configs, error-prone.

### Alternative 2: initializeCommand Workaround

Use `initializeCommand` to create missing directories:

```json
{
  "initializeCommand": "mkdir -p ${localWorkspaceFolder}/.bitbot/internal/container/home"
}
```

**Rejected:** Doesn't solve the fundamental problem of missing files.

### Alternative 3: Copy Everything, No Symlinks

Always copy, never symlink. Check for updates manually.

**Rejected:** Loses auto-update capability, worse user experience.

### Alternative 4: Container-Side Download

Download infrastructure from GitHub releases on startup.

**Rejected:**
- Requires internet connection
- Slower startup
- Version pinning complexity

---

## Open Questions

### Q1: Should `.bitbot/internal/container/` be committed?

**Answer:** Yes.
- **Pro:** Codespaces works out-of-box, no setup required
- **Con:** Larger repo size (~100KB), infrastructure changes in git history

**Decision:** Commit it. Self-contained workspaces are worth the trade-off.

### Q2: How to handle infrastructure version mismatches?

**Current:** Log warning, continue with existing files.

**Future:** Could add `bitbot check-workspace` command to report issues.

### Q3: What about custom modifications to infrastructure?

**Scenario:** User modifies `.bitbot/internal/container/home/.tmux.conf`

**Answer:** Depends on the mode.

**Work Mode (readonly):**
- Can't modify infrastructure files
- Forces intentional workflow: enter config mode to make changes

**Config Mode (read-write):**
- User can modify `.bitbot/internal/container/` files
- Next `initializeCommand` sync may overwrite changes
- User should commit customizations before BitBot update
- Or: Use `.devcontainer/home/` for per-workspace configs (recommended)

**Recommendation:**
- Global settings → `.bitbot/internal/container/` (affects all workspaces, requires config mode)
- Per-workspace settings → `.devcontainer/home/` (workspace-specific, always editable)

### Q4: What about wrapper scripts location?

**Answer:** Wrapper scripts stay in `$BITBOT_HOME/.bitbot/wrapper/` (not in `container/`).

**Rationale:**
- Wrapper is BitBot host infrastructure, not container infrastructure
- Doesn't need to be in workspace
- Managed separately from container files

**Mount:** Not needed - wrapper runs on host, not in container.

---

## Documentation Updates

### User Documentation

**File:** `README.md`

Add section:

```markdown
### GitHub Codespaces Support

BitBot workspaces work seamlessly in GitHub Codespaces:

1. Initialize workspace: `bitbot init`
2. Commit `.bitbot/internal/` directory
3. Push to GitHub
4. Open in Codespaces

Your workspace includes all necessary infrastructure files.
```

**File:** `docs/CODESPACES.md` (new)

Detailed Codespaces guide:
- How to open workspace in Codespaces
- Differences from local development
- Limitations (no Docker-in-Docker)
- How to update infrastructure

### Developer Documentation

**File:** `CLAUDE.md`

Update mount structure documentation with new paths.

**File:** `sparc/1-specification/12_MOUNT_STRUCTURE.md`

Add Codespaces section documenting `.bitbot/internal/` structure.

---

## Success Criteria

### v0.1.0 (Alpha)

- [x] `.bitbot/internal/` structure defined ✅
- [x] Dual-mode mount strategy (work ro, config rw) ✅
- [ ] `bitbot init` creates `.bitbot/internal/container/` directory
- [ ] `bitbot init` supports re-init for updates
- [ ] Work mode: `.bitbot/internal/` mounted readonly
- [ ] Config mode: `.bitbot/internal/container/` mounted read-write
- [ ] `initializeCommand` syncs from `$BITBOT_HOME/container`
- [ ] `postAttachCommand` for work mode: check-updates.sh
- [ ] `postAttachCommand` for config mode: sync-and-notify.sh
- [ ] Update base.devcontainer.json with initializeCommand
- [ ] Update bitbot-work template with readonly mount
- [ ] Update bitbot-config template with read-write mount
- [ ] Test in local environment (auto-update workflow)
- [ ] Test in Codespaces (fallback to committed copies)
- [ ] Test dual-mode switching (work ↔ config)
- [ ] Documentation updated
- [ ] Test suite passes (5 test cases)

### v0.2.0 (Beta)

- [ ] Migration command for existing workspaces
- [ ] `bitbot update-workspace` command
- [ ] Version tracking and warnings
- [ ] User testing with Codespaces

### v1.0 (Stable)

- [ ] Legacy mount support removed
- [ ] All templates migrated
- [ ] Production documentation complete

---

## Related Specifications

- `sparc/1-specification/12_MOUNT_STRUCTURE.md` - Current mount strategy
- `sparc/1-specification/08_WORKSPACE_MANAGEMENT.md` - Workspace initialization
- `sparc/0-research/GITHUB_CODESPACES_TESTING.md` - Codespaces testing
- `sparc/2-pseudocode/bitbot-init-codespaces.md` - Init pseudocode

---

**Last Updated:** 2025-10-28
**Status:** Ready for implementation
