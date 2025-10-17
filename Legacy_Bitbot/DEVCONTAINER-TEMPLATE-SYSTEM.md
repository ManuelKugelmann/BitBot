# DevContainer Template System

## Overview

BitBot now uses a centralized devcontainer.json template system that provides consistent behavior between VS Code DevContainer mode and Direct Docker mode, with enhanced workspace tracking.

## Architecture Changes

### 1. **Centralized Template**
- **Location**: `devcontainer-base/devcontainer.json` 
- **Purpose**: Single source of truth for devcontainer configuration
- **Benefits**: All devcontainer variants use the same base configuration

### 2. **BitBot Workspace Tracking**
- **`.bitbot/` folder**: Tracks BitBot workspace state
- **`.devcontainer/` folder**: Indicates VS Code mode preference
- **Mode Detection**: Presence of folders determines launch behavior

### 3. **Launch Mode Logic**

```
First Run (.bitbot doesn't exist):
├── Show launch mode menu
├── Choose VS Code → Create .devcontainer/ + .bitbot/
└── Choose Direct → Create .bitbot/ only

Subsequent Runs (.bitbot exists):
├── Has .devcontainer/ → Launch VS Code mode
└── No .devcontainer/ → Launch Direct Docker mode
```

## File Structure

```
devcontainer-base/
├── devcontainer.json          # Template with variables
├── docker-compose.yml         # Container configuration  
└── bitbot/                    # Container scripts

workspace/
├── .bitbot/                   # BitBot tracking (always created)
│   ├── workspace-hash         # Unique workspace identifier
│   ├── created               # Creation timestamp
│   └── launch-mode           # Saved preference
└── .devcontainer/            # VS Code mode (optional)
    └── devcontainer.json     # Customized from template
```

## Template System

### Template Variables
The `devcontainer-base/devcontainer.json` template contains:

- `${WORKSPACE_HASH}` - Replaced with unique workspace hash
- Relative paths that work from any workspace location
- Extensible mounts, features, and customizations

### Template Processing
When creating a workspace devcontainer:

1. **Copy template** from `devcontainer-base/devcontainer.json`
2. **Replace variables** with actual values:
   - `${WORKSPACE_HASH}` → unique hash (e.g., `abc12345`)
3. **Update paths** to point to BitBot installation
4. **Create .bitbot folder** with tracking metadata

### Example Transformation

**Template** (`devcontainer-base/devcontainer.json`):
```json
{
  "dockerComposeFile": "./docker-compose.yml",
  "containerEnv": {
    "WORKSPACE_HASH": "${WORKSPACE_HASH}"
  }
}
```

**Generated** (`.devcontainer/devcontainer.json`):
```json
{
  "dockerComposeFile": "/path/to/BitBot/devcontainer-base/docker-compose.yml",
  "containerEnv": {
    "WORKSPACE_HASH": "abc12345"
  }
}
```

## Custom Parts Injection

### DevContainer Mode Enhancements
The template includes BitBot-specific customizations:

- **Terminal profiles** with BitBot integration
- **VS Code extensions** for development
- **Post-create commands** for MCP service setup
- **Workspace mounts** for .bitbot folder access
- **Feature additions** for enhanced tools

### Container Script Integration
When running in devcontainer mode:

1. **postCreateCommand** runs workspace MCP setup
2. **BitBot scripts** available in container environment
3. **Workspace state** synchronized via .bitbot folder
4. **Custom terminal profiles** for easy BitBot access

## Benefits

### 🎯 **Consistency**
- Same container environment regardless of launch mode
- Identical tooling and service availability
- Consistent workspace mounting and paths

### 🔧 **Maintainability** 
- Single template to update for all workspaces
- Centralized configuration management
- Easy to add new features and customizations

### 🚀 **User Experience**
- Automatic mode detection based on folder presence
- Seamless switching between VS Code and Direct modes
- Persistent workspace state and preferences

### 🧪 **Testing**
- Template validation in test suite
- BitBot folder creation verification
- JSON syntax and variable replacement testing

## Migration Path

### Existing Workspaces
Existing BitBot workspaces will:
1. **Automatically migrate** on next BitBot run
2. **Preserve existing .devcontainer** if present
3. **Create .bitbot folder** for tracking
4. **Continue working** without interruption

### New Workspaces
New workspaces will:
1. **Use template system** from first run
2. **Create appropriate folders** based on mode choice
3. **Get latest customizations** automatically
4. **Track state** via .bitbot folder

This system provides a robust foundation for BitBot workspace management while maintaining backward compatibility and enabling future enhancements.