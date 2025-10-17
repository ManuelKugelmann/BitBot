# Shared MCP Tools

This directory contains shared MCP tool implementations that can be used by both global and workspace MCP services.

## Structure

Each tool should be in its own subdirectory with:
- `Dockerfile` - Container definition
- `requirements.txt` or equivalent dependency file
- Source code for the tool
- `README.md` - Tool-specific documentation

## Usage

Tools in this directory can be referenced by both global and workspace docker-compose files:

**Global services** (`mcp-services/global/docker-compose.yml`):
```yaml
services:
  my-tool:
    build:
      context: ../shared/tools/my-tool
    # ... global configuration
```

**Workspace services** (`mcp-services/workspace/docker-compose.yml`):
```yaml
services:
  workspace-my-tool:
    build:
      context: ../shared/tools/my-tool  # Same source!
    container_name: "workspace-my-tool-${WORKSPACE_HASH}"
    # ... workspace-specific configuration
```

## Example Tools

Potential tools to implement:
- `file-server` - File management and search
- `code-analyzer` - Code analysis and metrics
- `git-helper` - Git operations and history
- `test-runner` - Test execution and reporting
- `docs-generator` - Documentation generation

## Environment Variables

Tools should use environment variables to adapt behavior:
- `WORKSPACE_MODE=true/false` - Global vs workspace deployment
- `WORKSPACE_HASH` - Unique workspace identifier (workspace mode only)
- `REGISTRY_URL` - Service registry URL for registration