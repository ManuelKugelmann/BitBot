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

**The Strategy:** Host `bitbot` commands sync infrastructure, containers mount readonly:

1. **On `bitbot init`:** Copy `$BITBOT_HOME/container` → `.bitbot/internal/container/` (committed to git)
2. **On `bitbot work/config`:** Sync updates from `$BITBOT_HOME/container`, THEN start container
   - Local: `bitbot` commands sync automatically before starting container
   - Codespaces: No `bitbot` command, uses committed copies
3. **Container mounts:** `.bitbot/internal/` as readonly (both work and config modes)
4. **Container uses:** Files from `/workspace/.bitbot/internal/container/` (guaranteed to exist)

**Result:** Simple devcontainer.json, updates managed by host commands, self-contained in Codespaces!

**Mount Permissions:**
- `.bitbot/internal/` mounted **readonly** in both work and config modes
- Updates happen via **host `bitbot` commands** (before container starts)
- No `initializeCommand`, no `postAttachCommand` needed
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

### Mount Configuration: Simple Readonly Strategy

BitBot uses **simple readonly mounts** in all modes (same as `.devcontainer/`):

#### All Modes - Same Mount Strategy

**File:** `container/templates/shared/base.devcontainer.json`

```json
{
  "mounts": [
    "source=${localWorkspaceFolder}/.devcontainer/bitbot,target=/usr/local/bitbot,type=bind,readonly",
    "source=${localWorkspaceFolder}/.bitbot/internal,target=/workspace/.bitbot/internal,type=bind,readonly",
    "source=${localWorkspaceFolder}/.bitbot/internal/container/home/.tmux.conf,target=/root/.tmux.conf,type=bind,readonly"
  ]
}
```

**Config Mode Additions:**

**File:** `container/templates/bitbot-config/details.devcontainer.json`

```json
{
  "mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
  ]
}
```

**Key Points:**

| Aspect | Work Mode | Config Mode |
|--------|-----------|-------------|
| `.bitbot/internal/` mount | **Readonly** | **Readonly** (same) |
| Purpose | Production development | Infrastructure customization |
| Infrastructure updates | Via host `bitbot work` command | Via host `bitbot config` command |
| User edits | ❌ Read-only | ✅ Via workspace mount (not special mount) |
| Docker socket | ❌ Not mounted | ✅ Mounted (for rebuilds) |

**How Updates Work:**

1. **Host commands sync before starting container:**
   ```bash
   # In bitbot work/config/init commands:
   rsync -a --delete "$BITBOT_HOME/container/" ".bitbot/internal/container/"
   # THEN start devcontainer
   ```

2. **Container-side BitBot (work mode):**
   - Can detect if workspace has uncommitted changes in `.bitbot/internal/`
   - Informs user: "Infrastructure changes detected, review and commit"

3. **No devcontainer lifecycle hooks needed:**
   - No `initializeCommand`
   - No `postAttachCommand`
   - Simple, predictable behavior

**Result:**
- ✅ Simple devcontainer.json - just readonly mounts
- ✅ Updates managed by host `bitbot` commands
- ✅ Codespaces works (uses committed copies)
- ✅ Config mode doesn't need special mounts

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
    mkdir -p "$workspace/.bitbot/internal/container"

    # Sync from BITBOT_HOME (if available)
    sync_infrastructure "$workspace"

    # Copy version file
    echo "$(bitbot --version)" > "$workspace/.bitbot/internal/.version"
}

sync_infrastructure() {
    local workspace="$1"

    # This function is called by: bitbot init, bitbot work, bitbot config
    # Syncs $BITBOT_HOME/container → workspace/.bitbot/internal/container/

    if [ -n "$BITBOT_HOME" ] && [ -d "$BITBOT_HOME/container" ]; then
        echo "🔄 Syncing infrastructure from BitBot..."
        rsync -a --delete "$BITBOT_HOME/container/" "$workspace/.bitbot/internal/container/"
        echo "✅ Infrastructure synced"
    else
        echo "ℹ️  No BitBot installation found (Codespaces/standalone mode)"
        echo "   Using workspace infrastructure files"
    fi
}
```

### 2. `bitbot work` / `bitbot config` - Sync Before Start

**File:** `core/workspace/bitbot-work.sh` and `core/workspace/bitbot-config.sh`

```bash
#!/bin/bash
# Sync infrastructure, then start container

main() {
    # Detect workspace
    workspace=$(detect_workspace)

    # Sync infrastructure from $BITBOT_HOME (shared function)
    sync_infrastructure "$workspace"

    # Start devcontainer
    start_devcontainer "$workspace" "work"  # or "config"
}
```

**Behavior:**
- Every `bitbot work` or `bitbot config` call syncs infrastructure first
- Ensures containers always start with latest infrastructure
- Silent when up-to-date, informs when syncing

### 3. Container-Side Detection (Optional)

**File:** `container/bitbot/core/util/check-infrastructure.sh`

```bash
#!/bin/bash
# Check if workspace has uncommitted infrastructure changes

check_uncommitted_infrastructure() {
    cd /workspace

    # Check if .bitbot/internal/ has uncommitted changes
    if git status --porcelain .bitbot/internal/ | grep -q "^"; then
        echo "ℹ️  Infrastructure changes detected in .bitbot/internal/"
        echo "   Review changes: git diff .bitbot/internal/"
        echo "   Commit if ready: git add .bitbot/internal/ && git commit"
    fi
}

# Run check (can be called from work mode container)
check_uncommitted_infrastructure
```

**Usage:** Container BitBot can call this to inform user about pending changes.

### 4. Git Configuration

**File:** `.gitignore` (workspace root)

```gitignore
# BitBot infrastructure
/.bitbot/wrapper-runtime/        # Session files (never commit)
/.bitbot/internal/global/        # Not used (reserved for future)
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
- [x] Simple readonly mount strategy (all modes) ✅
- [x] Host-command-based sync (no lifecycle hooks) ✅
- [ ] `bitbot init` creates `.bitbot/internal/container/` directory
- [ ] `bitbot init` supports re-init for updates
- [ ] Add `sync_infrastructure()` function (shared)
- [ ] `bitbot work/config` calls `sync_infrastructure()` before starting container
- [ ] `.bitbot/internal/` mounted readonly (all modes)
- [ ] Config mode: Docker socket mounted (for rebuilds)
- [ ] Container-side: Optional uncommitted changes detection
- [ ] Update base.devcontainer.json (simple readonly mounts)
- [ ] Update bitbot-work template (no special config needed)
- [ ] Update bitbot-config template (add Docker socket mount)
- [ ] Test in local environment (host command sync workflow)
- [ ] Test in Codespaces (uses committed copies)
- [ ] Test switching modes (work ↔ config)
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
