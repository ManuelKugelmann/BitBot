# Container Orchestration Strategy Specification

**Feature ID**: SPEC-01
**Priority**: P0 (Critical - Blocking)
**Status**: Approved
**Created**: 2025-10-16
**Last Updated**: 2025-10-17

---

## Executive Summary

This document specifies BitBot's container orchestration strategy using custom Docker/Compose with per-workspace containers and selective folder mounting. The approach provides a single safety policy: all infrastructure changes and experimental edits are protected by git push or local bundle backup. There are no runtime/container modes or mode switching. All protection is enforced by requiring a clean git state or a backup before allowing destructive or infrastructure-changing actions.

**Key Decision**: Per-workspace containers + selective `.bitbot/` mounting (protected vs public) = clean, simple isolation. All safety is enforced by git push/bundle, not container modes.

---

## 1. Problem Statement

BitBot needs a container orchestration layer that:
- Creates and manages development containers per workspace
- Supports VS Code DevContainer integration for all workflows
- Manages tmux sessions inside containers
- Orchestrates MCP services (global + workspace-specific)
- Supports parallel work + setup sessions
- Provides AI-assisted infrastructure changes with safety auditing

**Decision**: Per-workspace containers with git-based safety provide cleaner isolation than bind mount remounting or runtime mode switching.

---

## 2. Architecture Overview

### 2.1 Final Architecture

```
┌──────────────────────────────────────────────────────────────┐
│ Host Machine                                                  │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ BitBot CLI (bash)                                       │ │
│  │  - bitbot            → starts devcontainer (CLI)        │ │
│  │  - bitbot vscode   → starts devcontainer (VS Code)    │ │
│  └─────────────────────────────────────────────────────────┘ │
│                             ↓                                 │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ DevContainer (bitbot-dev-${WORKSPACE_HASH})            │  │
│  │                                                         │  │
│  │  User: root (UID 0)                                    │  │
│  │  Mount: /workspace/                  (read-write)      │  │
│  │  Mount: /workspace/.devcontainer/    (read-write, git-protected) │  │
│  │  Mount: /workspace/.bitbot/          (read-write)      │  │
│  │  NOT mounted: .bitbot/setup/         (invisible)       │  │
│  │                                                         │  │
│  │  Docker socket: Available (if approved)                 │  │
│  │  MCP network: Access                                   │  │
│  │  VS Code: Can attach ✓                                 │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                               │
│  All safety is enforced by git push/bundle, not container modes│
└──────────────────────────────────────────────────────────────┘
```

### 2.2 Folder Structure

```
workspace/
├── .devcontainer/              # Devcontainer config
│   ├── devcontainer.json       # Read-only in work, read-write in setup
│   └── Dockerfile
│
├── .bitbot/                    # Mounted in both containers
│   ├── setup/                  # NOT mounted (BitBot internals)
│   │   ├── Dockerfile          # Setup container definition
│   │   └── scripts/            # Setup container scripts
│   │
│   ├── logs/                   # Logs (accessible in both modes)
│   │   └── mode-changes.log
│   ├── sessions/               # Session state
│   └── state/                  # BitBot state
│
└── src/                        # Source code
```



---

## 3. Implementation Specification





### 3.3 Setup Container Definition

```dockerfile
# .bitbot/setup/Dockerfile

FROM ubuntu:22.04

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    zsh \
    tmux \
    git \
    fzf \
    docker-compose \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install BitBot setup scripts
COPY scripts/entrypoint-setup.sh /opt/bitbot/entrypoint-setup.sh
COPY scripts/setup-audit.sh /opt/bitbot/setup-audit.sh
COPY scripts/setup-apply.sh /opt/bitbot/setup-apply.sh
RUN chmod +x /opt/bitbot/*.sh

# Install AI agent tools
# (Claude Code, etc.)

WORKDIR /setup/workspace

ENTRYPOINT ["/opt/bitbot/entrypoint-setup.sh"]
CMD ["/bin/zsh"]
```

### 3.4 Setup Entrypoint Script

```bash
#!/bin/bash
# .bitbot/setup/scripts/entrypoint-setup.sh

set -e

echo "BitBot Setup Container Starting..."
echo "Workspace: /setup/workspace"

# Ensure we're in the workspace
cd /setup/workspace

# Git safety check
if [ -d ".git" ]; then
    echo ""
    echo "=== Git Safety Check ==="
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "⚠ WARNING: Uncommitted changes detected"
        echo "  Consider committing before modifying .devcontainer"
    fi
    echo "========================"
    echo ""
fi

# Display setup mode info
cat <<EOF

=== BitBot Setup Mode ===

You can modify:
  - .devcontainer/ configuration
  - All workspace files
  - .bitbot/ (logs, sessions, state)

Note: .bitbot/setup/ is managed by BitBot scripts only

Available commands:
  bitbot-audit-setup   - AI safety audit of changes
  bitbot-apply-setup   - Apply changes to work container

AI Assistant: Ready to help with devcontainer setup
VS Code: This container is VS Code compatible

========================

EOF

# Log startup
TIMESTAMP=$(date -Iseconds)
mkdir -p .bitbot/logs
echo "[$TIMESTAMP] Setup container started" >> .bitbot/logs/mode-changes.log

# Start tmux session
exec tmux new-session -A -s bitbot-setup
```

### 3.5 Safety Audit Script

```bash
#!/bin/bash
# .bitbot/setup/scripts/setup-audit.sh

set -e

echo "=== BitBot Setup Safety Audit ==="
echo ""

cd /setup/workspace

# Check if .devcontainer exists
if [ ! -d ".devcontainer" ]; then
    echo "✓ No .devcontainer changes detected"
    exit 0
fi

# Check for uncommitted changes in .devcontainer
if git diff --quiet .devcontainer 2>/dev/null; then
    echo "✓ No .devcontainer changes detected"
    exit 0
fi

echo "Changes detected in .devcontainer/"
echo ""

# Show diff
echo "--- Changes ---"
git diff .devcontainer
echo ""

# AI-assisted audit
echo "--- AI Safety Audit ---"
# TODO: Integrate with Claude Code or other AI agent
# claude-code "Review these .devcontainer changes for security issues"

echo ""
echo "--- Manual Review Required ---"
echo "Please review the changes above and verify:"
echo "  1. No security vulnerabilities introduced"
echo "  2. No breaking changes to development workflow"
echo "  3. Configuration is valid"
echo ""
echo "Run 'bitbot-apply-setup' to apply changes after review"
```

### 3.6 Setup Apply Script

```bash
#!/bin/bash
# .bitbot/setup/scripts/setup-apply.sh

set -e

echo "=== BitBot Setup Apply ==="
echo ""

cd /setup/workspace

# Verify changes exist
if git diff --quiet .devcontainer 2>/dev/null; then
    echo "No changes to apply"
    exit 0
fi

# Confirmation
read -p "Apply .devcontainer changes to work container? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Commit changes
git add .devcontainer
git commit -m "Setup: Update .devcontainer configuration

Applied via bitbot-setup at $(date -Iseconds)"

echo "✓ Changes committed"
echo ""

# Rebuild work container
echo "Rebuilding work container..."
WORKSPACE_HASH=$(echo -n "$(pwd)" | sha256sum | cut -c1-8)

# Stop work container if running
docker stop "bitbot-dev-$WORKSPACE_HASH" 2>/dev/null || true

# Rebuild
docker-compose -f docker-compose.work.yml build

echo "✓ Work container rebuilt"
echo ""
echo "Run 'bitbot work' to start the updated container"
```

### 3.7 Host CLI Commands

```bash
#!/bin/bash
# bitbot CLI (on host)

COMMAND=${1:-work}
WORKSPACE="$PWD"
WORKSPACE_HASH=$(echo -n "$WORKSPACE" | sha256sum | cut -c1-8)

export WORKSPACE_PATH="$WORKSPACE"
export WORKSPACE_HASH="$WORKSPACE_HASH"

# Ensure .bitbot structure exists
mkdir -p "$WORKSPACE/.bitbot/setup"
mkdir -p "$WORKSPACE/.bitbot/logs"
mkdir -p "$WORKSPACE/.bitbot/sessions"
mkdir -p "$WORKSPACE/.bitbot/state"

case "$COMMAND" in
    work)
        echo "Starting WORK mode..."

        # Check if vscode flag
        if [ "$2" = "vscode" ]; then
            # Start work container
            docker-compose -f docker-compose.work.yml up -d

            # Open in VS Code
            code --remote "attach-container+bitbot-dev-$WORKSPACE_HASH" /workspace
        else
            # Start work container
            docker-compose -f docker-compose.work.yml up -d

            # Attach to CLI
            docker exec -it "bitbot-dev-$WORKSPACE_HASH" /bin/zsh
        fi
        ;;

    setup)
        echo "Starting SETUP mode..."

        # Check if vscode flag
        if [ "$2" = "vscode" ]; then
            # Start setup container
            docker-compose -f docker-compose.setup.yml up -d

            # Open in VS Code
            code --remote "attach-container+bitbot-setup-$WORKSPACE_HASH" /setup/workspace
        else
            # Start setup container
            docker-compose -f docker-compose.setup.yml up -d

            # Attach to CLI
            docker exec -it "bitbot-setup-$WORKSPACE_HASH" /bin/zsh
        fi
        ;;

    *)
        echo "Unknown command: $COMMAND"
        echo "Usage: bitbot {work|setup} [vscode]"
        exit 1
        ;;
esac
```

---

## 4. Key Benefits

### 4.1 vs Bind Mount Remounting Approach

| Aspect | Bind Mount Remounting | Per-Workspace Setup Container |
|--------|----------------------|-------------------------------|
| **Complexity** | Medium (CAP_SYS_ADMIN needed) | Low (standard volumes) |
| **Isolation** | Good (.devcontainer read-only) | Excellent (.bitbot/protected invisible) |
| **Setup Container** | Same container, different mode | Separate container per workspace |
| **VS Code** | Single container | Both containers VS Code compatible |
| **Parallel Sessions** | Sequential only | Work + Setup simultaneously |
| **AI Assistant** | Generic | Specialized for setup tasks |
| **Safety Audit** | Manual | Built-in workflow |

**Winner**: Per-workspace setup container approach ✓



---

## 5. Workflow Examples







---



---

## 7. References

**Related Specifications**:
- SPEC-00: Architectural Decisions
- SPEC-02: Security Mode System (folder structure)
- SPEC-03: MCP Service Architecture
- SPEC-05: Cross-Platform CLI

---

## 8. Decision Log

| Date | Decision | Rationale | Status |
|------|----------|-----------|--------|
| 2025-10-16 | Initial: Bind mount remounting | Simpler than multiple users | Superseded |
| 2025-10-17 | Updated: Per-workspace setup container | User suggestion: simpler, better isolation | **Approved** ✅ |

---

**Status**: **Approved**
**Implementation Priority**: P0 (Blocking for MVP)
**Next Steps**: Implement SPEC-02 (folder structure, safety audit)
