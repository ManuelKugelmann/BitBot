# BitBot Config Mode DevContainer

Configuration mode environment for editing `.devcontainer/` files and infrastructure.

## Purpose

Config mode provides a separate container environment where:
- `.devcontainer/` files are **read-write** (not read-only like work mode)
- Docker and DevContainer CLI tools are available
- You can test and rebuild containers
- AI agent is tuned for infrastructure tasks

## What's Different from Work Mode

| Feature                  | Work Mode            | Config Mode          |
|-------------------------|---------------------|---------------------|
| .devcontainer/ access   | Read-only           | Read-write          |
| Docker available        | No                  | Yes                 |
| DevContainer CLI        | No                  | Yes                 |
| AI agent focus          | Code development    | Infrastructure      |
| Primary use case        | Writing code        | Configuring env     |

## What's Included

- **Base:** Ubuntu 22.04 LTS
- **Tools:**
  - Git
  - Curl
  - Node.js LTS
  - Claude Code CLI
  - Docker CLI
  - DevContainer CLI
- **Extensions:**
  - Docker extension
  - YAML extension
  - Remote Containers extension

## Usage

Launch config mode:

```bash
bitbot config
```

This opens the config mode container where you can edit:
- `.devcontainer/devcontainer.json`
- `.devcontainer/Dockerfile`
- Test and rebuild containers
- Install additional tools

## When to Use Config Mode

Use config mode when you need to:
- Add new VS Code extensions
- Install system packages in Dockerfile
- Change container configuration
- Test devcontainer changes
- Set up Docker Compose services

Use work mode (default) for:
- Regular development work
- Writing code
- Running tests
- Using git

## Security Note

Config mode has elevated permissions to manage containers. Use work mode for day-to-day development to maintain the security boundary between your code and container configuration.

## See Also

- [BitBot Documentation](https://docs.bitbot.dev/)
- [DevContainer Specification](https://containers.dev/)
