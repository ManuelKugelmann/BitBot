# MCP Service Architecture Specification

**Feature ID**: SPEC-03
**Priority**: P0 (Critical - Blocking)
**Status**: Approved
**Depends On**: SPEC-01 (Container Orchestration), SPEC-02 (Security Modes)
**Created**: 2025-10-16
**Last Updated**: 2025-10-17

---

## Executive Summary

Dual-layer MCP (Model Context Protocol) service architecture with sibling containers. Global services shared across workspaces, workspace services per-workspace. Uses existing MCP discovery server for service registry.

**Key Design**: MCP services as sibling containers + dual-layer (global/workspace) + existing discovery server = extensible AI tooling.

---

## 1. Architecture

### 1.1 Dual-Layer Design

**Global Layer**:
- Shared across all workspaces
- Network: `mcp-global` (172.20.0.0/16)
- Services: Discovery server, git helper, package manager, code analyzer
- Lifecycle: Independent, host-managed
- Port: 8080 (discovery)

**Workspace Layer**:
- Per-workspace instance
- Network: `mcp-workspace-${WORKSPACE_HASH}` (172.21.x.0/24)
- Services: Workspace discovery, filesystem MCP, custom services
- Lifecycle: Tied to workspace
- Port: 9080 (discovery)

### 1.2 Container Topology

```
Host System
├── Global MCP Services
│   ├── mcp-discovery-global (port 8080)
│   ├── mcp-git-helper-global
│   ├── mcp-package-manager-global
│   └── mcp-code-analyzer-global
│   Network: mcp-global
│
├── Workspace MCP Services (per workspace)
│   ├── mcp-discovery-${WORKSPACE_HASH} (port 9080)
│   ├── mcp-filesystem-${WORKSPACE_HASH}
│   ├── mcp-git-safety-${WORKSPACE_HASH}
│   └── mcp-custom-services...
│   Network: mcp-workspace-${WORKSPACE_HASH} + mcp-global
│
└── DevContainer (bitbot-dev-${WORKSPACE_HASH})
    Network: mcp-workspace-${WORKSPACE_HASH} + mcp-global
    Access: Network-only (no direct filesystem to MCP services)
```

---

## 2. MCP Protocol

### 2.1 Core Primitives

**Tools**: Functions AI agents invoke
```json
{
  "method": "tools/call",
  "params": {
    "name": "read_file",
    "arguments": {"path": "/workspace/src/main.py"}
  }
}
```

**Resources**: Context and data for AI
```json
{
  "method": "resources/read",
  "params": {
    "uri": "file:///workspace/README.md"
  }
}
```

**Prompts**: Templated workflows
```json
{
  "method": "prompts/get",
  "params": {
    "name": "code_review",
    "arguments": {"file": "src/main.py"}
  }
}
```

### 2.2 Service Registration

Each MCP service registers with discovery server:

```json
{
  "id": "filesystem-${WORKSPACE_HASH}",
  "name": "filesystem-mcp",
  "scope": "workspace",
  "workspace_hash": "a1b2c3d4",
  "transport": {
    "type": "websocket",
    "endpoint": "ws://mcp-filesystem-a1b2c3d4:9090/mcp"
  },
  "capabilities": {
    "tools": ["read_file", "write_file"],
    "resources": ["file:///*"]
  },
  "health": {
    "endpoint": "http://mcp-filesystem-a1b2c3d4:9090/health",
    "interval_ms": 30000
  }
}
```

---

## 3. Global MCP Services

### 3.1 Service Composition

**Docker Compose** (`/opt/bitbot/global-mcp/docker-compose.yml`):

```yaml
services:
  mcp-discovery:
    image: mcp-community/discovery-server:latest
    container_name: mcp-discovery-global
    ports:
      - "8080:8080"  # REST API
      - "8081:8081"  # SSE events
    networks:
      - mcp-global
    restart: unless-stopped

  mcp-git-helper:
    image: bitbot/mcp-git-helper:latest
    container_name: mcp-git-helper-global
    environment:
      - MCP_DISCOVERY_URL=http://mcp-discovery:8080
      - MCP_SCOPE=global
    networks:
      - mcp-global
    restart: unless-stopped

  mcp-package-manager:
    image: bitbot/mcp-package-manager:latest
    container_name: mcp-package-manager-global
    environment:
      - MCP_DISCOVERY_URL=http://mcp-discovery:8080
    networks:
      - mcp-global
    restart: unless-stopped

networks:
  mcp-global:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### 3.2 Management

**Start global services**:
```bash
cd /opt/bitbot/global-mcp
docker-compose up -d
curl http://localhost:8080/api/services  # Verify
```

**Stop global services**:
```bash
docker-compose down  # Data persists in volumes
```

---

## 4. Workspace MCP Services

### 4.1 Service Composition

**Docker Compose** (`.bitbot/mcp/docker-compose.yml`):

```yaml
services:
  mcp-discovery-workspace:
    image: mcp-community/discovery-server:latest
    container_name: mcp-discovery-${WORKSPACE_HASH}
    ports:
      - "9080:8080"
    environment:
      - MCP_SCOPE=workspace
      - MCP_WORKSPACE_HASH=${WORKSPACE_HASH}
      - MCP_GLOBAL_DISCOVERY=http://mcp-discovery-global:8080
    networks:
      - mcp-global
      - mcp-workspace-${WORKSPACE_HASH}
    restart: unless-stopped

  mcp-filesystem:
    image: bitbot/mcp-filesystem:latest
    container_name: mcp-filesystem-${WORKSPACE_HASH}
    volumes:
      - ${WORKSPACE_PATH}:/workspace:ro  # Read-only
    environment:
      - MCP_DISCOVERY_URL=http://mcp-discovery-workspace:8080
      - MCP_WORKSPACE_HASH=${WORKSPACE_HASH}
    networks:
      - mcp-workspace-${WORKSPACE_HASH}
    restart: unless-stopped

  mcp-git-safety:
    image: bitbot/mcp-git-safety:latest
    container_name: mcp-git-safety-${WORKSPACE_HASH}
    volumes:
      - ${WORKSPACE_PATH}:/workspace:rw  # Needs write for commits
    environment:
      - MCP_DISCOVERY_URL=http://mcp-discovery-workspace:8080
    networks:
      - mcp-workspace-${WORKSPACE_HASH}
    restart: unless-stopped

networks:
  mcp-global:
    external: true
  mcp-workspace-${WORKSPACE_HASH}:
    driver: bridge
    ipam:
      config:
        - subnet: 172.21.${SUBNET_OCTET}.0/24
```

### 4.2 Lifecycle Management

**Automatic startup** (in `bitbot-core.sh`):

```bash
# Pseudocode
start_workspace_mcp_services() {
  workspace_hash = sha256(workspace_path)
  subnet_octet = hex_to_dec(workspace_hash[0:2])

  export WORKSPACE_HASH=$workspace_hash
  export WORKSPACE_PATH=$(pwd)
  export SUBNET_OCTET=$subnet_octet

  if exists ".bitbot/mcp/docker-compose.yml":
    docker-compose -f .bitbot/mcp/docker-compose.yml up -d
    wait_for_services(5)
    verify_registration()
}
```

**Shutdown**:
```bash
# Stop with workspace
bitbot stop
# Or manually
docker-compose -f .bitbot/mcp/docker-compose.yml down
```

---

## 5. Service Discovery

### 5.1 Discovery Server

**Decision**: Use existing MCP discovery server (not custom implementation)

**Options**:
- `mcp-community/discovery-server` (official reference)
- Consul with MCP adapter
- etcd with MCP adapter

**For BitBot**: Use existing MCP discovery server if available, otherwise minimal wrapper.

### 5.2 Discovery API

**List services**:
```http
GET /api/services?scope={global|workspace}&workspace={hash}

Response:
{
  "services": [
    {
      "id": "filesystem-a1b2c3d4",
      "name": "filesystem-mcp",
      "endpoint": "ws://mcp-filesystem-a1b2c3d4:9090/mcp",
      "capabilities": {...},
      "health": "healthy"
    }
  ]
}
```

**Register service**:
```http
POST /api/services

Request:
{
  "id": "my-service-abc123",
  "name": "my-custom-service",
  "scope": "workspace",
  "endpoint": "ws://my-service:9090/mcp",
  "capabilities": {...}
}
```

**Health check**:
```http
GET /api/services/{id}/health

Response:
{
  "id": "filesystem-a1b2c3d4",
  "status": "healthy",
  "last_check": "2025-10-17T12:35:00Z"
}
```

**Server-Sent Events** (real-time updates):
```http
GET /api/events

event: service.registered
data: {"id": "new-service", "name": "..."}

event: service.deregistered
data: {"id": "old-service"}
```

### 5.3 Health Checks

**Configuration**:
```yaml
# Discovery server config
health_checks:
  interval: 30s
  timeout: 10s
  retries: 3
  http:
    path: /health
    expected_status: 200
```

**Service implementation**:
```python
# Pseudocode
@app.get("/health")
def health():
  return {
    "status": "healthy",
    "service": "filesystem-mcp",
    "uptime_seconds": get_uptime()
  }
```

---

## 6. Custom MCP Services

### 6.1 Service Structure

```
workspace/
├── .bitbot/
│   └── services/
│       ├── my-custom-mcp/
│       │   ├── Dockerfile
│       │   ├── requirements.txt
│       │   ├── mcp_server.py
│       │   └── README.md
│       └── docker-compose.custom.yml
```

### 6.2 Service Template

**Dockerfile**:
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "mcp_server.py"]
```

**MCP Server** (pseudocode):
```python
from mcp_sdk import MCPServer, Tool

app = FastAPI()
mcp = MCPServer(name="my-custom-service")

@mcp.tool("analyze_code")
def analyze_code(file_path: str):
  # Implementation
  return {"quality_score": 85}

@app.get("/health")
def health():
  return {"status": "healthy"}

@app.websocket("/mcp")
def mcp_endpoint(websocket):
  mcp.handle_connection(websocket)

@app.on_event("startup")
def register():
  discovery_url = env("MCP_DISCOVERY_URL")
  workspace_hash = env("MCP_WORKSPACE_HASH")

  http_post(f"{discovery_url}/api/services", {
    "id": f"my-custom-{workspace_hash}",
    "endpoint": f"ws://my-custom-{workspace_hash}:9090/mcp",
    "capabilities": mcp.get_capabilities()
  })
```

**Compose file**:
```yaml
# .bitbot/services/docker-compose.custom.yml
services:
  my-custom-mcp:
    build: ./my-custom-mcp
    container_name: my-custom-mcp-${WORKSPACE_HASH}
    environment:
      - MCP_DISCOVERY_URL=http://mcp-discovery-workspace:8080
      - MCP_WORKSPACE_HASH=${WORKSPACE_HASH}
    networks:
      - mcp-workspace-${WORKSPACE_HASH}
    restart: unless-stopped

networks:
  mcp-workspace-${WORKSPACE_HASH}:
    external: true
```

**Start custom service**:
```bash
docker-compose -f .bitbot/services/docker-compose.custom.yml up -d
```

---

## 7. AI Agent Integration

### 7.1 Service Discovery

**From AI Agent** (pseudocode):
```javascript
workspace_hash = env("WORKSPACE_HASH")

// Query workspace discovery
response = fetch(`http://mcp-discovery-workspace:8080/api/services?workspace=${workspace_hash}`)
services = response.json().services

// Connect to services
for service in services:
  ws = WebSocket(service.endpoint)
  ws.send({
    "jsonrpc": "2.0",
    "method": "tools/list",
    "id": 1
  })
```

### 7.2 Tool Invocation

**Request**:
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "read_file",
    "arguments": {"path": "/workspace/src/main.py"}
  },
  "id": 123
}
```

**Response**:
```json
{
  "jsonrpc": "2.0",
  "result": {
    "content": [{"type": "text", "text": "def main():\n..."}]
  },
  "id": 123
}
```

---

## 8. Security & Access Control

### 8.1 Network Access Matrix

| Mode | Global MCP | Workspace MCP | Host Docker |
|------|-----------|--------------|-------------|
| **Work** | ✅ Network | ✅ Network | ❌ No |
| **Setup** | ✅ Network | ✅ Network | ✅ Socket |

**Key Points**:
- MCP services have NO direct filesystem access to devcontainer
- Communication is network-only (JSON-RPC over WebSocket)
- Services read workspace via explicit volume mounts
- Most services use read-only mounts for safety

### 8.2 Service Permissions

**Read-only filesystem** (default):
```yaml
volumes:
  - ${WORKSPACE_PATH}:/workspace:ro
```

**Why read-only?**
- AI agent requests file reads via MCP
- MCP service reads and returns content
- AI agent (in devcontainer) writes files directly
- Separation: Service = read, Agent = write

**Read-write exception** (trusted services only):
```yaml
# Example: git-safety needs write for commits
volumes:
  - ${WORKSPACE_PATH}:/workspace:rw
```

---

## 9. Operational Procedures

### 9.1 Deployment Workflow

**Step 1: Start global services** (one-time):
```bash
cd /opt/bitbot/global-mcp
docker-compose up -d
curl http://localhost:8080/api/services  # Verify
```

**Step 2: Start workspace** (automatic):
```bash
bitbot work  # Automatically starts workspace MCP services
```

**Step 3: Verify**:
```bash
# From devcontainer
curl http://mcp-discovery-workspace:8080/api/services
```

### 9.2 Troubleshooting

**Service not discovered**:
```bash
# Check running
docker ps | grep mcp-

# Check logs
docker logs mcp-filesystem-${hash}
docker logs mcp-discovery-workspace

# Test registration
curl -X POST http://localhost:9080/api/services -d '{...}'
```

**Service unhealthy**:
```bash
# Check health
curl http://mcp-filesystem-${hash}:9090/health

# Restart
docker-compose -f .bitbot/mcp/docker-compose.yml restart mcp-filesystem
```

**Network issues**:
```bash
# Verify networks
docker network ls | grep mcp

# Check connectivity
docker exec bitbot-dev-${hash} ping mcp-discovery-workspace
docker exec bitbot-dev-${hash} curl http://mcp-discovery-workspace:8080/health
```

---

## 10. Performance & Scaling

### 10.1 Resource Limits

**Per-service** (recommended):
```yaml
deploy:
  resources:
    limits:
      cpus: '0.5'
      memory: 256M
    reservations:
      cpus: '0.1'
      memory: 64M
```

**Resource totals**:
- Global services: ~512MB RAM, 0.6 CPU
- Per workspace: ~256MB RAM, 0.2 CPU
- 10 workspaces: ~3GB RAM total (within dev machine limits)

### 10.2 Scaling

**Service discovery load**:
- Global discovery: ~50 services (5 per workspace × 10 workspaces)
- Workspace discovery: ~5-10 services each
- HTTP/SSE based, minimal overhead

**Performance targets**:
- Service discovery query: < 100ms
- Tool invocation latency: < 500ms
- Health checks: < 10s
- Service registration: < 5s

---

## 11. Testing Strategy

### 11.1 Service Discovery Tests

- SD-01: Global services start successfully
- SD-02: Workspace services start successfully
- SD-03: Services register with discovery
- SD-04: Health checks function
- SD-05: Service deregistration on stop
- SD-06: SSE events stream correctly

### 11.2 Network Connectivity Tests

- NC-01: Devcontainer reaches global services
- NC-02: Devcontainer reaches workspace services
- NC-03: Services cannot reach devcontainer filesystem directly
- NC-04: Services can communicate with each other
- NC-05: Workspace network isolation (A cannot reach B)

### 11.3 MCP Protocol Tests

- MP-01: Tool invocation succeeds
- MP-02: Resource access works
- MP-03: Prompt retrieval works
- MP-04: Error handling (proper JSON-RPC errors)
- MP-05: Concurrent requests succeed

---

## 12. Success Criteria

**Functional**:
- [ ] Global MCP services start and register
- [ ] Workspace MCP services start per workspace
- [ ] Service discovery returns correct list
- [ ] AI agents invoke tools via MCP
- [ ] Custom services can be added
- [ ] Services accessible from both modes

**Performance**:
- [ ] Service discovery < 100ms
- [ ] Tool invocation < 500ms
- [ ] Health checks < 10s
- [ ] Service registration < 5s
- [ ] Total overhead: 512MB (global) + 256MB (per workspace)

**Reliability**:
- [ ] Services auto-restart on failure
- [ ] Discovery handles failures gracefully
- [ ] Health checks detect unhealthy services
- [ ] Network isolation prevents cross-workspace access
- [ ] Logs accessible for debugging

---

## 13. Implementation Phases

**Phase 1: Global Services**:
- Set up global MCP network
- Deploy discovery server
- Deploy git-helper, package-manager services
- Verify registration and health checks

**Phase 2: Workspace Services**:
- Generate workspace compose file
- Set up workspace network
- Deploy workspace discovery
- Deploy filesystem and git-safety services
- Test service discovery

**Phase 3: Integration**:
- Integrate with bitbot CLI
- Test AI agent discovery
- Test tool invocation
- Verify both modes access services
- Test custom service deployment

**Phase 4: Tooling**:
- `bitbot mcp list` command
- `bitbot mcp logs <service>` command
- `bitbot mcp restart <service>` command
- Service templates and documentation

---

## 14. References

**Related Specifications**:
- SPEC-01: Container Orchestration (sibling container architecture)
- SPEC-02: Security Mode System (network access per mode)
- SPEC-02A: Git Safety Integration (git-safety MCP service)
- SPEC-04: Session Management (AI agents access MCP)
- SPEC-05: Cross-Platform CLI (bitbot mcp commands)

**External Resources**:
- MCP Specification: https://modelcontextprotocol.io/specification/2024-11-05
- JSON-RPC 2.0: https://www.jsonrpc.org/specification
- Docker Compose Networking: https://docs.docker.com/compose/networking/

**Research Sources**:
- MCP_ARCHITECTURE_RESEARCH.md (protocol specification)
- User decision: Sibling containers + existing discovery server

---

**Status**: **Approved**
**Implementation Priority**: P0 (Blocking for AI agent functionality)
**Next Steps**: SPEC-04 (Session Management)
