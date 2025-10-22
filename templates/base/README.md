# BitBot Basic Template

Minimal Ubuntu-based development environment with essential tools.

## What's Included

- **Base:** Ubuntu 22.04 LTS
- **Tools:**
  - Git
  - Curl
  - Node.js LTS
  - Claude Code CLI
- **User:** root (development mode)

## Usage

This template is automatically copied to your workspace when you run:

```bash
bitbot init
```

After initialization, your workspace will have a `.devcontainer/` folder with this configuration.

## Customization

You can customize this template by editing the files in your workspace's `.devcontainer/` directory:

- `devcontainer.json` - Container configuration, VS Code settings, extensions
- `Dockerfile` - Base image and installed packages

## Adding More Tools

Edit `Dockerfile` to add additional packages:

```dockerfile
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
```

## VS Code Extensions

Add extensions in `devcontainer.json`:

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "dbaeumer.vscode-eslint"
      ]
    }
  }
}
```

## See Also

- [BitBot Documentation](https://docs.bitbot.dev/)
- [DevContainer Specification](https://containers.dev/)
