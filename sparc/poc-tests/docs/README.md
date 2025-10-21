# BitBot Windows Launch - Documentation

**Status**: Production Ready (VS Code Direct DevContainer Opening)
**Last Updated**: 2025-10-20
**Platform**: Windows 11 + WSL2 (tested), macOS/Linux (pending)

---

## Overview

This folder contains the production implementation of **VS Code Direct DevContainer Opening** , BitBot's method for launching VS Code directly in dev containers without manual "Reopen in Container" popups.

### Key Innovation

**Direct URI Opening**: VS Code opens directly in dev containers using hex-encoded URIs:
```bash
code --folder-uri="vscode-remote://dev-container+{HEX_ENCODED_PATH}/workspace"
```

**Benefits**:
- ✅ No "Reopen in Container" popup
- ✅ No devcontainer CLI needed (saves ~200MB in Alpine)
- ✅ No WSL path corruption issues
- ✅ Container reuse (same container for CLI and VS Code)
- ✅ 47% less code (~100 lines vs ~190)

---

## Production Scripts

Located in `../scripts/`:

### `bitbot-core.sh` ⭐
**Core VS Code Direct DevContainer Opening implementation** - Cross-platform bash script with:
- Platform detection (`detect_platform()`)
- Hex encoding with Alpine fallback (`path_to_hex()`)
- Direct URI opening (`bitbot_vscode()`)
- Windows username detection for WSL paths

**Usage**:
```bash
source bitbot-core.sh
bitbot_vscode /path/to/workspace
```

**Future location**: `/opt/bitbot/bin/bitbot-core.sh`

### `bitbot`
**Main BitBot launcher** - Integrated VS Code Direct DevContainer Opening functionality:
- Includes `open_vscode_devcontainer()` function
- Platform detection and hex encoding
- Direct URI opening

**Current location**: `scripts/bitbot`
**Future location**: `/opt/bitbot/bin/bitbot`

**Note**: Standalone `vscode-devcontainer-utils.sh` moved to `tests/` for reference.

### `Open-VSCodeDevContainer.ps1`
**Windows PowerShell entry point** - Direct PowerShell launcher for VS Code Direct DevContainer Opening.

**Usage**:
```powershell
.\Open-VSCodeDevContainer.ps1 -WorkspacePath "C:\Projects\MyProject"
```

---

## Architecture Documentation

### `FINAL-BITBOT-ARCHITECTURE.md` ⭐
**Primary architecture document** - Complete VS Code Direct DevContainer Opening implementation guide:
- Core principle and design
- Cross-platform implementation
- Platform detection and hex encoding
- Complete code examples
- Testing results (Windows validated)

**Start here** for understanding the production architecture.

### `DIRECT-DEVCONTAINER-FINDINGS.md` ⭐
**Technical deep-dive** - VS Code Direct DevContainer Opening discovery and analysis:
- How VS Code's folder-uri protocol works
- Hex encoding requirements
- Container hash differences (why VS Code builds differently)
- Comparison with manual devcontainer up approach
- Research methodology and findings

**Read this** for technical details and decision rationale.

### `DEVCONTAINER-CLI-STRATEGY.md`
**CLI approach comparison** - Analysis of different devcontainer CLI methods:
- Method 1: Native devcontainer (WSL corruption)
- Method 2: devcontainer.cmd (PowerShell only)
- Method 3: WSL → cmd.exe → devcontainer.cmd (works, but complex)
- Why VS Code Direct DevContainer Opening is superior to all CLI approaches

**Reference** for understanding why CLI approaches were abandoned.

---

## Test Scripts

Located in `../tests/`:

### VS Code DevContainer Tests (`tests/vscode_devcontainer/`)
**VS Code Direct DevContainer Opening URI validation**:
- `test-direct-open.ps1` - Direct PowerShell Direct DevContainer Opening test
- `test-bitbot-final.ps1` - WSL roundabout test (BitBot-Alpine → code.exe)

### Devcontainer Tests (`tests/devcontainer/`)
**CLI approach testing** (historical):
- `test-devcontainer-cli.ps1` - devcontainer CLI tests
- `test-devcontainer-windows-native.ps1` - Windows native CLI
- `test-devcontainer-wsl-wrapper.ps1` - WSL wrapper method
- `test-cli-then-vscode-attach.ps1` - CLI build + VS Code attach
- `test-reproduce-corruption.ps1` - WSL path corruption reproduction

### VS Code Tests (`tests/vscode/`)
**VS Code integration**:
- `test-vscode-auto.ps1` - Automated VS Code opening
- `test-vscode-build-and-open*.ps1` - Build and open workflows
- `test-vscode-direct.ps1` - Direct VS Code integration

### Discovery Tests (`tests/discovery/`)
**Container label discovery**:
- `test-label-discovery.ps1` - Container label tests
- `test-label-discovery-fixed.ps1` - Fixed label discovery

### Other Tests (`tests/`)
**Miscellaneous**:
- `test-docker.ps1` - Docker functionality
- `test-env-detection.ps1` - Environment detection
- `test-path-priority.ps1/sh` - PATH priority testing
- `test-container-claude.sh` - Claude Code integration

---

## Utilities

Located in `../utils/`:

### `compare-all-methods.ps1`
**Method comparison tool** - Compares all devcontainer launch methods:
- Direct URI
- PowerShell → devcontainer.cmd
- WSL → cmd.exe → devcontainer.cmd

Useful for documentation and benchmarking.

### `debug-containers.ps1`
**Container debugging** - Debug running/stopped dev containers:
- List containers by hash
- Inspect labels and mounts
- Check VS Code vs CLI differences

### `fix-docker-desktop-pwd.sh`
**Docker Desktop fix** - Fixes PWD variable corruption in Docker Desktop.

### `fix-wsl-service.ps1`
**WSL service fix** - Repairs WSL service issues on Windows.

---

## Archive

Located in `../archive/`:

### Legacy Launchers (`archive/legacy-launchers/`)
Pre-VS Code Direct DevContainer Opening launch methods (obsolete):
- `bitbot.ps1`, `bitbot.sh` - Original test launchers
- `bitbot-inline.ps1` - Inline execution method
- `bitbot-smart.ps1` - Smart detection approach
- `bitbot-newterminal.ps1` - New terminal approach
- `bitbot-launch-vscode.ps1` - Old VS Code launcher

### Manual Building (`archive/manual-building/`)
Manual devcontainer CLI scripts (replaced by VS Code Direct DevContainer Opening):
- `build-devcontainer.ps1/sh` - Manual container building
- `open-devcontainer.ps1` - devcontainer up approach
- `open-vscode-in-container.ps1` - Old VS Code opening
- `install/uninstall-bitbot-wsl.ps1` - Old installation

### Old Documentation (`archive/old-docs/`)
Superseded documentation:
- `UPDATED-BITBOT-ARCHITECTURE.md` - Old architecture (before VS Code Direct DevContainer Opening)
- `FINAL-BITBOT-FLOW.md` - Old flow diagram
- `FIXED-WSL-PATH-SCRIPTS.md` - WSL path fixes (now obsolete)
- `README-*.md` - Fragmented READMEs
- `SOLUTION-SUMMARY.md`, `TESTING-SUMMARY.md` - Old summaries

### Research (`archive/research/`)
Future enhancements and analysis:
- `TODO-HASH-MATCHING.md` - Container hash matching research (CI/CD pre-builds)
- `TROUBLESHOOTING-WSL-PATH.md` - Historical WSL path troubleshooting
- `DOCKER-DESKTOP-CORRUPTION-ANALYSIS.md` - WSL corruption analysis
- `LABEL-DISCOVERY-FINDINGS.md` - Container label research

---

## Quick Start

### Running VS Code Direct DevContainer Opening Production Code

**From PowerShell (Windows)**:
```powershell
cd C:\Projects\BitBot\test-windows-launch\scripts
.\Open-VSCodeDevContainer.ps1 -WorkspacePath "C:\Projects\MyProject"
```

**From WSL (BitBot-Alpine)**:
```bash
cd /mnt/c/Projects/BitBot/test-windows-launch/scripts
source bitbot-core.sh
bitbot_vscode /mnt/c/Projects/MyProject
```

**From macOS/Linux** (future):
```bash
cd /path/to/BitBot/test-windows-launch/scripts
source bitbot-core.sh
bitbot_vscode /path/to/myproject
```

### Running Tests

**VS Code Direct DevContainer Opening validation**:
```powershell
cd C:\Projects\BitBot\test-windows-launch\tests\vscode_devcontainer
.\test-direct-open.ps1
```

**Full test suite**:
```powershell
cd C:\Projects\BitBot\test-windows-launch\tests
Get-ChildItem -Recurse -Filter "test-*.ps1" | ForEach-Object { & $_.FullName }
```

---

## Platform Status

| Platform | Status | Notes |
|----------|--------|-------|
| Windows 11 + WSL2 | ✅ Tested | Production ready with BitBot-Alpine |
| macOS | ⏳ Pending | Code ready, needs testing |
| Linux native | ⏳ Pending | Code ready, needs testing |

---

## Technical Details

### Hex Encoding

**Purpose**: Convert file paths to hex for VS Code URI protocol.

**Implementation**:
```bash
# Preferred (if xxd available)
hex_path=$(printf "%s" "$path" | xxd -p -c 256 | tr -d '\n')

# Fallback for Alpine (no xxd)
hex_path=$(printf "%s" "$path" | od -A n -t x1 | tr -d ' \n')
```

### Platform Detection

```bash
detect_platform() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}
```

### VS Code URI Format

```
vscode-remote://dev-container+{HEX_ENCODED_WORKSPACE_PATH}{CONTAINER_PATH}
```

**Example**:
```
vscode-remote://dev-container+433a5c50726f6a656374735c4269744.../workspace
                              └─────────────────┬─────────────────┘ └───┬───┘
                                  C:\Projects\BitBot (hex)          container path
```

---

## Dependencies

### Required
- **VS Code** with Dev Containers extension
- **bash** (for bitbot-core.sh)
- **coreutils** (`od` for hex encoding fallback)

### Optional
- **xxd** (preferred hex encoder, faster than od)
- **PowerShell** (for Windows entry points)

### NOT Required (VS Code Direct DevContainer Opening advantage)
- ❌ Docker CLI in WSL/Alpine
- ❌ Node.js + npm
- ❌ @devcontainers/cli package

---

## Troubleshooting

### VS Code Opens But Not in Container

**Symptom**: VS Code opens in regular mode, not dev container.

**Causes**:
1. `.devcontainer/devcontainer.json` missing
2. Hex encoding incorrect
3. Path escaping issues

**Fix**:
```bash
# Verify .devcontainer exists
ls -la /path/to/workspace/.devcontainer/

# Test hex encoding
printf "%s" "C:\Projects\Test" | od -A n -t x1 | tr -d ' \n'
```

### WSL Path Corruption

**Symptom**: `/mnt/c/Users/.../My Documents` becomes broken path.

**This is why VS Code Direct DevContainer Opening exists!** The old devcontainer CLI approach corrupted paths. VS Code Direct DevContainer Opening uses hex encoding which is immune to path corruption.

**If still seeing issues**:
- Ensure using `scripts/bitbot (integrated core)` (VS Code Direct DevContainer Opening), not archive scripts
- Check no spaces in workspace path variable

### Container Not Found

**Symptom**: "No dev container configuration found"

**Fix**: Ensure `.devcontainer/devcontainer.json` exists with valid JSON.

---

## References

### Specifications
- **SPEC-06**: VS Code DevContainer Integration
  - Section 0: VS Code Direct DevContainer Opening 
  - `/mnt/c/Projects/BitBot/Claude_Specification/06_VSCODE_DEVCONTAINER_INTEGRATION.md`

### Decision Records
- **Direct DevContainer Opening**: VS Code Direct DevContainer Opening (hex-encoded URIs)

### External Resources
- VS Code Dev Containers: https://code.visualstudio.com/docs/devcontainers/containers
- VS Code URI Handling: https://code.visualstudio.com/api/advanced-topics/uri-handler

---

## Contributing

### Adding Tests

Place new tests in appropriate subfolder:
- Direct DevContainer Opening validation (VS Code direct opening) → `tests/vscode_devcontainer/`
- Devcontainer CLI → `tests/devcontainer/`
- VS Code integration → `tests/vscode/`
- Discovery/labels → `tests/discovery/`

### Updating Production Scripts

1. Edit in `scripts/`
2. Test on all platforms (Windows, macOS, Linux)
3. Update this README.md if behavior changes
4. Update SPEC-06 if architecture changes

---

**Questions?** See `FINAL-BITBOT-ARCHITECTURE.md` for complete implementation details.
