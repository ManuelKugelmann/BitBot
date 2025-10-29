# DevContainer CLI WSL Path Formats - Research & Testing

**Date**: 2025-10-29
**Status**: ✅ Verified
**Summary**: `devcontainer.cmd` DOES support WSL native paths using `\\wsl.localhost\<distro>\...` format

---

## Executive Summary

**Previous Understanding (INCORRECT)**:
- ❌ "devcontainer.cmd cannot accept WSL native paths when called from bash"
- ❌ "WSL native paths ($HOME) cannot be translated to Windows format"

**Corrected Understanding (VERIFIED)**:
- ✅ `devcontainer.cmd` accepts WSL native paths via `\\wsl.localhost\<distro>\...` format
- ✅ Works when called from bash via PowerShell wrapper
- ✅ VS Code recognizes containers built with these paths
- ✅ No rebuild required when VS Code opens the workspace

---

## Path Format Comparison

### Method 1: WSL Path (FAILS)
```bash
# Trying to use raw WSL path
/home/mk/test-project

# Result: Path translation fails
devcontainer.local_folder = /mnt/c/...  # Wrong format, VS Code won't match
```

### Method 2: /mnt/c/ Mount (WORKS)
```bash
# Using Windows mount
/mnt/c/Projects/test-project

# Result: Converts to Windows path
devcontainer.local_folder = C:\Projects\test-project  # Correct, VS Code matches
```

### Method 3: UNC Path via cmd.exe (FAILS)
```bash
# Trying UNC path with cmd.exe
cmd.exe /c "cd /d \\wsl.localhost\Ubuntu\home\mk\test-project && ..."

# Result: cmd.exe rejects UNC paths as current directory
CMD does not support UNC paths as current directories.
```

### Method 4: UNC Path via PowerShell (WORKS) ✅
```bash
# Using PowerShell wrapper with UNC path
powershell.exe -NoProfile -Command "devcontainer.cmd up --workspace-folder '\\\\wsl.localhost\\Ubuntu\\home\\mk\\test-project'"

# Result: Correct labels, VS Code matches!
devcontainer.local_folder = \\wsl.localhost\Ubuntu\home\mk\test-project
```

---

## Empirical Test Results

### Test Setup
```bash
# Test workspace in WSL home
cd "$HOME/test-wsl-localhost-path"

# Create minimal devcontainer config
mkdir -p .devcontainer
cat > .devcontainer/devcontainer.json <<'EOF'
{
  "name": "WSL Localhost Path Test",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {}
}
EOF
```

### Test Execution
```bash
# Convert WSL path to \\wsl.localhost format
WSL_DISTRO="Ubuntu"  # From $WSL_DISTRO_NAME
WSL_PATH="/home/mk/test-wsl-localhost-path"
WIN_PATH="\\\\wsl.localhost\\${WSL_DISTRO}${WSL_PATH}"

# Build container
powershell.exe -NoProfile -Command "devcontainer.cmd build --workspace-folder '$WIN_PATH'"
# ✅ SUCCESS: Build completed

# Start container
powershell.exe -NoProfile -Command "devcontainer.cmd up --workspace-folder '$WIN_PATH'"
# ✅ SUCCESS: Container started
```

### Container Labels (Verified)
```bash
docker inspect <container> --format '{{.Config.Labels}}'

# Results:
devcontainer.local_folder = \\wsl.localhost\Ubuntu\home\mk\test-wsl-localhost-path
devcontainer.config_file = \Ubuntu\home\mk\test-wsl-localhost-path\.devcontainer\devcontainer.json
```

### VS Code Detection (Verified)
```bash
# Open workspace in VS Code
code .

# Result: ✅ VS Code detected the container!
# - "Reopen in Container" popup appeared
# - Clicking it attached to existing container (no rebuild)
# - Container label matched VS Code's workspace path format
```

---

## Technical Analysis

### Why Method 4 Works

1. **UNC Path Support in PowerShell**
   - PowerShell can use UNC paths as arguments
   - `devcontainer.cmd` receives the path as a parameter (not current directory)
   - No `cd` operation with UNC path (avoids cmd.exe limitation)

2. **WSL.localhost Protocol**
   - Windows 10/11 feature for accessing WSL filesystems
   - Format: `\\wsl.localhost\<DistroName>\<Path>`
   - Works with native Windows applications
   - Docker can mount these paths

3. **VS Code Label Matching**
   - VS Code uses `devcontainer.local_folder` label to find containers
   - Accepts both `C:\...` and `\\wsl.localhost\...` formats
   - Label must match the workspace path format VS Code sees
   - When opening WSL workspace, VS Code likely uses `\\wsl.localhost` internally

### Why cmd.exe Fails

```
CMD.EXE was started with the above path as the current directory.
UNC paths are not supported.  Defaulting to Windows directory.
```

- `cmd.exe /c "cd /d <UNC>"` doesn't work
- cmd.exe limitation, not devcontainer.cmd limitation
- PowerShell doesn't have this restriction

---

## Implementation Strategy

### Bash Wrapper Function

```bash
devcontainer_wsl_path() {
    local wsl_path="$1"
    local distro="${WSL_DISTRO_NAME:-Ubuntu}"

    # Convert /home/user/... to \\wsl.localhost\Ubuntu\home\user\...
    local win_path="\\\\wsl.localhost\\${distro}${wsl_path}"

    # Call via PowerShell
    powershell.exe -NoProfile -Command "devcontainer.cmd up --workspace-folder '$win_path'"
}
```

### Path Detection Logic

```bash
detect_and_convert_path() {
    local path="$1"

    if [[ "$path" == /mnt/* ]]; then
        # Windows mount - convert to C:\ format
        echo "$path" | sed 's|/mnt/\([a-z]\)/|\U\1:/|' | sed 's|/|\\|g'
    else
        # WSL native path - use \\wsl.localhost format
        local distro="${WSL_DISTRO_NAME:-Ubuntu}"
        echo "\\\\wsl.localhost\\${distro}${path}"
    fi
}
```

---

## Performance Implications

### WSL Native Filesystem (ext4)
- **Performance**: Best (native Linux filesystem)
- **Path Format**: `\\wsl.localhost\Ubuntu\home\...`
- **Use Case**: Recommended for development

### Windows Mount (/mnt/c/)
- **Performance**: Slower (9P protocol overhead)
- **Path Format**: `C:\Projects\...`
- **Use Case**: When sharing files with Windows apps

### Sources
- VS Code Documentation: "Use WSL 2 filesystem for best performance"
- Microsoft WSL docs: 9P filesystem slower than native ext4

---

## Test Matrix

| Path Type | Format | cmd.exe Wrapper | PowerShell Wrapper | VS Code Match |
|-----------|--------|-----------------|-------------------|---------------|
| WSL Home | `/home/...` | ❌ (cd fails) | ✅ (UNC works) | ✅ |
| Windows Mount | `/mnt/c/...` | ✅ (converts) | ✅ (converts) | ✅ |
| Literal UNC | `\\wsl.localhost\...` | ❌ (cd fails) | ✅ (works) | ✅ |

---

## Related Research

### vscli (michidk/vscli)
- Rust CLI tool for launching VS Code with dev container support
- Handles multiple dev container configs in same project
- Provides interactive selection TUI
- Does NOT document specific WSL path handling
- Uses VS Code's URI protocol for launching

### blog.lohr.dev
- Documents dev container URI format
- Hex-encoded paths in `vscode-remote://dev-container+<hex>...`
- Alternative to CLI-based launching
- Direct URI bypass "Reopen in Container" popup

### GitHub Issue #8738
- Reports `devcontainer` CLI hangs in WSL
- Related to wrapper script issues
- Does NOT apply to `devcontainer.cmd` with proper path format

---

## Corrected Method Comparison

| Method | Command | Path Label | VS Code | Notes |
|--------|---------|------------|---------|-------|
| 1 | WSL → devcontainer | `/mnt/c/...` | ❌ | Wrong format |
| 2 | cmd.exe → devcontainer.cmd | `C:\...` | ✅ | /mnt/c/ only |
| 3 | cmd.exe + cd UNC | - | ❌ | cmd.exe limitation |
| **4** | **PowerShell → devcontainer.cmd** | **`\\wsl.localhost\...`** | **✅** | **WSL home works!** |

---

## Conclusion

**Key Finding**: The limitation was NOT in `devcontainer.cmd`, but in our approach.

**Corrected Statement**:
> "devcontainer.cmd DOES support WSL native paths using the `\\wsl.localhost\<distro>\...` format when called via PowerShell wrapper."

**Recommendation**: Update all tests and documentation to use Method 4 (PowerShell wrapper with `\\wsl.localhost` paths) for WSL native filesystem support.

---

## References

- **Test Date**: 2025-10-29
- **Test Location**: `/home/mk/test-wsl-localhost-path`
- **Container ID**: `7e8e760ac5ff` (clever_payne)
- **VS Code Detection**: ✅ Verified working
- **Label Format**: `\\wsl.localhost\Ubuntu\home\mk\test-wsl-localhost-path`
