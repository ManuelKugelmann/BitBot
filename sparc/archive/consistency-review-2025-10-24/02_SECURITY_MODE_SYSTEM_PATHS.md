# SPEC-02 Path Updates

**Purpose**: Update paths to reflect new template organization structure

**Status**: Ready for manual application

---

## Changes Needed

### Global Path Updates

Replace all instances of:
- `~/.bitbot/setup-devcontainer/` → `templates/bitbot/config/`
- `.bitbot/setup/` → `.bitbot/internal/`

### Specific Context Updates

**Line 28**:
```
OLD: - **Protection**: `.devcontainer` mounted read-only, `.bitbot/setup/` invisible
NEW: - **Protection**: `.devcontainer` mounted read-only, `.bitbot/internal/` invisible
```

**Line 33**:
```
OLD: - **Container**: Uses global setup devcontainer template (~/.bitbot/setup-devcontainer/)
NEW: - **Container**: Uses global config devcontainer template (templates/bitbot/config/)
```

**Line 123**:
```
OLD: - ❌ See or modify `.bitbot/setup/` directory
NEW: - ❌ See or modify `.bitbot/internal/` directory
```

**Line 186** (Section):
```
OLD: **Global Template Location**: `~/.bitbot/setup-devcontainer/`
    ```
    ~/.bitbot/setup-devcontainer/
    ├── devcontainer.json        # Global setup config
    └── Dockerfile               # Config container (Claude Code AI + config tools, no Docker inside)
    ```
NEW: **Global Template Location**: `templates/bitbot/config/`
    ```
    templates/bitbot/config/
    ├── devcontainer.json        # Global config mode config
    └── Dockerfile               # Config container (Claude Code AI + config tools, no Docker inside)
    ```
```

**Line 195**:
```
OLD: **Per-Workspace Config**: `.bitbot/setup/devcontainer.json`
- Created on first `bitbot config` launch
- References global Dockerfile
- Configures workspace-specific mounts
NEW: **Per-Workspace Config**: `.bitbot/internal/devcontainer.json`
- Created on first `bitbot config` launch
- References global Dockerfile at templates/bitbot/config/
- Configures workspace-specific mounts
```

**Line 254**:
```
OLD: - Config: Uses global `~/.bitbot/setup-devcontainer/` + no RO mount
NEW: - Config: Uses global `templates/bitbot/config/` + no RO mount
```

**Line 268**:
```
OLD: | `.bitbot/setup/`     | N/A        | Config only| Per-workspace setup config         |
NEW: | `.bitbot/internal/`  | N/A        | Config only| Per-workspace config mode settings |
```

**Line 271** (Section Title):
```
OLD: ### 4.2 Global Setup Template Protection
NEW: ### 4.2 Global Config Template Protection
```

**Line 273**:
```
OLD: **~/.bitbot/setup-devcontainer/ Contents** (On host, not workspace):
    ```
    ~/.bitbot/setup-devcontainer/
    ├── devcontainer.json        # Global config mode template
    └── Dockerfile               # Config container image (no Docker inside)
    ```
NEW: **templates/bitbot/config/ Contents** (In BitBot installation):
    ```
    templates/bitbot/config/
    ├── devcontainer.json        # Global config mode template
    └── Dockerfile               # Config container image (no Docker inside)
    ```
```

**Line 280**:
```
OLD: **Per-Workspace Setup Config**:
    ```
    .bitbot/setup/
    └── devcontainer.json        # Links to global template, workspace mounts
    ```
NEW: **Per-Workspace Config Settings**:
    ```
    .bitbot/internal/
    └── devcontainer.json        # Links to global template, workspace mounts
    ```
```

**Line 286**:
```
OLD: **Why Separate**:
- Shared setup image across all workspaces
- Per-workspace mount configuration
- Setup container can work on any workspace via BITBOT_WORKSPACE env var
NEW: **Why Separate**:
- Shared config mode image across all workspaces
- Per-workspace mount configuration
- Config container can work on any workspace via workspace mount
```

**Line 472**:
```
OLD: - [ ] Config uses global template (~/.bitbot/setup-devcontainer/)
NEW: - [ ] Config uses global template (templates/bitbot/config/)
```

---

## Architecture Context

The new path structure reflects:
- **Installation portability**: No `~/.bitbot/` global directory
- **Template organization**: All templates in `templates/bitbot/` folder
- **Clear naming**: `internal/` better describes per-workspace config settings
- **Consistency**: Matches workspace template at `templates/bitbot/workspace/`

---

## Related Changes

These path updates align with:
- Template reorganization (2025-10-24)
- SPARC directory structure
- Portable installation design
- Global config strategy (see GLOBAL_CLAUDE_CONFIG_SPEC.md)
