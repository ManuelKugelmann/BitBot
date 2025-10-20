# Container Workspace Isolation & Permission Strategies
**Research Report for BitBot Development Environment**
**Date**: October 16, 2025
**Focus**: Multi-mode containerized development with sketch/work/setup permission levels

> **⚠️ HISTORICAL DOCUMENT**: This research explored a three-mode system (sketch/work/setup).
> **FINAL DECISION (2025-10-17)**: Sketch mode was **removed** from BitBot design.
> Current implementation uses **two modes only** (work/setup) with **Git-based safety** instead.
> See **SPEC-02A (Git Safety Integration)** and **D-11 (Mode Count Decision)** for rationale.
> This research remains valuable for understanding container isolation techniques.

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Mount Modes & Volume Management](#mount-modes--volume-management)
3. [Linux Namespaces for Isolation](#linux-namespaces-for-isolation)
4. [Capabilities & Security Profiles](#capabilities--security-profiles)
5. [User Mapping Strategies](#user-mapping-strategies)
6. [Multi-Mode Architecture Patterns](#multi-mode-architecture-patterns)
7. [Filesystem Restrictions](#filesystem-restrictions)
8. [Safety Patterns & Recovery](#safety-patterns--recovery)
9. [Production Examples](#production-examples)
10. [Implementation Recommendations for BitBot](#implementation-recommendations-for-bitbot)

---

## Executive Summary

This report provides comprehensive research on containerized workspace isolation and permission strategies, specifically addressing BitBot's need for three distinct security modes (sketch, work, setup) using the same container architecture. Key findings include:

- **Multi-mode containers** are achievable through layered security controls (mount options, capabilities, namespaces)
- **User namespace mapping** enables rootless containers with proper UID/GID alignment
- **Read-only root filesystems** with selective tmpfs mounts provide strong isolation
- **AppArmor/SELinux** profiles offer mandatory access control for enhanced security
- **Recovery patterns** using overlay filesystems and snapshots enable safe experimentation

### Quick Reference: BitBot Mode Mapping

| Mode | Write Access | Read Access | Network | Docker Access | Implementation Strategy |
|------|-------------|-------------|---------|---------------|------------------------|
| **Sketch** | `/workspace/sketch/` only | Full workspace (RO) | AI agent + MCP only | None | Bind mount RO + RW overlay |
| **Work** | Full workspace (except `.devcontainer/`) | Full workspace | Standard + MCP | Isolated DinD | Selective RO mounts |
| **Setup** | Full container | Full system | Unrestricted | Full DinD | Privileged mode |

---

## 1. Mount Modes & Volume Management

### 1.1 Bind Mounts vs. Volumes

Docker provides two primary storage mechanisms for persisting data and sharing files between host and containers:

#### **Bind Mounts**
- **Definition**: A file or directory on the host machine is mounted into a container
- **Characteristics**:
  - Files maintain exact host permissions (UID/GID preserved)
  - Changes are immediately reflected on both host and container
  - Direct access to host filesystem structure
  - Performance: Native filesystem speed

#### **Volumes**
- **Definition**: Docker creates and manages a directory within Docker's storage directory
- **Characteristics**:
  - Managed by Docker daemon
  - By default owned by root inside container
  - Better performance on Windows/macOS (especially Docker Desktop)
  - Easier to backup and migrate

#### **Best Practice for BitBot**: Use bind mounts for workspace access (matches VS Code DevContainer behavior) and volumes for internal state/cache.

### 1.2 Read-Only vs Read-Write Mount Modes

#### **Syntax Options**

**Short syntax** (legacy `-v` flag):
```bash
docker run -v /host/path:/container/path:ro myimage    # Read-only
docker run -v /host/path:/container/path:rw myimage    # Read-write (default)
```

**Long syntax** (recommended `--mount` flag):
```bash
docker run --mount type=bind,source=/host/path,target=/container/path,readonly myimage
docker run --mount type=bind,source=/host/path,target=/container/path myimage  # RW default
```

#### **Docker Compose Syntax**

```yaml
services:
  app:
    volumes:
      # Short syntax
      - /host/path:/container/path:ro

      # Long syntax (preferred)
      - type: bind
        source: /host/path
        target: /container/path
        read_only: true
```

### 1.3 Mount Propagation

Mount propagation controls whether mounts created within a bind-mount are propagated to replicas of that mount.

#### **Propagation Modes**

| Mode | Direction | Description | Use Case |
|------|-----------|-------------|----------|
| **rprivate** | None | Mount isolation (default) | Standard containers |
| **private** | None | Legacy rprivate | Older systems |
| **rshared** | Bidirectional | Mounts propagate both ways | Docker-in-Docker |
| **shared** | Bidirectional | Legacy rshared | |
| **rslave** | Host → Container | Container sees host mounts only | Read-only host access |
| **slave** | Host → Container | Legacy rslave | |

#### **Example: Docker-in-Docker with Propagation**

```yaml
services:
  docker-in-docker:
    image: docker:dind
    privileged: true
    volumes:
      - type: bind
        source: /var/run/docker.sock
        target: /var/run/docker.sock
        bind:
          propagation: rshared  # Required for DinD
```

### 1.4 Permission Handling with Bind Mounts

**Critical Concept**: When using bind mounts, files maintain their host permissions. The container user must have a matching UID/GID or be in the appropriate group to access files.

#### **Common Permission Issues**

1. **Root ownership inside container**: Docker volumes default to root ownership
2. **UID mismatch**: Host UID 1000 may not exist in container
3. **Group access**: Container user may not be in the correct group

#### **Solutions**

**Option 1: Match UIDs** (VS Code DevContainer approach)
```json
// devcontainer.json
{
  "remoteUser": "vscode",
  "updateRemoteUserUID": true  // Auto-matches host UID (Linux only)
}
```

**Option 2: Use rootless containers with user namespace mapping**
```bash
podman run --userns=keep-id -v /host/path:/container/path myimage
```

**Option 3: Set permissions in Dockerfile**
```dockerfile
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupmod --gid $USER_GID username \
    && usermod --uid $USER_UID --gid $USER_GID username \
    && chown -R $USER_UID:$USER_GID /home/username
```

### 1.5 Volume Mount Options

#### **Security-Focused Mount Options**

```yaml
volumes:
  - type: tmpfs
    target: /tmp
    tmpfs:
      size: 100M           # Limit size to prevent memory exhaustion
      mode: 1777           # Standard tmp permissions

  - type: bind
    source: ./workspace
    target: /workspace
    read_only: true        # Prevent writes

  - type: bind
    source: ./scratch
    target: /workspace/scratch
    bind:
      propagation: rprivate   # Isolate mounts
```

#### **Linux Filesystem Mount Options** (via `--mount`)

```bash
docker run --mount type=tmpfs,target=/tmp,tmpfs-mode=1777,tmpfs-size=64m myimage
```

Common options:
- `noexec` - Cannot execute binaries
- `nosuid` - SUID bits ignored
- `nodev` - Device files disabled
- `ro` - Read-only
- `size=<bytes>` - Maximum size

---

## 2. Linux Namespaces for Isolation

Linux namespaces are the fundamental building block of container isolation. They provide separate instances of global system resources.

### 2.1 Namespace Types

| Namespace | Isolation | Container Impact | Security Benefit |
|-----------|-----------|------------------|------------------|
| **User** | UIDs/GIDs | Root in container ≠ root on host | Privilege isolation |
| **PID** | Process IDs | Isolated process tree | Cannot see host processes |
| **Mount** | Filesystem mounts | Isolated mount table | Filesystem isolation |
| **Network** | Network stack | Isolated network interfaces | Network isolation |
| **IPC** | Inter-process communication | Isolated message queues | Process communication isolation |
| **UTS** | Hostname | Isolated hostname | Identity isolation |
| **Cgroup** | Resource limits | Isolated resource views | Resource accounting |

### 2.2 User Namespaces (Critical for BitBot)

User namespaces enable running containers as non-root while appearing as root inside the container.

#### **How User Namespace Mapping Works**

```
Host UID/GID Range → Container UID/GID Range
─────────────────────────────────────────────
Host UID 1000      → Container UID 0 (root)
Host UID 100000    → Container UID 1
Host UID 100001    → Container UID 2
...                → ...
Host UID 165535    → Container UID 65535
```

**Formula**: `host_uid = subuid_start + container_uid - 1` (except UID 0 maps to invoking user)

#### **Configuration Files**

**/etc/subuid** - Subordinate UID ranges for users:
```
username:100000:65536
```
This allocates UIDs 100000-165535 to `username` for use in containers.

**/etc/subgid** - Subordinate GID ranges:
```
username:100000:65536
```

#### **Docker User Namespace Remapping**

**Enable in Docker daemon** (`/etc/docker/daemon.json`):
```json
{
  "userns-remap": "default"
}
```

This automatically creates `dockremap` user with subordinate ID ranges.

**Custom user remapping**:
```json
{
  "userns-remap": "username:groupname"
}
```

#### **Rootless Docker/Podman**

**Rootless mode benefits**:
- Docker daemon runs as non-root user
- Containers run in user namespaces automatically
- Enhanced security: no root on host
- UID 0 in container = invoking user on host

**Start rootless Docker**:
```bash
dockerd-rootless.sh
```

**Podman (rootless by default)**:
```bash
podman run --rm -it alpine sh
# Inside container: you appear as root (UID 0)
# On host: process runs as your user (UID 1000)
```

### 2.3 PID Namespaces

**Purpose**: Isolate process tree so container processes cannot see or signal host processes.

#### **Default Behavior**
```bash
docker run --rm alpine ps aux
# Only sees processes inside container
```

#### **Share Host PID Namespace** (dangerous)
```bash
docker run --pid=host alpine ps aux
# Can see ALL host processes - avoid in production
```

**BitBot Use Case**: Never use `--pid=host` in sketch or work modes. Only potentially in setup mode for debugging.

### 2.4 Network Namespaces

**Purpose**: Isolate network stack (interfaces, routing tables, firewall rules).

#### **Network Modes**

```yaml
services:
  app:
    network_mode: "none"        # No network access
    # OR
    network_mode: "host"        # Use host network (no isolation)
    # OR
    network_mode: "bridge"      # Default: isolated bridge network
    # OR
    networks:                   # Custom networks
      - mcp-workspace-network
```

#### **BitBot Network Strategy**

```yaml
# Sketch mode - minimal network
services:
  bitbot-sketch:
    networks:
      - mcp-minimal
    # Only MCP services, no internet

# Work mode - isolated networks
  bitbot-work:
    networks:
      - mcp-workspace
      - user-development
    # Separated BitBot and user networks

# Setup mode - full access
  bitbot-setup:
    network_mode: "bridge"
    # Or host mode for full access
```

### 2.5 Mount Namespaces

**Purpose**: Isolate filesystem mount points.

#### **Interaction with Bind Propagation**

Mount namespaces work with propagation modes to control mount visibility:

```bash
# Container with isolated mount namespace
docker run --mount type=bind,source=/data,target=/data,bind-propagation=rprivate alpine
```

**BitBot Application**: Use mount namespaces to prevent container from seeing host mounts unintentionally.

---

## 3. Capabilities & Security Profiles

### 3.1 Linux Capabilities

Capabilities divide root privileges into distinct units that can be independently enabled or disabled.

#### **Default Docker Capabilities**

Docker drops most dangerous capabilities but retains some for basic functionality:

**Retained by default**:
- `CAP_CHOWN` - Change file ownership
- `CAP_DAC_OVERRIDE` - Bypass file read/write/execute permission checks
- `CAP_FOWNER` - Bypass permission checks for operations on files
- `CAP_FSETID` - Don't clear SUID/SGID on file modification
- `CAP_KILL` - Bypass permission checks for sending signals
- `CAP_SETGID` - Manipulate process GIDs
- `CAP_SETUID` - Manipulate process UIDs
- `CAP_NET_BIND_SERVICE` - Bind to ports < 1024
- `CAP_NET_RAW` - Use RAW and PACKET sockets
- `CAP_SYS_CHROOT` - Use chroot()
- `CAP_MKNOD` - Create special files
- `CAP_AUDIT_WRITE` - Write to kernel audit log
- `CAP_SETFCAP` - Set file capabilities

**Dangerous capabilities dropped by default**:
- `CAP_SYS_ADMIN` - Mount filesystems, perform admin operations
- `CAP_SYS_MODULE` - Load/unload kernel modules
- `CAP_SYS_PTRACE` - Trace arbitrary processes
- `CAP_SYS_BOOT` - Reboot system
- `CAP_NET_ADMIN` - Network administration

#### **Production Hardening Pattern**

**Drop all, add only what's needed**:
```yaml
services:
  app:
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Only if binding to privileged ports
      - SETFCAP           # Only if setting file capabilities
```

**Docker CLI**:
```bash
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE nginx
```

#### **BitBot Mode Recommendations**

**Sketch Mode** (most restricted):
```yaml
cap_drop:
  - ALL
cap_add:
  - CHOWN           # For file operations
  - SETUID          # For su/sudo if needed
  - SETGID          # For group changes
```

**Work Mode** (standard development):
```yaml
cap_drop:
  - ALL
cap_add:
  - CHOWN
  - DAC_OVERRIDE    # For file access flexibility
  - SETUID
  - SETGID
  - NET_BIND_SERVICE  # For development servers
```

**Setup Mode** (full access):
```yaml
privileged: true  # All capabilities
# OR selective approach:
cap_drop: []      # Keep defaults
cap_add:
  - SYS_ADMIN     # For advanced operations
```

### 3.2 no-new-privileges Security Option

**Purpose**: Prevents processes from gaining additional privileges via setuid/setgid binaries or file capabilities.

#### **How It Works**

Without `no-new-privileges`, a process can execute a setuid binary and gain elevated privileges:
```bash
# Regular user executes setuid binary
$ ls -l /usr/bin/passwd
-rwsr-xr-x 1 root root 68208 /usr/bin/passwd  # Note the 's' (setuid)

$ /usr/bin/passwd  # Runs as root temporarily
```

With `no-new-privileges=true`, setuid/setgid bits are ignored.

#### **Implementation**

**Docker Compose**:
```yaml
services:
  app:
    security_opt:
      - no-new-privileges:true
```

**Docker CLI**:
```bash
docker run --security-opt=no-new-privileges:true myimage
```

**BitBot Application**: Enable for sketch and work modes to prevent privilege escalation.

### 3.3 AppArmor Security Profiles

**AppArmor** (Application Armor) is a Linux security module using Mandatory Access Control (MAC).

#### **How AppArmor Works**

AppArmor profiles define what resources (files, network, capabilities) a process can access. Profiles operate in two modes:
- **Enforce mode**: Violations are blocked
- **Complain mode**: Violations are logged but allowed

#### **Docker's Default Profile**

Docker automatically generates a default profile called `docker-default` that:
- Denies access to sensitive `/proc` and `/sys` paths
- Blocks mount operations
- Restricts access to raw sockets
- Limits ptrace capabilities

#### **Custom AppArmor Profile for BitBot**

**/etc/apparmor.d/bitbot-sketch-mode**:
```
#include <tunables/global>

profile bitbot-sketch-mode flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  # Allow network access for MCP services
  network inet stream,
  network inet6 stream,

  # Read-only access to workspace
  /workspace/** r,

  # Read-write access to sketch directory only
  /workspace/sketch/** rw,

  # Block access to sensitive directories
  deny /workspace/.devcontainer/** rw,
  deny /workspace/.git/config w,
  deny /workspace/.env w,

  # Allow temporary files
  /tmp/** rw,

  # Deny capability escalation
  deny capability sys_admin,
  deny capability sys_module,
  deny capability sys_ptrace,
}
```

#### **Applying Custom Profile**

```bash
# Load profile
sudo apparmor_parser -r -W /etc/apparmor.d/bitbot-sketch-mode

# Use in container
docker run --security-opt apparmor=bitbot-sketch-mode myimage
```

**Docker Compose**:
```yaml
services:
  bitbot-sketch:
    security_opt:
      - apparmor:bitbot-sketch-mode
```

### 3.4 SELinux Security Profiles

**SELinux** (Security-Enhanced Linux) provides mandatory access control via type enforcement and multi-category security.

#### **How SELinux Differs from AppArmor**

| Feature | AppArmor | SELinux |
|---------|----------|---------|
| **Policy basis** | Path-based | Label-based |
| **Complexity** | Simpler | More complex |
| **Distributions** | Debian/Ubuntu | Red Hat/CentOS/Fedora |
| **Container isolation** | Profile per container type | MCS labels per container instance |

#### **SELinux Multi-Category Security (MCS)**

SELinux can enforce that each container can only access files labeled for that specific container.

**Example**:
- Container A: labeled `system_u:system_r:svirt_lxc_net_t:s0:c1,c2`
- Container B: labeled `system_u:system_r:svirt_lxc_net_t:s0:c3,c4`
- Files for A: labeled `system_u:object_r:svirt_sandbox_file_t:s0:c1,c2`
- Files for B: labeled `system_u:object_r:svirt_sandbox_file_t:s0:c3,c4`

Container A **cannot** access Container B's files even if it escapes the container, because the kernel enforces MCS labels.

#### **Docker SELinux Options**

```yaml
services:
  app:
    security_opt:
      - label:type:svirt_apache_t          # Custom SELinux type
      - label:level:s0:c100,c200            # MCS categories
```

**Volume labeling**:
```yaml
volumes:
  - ./workspace:/workspace:Z   # Private unshared label
  - ./shared:/shared:z         # Shared label across containers
```

#### **BitBot Recommendation**

- **AppArmor**: Better for Debian/Ubuntu-based BitBot implementations
- **SELinux**: Better for Red Hat/CentOS-based environments
- **Implementation**: Detect host MAC system and configure appropriately

### 3.5 Seccomp Profiles

**Seccomp** (Secure Computing Mode) filters system calls a container can make.

#### **Default Docker Seccomp Profile**

Docker applies a default seccomp profile that blocks ~44 dangerous syscalls including:
- `reboot`, `swapon`, `swapoff` - System operations
- `mount`, `umount` - Filesystem operations
- `kexec_load`, `init_module` - Kernel operations
- `ptrace` - Process tracing
- `personality` - Process personality changes

#### **Custom Seccomp Profile**

**bitbot-sketch-seccomp.json**:
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64", "SCMP_ARCH_X86", "SCMP_ARCH_AARCH64"],
  "syscalls": [
    {
      "names": ["read", "write", "open", "close", "stat", "fstat", "lstat"],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": ["socket", "connect", "accept", "bind", "listen"],
      "action": "SCMP_ACT_ALLOW",
      "args": []
    },
    {
      "names": ["mount", "umount2", "pivot_root"],
      "action": "SCMP_ACT_ERRNO"
    }
  ]
}
```

**Apply profile**:
```yaml
services:
  app:
    security_opt:
      - seccomp:./bitbot-sketch-seccomp.json
```

---

## 4. User Mapping Strategies

### 4.1 The UID/GID Problem

**Core Issue**: Container processes run with specific UIDs/GIDs that must align with host filesystem permissions for bind mounts.

#### **Scenarios**

| Scenario | Container UID | Host File UID | Result |
|----------|---------------|---------------|--------|
| **Mismatch** | 1000 | 1001 | Permission denied |
| **Root container** | 0 | 1000 | Works but insecure |
| **Matched** | 1000 | 1000 | Works correctly |
| **User namespace** | 0 (mapped to 1000) | 1000 | Works securely |

### 4.2 Strategy 1: UID/GID Matching in Dockerfile

**Build-time approach**: Set container user UID/GID to match expected host user.

```dockerfile
FROM ubuntu:22.04

# Accept build arguments for user ID matching
ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=1000

# Create user with matching UID/GID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Set ownership of user home directory
RUN chown -R $USER_UID:$USER_GID /home/$USERNAME

USER $USERNAME
```

**Build with host UID**:
```bash
docker build \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g) \
  -t bitbot-dev .
```

**Pros**:
- Simple to understand
- Works on all platforms
- No special Docker configuration

**Cons**:
- Requires rebuilding for different users
- Not dynamic
- Doesn't work well for multi-user environments

### 4.3 Strategy 2: Runtime UID/GID Adjustment

**Runtime approach**: Modify container user UID/GID at container startup.

**entrypoint.sh**:
```bash
#!/bin/bash

# Get host user UID/GID from environment
HOST_UID=${HOST_UID:-1000}
HOST_GID=${HOST_GID:-1000}

# Get current container user UID/GID
CURRENT_UID=$(id -u devuser)
CURRENT_GID=$(id -g devuser)

# Adjust if different
if [ "$CURRENT_UID" != "$HOST_UID" ] || [ "$CURRENT_GID" != "$HOST_GID" ]; then
    echo "Adjusting user UID:GID from $CURRENT_UID:$CURRENT_GID to $HOST_UID:$HOST_GID"

    groupmod -g $HOST_GID devuser
    usermod -u $HOST_UID -g $HOST_GID devuser
    chown -R $HOST_UID:$HOST_GID /home/devuser
fi

# Execute command as adjusted user
exec gosu devuser "$@"
```

**Docker Compose**:
```yaml
services:
  dev:
    build: .
    environment:
      - HOST_UID=${UID:-1000}
      - HOST_GID=${GID:-1000}
    volumes:
      - ./workspace:/workspace
```

**Launch**:
```bash
UID=$(id -u) GID=$(id -g) docker-compose up
```

**Pros**:
- Single image for multiple users
- Dynamic adjustment
- More flexible

**Cons**:
- More complex
- Slower startup (UID adjustment takes time)
- Requires privileged operations in entrypoint

### 4.4 Strategy 3: User Namespace Remapping (Recommended)

**Advanced approach**: Use Linux user namespaces to map container root to host user.

#### **Docker with User Namespace Remap**

**Configure daemon** (`/etc/docker/daemon.json`):
```json
{
  "userns-remap": "default"
}
```

**Restart Docker**:
```bash
sudo systemctl restart docker
```

**What happens**:
1. Docker creates `dockremap` user
2. Allocates subordinate UID/GID range (typically 100000-165535)
3. Container UID 0 → Host UID 100000
4. Container UID 1 → Host UID 100001
5. etc.

**Check mapping**:
```bash
cat /etc/subuid
dockremap:100000:65536

cat /etc/subgid
dockremap:100000:65536
```

#### **Rootless Docker (User Namespace by Default)**

```bash
# Install rootless Docker
dockerd-rootless-setuptool.sh install

# Run container
docker run --rm -it alpine sh
# Inside: UID 0 (root)
# On host: Your UID (e.g., 1000)
```

#### **Podman Rootless (Recommended for BitBot)**

Podman is rootless by default and handles user namespaces automatically.

```bash
# Check subordinate ID allocation
cat /etc/subuid
username:100000:65536

# Run container as root inside, username outside
podman run --rm -it alpine sh
```

**Podman unshare**: Execute commands in the user namespace:
```bash
# View files as container would see them
podman unshare ls -la /path/to/workspace

# Fix permissions for container
podman unshare chown -R 0:0 /path/to/data
```

**Pros**:
- Most secure approach
- Container root ≠ host root
- No privileged operations needed
- Matches VS Code DevContainer behavior (Linux)

**Cons**:
- More complex setup
- Some Docker features unavailable (e.g., cgroups v1)
- Windows/macOS: user namespaces handled differently

### 4.5 Strategy 4: VS Code DevContainer Approach

VS Code uses a hybrid approach optimized for developer experience.

#### **Linux**

**remoteUser + updateRemoteUserUID**:
```json
{
  "remoteUser": "vscode",
  "updateRemoteUserUID": true
}
```

What happens:
1. VS Code detects host user UID/GID
2. Adjusts `vscode` user in container to match
3. Changes ownership of `/home/vscode`
4. Bind-mounted workspace is accessible

#### **Windows/macOS**

User namespace support differs on Windows/macOS (Docker Desktop uses VM):
- Windows: WSL2 provides user namespace support
- macOS: VM handles UID mapping transparently

**Result**: Less explicit UID matching needed on Windows/macOS.

### 4.6 BitBot User Mapping Strategy Recommendation

**Multi-platform approach**:

```yaml
# docker-compose.yml
services:
  bitbot-dev:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        USER_UID: ${USER_UID:-1000}
        USER_GID: ${USER_GID:-1000}
    environment:
      - HOST_UID=${USER_UID:-1000}
      - HOST_GID=${USER_GID:-1000}
    user: "${USER_UID:-1000}:${USER_GID:-1000}"  # Override at runtime
    volumes:
      - ${WORKSPACE_FOLDER}:/workspace
```

**Launch script** (Linux/macOS):
```bash
export USER_UID=$(id -u)
export USER_GID=$(id -g)
docker-compose up -d
```

**Launch script** (Windows WSL2):
```bash
# WSL2 provides user namespace support
export USER_UID=$(id -u)
export USER_GID=$(id -g)
docker-compose up -d
```

**Dockerfile**:
```dockerfile
FROM ubuntu:22.04

ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid $USER_GID bitbot \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash bitbot \
    && apt-get update \
    && apt-get install -y sudo \
    && echo "bitbot ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/bitbot

# Set default user (can be overridden with docker-compose 'user' field)
USER bitbot
WORKDIR /workspace
```

This approach provides:
- **Build-time UID/GID matching** for common case
- **Runtime override** for flexibility
- **Cross-platform compatibility**
- **VS Code DevContainer alignment**

---

## 5. Multi-Mode Architecture Patterns

### 5.1 Design Principles

#### **Single Image, Multiple Modes**

**Goal**: Use the same container image for sketch, work, and setup modes by varying:
1. Mount configurations (read-only vs read-write)
2. Capability sets (restricted vs expanded)
3. Network access (isolated vs connected)
4. User permissions (unprivileged vs privileged)

**Benefits**:
- Single image to build and maintain
- Consistent environment across modes
- Easy mode switching without rebuilding
- Reduced storage and build time

### 5.2 Implementation Pattern: Docker Compose Profiles

Docker Compose profiles enable defining mode-specific configurations in a single file.

#### **Example: BitBot Multi-Mode Compose**

```yaml
# docker-compose.yml
services:
  # Base service definition (inherited by all modes)
  bitbot-base:
    build:
      context: .
      dockerfile: Dockerfile
    image: bitbot:latest
    environment:
      - WORKSPACE_FOLDER=/workspace
      - BITBOT_MODE=${BITBOT_MODE:-work}
    volumes:
      # Base mounts (common to all modes)
      - ${WORKSPACE_FOLDER}:/workspace-base:ro  # Base read-only mount
    networks:
      - mcp-workspace
    user: "${USER_UID:-1000}:${USER_GID:-1000}"
    working_dir: /workspace

  # Sketch mode - most restricted
  bitbot-sketch:
    extends: bitbot-base
    profiles: ["sketch"]
    container_name: bitbot-dev-${WORKSPACE_HASH}-sketch
    security_opt:
      - no-new-privileges:true
      - apparmor:bitbot-sketch
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETUID
      - SETGID
    read_only: true  # Root filesystem read-only
    volumes:
      # Workspace read-only
      - ${WORKSPACE_FOLDER}:/workspace:ro

      # Sketch directory read-write (overlay)
      - ${WORKSPACE_FOLDER}/sketch:/workspace/sketch:rw

      # Tmpfs for temporary files
      - type: tmpfs
        target: /tmp
        tmpfs:
          size: 100M
          mode: 1777

      # Runtime directories
      - type: tmpfs
        target: /var/tmp
        tmpfs:
          size: 50M

      # BitBot state (persistent)
      - bitbot-sketch-state:/home/bitbot/.bitbot
    networks:
      - mcp-minimal  # Restricted network
    environment:
      - BITBOT_MODE=sketch
      - NETWORK_POLICY=restricted

  # Work mode - standard development
  bitbot-work:
    extends: bitbot-base
    profiles: ["work"]
    container_name: bitbot-dev-${WORKSPACE_HASH}-work
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - DAC_OVERRIDE
      - SETUID
      - SETGID
      - NET_BIND_SERVICE
    volumes:
      # Full workspace access
      - ${WORKSPACE_FOLDER}:/workspace:rw

      # Protect critical files (read-only)
      - ${WORKSPACE_FOLDER}/.devcontainer:/workspace/.devcontainer:ro
      - ${WORKSPACE_FOLDER}/.bitbot:/workspace/.bitbot:ro

      # Docker socket for user's Docker (isolated)
      - bitbot-user-docker:/var/run/user-docker

      # Cache directories (persistent)
      - bitbot-work-cache:/home/bitbot/.cache
    networks:
      - mcp-workspace
      - user-development
    environment:
      - BITBOT_MODE=work
      - DOCKER_HOST=unix:///var/run/user-docker/docker.sock

  # Setup mode - full access
  bitbot-setup:
    extends: bitbot-base
    profiles: ["setup"]
    container_name: bitbot-dev-${WORKSPACE_HASH}-setup
    privileged: true  # Full capabilities
    volumes:
      # Full workspace read-write
      - ${WORKSPACE_FOLDER}:/workspace:rw

      # Full Docker access (BitBot's Docker)
      - /var/run/docker.sock:/var/run/docker.sock

      # System directories (for configuration)
      - /etc/docker:/etc/docker:ro
    networks:
      - mcp-workspace
      - mcp-global
    environment:
      - BITBOT_MODE=setup
      - DOCKER_HOST=unix:///var/run/docker.sock
    user: "0:0"  # Run as root

# Networks
networks:
  mcp-minimal:
    driver: bridge
    internal: true  # No internet access

  mcp-workspace:
    driver: bridge

  mcp-global:
    external: true

  user-development:
    driver: bridge

# Volumes
volumes:
  bitbot-sketch-state:
  bitbot-work-cache:
  bitbot-user-docker:
```

#### **Launching Different Modes**

```bash
# Sketch mode
COMPOSE_PROFILES=sketch docker-compose up -d

# Work mode (default)
COMPOSE_PROFILES=work docker-compose up -d

# Setup mode
COMPOSE_PROFILES=setup docker-compose up -d
```

### 5.3 Implementation Pattern: Environment-Based Configuration

Alternative approach using environment variables to control behavior.

```yaml
services:
  bitbot:
    image: bitbot:latest
    environment:
      - BITBOT_MODE=${BITBOT_MODE:-work}
    volumes:
      - ${WORKSPACE_FOLDER}:/workspace:${WORKSPACE_MOUNT_MODE:-rw}
      - type: tmpfs
        target: /tmp
        tmpfs:
          size: ${TMPFS_SIZE:-100M}
    security_opt:
      - no-new-privileges:${NO_NEW_PRIVS:-true}
    cap_drop: ${CAP_DROP:-ALL}
    cap_add: ${CAP_ADD:-CHOWN,SETUID,SETGID}
    networks:
      - ${NETWORK_NAME:-mcp-workspace}
```

**Mode configuration files**:

**sketch.env**:
```bash
BITBOT_MODE=sketch
WORKSPACE_MOUNT_MODE=ro
TMPFS_SIZE=100M
NO_NEW_PRIVS=true
CAP_DROP=ALL
CAP_ADD=CHOWN,SETUID,SETGID
NETWORK_NAME=mcp-minimal
```

**work.env**:
```bash
BITBOT_MODE=work
WORKSPACE_MOUNT_MODE=rw
TMPFS_SIZE=200M
NO_NEW_PRIVS=true
CAP_DROP=ALL
CAP_ADD=CHOWN,DAC_OVERRIDE,SETUID,SETGID,NET_BIND_SERVICE
NETWORK_NAME=mcp-workspace
```

**setup.env**:
```bash
BITBOT_MODE=setup
WORKSPACE_MOUNT_MODE=rw
TMPFS_SIZE=500M
NO_NEW_PRIVS=false
CAP_DROP=
CAP_ADD=
NETWORK_NAME=mcp-global
```

**Launch**:
```bash
docker-compose --env-file sketch.env up -d
```

### 5.4 Implementation Pattern: Runtime Mode Switching

**Advanced approach**: Switch modes without restarting container.

#### **Entrypoint Script with Mode Logic**

**/usr/local/bin/bitbot-entrypoint.sh**:
```bash
#!/bin/bash
set -e

BITBOT_MODE=${BITBOT_MODE:-work}

setup_sketch_mode() {
    echo "Setting up SKETCH mode restrictions..."

    # Mount workspace as read-only (if not already)
    if ! mount | grep -q "/workspace.*ro"; then
        mount -o remount,ro /workspace || echo "Warning: Cannot remount read-only"
    fi

    # Ensure sketch directory is writable
    mkdir -p /workspace/sketch
    mount -o remount,rw /workspace/sketch 2>/dev/null || true

    # Drop network access except MCP
    iptables -A OUTPUT -d 172.20.0.0/16 -j ACCEPT  # MCP network
    iptables -A OUTPUT -j DROP

    # Set restrictive umask
    umask 0022
}

setup_work_mode() {
    echo "Setting up WORK mode configuration..."

    # Protect critical directories
    chmod -R 555 /workspace/.devcontainer 2>/dev/null || true
    chmod -R 555 /workspace/.bitbot 2>/dev/null || true

    # Standard umask
    umask 0022
}

setup_setup_mode() {
    echo "Setting up SETUP mode (full access)..."

    # Remove restrictions
    umask 0002
}

# Apply mode-specific setup
case "$BITBOT_MODE" in
    sketch)
        setup_sketch_mode
        ;;
    work)
        setup_work_mode
        ;;
    setup)
        setup_setup_mode
        ;;
    *)
        echo "Unknown mode: $BITBOT_MODE, defaulting to work"
        setup_work_mode
        ;;
esac

# Execute main command
exec "$@"
```

**Dockerfile**:
```dockerfile
COPY bitbot-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/bitbot-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/bitbot-entrypoint.sh"]
CMD ["/bin/bash"]
```

**Limitations**: Some restrictions (capabilities, mount modes) cannot be changed at runtime and require container restart.

### 5.5 Mode Enforcement Strategies

#### **Filesystem-Level Enforcement**

**Overlay mount for sketch mode**:
```bash
# Create overlay with read-only lower, read-write upper for /workspace/sketch
mount -t overlay overlay \
  -o lowerdir=/workspace,upperdir=/workspace/sketch,workdir=/tmp/overlay-work \
  /workspace
```

**Bind mount remounting**:
```bash
# Remount existing mount as read-only
mount -o remount,ro /workspace

# Create writable overlay for sketch directory
mount --bind /workspace/sketch-rw /workspace/sketch
```

#### **Network-Level Enforcement**

**iptables rules**:
```bash
# Sketch mode: Only MCP services
iptables -A OUTPUT -d 172.20.0.0/16 -j ACCEPT  # MCP network
iptables -A OUTPUT -m owner --uid-owner 1000 -j DROP

# Work mode: Block BitBot infrastructure
iptables -A OUTPUT -d 172.20.0.0/16 -m owner --uid-owner 1000 -j DROP
iptables -A OUTPUT -j ACCEPT
```

**Docker network policies**:
```yaml
networks:
  mcp-minimal:
    internal: true  # No external connectivity

  mcp-workspace:
    driver: bridge  # Standard connectivity
    driver_opts:
      com.docker.network.bridge.enable_ip_masquerade: "true"
```

#### **Process-Level Enforcement**

**User namespace UID restrictions**:
```bash
# Run agent process as non-privileged UID in sketch mode
su -s /bin/bash -c "/usr/bin/ai-agent" restricted-user
```

**Capability restrictions** (already covered in section 3).

#### **Audit Logging**

**Log mode violations**:
```bash
# Install auditd in container
apt-get install auditd

# Watch for write attempts to protected paths
auditctl -w /workspace/.devcontainer -p wa -k bitbot-violation
auditctl -w /workspace/.bitbot -p wa -k bitbot-violation

# Monitor logs
ausearch -k bitbot-violation
```

### 5.6 Production Example: VS Code DevContainer Security Modes

VS Code doesn't have explicit "modes," but implements layered security:

```json
{
  "name": "Secure Dev Container",

  // Non-root user
  "remoteUser": "vscode",

  // Mount configurations
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind",
    "source=${localWorkspaceFolder}/.devcontainer,target=/workspace/.devcontainer,type=bind,readonly"
  ],

  // Capabilities restriction
  "capAdd": [],
  "securityOpt": ["no-new-privileges:true"],

  // Read-only root filesystem
  "runArgs": [
    "--read-only",
    "--tmpfs=/tmp:rw,noexec,nosuid,size=100m"
  ],

  // AppArmor profile
  "appPort": [],
  "forwardPorts": [],

  "containerEnv": {
    "SECURITY_MODE": "restricted"
  }
}
```

---

## 6. Filesystem Restrictions

### 6.1 Read-Only Root Filesystem

**Purpose**: Minimize attack surface by making the entire root filesystem read-only.

#### **Benefits**
- **Immutability**: Container filesystem cannot be modified
- **Security**: Prevents malware from writing persistence mechanisms
- **Compliance**: Meets security requirements for untrusted code execution
- **Debugging**: Easier to identify unauthorized changes

#### **Implementation**

**Docker CLI**:
```bash
docker run --read-only myimage
```

**Docker Compose**:
```yaml
services:
  app:
    image: myimage
    read_only: true
```

**Kubernetes**:
```yaml
spec:
  containers:
  - name: app
    image: myimage
    securityContext:
      readOnlyRootFilesystem: true
```

#### **Challenge: Applications Need Writable Paths**

Most applications need to write to:
- `/tmp` - Temporary files
- `/var/run` - Runtime data (PID files)
- `/var/cache` - Cache files
- `/var/log` - Log files
- Application-specific directories

**Solution**: Mount tmpfs or volumes for writable paths.

### 6.2 Tmpfs Mounts for Writable Directories

**Tmpfs**: Memory-backed temporary filesystem that's automatically cleared on container stop.

#### **Basic Tmpfs Mount**

```yaml
services:
  app:
    image: myimage
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
      - /var/cache
```

#### **Tmpfs with Size Limits** (Important!)

**Without size limits**, tmpfs can consume all available memory and crash the system.

```yaml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp:rw,noexec,nosuid,size=100m      # Limit to 100MB
      - /var/run:rw,noexec,nosuid,size=10m   # Limit to 10MB
```

**Docker CLI**:
```bash
docker run --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=100m \
  --tmpfs /var/run:rw,noexec,nosuid,size=10m \
  myimage
```

#### **Tmpfs Options**

| Option | Description | Security Impact |
|--------|-------------|-----------------|
| `rw` | Read-write (default) | Standard |
| `ro` | Read-only | High security (why use tmpfs?) |
| `noexec` | Cannot execute binaries | Prevents tmpfs-based attacks |
| `nosuid` | Ignore SUID/SGID bits | Prevents privilege escalation |
| `nodev` | Ignore device files | Prevents device access |
| `size=<bytes>` | Maximum size | Prevents memory exhaustion |
| `mode=<octal>` | Permission bits | Controls access |

**Recommended tmpfs options**: `rw,noexec,nosuid,size=<appropriate>`

#### **Tmpfs Size Guidelines**

| Path | Recommended Size | Purpose |
|------|-----------------|---------|
| `/tmp` | 100MB - 500MB | General temporary files |
| `/var/run` | 10MB - 50MB | Runtime data (PID files) |
| `/var/cache` | 50MB - 200MB | Application cache |
| `/home/user/.cache` | 100MB - 500MB | User cache |

**BitBot Recommendations**:
- **Sketch mode**: `/tmp` = 100MB (limited scope)
- **Work mode**: `/tmp` = 500MB (full development)
- **Setup mode**: `/tmp` = 1GB (build operations)

### 6.3 OverlayFS for Read-Only Base with Writable Layer

**OverlayFS**: Union filesystem that layers a read-write directory over a read-only directory.

#### **How OverlayFS Works**

```
┌─────────────────────────────────┐
│      Merged View                │  ← What users see
│  (unified filesystem)           │
└─────────────────────────────────┘
         ▲
         │ union mount
         │
    ┌────┴─────┐
    │          │
┌───┴───┐  ┌───┴───┐
│ Upper │  │ Lower │
│ (RW)  │  │ (RO)  │
└───────┘  └───────┘
```

- **Lower**: Read-only base layer
- **Upper**: Read-write layer for changes
- **Work**: Temporary working directory for OverlayFS operations
- **Merged**: Combined view presented to users

**Changes**:
- New files → Created in upper
- Modified files → Copied from lower to upper, then modified (copy-on-write)
- Deleted files → Marked as deleted in upper (whiteout file)

#### **Manual OverlayFS Mount**

```bash
# Create directories
mkdir -p /lower /upper /work /merged

# Mount overlay
mount -t overlay overlay \
  -o lowerdir=/lower,upperdir=/upper,workdir=/work \
  /merged
```

**Result**: `/merged` shows unified view, writes go to `/upper`, `/lower` remains untouched.

#### **Container OverlayFS Usage**

Docker automatically uses OverlayFS (overlay2 storage driver) for image layers, but you can manually create overlays for workspace isolation.

**BitBot Sketch Mode with OverlayFS**:

```yaml
services:
  bitbot-sketch:
    image: bitbot:latest
    volumes:
      # Mount workspace read-only as lower layer
      - ${WORKSPACE_FOLDER}:/workspace-lower:ro

      # Create upper layer for sketch directory
      - bitbot-sketch-upper:/workspace-upper
      - bitbot-sketch-work:/workspace-work

    entrypoint:
      - /bin/bash
      - -c
      - |
        mkdir -p /workspace
        mount -t overlay overlay \
          -o lowerdir=/workspace-lower,upperdir=/workspace-upper/sketch,workdir=/workspace-work \
          /workspace
        exec /usr/local/bin/bitbot-entrypoint.sh
```

**Limitation**: Requires `CAP_SYS_ADMIN` to mount overlays, which conflicts with security restrictions.

#### **Alternative: Use Docker's Built-in Overlay**

**Leverage image layers**:

```dockerfile
# Base image with read-only workspace
FROM bitbot-base AS sketch-base
COPY --from=workspace /workspace /workspace-ro
RUN chmod -R 555 /workspace-ro

# Create writable sketch directory
FROM sketch-base
RUN mkdir -p /workspace/sketch
VOLUME /workspace/sketch
```

**Docker Compose**:
```yaml
services:
  bitbot-sketch:
    build:
      target: sketch-base
    volumes:
      - sketch-data:/workspace/sketch
```

### 6.4 Protecting Specific Paths

#### **Read-Only Bind Mounts for Critical Files**

```yaml
volumes:
  # Full workspace read-write
  - ${WORKSPACE_FOLDER}:/workspace:rw

  # Overlay critical directories as read-only
  - ${WORKSPACE_FOLDER}/.devcontainer:/workspace/.devcontainer:ro
  - ${WORKSPACE_FOLDER}/.bitbot:/workspace/.bitbot:ro
  - ${WORKSPACE_FOLDER}/.git/config:/workspace/.git/config:ro
  - ${WORKSPACE_FOLDER}/.env:/workspace/.env:ro
```

**Pros**: Simple and effective
**Cons**: Requires explicit listing of protected paths

#### **File Permission Restrictions**

**Set immutable flag** (Linux):
```bash
# Make file immutable (cannot be modified/deleted even by root)
chattr +i /workspace/.devcontainer/devcontainer.json

# Check immutable files
lsattr /workspace/.devcontainer/

# Remove immutable flag
chattr -i /workspace/.devcontainer/devcontainer.json
```

**In Dockerfile**:
```dockerfile
RUN chattr +i /etc/important-config.conf
```

**Note**: Requires `CAP_LINUX_IMMUTABLE` capability or root.

#### **Directory-Level Restrictions**

```bash
# Remove write permission for group and others
chmod 755 /workspace/.bitbot

# Set directory to read-only for all
chmod 555 /workspace/.devcontainer
```

### 6.5 Workspace Subdirectory Isolation

**Pattern**: Allow writes only to specific subdirectories.

#### **BitBot Sketch Mode Implementation**

```yaml
services:
  bitbot-sketch:
    volumes:
      # Mount entire workspace read-only
      - type: bind
        source: ${WORKSPACE_FOLDER}
        target: /workspace
        read_only: true

      # Overlay sketch directory as read-write
      - type: bind
        source: ${WORKSPACE_FOLDER}/sketch
        target: /workspace/sketch
        read_only: false

      # Ensure sketch directory exists
      - type: volume
        source: sketch-init
        target: /init-sketch
```

**Initialization** (in entrypoint):
```bash
#!/bin/bash
# Ensure sketch directory exists on host
if [ ! -d "/workspace/sketch" ]; then
    echo "Creating /workspace/sketch directory..."
    # Note: This will fail if /workspace is read-only
    # Alternative: Pre-create on host before container launch
fi

exec "$@"
```

**Host-side initialization** (in launch script):
```bash
# Ensure sketch directory exists before launching container
mkdir -p "$WORKSPACE_FOLDER/sketch"
docker-compose up -d
```

### 6.6 Copy-on-Write Snapshots

**Use storage drivers that support CoW**:
- **overlay2** (default): File-level CoW
- **btrfs**: Block-level CoW with snapshots
- **zfs**: Block-level CoW with advanced features

#### **Btrfs Snapshots**

**Create snapshot before risky operation**:
```bash
# Create subvolume snapshot
btrfs subvolume snapshot /workspace /workspace-snapshot-20251016

# Experiment with changes...

# Rollback if needed
btrfs subvolume delete /workspace
btrfs subvolume snapshot /workspace-snapshot-20251016 /workspace
```

#### **ZFS Snapshots**

```bash
# Create snapshot
zfs snapshot tank/workspace@pre-experiment

# Experiment with changes...

# Rollback
zfs rollback tank/workspace@pre-experiment
```

**Advantage**: Instant snapshots, efficient storage
**Disadvantage**: Requires ZFS/Btrfs host filesystem

---

## 7. Safety Patterns & Recovery

### 7.1 Data Loss Prevention Strategies

#### **7.1.1 Git Safe Directory Configuration**

**Problem**: Git detects multi-user ownership in containers and blocks operations.

**CVE-2022-24765**: Vulnerability allowing untrusted users to exploit .git repositories.

**Solution**: Configure safe directories.

```bash
# In container entrypoint
git config --global --add safe.directory /workspace
```

**VS Code DevContainer**:
```json
{
  "postStartCommand": "git config --global --add safe.directory ${containerWorkspaceFolder}"
}
```

**BitBot Implementation**:
```bash
# In bitbot-entrypoint.sh
if [ -d "/workspace/.git" ]; then
    git config --global --add safe.directory /workspace
fi
```

#### **7.1.2 Dirty State Protection**

**Pattern**: Prevent operations on repositories with uncommitted changes.

**Detection**:
```bash
#!/bin/bash
# Check for dirty state
if [ -n "$(git status --porcelain)" ]; then
    echo "ERROR: Repository has uncommitted changes"
    echo "Commit or stash changes before proceeding"
    exit 1
fi
```

**Exceptions**: Define ignorable paths.
```bash
# Ignore specific files
IGNORE_PATTERNS=(".bitbot/tmp" "sketch/*")

git status --porcelain | grep -vE "$(IFS=\|; echo "${IGNORE_PATTERNS[*]}")"
```

**BitBot Application**: Warn users in sketch mode if uncommitted changes exist outside sketch directory.

#### **7.1.3 Backup Before Destructive Operations**

**Pattern**: Automatic backups before mode switches or risky operations.

```bash
#!/bin/bash
create_backup() {
    local backup_dir="/workspace/.bitbot/backups"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_name="workspace-backup-$timestamp"

    mkdir -p "$backup_dir"

    # Create tarball of workspace (exclude .git for efficiency)
    tar -czf "$backup_dir/$backup_name.tar.gz" \
        --exclude='.git' \
        --exclude='.bitbot/backups' \
        /workspace

    echo "Backup created: $backup_dir/$backup_name.tar.gz"
}

# Before switching to setup mode
if [ "$BITBOT_MODE" = "setup" ]; then
    echo "Creating backup before setup mode..."
    create_backup
fi
```

### 7.2 Snapshot and Rollback Patterns

#### **7.2.1 Container-Level Snapshots**

**Using Docker commit**:
```bash
# Save current container state
docker commit bitbot-dev-abc123 bitbot-dev-abc123:snapshot-$(date +%s)

# Rollback: Run from snapshot
docker run --rm -it bitbot-dev-abc123:snapshot-1697456789
```

**Limitation**: Large snapshots, includes entire filesystem.

#### **7.2.2 Volume Snapshots**

**Using volume backups**:
```bash
# Backup volume to tarball
docker run --rm \
  -v bitbot-work-data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar -czf /backup/volume-backup-$(date +%s).tar.gz /data

# Restore volume from tarball
docker run --rm \
  -v bitbot-work-data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar -xzf /backup/volume-backup-1697456789.tar.gz -C /
```

#### **7.2.3 Filesystem Snapshots with Btrfs/ZFS**

**Btrfs automated snapshots**:
```bash
# Create snapshot function
snapshot_workspace() {
    local snapshot_name="workspace-$(date +%Y%m%d-%H%M%S)"
    btrfs subvolume snapshot /workspace /snapshots/$snapshot_name
    echo "Snapshot created: $snapshot_name"
}

# Rollback function
rollback_workspace() {
    local snapshot_name=$1
    btrfs subvolume delete /workspace
    btrfs subvolume snapshot /snapshots/$snapshot_name /workspace
    echo "Rolled back to: $snapshot_name"
}
```

**ZFS automated snapshots**:
```bash
# Automatic snapshot on mode switch
zfs snapshot tank/workspace@$(date +%Y%m%d-%H%M%S)-$BITBOT_MODE

# List snapshots
zfs list -t snapshot

# Rollback
zfs rollback tank/workspace@20251016-120000-work
```

#### **7.2.4 Overlay Snapshot Pattern**

**Use overlay upper layer for ephemeral changes**:

```yaml
services:
  bitbot-experiment:
    volumes:
      # Lower: Stable workspace
      - ${WORKSPACE_FOLDER}:/workspace-base:ro

      # Upper: Temporary changes (can be discarded)
      - experiment-upper:/overlay-upper
      - experiment-work:/overlay-work

    entrypoint:
      - /bin/sh
      - -c
      - |
        mount -t overlay overlay \
          -o lowerdir=/workspace-base,upperdir=/overlay-upper,workdir=/overlay-work \
          /workspace
        exec "$@"
```

**Discard changes**: Simply delete the `experiment-upper` volume.

```bash
docker-compose down -v  # Removes volumes
```

### 7.3 Version Control Integration Patterns

#### **7.3.1 Auto-Commit Before Dangerous Operations**

```bash
#!/bin/bash
auto_commit() {
    local message=$1

    if [ -d "/workspace/.git" ] && [ -n "$(git status --porcelain)" ]; then
        echo "Auto-committing changes..."
        git add -A
        git commit -m "$message" \
            -m "Auto-generated commit by BitBot" \
            -m "Mode: $BITBOT_MODE" \
            -m "Timestamp: $(date -Iseconds)"
    fi
}

# Before mode switch
auto_commit "Pre-setup mode auto-commit"
switch_to_setup_mode
```

#### **7.3.2 Branch-Based Experimentation**

**Pattern**: Create experimental branch for sketch mode.

```bash
#!/bin/bash
setup_sketch_branch() {
    if [ -d "/workspace/.git" ]; then
        # Save current branch
        local current_branch=$(git rev-parse --abbrev-ref HEAD)
        echo "$current_branch" > /workspace/.bitbot/previous-branch

        # Create and checkout sketch branch
        local sketch_branch="bitbot-sketch-$(date +%Y%m%d-%H%M%S)"
        git checkout -b "$sketch_branch"

        echo "Created experimental branch: $sketch_branch"
        echo "Original branch: $current_branch"
    fi
}

restore_original_branch() {
    if [ -f "/workspace/.bitbot/previous-branch" ]; then
        local previous_branch=$(cat /workspace/.bitbot/previous-branch)

        # Ask user if they want to merge
        echo "Do you want to merge sketch changes into $previous_branch? (y/n)"
        # ... (interactive merge or discard)

        git checkout "$previous_branch"
    fi
}
```

#### **7.3.3 Stash-Based Safety**

```bash
# Stash uncommitted changes before mode switch
git stash push -m "BitBot auto-stash before $BITBOT_MODE mode"

# Later restoration
git stash pop
```

### 7.4 Container Restart Strategies

#### **7.4.1 Health Checks**

**Docker health check**:
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD /usr/local/bin/health-check.sh
```

**health-check.sh**:
```bash
#!/bin/bash
# Check critical services
pgrep -x ai-agent > /dev/null || exit 1
curl -f http://localhost:9090/health || exit 1
exit 0
```

**Docker Compose**:
```yaml
services:
  bitbot:
    healthcheck:
      test: ["CMD", "/usr/local/bin/health-check.sh"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 5s
```

#### **7.4.2 Restart Policies**

```yaml
services:
  bitbot:
    restart: unless-stopped  # Restart on failure, unless explicitly stopped

    # Alternative policies:
    # restart: no              # Never restart
    # restart: always          # Always restart
    # restart: on-failure      # Restart only on error exit
    # restart: on-failure:5    # Restart max 5 times
```

#### **7.4.3 Graceful Shutdown**

**Handle SIGTERM in entrypoint**:
```bash
#!/bin/bash

# Graceful shutdown function
shutdown() {
    echo "Received SIGTERM, shutting down gracefully..."

    # Save state
    if [ -n "$AI_AGENT_PID" ]; then
        kill -TERM "$AI_AGENT_PID"
        wait "$AI_AGENT_PID"
    fi

    # Sync filesystems
    sync

    exit 0
}

trap shutdown SIGTERM SIGINT

# Start main process
/usr/bin/ai-agent &
AI_AGENT_PID=$!

# Wait for signal
wait $AI_AGENT_PID
```

### 7.5 Audit Logging

#### **7.5.1 File Access Logging**

**Using inotify**:
```bash
#!/bin/bash
# Monitor file changes
inotifywait -m -r /workspace \
  -e modify,create,delete,move \
  --format '%T %e %w%f' --timefmt '%Y-%m-%d %H:%M:%S' \
  >> /workspace/.bitbot/audit.log &
```

#### **7.5.2 Command Logging**

**Bash history with timestamps**:
```bash
# In .bashrc
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
export HISTFILE=/workspace/.bitbot/bash_history
export HISTSIZE=10000
export HISTFILESIZE=20000
```

#### **7.5.3 Mode Transition Logging**

```bash
log_mode_transition() {
    local from_mode=$1
    local to_mode=$2
    local reason=$3

    local log_entry=$(cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "from_mode": "$from_mode",
  "to_mode": "$to_mode",
  "reason": "$reason",
  "user": "$USER",
  "workspace": "$WORKSPACE_FOLDER"
}
EOF
)

    echo "$log_entry" >> /workspace/.bitbot/mode-transitions.jsonl
}
```

### 7.6 Recovery Procedures

#### **7.6.1 Reset to Clean State**

```bash
#!/bin/bash
# Reset BitBot workspace to clean state

bitbot_reset() {
    echo "Resetting BitBot workspace..."

    # Stop containers
    docker-compose down

    # Remove volumes (optional)
    read -p "Remove volumes (cached data will be lost)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose down -v
    fi

    # Remove BitBot state
    rm -rf .bitbot/cache
    rm -rf .bitbot/tmp

    # Keep configuration and backups
    echo "BitBot reset complete"
}
```

#### **7.6.2 Emergency Stop**

```bash
# Stop all BitBot containers immediately
bitbot_emergency_stop() {
    echo "Emergency stop: killing all BitBot containers..."
    docker ps -q --filter "name=bitbot-*" | xargs -r docker kill
}
```

#### **7.6.3 Corruption Recovery**

```bash
bitbot_recover() {
    echo "Attempting recovery..."

    # Check for backups
    if [ -d "/workspace/.bitbot/backups" ]; then
        local latest_backup=$(ls -t /workspace/.bitbot/backups | head -1)
        echo "Latest backup found: $latest_backup"
        echo "Restore from backup? (y/n)"
        read -r response
        if [ "$response" = "y" ]; then
            tar -xzf "/workspace/.bitbot/backups/$latest_backup" -C /
        fi
    fi

    # Rebuild container if needed
    docker-compose build --no-cache
    docker-compose up -d
}
```

---

## 8. Production Examples

### 8.1 VS Code DevContainer

**Real-world implementation**: Microsoft's VS Code DevContainer feature.

#### **Security Features**

```json
{
  "name": "Secure Development",

  // Non-root user
  "remoteUser": "vscode",
  "updateRemoteUserUID": true,

  // Capabilities
  "capAdd": [],
  "securityOpt": [
    "no-new-privileges:true"
  ],

  // Mount restrictions
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind",
    "source=${localWorkspaceFolder}/.devcontainer,target=/workspace/.devcontainer,type=bind,readonly"
  ],

  // Post-start security setup
  "postStartCommand": "git config --global --add safe.directory /workspace",

  // Features (with minimal privileges)
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {
      "version": "latest",
      "moby": false
    }
  }
}
```

**Key Patterns**:
- Non-root user with UID matching
- Read-only mount for configuration
- Git safe directory configuration
- Docker-in-Docker isolation

### 8.2 GitHub Codespaces

**Implementation**: Cloud-based development environments with multi-level isolation.

#### **Architecture**

```
┌──────────────────────────────────────────────┐
│         User's Browser                       │
└──────────────────┬───────────────────────────┘
                   │ HTTPS/WebSocket
┌──────────────────▼───────────────────────────┐
│         Codespace Container                  │
│  ┌────────────────────────────────────────┐  │
│  │  User Development Environment          │  │
│  │  - VS Code Server                      │  │
│  │  - User workspace (/workspace)         │  │
│  │  - Development tools                   │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │  Isolated Docker-in-Docker             │  │
│  │  - User containers                     │  │
│  │  - Separate network                    │  │
│  └────────────────────────────────────────┘  │
└───────────────────────────────────────────────┘
```

**Security Layers**:
1. **VM isolation**: Each Codespace runs in a dedicated VM
2. **Container isolation**: Development environment containerized
3. **User namespaces**: Rootless container execution
4. **Network segmentation**: Isolated networks for user containers
5. **Resource limits**: CPU/memory quotas enforced

### 8.3 Gitpod

**Implementation**: Automated cloud development environments.

#### **Multi-Mode Configuration**

**.gitpod.yml**:
```yaml
image: gitpod/workspace-full

# Ports
ports:
  - port: 3000
    onOpen: open-preview
  - port: 8080
    onOpen: ignore

# Pre-installed extensions
vscode:
  extensions:
    - dbaeumer.vscode-eslint

# Init tasks
tasks:
  - name: Setup
    init: npm install
    command: npm run dev

# GitHub integration
github:
  prebuilds:
    master: true
    pullRequests: true
```

**Workspace Modes**:
- **Ephemeral**: Short-lived workspaces (destroyed after inactivity)
- **Persistent**: Long-running workspaces with snapshot backups
- **Shared**: Collaborative workspaces with multi-user access

### 8.4 Docker Official Images Security Best Practices

**Real-world pattern**: Official Docker images follow security guidelines.

#### **Example: Node.js Official Image**

```dockerfile
FROM debian:bookworm-slim

# Create non-root user
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# Install Node.js
RUN apt-get update \
  && apt-get install -y ca-certificates curl gnupg \
  && mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
     | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && apt-get update \
  && apt-get install -y nodejs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Switch to non-root user
USER node
WORKDIR /home/node

CMD ["node"]
```

**Security Features**:
- Non-root user (node:node)
- Minimal base image (debian-slim)
- Clean package cache
- Standard UID/GID (1000:1000)

### 8.5 Kubernetes Security Contexts

**Real-world pattern**: Kubernetes Pod Security Standards.

#### **Restricted Pod Security Standard**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
spec:
  securityContext:
    # Run as non-root
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000

    # Kernel restrictions
    seccompProfile:
      type: RuntimeDefault

  containers:
  - name: app
    image: myapp:latest

    securityContext:
      # Capabilities
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL

      # Filesystem
      readOnlyRootFilesystem: true

    # Writable paths
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: var-tmp
      mountPath: /var/tmp

  volumes:
  - name: tmp
    emptyDir:
      sizeLimit: 100Mi
  - name: var-tmp
    emptyDir:
      sizeLimit: 50Mi
```

**Security Features**:
- Non-root user with explicit UID/GID
- No privilege escalation
- All capabilities dropped
- Read-only root filesystem
- Tmpfs with size limits
- Seccomp default profile

### 8.6 Flatpak Sandboxing (Bubblewrap)

**Real-world implementation**: Desktop application sandboxing.

#### **Flatpak Permissions Model**

**Manifest** (org.example.App.json):
```json
{
  "app-id": "org.example.App",
  "runtime": "org.freedesktop.Platform",
  "runtime-version": "23.08",
  "sdk": "org.freedesktop.Sdk",

  "finish-args": [
    /* Filesystem access */
    "--filesystem=home:ro",              /* Home directory read-only */
    "--filesystem=~/Documents:rw",       /* Documents read-write */

    /* Network */
    "--share=network",

    /* Display */
    "--share=ipc",
    "--socket=wayland",
    "--socket=fallback-x11",

    /* Sound */
    "--socket=pulseaudio",

    /* Devices */
    "--device=dri",                      /* GPU access */

    /* Restrictions */
    "--nodevice=all",                    /* Block all devices except explicitly allowed */
    "--nosocket=system-bus"              /* No system D-Bus */
  ]
}
```

**Bubblewrap Invocation** (underlying technology):
```bash
bwrap \
  --ro-bind /usr /usr \
  --ro-bind /etc /etc \
  --tmpfs /tmp \
  --bind $HOME/.var/app/org.example.App $HOME \
  --ro-bind $HOME/Documents $HOME/Documents \
  --unshare-pid \
  --unshare-net \
  --proc /proc \
  --dev /dev \
  /usr/bin/app
```

**Key Patterns for BitBot**:
- Granular filesystem permissions
- Socket-based access control (display, audio, etc.)
- Network unsharing
- PID namespace isolation

### 8.7 Firejail Application Sandboxing

**Real-world implementation**: User-space sandboxing tool.

#### **Firejail Profile for Web Browser**

**/etc/firejail/firefox.profile**:
```
# Firejail profile for Firefox

# Filesystem
whitelist ${HOME}/.mozilla
whitelist ${HOME}/Downloads
whitelist ${DOWNLOADS}

mkdir ${HOME}/.mozilla
mkdir ${HOME}/.cache/mozilla

include disable-common.inc
include disable-programs.inc

# Network
net none  # No network in sketch mode
# OR
# netfilter  # Apply network filter

# Capabilities
caps.drop all
nonewprivs
seccomp

# User namespace
noroot

# Blacklist
blacklist ${HOME}/.ssh
blacklist ${HOME}/.gnupg

# Read-only
read-only ${HOME}/.mozilla/firefox/profiles.ini
```

**BitBot Application**:

**/etc/firejail/bitbot-sketch.profile**:
```
# BitBot Sketch Mode Profile

# Filesystem
whitelist /workspace/sketch
mkdir /workspace/sketch

read-only /workspace
noblacklist /workspace/sketch

include disable-common.inc

# Network (MCP only)
netfilter /etc/firejail/bitbot-mcp.net

# Security
caps.drop all
nonewprivs
seccomp
noroot

# Temporary files
private-tmp

# Blacklist sensitive directories
blacklist /workspace/.devcontainer
blacklist /workspace/.bitbot
blacklist /workspace/.git/config
```

---

## 9. Implementation Recommendations for BitBot

### 9.1 Mode Implementation Matrix

| Feature | Sketch Mode | Work Mode | Setup Mode |
|---------|-------------|-----------|------------|
| **Workspace Mount** | Read-only | Read-write | Read-write |
| **Sketch Directory** | Read-write | Read-write | Read-write |
| **Config Directories** | Read-only | Read-only | Read-write |
| **Root Filesystem** | Read-only | Read-write | Read-write |
| **Tmpfs `/tmp`** | 100MB, noexec | 500MB, noexec | 1GB |
| **User** | bitbot (1000:1000) | bitbot (1000:1000) | root (0:0) or bitbot with sudo |
| **Capabilities** | Drop ALL, add minimal | Drop ALL, add standard | Keep defaults or ALL |
| **no-new-privileges** | true | true | false |
| **AppArmor/SELinux** | Custom restrictive | Docker default | Unconfined |
| **Seccomp** | Custom profile | Docker default | Unconfined |
| **Network** | MCP-minimal (internal) | MCP-workspace (bridge) | Bridge or host |
| **Docker Access** | None | Isolated DinD | Full host Docker |
| **Health Check** | Enabled | Enabled | Enabled |
| **Restart Policy** | unless-stopped | unless-stopped | no |

### 9.2 Recommended Docker Compose Structure

**docker-compose.yml** (consolidated):
```yaml
version: "3.9"

x-common: &common
  image: bitbot:${BITBOT_VERSION:-latest}
  build:
    context: .
    dockerfile: Dockerfile
    args:
      USER_UID: ${USER_UID:-1000}
      USER_GID: ${USER_GID:-1000}
  environment:
    - WORKSPACE_FOLDER=/workspace
    - BITBOT_ROOT=${BITBOT_ROOT}
    - USER_UID=${USER_UID:-1000}
    - USER_GID=${USER_GID:-1000}
    - TZ=${TZ:-UTC}
  working_dir: /workspace
  init: true  # Use tini for proper signal handling

services:
  # Sketch Mode
  bitbot-sketch:
    <<: *common
    profiles: ["sketch"]
    container_name: bitbot-dev-${WORKSPACE_HASH}-sketch
    user: "${USER_UID:-1000}:${USER_GID:-1000}"

    # Security hardening
    security_opt:
      - no-new-privileges:true
      - apparmor:bitbot-sketch
      - seccomp:./security/seccomp-sketch.json
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETUID
      - SETGID

    # Read-only root filesystem
    read_only: true

    # Volumes
    volumes:
      # Workspace read-only
      - type: bind
        source: ${WORKSPACE_FOLDER}
        target: /workspace
        read_only: true

      # Sketch directory read-write
      - type: bind
        source: ${WORKSPACE_FOLDER}/sketch
        target: /workspace/sketch
        read_only: false

      # Tmpfs for temporary files
      - type: tmpfs
        target: /tmp
        tmpfs:
          size: 100m
          mode: 1777
          options: noexec,nosuid,nodev

      - type: tmpfs
        target: /var/tmp
        tmpfs:
          size: 50m
          options: noexec,nosuid,nodev

      # Home directory for user data
      - type: tmpfs
        target: /home/bitbot
        tmpfs:
          size: 100m

      # BitBot state (persistent)
      - bitbot-sketch-state:/workspace/.bitbot/state

    # Network (isolated)
    networks:
      - mcp-minimal

    # Environment
    environment:
      - BITBOT_MODE=sketch
      - NETWORK_POLICY=restricted

    # Health check
    healthcheck:
      test: ["CMD", "/usr/local/bin/health-check.sh"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

    # Restart policy
    restart: unless-stopped

  # Work Mode
  bitbot-work:
    <<: *common
    profiles: ["work"]
    container_name: bitbot-dev-${WORKSPACE_HASH}-work
    user: "${USER_UID:-1000}:${USER_GID:-1000}"

    # Security hardening
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - DAC_OVERRIDE
      - SETUID
      - SETGID
      - NET_BIND_SERVICE

    # Volumes
    volumes:
      # Workspace read-write
      - type: bind
        source: ${WORKSPACE_FOLDER}
        target: /workspace

      # Protect critical directories (read-only overlays)
      - type: bind
        source: ${WORKSPACE_FOLDER}/.devcontainer
        target: /workspace/.devcontainer
        read_only: true

      - type: bind
        source: ${WORKSPACE_FOLDER}/.bitbot
        target: /workspace/.bitbot
        read_only: true

      # Docker socket (isolated DinD)
      - bitbot-user-docker:/var/run/user-docker

      # Cache directories
      - bitbot-work-cache:/home/bitbot/.cache
      - bitbot-work-local:/home/bitbot/.local

    # Networks
    networks:
      - mcp-workspace
      - user-development

    # Environment
    environment:
      - BITBOT_MODE=work
      - DOCKER_HOST=unix:///var/run/user-docker/docker.sock

    # Health check
    healthcheck:
      test: ["CMD", "/usr/local/bin/health-check.sh"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

    # Restart policy
    restart: unless-stopped

  # Setup Mode
  bitbot-setup:
    <<: *common
    profiles: ["setup"]
    container_name: bitbot-dev-${WORKSPACE_HASH}-setup

    # Full privileges
    privileged: true
    user: "0:0"  # Root user

    # Volumes
    volumes:
      # Full workspace read-write
      - type: bind
        source: ${WORKSPACE_FOLDER}
        target: /workspace

      # Full Docker access
      - /var/run/docker.sock:/var/run/docker.sock

      # System directories (read-only)
      - /etc/docker:/etc/docker:ro

    # Networks
    networks:
      - mcp-workspace
      - mcp-global

    # Environment
    environment:
      - BITBOT_MODE=setup
      - DOCKER_HOST=unix:///var/run/docker.sock

    # Health check
    healthcheck:
      test: ["CMD", "/usr/local/bin/health-check.sh"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

    # Restart policy (manual restart only)
    restart: "no"

# Networks
networks:
  mcp-minimal:
    driver: bridge
    internal: true  # No external connectivity
    ipam:
      config:
        - subnet: 172.22.0.0/24

  mcp-workspace:
    driver: bridge
    ipam:
      config:
        - subnet: 172.21.${WORKSPACE_SUBNET:-1}.0/24

  mcp-global:
    external: true
    name: bitbot-mcp-global

  user-development:
    driver: bridge
    ipam:
      config:
        - subnet: 172.23.${WORKSPACE_SUBNET:-1}.0/24

# Volumes
volumes:
  bitbot-sketch-state:
    name: bitbot-${WORKSPACE_HASH}-sketch-state

  bitbot-work-cache:
    name: bitbot-${WORKSPACE_HASH}-work-cache

  bitbot-work-local:
    name: bitbot-${WORKSPACE_HASH}-work-local

  bitbot-user-docker:
    name: bitbot-${WORKSPACE_HASH}-user-docker
```

### 9.3 Dockerfile Recommendations

**Dockerfile**:
```dockerfile
# syntax=docker/dockerfile:1.4

FROM ubuntu:22.04

# Build arguments for user mapping
ARG USER_UID=1000
ARG USER_GID=1000
ARG USERNAME=bitbot

# Environment
ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color

# Install base packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        sudo \
        tmux \
        vim \
        openssh-client \
        gnupg \
        inotify-tools \
        jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user with matching UID/GID
RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Install tini for proper signal handling
RUN curl -fsSL https://github.com/krallin/tini/releases/download/v0.19.0/tini-amd64 \
        -o /usr/local/bin/tini \
    && chmod +x /usr/local/bin/tini

# Copy scripts
COPY --chmod=755 scripts/bitbot-entrypoint.sh /usr/local/bin/
COPY --chmod=755 scripts/health-check.sh /usr/local/bin/
COPY --chmod=755 scripts/bitbot /usr/local/bin/

# Create workspace directory
RUN mkdir -p /workspace \
    && chown ${USER_UID}:${USER_GID} /workspace

# Switch to non-root user
USER ${USERNAME}
WORKDIR /workspace

# Set up tmux configuration
COPY --chown=${USER_UID}:${USER_GID} config/.tmux.conf /home/${USERNAME}/.tmux.conf

# Entry point
ENTRYPOINT ["/usr/local/bin/tini", "--", "/usr/local/bin/bitbot-entrypoint.sh"]
CMD ["/bin/bash"]
```

### 9.4 Security Profile Recommendations

#### **AppArmor Profile for Sketch Mode**

**/etc/apparmor.d/bitbot-sketch**:
```
#include <tunables/global>

profile bitbot-sketch flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  # Network access (MCP services only)
  network inet stream,
  network inet6 stream,
  deny network raw,

  # Workspace read-only
  /workspace/** r,

  # Sketch directory read-write
  /workspace/sketch/** rw,

  # Block writes to protected directories
  deny /workspace/.devcontainer/** w,
  deny /workspace/.bitbot/** w,
  deny /workspace/.git/config w,
  deny /workspace/.env w,
  deny /workspace/.env.* w,

  # Temporary files
  /tmp/** rw,
  /var/tmp/** rw,

  # User home
  /home/bitbot/** rw,

  # System binaries (read-execute)
  /bin/* rix,
  /usr/bin/* rix,
  /usr/local/bin/* rix,

  # Libraries
  /lib/** mr,
  /usr/lib/** mr,

  # Deny dangerous capabilities
  deny capability sys_admin,
  deny capability sys_module,
  deny capability sys_ptrace,
  deny capability sys_boot,
  deny capability sys_time,

  # Proc and sys (limited)
  /proc/** r,
  deny /proc/sys/kernel/** w,
  /sys/** r,
  deny /sys/** w,
}
```

**Load profile**:
```bash
sudo apparmor_parser -r -W /etc/apparmor.d/bitbot-sketch
```

#### **Seccomp Profile for Sketch Mode**

**security/seccomp-sketch.json**:
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_X86",
    "SCMP_ARCH_X32",
    "SCMP_ARCH_AARCH64",
    "SCMP_ARCH_ARM"
  ],
  "syscalls": [
    {
      "names": [
        "accept",
        "accept4",
        "access",
        "bind",
        "brk",
        "chdir",
        "chmod",
        "chown",
        "close",
        "connect",
        "dup",
        "dup2",
        "dup3",
        "execve",
        "exit",
        "exit_group",
        "fchdir",
        "fchmod",
        "fchown",
        "fcntl",
        "fork",
        "fstat",
        "getdents",
        "getdents64",
        "getegid",
        "geteuid",
        "getgid",
        "getpid",
        "getppid",
        "getuid",
        "listen",
        "lseek",
        "lstat",
        "mkdir",
        "mmap",
        "munmap",
        "open",
        "openat",
        "pipe",
        "pipe2",
        "poll",
        "read",
        "recv",
        "recvfrom",
        "recvmsg",
        "rename",
        "rmdir",
        "select",
        "send",
        "sendto",
        "sendmsg",
        "setgid",
        "setuid",
        "socket",
        "stat",
        "unlink",
        "wait4",
        "write"
      ],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": [
        "mount",
        "umount",
        "umount2",
        "pivot_root",
        "chroot",
        "reboot",
        "swapon",
        "swapoff",
        "init_module",
        "delete_module",
        "ptrace",
        "kexec_load"
      ],
      "action": "SCMP_ACT_ERRNO"
    }
  ]
}
```

### 9.5 BitBot Launch Script Integration

**scripts/launch-docker.sh** (enhanced):
```bash
#!/bin/bash
set -euo pipefail

# Determine mode
BITBOT_MODE="${1:-work}"

# Set user UID/GID
export USER_UID=$(id -u)
export USER_GID=$(id -g)

# Set workspace variables
export WORKSPACE_FOLDER="$(pwd)"
export WORKSPACE_HASH=$(echo -n "$WORKSPACE_FOLDER" | sha256sum | cut -c1-8)
export WORKSPACE_SUBNET=$((16#${WORKSPACE_HASH:0:2} % 254 + 1))

# Ensure sketch directory exists for sketch mode
if [ "$BITBOT_MODE" = "sketch" ]; then
    mkdir -p "$WORKSPACE_FOLDER/sketch"
fi

# Ensure BitBot state directory exists
mkdir -p "$WORKSPACE_FOLDER/.bitbot/state"
mkdir -p "$WORKSPACE_FOLDER/.bitbot/backups"

# Create backup before setup mode
if [ "$BITBOT_MODE" = "setup" ]; then
    echo "Creating backup before setup mode..."
    timestamp=$(date +%Y%m%d-%H%M%S)
    tar -czf "$WORKSPACE_FOLDER/.bitbot/backups/pre-setup-$timestamp.tar.gz" \
        --exclude='.git' \
        --exclude='.bitbot/backups' \
        --exclude='node_modules' \
        "$WORKSPACE_FOLDER" 2>/dev/null || echo "Warning: Backup creation failed"
fi

# Launch container with mode-specific profile
echo "Launching BitBot in $BITBOT_MODE mode..."
COMPOSE_PROFILES=$BITBOT_MODE docker-compose up -d

# Wait for container to be healthy
echo "Waiting for container to be healthy..."
timeout 60 bash -c "until docker inspect bitbot-dev-$WORKSPACE_HASH-$BITBOT_MODE | jq -r '.[0].State.Health.Status' | grep -q 'healthy'; do sleep 2; done" || {
    echo "Warning: Container health check timed out"
}

# Attach to tmux session
docker exec -it bitbot-dev-$WORKSPACE_HASH-$BITBOT_MODE \
    /usr/local/bin/bitbot attach
```

### 9.6 Health Check Script

**scripts/health-check.sh**:
```bash
#!/bin/bash

# Check critical processes
check_process() {
    pgrep -x "$1" > /dev/null
}

# Check AI agent
if ! check_process "ai-agent" && [ "$BITBOT_MODE" != "setup" ]; then
    echo "AI agent not running"
    exit 1
fi

# Check MCP services connectivity
if [ "$BITBOT_MODE" != "setup" ]; then
    curl -sf http://mcp-gateway:9090/health > /dev/null || {
        echo "MCP services unreachable"
        exit 1
    }
fi

# Check workspace mount
if [ ! -d "/workspace" ]; then
    echo "Workspace not mounted"
    exit 1
fi

# Check write access (mode-dependent)
case "$BITBOT_MODE" in
    sketch)
        if [ ! -w "/workspace/sketch" ]; then
            echo "Sketch directory not writable"
            exit 1
        fi
        ;;
    work|setup)
        if [ ! -w "/workspace" ]; then
            echo "Workspace not writable"
            exit 1
        fi
        ;;
esac

echo "Health check passed"
exit 0
```

### 9.7 Mode Transition Management

**scripts/bitbot-mode-switch.sh**:
```bash
#!/bin/bash
set -euo pipefail

CURRENT_MODE="${BITBOT_MODE:-work}"
TARGET_MODE="$1"

if [ "$CURRENT_MODE" = "$TARGET_MODE" ]; then
    echo "Already in $TARGET_MODE mode"
    exit 0
fi

echo "Switching from $CURRENT_MODE to $TARGET_MODE mode..."

# Log transition
log_entry=$(cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "from_mode": "$CURRENT_MODE",
  "to_mode": "$TARGET_MODE",
  "workspace": "$WORKSPACE_FOLDER",
  "user": "$USER"
}
EOF
)
echo "$log_entry" >> /workspace/.bitbot/mode-transitions.jsonl

# Create backup if transitioning to setup mode
if [ "$TARGET_MODE" = "setup" ]; then
    echo "Creating backup before setup mode..."
    timestamp=$(date +%Y%m%d-%H%M%S)
    tar -czf "/workspace/.bitbot/backups/pre-setup-$timestamp.tar.gz" \
        --exclude='.git' \
        --exclude='.bitbot/backups' \
        --exclude='node_modules' \
        "/workspace" 2>/dev/null || echo "Warning: Backup creation failed"
fi

# Stop current container
docker-compose --profile "$CURRENT_MODE" down

# Start new container with target mode
COMPOSE_PROFILES="$TARGET_MODE" docker-compose up -d

# Wait for health
echo "Waiting for container to be healthy..."
timeout 60 bash -c "until docker inspect bitbot-dev-$WORKSPACE_HASH-$TARGET_MODE | jq -r '.[0].State.Health.Status' | grep -q 'healthy'; do sleep 2; done" || {
    echo "Warning: Container health check timed out"
}

echo "Mode switch complete: $CURRENT_MODE → $TARGET_MODE"
```

---

## 10. Summary & Quick Reference

### 10.1 Key Takeaways

1. **Multi-mode containers** are achieved through layered security:
   - Mount configurations (RO/RW)
   - Capability restrictions (cap_drop/cap_add)
   - Network isolation (internal/bridge networks)
   - User namespaces (rootless execution)

2. **User namespace mapping** solves UID/GID permission issues:
   - Container root (UID 0) maps to host user (UID 1000)
   - Subordinate UID ranges enable proper isolation
   - Podman provides best rootless experience

3. **Read-only root filesystem** with tmpfs provides strong isolation:
   - Prevents filesystem modification attacks
   - Requires tmpfs mounts for writable paths
   - Must set size limits to prevent memory exhaustion

4. **AppArmor/SELinux** provide mandatory access control:
   - AppArmor: Path-based, simpler (Debian/Ubuntu)
   - SELinux: Label-based, more complex (Red Hat/CentOS)
   - Custom profiles enable fine-grained restrictions

5. **Safety patterns** prevent data loss:
   - Git safe directory configuration
   - Dirty state detection
   - Automatic backups before risky operations
   - Snapshot/rollback capabilities

### 10.2 BitBot Mode Implementation Checklist

#### **Sketch Mode**
- [ ] Mount workspace read-only
- [ ] Mount sketch directory read-write
- [ ] Enable read-only root filesystem
- [ ] Add tmpfs for /tmp (100MB, noexec)
- [ ] Drop all capabilities, add minimal set
- [ ] Enable no-new-privileges
- [ ] Apply restrictive AppArmor/Seccomp profile
- [ ] Use internal network (no internet)
- [ ] Run as non-root user (bitbot)
- [ ] Implement health check
- [ ] Add audit logging

#### **Work Mode**
- [ ] Mount workspace read-write
- [ ] Protect .devcontainer and .bitbot (read-only overlays)
- [ ] Drop all capabilities, add standard set
- [ ] Enable no-new-privileges
- [ ] Apply Docker default AppArmor profile
- [ ] Use isolated Docker-in-Docker
- [ ] Use bridge network (internet access)
- [ ] Run as non-root user (bitbot)
- [ ] Implement health check
- [ ] Add git safe directory config

#### **Setup Mode**
- [ ] Mount workspace read-write
- [ ] Grant full Docker access (host socket)
- [ ] Enable privileged mode or full capabilities
- [ ] Use bridge or host network
- [ ] Run as root or bitbot with sudo
- [ ] Implement health check
- [ ] Create backup before entering mode
- [ ] Add mode transition logging

### 10.3 Security Hardening Checklist

- [ ] **User Management**
  - [ ] Run containers as non-root user
  - [ ] Match container UID/GID to host user
  - [ ] Use user namespaces for rootless execution

- [ ] **Capabilities**
  - [ ] Drop all capabilities by default
  - [ ] Add only required capabilities explicitly
  - [ ] Never use --privileged in production

- [ ] **Filesystem**
  - [ ] Use read-only root filesystem where possible
  - [ ] Mount tmpfs with size limits and noexec
  - [ ] Protect critical files with read-only mounts
  - [ ] Implement file access auditing

- [ ] **Network**
  - [ ] Use internal networks for service isolation
  - [ ] Segment BitBot and user networks
  - [ ] Apply network policies/firewall rules

- [ ] **Security Profiles**
  - [ ] Enable no-new-privileges
  - [ ] Apply AppArmor or SELinux profiles
  - [ ] Use custom Seccomp profiles for strict modes

- [ ] **Monitoring**
  - [ ] Implement health checks
  - [ ] Enable audit logging
  - [ ] Monitor mode transitions
  - [ ] Track file modifications

- [ ] **Recovery**
  - [ ] Create backups before risky operations
  - [ ] Implement snapshot/rollback capabilities
  - [ ] Test disaster recovery procedures
  - [ ] Document recovery steps

### 10.4 Resources

#### **Documentation**
- Docker Security: https://docs.docker.com/engine/security/
- Podman Rootless: https://docs.podman.io/en/latest/markdown/podman.1.html
- AppArmor: https://gitlab.com/apparmor/apparmor/-/wikis/home
- SELinux: https://selinuxproject.org/page/Main_Page
- Seccomp: https://www.kernel.org/doc/html/latest/userspace-api/seccomp_filter.html

#### **Tools**
- Docker: https://www.docker.com/
- Podman: https://podman.io/
- Bubblewrap: https://github.com/containers/bubblewrap
- Firejail: https://firejail.wordpress.com/

#### **Best Practices**
- OWASP Docker Security: https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html
- CIS Docker Benchmark: https://www.cisecurity.org/benchmark/docker
- Kubernetes Security: https://kubernetes.io/docs/concepts/security/

---

## Conclusion

Implementing multi-mode containerized environments with varying permission levels requires a layered security approach combining mount restrictions, capability controls, namespace isolation, and security profiles. BitBot's sketch/work/setup modes can be effectively implemented using Docker Compose profiles with mode-specific configurations.

Key strategies include:
1. **Read-only base mounts** with selective read-write overlays
2. **Capability restrictions** appropriate to each mode's requirements
3. **User namespace mapping** for secure rootless execution
4. **Network segmentation** to isolate infrastructure from user workloads
5. **Safety patterns** including backups, snapshots, and audit logging

Production examples from VS Code DevContainers, GitHub Codespaces, and Kubernetes demonstrate these patterns are battle-tested and scalable. By following the implementation recommendations in this report, BitBot can provide secure, flexible development environments that adapt to different security requirements while maintaining a consistent user experience.

---

**End of Report**
