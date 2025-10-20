# Container Orchestration Strategy Specification

**Feature ID**: SPEC-01
**Priority**: P0 (Critical - Blocking)
**Status**: Approved
**Depends On**: None
**Created**: 2025-10-20
**Last Updated**: 2025-10-20

---

## Executive Summary

BitBot uses `@devcontainers/cli` for work containers with Docker Compose fallback for setup containers. Work and setup are separate containers that can run simultaneously. Both support VS Code attachment and provide different access levels for safety.

**Key Decision (D-01)**: `@devcontainers/cli` with Docker Compose fallback provides standards compliance while maintaining flexibility for advanced workflows.

---

## 1. Architecture Overview

### 1.1 Container Strategy

```
┌─────────────────────────────────────────────────────────────┐
│ Host Machine                                                │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │ BitBot CLI      │    │ VS Code (Optional)              │ │
│  │ (bash)          │    │ - Can attach to both containers │ │
│  └─────────────────┘    └─────────────────────────────────┘ │
│           │                                                 │
│           ├─────────────────┬───────────────────────────────┤
│           ▼                 ▼                               │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │ Work Container  │    │ Setup Container                 │ │
│  │ (@devcontainers)│    │ (Docker Compose)               │ │
│  │                 │    │                                 │ │
│  │ • AI Agents     │    │ • .devcontainer editing        │ │
│  │ • Development   │    │ • Infrastructure changes       │ │
│  │ • Read-only     │    │ • Docker socket access         │ │
│  │   .devcontainer │    │ • Setup wizards                │ │
│  └─────────────────┘    └─────────────────────────────────┘ │
│                                                             │
│  Both containers can run simultaneously                     │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Implementation Components

**Work Container**:
- Managed by `@devcontainers/cli`
- Standards-compliant DevContainer
- AI agents run inside
- .devcontainer mounted read-only

**Setup Container**:
- Custom Docker Compose in `.bitbot/setup/`
- Full workspace read-write access
- Can modify .devcontainer
- Docker socket available when approved

---

## 2. Work Container Implementation

### 2.1 DevContainer Configuration

**Standard .devcontainer/devcontainer.json**:
```json
{
  "name": "BitBot Development Environment",
  "dockerComposeFile": "../.bitbot/docker-compose.work.yml",
  "service": "bitbot-work",
  "workspaceFolder": "/workspace",

  "features": {
    "ghcr.io/devcontainers/features/git:1": {},
    "ghcr.io/devcontainers/features/node:1": {
      "version": "18"
    }
  },

  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.vscode-json"
      ]
    }
  },

  "postCreateCommand": "/opt/bitbot/setup-workspace.sh",
  "remoteUser": "root"
}
```

### 2.2 Work Container Compose

**.bitbot/docker-compose.work.yml**:
```yaml
version: '3.8'

services:
  bitbot-work:
    build:
      context: .
      dockerfile: .devcontainer/Dockerfile
    container_name: "bitbot-work-${WORKSPACE_HASH}"
    volumes:
      # Workspace (read-write)
      - "${WORKSPACE_PATH}:/workspace"
      # .devcontainer (read-only for safety)
      - "${WORKSPACE_PATH}/.devcontainer:/workspace/.devcontainer:ro"
      # BitBot state (read-write, except setup/)
      - "${WORKSPACE_PATH}/.bitbot/logs:/workspace/.bitbot/logs"
      - "${WORKSPACE_PATH}/.bitbot/sessions:/workspace/.bitbot/sessions"
      - "${WORKSPACE_PATH}/.bitbot/state:/workspace/.bitbot/state"
      # .bitbot/setup/ is NOT mounted (invisible to work container)
    networks:
      - bitbot-network
    environment:
      - BITBOT_MODE=work
      - WORKSPACE_HASH=${WORKSPACE_HASH}
    working_dir: /workspace
    command: ["tail", "-f", "/dev/null"]  # Keep container running

networks:
  bitbot-network:
    external: true
    name: bitbot-network
```

### 2.3 Work Container Commands

```bash
# Host commands that manage work container
bitbot work         # Start work container (CLI)
bitbot work vscode  # Start work container + launch VS Code
bitbot cli          # Attach to existing work container
```

---

## 3. Setup Container Implementation

### 3.1 Setup Container Compose

**.bitbot/setup/docker-compose.yml**:
```yaml
version: '3.8'

services:
  bitbot-setup:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: "bitbot-setup-${WORKSPACE_HASH}"
    volumes:
      # Full workspace access (read-write)
      - "${WORKSPACE_PATH}:/setup/workspace"
      # Docker socket (when approved)
      - "/var/run/docker.sock:/var/run/docker.sock"
    networks:
      - bitbot-network
    environment:
      - BITBOT_MODE=setup
      - WORKSPACE_HASH=${WORKSPACE_HASH}
      - DOCKER_HOST=unix:///var/run/docker.sock
    working_dir: /setup/workspace
    command: ["/opt/bitbot/entrypoint-setup.sh"]

networks:
  bitbot-network:
    external: true
    name: bitbot-network
```

### 3.2 Setup Container Dockerfile

**.bitbot/setup/Dockerfile**:
```dockerfile
FROM ubuntu:22.04

# Install base tools
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    git \
    tmux \
    zsh \
    vim \
    jq \
    fzf \
    docker.io \
    docker-compose \
    && rm -rf /var/lib/apt/lists/*

# Install @devcontainers/cli
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g @devcontainers/cli

# Install BitBot setup tools
COPY scripts/ /opt/bitbot/
RUN chmod +x /opt/bitbot/*.sh

# Setup user environment
RUN chsh -s /bin/zsh root

WORKDIR /setup/workspace
ENTRYPOINT ["/opt/bitbot/entrypoint-setup.sh"]
CMD ["/bin/zsh"]
```

### 3.3 Setup Container Commands

```bash
# Host commands that manage setup container
bitbot setup         # Start setup container (CLI)
bitbot setup vscode  # Start setup container + launch VS Code
```

---

## 4. Container Lifecycle Management

### 4.1 Startup Flow

**Work Container Startup**:
1. Check if `.devcontainer/devcontainer.json` exists
2. Generate `WORKSPACE_HASH` from workspace path
3. Create Docker network if not exists: `bitbot-network`
4. Run `@devcontainers/cli up` or fallback to `docker-compose`
5. Execute post-create commands
6. Start tmux session inside container

**Setup Container Startup**:
1. Ensure `.bitbot/setup/` directory exists
2. Generate setup container if needed
3. Mount full workspace at `/setup/workspace`
4. Mount Docker socket (with user approval)
5. Start setup environment with specialized tools

### 4.2 Container Communication

**Network Architecture**:
```yaml
# Shared network for container communication
networks:
  bitbot-network:
    external: true
    name: bitbot-network
```

**Service Discovery**:
- Work container: `bitbot-work-${WORKSPACE_HASH}`
- Setup container: `bitbot-setup-${WORKSPACE_HASH}`
- MCP services: `mcp-*-${WORKSPACE_HASH}`

### 4.3 Parallel Execution

Both containers can run simultaneously:
- **Developer workflow**: Work in work container
- **Infrastructure changes**: Use setup container in parallel
- **No conflicts**: Separate mount strategies prevent issues

---

## 5. Safety and Security

### 5.1 Work Container Safety

**Read-only .devcontainer**:
```yaml
volumes:
  - "${WORKSPACE_PATH}/.devcontainer:/workspace/.devcontainer:ro"
```

**No Docker socket by default**:
- Work container cannot modify host Docker
- AI agents cannot create/destroy containers
- Infrastructure changes require setup mode

### 5.2 Setup Container Safety

**Git-based protection** (Decision D-02):
- All infrastructure changes protected by git push/bundle
- Setup container warns on uncommitted changes
- User must explicitly approve Docker socket access

**Audit trail**:
```bash
# All setup actions logged
echo "[$TIMESTAMP] Setup container started" >> .bitbot/logs/setup.log
```

---

## 6. VS Code Integration

### 6.1 DevContainer Compatibility

Both containers are VS Code DevContainer compatible:

**Work Container**:
```bash
code --remote "attach-container+bitbot-work-${WORKSPACE_HASH}" /workspace
```

**Setup Container**:
```bash
code --remote "attach-container+bitbot-setup-${WORKSPACE_HASH}" /setup/workspace
```

### 6.2 Multi-container Development

VS Code can attach to both containers simultaneously:
- **Primary workspace**: Work container
- **Configuration editing**: Setup container
- **Seamless switching**: Via VS Code Remote-Containers extension

---

## 7. Implementation Commands

### 7.1 Host CLI Implementation

```bash
#!/bin/bash
# bitbot command implementation

WORKSPACE_PATH="$(pwd)"
WORKSPACE_HASH=$(echo -n "$WORKSPACE_PATH" | sha256sum | cut -c1-8)

export WORKSPACE_PATH WORKSPACE_HASH

case "${1:-work}" in
    work)
        if [ "$2" = "vscode" ]; then
            devcontainer up --workspace-folder "$WORKSPACE_PATH"
            code --remote "attach-container+bitbot-work-$WORKSPACE_HASH" /workspace
        else
            devcontainer up --workspace-folder "$WORKSPACE_PATH"
            devcontainer exec --workspace-folder "$WORKSPACE_PATH" /bin/zsh
        fi
        ;;

    setup)
        cd "$WORKSPACE_PATH/.bitbot/setup"
        if [ "$2" = "vscode" ]; then
            docker-compose up -d
            code --remote "attach-container+bitbot-setup-$WORKSPACE_HASH" /setup/workspace
        else
            docker-compose up -d
            docker-compose exec bitbot-setup /bin/zsh
        fi
        ;;

    done)
        # Inside container command - handled by internal scripts
        /opt/bitbot/done.sh
        ;;
esac
```

### 7.2 Container Detection

```bash
# Detect if running inside container
if [ -f "/.dockerenv" ]; then
    # Inside container - different command behavior
    BITBOT_MODE="${BITBOT_MODE:-work}"
else
    # On host - container management commands
    BITBOT_MODE="host"
fi
```

---

## 8. Fallback Strategy

### 8.1 @devcontainers/cli Issues

If `@devcontainers/cli` has problems:

1. **Fallback to Docker Compose**: Use `.bitbot/docker-compose.work.yml` directly
2. **Maintain compatibility**: Same container name and mount structure
3. **User notification**: Inform about fallback usage
4. **Automatic retry**: Periodically test `@devcontainers/cli` availability

### 8.2 Docker Compose Fallback

```bash
# Fallback implementation
if ! command -v devcontainer >/dev/null 2>&1; then
    echo "⚠ @devcontainers/cli not available, using Docker Compose fallback"
    cd "$WORKSPACE_PATH"
    docker-compose -f .bitbot/docker-compose.work.yml up -d
    docker-compose -f .bitbot/docker-compose.work.yml exec bitbot-work /bin/zsh
fi
```

---

## 9. Success Criteria

**Functional Requirements**:
- [ ] Work container starts with `@devcontainers/cli`
- [ ] Setup container starts with Docker Compose
- [ ] Both containers can run simultaneously
- [ ] VS Code can attach to both containers
- [ ] .devcontainer is read-only in work container
- [ ] .devcontainer is read-write in setup container
- [ ] Docker socket available in setup (when approved)
- [ ] Fallback to Docker Compose works if needed

**User Experience**:
- [ ] Single `bitbot` command manages both containers
- [ ] Clear indication of which container is active
- [ ] Seamless VS Code integration
- [ ] Easy switching between containers

**Safety**:
- [ ] Work container cannot modify .devcontainer accidentally
- [ ] Setup container requires explicit approval for Docker access
- [ ] All container actions logged for audit
- [ ] Git safety checks before infrastructure changes

---

## 10. References

**Related Specifications**:
- SPEC-00: Architectural Decisions (D-01: Container orchestration)
- SPEC-02: Security Mode System (mount strategies)
- SPEC-05: Cross-Platform CLI (host command structure)
- SPEC-06: VS Code DevContainer Integration

**External Dependencies**:
- `@devcontainers/cli`: https://github.com/devcontainers/cli
- Docker Compose: https://docs.docker.com/compose/
- VS Code Remote-Containers: https://code.visualstudio.com/docs/remote/containers

---

**Status**: **Approved**
**Implementation Priority**: P0 (Critical - Blocking)
**Next Steps**: Implement SPEC-02 (Security Mode System)