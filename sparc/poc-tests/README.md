# Proof-of-Concept Tests (Windows Launcher)

This directory contains proof-of-concept tests and experimental code for BitBot's Windows launcher implementation, particularly the **VS Code Direct DevContainer Opening** approach.

## Purpose

These PoC tests served to:
- **Validate** the Windows launcher approach using WSL and Alpine Linux
- **Explore** different methods for opening VS Code in dev containers
- **Test** cross-platform compatibility (Windows, macOS, Linux)
- **Document** findings and technical decisions
- **Archive** alternative approaches that were considered but not adopted

## Status

**Phase**: Proof-of-Concept Complete
**Production Code**: Moved to `/core/` (formerly `/lib/`)
**Key Innovation**: VS Code Direct DevContainer Opening (hex-encoded URIs)

## Directory Structure

```
poc-tests/
├── docs/             Detailed documentation and architecture
│   ├── FINAL-BITBOT-ARCHITECTURE.md ⭐ Primary architecture doc
│   ├── DIRECT-DEVCONTAINER-FINDINGS.md ⭐ Technical deep-dive
│   ├── DEVCONTAINER-CLI-STRATEGY.md    CLI approach comparison
│   └── LINE-ENDING-STRATEGY.md         Line ending management
├── scripts/          Production-ready scripts (PoC versions)
│   ├── bitbot        Main launcher (PoC version)
│   ├── bitbot-core.sh VS Code opening implementation
│   └── *.ps1         PowerShell entry points
├── tests/            Test suites for validation
│   ├── vscode_devcontainer_open/  VS Code URI opening tests
│   ├── vscode_devcontainer_interop/ Integration tests
│   ├── terminal/                   Terminal handling tests
│   └── generic/                    General tests
├── archive/          Historical approaches (obsolete)
│   ├── legacy-launchers/  Pre-direct-opening methods
│   ├── manual-building/   Manual devcontainer CLI scripts
│   └── research/          Analysis and future work
└── .devcontainer/    PoC dev environment config
```

## Key Innovation: VS Code Direct DevContainer Opening

The primary achievement of these PoC tests was discovering and validating the **Direct DevContainer Opening** approach:

### The Problem
Traditional devcontainer CLI methods had issues:
- ✗ Required `@devcontainers/cli` package (~200MB)
- ✗ WSL path corruption with spaces
- ✗ Complex Windows/WSL interop
- ✗ Manual "Reopen in Container" popups

### The Solution
Direct VS Code opening using hex-encoded URIs:

```bash
code --folder-uri="vscode-remote://dev-container+{HEX_PATH}/workspace"
```

**Benefits**:
- ✓ No devcontainer CLI needed
- ✓ No WSL path corruption (hex encoding is immune)
- ✓ No manual popup
- ✓ Container reuse between CLI and VS Code
- ✓ 47% less code (100 lines vs 190)

## Relationship to Production Code

### PoC → Production Migration

| PoC Location                              | Production Location                  | Status      |
|-------------------------------------------|--------------------------------------|-------------|
| `poc-tests/scripts/bitbot`                | `/bitbot` (root)                     | ✓ Migrated  |
| `poc-tests/scripts/bitbot-core.sh`        | `/core/workspace/bitbot-vscode.sh`   | ✓ Adapted   |
| `poc-tests/docs/FINAL-BITBOT-ARCHITECTURE.md` | `../1-specification/06_VSCODE_DEVCONTAINER_INTEGRATION.md` | ✓ Spec'd |
| `poc-tests/tests/`                        | `/tests/` (root)                     | ✓ Migrated  |

### What Stayed in PoC
- Archive of abandoned approaches
- Experimental scripts
- Detailed technical findings
- Platform-specific validation tests

## Key Documents

### Architecture & Decisions
- **`docs/FINAL-BITBOT-ARCHITECTURE.md`** - Complete architecture guide ⭐
- **`docs/DIRECT-DEVCONTAINER-FINDINGS.md`** - Technical discovery and analysis ⭐
- **`docs/DEVCONTAINER-CLI-STRATEGY.md`** - Why CLI approaches were abandoned

### Historical Context
- **`archive/research/DOCKER-DESKTOP-CORRUPTION-ANALYSIS.md`** - WSL corruption analysis
- **`archive/research/LABEL-DISCOVERY-FINDINGS.md`** - Container label research
- **`archive/research/TODO-HASH-MATCHING.md`** - Future optimization ideas

## Platform Testing Results

| Platform           | Status      | Notes                                   |
|--------------------|-------------|-----------------------------------------|
| Windows 11 + WSL2  | ✅ Validated | Production-ready with BitBot-Alpine     |
| macOS              | ⏳ Pending  | Code ready, needs platform testing      |
| Linux              | ⏳ Pending  | Code ready, needs platform testing      |

## Technical Highlights

### Hex Encoding Strategy
**Problem**: Paths with spaces broke in traditional CLI approaches
**Solution**: Hex-encode entire path for VS Code URI

```bash
# Example: "C:\Projects\BitBot" → hex
hex=$(printf "%s" "$path" | od -A n -t x1 | tr -d ' \n')
# Result: 433a5c50726f6a656374735c4269744...
```

### Cross-Platform Detection
```bash
detect_platform() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"      # Windows Subsystem for Linux
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"    # macOS
    else
        echo "linux"    # Native Linux
    fi
}
```

### Windows Username Detection
For WSL → Windows path conversion:
```bash
# Get Windows username from WSL
WINDOWS_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
```

## Not Included in Release

The entire `poc-tests/` directory is excluded from release distributions. Only validated production code in `/core/`, `/templates/`, and entry scripts are released.

## Usage

**For developers**:
- Reference `docs/` for understanding design decisions
- Review `archive/` to see alternative approaches considered
- Run `tests/` to validate cross-platform behavior

**For implementation**:
- **Don't** copy from `scripts/` - use production code in `/core/`
- **Do** reference `docs/FINAL-BITBOT-ARCHITECTURE.md` for architecture
- **Do** check SPEC-06 for authoritative specification

## See Also

- **Production Specs**: `../1-specification/06_VSCODE_DEVCONTAINER_INTEGRATION.md`
- **Research**: `../0-research/VM_WRAPPER_SOLUTIONS_RESEARCH.md`
- **Production Code**: `/core/workspace/bitbot-vscode.sh`
- **Tests**: `/tests/` (root)
