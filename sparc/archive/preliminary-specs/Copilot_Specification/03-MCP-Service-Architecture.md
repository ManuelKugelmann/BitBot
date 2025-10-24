# Feature: MCP Service Architecture

## Research References
- Research/MCP_ARCHITECTURE_RESEARCH.md (lines 1-51)
- Claude_info.txt:139-174 (service orchestration)

## Feature Description
BitBot orchestrates Model Context Protocol (MCP) services for AI agents, supporting both global and per-workspace service isolation.

### Chosen Approach: Dual Compose/Networks (Option B)
- **Global MCP services** (e.g., registry, gateway) run in a dedicated Docker Compose network, managed by a global BitBot Compose file.
- **Per-workspace MCP services** (e.g., file-system, git-helper, code-analyzer) run in separate Docker Compose networks, managed by workspace-specific Compose files.
- Each workspace only sees its own MCPs and the global MCPs.
- Service discovery and health checks are implemented for both global and workspace MCPs.

## Implementation Details
- On first BitBot run on the host, BitBot will start the global MCP Docker Compose stack if not already running.
- If a workspace container detects missing global MCPs, BitBot will prompt the user to start the global service (with a helpful hint).
- BitBot global setup will:
  - Adjust PATH and environment variables for CLI integration
  - Offer an autostart option for global MCP services (e.g., systemd, Windows service, or Docker restart policy)
- Per-workspace MCPs are started/stopped with the workspace container lifecycle.
- Networks and volumes are isolated per workspace for security and sandboxing.

## MCP Service Deployment Options
BitBot supports three deployment options for MCP servers:

### 1. Global MCP Services
- Run as dedicated containers on the host, shared across all workspaces.
- Managed by a global Docker Compose stack.
- Accessible to all devcontainers via Docker network.

### 2. Workspace MCP Services
- Run as containers alongside the devcontainer, isolated per workspace.
- Managed by workspace-specific Docker Compose stacks.
- Only accessible to the associated workspace devcontainer.

### 3. Sandboxed MCP Services
- Run inside the devcontainer using rootless Docker (DinD) for extra isolation.
- Used for untrusted or experimental MCPs.
- Not accessible to other workspaces or the host.
- User can choose per-MCP whether to run it globally, per-workspace, or sandboxed inside the devcontainer.

## Rationale
- Provides flexibility and security: trusted MCPs can run globally or per-workspace, while untrusted MCPs are sandboxed.
- No Docker socket mount required for most workflows; only needed for advanced scenarios.
- Aligns with best practices for multi-tenant and secure development environments.
