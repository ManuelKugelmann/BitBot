# VS Code WSL Mode Test Results

**Date**: 2025-10-24
**Test**: VS Code launched from WSL with `code` command
**Purpose**: Determine path format used by VS Code when launched natively from WSL

---

## Test Setup

### Workspace
```bash
/tmp/vscode-wsl-test/
├── .devcontainer/
│   └── devcontainer.json
└── README.md
```

### DevContainer Config
```json
{
  "name": "vscode-wsl-test",
  "image": "ubuntu:22.04",
  "workspaceFolder": "/workspace",
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind"
}
```

### Launch Method
```bash
cd /tmp/vscode-wsl-test
code .
```

**Launch behavior:**
1. VS Code opens in WSL mode (bottom-left shows `WSL: Ubuntu`)
2. Popup: "Folder contains a Dev Container configuration file. Reopen folder to develop in a container"
3. Clicked: "Reopen in Container"
4. VS Code builds and starts the devcontainer

---

## Test Results

### Container Created
```
Name: pensive_cori
Status: Up
```

### Container Labels

**Full devcontainer labels:**
```
devcontainer.config_file = /tmp/vscode-wsl-test/.devcontainer/devcontainer.json
devcontainer.local_folder = \\wsl.localhost\Ubuntu\tmp\vscode-wsl-test
devcontainer.metadata = []
```

### Path Format Analysis

**devcontainer.local_folder value:**
```
\\wsl.localhost\Ubuntu\tmp\vscode-wsl-test
```

**Path format:** Windows UNC path for WSL access

**Components:**
- `\\wsl.localhost\` - Windows UNC prefix for WSL access
- `Ubuntu` - WSL distribution name
- `\tmp\vscode-wsl-test` - Unix path within WSL (with Windows backslashes)

---

## Key Findings

### 1. VS Code Uses UNC Paths for WSL

When launched from WSL with `code` command, VS Code uses **Windows UNC paths** (`\\wsl.localhost\...`), NOT:
- ❌ WSL paths (`/mnt/c/...`)
- ❌ Unix paths (`/tmp/...`)
- ❌ Windows drive paths (`C:\...`)

### 2. No Path Corruption

✅ **No corruption observed**
- No `/mnt/wsl/docker-desktop-bind-mounts/...` paths
- Labels are clean and consistent

### 3. Cross-Platform Accessibility

The `\\wsl.localhost\Ubuntu\...` format:
- ✅ Works from Windows (File Explorer, VS Code on Windows)
- ✅ Works from WSL (VS Code in WSL mode)
- ✅ VS Code can discover and reattach to these containers

### 4. Config File Path Format

Interesting: `devcontainer.config_file` uses **Unix path format**:
```
/tmp/vscode-wsl-test/.devcontainer/devcontainer.json
```

But `devcontainer.local_folder` uses **UNC format**:
```
\\wsl.localhost\Ubuntu\tmp\vscode-wsl-test
```

This suggests VS Code normalizes workspace paths to UNC format for container discovery, but keeps config paths as-is.

---

## Comparison with Previous Research

### From LABEL-DISCOVERY-FINDINGS.md

**Previous finding (VS Code from Windows):**
```
devcontainer.local_folder = c:\Projects\BitBot\test-windows-launch
```

**This test (VS Code from WSL):**
```
devcontainer.local_folder = \\wsl.localhost\Ubuntu\tmp\vscode-wsl-test
```

### Path Format Summary

| VS Code Launch Context | devcontainer.local_folder Format | Example |
|------------------------|----------------------------------|---------|
| Windows (native) | Windows drive path | `c:\Projects\BitBot\...` |
| WSL (`code` command) | Windows UNC path | `\\wsl.localhost\Ubuntu\tmp\...` |
| WSL (`code.exe` command) | **Unknown** - needs testing | TBD |

---

## Implications for BitBot

### 1. The `windows` Modifier May Be Unnecessary

Since VS Code's `code` command from WSL already uses proper UNC paths:
- No path corruption risk
- VS Code can discover containers correctly
- The `windows` modifier (forcing `code.exe`) may not be needed

### 2. devcontainer CLI Behavior

**Still unknown:**
- Does `devcontainer` (native) also use UNC paths when called from WSL?
- Or does it use `/mnt/c/...` or `/tmp/...` paths?

**Next test needed:**
```bash
# What labels does devcontainer CLI create?
devcontainer up --workspace-folder /tmp/vscode-wsl-test
docker inspect <container> --format '{{index .Config.Labels "devcontainer.local_folder"}}'
```

### 3. devcontainer.cmd Risk Still Valid

The corruption research showed that `devcontainer.cmd` can cause issues. Our current approach (always use native `devcontainer`) appears correct based on VS Code's successful use of UNC paths.

---

## Questions for Further Testing

### Test 2: devcontainer CLI from WSL
- [ ] What path format does `devcontainer` use when called from WSL?
- [ ] Does it match VS Code's UNC format?
- [ ] Or does it use `/mnt/c/...` or `/tmp/...`?

### Test 3: code.exe from WSL
- [ ] What path format does `code.exe` use when called from WSL?
- [ ] Is it different from `code`?
- [ ] Does it create Windows drive paths (`C:\...`) or UNC paths?

### Test 4: BitBot Integration
- [ ] Does BitBot's `devcontainer up` create compatible labels?
- [ ] Can VS Code discover containers created by BitBot?
- [ ] Can BitBot discover containers created by VS Code?

---

## Conclusions

1. **VS Code WSL mode works correctly** - Uses proper UNC paths
2. **No corruption with native `code` command** - Safe to use
3. **UNC paths are the key** - `\\wsl.localhost\` format works across contexts
4. **devcontainer CLI behavior still unknown** - Needs separate test
5. **BitBot's current approach is likely correct** - Using native `devcontainer` (not `.cmd`)

---

## Next Steps

1. Test `devcontainer` CLI directly to see its label format
2. Compare with VS Code's format
3. Verify BitBot can discover VS Code containers
4. Verify VS Code can discover BitBot containers
5. Document final path format strategy

---

## Related Documents

- `LABEL-DISCOVERY-FINDINGS.md` - Original label format research
- `DOCKER-DESKTOP-CORRUPTION-ANALYSIS.md` - Path corruption investigation
- `/mnt/c/Projects/BitBot/tests/RUN-THIS-TEST.md` - Test procedure
- `SPEC-05` section 2.1 - Windows Path Corruption Root Cause
- `SPEC-06` - VS Code DevContainer Integration
