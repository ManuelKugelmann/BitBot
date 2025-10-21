# Future Features and Roadmap

## Brief Mention: Audit Logging, Advanced Network Limiting
- **Audit Logging:** Planned for future releases. Will log privileged actions, mode switches, and file/network access for compliance and debugging.
- **Advanced Network Limiting:** Future versions will add per-mode network restrictions and firewall rules for work and setup modes.

---

## BitBot CLI UX and Command Structure (Proposal)

### Command Philosophy
- Short, memorable commands (e.g., `bitbot work`, `bitbot claude`, `bitbot config`)
- No double-dash flags for common actions
- Composable: `bitbot work vscode --agent claude` (mode + interface + agent)
- Context-aware: adapts to workspace state and user config

### Core Commands
```bash
bitbot                # Smart launch (resume or new session)
bitbot new            # Force new session
bitbot list           # List all sessions
bitbot stop           # Stop current session
bitbot kill           # Stop all BitBot containers
 bitbot work           # Launch in work mode
bitbot setup          # Launch in setup mode
bitbot claude         # Use Claude Code agent
bitbot open           # Use OpenCode agent
bitbot config         # Interactive configuration wizard
bitbot template web   # Apply web development template
bitbot doctor         # System diagnostics
bitbot version        # Version info
```

### UX Details
- **Session Management:** BitBot CLI guides the user to resume, create, or switch sessions.
- **Mode Switching:** Work and setup are separate containers managed by host CLI (no runtime switching inside containers).
- **Agent Selection:** CLI wizard for agent selection/configuration; settings stored in `.bitbot/agent.yml`.
- **Help & Discoverability:** `bitbot help` lists all commands and usage examples.

-- **Experimental Workflow Git Pre-Check:** BitBot provides Git safety checks that verify the working tree is clean before AI-assisted changes. If dirty, BitBot will prompt the user to `Commit`, `Stash`, `Abort`, or `Force`. Git safety is integrated via SPEC-02A.
-- **Experimental Workflows (planned)**: Safe experimental workflows using Git branches will be enhanced in future releases. Uses standard Git workflows (experimental branches, worktrees) rather than a separate mode. Detailed in SPEC-02A (Git Safety Integration).

---

## Next: Workspace State Management and Metadata
- Specification for `.bitbot/` state tracking, session metadata, and mode history will be documented next.

---

## Backlog: Enhanced Experimental Git Workflows

- Priority: Backlogged for post-MVP (recorded so design and implementation can resume later).
- Goal: Provide enhanced Git-based workflows for experimental/agent-driven edits using standard Git features (branches, worktrees).
- **Note**: NOT a separate "sketch mode" - uses work mode with Git branch workflows (see SPEC-02A).
- Planned enhancements (summary):
	- Automated backup via Git bundle before experimental branches
	- Helper commands for creating isolated `git worktree` for experiments
	- CLI helpers for experimental workflow management
	- All actions logged to `.bitbot/audit.log`
- Next steps when unblocked:
	1. Enhance Git safety MCP tools (SPEC-02A)
	2. Add workflow management CLI commands
	3. Integrate with AI agent instructions for experimental branch usage

---

## Backlog: VM-Based Container Deployment

- Priority: Backlogged for Phase 3 (enhanced isolation and cloud deployment).
- Goal: Support VM-backed devcontainer deployment for enhanced security isolation and cloud/remote development workflows.
- Research: Documented in `Research/VM_WRAPPER_SOLUTIONS_RESEARCH.md`

### Approach 1: DevPod Integration (Recommended)

**DevPod** (https://github.com/loft-sh/devpod) provides an open-source, client-only solution for running devcontainers across multiple providers:

**Architecture:**
- Uses standard `devcontainer.json` specification
- Provider-based architecture (Multipass, AWS, GCP, Azure, Kubernetes, Docker)
- Client-agent model with SSH tunneling for IDE connection
- Supports VS Code, VS Code Browser, and JetBrains IDEs

**Benefits for BitBot:**
- ✅ Aligns with BitBot's multi-mode architecture (work/setup containers)
- ✅ VM-level isolation reduces container escape risk
- ✅ Cross-platform (Windows, macOS, Linux)
- ✅ Cloud-ready (AWS, GCP, Azure support)
- ✅ Team-ready (shared infrastructure patterns)
- ✅ No custom configuration needed (uses standard devcontainer.json)

**Implementation Path:**
```bash
# User installs DevPod
devpod provider add multipass

# BitBot wraps DevPod for workspace management
bitbot init --provider devpod-multipass
# Creates DevPod workspace using BitBot's devcontainer.json

bitbot work --provider devpod-multipass
# Launches work container in VM via DevPod
```

**Multipass Provider:**
- Community-maintained provider: https://github.com/minhio/devpod-provider-multipass
- Launches Ubuntu VMs via Multipass, runs devcontainer inside
- `MULTIPASS_MOUNTS` option for host path mounting
- Provides VM isolation with container workflow

### Approach 2: Direct VM Management

**Direct Multipass/Lima Integration:**
- BitBot manages VM lifecycle directly
- Sets up Docker in VM
- Creates Docker context pointing to VM
- Launches devcontainers via `@devcontainers/cli` in VM context

**Benefits:**
- ✅ Simpler for single-user scenarios
- ✅ More control over VM lifecycle
- ✅ No additional dependencies beyond VM tool

**Trade-offs:**
- ❌ More custom setup logic required
- ❌ Less cloud-ready than DevPod
- ❌ Team patterns need custom implementation

### Approach 3: Hybrid Strategy

**Auto-Detection:**
- Check if DevPod is installed → use DevPod provider architecture
- Otherwise → fall back to direct VM management (Multipass/Lima)
- Provide `bitbot doctor` diagnostics for VM backend recommendations

**Benefits:**
- ✅ Best of both worlds
- ✅ Gradual adoption path
- ✅ Graceful fallback

### Security Benefits

VM wrapping provides additional isolation layer:

| Solution              | Isolation Level      | Kernel Sharing | Container Escape Risk |
|-----------------------|----------------------|----------------|-----------------------|
| Standard Docker       | Namespace/cgroups    | ✅ Yes         | Medium                |
| VM + Docker           | VM + namespace       | ❌ No (VM)     | Low                   |
| Kata Containers       | Micro-VM per container| ❌ No         | Very Low              |

**For BitBot:** VM wrapper significantly reduces container escape risk by adding VM-level isolation, especially important for AI agent workloads with elevated privileges.

### VM Solution Comparison

| Solution      | Platform          | VM Type       | Devcontainer | Best For              |
|---------------|-------------------|---------------|--------------|------------------------|
| **DevPod**    | All               | Multi-provider| ✅ Native    | Multi-cloud, teams    |
| **Multipass** | All               | Ubuntu VM     | ✅ Via setup | Simple Ubuntu VMs     |
| **Colima**    | macOS/Linux       | Multi-distro  | ✅ Docker    | macOS Docker replace  |
| **OrbStack** | macOS             | Shared kernel | ✅ Docker    | macOS performance     |
| **Vagrant**   | All               | Full VMs      | ⚠️  SSH      | Complex full-stack    |

### Implementation Phases

**Phase 3a: Research & Prototype** (Week 11-12)
1. Validate DevPod integration with BitBot's devcontainer configs
2. Test Multipass provider with work/setup container patterns
3. Benchmark performance vs. native Docker
4. Document security benefits

**Phase 3b: DevPod Integration** (Week 13-15)
1. Add `--provider` flag to BitBot CLI
2. Implement DevPod workspace creation
3. Add provider selection to `bitbot init` wizard
4. Document VM backend setup for users

**Phase 3c: Cloud Provider Support** (Week 16+)
1. Test AWS/GCP/Azure providers
2. Add cloud cost estimation warnings
3. Document team deployment patterns
4. Add `bitbot cloud` command for cloud workspace management

### Future Command Extensions

```bash
# Provider management
bitbot init --provider devpod-multipass    # Use Multipass VM
bitbot init --provider devpod-aws          # Use AWS EC2
bitbot init --provider docker              # Use Docker (default)

# Provider info
bitbot provider list                       # List available providers
bitbot provider info multipass             # Show provider details

# Cloud deployment
bitbot cloud deploy --provider aws         # Deploy workspace to AWS
bitbot cloud cost                          # Estimate cloud costs
bitbot cloud destroy                       # Tear down cloud resources
```

### References

- DevPod Documentation: https://devpod.sh
- Multipass Provider: https://github.com/minhio/devpod-provider-multipass
- VM Wrapper Research: `Research/VM_WRAPPER_SOLUTIONS_RESEARCH.md`
- DevPod Architecture: https://devpod.sh/docs/how-it-works/overview
