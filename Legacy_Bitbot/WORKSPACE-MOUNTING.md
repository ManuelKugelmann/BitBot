# Workspace Mounting in BitBot

## Overview

BitBot now mirrors VS Code devcontainer workspace mounting behavior exactly, ensuring consistency between VS Code DevContainer mode and Direct Docker mode.

## How VS Code DevContainers Work

1. **VS Code detects workspace root** - The folder opened in VS Code
2. **Sets environment variable** - `WORKSPACE_FOLDER` = absolute path to workspace  
3. **Mounts workspace** - `$WORKSPACE_FOLDER` mounted as `/workspace` in container
4. **Sets working directory** - Container starts in `/workspace`
5. **devcontainer.json config** - `"workspaceFolder": "/workspace"` specifies mount point

## BitBot Implementation

### Standalone Docker Launch
When BitBot runs in Direct Docker mode, it:

1. **Sets `WORKSPACE_FOLDER`** - Same variable VS Code uses
   ```bash
   export WORKSPACE_FOLDER="$CURRENT_DIR"  # Current directory = workspace root
   ```

2. **Uses docker-compose** - Same compose file as VS Code
   ```yaml
   volumes:
     - type: bind
       source: "${WORKSPACE_FOLDER:-.}"  # Mounts workspace folder
       target: /workspace                 # At /workspace mount point
   ```

3. **Sets working directory** - Container starts in `/workspace`
   ```yaml
   working_dir: /workspace
   ```

4. **tmux sessions** - All sessions start in `/workspace`
   ```bash
   tmux new-session -d -s "$session_name" -n "terminal" -c /workspace
   ```

## Key Files Updated

### `global/launch-docker.sh`
- ✅ Fixed: Sets `WORKSPACE_FOLDER` instead of `WORKSPACE_PATH`
- ✅ Added: Workspace mount logging for debugging
- ✅ Added: Timezone environment variable

### `global/bitbot-core.sh`  
- ✅ Fixed: Updated script paths to use `global/` directory
- ✅ Fixed: Correct references to `launch-docker.sh` and `setup-devcontainer.sh`

### `devcontainer-base/docker-compose.yml`
- ✅ Uses: `${WORKSPACE_FOLDER:-.}` for workspace mounting
- ✅ Sets: `working_dir: /workspace` 
- ✅ Fixed: Configuration directory mounting

### `devcontainer-base/bitbot/bitbot` (Container Script)
- ✅ Creates: All tmux sessions with `-c /workspace`
- ✅ Starts: All windows in `/workspace` directory

## Result

**Perfect consistency between modes:**

| Aspect | VS Code DevContainer | BitBot Direct Docker |
|--------|---------------------|---------------------|
| Mount source | `$WORKSPACE_FOLDER` | `$WORKSPACE_FOLDER` |
| Mount target | `/workspace` | `/workspace` |
| Working directory | `/workspace` | `/workspace` |
| tmux sessions | `/workspace` | `/workspace` |
| Environment setup | VS Code managed | BitBot managed |

## Testing

The workspace mounting is validated by:

1. **Test suite** - `tests/test-bitbot.sh` includes workspace mounting tests
2. **Environment validation** - Verifies `WORKSPACE_FOLDER` is set correctly
3. **Docker compose validation** - Confirms workspace path in generated config
4. **Mount logging** - Shows workspace mount mapping during launch

## User Experience

Users now get **identical workspace behavior** regardless of launch mode:

- Files appear in `/workspace` inside container
- All terminals start in `/workspace` 
- Relative paths work the same way
- File changes sync between host and container
- Working directory is consistent across all tools

This ensures that development workflows, scripts, and tool configurations work identically whether launched via VS Code or BitBot's direct Docker mode.