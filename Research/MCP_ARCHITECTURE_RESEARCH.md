# Model Context Protocol (MCP) Architecture Research

## Executive Summary

This document provides comprehensive research on the Model Context Protocol (MCP), focusing on architecture patterns, implementation strategies, and best practices for building a dual-layer MCP system (global + workspace-specific) for BitBot. The research covers protocol specifications, service discovery, security, deployment patterns, and integration with AI agents.

---

## Table of Contents

1. [MCP Protocol Overview](#mcp-protocol-overview)
2. [Core Architecture](#core-architecture)
3. [Protocol Specification](#protocol-specification)
4. [Service Discovery & Registry Patterns](#service-discovery--registry-patterns)
5. [Tool Integration](#tool-integration)
6. [Resource Management](#resource-management)
7. [Prompt Templates](#prompt-templates)
8. [Transport Layers](#transport-layers)
9. [Security & Isolation](#security--isolation)
10. [Deployment Patterns](#deployment-patterns)
11. [Multi-Tenant Architecture](#multi-tenant-architecture)
12. [Docker Compose Patterns](#docker-compose-patterns)
13. [Client Integration (Claude & AI Agents)](#client-integration-claude--ai-agents)
14. [Error Handling & Resilience](#error-handling--resilience)
15. [Observability & Monitoring](#observability--monitoring)
16. [Production Best Practices](#production-best-practices)
17. [Implementation Recommendations for BitBot](#implementation-recommendations-for-bitbot)

---

## MCP Protocol Overview

### What is MCP?

The **Model Context Protocol (MCP)** is an open standard developed by Anthropic for connecting AI assistants to external data sources, tools, and services. It provides a standardized way to give LLMs access to the context they need.

**Key Benefits:**
- **Standardization**: Universal protocol for AI-to-system integration
- **Extensibility**: Support for custom tools, resources, and prompts
- **Modularity**: Connect multiple data sources and services
- **Security**: Built-in patterns for authorization and sandboxing

**Current Version:** `2025-06-18` (uses YYYY-MM-DD format)

**Official Resources:**
- Specification: https://modelcontextprotocol.io/specification/2025-06-18
- GitHub: https://github.com/modelcontextprotocol
- Documentation: https://modelcontextprotocol.io/

---

## Core Architecture

### Architectural Roles

MCP defines three primary architectural roles:

```
┌──────────────────────────────────────────────────────────┐
│                     MCP ARCHITECTURE                      │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────┐                                         │
│  │    HOST     │  (LLM applications: Claude Desktop,     │
│  │             │   IDEs, AI tools)                       │
│  └──────┬──────┘                                         │
│         │                                                 │
│         │  Initiates connections                         │
│         │                                                 │
│  ┌──────▼──────┐                                         │
│  │   CLIENT    │  (Protocol connector within host)       │
│  │             │  Maintains 1:1 connections to servers   │
│  └──────┬──────┘                                         │
│         │                                                 │
│         │  JSON-RPC 2.0 over transport                   │
│         │                                                 │
│  ┌──────▼──────────────────────────────────────────┐    │
│  │              MCP SERVERS                        │    │
│  │  (Expose capabilities via standardized protocol)│    │
│  │                                                  │    │
│  │  ├─ Server A (filesystem)                       │    │
│  │  ├─ Server B (database)                         │    │
│  │  ├─ Server C (API gateway)                      │    │
│  │  └─ Server N (custom tools)                     │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

**1. Hosts**
- LLM applications that initiate connections
- Examples: Claude Desktop, GitHub Copilot, VS Code
- Responsible for user authorization and data protection

**2. Clients**
- Connectors within host applications
- Maintain 1:1 stateful connections with servers
- Handle protocol negotiation and message routing

**3. Servers**
- Lightweight programs exposing specific capabilities
- Provide tools, resources, and prompts
- Can be local (stdio) or remote (HTTP/SSE)

---

## Protocol Specification

### Core Primitives

MCP servers offer three main primitives:

#### 1. **Tools**
Functions that AI agents can invoke to perform actions.

**Characteristics:**
- Executable functions with defined schemas
- Accept parameters validated via JSON Schema
- Return structured results or errors
- Require user approval (human-in-the-loop)

**Use Cases:**
- API calls
- System commands
- Data transformations
- File operations

#### 2. **Resources**
Context and data for users or AI models.

**Characteristics:**
- Read-only, addressable content
- Identified by URIs (file://, mysql://, custom://)
- Support text and binary (base64) formats
- Include MIME type for proper handling

**Use Cases:**
- Documents and files
- Database records
- Configuration data
- Logs and metrics

#### 3. **Prompts**
Templated messages and workflows.

**Characteristics:**
- Reusable interaction templates
- Support dynamic arguments
- Can reference resources
- Surface as UI elements (slash commands)

**Use Cases:**
- Code review templates
- Commit message generators
- Documentation prompts
- Workflow shortcuts

### Client Capabilities

MCP clients offer two main capabilities:

#### 1. **Roots**
Server inquiries into operational URI/filesystem boundaries.

**Purpose:**
- Define where servers can operate
- Enable workspace discovery
- Support dynamic scope updates

**Implementation:**
```
file:///workspace/project-a
file:///workspace/project-b
```

#### 2. **Sampling**
Server-initiated agentic behaviors and recursive LLM interactions.

**Purpose:**
- Enable servers to request LLM completions
- Support multi-step agentic workflows
- Allow recursive reasoning patterns

**Note:** Not yet supported in Claude Desktop or GitHub Copilot.

---

## Service Discovery & Registry Patterns

### Current State

**Challenge:** As the MCP ecosystem grows, discoverability is a significant challenge:
- Dozens of registries emerging weekly
- No agreed-upon standard for MCP server metadata
- Most third-party registries rely on GitHub scraping
- No canonical, centralized registry

### Registry Patterns

#### 1. **Client-Side Discovery**

```
┌──────────┐          ┌──────────────────┐
│          │  Query   │                  │
│  Client  ├─────────►│ Service Registry │
│          │◄─────────┤  (Eureka, Consul)│
└────┬─────┘ Location └──────────────────┘
     │
     │ Direct Connection
     │
     ▼
┌────────────┐
│ MCP Server │
└────────────┘
```

**Characteristics:**
- Client queries registry for available services
- Client maintains service locations
- Suitable for dynamic environments

**Example:** Netflix Eureka, Consul

#### 2. **Server-Side Discovery**

```
┌──────────┐          ┌──────────────┐
│          │  Request │              │
│  Client  ├─────────►│ Load Balancer│
│          │◄─────────┤   (Gateway)  │
└──────────┘ Response └──────┬───────┘
                              │
                              │ Queries registry
                              │
                   ┌──────────▼────────────┐
                   │   Service Registry    │
                   └──────────┬────────────┘
                              │
                    ┌─────────┼─────────┐
                    │         │         │
              ┌─────▼───┐ ┌──▼─────┐ ┌─▼───────┐
              │ Server  │ │ Server │ │ Server  │
              │    A    │ │   B    │ │    C    │
              └─────────┘ └────────┘ └─────────┘
```

**Characteristics:**
- Load balancer queries registry
- Client unaware of service instances
- Centralized routing and load balancing

**Example:** AWS ELB, Kubernetes Services

#### 3. **Azure API Center Pattern**

Azure API Center can serve as an inventory/registry of remote MCP servers:
- Centralized catalog of available MCP servers
- Metadata management (capabilities, endpoints, schemas)
- OAuth configuration for authorization
- Discovery API for clients

### Registry Schema Recommendations

For BitBot's dual-layer architecture, a registry should track:

```json
{
  "id": "server-unique-id",
  "name": "filesystem-server",
  "scope": "global|workspace",
  "description": "File system access server",
  "version": "1.0.0",
  "transport": "stdio|http|sse",
  "endpoint": "http://localhost:3000/mcp",
  "capabilities": {
    "tools": ["read_file", "write_file", "list_directory"],
    "resources": ["file://"],
    "prompts": ["code_review"]
  },
  "authentication": {
    "type": "oauth2|apikey|none",
    "required": true
  },
  "health_check": {
    "endpoint": "/health",
    "interval": 30000
  },
  "metadata": {
    "tags": ["filesystem", "workspace"],
    "docker_image": "bitbot/mcp-filesystem:latest"
  }
}
```

### Service Discovery Implementation Strategy

For BitBot:

1. **Global Registry**: Central service tracking all available MCP servers
2. **Workspace Registry**: Per-workspace service configurations
3. **Dynamic Registration**: Services self-register on startup
4. **Health Monitoring**: Periodic health checks with auto-deregistration
5. **Capability Query**: Clients can query available tools/resources
6. **Failover Support**: Track multiple instances for redundancy

---

## Tool Integration

### Tool Definition Schema

MCP tools are defined using JSON Schema for parameter validation:

```json
{
  "name": "read_file",
  "description": "Read the contents of a file",
  "inputSchema": {
    "type": "object",
    "properties": {
      "path": {
        "type": "string",
        "description": "Absolute path to the file"
      },
      "encoding": {
        "type": "string",
        "enum": ["utf-8", "base64"],
        "default": "utf-8"
      }
    },
    "required": ["path"]
  }
}
```

### Tool Invocation Flow

```
┌─────────┐                                        ┌────────────┐
│  Client │                                        │ MCP Server │
└────┬────┘                                        └─────┬──────┘
     │                                                   │
     │  1. tools/call                                    │
     │  {                                                │
     │    "name": "read_file",                           │
     │    "arguments": {                                 │
     │      "path": "/workspace/file.txt"                │
     │    }                                              │
     │  }                                                │
     ├──────────────────────────────────────────────────►│
     │                                                   │
     │                         2. Validate parameters    │
     │                         3. Execute tool           │
     │                         4. Return result          │
     │                                                   │
     │  {                                                │
     │    "content": [                                   │
     │      {                                            │
     │        "type": "text",                            │
     │        "text": "File contents here..."            │
     │      }                                            │
     │    ]                                              │
     │  }                                                │
     │◄──────────────────────────────────────────────────┤
     │                                                   │
```

### Parameter Validation Best Practices

**1. Never Trust Client Input**
- Always validate all inputs server-side
- Treat all client data as untrusted, even from AI models

**2. Use Allowlisting Over Blocklisting**
- Define exactly what is permitted
- More secure than trying to block malicious patterns

**3. Leverage JSON Schema**
```typescript
import { z } from "zod";

const ReadFileSchema = z.object({
  path: z.string().min(1).regex(/^\/workspace\/.+/),
  encoding: z.enum(["utf-8", "base64"]).default("utf-8")
});
```

**4. Validation Modes**

- **Flexible (Default)**: Coerce compatible inputs (e.g., "123" → 123)
- **Strict**: Reject any type mismatches
- Choose based on security requirements

**5. Error Responses**

Follow JSON-RPC 2.0 specification:
```json
{
  "jsonrpc": "2.0",
  "id": 123,
  "error": {
    "code": -32602,
    "message": "Invalid parameters",
    "data": {
      "details": "Path must start with /workspace/"
    }
  }
}
```

**Security Note:** Log full error details internally, but return sanitized errors to clients to prevent information leakage.

### Tool Execution Patterns

**1. Synchronous Execution**
- Simple request-response
- Suitable for fast operations (<2s)

**2. Asynchronous with Progress**
```json
// Initial request includes progress token
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "analyze_codebase",
    "arguments": { "path": "/workspace" }
  },
  "_meta": {
    "progressToken": "progress-123"
  }
}

// Server sends progress notifications
{
  "jsonrpc": "2.0",
  "method": "notifications/progress",
  "params": {
    "progressToken": "progress-123",
    "progress": 45,
    "total": 100
  }
}
```

**3. Cancellable Operations**
```json
// Client sends cancellation
{
  "jsonrpc": "2.0",
  "method": "notifications/cancelled",
  "params": {
    "requestId": 1,
    "reason": "User cancelled"
  }
}
```

---

## Resource Management

### Resource Schema

Resources are identified by URIs and contain either text or binary data:

```json
{
  "uri": "file:///workspace/README.md",
  "mimeType": "text/markdown",
  "text": "# Project Documentation\n\nWelcome to..."
}
```

```json
{
  "uri": "file:///workspace/image.png",
  "mimeType": "image/png",
  "blob": "iVBORw0KGgoAAAANSUhEUgAAA..." // base64
}
```

### URI Schemes

Common patterns for BitBot:

```
file:///workspace/[path]           - Local files
git://repo/[branch]/[path]         - Git repository content
db://[database]/[table]/[id]       - Database records
config://[service]/[key]           - Configuration values
memory://[namespace]/[key]         - In-memory cache
api://[service]/[endpoint]         - External API data
```

### URI Templates (RFC 6570)

Support parameterized resource access:

```json
{
  "uriTemplate": "file:///logs/{date}.log",
  "name": "daily_logs",
  "description": "Access logs by date",
  "mimeType": "text/plain"
}
```

Client usage:
```
GET file:///logs/2025-10-16.log
```

**Template Syntax:**
- Simple: `{variable}`
- Path: `{/path*}`
- Query: `{?param1,param2}`

### Resource Listing

Servers expose available resources:

```json
{
  "jsonrpc": "2.0",
  "method": "resources/list",
  "result": {
    "resources": [
      {
        "uri": "file:///workspace/config.json",
        "name": "Configuration",
        "description": "Project configuration file",
        "mimeType": "application/json"
      },
      {
        "uri": "db://analytics/users",
        "name": "User Database",
        "mimeType": "application/json"
      }
    ]
  }
}
```

### Resource Access Control

**Best Practices:**

1. **Validate URIs**: Ensure requested URIs are within allowed boundaries
2. **Check Roots**: Respect client-provided root boundaries
3. **Path Traversal Prevention**: Block `..` and absolute paths outside scope
4. **Audit Access**: Log all resource reads for security monitoring

```python
def validate_resource_access(uri: str, roots: List[str]) -> bool:
    """Validate resource URI against allowed roots."""
    parsed = urlparse(uri)

    if parsed.scheme != "file":
        # Custom validation for other schemes
        return validate_custom_scheme(parsed)

    path = parsed.path

    # Normalize to prevent path traversal
    normalized = os.path.normpath(path)

    # Check against roots
    for root in roots:
        if normalized.startswith(root):
            return True

    return False
```

---

## Prompt Templates

### Prompt Structure

Prompts are reusable templates with dynamic arguments:

```json
{
  "name": "git_commit",
  "description": "Generate a Git commit message",
  "arguments": [
    {
      "name": "changes",
      "description": "Summary of changes",
      "required": true
    },
    {
      "name": "type",
      "description": "Commit type (feat, fix, docs, etc.)",
      "required": false
    }
  ]
}
```

### Prompt Invocation

```json
{
  "jsonrpc": "2.0",
  "method": "prompts/get",
  "params": {
    "name": "git_commit",
    "arguments": {
      "changes": "Added user authentication",
      "type": "feat"
    }
  }
}
```

Response:
```json
{
  "jsonrpc": "2.0",
  "result": {
    "messages": [
      {
        "role": "user",
        "content": {
          "type": "text",
          "text": "Generate a commit message for:\n\nType: feat\nChanges: Added user authentication\n\nFollow conventional commits format."
        }
      }
    ]
  }
}
```

### Dynamic Prompt Patterns

**1. Resource Integration**
```json
{
  "name": "code_review",
  "arguments": [
    {
      "name": "file_uri",
      "description": "URI of file to review",
      "required": true
    }
  ]
}
```

Server can load resource content dynamically:
```python
async def get_code_review_prompt(file_uri: str):
    # Load file content
    file_content = await read_resource(file_uri)

    return {
        "messages": [
            {
                "role": "user",
                "content": {
                    "type": "text",
                    "text": f"Review this code:\n\n```\n{file_content}\n```"
                }
            }
        ]
    }
```

**2. Multi-Step Workflows**
```json
{
  "name": "feature_planning",
  "description": "Plan a new feature implementation",
  "arguments": [
    {
      "name": "feature_name",
      "required": true
    }
  ]
}
```

Can guide through architecture → implementation → testing phases.

### Prompt Best Practices

1. **Clear Instructions**: Provide unambiguous guidance about desired output
2. **Structured Output**: Define JSON schemas for expected responses
3. **Context Inclusion**: Reference relevant resources
4. **Argument Validation**: Validate all dynamic inputs
5. **UI Integration**: Design prompts to surface as slash commands

---

## Transport Layers

### Overview

MCP supports multiple transport mechanisms for client-server communication:

```
┌─────────────────────────────────────────────────────┐
│              TRANSPORT LAYERS                       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  1. STDIO (Standard Input/Output)                  │
│     ├─ Local subprocess communication              │
│     ├─ Newline-delimited JSON-RPC messages         │
│     └─ Best for: Local plugins, CLI tools          │
│                                                     │
│  2. Streamable HTTP (Current Standard)             │
│     ├─ HTTP POST for client→server                 │
│     ├─ SSE streams for server→client               │
│     └─ Best for: Remote services, web apps         │
│                                                     │
│  3. HTTP with SSE (Deprecated as of 2024-11-05)    │
│     ├─ Replaced by Streamable HTTP                 │
│     └─ Maintained for backward compatibility       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 1. STDIO Transport

**Characteristics:**
- Client launches server as subprocess
- JSON-RPC messages on stdin/stdout
- Messages delimited by newlines
- No embedded newlines allowed in messages
- stderr used for logging

**Connection Flow:**
```
┌────────┐                           ┌────────┐
│ Client │                           │ Server │
└───┬────┘                           └───┬────┘
    │                                    │
    │  1. Spawn subprocess               │
    ├───────────────────────────────────►│
    │                                    │
    │  2. Initialize (via stdin)         │
    │  {"jsonrpc":"2.0","method":...}    │
    ├───────────────────────────────────►│
    │                                    │
    │  3. Response (via stdout)          │
    │◄───────────────────────────────────┤
    │                                    │
```

**Configuration Example (Claude Desktop):**
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": ["/path/to/server/index.js"],
      "env": {
        "WORKSPACE_PATH": "/workspace"
      }
    }
  }
}
```

**Use Cases:**
- Local development tools
- CLI integrations
- Single-user desktop applications
- Trusted local processes

**Security Notes:**
- Server inherits client's permissions
- No network isolation
- Suitable only for trusted code

### 2. Streamable HTTP Transport

**Characteristics:**
- HTTP POST for client-to-server messages
- Optional SSE streams for server-to-client
- Supports stateful connections
- Web-friendly and firewall-traversable

**Endpoints:**

```
POST /mcp/v1/messages
  - Client sends requests
  - Returns JSON-RPC responses

GET /mcp/v1/sse
  - Establishes SSE stream
  - Server pushes notifications
  - Client provides session token
```

**Connection Flow:**
```
┌────────┐                           ┌────────┐
│ Client │                           │ Server │
└───┬────┘                           └───┬────┘
    │                                    │
    │  1. POST /mcp/v1/messages          │
    │     (initialize request)           │
    ├───────────────────────────────────►│
    │                                    │
    │  2. HTTP 200 (session token)       │
    │◄───────────────────────────────────┤
    │                                    │
    │  3. GET /mcp/v1/sse?token=...      │
    ├───────────────────────────────────►│
    │                                    │
    │  4. SSE stream established         │
    │◄───────────────────────────────────┤
    │                                    │
    │  5. POST /mcp/v1/messages          │
    │     (tool/resource requests)       │
    ├───────────────────────────────────►│
    │                                    │
    │  6. Server notifications via SSE   │
    │◄───────────────────────────────────┤
    │                                    │
```

**Request Format:**
```http
POST /mcp/v1/messages HTTP/1.1
Host: mcp-server.example.com
Content-Type: application/json
Authorization: Bearer <token>

{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "read_file",
    "arguments": {
      "path": "/workspace/file.txt"
    }
  }
}
```

**SSE Format:**
```
event: notification
data: {"jsonrpc":"2.0","method":"progress","params":{"progress":50}}

event: notification
data: {"jsonrpc":"2.0","method":"log","params":{"level":"info","message":"Processing..."}}
```

**Use Cases:**
- Remote MCP servers
- Multi-tenant services
- Cloud-hosted integrations
- Web-based AI applications

**Benefits:**
- Standard HTTP (works through firewalls)
- OAuth/JWT authentication support
- Load balancing compatible
- Scalable for production

### Transport Selection Guide

| Criteria | STDIO | Streamable HTTP |
|----------|-------|-----------------|
| **Deployment** | Local only | Local or Remote |
| **Isolation** | Process-level | Network-level |
| **Authentication** | Process ownership | OAuth/JWT/API Keys |
| **Scalability** | Single client | Multiple clients |
| **Firewall** | N/A | Traversable |
| **Latency** | Lowest | Low (network overhead) |
| **Use Case** | Desktop apps, CLI | Production services |

### Message Framing

All transports use JSON-RPC 2.0 format:

**Request:**
```json
{
  "jsonrpc": "2.0",
  "id": 123,
  "method": "tools/call",
  "params": { ... }
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 123,
  "result": { ... }
}
```

**Notification (no response expected):**
```json
{
  "jsonrpc": "2.0",
  "method": "notifications/progress",
  "params": { ... }
}
```

---

## Security & Isolation

### Security Model

MCP prioritizes connectivity over built-in security, **delegating access control to implementers**. This design choice requires careful security implementation.

### Key Security Principles

**1. Zero Trust Model**
- Never trust client input, even from AI models
- Validate all parameters server-side
- Treat every request as potentially malicious

**2. Least Privilege**
- Grant minimal permissions required
- Scope tokens to specific capabilities
- Time-limit access tokens

**3. Defense in Depth**
- Multiple security layers
- Fail securely by default
- Audit all access attempts

### Authentication & Authorization

#### OAuth 2.0 / OIDC (Recommended)

```
┌────────┐                 ┌──────────┐              ┌────────────┐
│ Client │                 │ Auth     │              │ MCP Server │
│        │                 │ Provider │              │            │
└───┬────┘                 └────┬─────┘              └─────┬──────┘
    │                           │                          │
    │ 1. Request authorization  │                          │
    ├──────────────────────────►│                          │
    │                           │                          │
    │ 2. User authenticates     │                          │
    │◄──────────────────────────┤                          │
    │                           │                          │
    │ 3. Authorization code     │                          │
    │◄──────────────────────────┤                          │
    │                           │                          │
    │ 4. Exchange for token     │                          │
    ├──────────────────────────►│                          │
    │                           │                          │
    │ 5. Access + Refresh token │                          │
    │◄──────────────────────────┤                          │
    │                           │                          │
    │ 6. API call with token    │                          │
    ├─────────────────────────────────────────────────────►│
    │                           │                          │
    │                           │  7. Validate token       │
    │                           │◄─────────────────────────┤
    │                           │                          │
    │                           │  8. Token valid          │
    │                           ├─────────────────────────►│
    │                           │                          │
    │                           │         9. Execute       │
    │                           │                          │
    │ 10. Response              │                          │
    │◄─────────────────────────────────────────────────────┤
    │                           │                          │
```

**Token Scoping:**
```json
{
  "access_token": "eyJhbGc...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "tools:read_file tools:write_file resources:workspace",
  "refresh_token": "eyJhbGc..."
}
```

**Server-Side Validation:**
```python
from jose import jwt

def validate_token(token: str) -> dict:
    """Validate JWT and extract claims."""
    try:
        payload = jwt.decode(
            token,
            public_key,
            algorithms=["RS256"],
            audience="mcp-server"
        )

        # Check expiration
        if payload["exp"] < time.time():
            raise AuthenticationError("Token expired")

        # Extract scopes
        scopes = payload.get("scope", "").split()

        return {
            "user_id": payload["sub"],
            "scopes": scopes,
            "tenant_id": payload.get("tenant_id")
        }
    except jwt.JWTError as e:
        raise AuthenticationError(f"Invalid token: {e}")

def require_scope(required_scope: str):
    """Decorator to enforce scope requirements."""
    def decorator(func):
        async def wrapper(request, *args, **kwargs):
            auth = request.headers.get("Authorization", "")
            token = auth.replace("Bearer ", "")

            claims = validate_token(token)

            if required_scope not in claims["scopes"]:
                raise PermissionError(f"Missing scope: {required_scope}")

            request.state.user_id = claims["user_id"]
            request.state.tenant_id = claims["tenant_id"]

            return await func(request, *args, **kwargs)
        return wrapper
    return decorator
```

#### API Key Authentication

For simpler scenarios:

```http
POST /mcp/v1/messages HTTP/1.1
Host: mcp-server.example.com
X-API-Key: mcp_sk_1234567890abcdef
Content-Type: application/json
```

**Best Practices:**
- Use cryptographically secure random keys
- Prefix keys for identification (e.g., `mcp_sk_`)
- Store hashed versions only
- Support key rotation
- Implement rate limiting per key

### Sandboxing

#### Docker Container Isolation

**Recommended Approach:**
Run each MCP server in isolated Docker containers with restricted privileges.

```yaml
# docker-compose.yml
services:
  mcp-filesystem:
    image: bitbot/mcp-filesystem:latest

    # Security constraints
    user: "10001:10001"  # Non-root user
    read_only: true      # Read-only root filesystem

    # Capability restrictions
    cap_drop:
      - ALL              # Drop all capabilities
    cap_add:
      - CHOWN            # Add only required capabilities
      - DAC_OVERRIDE

    # Resource limits
    mem_limit: 512m
    cpus: 0.5

    # Filesystem access (minimal)
    volumes:
      - /workspace/allowed:/workspace:ro  # Read-only mount
      - /tmp/mcp-cache:/tmp:rw           # Writable temp

    # Network isolation
    networks:
      - mcp-internal

    # Security options
    security_opt:
      - no-new-privileges:true
      - seccomp:unconfined

    environment:
      - ALLOWED_PATHS=/workspace
```

**Defense-in-Depth:**
1. **Container**: Isolated process space
2. **User**: Non-root execution
3. **Filesystem**: Read-only root + minimal mounts
4. **Network**: Restricted network access
5. **Capabilities**: Minimal Linux capabilities
6. **Resources**: CPU/memory limits

#### Process-Level Sandboxing

For STDIO transport:

```python
import subprocess
import os

def launch_mcp_server(command: list, workspace: str):
    """Launch MCP server with restricted permissions."""

    # Create restricted environment
    env = {
        "PATH": "/usr/bin:/bin",
        "HOME": "/tmp/mcp-home",
        "ALLOWED_PATH": workspace
    }

    # Launch with restrictions
    process = subprocess.Popen(
        command,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
        cwd="/tmp",
        preexec_fn=lambda: (
            os.setgid(10001),  # Drop to unprivileged GID
            os.setuid(10001)   # Drop to unprivileged UID
        )
    )

    return process
```

### Privilege Escalation Prevention

#### Common Vulnerabilities

**1. Path Traversal**
```python
# VULNERABLE
def read_file(path: str):
    return open(path).read()

# SECURE
def read_file(path: str, allowed_root: str):
    # Normalize path
    resolved = os.path.realpath(path)
    allowed = os.path.realpath(allowed_root)

    # Ensure within allowed root
    if not resolved.startswith(allowed):
        raise PermissionError("Access denied")

    return open(resolved).read()
```

**2. Command Injection**
```python
# VULNERABLE
def run_command(cmd: str):
    os.system(cmd)

# SECURE
def run_command(cmd: str, args: list):
    # Use subprocess with argument list (no shell)
    subprocess.run([cmd] + args, shell=False, check=True)
```

**3. OAuth Token Confusion**
```python
# VULNERABLE: Accepts any valid token
def authorize(token: str):
    return jwt.decode(token, verify=False)

# SECURE: Validates audience and issuer
def authorize(token: str):
    return jwt.decode(
        token,
        audience="mcp-server",
        issuer="https://auth.example.com",
        algorithms=["RS256"]
    )
```

#### Input Validation

```python
from typing import Any
import re

class InputValidator:
    """Comprehensive input validation."""

    @staticmethod
    def validate_path(path: str, allowed_patterns: list[str]) -> bool:
        """Validate file paths against allowlist."""
        # Reject dangerous patterns
        if ".." in path or path.startswith("/etc") or path.startswith("/sys"):
            return False

        # Check against allowlist
        for pattern in allowed_patterns:
            if re.match(pattern, path):
                return True

        return False

    @staticmethod
    def validate_command(cmd: str, allowed_commands: set[str]) -> bool:
        """Validate commands against allowlist."""
        return cmd in allowed_commands

    @staticmethod
    def sanitize_string(value: str, max_length: int = 1000) -> str:
        """Sanitize string inputs."""
        # Truncate
        value = value[:max_length]

        # Remove control characters
        value = "".join(c for c in value if c.isprintable() or c.isspace())

        return value
```

### Secrets Management

**Never store secrets in:**
- Code repositories
- Configuration files committed to git
- Environment variables in Dockerfiles
- Client-side code

**Recommended Approaches:**

**1. External Secret Stores**
```python
import boto3

def get_secret(secret_name: str) -> dict:
    """Retrieve secret from AWS Secrets Manager."""
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response["SecretString"])

# Usage
db_credentials = get_secret("bitbot/mcp/database")
```

**2. Docker Secrets**
```yaml
services:
  mcp-server:
    image: bitbot/mcp-server
    secrets:
      - db_password
      - api_key

secrets:
  db_password:
    external: true
  api_key:
    external: true
```

**3. Environment Variables (Runtime Only)**
```bash
# Load from secure store at runtime
export DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id db-pass --query SecretString --output text)
docker run -e DB_PASSWORD=$DB_PASSWORD mcp-server
```

### Security Checklist

- [ ] OAuth 2.0 / OIDC authentication implemented
- [ ] Token validation with audience/issuer checks
- [ ] Scope-based authorization enforced
- [ ] All inputs validated against allowlists
- [ ] Path traversal prevention in place
- [ ] Command injection prevention implemented
- [ ] Servers run in Docker with minimal privileges
- [ ] Non-root user enforced
- [ ] Read-only root filesystem
- [ ] Minimal Linux capabilities granted
- [ ] Resource limits configured (CPU/memory)
- [ ] Network access restricted
- [ ] Secrets stored in external secret manager
- [ ] Audit logging for all operations
- [ ] Rate limiting implemented
- [ ] Error messages sanitized (no internal info leakage)

---

## Deployment Patterns

### Local vs Remote Deployment

```
┌──────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT PATTERNS                        │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  LOCAL DEPLOYMENT                                            │
│  ┌────────────────────────────────────────────────┐         │
│  │  ┌──────────┐                                   │         │
│  │  │  Client  │                                   │         │
│  │  └────┬─────┘                                   │         │
│  │       │ STDIO (subprocess)                      │         │
│  │       │                                         │         │
│  │  ┌────▼────────┐  ┌────────────┐  ┌─────────┐ │         │
│  │  │ MCP Server  │  │ MCP Server │  │   MCP   │ │         │
│  │  │      A      │  │      B     │  │ Server  │ │         │
│  │  │(filesystem) │  │  (git)     │  │   C     │ │         │
│  │  └─────────────┘  └────────────┘  └─────────┘ │         │
│  │                                                 │         │
│  │  ✓ Full control                                │         │
│  │  ✓ No network latency                          │         │
│  │  ✓ Complete data privacy                       │         │
│  │  ✗ Single client only                          │         │
│  │  ✗ Manual updates required                     │         │
│  └─────────────────────────────────────────────────┘        │
│                                                               │
│  REMOTE DEPLOYMENT                                           │
│  ┌────────────────────────────────────────────────┐         │
│  │  ┌──────────┐      ┌──────────┐                │         │
│  │  │ Client A │      │ Client B │                │         │
│  │  └────┬─────┘      └────┬─────┘                │         │
│  │       │                 │                       │         │
│  │       │ HTTP/SSE        │ HTTP/SSE              │         │
│  │       │                 │                       │         │
│  │  ┌────▼─────────────────▼──────┐               │         │
│  │  │     Load Balancer            │               │         │
│  │  └──────┬──────────┬────────┬───┘               │         │
│  │         │          │        │                   │         │
│  │    ┌────▼────┐ ┌───▼───┐ ┌─▼─────┐             │         │
│  │    │  MCP    │ │  MCP  │ │  MCP  │             │         │
│  │    │ Server  │ │ Server│ │ Server│             │         │
│  │    │    1    │ │   2   │ │   3   │             │         │
│  │    └─────────┘ └───────┘ └───────┘             │         │
│  │                                                 │         │
│  │  ✓ Multi-client support                        │         │
│  │  ✓ Centralized updates                         │         │
│  │  ✓ Team collaboration                          │         │
│  │  ✓ Horizontal scaling                          │         │
│  │  ✗ Network latency                             │         │
│  │  ✗ Requires infrastructure                     │         │
│  └─────────────────────────────────────────────────┘        │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

### Docker-Based Deployment

#### Single Server Container

```dockerfile
# Dockerfile for MCP Server
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# Runtime stage
FROM node:20-alpine

# Security: Use non-root user
RUN addgroup -g 10001 mcp && \
    adduser -D -u 10001 -G mcp mcp

WORKDIR /app

# Copy from builder
COPY --from=builder --chown=mcp:mcp /app/dist ./dist
COPY --from=builder --chown=mcp:mcp /app/node_modules ./node_modules
COPY --from=builder --chown=mcp:mcp /app/package.json ./

USER mcp

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"

CMD ["node", "dist/index.js"]
```

#### Docker Compose Orchestration

```yaml
version: "3.9"

services:
  # Gateway/Load Balancer
  mcp-gateway:
    image: bitbot/mcp-gateway:latest
    ports:
      - "8080:8080"
    environment:
      - REGISTRY_URL=http://mcp-registry:5000
    depends_on:
      - mcp-registry
    networks:
      - mcp-public
      - mcp-internal
    restart: unless-stopped

  # Service Registry
  mcp-registry:
    image: bitbot/mcp-registry:latest
    ports:
      - "5000:5000"
    volumes:
      - registry-data:/data
    networks:
      - mcp-internal
    restart: unless-stopped

  # MCP Servers
  mcp-filesystem:
    image: bitbot/mcp-filesystem:latest
    volumes:
      - /workspace:/workspace:ro
    environment:
      - ALLOWED_PATHS=/workspace
      - REGISTRY_URL=http://mcp-registry:5000
      - SERVER_ID=filesystem-1
    networks:
      - mcp-internal
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: "0.5"
          memory: 512M

  mcp-database:
    image: bitbot/mcp-database:latest
    environment:
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=bitbot
      - REGISTRY_URL=http://mcp-registry:5000
      - SERVER_ID=database-1
    secrets:
      - db_password
    networks:
      - mcp-internal
      - db-network
    restart: unless-stopped

  mcp-git:
    image: bitbot/mcp-git:latest
    volumes:
      - /workspace/.git:/git:ro
    environment:
      - REGISTRY_URL=http://mcp-registry:5000
      - SERVER_ID=git-1
    networks:
      - mcp-internal
    restart: unless-stopped

networks:
  mcp-public:
    driver: bridge
  mcp-internal:
    driver: bridge
    internal: true
  db-network:
    driver: bridge

volumes:
  registry-data:

secrets:
  db_password:
    external: true
```

### Production Deployment Architectures

#### Architecture 1: Centralized Gateway

```
                         Internet
                            │
                            │
                    ┌───────▼────────┐
                    │  Load Balancer │
                    │   (AWS ALB)    │
                    └───────┬────────┘
                            │
              ┌─────────────┼─────────────┐
              │             │             │
        ┌─────▼──────┐ ┌────▼─────┐ ┌────▼──────┐
        │    MCP     │ │   MCP    │ │    MCP    │
        │  Gateway   │ │ Gateway  │ │  Gateway  │
        │     1      │ │    2     │ │     3     │
        └─────┬──────┘ └────┬─────┘ └────┬──────┘
              │             │             │
              └─────────────┼─────────────┘
                            │
                    ┌───────▼────────┐
                    │ Service Registry│
                    └───────┬────────┘
                            │
              ┌─────────────┼──────────────┐
              │             │              │
        ┌─────▼──────┐ ┌────▼──────┐ ┌────▼──────┐
        │MCP Server  │ │MCP Server │ │MCP Server │
        │    Pool    │ │   Pool    │ │   Pool    │
        │(Filesystem)│ │(Database) │ │   (Git)   │
        └────────────┘ └───────────┘ └───────────┘
```

**Characteristics:**
- Centralized authentication/authorization
- Unified API endpoint
- Request routing to appropriate servers
- Cross-cutting concerns (logging, rate limiting)

#### Architecture 2: Direct Service Access

```
                         Internet
                            │
                ┌───────────┼───────────┐
                │           │           │
         ┌──────▼─────┐ ┌───▼──────┐ ┌─▼────────┐
         │ Filesystem │ │ Database │ │   Git    │
         │    LB      │ │    LB    │ │   LB     │
         └──────┬─────┘ └───┬──────┘ └─┬────────┘
                │           │           │
         ┌──────▼─────┐ ┌───▼──────┐ ┌─▼────────┐
         │MCP Server  │ │MCP Server│ │MCP Server│
         │   Pool     │ │   Pool   │ │   Pool   │
         └────────────┘ └──────────┘ └──────────┘
```

**Characteristics:**
- Independent scaling per service
- Reduced latency (no gateway hop)
- Service-specific optimization
- More complex client configuration

#### Architecture 3: Multi-Region

```
       US-EAST-1                          EU-WEST-1
    ┌──────────────┐                  ┌──────────────┐
    │              │                  │              │
    │   ┌──────┐   │                  │   ┌──────┐   │
    │   │  LB  │   │                  │   │  LB  │   │
    │   └──┬───┘   │                  │   └──┬───┘   │
    │      │       │                  │      │       │
    │   ┌──▼────┐  │                  │   ┌──▼────┐  │
    │   │Gateway│  │                  │   │Gateway│  │
    │   └──┬────┘  │                  │   └──┬────┘  │
    │      │       │                  │      │       │
    │   ┌──▼────┐  │                  │   ┌──▼────┐  │
    │   │Servers│  │◄────Replication──┼───┤Servers│  │
    │   └───────┘  │                  │   └───────┘  │
    │              │                  │              │
    └──────────────┘                  └──────────────┘
```

**Characteristics:**
- Geographic distribution
- Reduced latency for global users
- High availability across regions
- Data replication considerations

### Kubernetes Deployment

```yaml
# mcp-server-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mcp-filesystem
  namespace: bitbot
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mcp-filesystem
  template:
    metadata:
      labels:
        app: mcp-filesystem
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        fsGroup: 10001

      containers:
      - name: mcp-server
        image: bitbot/mcp-filesystem:1.0.0

        ports:
        - containerPort: 3000
          name: http

        env:
        - name: ALLOWED_PATHS
          value: "/workspace"
        - name: REGISTRY_URL
          value: "http://mcp-registry:5000"

        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi

        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 30

        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 10

        volumeMounts:
        - name: workspace
          mountPath: /workspace
          readOnly: true

      volumes:
      - name: workspace
        persistentVolumeClaim:
          claimName: workspace-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: mcp-filesystem
  namespace: bitbot
spec:
  selector:
    app: mcp-filesystem
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: mcp-filesystem-hpa
  namespace: bitbot
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: mcp-filesystem
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Health Checks and Monitoring

```python
# health.py
from fastapi import FastAPI, Response
import time

app = FastAPI()

start_time = time.time()

@app.get("/health")
async def health_check():
    """Basic liveness check."""
    return {
        "status": "healthy",
        "uptime": time.time() - start_time
    }

@app.get("/ready")
async def readiness_check():
    """Readiness check with dependency validation."""
    checks = {
        "server": True,
        "registry": await check_registry_connection(),
        "dependencies": await check_dependencies()
    }

    if all(checks.values()):
        return {
            "status": "ready",
            "checks": checks
        }
    else:
        return Response(
            content=json.dumps({"status": "not_ready", "checks": checks}),
            status_code=503
        )

async def check_registry_connection() -> bool:
    """Check connection to service registry."""
    try:
        # Attempt connection
        response = await http_client.get(
            f"{REGISTRY_URL}/health",
            timeout=2.0
        )
        return response.status_code == 200
    except:
        return False

async def check_dependencies() -> bool:
    """Check external dependencies."""
    # Implementation specific
    return True
```

---

## Multi-Tenant Architecture

### Tenant Isolation Strategies

Multi-tenant MCP deployments require strict isolation to prevent data leakage between tenants.

```
┌────────────────────────────────────────────────────────────┐
│              MULTI-TENANT ARCHITECTURE                      │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                │
│  │ Client A │  │ Client B │  │ Client C │                │
│  │(Tenant 1)│  │(Tenant 2)│  │(Tenant 3)│                │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                │
│       │             │             │                        │
│       │ Tenant-ID: 1│ Tenant-ID: 2│ Tenant-ID: 3          │
│       │             │             │                        │
│  ┌────▼─────────────▼─────────────▼─────┐                 │
│  │       MCP Gateway / Auth Layer       │                 │
│  │  - Tenant identification              │                 │
│  │  - Token validation                   │                 │
│  │  - Scope enforcement                  │                 │
│  └────┬─────────────┬─────────────┬─────┘                 │
│       │             │             │                        │
│  ┌────▼─────────────▼─────────────▼─────┐                 │
│  │        Tenant Context Manager        │                 │
│  │  - Inject tenant_id into requests    │                 │
│  │  - Route to tenant-specific servers  │                 │
│  └────┬─────────────┬─────────────┬─────┘                 │
│       │             │             │                        │
│       │             │             │                        │
│  ┌────▼─────┐  ┌────▼─────┐  ┌───▼──────┐                │
│  │ Tenant 1 │  │ Tenant 2 │  │ Tenant 3 │                │
│  │  Data    │  │  Data    │  │  Data    │                │
│  └──────────┘  └──────────┘  └──────────┘                │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

### Isolation Approaches

#### 1. **Silo Model** (Dedicated Infrastructure)

```yaml
# Separate deployment per tenant
services:
  mcp-server-tenant1:
    image: bitbot/mcp-server:latest
    environment:
      - TENANT_ID=tenant-1
      - DB_NAME=bitbot_tenant1
    networks:
      - tenant1-network

  mcp-server-tenant2:
    image: bitbot/mcp-server:latest
    environment:
      - TENANT_ID=tenant-2
      - DB_NAME=bitbot_tenant2
    networks:
      - tenant2-network
```

**Pros:**
- Complete isolation
- Independent scaling
- Easier compliance (data residency)

**Cons:**
- Higher infrastructure cost
- More complex management
- Resource inefficiency

#### 2. **Pool Model** (Shared Infrastructure)

```python
# Shared servers with tenant context
class TenantContextMiddleware:
    async def __call__(self, request: Request, call_next):
        # Extract tenant ID from token
        token = request.headers.get("Authorization", "").replace("Bearer ", "")
        claims = validate_token(token)
        tenant_id = claims["tenant_id"]

        # Inject into request context
        request.state.tenant_id = tenant_id

        # Add to logging context
        with tenant_context(tenant_id):
            response = await call_next(request)

        return response

# Tenant-scoped data access
class DataRepository:
    async def get_resource(self, resource_id: str, tenant_id: str):
        # Automatic tenant filtering
        query = """
            SELECT * FROM resources
            WHERE id = $1 AND tenant_id = $2
        """
        return await db.fetch_one(query, resource_id, tenant_id)
```

**Pros:**
- Cost-effective
- Efficient resource utilization
- Simplified management

**Cons:**
- Risk of data leakage (if bugs exist)
- Noisy neighbor issues
- More complex code

#### 3. **Bridge Model** (Hybrid)

- Shared infrastructure for compute
- Isolated storage per tenant
- Best of both worlds

### Tenant Identification

#### HTTP Headers
```http
POST /mcp/v1/messages HTTP/1.1
Host: mcp.example.com
Authorization: Bearer eyJhbGc...
X-Tenant-ID: tenant-abc-123
Content-Type: application/json
```

#### JWT Claims
```json
{
  "sub": "user-123",
  "tenant_id": "tenant-abc-123",
  "scope": "tools:read resources:write",
  "iat": 1697472000,
  "exp": 1697475600
}
```

### Tenant-Scoped Operations

```python
from contextvars import ContextVar

# Global context variable for tenant ID
tenant_context_var: ContextVar[str] = ContextVar("tenant_id")

class TenantScopedService:
    """Base class for tenant-scoped services."""

    @property
    def tenant_id(self) -> str:
        """Get current tenant ID from context."""
        tenant_id = tenant_context_var.get(None)
        if not tenant_id:
            raise RuntimeError("No tenant context set")
        return tenant_id

    def ensure_tenant_access(self, resource_tenant_id: str):
        """Verify tenant has access to resource."""
        if self.tenant_id != resource_tenant_id:
            raise PermissionError(f"Tenant {self.tenant_id} cannot access resource")

class FileSystemService(TenantScopedService):
    """Tenant-scoped filesystem operations."""

    async def read_file(self, path: str) -> str:
        # Construct tenant-specific path
        tenant_path = f"/data/tenants/{self.tenant_id}{path}"

        # Validate path is within tenant boundary
        if not os.path.realpath(tenant_path).startswith(f"/data/tenants/{self.tenant_id}"):
            raise PermissionError("Path outside tenant boundary")

        return await async_read_file(tenant_path)

    async def list_files(self) -> List[str]:
        tenant_root = f"/data/tenants/{self.tenant_id}"
        return await async_list_directory(tenant_root)
```

### Database Isolation

#### Row-Level Security (PostgreSQL)

```sql
-- Enable row-level security
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;

-- Create policy for tenant isolation
CREATE POLICY tenant_isolation ON resources
    USING (tenant_id = current_setting('app.tenant_id')::uuid);

-- Grant access
GRANT ALL ON resources TO mcp_user;
```

Application usage:
```python
async def query_with_tenant_context(tenant_id: str, query: str):
    async with db.acquire() as conn:
        # Set tenant context
        await conn.execute(f"SET app.tenant_id = '{tenant_id}'")

        # Query automatically filtered by RLS
        result = await conn.fetch(query)

        return result
```

#### Schema-Per-Tenant

```python
def get_tenant_schema(tenant_id: str) -> str:
    """Get schema name for tenant."""
    return f"tenant_{tenant_id.replace('-', '_')}"

async def query_tenant_data(tenant_id: str, table: str):
    schema = get_tenant_schema(tenant_id)
    query = f"SELECT * FROM {schema}.{table}"
    return await db.fetch(query)
```

### Workspace-Specific MCP Servers

For BitBot's dual-layer architecture:

```yaml
# Global MCP servers (shared across workspaces)
global:
  servers:
    - name: auth-server
      scope: global
      image: bitbot/mcp-auth:latest

    - name: user-management
      scope: global
      image: bitbot/mcp-users:latest

# Workspace-specific MCP servers
workspace:
  servers:
    - name: filesystem
      scope: workspace
      image: bitbot/mcp-filesystem:latest
      config:
        allowed_paths:
          - /workspace/${WORKSPACE_ID}

    - name: database
      scope: workspace
      image: bitbot/mcp-database:latest
      config:
        database: bitbot_workspace_${WORKSPACE_ID}

    - name: git
      scope: workspace
      image: bitbot/mcp-git:latest
      config:
        repo_path: /workspace/${WORKSPACE_ID}/.git
```

Initialization flow:
```python
class WorkspaceManager:
    """Manage workspace-specific MCP servers."""

    async def initialize_workspace(self, workspace_id: str, config: dict):
        """Initialize MCP servers for a new workspace."""

        # Create workspace directory
        workspace_path = f"/data/workspaces/{workspace_id}"
        os.makedirs(workspace_path, exist_ok=True)

        # Launch workspace-specific servers
        servers = []
        for server_config in config["servers"]:
            if server_config["scope"] == "workspace":
                server = await self.launch_server(
                    workspace_id=workspace_id,
                    config=server_config
                )
                servers.append(server)

        # Register in workspace registry
        await self.registry.register_workspace(workspace_id, servers)

        return servers

    async def launch_server(self, workspace_id: str, config: dict):
        """Launch a workspace-specific MCP server."""

        # Substitute workspace ID in config
        env = {
            "WORKSPACE_ID": workspace_id,
            "ALLOWED_PATHS": f"/data/workspaces/{workspace_id}",
        }

        # Launch Docker container
        container = await docker_client.containers.run(
            image=config["image"],
            environment=env,
            volumes={
                f"/data/workspaces/{workspace_id}": {
                    "bind": f"/workspace",
                    "mode": "rw"
                }
            },
            network=f"workspace-{workspace_id}",
            labels={
                "bitbot.workspace": workspace_id,
                "bitbot.server": config["name"]
            },
            detach=True
        )

        return container
```

---

## Docker Compose Patterns

### MCP Gateway Pattern

Docker's MCP Gateway provides enterprise-ready orchestration for multiple MCP servers.

```yaml
# docker-compose.yml
version: "3.9"

services:
  # MCP Gateway (aggregates multiple servers)
  mcp-gateway:
    image: docker/mcp-gateway:latest
    ports:
      - "8080:8080"
    volumes:
      - ./gateway-config.yml:/config/gateway.yml:ro
    environment:
      - CONFIG_FILE=/config/gateway.yml
      - LOG_LEVEL=info
    networks:
      - mcp-public
      - mcp-internal
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 3s
      retries: 3

  # Individual MCP Servers
  mcp-filesystem:
    image: mcp/server-filesystem:latest
    volumes:
      - /workspace:/workspace:ro
    environment:
      - ALLOWED_PATHS=/workspace
    networks:
      - mcp-internal
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: "0.5"
          memory: 512M
      replicas: 2

  mcp-database:
    image: mcp/server-database:latest
    environment:
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=${DB_NAME}
    secrets:
      - db_password
    networks:
      - mcp-internal
      - db-network
    restart: unless-stopped

  mcp-git:
    image: mcp/server-git:latest
    volumes:
      - /workspace:/workspace:ro
    networks:
      - mcp-internal
    restart: unless-stopped

  # Supporting Services
  postgres:
    image: postgres:16-alpine
    environment:
      - POSTGRES_DB=bitbot
      - POSTGRES_USER=bitbot
    secrets:
      - db_password
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - db-network
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    networks:
      - mcp-internal
    restart: unless-stopped

networks:
  mcp-public:
    driver: bridge
  mcp-internal:
    driver: bridge
    internal: true
  db-network:
    driver: bridge

volumes:
  postgres-data:

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### Gateway Configuration

```yaml
# gateway-config.yml
gateway:
  port: 8080
  host: 0.0.0.0

  # Authentication
  auth:
    type: oauth2
    issuer: https://auth.example.com
    audience: mcp-gateway

  # Rate limiting
  rate_limit:
    enabled: true
    requests_per_minute: 100
    burst: 20

# MCP Server Configurations
servers:
  filesystem:
    url: http://mcp-filesystem:3000
    transport: http
    capabilities:
      - tools
      - resources
    health_check:
      endpoint: /health
      interval: 30s

  database:
    url: http://mcp-database:3000
    transport: http
    capabilities:
      - tools
      - resources
    health_check:
      endpoint: /health
      interval: 30s

  git:
    url: http://mcp-git:3000
    transport: http
    capabilities:
      - tools
      - resources
      - prompts
    health_check:
      endpoint: /health
      interval: 30s

# Routing Rules
routing:
  - match:
      tool: "read_file|write_file|list_directory"
    target: filesystem

  - match:
      tool: "db_query|db_execute"
    target: database

  - match:
      tool: "git_*"
    target: git

# Logging
logging:
  level: info
  format: json
  output: stdout
```

### MCP-Compose Tool

Alternative orchestration using `mcp-compose`:

```yaml
# mcp-compose.yml
version: "1.0"

# Global Configuration
config:
  log_level: info
  auth:
    enabled: true
    provider: oauth2

  proxy:
    port: 8080
    host: 0.0.0.0

# MCP Servers
servers:
  filesystem:
    image: bitbot/mcp-filesystem:latest
    transport: stdio
    command: ["node", "dist/index.js"]
    environment:
      ALLOWED_PATHS: /workspace
    volumes:
      - /workspace:/workspace:ro
    capabilities:
      tools:
        - read_file
        - write_file
        - list_directory
      resources:
        - file://

  database:
    image: bitbot/mcp-database:latest
    transport: http
    port: 3001
    environment:
      DB_HOST: postgres
      DB_NAME: bitbot
    secrets:
      - db_password
    capabilities:
      tools:
        - db_query
        - db_execute
      resources:
        - db://

  git:
    image: bitbot/mcp-git:latest
    transport: stdio
    command: ["python", "server.py"]
    volumes:
      - /workspace/.git:/git:ro
    capabilities:
      tools:
        - git_status
        - git_log
        - git_diff
      prompts:
        - commit_message
        - pr_description
```

### Dynamic Server Registration

```python
# server_registration.py
import aiohttp
import os

class ServerRegistry:
    """Auto-register MCP servers with gateway."""

    def __init__(self, gateway_url: str):
        self.gateway_url = gateway_url
        self.server_id = os.getenv("SERVER_ID")

    async def register(self, capabilities: dict):
        """Register server with gateway on startup."""

        registration = {
            "server_id": self.server_id,
            "endpoint": f"http://{os.getenv('HOSTNAME')}:3000",
            "transport": "http",
            "capabilities": capabilities,
            "health_check": {
                "endpoint": "/health",
                "interval": 30
            },
            "metadata": {
                "version": os.getenv("VERSION", "1.0.0"),
                "tags": os.getenv("TAGS", "").split(",")
            }
        }

        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.gateway_url}/register",
                json=registration
            ) as response:
                if response.status == 200:
                    print(f"Successfully registered server: {self.server_id}")
                else:
                    print(f"Failed to register: {await response.text()}")

    async def heartbeat(self):
        """Send periodic heartbeat to maintain registration."""
        while True:
            try:
                async with aiohttp.ClientSession() as session:
                    async with session.post(
                        f"{self.gateway_url}/heartbeat",
                        json={"server_id": self.server_id}
                    ) as response:
                        if response.status != 200:
                            print(f"Heartbeat failed: {await response.text()}")
            except Exception as e:
                print(f"Heartbeat error: {e}")

            await asyncio.sleep(30)

# Usage in server
async def main():
    registry = ServerRegistry(os.getenv("GATEWAY_URL"))

    # Register capabilities
    await registry.register({
        "tools": ["read_file", "write_file"],
        "resources": ["file://"],
        "prompts": []
    })

    # Start heartbeat
    asyncio.create_task(registry.heartbeat())

    # Start server
    await start_server()
```

---

## Client Integration (Claude & AI Agents)

### Claude Desktop Integration

#### Configuration

MCP servers are configured in Claude Desktop's configuration file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": ["/path/to/mcp-filesystem/index.js"],
      "env": {
        "ALLOWED_PATHS": "/Users/username/workspace"
      }
    },
    "database": {
      "command": "python",
      "args": ["/path/to/mcp-database/server.py"],
      "env": {
        "DB_HOST": "localhost",
        "DB_NAME": "bitbot"
      }
    },
    "remote-api": {
      "url": "https://mcp.example.com",
      "apiKey": "sk_live_..."
    }
  }
}
```

### MCP Client Implementation (Node.js)

```typescript
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { SSEClientTransport } from "@modelcontextprotocol/sdk/client/sse.js";

class MCPClient {
  private client: Client;

  constructor() {
    this.client = new Client(
      {
        name: "bitbot-client",
        version: "1.0.0",
      },
      {
        capabilities: {
          roots: {
            listChanged: true,
          },
          sampling: {},
        },
      }
    );
  }

  async connectStdio(command: string, args: string[]) {
    /**
     * Connect to local MCP server via stdio.
     */
    const transport = new StdioClientTransport({
      command,
      args,
      env: process.env,
    });

    await this.client.connect(transport);

    console.log("Connected via stdio");
  }

  async connectHTTP(url: string, apiKey?: string) {
    /**
     * Connect to remote MCP server via HTTP/SSE.
     */
    const transport = new SSEClientTransport(
      new URL(url),
      {
        headers: apiKey ? { "Authorization": `Bearer ${apiKey}` } : {},
      }
    );

    await this.client.connect(transport);

    console.log("Connected via HTTP/SSE");
  }

  async listTools() {
    /**
     * List available tools from server.
     */
    const response = await this.client.request(
      { method: "tools/list" },
      { timeout: 5000 }
    );

    return response.tools;
  }

  async callTool(name: string, args: Record<string, unknown>) {
    /**
     * Invoke a tool.
     */
    const response = await this.client.request(
      {
        method: "tools/call",
        params: {
          name,
          arguments: args,
        },
      },
      { timeout: 30000 }
    );

    return response.content;
  }

  async listResources() {
    /**
     * List available resources.
     */
    const response = await this.client.request(
      { method: "resources/list" },
      { timeout: 5000 }
    );

    return response.resources;
  }

  async readResource(uri: string) {
    /**
     * Read a resource.
     */
    const response = await this.client.request(
      {
        method: "resources/read",
        params: { uri },
      },
      { timeout: 10000 }
    );

    return response.contents;
  }

  async getPrompt(name: string, args: Record<string, string>) {
    /**
     * Get a prompt template.
     */
    const response = await this.client.request(
      {
        method: "prompts/get",
        params: {
          name,
          arguments: args,
        },
      },
      { timeout: 5000 }
    );

    return response.messages;
  }

  async setRoots(roots: string[]) {
    /**
     * Notify server of workspace roots.
     */
    await this.client.notification({
      method: "notifications/roots/list_changed",
      params: {
        roots: roots.map(r => ({ uri: r })),
      },
    });
  }

  async close() {
    /**
     * Close connection.
     */
    await this.client.close();
  }
}

// Usage Example
async function main() {
  const client = new MCPClient();

  // Connect to local server
  await client.connectStdio("node", ["./mcp-server/index.js"]);

  // Set workspace roots
  await client.setRoots([
    "file:///workspace/project-a",
    "file:///workspace/project-b",
  ]);

  // List tools
  const tools = await client.listTools();
  console.log("Available tools:", tools);

  // Call a tool
  const result = await client.callTool("read_file", {
    path: "/workspace/project-a/README.md",
  });
  console.log("Result:", result);

  // Close connection
  await client.close();
}
```

### Integration with AI Agent Frameworks

#### LangChain Integration

```python
from langchain.agents import Tool
from langchain.agents import initialize_agent
from langchain.llms import Anthropic
import asyncio
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

class MCPToolWrapper:
    """Wrap MCP tools for LangChain."""

    def __init__(self, server_params: StdioServerParameters):
        self.server_params = server_params
        self.session = None

    async def connect(self):
        """Establish connection to MCP server."""
        async with stdio_client(self.server_params) as (read, write):
            async with ClientSession(read, write) as session:
                await session.initialize()
                self.session = session

                # List available tools
                tools_result = await session.list_tools()
                return tools_result.tools

    def create_langchain_tools(self, mcp_tools):
        """Convert MCP tools to LangChain tools."""
        langchain_tools = []

        for mcp_tool in mcp_tools:
            def create_tool_func(tool_name):
                async def tool_func(**kwargs):
                    result = await self.session.call_tool(
                        tool_name,
                        arguments=kwargs
                    )
                    return result.content[0].text
                return tool_func

            langchain_tool = Tool(
                name=mcp_tool.name,
                func=lambda **kwargs, tn=mcp_tool.name: asyncio.run(
                    create_tool_func(tn)(**kwargs)
                ),
                description=mcp_tool.description,
            )
            langchain_tools.append(langchain_tool)

        return langchain_tools

# Usage
async def main():
    # Initialize MCP wrapper
    mcp = MCPToolWrapper(
        StdioServerParameters(
            command="node",
            args=["./mcp-server/index.js"],
        )
    )

    # Connect and get tools
    mcp_tools = await mcp.connect()
    langchain_tools = mcp.create_langchain_tools(mcp_tools)

    # Initialize LangChain agent
    llm = Anthropic(model="claude-3-5-sonnet-20241022")
    agent = initialize_agent(
        langchain_tools,
        llm,
        agent="zero-shot-react-description",
        verbose=True,
    )

    # Use agent
    result = agent.run("Read the README.md file")
    print(result)
```

#### PydanticAI Integration

```python
from pydantic_ai import Agent
from pydantic_ai.mcp import MCPClient

# PydanticAI has first-class MCP support
agent = Agent(
    model="claude-3-5-sonnet",
    system_prompt="You are a helpful assistant with access to filesystem tools.",
)

# Connect MCP servers
mcp_client = MCPClient()
await mcp_client.add_server(
    "filesystem",
    command="node",
    args=["./mcp-filesystem/index.js"],
)

# Agent automatically uses MCP tools
result = await agent.run_sync(
    "List all Python files in the workspace",
    mcp_client=mcp_client,
)
```

---

## Error Handling & Resilience

### Standard Error Codes

MCP uses JSON-RPC 2.0 error codes in the reserved range (-32768 to -32000):

| Code | Meaning | Description |
|------|---------|-------------|
| -32700 | Parse error | Invalid JSON received |
| -32600 | Invalid request | JSON-RPC request is invalid |
| -32601 | Method not found | Method does not exist |
| -32602 | Invalid params | Invalid method parameters |
| -32603 | Internal error | Internal JSON-RPC error |
| -32000 | Server error | Generic server error |
| -32001 | Request timeout | Operation timed out |
| -32002 | Resource not found | Requested resource not found |

### Error Response Format

```json
{
  "jsonrpc": "2.0",
  "id": 123,
  "error": {
    "code": -32602,
    "message": "Invalid parameters",
    "data": {
      "details": "Path must be within allowed boundaries",
      "field": "path",
      "value": "/etc/passwd"
    }
  }
}
```

### Retry Patterns

```python
import asyncio
import random
from typing import TypeVar, Callable, Optional

T = TypeVar("T")

class RetryStrategy:
    """Intelligent retry with exponential backoff."""

    def __init__(
        self,
        max_attempts: int = 3,
        base_delay: float = 1.0,
        max_delay: float = 60.0,
        exponential_base: float = 2.0,
        jitter: bool = True,
    ):
        self.max_attempts = max_attempts
        self.base_delay = base_delay
        self.max_delay = max_delay
        self.exponential_base = exponential_base
        self.jitter = jitter

    def calculate_delay(self, attempt: int) -> float:
        """Calculate delay for given attempt number."""
        # Exponential backoff
        delay = min(
            self.base_delay * (self.exponential_base ** attempt),
            self.max_delay
        )

        # Add jitter to prevent thundering herd
        if self.jitter:
            delay = delay * (0.5 + random.random())

        return delay

    async def execute(
        self,
        func: Callable[[], T],
        retryable_exceptions: tuple = (Exception,),
    ) -> T:
        """Execute function with retry logic."""
        last_exception = None

        for attempt in range(self.max_attempts):
            try:
                return await func()
            except retryable_exceptions as e:
                last_exception = e

                if attempt < self.max_attempts - 1:
                    delay = self.calculate_delay(attempt)
                    print(f"Attempt {attempt + 1} failed: {e}. Retrying in {delay:.2f}s...")
                    await asyncio.sleep(delay)
                else:
                    print(f"All {self.max_attempts} attempts failed.")

        raise last_exception

# Usage
retry = RetryStrategy(max_attempts=3, base_delay=1.0)

async def call_mcp_tool():
    return await client.call_tool("read_file", {"path": "/workspace/file.txt"})

try:
    result = await retry.execute(
        call_mcp_tool,
        retryable_exceptions=(TimeoutError, ConnectionError)
    )
except Exception as e:
    print(f"Failed after retries: {e}")
```

### Circuit Breaker Pattern

```python
import time
from enum import Enum

class CircuitState(Enum):
    CLOSED = "closed"       # Normal operation
    OPEN = "open"           # Failing, reject requests
    HALF_OPEN = "half_open" # Testing recovery

class CircuitBreaker:
    """Circuit breaker to prevent cascading failures."""

    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: float = 60.0,
        success_threshold: int = 2,
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.success_threshold = success_threshold

        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time = None

    async def call(self, func: Callable):
        """Execute function with circuit breaker protection."""

        # Check if circuit should transition from OPEN to HALF_OPEN
        if self.state == CircuitState.OPEN:
            if time.time() - self.last_failure_time >= self.recovery_timeout:
                self.state = CircuitState.HALF_OPEN
                self.success_count = 0
            else:
                raise Exception("Circuit breaker is OPEN")

        try:
            result = await func()
            self.on_success()
            return result
        except Exception as e:
            self.on_failure()
            raise e

    def on_success(self):
        """Handle successful call."""
        if self.state == CircuitState.HALF_OPEN:
            self.success_count += 1
            if self.success_count >= self.success_threshold:
                self.state = CircuitState.CLOSED
                self.failure_count = 0
        elif self.state == CircuitState.CLOSED:
            self.failure_count = 0

    def on_failure(self):
        """Handle failed call."""
        self.failure_count += 1
        self.last_failure_time = time.time()

        if self.state == CircuitState.HALF_OPEN:
            self.state = CircuitState.OPEN
        elif self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN

# Usage
breaker = CircuitBreaker(failure_threshold=5, recovery_timeout=60.0)

async def resilient_call():
    try:
        return await breaker.call(lambda: client.call_tool("read_file", {...}))
    except Exception as e:
        print(f"Circuit breaker prevented call or operation failed: {e}")
```

### Timeout Management

```python
import asyncio

async def with_timeout(coro, timeout: float, operation: str):
    """Execute coroutine with timeout."""
    try:
        return await asyncio.wait_for(coro, timeout=timeout)
    except asyncio.TimeoutError:
        raise TimeoutError(
            f"Operation '{operation}' timed out after {timeout}s"
        )

# Usage
result = await with_timeout(
    client.call_tool("expensive_operation", {...}),
    timeout=30.0,
    operation="expensive_operation"
)
```

### Error Logging

```python
import logging
import traceback
from datetime import datetime

class MCPErrorLogger:
    """Structured error logging for MCP operations."""

    def __init__(self, logger: logging.Logger):
        self.logger = logger

    def log_error(
        self,
        operation: str,
        error: Exception,
        context: dict = None,
    ):
        """Log error with full context."""
        error_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "operation": operation,
            "error_type": type(error).__name__,
            "error_message": str(error),
            "traceback": traceback.format_exc(),
            "context": context or {},
        }

        self.logger.error(
            f"MCP operation failed: {operation}",
            extra=error_data
        )

    def log_retry(self, operation: str, attempt: int, max_attempts: int):
        """Log retry attempt."""
        self.logger.warning(
            f"Retrying {operation} (attempt {attempt}/{max_attempts})"
        )

# Usage
error_logger = MCPErrorLogger(logging.getLogger("mcp"))

try:
    result = await client.call_tool("read_file", {"path": "/workspace/file.txt"})
except Exception as e:
    error_logger.log_error(
        operation="read_file",
        error=e,
        context={
            "tool": "read_file",
            "path": "/workspace/file.txt",
            "tenant_id": "tenant-123",
        }
    )
```

---

## Observability & Monitoring

### Logging Best Practices

**Critical Rule for MCP:**
- **STDIO transport**: MCP uses stdout exclusively for protocol communication
- **Always log to stderr** or external logging systems
- Never output to stdout except JSON-RPC messages

```python
import logging
import sys
import json

# Configure logging to stderr
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stderr  # CRITICAL: Use stderr, not stdout
)

logger = logging.getLogger("mcp-server")

# Structured logging
class StructuredLogger:
    """JSON-formatted structured logging."""

    def __init__(self, name: str):
        self.logger = logging.getLogger(name)

    def log(self, level: str, message: str, **kwargs):
        """Log with structured data."""
        log_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": level,
            "message": message,
            "server": os.getenv("SERVER_ID", "unknown"),
            **kwargs
        }

        # Output to stderr as JSON
        print(json.dumps(log_data), file=sys.stderr)

# Usage
structured_logger = StructuredLogger("mcp-filesystem")

structured_logger.log(
    "info",
    "Tool invoked",
    tool="read_file",
    path="/workspace/file.txt",
    tenant_id="tenant-123",
    request_id="req-456"
)
```

### OpenTelemetry Integration

```python
from opentelemetry import trace, metrics
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# Initialize tracing
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# Configure OTLP exporter
otlp_exporter = OTLPSpanExporter(
    endpoint="http://otel-collector:4317",
    insecure=True
)
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# Instrument FastAPI
FastAPIInstrumentor.instrument_app(app)

# Manual instrumentation
class MCPServerTracing:
    """Add tracing to MCP operations."""

    def __init__(self, tracer: trace.Tracer):
        self.tracer = tracer

    async def trace_tool_call(
        self,
        tool_name: str,
        arguments: dict,
        func: Callable,
    ):
        """Trace tool execution."""
        with self.tracer.start_as_current_span(
            f"mcp.tool.{tool_name}",
            attributes={
                "mcp.tool.name": tool_name,
                "mcp.tool.arguments": json.dumps(arguments),
            }
        ) as span:
            try:
                result = await func()
                span.set_status(trace.Status(trace.StatusCode.OK))
                return result
            except Exception as e:
                span.set_status(
                    trace.Status(
                        trace.StatusCode.ERROR,
                        str(e)
                    )
                )
                span.record_exception(e)
                raise

# Usage
tracer = MCPServerTracing(trace.get_tracer("mcp-server"))

@app.post("/mcp/tools/call")
async def call_tool(request: ToolCallRequest):
    return await tracer.trace_tool_call(
        request.tool_name,
        request.arguments,
        lambda: execute_tool(request)
    )
```

### Metrics Collection

```python
from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter

# Initialize metrics
metric_exporter = OTLPMetricExporter(
    endpoint="http://otel-collector:4317",
    insecure=True
)
metric_reader = PeriodicExportingMetricReader(
    metric_exporter,
    export_interval_millis=60000  # Export every 60s
)
meter_provider = MeterProvider(metric_readers=[metric_reader])
metrics.set_meter_provider(meter_provider)

# Create meters and instruments
meter = metrics.get_meter("mcp-server")

# Counters
tool_calls_counter = meter.create_counter(
    "mcp.tool.calls",
    description="Number of tool calls",
    unit="1"
)

tool_errors_counter = meter.create_counter(
    "mcp.tool.errors",
    description="Number of tool errors",
    unit="1"
)

# Histograms
tool_duration_histogram = meter.create_histogram(
    "mcp.tool.duration",
    description="Tool execution duration",
    unit="ms"
)

# Gauges
active_connections_gauge = meter.create_observable_gauge(
    "mcp.connections.active",
    description="Number of active connections",
    unit="1"
)

class MCPMetrics:
    """Collect MCP-specific metrics."""

    def __init__(self):
        self.active_connections = 0

    def record_tool_call(self, tool_name: str, duration_ms: float, error: bool = False):
        """Record tool call metrics."""
        attributes = {"tool": tool_name}

        tool_calls_counter.add(1, attributes)
        tool_duration_histogram.record(duration_ms, attributes)

        if error:
            tool_errors_counter.add(1, attributes)

    def increment_connections(self):
        self.active_connections += 1

    def decrement_connections(self):
        self.active_connections -= 1

# Register gauge callback
metrics_collector = MCPMetrics()

def get_active_connections(options):
    yield Observation(
        metrics_collector.active_connections,
        {}
    )

active_connections_gauge.set_callback(get_active_connections)
```

### Distributed Tracing

```python
from opentelemetry.propagate import extract, inject
from opentelemetry import baggage

class DistributedTracingMiddleware:
    """Propagate trace context across services."""

    async def __call__(self, request: Request, call_next):
        # Extract trace context from incoming request
        context = extract(request.headers)

        # Extract baggage (tenant_id, user_id, etc.)
        tenant_id = baggage.get_baggage("tenant_id", context)

        # Add to request state
        request.state.trace_context = context
        request.state.tenant_id = tenant_id

        # Process request
        response = await call_next(request)

        # Inject trace context into response
        inject(response.headers)

        return response

# When calling downstream services
async def call_downstream_service(url: str, data: dict):
    """Call another MCP server with trace propagation."""
    headers = {}
    inject(headers)  # Inject current trace context

    async with httpx.AsyncClient() as client:
        response = await client.post(url, json=data, headers=headers)
        return response.json()
```

### Health Checks

```python
from fastapi import FastAPI, Response
import asyncio

app = FastAPI()

class HealthChecker:
    """Comprehensive health checks."""

    def __init__(self):
        self.startup_time = time.time()

    async def check_registry(self) -> bool:
        """Check connection to service registry."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{REGISTRY_URL}/health",
                    timeout=2.0
                )
                return response.status_code == 200
        except:
            return False

    async def check_database(self) -> bool:
        """Check database connectivity."""
        try:
            await db.execute("SELECT 1")
            return True
        except:
            return False

    async def check_dependencies(self) -> dict:
        """Check all dependencies."""
        results = await asyncio.gather(
            self.check_registry(),
            self.check_database(),
            return_exceptions=True
        )

        return {
            "registry": results[0] if not isinstance(results[0], Exception) else False,
            "database": results[1] if not isinstance(results[1], Exception) else False,
        }

health_checker = HealthChecker()

@app.get("/health")
async def health():
    """Liveness probe - is the service running?"""
    return {
        "status": "healthy",
        "uptime": time.time() - health_checker.startup_time
    }

@app.get("/ready")
async def readiness():
    """Readiness probe - is the service ready to handle requests?"""
    checks = await health_checker.check_dependencies()

    if all(checks.values()):
        return {
            "status": "ready",
            "checks": checks
        }
    else:
        return Response(
            content=json.dumps({
                "status": "not_ready",
                "checks": checks
            }),
            status_code=503,
            media_type="application/json"
        )
```

---

## Production Best Practices

### 1. Configuration Management

```python
from pydantic import BaseSettings, Field
from typing import List

class MCPServerConfig(BaseSettings):
    """Production-ready configuration."""

    # Server
    server_id: str = Field(..., env="SERVER_ID")
    server_name: str = Field(..., env="SERVER_NAME")
    version: str = Field("1.0.0", env="VERSION")

    # Transport
    transport: str = Field("http", env="TRANSPORT")  # stdio|http
    host: str = Field("0.0.0.0", env="HOST")
    port: int = Field(3000, env="PORT")

    # Registry
    registry_url: str = Field(..., env="REGISTRY_URL")
    registry_enabled: bool = Field(True, env="REGISTRY_ENABLED")

    # Authentication
    auth_enabled: bool = Field(True, env="AUTH_ENABLED")
    auth_issuer: str = Field(..., env="AUTH_ISSUER")
    auth_audience: str = Field(..., env="AUTH_AUDIENCE")

    # Security
    allowed_paths: List[str] = Field(..., env="ALLOWED_PATHS")
    max_file_size: int = Field(10485760, env="MAX_FILE_SIZE")  # 10MB

    # Performance
    max_concurrent_requests: int = Field(100, env="MAX_CONCURRENT_REQUESTS")
    request_timeout: float = Field(30.0, env="REQUEST_TIMEOUT")

    # Logging
    log_level: str = Field("INFO", env="LOG_LEVEL")
    log_format: str = Field("json", env="LOG_FORMAT")

    # Observability
    otel_enabled: bool = Field(True, env="OTEL_ENABLED")
    otel_endpoint: str = Field("http://otel-collector:4317", env="OTEL_ENDPOINT")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

# Load configuration
config = MCPServerConfig()
```

### 2. Rate Limiting

```python
from fastapi import Request, HTTPException
import time
from collections import defaultdict

class RateLimiter:
    """Token bucket rate limiter."""

    def __init__(self, requests_per_minute: int = 60, burst: int = 10):
        self.rate = requests_per_minute / 60.0  # Per second
        self.burst = burst
        self.buckets = defaultdict(lambda: {"tokens": burst, "last_update": time.time()})

    def _refill(self, bucket: dict):
        """Refill tokens based on elapsed time."""
        now = time.time()
        elapsed = now - bucket["last_update"]
        bucket["tokens"] = min(
            self.burst,
            bucket["tokens"] + elapsed * self.rate
        )
        bucket["last_update"] = now

    def check(self, key: str) -> bool:
        """Check if request is allowed."""
        bucket = self.buckets[key]
        self._refill(bucket)

        if bucket["tokens"] >= 1:
            bucket["tokens"] -= 1
            return True

        return False

rate_limiter = RateLimiter(requests_per_minute=100, burst=20)

@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    # Extract identifier (API key, tenant ID, IP)
    identifier = request.state.tenant_id or request.client.host

    if not rate_limiter.check(identifier):
        raise HTTPException(
            status_code=429,
            detail="Rate limit exceeded"
        )

    return await call_next(request)
```

### 3. Request Validation

```python
from pydantic import BaseModel, validator
import re

class ToolCallRequest(BaseModel):
    """Validated tool call request."""

    tool_name: str
    arguments: dict

    @validator("tool_name")
    def validate_tool_name(cls, v):
        # Allowlist pattern
        if not re.match(r"^[a-z_][a-z0-9_]*$", v):
            raise ValueError("Invalid tool name format")
        return v

    @validator("arguments")
    def validate_arguments(cls, v):
        # Ensure no excessively large payloads
        serialized = json.dumps(v)
        if len(serialized) > 1000000:  # 1MB
            raise ValueError("Arguments too large")
        return v

@app.post("/mcp/tools/call")
async def call_tool(request: ToolCallRequest):
    """Call tool with validation."""
    # Additional validation
    if request.tool_name not in ALLOWED_TOOLS:
        raise HTTPException(status_code=404, detail="Tool not found")

    # Execute
    result = await execute_tool(request.tool_name, request.arguments)
    return result
```

### 4. Graceful Shutdown

```python
import signal

class GracefulShutdown:
    """Handle graceful shutdown."""

    def __init__(self):
        self.is_shutting_down = False
        self.active_requests = 0

        # Register signal handlers
        signal.signal(signal.SIGTERM, self.handle_sigterm)
        signal.signal(signal.SIGINT, self.handle_sigint)

    def handle_sigterm(self, signum, frame):
        """Handle SIGTERM."""
        print("Received SIGTERM, initiating graceful shutdown...")
        self.is_shutting_down = True

    def handle_sigint(self, signum, frame):
        """Handle SIGINT (Ctrl+C)."""
        print("Received SIGINT, initiating graceful shutdown...")
        self.is_shutting_down = True

    async def wait_for_requests(self, timeout: float = 30.0):
        """Wait for active requests to complete."""
        start = time.time()

        while self.active_requests > 0:
            if time.time() - start > timeout:
                print(f"Shutdown timeout, {self.active_requests} requests still active")
                break

            await asyncio.sleep(0.1)

        print("All requests completed")

shutdown_handler = GracefulShutdown()

@app.middleware("http")
async def track_requests(request: Request, call_next):
    if shutdown_handler.is_shutting_down:
        return Response(
            content="Server is shutting down",
            status_code=503
        )

    shutdown_handler.active_requests += 1
    try:
        response = await call_next(request)
        return response
    finally:
        shutdown_handler.active_requests -= 1

@app.on_event("shutdown")
async def on_shutdown():
    """Cleanup on shutdown."""
    # Deregister from registry
    await registry.deregister(config.server_id)

    # Wait for active requests
    await shutdown_handler.wait_for_requests()

    # Close connections
    await db.close()
```

### 5. Production Checklist

- [ ] **Configuration**
  - [ ] Environment-based configuration
  - [ ] Secrets externalized (no hardcoded credentials)
  - [ ] Configuration validation on startup

- [ ] **Security**
  - [ ] Authentication enabled (OAuth 2.0/API keys)
  - [ ] Authorization enforced (scope-based)
  - [ ] Input validation on all endpoints
  - [ ] Rate limiting implemented
  - [ ] HTTPS/TLS for remote servers

- [ ] **Observability**
  - [ ] Structured logging to stderr
  - [ ] OpenTelemetry tracing
  - [ ] Metrics collection
  - [ ] Health check endpoints
  - [ ] Distributed tracing propagation

- [ ] **Resilience**
  - [ ] Retry logic with exponential backoff
  - [ ] Circuit breakers for external dependencies
  - [ ] Timeout handling
  - [ ] Graceful shutdown

- [ ] **Deployment**
  - [ ] Docker containerization
  - [ ] Non-root user
  - [ ] Read-only filesystem (where possible)
  - [ ] Resource limits (CPU/memory)
  - [ ] Health checks configured
  - [ ] Auto-scaling policies

- [ ] **Monitoring**
  - [ ] Alerts for error rates
  - [ ] Alerts for latency
  - [ ] Alerts for resource usage
  - [ ] Dashboard for key metrics

- [ ] **Testing**
  - [ ] Unit tests
  - [ ] Integration tests
  - [ ] Load tests
  - [ ] Security tests

---

## Implementation Recommendations for BitBot

### Dual-Layer Architecture

BitBot should implement a **two-tier MCP architecture**:

```
┌────────────────────────────────────────────────────────┐
│                 BITBOT MCP ARCHITECTURE                 │
├────────────────────────────────────────────────────────┤
│                                                         │
│  LAYER 1: GLOBAL MCP SERVERS                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │  ┌───────────┐  ┌──────────┐  ┌──────────────┐ │  │
│  │  │   Auth    │  │   User   │  │   System     │ │  │
│  │  │  Server   │  │   Mgmt   │  │    Tools     │ │  │
│  │  └───────────┘  └──────────┘  └──────────────┘ │  │
│  │                                                  │  │
│  │  Shared across all workspaces                   │  │
│  │  - Authentication & authorization               │  │
│  │  - User management                              │  │
│  │  - System-level operations                      │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  LAYER 2: WORKSPACE-SPECIFIC MCP SERVERS               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Workspace A                                     │  │
│  │  ├─ Filesystem (scoped to /workspace/a)         │  │
│  │  ├─ Database (db: workspace_a)                   │  │
│  │  ├─ Git (repo: workspace_a)                      │  │
│  │  └─ Custom tools                                 │  │
│  │                                                  │  │
│  │  Workspace B                                     │  │
│  │  ├─ Filesystem (scoped to /workspace/b)         │  │
│  │  ├─ Database (db: workspace_b)                   │  │
│  │  ├─ Git (repo: workspace_b)                      │  │
│  │  └─ Custom tools                                 │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└────────────────────────────────────────────────────────┘
```

### Recommended Stack

**Language:** Python or TypeScript (both have official MCP SDKs)

**Frameworks:**
- **Python**: FastAPI + MCP Python SDK
- **TypeScript**: Express/Fastify + MCP TypeScript SDK

**Infrastructure:**
- **Orchestration**: Docker Compose (development), Kubernetes (production)
- **Gateway**: Docker MCP Gateway or custom FastAPI gateway
- **Registry**: Redis or PostgreSQL for service registry
- **Auth**: Keycloak or Auth0 for OAuth 2.0
- **Observability**: OpenTelemetry + Prometheus + Grafana
- **Logging**: Structured JSON logs to stderr + centralized logging (ELK/Loki)

### Directory Structure

```
bitbot/
├── mcp/
│   ├── gateway/                 # MCP Gateway
│   │   ├── Dockerfile
│   │   ├── main.py
│   │   ├── router.py
│   │   └── auth.py
│   │
│   ├── registry/                # Service Registry
│   │   ├── Dockerfile
│   │   ├── main.py
│   │   └── models.py
│   │
│   ├── servers/
│   │   ├── global/              # Global MCP servers
│   │   │   ├── auth/
│   │   │   ├── users/
│   │   │   └── system/
│   │   │
│   │   └── workspace/           # Workspace-specific servers
│   │       ├── filesystem/
│   │       ├── database/
│   │       └── git/
│   │
│   ├── sdk/                     # Shared SDK/utilities
│   │   ├── auth.py
│   │   ├── validation.py
│   │   └── tracing.py
│   │
│   └── docker-compose.yml       # Orchestration
│
├── docs/
│   └── mcp-architecture.md      # This document
│
└── config/
    ├── gateway.yml
    └── servers.yml
```

### Implementation Phases

#### Phase 1: Foundation (Weeks 1-2)
- [ ] Set up MCP SDK (Python or TypeScript)
- [ ] Implement basic MCP server (filesystem)
- [ ] Create service registry
- [ ] Implement stdio transport
- [ ] Test with Claude Desktop

#### Phase 2: Gateway & Authentication (Weeks 3-4)
- [ ] Build MCP Gateway
- [ ] Implement OAuth 2.0 authentication
- [ ] Add HTTP/SSE transport
- [ ] Implement rate limiting
- [ ] Add tenant isolation

#### Phase 3: Workspace Isolation (Weeks 5-6)
- [ ] Workspace manager
- [ ] Dynamic server provisioning
- [ ] Workspace-scoped servers (filesystem, database, git)
- [ ] Tenant-scoped data access

#### Phase 4: Production Readiness (Weeks 7-8)
- [ ] OpenTelemetry integration
- [ ] Comprehensive error handling
- [ ] Circuit breakers and retries
- [ ] Health checks
- [ ] Docker containerization
- [ ] Security hardening

#### Phase 5: Advanced Features (Weeks 9-10)
- [ ] Resource templates (RFC 6570)
- [ ] Prompt templates
- [ ] Sampling capability
- [ ] Multi-region support
- [ ] Auto-scaling

### Key Design Decisions

**1. Global vs Workspace Servers**

| Server Type | Scope | Examples | Rationale |
|-------------|-------|----------|-----------|
| Global | All workspaces | Auth, Users, System | Shared functionality, consistency |
| Workspace | Single workspace | Filesystem, Database, Git | Isolation, security, customization |

**2. Transport Selection**

- **Development**: STDIO (simpler, lower latency)
- **Production**: HTTP/SSE (scalable, multi-client, networkable)

**3. Authentication Strategy**

- **OAuth 2.0 with JWT** for remote servers
- **Process isolation** for stdio servers
- **Tenant ID in JWT claims** for multi-tenancy

**4. Service Discovery**

- **Centralized registry** (Redis or PostgreSQL)
- **Health-based routing**
- **Automatic deregistration** on failure

**5. Data Isolation**

- **Silo model** for workspaces (separate containers)
- **Row-level security** for shared databases
- **Filesystem isolation** via Docker volumes

### Sample Implementation: Filesystem Server

```python
# mcp/servers/workspace/filesystem/server.py
from mcp.server import Server
from mcp.server.stdio import stdio_server
import os
import json

server = Server("bitbot-filesystem")

@server.list_tools()
async def list_tools():
    """List available filesystem tools."""
    return [
        {
            "name": "read_file",
            "description": "Read file contents",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "path": {"type": "string"}
                },
                "required": ["path"]
            }
        },
        {
            "name": "write_file",
            "description": "Write file contents",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "path": {"type": "string"},
                    "content": {"type": "string"}
                },
                "required": ["path", "content"]
            }
        }
    ]

@server.call_tool()
async def call_tool(name: str, arguments: dict):
    """Execute filesystem tool."""
    allowed_root = os.getenv("ALLOWED_PATHS", "/workspace")

    if name == "read_file":
        path = arguments["path"]

        # Validate path
        if not validate_path(path, allowed_root):
            raise PermissionError("Access denied")

        # Read file
        with open(path, "r") as f:
            content = f.read()

        return {
            "content": [
                {"type": "text", "text": content}
            ]
        }

    elif name == "write_file":
        path = arguments["path"]
        content = arguments["content"]

        # Validate path
        if not validate_path(path, allowed_root):
            raise PermissionError("Access denied")

        # Write file
        with open(path, "w") as f:
            f.write(content)

        return {
            "content": [
                {"type": "text", "text": f"Successfully wrote to {path}"}
            ]
        }

def validate_path(path: str, allowed_root: str) -> bool:
    """Validate path is within allowed root."""
    resolved = os.path.realpath(path)
    allowed = os.path.realpath(allowed_root)
    return resolved.startswith(allowed)

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options()
        )

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
```

---

## Conclusion

The Model Context Protocol (MCP) provides a powerful, standardized approach to connecting AI agents with external tools and data sources. For BitBot's dual-layer architecture:

**Key Takeaways:**

1. **Modularity**: Separate global and workspace-specific servers for optimal isolation
2. **Security**: OAuth 2.0, Docker isolation, and input validation are critical
3. **Scalability**: HTTP transport, load balancing, and horizontal scaling for production
4. **Observability**: OpenTelemetry, structured logging, and comprehensive monitoring
5. **Resilience**: Retry logic, circuit breakers, and graceful degradation

**Next Steps:**

1. Review this document with the team
2. Decide on implementation language (Python vs TypeScript)
3. Begin Phase 1 (Foundation) implementation
4. Set up development environment with Docker Compose
5. Implement first MCP server (filesystem) and test with Claude Desktop

**Resources:**

- Official Specification: https://modelcontextprotocol.io/specification/2025-06-18
- Python SDK: https://github.com/modelcontextprotocol/python-sdk
- TypeScript SDK: https://github.com/modelcontextprotocol/typescript-sdk
- Community Servers: https://github.com/modelcontextprotocol/servers

---

*Document Version: 1.0*
*Last Updated: 2025-10-16*
*Author: Claude Code (Research Agent)*
