# BitBot Planning

This document outlines the plan for the new `bitbot` implementation, based on the analysis of the legacy `bitbot` and the requirements from `info.txt`.

## Key Findings from Legacy BitBot

*   **Polyglot Entry Point:** A clever `bitbot` script works across Windows and Unix-like systems by detecting the environment and executing a core Bash script (`bitbot-core.sh`).
*   **Centralized Core Logic:** All main operations (platform detection, Docker checks, workspace setup, service management) are handled within `bitbot-core.sh`.
*   **Clear First-Run Experience:** The system prompts users to choose between a VS Code-integrated or a terminal-only (Direct Docker) setup on the first run.
*   **Stateful Workspaces:** A `.bitbot` directory tracks workspace-specific information, and the presence of a `.devcontainer` directory signals a user's preference for the VS Code workflow.

## Proposal for the new BitBot (MVP)

The new `bitbot` will be a fresh, more robust implementation that is easier to maintain and extend.

### Proposed MVP Features:

*   **Unified `bitbot` Command:** A single, cross-platform executable.
*   **Devcontainer-Centric:** Fully embrace the `devcontainer.json` standard as the source of truth.
*   **Automatic Setup:**
    *   If `.devcontainer` exists, `bitbot` will use it to start the environment.
    *   If not, `bitbot` will offer to create one from a template.
*   **Seamless Container Interaction:**
    *   `bitbot` will automatically start a stopped container.
    *   If already running, `bitbot` will attach a shell to it.
*   **`tmux` Integration:** For terminal-only workflows, automatically manage and attach to `tmux` sessions inside the container.
*   **MCP Management:** Retain the concept of global and workspace-local MCPs.
*   **Simplified Configuration:** Use a single, clear configuration file within the `.bitbot` directory.
*   **Container Modes:** Implement the "sketch," "work," and "setup" modes for filesystem access control.

### Proposed `bitbot` Commands:

*   `bitbot init`: Initialize a new workspace by creating a `.devcontainer` configuration from a template.
*   `bitbot up`: Start the devcontainer and any associated services.
*   `bitbot down`: Stop the devcontainer and services.
*   `bitbot shell`: Open a shell in the running devcontainer.
*   `bitbot run <command>`: Execute a specific command inside the devcontainer.
*   `bitbot status`: Display the status of the BitBot environment.
*   `bitbot mcp (start|stop|status)`: Manage the global MCP services.

## High-Level Implementation Plan

1.  **Project Scaffolding:** Set up a new project structure with directories for source code (`src`), devcontainer templates (`templates`), and helper scripts (`scripts`).
2.  **Core Logic:** Develop the core application in a modern, cross-platform language like **Go** or **Rust**. This will handle command-line parsing, devcontainer configuration, Docker API interaction, and `tmux` session management.
3.  **`bitbot` Entry Point:** Create a simple, cross-platform wrapper that calls the core executable.
4.  **Devcontainer Templates:** Develop a library of starter templates for common languages and environments (e.g., Generic Linux, Node.js, Python).
5.  **Installation:** Create simple installation scripts for Windows, macOS, and Linux that place the `bitbot` executable in the user's `PATH`.
6.  **Testing:** Build a comprehensive test suite covering all commands and features.
