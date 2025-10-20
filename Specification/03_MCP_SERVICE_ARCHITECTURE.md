# MCP Service Architecture Specification

**Feature ID**: SPEC-03
**Priority**: P1 (Important)
**Status**: Approved
**Depends On**: SPEC-01 (Container Orchestration), SPEC-02 (Security Modes)
**Created**: 2025-10-20
**Last Updated**: 2025-10-20

---

## Executive Summary

Dual-layer MCP (Model Context Protocol) service architecture providing AI agents with standardized tools and context. Global services shared across workspaces, workspace-specific services per project. Uses Docker Compose services as sibling containers with network-based communication.

**Key Decision (D-05)**: Docker Compose services (global + workspace) provide scalable, isolated MCP architecture with shared discovery.

---

## 1. MCP Architecture Overview

### 1.1 Dual-Layer Design

```
┌─────────────────────────────────────────────────────────────┐
│ MCP Service Architecture                                    │
│                                                             │
│ ┌─────────────────┐    ┌─────────────────────────────────┐ │
│ │ Global Layer    │    │ Workspace Layer                 │ │
│ │                 │    │                                 │ │
│ │ • Git MCP       │◄──►│ • Filesystem MCP               │ │
│ │ • Code Analysis │    │ • Git Safety MCP               │ │
│ │ • Package Mgmt  │    │ • Project-specific MCPs        │ │
│ │ • Discovery     │    │ • Workspace Discovery          │ │
│ │                 │    │                                 │ │
│ │ Network:        │    │ Network:                        │ │
│ │ mcp-global      │    │ mcp-workspace-${HASH}           │ │
│ └─────────────────┘    └─────────────────────────────────┘ │
│          ▲                           ▲                     │
│          │                           │                     │
│          └───────────┬───────────────┘                     │
│                      ▼                                     │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ AI Agent in DevContainer                                │ │
│ │ • Connects to both layers via network                   │ │
│ │ • Discovers services via MCP discovery protocol        │ │
│ │ • Invokes tools and accesses resources                  │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Service Layers

**Global Layer**:
- **Purpose**: Cross-workspace functionality
- **Lifecycle**: Started on host boot or first BitBot run
- **Network**: `mcp-global` (172.20.0.0/16)
- **Examples**: Git operations, code analysis, package management
- **Discovery**: `http://mcp-discovery-global:8080`

**Workspace Layer**:
- **Purpose**: Project-specific functionality
- **Lifecycle**: Started/stopped with workspace container
- **Network**: `mcp-workspace-${WORKSPACE_HASH}` (172.21.x.0/24)
- **Examples**: Filesystem access, workspace git safety, custom tools
- **Discovery**: `http://mcp-discovery-workspace:9080`

---

## 2. Global MCP Services

### 2.1 Global Service Composition

**Location**: `~/.bitbot/global/mcp/docker-compose.yml`

```yaml
version: '3.8'

services:
  # MCP Discovery Server (Global)
  mcp-discovery-global:
    image: mcp-community/discovery-server:latest
    container_name: mcp-discovery-global
    ports:
      - "8080:8080"   # REST API
      - "8081:8081"   # WebSocket/SSE
    networks:
      - mcp-global
    environment:
      - MCP_SCOPE=global
      - MCP_REGISTRY_PERSIST=true
    volumes:
      - mcp-discovery-data:/var/lib/mcp/registry
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Git Helper MCP (Global)
  mcp-git-helper-global:
    image: bitbot/mcp-git-helper:latest
    container_name: mcp-git-helper-global
    networks:
      - mcp-global
    environment:
      - MCP_DISCOVERY_URL=http://mcp-discovery-global:8080
      - MCP_SERVICE_ID=git-helper-global
      - MCP_SCOPE=global
    depends_on:
      - mcp-discovery-global
    restart: unless-stopped

  # Code Analysis MCP (Global)
  mcp-code-analyzer-global:
    image: bitbot/mcp-code-analyzer:latest
    container_name: mcp-code-analyzer-global
    networks:
      - mcp-global
    environment:
      - MCP_DISCOVERY_URL=http://mcp-discovery-global:8080
      - MCP_SERVICE_ID=code-analyzer-global
      - MCP_SCOPE=global
    depends_on:
      - mcp-discovery-global
    restart: unless-stopped

  # Package Manager MCP (Global)
  mcp-package-manager-global:
    image: bitbot/mcp-package-manager:latest
    container_name: mcp-package-manager-global
    networks:
      - mcp-global
    environment:
      - MCP_DISCOVERY_URL=http://mcp-discovery-global:8080
      - MCP_SERVICE_ID=package-manager-global
      - MCP_SCOPE=global
    depends_on:
      - mcp-discovery-global
    restart: unless-stopped

networks:
  mcp-global:
    external: true
    name: mcp-global

volumes:
  mcp-discovery-data:
    name: mcp-discovery-global-data
```

### 2.2 Global Service Capabilities

#### Git Helper MCP
```json
{
  "id": "git-helper-global",
  "name": "Git Helper",
  "scope": "global",
  "capabilities": {
    "tools": [
      "git_clone",
      "git_fetch_remote",
      "git_search_history",
      "git_blame_file",
      "git_branch_list",
      "git_remote_info"
    ],
    "resources": [
      "git://history/*",
      "git://remotes/*",
      "git://branches/*"
    ],
    "prompts": [
      "commit_message_suggest",
      "branch_name_suggest",
      "merge_conflict_resolve"
    ]
  }
}
```

#### Code Analysis MCP
```json
{
  "id": "code-analyzer-global",
  "name": "Code Analysis",
  "scope": "global",
  "capabilities": {
    "tools": [
      "analyze_code_quality",
      "detect_patterns",
      "suggest_refactoring",
      "find_dependencies",
      "security_scan"
    ],
    "resources": [
      "analysis://quality/*",
      "analysis://patterns/*",
      "analysis://dependencies/*"
    ],
    "prompts": [
      "code_review",
      "refactoring_plan",
      "security_audit"
    ]
  }
}
```

---

## 3. Workspace MCP Services

### 3.1 Workspace Service Composition

**Location**: `.bitbot/mcp/docker-compose.yml`

```yaml
version: '3.8'

services:
  # Workspace Discovery Server
  mcp-discovery-workspace:
    image: mcp-community/discovery-server:latest
    container_name: "mcp-discovery-${WORKSPACE_HASH}"
    ports:
      - "9080:8080"   # REST API (different port from global)
    networks:
      - mcp-workspace
      - mcp-global     # Access to global services
    environment:
      - MCP_SCOPE=workspace
      - MCP_WORKSPACE_HASH=${WORKSPACE_HASH}
      - MCP_GLOBAL_DISCOVERY=http://mcp-discovery-global:8080
    volumes:
      - mcp-workspace-registry:/var/lib/mcp/registry
    restart: unless-stopped

  # Filesystem MCP (Workspace-specific)
  mcp-filesystem-workspace:
    image: bitbot/mcp-filesystem:latest
    container_name: "mcp-filesystem-${WORKSPACE_HASH}"
    networks:
      - mcp-workspace
    environment:
      - MCP_DISCOVERY_URL=http://mcp-discovery-workspace:8080
      - MCP_SERVICE_ID=filesystem-${WORKSPACE_HASH}
      - MCP_SCOPE=workspace
      - WORKSPACE_PATH=/workspace
    volumes:
      # Mount workspace for filesystem operations
      - "${WORKSPACE_PATH}:/workspace:rw"
    depends_on:
      - mcp-discovery-workspace
    restart: unless-stopped

  # Git Safety MCP (Workspace-specific)
  mcp-git-safety-workspace:
    image: bitbot/mcp-git-safety:latest
    container_name: "mcp-git-safety-${WORKSPACE_HASH}"
    networks:
      - mcp-workspace
    environment:
      - MCP_DISCOVERY_URL=http://mcp-discovery-workspace:8080
      - MCP_SERVICE_ID=git-safety-${WORKSPACE_HASH}
      - MCP_SCOPE=workspace
      - WORKSPACE_PATH=/workspace
    volumes:
      # Mount workspace for git operations
      - "${WORKSPACE_PATH}:/workspace:rw"
    depends_on:
      - mcp-discovery-workspace
    restart: unless-stopped

networks:
  mcp-workspace:
    external: true
    name: "mcp-workspace-${WORKSPACE_HASH}"
  mcp-global:
    external: true
    name: mcp-global

volumes:
  mcp-workspace-registry:
    name: "mcp-registry-${WORKSPACE_HASH}"
```

### 3.2 Workspace Service Capabilities

#### Filesystem MCP
```json
{
  "id": "filesystem-${WORKSPACE_HASH}",
  "name": "Workspace Filesystem",
  "scope": "workspace",
  "workspace_hash": "${WORKSPACE_HASH}",
  "capabilities": {
    "tools": [
      "read_file",
      "write_file",
      "list_directory",
      "create_directory",
      "delete_file",
      "move_file",
      "search_files",
      "get_file_info"
    ],
    "resources": [
      "file:///workspace/*",
      "directory:///workspace/*"
    ],
    "prompts": [
      "file_structure_analysis",
      "workspace_overview"
    ]
  }
}
```

#### Git Safety MCP
```json
{
  "id": "git-safety-${WORKSPACE_HASH}",
  "name": "Workspace Git Safety",
  "scope": "workspace",
  "workspace_hash": "${WORKSPACE_HASH}",
  "capabilities": {
    "tools": [
      "git_status_check",
      "git_create_checkpoint",
      "git_diff_summary",
      "git_safety_audit",
      "git_recommend_action"
    ],
    "resources": [
      "git://workspace/status",
      "git://workspace/diff",
      "git://workspace/log"
    ],
    "prompts": [
      "safety_check_report",
      "checkpoint_recommendation"
    ]
  }
}
```

---

## 4. Service Discovery and Registration

### 4.1 Discovery Protocol

**Global Service Discovery**:
```bash
# AI agents query global discovery
curl http://mcp-discovery-global:8080/api/services

# Response
{
  "services": [
    {
      "id": "git-helper-global",
      "name": "Git Helper",
      "scope": "global",
      "endpoint": "ws://mcp-git-helper-global:9090/mcp",
      "health": "healthy",
      "capabilities": { ... }
    }
  ]
}
```

**Workspace Service Discovery**:
```bash
# AI agents query workspace discovery
curl http://mcp-discovery-workspace:8080/api/services

# Response includes workspace services + global services
{
  "services": [
    {
      "id": "filesystem-a1b2c3d4",
      "name": "Workspace Filesystem",
      "scope": "workspace",
      "workspace_hash": "a1b2c3d4",
      "endpoint": "ws://mcp-filesystem-a1b2c3d4:9090/mcp",
      "health": "healthy"
    },
    {
      "id": "git-helper-global",
      "name": "Git Helper",
      "scope": "global",
      "endpoint": "ws://mcp-git-helper-global:9090/mcp",
      "health": "healthy"
    }
  ]
}
```

### 4.2 Service Registration

**MCP Service Registration Flow**:
1. Service starts up
2. Reads MCP_DISCOVERY_URL from environment
3. Registers with discovery server via POST
4. Maintains heartbeat for health checks
5. Discovery server provides service to AI agents

**Registration Request**:
```json
{
  "id": "filesystem-a1b2c3d4",
  "name": "Workspace Filesystem",
  "scope": "workspace",
  "workspace_hash": "a1b2c3d4",
  "transport": {
    "type": "websocket",
    "endpoint": "ws://mcp-filesystem-a1b2c3d4:9090/mcp"
  },
  "capabilities": {
    "tools": ["read_file", "write_file", "list_directory"],
    "resources": ["file:///workspace/*"],
    "prompts": ["workspace_overview"]
  },
  "health": {
    "endpoint": "http://mcp-filesystem-a1b2c3d4:9090/health",
    "interval_ms": 30000
  }
}
```

---

## 5. Network Architecture

### 5.1 Network Topology

**Network Segmentation**:
```yaml
# Global MCP Network
networks:
  mcp-global:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

# Per-Workspace Networks
networks:
  mcp-workspace-a1b2c3d4:
    driver: bridge
    ipam:
      config:
        - subnet: 172.21.1.0/24

  mcp-workspace-b2c3d4e5:
    driver: bridge
    ipam:
      config:
        - subnet: 172.21.2.0/24
```

### 5.2 Container Network Membership

**DevContainer Network Access**:
```yaml
# Work container connects to both networks
services:
  bitbot-work:
    networks:
      - mcp-global                    # Access global services
      - mcp-workspace-${WORKSPACE_HASH}  # Access workspace services
```

**MCP Service Network Access**:
```yaml
# Workspace MCP services connect to both networks
services:
  mcp-filesystem-workspace:
    networks:
      - mcp-workspace-${WORKSPACE_HASH}  # Primary network
      - mcp-global                    # Discovery of global services
```

---

## 6. AI Agent Integration

### 6.1 Service Discovery in AI Agents

**Claude Code Integration** (`.claude/config.yml`):
```yaml
mcpServers:
  # Dynamic discovery from workspace
  workspace-discovery:
    command: curl
    args: ["http://mcp-discovery-workspace:8080/api/services"]

  # Static global services
  git-helper:
    command: docker
    args: ["exec", "mcp-git-helper-global", "mcp-server"]

  filesystem:
    command: docker
    args: ["exec", "mcp-filesystem-${WORKSPACE_HASH}", "mcp-server"]
    env:
      WORKSPACE_PATH: "${workspaceFolder}"
```

### 6.2 Tool Invocation Examples

**File Operations**:
```javascript
// AI agent calls filesystem MCP
const result = await mcpClient.callTool("filesystem-a1b2c3d4", "read_file", {
  path: "/workspace/src/main.py"
});
```

**Git Safety Checks**:
```javascript
// AI agent calls git safety MCP
const gitStatus = await mcpClient.callTool("git-safety-a1b2c3d4", "git_status_check", {
  verbose: true
});

if (gitStatus.uncommitted_changes > 0) {
  await mcpClient.callTool("git-safety-a1b2c3d4", "git_create_checkpoint", {
    message: "Before refactoring",
    method: "stash"
  });
}
```

**Code Analysis**:
```javascript
// AI agent calls global code analysis MCP
const analysis = await mcpClient.callTool("code-analyzer-global", "analyze_code_quality", {
  workspace_path: "/workspace",
  language: "python"
});
```

---

## 7. Lifecycle Management

### 7.1 Global Services Lifecycle

**Start Global Services**:
```bash
#!/bin/bash
# Start global MCP services (run once per host)

cd ~/.bitbot/global/mcp

# Create global network if not exists
docker network create mcp-global --subnet=172.20.0.0/16 2>/dev/null || true

# Start global services
docker-compose up -d

# Wait for discovery server
while ! curl -s http://localhost:8080/health >/dev/null; do
  echo "Waiting for global MCP discovery..."
  sleep 2
done

echo "✓ Global MCP services started"
```

**Stop Global Services**:
```bash
#!/bin/bash
# Stop global MCP services (optional, they can run continuously)

cd ~/.bitbot/global/mcp
docker-compose down

echo "✓ Global MCP services stopped"
```

### 7.2 Workspace Services Lifecycle

**Start Workspace Services**:
```bash
#!/bin/bash
# Start workspace MCP services (per workspace)

WORKSPACE_PATH="$(pwd)"
WORKSPACE_HASH=$(echo -n "$WORKSPACE_PATH" | sha256sum | cut -c1-8)

export WORKSPACE_PATH WORKSPACE_HASH

cd "$WORKSPACE_PATH/.bitbot/mcp"

# Create workspace network if not exists
docker network create "mcp-workspace-$WORKSPACE_HASH" \
  --subnet="172.21.$((WORKSPACE_HASH % 255)).0/24" 2>/dev/null || true

# Start workspace services
docker-compose up -d

# Wait for workspace discovery
while ! curl -s "http://localhost:9080/health" >/dev/null; do
  echo "Waiting for workspace MCP discovery..."
  sleep 2
done

echo "✓ Workspace MCP services started (workspace: $WORKSPACE_HASH)"
```

**Stop Workspace Services**:
```bash
#!/bin/bash
# Stop workspace MCP services

WORKSPACE_HASH=$(echo -n "$(pwd)" | sha256sum | cut -c1-8)

cd .bitbot/mcp
docker-compose down

echo "✓ Workspace MCP services stopped (workspace: $WORKSPACE_HASH)"
```

---

## 8. Security and Isolation

### 8.1 Network Security

**Network Isolation**:
- Global services cannot access workspace filesystems
- Workspace services are isolated per workspace
- DevContainers only access their own workspace services
- No direct host filesystem access for MCP services

**Service Authentication**:
```yaml
# MCP services use shared secrets for authentication
environment:
  - MCP_AUTH_TOKEN=${MCP_AUTH_TOKEN}  # Shared secret
  - MCP_CLIENT_CERT=/etc/mcp/client.crt  # Optional: mTLS
```

### 8.2 Resource Limits

**Container Resource Limits**:
```yaml
services:
  mcp-filesystem-workspace:
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
        reservations:
          memory: 128M
          cpus: '0.25'
```

**File System Access Control**:
```yaml
# Filesystem MCP only accesses workspace, not host
volumes:
  - "${WORKSPACE_PATH}:/workspace:rw"  # Workspace only
  # No host directories mounted
```

---

## 9. Configuration and Extension

### 9.1 Custom MCP Services

**Adding Custom Workspace Services** (`.bitbot/mcp/docker-compose.yml`):
```yaml
services:
  # Custom project-specific MCP service
  mcp-database-helper:
    image: myproject/mcp-database-helper:latest
    container_name: "mcp-database-${WORKSPACE_HASH}"
    networks:
      - mcp-workspace
    environment:
      - MCP_DISCOVERY_URL=http://mcp-discovery-workspace:8080
      - MCP_SERVICE_ID=database-${WORKSPACE_HASH}
      - DATABASE_URL=${DATABASE_URL}
    depends_on:
      - mcp-discovery-workspace
```

### 9.2 MCP Service Templates

**Service Template Structure**:
```
~/.bitbot/templates/mcp-services/
├── database-helper/
│   ├── docker-compose.yml      # Service definition
│   ├── Dockerfile              # Custom image (optional)
│   └── config.json             # Service configuration
└── api-client/
    ├── docker-compose.yml
    └── config.json
```

**Template Usage**:
```bash
# Add custom MCP service to workspace
bitbot mcp add database-helper

# Configure service
bitbot mcp config database-helper --database-url="postgresql://..."

# Start service
bitbot mcp start database-helper
```

---

## 10. Monitoring and Debugging

### 10.1 Service Health Monitoring

**Health Check Endpoints**:
```bash
# Check global services
curl http://localhost:8080/health
curl http://mcp-git-helper-global:9090/health

# Check workspace services  
curl http://localhost:9080/health
curl http://mcp-filesystem-${WORKSPACE_HASH}:9090/health
```

**Service Logs**:
```bash
# View MCP service logs
docker logs mcp-discovery-global
docker logs mcp-filesystem-${WORKSPACE_HASH}

# Follow logs for debugging
docker logs -f mcp-git-safety-${WORKSPACE_HASH}
```

### 10.2 Service Discovery Debugging

**List Registered Services**:
```bash
# Global services
curl http://localhost:8080/api/services | jq

# Workspace services
curl http://localhost:9080/api/services | jq
```

**Test Service Communication**:
```bash
# Test MCP tool invocation
docker exec bitbot-work-${WORKSPACE_HASH} \
  curl -X POST http://mcp-filesystem-${WORKSPACE_HASH}:9090/mcp \
  -H "Content-Type: application/json" \
  -d '{"method": "tools/list"}'
```

---

## 11. Success Criteria

**Functional Requirements**:
- [ ] Global MCP services start and register correctly
- [ ] Workspace MCP services start per workspace
- [ ] AI agents can discover services via discovery protocol
- [ ] Tool invocation works across network boundaries
- [ ] Service health monitoring operational
- [ ] Custom MCP services can be added

**Performance Requirements**:
- [ ] Service discovery response time < 500ms
- [ ] Tool invocation latency < 1s for simple operations
- [ ] Memory usage per MCP service < 256MB
- [ ] Network overhead minimal for MCP communication

**Security Requirements**:
- [ ] Network isolation between workspaces
- [ ] No unauthorized filesystem access
- [ ] Service authentication working
- [ ] Resource limits enforced

---

## 12. References

**Related Specifications**:
- SPEC-00: Architectural Decisions (D-05: MCP service architecture)
- SPEC-01: Container Orchestration (network integration)
- SPEC-02A: Git Safety Integration (git safety MCP tools)
- SPEC-07: AI Agent Integration (MCP client configuration)

**External References**:
- Model Context Protocol: https://modelcontextprotocol.io/
- MCP Community Registry: https://github.com/mcp-community
- Docker Compose Networking: https://docs.docker.com/compose/networking/

---

**Status**: **Approved**
**Implementation Priority**: P1 (Important for AI workflows)
**Next Steps**: Implement SPEC-04 (Session Management)