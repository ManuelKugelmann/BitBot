# SPEC-02 Terminology Updates

**Purpose**: Update terminology from "setup mode" to "config mode" throughout SPEC-02

**Status**: Ready for manual application

---

## Changes Needed

### Global Find/Replace

Replace all instances of:
- `setup mode` → `config mode`
- `Setup Mode` → `Config Mode`
- `SETUP_START` → `CONFIG_START`
- `setup` → `config` (in command contexts like `bitbot setup` → `bitbot config`)

### Specific Context Updates

**Line 14**:
```
OLD: Two-mode security system (work/setup)
NEW: Two-mode security system (work/config)
```

**Line 16**:
```
OLD: "Key Decision (D-02): Two modes (work/setup) + git-based protection"
NEW: "Key Decision (D-02): Two modes (work/config) + git-based protection"
```

**Line 31**:
```
OLD: **Setup Mode** (MVP Simplified - also called "Config Mode"):
NEW: **Config Mode**:
```

**Line 52**:
```
OLD: │ 3. Both Modes: Separate devcontainer configurations        │
    │    (work uses workspace .devcontainer, setup uses global)   │
NEW: │ 3. Both Modes: Separate devcontainer configurations        │
    │    (work uses workspace .devcontainer, config uses global)  │
```

**Line 80**:
```
OLD: - ✅ Both work and setup containers use synced UID
NEW: - ✅ Both work and config containers use synced UID
```

**Line 85**:
```
OLD: - Static UIDs (2001=sketch, 2002=work, 2003=setup)
NEW: - Static UIDs (2001=sketch, 2002=work, 2003=config)
```

**Line 124**:
```
OLD: - ❌ Change container configuration without user switching to setup mode
NEW: - ❌ Change container configuration without user switching to config mode
```

**Line 182** (Section Title):
```
OLD: ## 3. Setup Mode Security (MVP Simplified)
NEW: ## 3. Config Mode Security (MVP Simplified)
```

**Line 184** (Subsection Title):
```
OLD: ### 3.1 Setup Devcontainer Architecture
NEW: ### 3.1 Config Devcontainer Architecture
```

**Line 195**:
```
OLD: **Per-Workspace Config**: `.bitbot/setup/devcontainer.json`
- Created on first `bitbot setup` launch
NEW: **Per-Workspace Config**: `.bitbot/internal/devcontainer.json`
- Created on first `bitbot config` launch
```

**Line 200**:
```
OLD: **Setup Container Mounts** (MVP):
NEW: **Config Container Mounts** (MVP):
```

**Line 202**:
```
OLD: # Managed by global setup devcontainer
NEW: # Managed by global config devcontainer
```

**Line 237**:
```
OLD: 1. User runs `bitbot setup`
NEW: 1. User runs `bitbot config`
```

**Line 239**:
```
OLD: 3. Setup devcontainer launches with RW access to .devcontainer
NEW: 3. Config devcontainer launches with RW access to .devcontainer
```

**Line 254**:
```
OLD: - Work: Uses workspace's `.devcontainer/` + RO bind mount
    - Setup: Uses global `~/.bitbot/setup-devcontainer/` + no RO mount
NEW: - Work: Uses workspace's `.devcontainer/` + RO bind mount
    - Config: Uses global `templates/bitbot/config/` + no RO mount
```

**Line 268**:
```
OLD: | `.bitbot/setup/`     | N/A        | Config only| Per-workspace setup config         |
NEW: | `.bitbot/internal/`  | N/A        | Config only| Per-workspace config mode settings |
```

**Line 302**:
```
OLD: bitbot setup  # Start/attach to setup container (simplified, no approval)
NEW: bitbot config # Start/attach to config container (simplified, no approval)
```

**Line 317**:
```
OLD: - **Infrastructure changes**: Configure in setup container
NEW: - **Infrastructure changes**: Configure in config container
```

**Line 334**:
```
OLD: [2025-10-20T14:31:00Z] SETUP_START: container=bitbot-setup user=developer
NEW: [2025-10-20T14:31:00Z] CONFIG_START: container=bitbot-config user=developer
```

**Line 345**:
```
OLD: **Future**: Add comprehensive audit trail when setup mode gets approval flow
NEW: **Future**: Add comprehensive audit trail when config mode gets approval flow
```

**Line 359**:
```
OLD: # Enter setup mode to fix .devcontainer
    bitbot setup
NEW: # Enter config mode to fix .devcontainer
    bitbot config
```

**Line 410** (Subsection Title):
```
OLD: ### 8.2 Setup/Config Mode Container Security
NEW: ### 8.2 Config Mode Container Security
```

**Line 470**:
```
OLD: - [ ] Setup mode allows `.devcontainer` modification (no RO mount)
NEW: - [ ] Config mode allows `.devcontainer` modification (no RO mount)
```

**Line 472**:
```
OLD: - [ ] Setup uses global template (~/.bitbot/setup-devcontainer/)
NEW: - [ ] Config uses global template (templates/bitbot/config/)
```

---

## Notes

- Keep "Config Mode" capitalized when referring to the mode as a proper noun
- Use lowercase "config mode" in flowing text
- Preserve "setup" in historical context (e.g., "first-time setup wizard")
- The term "config" aligns with the container's purpose: configuration editing
