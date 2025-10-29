# PowerShell and CMD from WSL Reference

Quick reference for calling Windows commands from WSL.

## PowerShell Commands

**Single command:**
```bash
powershell.exe -Command "command"
```

**Run script:**
```bash
powershell.exe -File "script.ps1"
```

**Faster (no profile):**
```bash
powershell.exe -NoProfile -Command "..."
```

## CMD Files (.cmd/.bat)

**ALWAYS use cmd.exe:**
```bash
cmd.exe /c "command.cmd args"
```

**For devcontainer:**
```bash
cmd.exe /c "cd /d C:\Path && devcontainer.cmd build --workspace-folder ."
```

**DO NOT** call .cmd files via PowerShell - use cmd.exe wrapper

## Path Handling

**WSL paths:**
- Work directly: `/mnt/c/Projects/...`
- Convert to Windows: Use `wslpath -w <path>`

**Windows paths:**
- Format: `C:\Projects\...`
- Escape backslashes in quotes
- Convert from Windows: Use `wslpath -u <path>`

## See Also

- `core/util/helpers.sh` - `convert_wsl_to_windows_path()`, `convert_windows_to_wsl_path()`
- `core/util/devcontainer.sh` - Path conversion for VS Code launches
