# Testing BitBot Launcher Scripts

Quick guide for testing the newly created BitBot launcher.

## Files Created

✅ **bitbot.ps1** - PowerShell entry point (Windows)
✅ **bitbot.bat** - Batch entry point (Windows cmd.exe)
✅ **bitbot** - Main bash launcher script (WSL/Linux/macOS)
✅ **test-bitbot-launcher.ps1** - Automated test script
✅ **README.md** - Complete documentation

## Quick Tests

### 1. Test Version Command (WSL)

```bash
cd /mnt/c/Projects/BitBot/test-windows-launch/tests
./bitbot version
```

**Expected output:**
```
BitBot version 0.1.0-test

Platform: wsl

Available tools:
  ✓ VS Code
  ✓ DevContainer CLI (standalone)
  ✓ Docker
```

### 2. Test Help Command (WSL)

```bash
./bitbot help
```

**Expected:** Full help text with commands and options

### 3. Test PowerShell Entry Point (Windows PowerShell)

```powershell
cd C:\Projects\BitBot\test-windows-launch\tests
.\bitbot.ps1 version
```

**Expected:** Same version output as WSL test

### 4. Test Batch Entry Point (Windows cmd.exe)

```batch
cd C:\Projects\BitBot\test-windows-launch\tests
bitbot.bat version
```

**Expected:** Same version output

### 5. Run Automated Tests (Windows PowerShell)

```powershell
cd C:\Projects\BitBot\test-windows-launch\tests
.\test-bitbot-launcher.ps1
```

**Expected:**
```
BitBot Launcher Test
====================

[1/7] Checking WSL availability...
    ✓ WSL found
[2/7] Checking bash launcher...
    ✓ bitbot script found
[3/7] Converting path to WSL format...
    ✓ WSL path: /mnt/c/Projects/BitBot/test-windows-launch/tests/bitbot
[4/7] Checking bash script syntax...
    ✓ Bash syntax OK
[5/7] Testing 'bitbot version' command...
    ✓ Version command works
[6/7] Testing 'bitbot help' command...
    ✓ Help command works
[7/7] Testing PowerShell entry point...
    ✓ PowerShell entry point works

✓ All tests passed!
```

## Test Workflow (Without Building Containers)

These tests verify the launcher works without actually building containers:

### Test DevContainer CLI Detection

```bash
./bitbot version
```

Checks:
- ✅ Platform detection (wsl/macos/linux)
- ✅ VS Code installation
- ✅ DevContainer CLI availability
- ✅ Docker availability

### Test Help System

```bash
./bitbot help
```

Shows:
- Commands: work, setup, version, help
- Options: vscode
- Examples
- Entry points

## Test Full Workflow (Requires .devcontainer)

⚠️ **Prerequisites:**
- Docker running
- `.devcontainer/devcontainer.json` in workspace
- VS Code with Dev Containers extension OR standalone devcontainer CLI

### Test Terminal Mode

```bash
# From project root with .devcontainer/
cd /mnt/c/Projects/BitBot

# Run BitBot
./test-windows-launch/scripts/bitbot work
```

**Expected flow:**
1. Detects platform and CLI
2. Builds devcontainer using `devcontainer up`
3. Enters container terminal
4. Opens bash at `/workspace`

**What to check:**
- Container builds successfully
- Terminal is inside container (check `hostname`)
- Working directory is `/workspace`
- Can run commands (e.g., `ls`, `git status`)

### Test VS Code Mode

```powershell
# From Windows PowerShell at project root
cd C:\Projects\BitBot
.\test-windows-launch\scripts\bitbot.ps1 work vscode
```

**Expected flow:**
1. Detects VS Code installation
2. Generates hex-encoded URI
3. Launches VS Code with URI
4. VS Code opens directly in devcontainer (no popup!)

**What to check:**
- VS Code launches
- No "Reopen in Container" popup appears
- VS Code opens directly inside devcontainer
- Bottom-left shows "Dev Container: ..." status
- Terminal inside VS Code is at `/workspace`

## Debugging

If you encounter issues, use the debug version:

```powershell
..\scripts\bitbot-debug.ps1 version
```

This shows:
- ✓ WSL detection
- ✓ Script paths (Windows and WSL)
- ✓ Exact command being executed
- ✓ Exit code

Example output:
```
BitBot Debug Info
=================

Checking WSL...
  ✓ WSL found

Locating bash script...
  Windows path: C:\Projects\BitBot\test-windows-launch\tests\bitbot
  ✓ Script exists

Converting to WSL path...
  WSL path: /mnt/c/Projects/BitBot/test-windows-launch/tests/bitbot

Building command...
  Command: version
  Full WSL command: wsl -- bash /mnt/c/Projects/BitBot/test-windows-launch/tests/bitbot version

Executing...
─────────────────────────────────────────────────
BitBot version 0.1.0-test
...
─────────────────────────────────────────────────
Exit code: 0
```

## Common Issues

### "WSL not found"

**Windows PowerShell:**
```
PS> .\bitbot.ps1 version
wsl : The term 'wsl' is not recognized...
```

**Fix:** Install WSL2
```powershell
wsl --install
```

### "bash: No such file or directory"

```
bash: /mnt/c/Projects/BitBot/test-windows-launch/scripts/bitbot: No such file or directory
```

**Cause:** CRLF line endings in bash script

**Fix:**
```bash
/mnt/c/Projects/BitBot/.claude/tools/fix-line-endings.sh /mnt/c/Projects/BitBot/test-windows-launch/scripts/bitbot
```

Or use the auto-approved tool:
```bash
/mnt/c/Projects/BitBot/.claude/tools/fix-and-check-bash.sh /mnt/c/Projects/BitBot/test-windows-launch/scripts/bitbot
```

### "Permission denied"

```
bash: ../scripts/bitbot: Permission denied
```

**Fix:**
```bash
chmod +x /mnt/c/Projects/BitBot/test-windows-launch/scripts/bitbot
```

### "DevContainer CLI not found"

```
DevContainer CLI not found.
Options:
  1. Install VS Code with Dev Containers extension (recommended)
  2. Install standalone: npm install -g @devcontainers/cli
```

**Fix Option 1** (Recommended):
1. Install VS Code: https://code.visualstudio.com/
2. Install extension: `code --install-extension ms-vscode-remote.remote-containers`

**Fix Option 2**:
```bash
# Requires Node.js
npm install -g @devcontainers/cli
```

### "Docker is not running"

```
Error: Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Fix:** Start Docker Desktop on Windows

### "Container not running" (Terminal Mode)

```
Error: Container not running
The devcontainer should have been started by 'devcontainer up'
```

**Cause:** Container build failed

**Debug:**
```bash
# Check if devcontainer CLI works
devcontainer --version

# Try building manually
devcontainer up --workspace-folder "$(pwd)"

# Check Docker containers
docker ps -a
```

## Next Steps After Testing

1. ✅ Verify all tests pass
2. 📋 Test terminal mode with real workspace
3. 📋 Test VS Code mode with real workspace
4. 📋 Create BitBot-Alpine WSL distribution
5. 📋 Implement session management menu
6. 📋 Add setup mode support

## Questions?

See:
- **Full docs**: `test-windows-launch/tests/README.md`
- **Specs**: `Claude_Specification/05_CROSS_PLATFORM_CLI.md`
- **Architecture**: `test-windows-launch/docs/FINAL-BITBOT-ARCHITECTURE.md`
