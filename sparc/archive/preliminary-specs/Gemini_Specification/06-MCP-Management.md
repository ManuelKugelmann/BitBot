# Feature 06: MCP (Model Context Protocol) Management

## 1. Description

This feature defines how BitBot discovers, configures, and launches MCP services. The system must support both "global" services (shared across all projects) and "workspace-local" services (specific to the current project).

*Reference: `info.txt` (lines 38-40)*

## 2. Chosen Approach

The selected approach is **"Unified Docker Compose Management with Autostart"**. 

This method uses `docker-compose` as the single, consistent mechanism for defining services, which provides maximum flexibility for promoting or demoting services between the global and workspace scopes. It is enhanced with automatic startup mechanisms to improve user experience.

### 2.1. Service Definition

*   **Unified Format:** Both global and workspace-local MCPs will be defined as services within `docker-compose.yml` files. This consistency makes it trivial to move a service from one scope to another by copying its definition.
*   **Global Services:** Defined in a `docker-compose.yml` file located in the main BitBot installation directory (e.g., `~/.bitbot/mcp/docker-compose.yml`).
*   **Local Services:** Defined in the project's `.devcontainer/docker-compose.yml` file. The `devcontainer` CLI will manage the lifecycle of these services as part of the workspace environment.

### 2.2. Automatic Startup of Global MCPs

To eliminate the need for manual service management, the main `bitbot` command will ensure the global MCPs are running:

1.  On every execution, `bitbot` will perform a quick check on the status of the global MCP containers.
2.  If the containers are not running, it will automatically start them in the background (equivalent to `docker-compose up -d`) before executing the user's primary command.

This ensures that global services are always available when needed without requiring a separate `bitbot mcp start` command.

### 2.3. System-Level Autostart (on First Install)

To further improve the "always-on" nature of the global services, the BitBot installer will include an option for system-level autostart.

*   **Prompt:** During the initial installation of BitBot, the installer script will ask the user: `Would you like the global BitBot services to start automatically when your computer boots? [y/N]`.
*   **Action:** If the user agrees, the installer will attempt to register a system service (e.g., using `systemd` on Linux, `launchd` on macOS, or Task Scheduler on Windows) that runs the `docker-compose up -d` command for the global MCPs on system startup.
