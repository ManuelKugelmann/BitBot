# BitBot Workspace Template

AI-powered development workspace with shared configuration folders.

## What's Included

- **Base:** Ubuntu 22.04 LTS
- **Features:**
  - Node.js LTS
  - Git
  - Claude Code (official feature)
  - Optional: Claude Flow, Open Code
- **Build Tools:** gcc, make, curl, wget
- **Shared Configs:** Persistent AI tool configurations

## Hybrid Installation Approach

This template uses a **hybrid approach** for installing AI tools:

### Official Features (Preferred)
- **Claude Code:** `ghcr.io/anthropics/devcontainer-features/claude-code:1`
- **Claude Flow:** `ghcr.io/anthropics/devcontainer-features/claude-flow:0.3` (experimental)
- **Open Code:** `ghcr.io/opencode-dev/features/open-code:0.1` (prototype)

### Fallback Scripts
- `scripts/install-fallbacks.sh` - Installs tools when features are unavailable
- `scripts/post-create.sh` - Post-creation setup and verification

## Shared Home Folders

This template includes **BitBot-specific shared home folders** for AI tool configurations:

```
.devcontainer/home/
  claude/          → mounted to /home/bitbot/.claude
  claude-flow/     → mounted to /home/bitbot/.claude-flow
  opencode/        → mounted to /home/bitbot/.opencode
```

### Why Shared Folders?

These folders are:
- ✅ **Persistent** - Survive container rebuilds
- ✅ **Shared** - Common configs across all BitBot workspace containers
- ✅ **BitBot-scoped** - Specific to your BitBot project, not system-wide
- ✅ **Version-controlled** - Part of your project repository

### What Goes in Shared Folders?

| Folder       | Contains                          | Example Files           |
|--------------|-----------------------------------|-------------------------|
| claude/      | Claude Code instructions, tools   | CLAUDE.md, tools/*.sh   |
| claude-flow/ | Workflow definitions, automation  | workflows/*.yaml        |
| opencode/    | Code templates, snippets          | templates/*.tmpl        |

## Enabling Optional Features

### Enable Claude Flow

Uncomment in `devcontainer.json`:
```json
"ghcr.io/devcontainers/features/docker-outside-of-docker:1": {},
"ghcr.io/anthropics/devcontainer-features/claude-flow:0.3": {
  "version": "latest"
}
```

### Enable Open Code

Uncomment in `devcontainer.json`:
```json
"ghcr.io/opencode-dev/features/open-code:0.1": {
  "version": "latest"
}
```

## Mount Options

### Default Mounts
- Workspace: `${localWorkspaceFolder}` → `/workspace`
- Shared home folders (see above)

### Optional Mounts (uncomment to enable)
```json
// SSH keys
"source=${localEnv:HOME}${localEnv:USERPROFILE}/.ssh,target=/root/.ssh,type=bind,readonly"

// Git config
"source=${localEnv:HOME}${localEnv:USERPROFILE}/.gitconfig,target=/root/.gitconfig,type=bind,readonly"

// Docker socket (for Docker-in-Docker)
"source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
```

## Usage

### With BitBot
```bash
# BitBot will use this template automatically for workspace mode
bitbot work
```

### Manual Usage
```bash
# Copy to your project
cp -r templates/workspace/.devcontainer /path/to/your/project/

# Open in VS Code
code /path/to/your/project
# VS Code will prompt to reopen in container
```

## Troubleshooting

### Feature Not Installing
If a feature fails to install, the fallback script will attempt npm installation.

### Shared Folders Not Mounting
Ensure `.devcontainer/home/` exists in your workspace root.

### Permission Issues
Run in container:
```bash
chmod 755 /home/bitbot/.claude
chmod 755 /home/bitbot/.claude-flow
chmod 755 /home/bitbot/.opencode
```

## See Also

- [DevContainer Features Research](../../sparc/0-research/DEVCONTAINER_FEATURES_RESEARCH.md)
- [Anthropic DevContainer Features](https://github.com/anthropics/devcontainer-features)
- [DevContainer Specification](https://containers.dev/)
