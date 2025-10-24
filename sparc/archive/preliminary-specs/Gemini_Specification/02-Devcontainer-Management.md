# 02: Devcontainer Lifecycle Management

## 1. Description

This feature covers how BitBot will handle the creation, startup, and shutdown of the development container. The goal is to provide a seamless lifecycle for the primary **work container** and a powerful, separate environment for **setup and recovery**.

## 2. Core Strategy: Hybrid Model

BitBot uses a hybrid strategy for container management to combine standardization with power-user features.

### 2.1. Work Container: `@devcontainers/cli`

The primary **work container** is managed by the official **`@devcontainers/cli`**. This ensures that BitBot is always compliant with the latest dev container specification and leverages the robust, community-supported tool for the heavy lifting.

*   `bitbot up`: Will wrap `devcontainer up` to build and start the work container.
*   `bitbot down`: Will wrap `devcontainer down`.
*   `bitbot shell`: Will wrap `devcontainer exec` to open a shell.
*   `bitbot run <command>`: Will wrap `devcontainer exec -- <command>`.

### 2.2. Setup Container: Custom Docker Compose

For advanced setup, recovery, and debugging of devcontainer configurations, BitBot provides a **Per-Workspace Setup Environment** managed by a custom Docker Compose file. This provides a level of control and a meta-workflow not possible with the standard CLI alone.

## 3. Setup and Recovery Environment

This model provides a powerful, iterative workflow for authoring devcontainer configurations and a failsafe for fixing broken ones.

### 3.1. Architecture

*   **Location:** A `.bitbot/setup/` directory is created within each workspace.
*   **Configuration:** This directory houses a dedicated `docker-compose.yml` file designed to launch a **setup container**.
*   **Generic Image:** The setup container uses a generic, globally-cached image (e.g., `bitbot/setup-tools:latest`) that comes pre-installed with Docker, Docker Compose, text editors, and other necessary tools.
*   **Mounts:** The setup container mounts the entire workspace root directory into a `/target` sub-directory inside itself.

### 3.2. Workflow: Iterative Debugging

The `bitbot setup` command launches the setup container, enabling a powerful CLI-based workflow:

1.  **Launch Setup Session:** `bitbot setup` starts the container and opens a shell inside it.
2.  **Edit Configuration:** The user can edit the work container's configuration at `/target/.devcontainer/`.
3.  **Test Launch Work Container:** From the setup shell, a command like `bitbot-test-launch` uses the setup container's Docker client to launch the **work container** as a sibling.
4.  **Attach and Verify:** The user can then attach VS Code to the running work container from the host or use `bitbot-test-exec` to get a shell and verify the changes.
5.  **Iterate:** The user can bring the work container down (`bitbot-test-down`), make more changes, and repeat the cycle, all from within the single, stable setup session.
