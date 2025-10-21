# Release Files Analysis

**Purpose:** Determine which files should be included in the release branch
**Date:** 2025-10-21
**Status:** In Progress

---

## Current Repository Structure

```
/mnt/c/Projects/BitBot/
├── bitbot                      # Main router (bash)
├── bitbot.cmd                  # Windows CMD wrapper
├── bitbot.exe                  # Windows C launcher (38KB)
├── .devcontainer/              # Current work devcontainer
│   ├── devcontainer.json
│   ├── Dockerfile
│   └── .gitattributes
├── lib/                        # Command implementations
│   ├── bitbot-version.sh
│   ├── global/
│   │   └── bitbot-init.sh
│   ├── util/
│   │   ├── detect.sh
│   │   ├── devcontainer.sh
│   │   ├── git.sh
│   │   ├── helpers.sh
│   │   └── prerequisites.sh
│   └── workspace/
│       ├── bitbot-config.sh
│       ├── bitbot-help.sh
│       ├── bitbot-init.sh
│       └── bitbot-work.sh
├── README.md
├── LICENSE
├── _SPARC/                     # Development files (exclude from release)
├── tests/                      # Test suite (exclude from release)
├── src/                        # Source code (exclude from release)
├── scripts/                    # Dev scripts (exclude from release)
└── .github/                    # CI/CD workflows (exclude from release)
```

---

## Pseudocode Expected Structure

From `_SPARC/Pseudocode/bitbot.md`:

```
{INSTALL_BASE_PATH}/bitbot/
├── bitbot                       # Main router (bash script)
├── bitbot.ps1                   # Windows wrapper (not yet created)
├── bitbot.bat                   # Windows wrapper (not yet created)
├── config.json                  # Created during first run (not in repo)
├── config-devcontainer/         # Config mode devcontainer (NOT FOUND)
│   ├── devcontainer.json
│   └── Dockerfile
├── devcontainer-template/       # Base template for workspace .devcontainer (NOT FOUND)
│   ├── devcontainer.json        # Minimal template with BitBot defaults
│   └── Dockerfile               # Base Alpine/Ubuntu image
└── lib/
    ├── global/                  # Global commands (from install folder)
    │   └── init.sh              # First-run setup + environment validation
    ├── workspace/               # Workspace commands (from projects)
    │   ├── work.sh              # Work mode
    │   ├── config.sh            # Config mode
    │   ├── vscode.sh            # VS Code launch (NOT YET CREATED)
    │   ├── init.sh              # Workspace init
    │   └── help.sh              # Workspace help text
    └── util/                    # Shared utilities
        ├── prerequisites.sh     # Dependency checking
        ├── version.sh           # Universal: Version
        └── helpers.sh           # Common utilities
```

---

## Files Status

### ✓ Exists in Repository

1. **Entry Points:**
   - `bitbot` - Main router ✓
   - `bitbot.exe` - Windows C launcher ✓
   - `bitbot.cmd` - Windows CMD wrapper ✓

2. **Library Scripts:**
   - `lib/bitbot-version.sh` ✓
   - `lib/global/bitbot-init.sh` ✓
   - `lib/util/detect.sh` ✓
   - `lib/util/devcontainer.sh` ✓
   - `lib/util/git.sh` ✓
   - `lib/util/helpers.sh` ✓
   - `lib/util/prerequisites.sh` ✓
   - `lib/workspace/bitbot-config.sh` ✓
   - `lib/workspace/bitbot-help.sh` ✓
   - `lib/workspace/bitbot-init.sh` ✓
   - `lib/workspace/bitbot-work.sh` ✓

3. **Documentation:**
   - `README.md` ✓
   - `LICENSE` ✓ (presumably exists)

4. **Devcontainer:**
   - `.devcontainer/` ✓ (current work devcontainer)

### ✗ Missing from Repository

1. **Windows Wrappers:**
   - `bitbot.ps1` ✗ (PowerShell wrapper - not yet created)
   - `bitbot.bat` ✗ (Batch wrapper - not yet created)
   - **Note:** We have `bitbot.exe` + `bitbot.cmd` instead

2. **Config Mode Devcontainer:**
   - `config-devcontainer/` ✗ (NOT FOUND)
   - `config-devcontainer/devcontainer.json` ✗
   - `config-devcontainer/Dockerfile` ✗

3. **Workspace Devcontainer Template:**
   - `devcontainer-template/` ✗ (NOT FOUND)
   - `devcontainer-template/devcontainer.json` ✗
   - `devcontainer-template/Dockerfile` ✗

4. **Library Scripts:**
   - `lib/workspace/vscode.sh` ✗ (VS Code launch - not yet created)

---

## Analysis

### Current State

**What we have:**
- Working entry points (bitbot, bitbot.exe, bitbot.cmd)
- Complete lib/ structure with all core scripts
- Current .devcontainer/ for work mode
- README.md and LICENSE

**What's missing for MVP:**
- Config mode devcontainer (`config-devcontainer/`)
- Workspace devcontainer template (`devcontainer-template/`)
- VS Code launch script (`lib/workspace/vscode.sh`)
- Windows PowerShell/Batch wrappers (though we have bitbot.exe instead)

### Release Branch Inclusion Strategy

#### Option 1: Include Only What Exists (Minimal Release)

**Include:**
```
bitbot                          # Main router
bitbot.exe                      # Windows launcher
bitbot.cmd                      # Windows CMD wrapper
lib/                            # All library scripts
README.md                       # User documentation
LICENSE                         # License file
```

**Pros:**
- Clean release with only working components
- No placeholder/incomplete files
- Users get what's actually implemented

**Cons:**
- Missing config mode devcontainer
- Missing workspace template
- Users would need to create .devcontainer from scratch

#### Option 2: Include Current + Templates (Complete Release)

**Include:**
```
bitbot                          # Main router
bitbot.exe                      # Windows launcher
bitbot.cmd                      # Windows CMD wrapper
lib/                            # All library scripts
.devcontainer/                  # Work mode devcontainer (as template?)
README.md                       # User documentation
LICENSE                         # License file
```

**Question:** Should we rename `.devcontainer/` to `devcontainer-template/` for release?

**Pros:**
- Provides working devcontainer template
- Users have starting point
- More complete release

**Cons:**
- Still missing config-devcontainer/
- Naming confusion (.devcontainer vs devcontainer-template)

#### Option 3: Create Missing Templates (MVP-Complete Release)

**Create before release:**
1. `config-devcontainer/` - Config mode devcontainer
2. `devcontainer-template/` - Workspace template (copy of current .devcontainer/)
3. `lib/workspace/bitbot-vscode.sh` - VS Code launcher

**Include:**
```
bitbot                          # Main router
bitbot.exe                      # Windows launcher
bitbot.cmd                      # Windows CMD wrapper
config-devcontainer/            # Config mode devcontainer
devcontainer-template/          # Workspace template
lib/                            # All library scripts
README.md                       # User documentation
LICENSE                         # License file
```

**Pros:**
- Complete MVP as per specs
- Users have all needed templates
- Follows pseudocode structure

**Cons:**
- Requires creating missing components first
- More work before initial release

---

## Recommendation

**Phase 1 (Immediate):** Option 1 - Minimal Release
- Include only working components
- Get initial release out quickly
- Document what's missing in README

**Phase 2 (Near Future):** Option 3 - Complete MVP
- Create missing templates
- Add config-devcontainer/
- Add devcontainer-template/
- Update release branch

---

## Release Files List (Phase 1 - Immediate)

```
bitbot                          # Main router (bash)
bitbot.exe                      # Windows C launcher (38KB)
bitbot.cmd                      # Windows CMD wrapper
lib/                            # All library scripts
├── bitbot-version.sh
├── global/
│   └── bitbot-init.sh
├── util/
│   ├── detect.sh
│   ├── devcontainer.sh
│   ├── git.sh
│   ├── helpers.sh
│   └── prerequisites.sh
└── workspace/
    ├── bitbot-config.sh
    ├── bitbot-help.sh
    ├── bitbot-init.sh
    └── bitbot-work.sh
README.md                       # User documentation
LICENSE                         # License file
```

---

## Release Files List (Phase 2 - Complete MVP)

**Additional files to create:**
```
config-devcontainer/            # Config mode devcontainer
├── devcontainer.json
└── Dockerfile

devcontainer-template/          # Workspace template
├── devcontainer.json
└── Dockerfile

lib/workspace/bitbot-vscode.sh # VS Code launcher
```

---

## Questions for User

1. **Immediate release or wait for complete MVP?**
   - Option A: Release with what we have now (Phase 1)
   - Option B: Create missing templates first, then release (Phase 2)

2. **Devcontainer handling:**
   - Should current `.devcontainer/` be copied to `devcontainer-template/` for release?
   - Should we keep `.devcontainer/` as development-only (exclude from release)?

3. **Windows wrappers:**
   - Do we need `bitbot.ps1` and `bitbot.bat`?
   - Or is `bitbot.exe` + `bitbot.cmd` sufficient?

4. **Config mode:**
   - Is config-devcontainer/ critical for MVP release?
   - Can it be added in Phase 2?

---

## Next Steps

1. **Wait for user decision** on Phase 1 vs Phase 2
2. **Update sync scripts** with final file list
3. **Test release branch creation**
4. **Verify all included files are functional**
5. **Update README.md** for release (user-facing docs)
