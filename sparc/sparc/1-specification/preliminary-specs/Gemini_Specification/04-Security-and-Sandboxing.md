# 04: Security and Sandboxing

This document outlines the security model for the BitBot development environment. The model is designed to be compatible with the `@devcontainers/cli` lifecycle and focuses on protecting the workspace from accidental or malicious operations.

## 1. Core Principle: Workspace and Git Protection

The security model has two primary pillars:

1.  **Git Safety:** Preventing destructive Git operations through command interception.
2.  **Filesystem Isolation:** Selectively mounting configuration and state directories to limit the work container's access.

This moves away from a complex in-container user-switching model in favor of a simpler approach focused on concrete, high-risk operations.

## 2. Filesystem Protection (`.bitbot` folder)

To protect sensitive configuration while allowing the work container access to necessary state, the `.bitbot` folder is structured, and only specific sub-directories are mounted into the work container.

*   **Folder Structure:**
    ```
    .bitbot/
    ├── setup/      # (Protected) Contains the custom compose file for the setup container.
    ├── state/      # (Public) Contains benign state info the work container may need.
    └── logs/       # (Public) Contains logs.
    ```
*   **Mounting Strategy:** The `devcontainer.json` for the work container will **only** mount the public folders:
    ```json
    "mounts": [
        "source=${localWorkspaceFolder}/.bitbot/state,target=/workspace/.bitbot/state,type=bind",
        "source=${localWorkspaceFolder}/.bitbot/logs,target=/workspace/.bitbot/logs,type=bind"
    ]
    ```
    The sensitive `setup` directory, which contains the configuration for the privileged setup environment, is never mounted into the standard work container.

## 3. Git Protection Strategy

To prevent accidental data loss, BitBot implements a Git protection layer. This is the primary safety net for the AI agent and the user.

*   **Automatic Git Initialization:** If a workspace is not already a Git repository, `bitbot` will initialize one.
*   **Destructive Command Prevention:** A mechanism will be put in place to block potentially destructive Git commands (e.g., `git push --force`). This will likely be implemented via a Git hook or a wrapper script that intercepts git commands, providing a crucial safety net.
