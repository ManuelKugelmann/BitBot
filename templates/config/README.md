# BitBot Config Mode DevContainer

Configuration mode environment for editing `.devcontainer/` files and infrastructure.

## Purpose

Config mode provides a separate container environment where:
- `.devcontainer/` files are **read-write** (not read-only like work mode)
- AI agent is tuned for infrastructure editing tasks
- No Docker access (prevents accidental container manipulation)
- Focus on editing configuration files safely

## What's Different from Work Mode

| Feature                  | Work Mode                    | Config Mode          |
|-------------------------|------------------------------|---------------------|
| .devcontainer/ access   | Read-only                    | Read-write          |
| Docker available        | Optional (template-dependent)| No                  |
| AI agent focus          | Code development             | Infrastructure      |
| Primary use case        | Writing code                 | Editing config      |

## What's Included

- **Base:** Ubuntu 22.04 LTS
- **Tools:**
  - Git
  - Curl
  - Node.js LTS
  - Claude Code CLI
- **Extensions:**
  - YAML extension
  - JSON extension

## Usage

Launch config mode:

```bash
bitbot config
```

This opens the config mode container where you can edit:
- `.devcontainer/devcontainer.json`
- `.devcontainer/Dockerfile`
- Container configuration files
- Install additional tools

## When to Use Config Mode

Use config mode when you need to:
- Add new VS Code extensions
- Install system packages in Dockerfile
- Change container configuration
- Update devcontainer settings

Use work mode (default) for:
- Regular development work
- Writing code
- Running tests
- Using git

## Security Note

Config mode provides read-write access to infrastructure files. Use work mode for day-to-day development to maintain the security boundary between your code and container configuration.

## See Also

- [BitBot Documentation](https://docs.bitbot.dev/)
- [DevContainer Specification](https://containers.dev/)
