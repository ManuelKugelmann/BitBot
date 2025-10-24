# Automatic Docker WSL Integration Setup

## Overview

BitBot now automatically detects when Docker WSL integration is not enabled for BitBot-Alpine and offers to enable it.

---

## User Experience

### When Integration is Missing

```bash
$ bitbot work

BitBot Work Mode
================

Building devcontainer...
  Workspace: /mnt/c/Projects/BitBot/test-windows-launch
  Platform:  wsl
  CLI:       standalone (devcontainer.cmd)

========================================================
  Docker WSL Integration Setup Required
========================================================

BitBot-Alpine cannot access Docker.

This is a one-time setup that will:
  - Stop Docker Desktop
  - Enable BitBot-Alpine in Docker settings
  - Restart Docker Desktop (~30 seconds)

Enable Docker integration for BitBot-Alpine? [Y/n]
```

### If User Accepts (Y or Enter)

```bash
Enable Docker integration for BitBot-Alpine? [Y/n] y

=== Enable Docker Desktop WSL Integration ===

OK: Docker Desktop found
OK: BitBot-Alpine found
OK: Settings file found
OK: Backup created
OK: BitBot-Alpine enabled

Stopping Docker Desktop...
OK: Docker Desktop stopped

Saving settings...
OK: Settings saved

Starting Docker Desktop...
(This may take 20-30 seconds)
OK: Docker Desktop started

Verifying integration...
OK: BitBot-Alpine can access Docker!

CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

=== Done ===

✓ Docker integration setup complete!

[Building devcontainer continues...]
```

### If User Declines (n)

```bash
Enable Docker integration for BitBot-Alpine? [Y/n] n

Setup cancelled.

Manual setup:
  1. Open Docker Desktop
  2. Settings → Resources → WSL Integration
  3. Enable 'BitBot-Alpine'
  4. Apply & Restart

Then run: bitbot work
```

---

## Implementation Details

### Function: `check_docker_wsl_integration()`

**Location**: `scripts/bitbot` (line 272)

**Called by**: `build_devcontainer()` after Docker is verified running

**Logic**:
1. Only runs on WSL with BitBot-Alpine
2. Tests if `docker ps` works
3. If fails with "Cannot connect to Docker daemon" → WSL integration issue
4. Prompts user to enable integration
5. Runs `enable-docker-wsl-integration-simple.ps1` if user agrees
6. Exits with manual instructions if user declines

**Key Code**:
```bash
check_docker_wsl_integration() {
    local platform=$(detect_platform)

    # Only check on WSL with BitBot-Alpine
    if [[ "$platform" != "wsl" ]] || [[ "$WSL_DISTRO_NAME" != "BitBot-Alpine" ]]; then
        return 0
    fi

    # Try docker command
    if docker ps &>/dev/null 2>&1; then
        return 0  # Docker works, all good
    fi

    local error=$(docker ps 2>&1)

    # Check if it's a WSL integration issue
    if echo "$error" | grep -q "Cannot connect to the Docker daemon"; then
        # Show prompt and handle user response
        ...
    fi
}
```

---

## When Check Runs

**Timing**: After Docker Desktop is verified running, before building container

**Flow**:
```
bitbot work
  ↓
build_devcontainer()
  ↓
Check if Docker running → start_docker() if needed
  ↓
check_docker_wsl_integration()  ← NEW CHECK HERE
  ↓
Build devcontainer...
```

---

## Skipped Scenarios

The check is **skipped** when:
- Not running on WSL (native Linux/macOS)
- Not running in BitBot-Alpine (e.g., using default WSL)
- Docker already accessible (integration already enabled)

---

## Dependencies

**Required file**: `tests/enable-docker-wsl-integration-simple.ps1`

The script expects the setup script to be at:
```
<bitbot-dir>/tests/enable-docker-wsl-integration-simple.ps1
```

Relative to the `bitbot` script location:
```bash
scripts/bitbot → ../tests/enable-docker-wsl-integration-simple.ps1
```

---

## Error Handling

### Setup Script Not Found

```bash
Error: Setup script not found at: /path/to/enable-docker-wsl-integration-simple.ps1

Manual setup:
  1. Open Docker Desktop
  2. Settings → Resources → WSL Integration
  3. Enable 'BitBot-Alpine'
  4. Apply & Restart
```

### Setup Script Fails

```bash
✗ Setup failed. Try manual setup.

Manual setup:
  1. Open Docker Desktop
  2. Settings → Resources → WSL Integration
  3. Enable 'BitBot-Alpine'
  4. Apply & Restart
```

---

## Testing

### Simulate Missing Integration

To test the auto-setup feature:

1. **Disable integration** in Docker Desktop:
   - Settings → Resources → WSL Integration
   - Uncheck BitBot-Alpine
   - Apply & Restart

2. **Terminate BitBot-Alpine** to force fresh connection:
   ```powershell
   wsl --terminate BitBot-Alpine
   ```

3. **Run BitBot**:
   ```bash
   bitbot work
   ```

4. **Verify prompt appears** and test both accept/decline flows

### Verify Integration Already Enabled

```bash
$ bitbot work

# Should NOT show prompt, goes straight to building:
Building devcontainer...
  Workspace: /mnt/c/Projects/BitBot/test-windows-launch
  ...
```

---

## Future Enhancements (TODO)

### Option to Use Default WSL

**Status**: On todo list - requires config system

Allow users to choose between:
1. Enable BitBot-Alpine integration (recommended)
2. Use default WSL distribution instead (quick testing)

**Requires**:
- Configuration system to persist user choice
- Logic to re-execute bitbot in different WSL distro
- Warning about loss of isolation

**Design**:
```bash
Choose an option:
  1) Enable Docker integration for BitBot-Alpine (recommended)
  2) Use your default WSL distribution instead
  3) Manual setup / Exit

Enter choice [1-3]:
```

---

## Benefits

✅ **Better UX**: Clear prompt instead of confusing timeout
✅ **One-time setup**: User only sees this once
✅ **Automatic**: No manual Docker Desktop configuration needed
✅ **Safe**: Always asks before modifying settings
✅ **Fallback**: Provides manual instructions if automation fails

---

**Status**: ✅ Implemented and tested
**Date**: 2025-10-20
**Version**: BitBot 0.1.0-test
