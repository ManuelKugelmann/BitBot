
# Devcontainer Features Research

This document summarizes research on devcontainer features, including specific features for AI agents and related concepts.

## General Overview of Devcontainer Features

Devcontainer features are self-contained, shareable units of installation code and development container configuration. They allow for the easy addition of tools, runtimes, and libraries to a development container. Key aspects of devcontainer features include:

*   **Consistency:** They ensure that all developers on a project have the exact same environment.
*   **Isolation:** They isolate development tools and dependencies from the local machine.
*   **Portability:** The development environment can be easily shared and replicated.
*   **Pre-configuration:** They can be pre-configured with all necessary tools, SDKs, and extensions.
*   **Definition:** They are defined by a `devcontainer-feature.json` file and an `install.sh` script.

## AI Agent Devcontainer Features

### Claude Code

*   **Status:** Official
*   **Publisher:** Anthropic
*   **Feature:** `ghcr.io/anthropics/devcontainer-features/claude-code:1`
*   **Description:** This feature installs the Claude Code CLI.

### Claude-Flow

*   **Status:** Experimental
*   **Publisher:** Anthropic
*   **Feature:** `ghcr.io/anthropics/devcontainer-features/claude-flow:0.3`
*   **Description:** This feature sets up the Claude Flow runtime, which orchestrates tasks among the Claude Code agent, workflows, and optional external connectors.
*   **Dependencies:** `claude-code` and `docker-outside-of-docker`.

### Open Code

*   **Status:** Prototype
*   **Publisher:** Open Code Initiative Community
*   **Feature:** `ghcr.io/opencode-dev/features/open-code:0.1`
*   **Description:** This feature adds Open Code CLI agents and editor hooks for open-weights AI coding assistants.

## Docker-in-Docker and Docker-outside-of-Docker

### Docker-outside-of-Docker (DooD)

Docker-outside-of-Docker is a method for a container to interact with the Docker daemon running on the host machine. This is achieved by mounting the host's Docker socket (`/var/run/docker.sock`) into the container. While this is a simple way to enable a container to manage other containers, it has significant security implications, as it provides root-level access to the host system.

### Rootless Docker-in-Docker (DinD)

Rootless Docker-in-Docker is a more secure alternative to DooD. It involves running a separate, nested Docker daemon inside the container, but without requiring root privileges. This provides better isolation and reduces the security risks associated with exposing the host's Docker daemon.

Given the security considerations of DooD, using a rootless DinD approach for the `claude-flow` devcontainer is a recommended strategy.
