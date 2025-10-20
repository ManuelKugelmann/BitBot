# BitBot Architecture Decisions

**Status**: Consolidated from Q&A Session
**Last Updated**: 2025-10-17
**Sources**: Claude_Specification, Copilot_Specification, Gemini_Specification

---

## Key Architectural Decisions

### D-01: Container Orchestration Strategy

**Decision**: `@devcontainers/cli` with Docker Compose fallback

**Rationale**:
- Standards-compliant using official `@devcontainers/cli`
- Fallback to custom Docker Compose if problematic
- Work and setup are separate containers (can run simultaneously)
- VS Code compatible for both modes

**Implementation**:
- Work container: Managed by `@devcontainers/cli`
- Setup container: Custom Docker Compose in `.bitbot/setup/`
- Both accessible via host `bitbot` command

**References**: Q1-Q3 from consolidation session

---

### D-02: Security & Mode System

**Decision**: Two modes (work/setup) + git-based protection

**Work Mode**:
- Own `.devcontainer` mounted read-only inside work container
- Workspace read-write
- Git warnings on uncommitted/unpushed changes
- AI agents run inside container

**Setup Mode**:
- Target workspace mounted at `/setup/workspace` (read-write)
- Can modify `.devcontainer` for target workspace
- `.git` folder can be protected (force review before push)
- Separate container from work mode

**Key Protection**:
- `.bitbot/setup/` never mounted (BitBot internals on host)
- Git push/bundle required before destructive operations
- Physical read-only mounts where needed

**References**: Q2, D-03, D-11 from original specs

---

### D-03: CLI Command Structure

**Decision**: Context-aware `bitbot` command (host vs container)

**Host Commands** (Container management):
```bash
bitbot              # Smart launch (config default)
bitbot work         # Launch work container
bitbot setup        # Launch setup container
bitbot vscode       # Launch VS Code (config default mode)
bitbot vscode work  # Launch work in VS Code
bitbot cli          # Launch CLI (config default mode)
bitbot done         # Not applicable on host
```

**Inside Container Commands** (AI/workspace management):
```bash
bitbot              # Launch default AI agent
bitbot <agent>      # Launch specific agent
bitbot done         # Review changes → git push → exit
```

**Rationale**:
- Same command name, behavior depends on context
- Intuitive: "bitbot" always does the right thing
- No mode switching inside containers

**References**: Q4-Q5, D-08

---

### D-04: Windows Integration

**Decision**: Inline WSL execution with VS Code detection

**PowerShell/cmd → WSL**:
- `bitbot.exe` / `bitbot.ps1` launches WSL with login shell (`bash -l`)
- Inline execution (stays in same terminal)
- VS Code detection via `$env:TERM_PROGRAM`
- If VS Code terminal: Stay inline
- If standalone: Can optionally launch new terminal

**PATH Strategy**:
- Load nvm/npm paths (via `-l` flag)
- Prioritize WSL binaries: `/usr/local/bin:/usr/bin:...` prepended
- Keep Windows paths as fallback (don't filter)
- Result: WSL tools preferred, Windows tools accessible

**Line Endings**:
- `.gitattributes`: `*.sh text eol=lf`
- Auto-convert on checkout

**References**: Q22-Q23, Windows launch tests

---

### D-05: MCP Service Architecture

**Decision**: Docker Compose services (global + workspace)

**Global MCPs**:
- Started by BitBot on first run or host boot (optional)
- Shared across all workspaces
- Examples: Git MCP, File MCP, common tools

**Workspace MCPs**:
- Per-workspace `docker-compose.yml` in `.bitbot/mcp/`
- Started with workspace container
- Project-specific services

**Network**:
- Shared Docker network for communication
- MCP registry for service discovery

**References**: Q7, D-04 from original specs

---

### D-06: Session Management

**Decision**: tmux with auto-timestamped sessions

**Sessions** (hidden from user):
- Auto-created with timestamp: `2025-10-17_14-23-45`
- Stored in `.bitbot/sessions/`
- Resumed on re-entry with interactive menu
- User can name/tag sessions (future: AI auto-tagging)

**Inside Container `bitbot` call**:
- Shows detached sessions with context
- Option to create new or attach to existing
- No direct tmux exposure

**References**: Q8-Q9

---

### D-07: Template System

**Decision**: Layered composition (standards-first)

**Layers**:
1. **Tech Stack**: DevContainer Features (python, node, go, etc.)
2. **Add-ons**: Docker Compose services (postgres, redis, etc.)
3. **AI Profile**: Setup scripts + ENV vars (aggressive/balanced/conservative)
4. **Custom**: User scripts in `.devcontainer/setup/`

**Fallback**: Custom scripts only when standard features unavailable

**References**: Q15, D (Hybrid approach)

---

### D-08: First-Run Experience

**Decision**: Quick 3-question setup (host) + workspace setup wizard

**Global Setup** (first `bitbot` run on host):
1. Dependency checks (Git, Docker, @devcontainers/cli, VS Code)
2. Auto-install offers for missing tools
3. Configuration:
   - Default interface: CLI / VSCode
   - Default AI agent: None / Claude / ...
   - Default shell: bash / zsh
   - Auto-start global MCPs on boot: No / Yes
4. Add to PATH, set `BITBOT_HOME`

**Workspace Setup** (first `bitbot` in new folder):
- Enters setup container automatically
- Wizard menu:
  1. Keep current `.devcontainer` (if exists)
  2. Choose from templates
  3. Init from global default template (future)
  4. Exit to shell
  5. Exit to host
- Template flow: Tech Stack → AI Profile → Add-ons → Workspace defaults

**References**: Q16-Q17, Q19

---

### D-09: Installation & Distribution

**Decision**: Git clone from GitHub (trunk-based, self-updating)

**Primary**:
- `git clone https://github.com/.../bitbot` to `~/.bitbot/`
- Portable: Can move folder, still works
- Auto-update: `git pull` in `~/.bitbot/`

**Structure**:
```
~/.bitbot/
├── .git/              (for auto-update)
├── bin/
│   ├── bitbot         (bash script)
│   └── bitbot.exe     (Windows launcher)
├── templates/         (built-in workspace templates)
└── ...
```

**Future**: Package managers (apt, brew, choco)

**References**: Q16, D-07

---

### D-10: Terminal Output

**Decision**: ASCII symbols for maximum compatibility

**Symbol Set**:
- `[+]` Success (green)
- `[X]` Error (red)
- `[!]` Warning (yellow)
- `[>]` Progress/action (cyan)
- `[i]` Info/note (gray)

**Rationale**:
- Works in all terminals (PowerShell, cmd, bash, SSH)
- No Unicode emoji issues
- Professional appearance

**References**: Windows testing, symbol research

---

### D-11: Prerequisites

**Decision**: Docker Desktop required, other tools auto-installable

**Required**:
- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- WSL2 with enabled Docker integration (Windows)
- Git

**Auto-installable**:
- `@devcontainers/cli` (npm install to `~/.local/`)
- Node.js/npm (if missing)
- VS Code extensions (if VS Code present)

**References**: test-docker.ps1, first-run checks

---

### D-12: BitBot WSL Distro (Windows Only)

**Decision**: Dedicated non-default WSL distro for BitBot on Windows

**Problem Discovered**:
- Docker Desktop corrupts default WSL distro's working directory state
- VS Code WSL terminals open at `/mnt/wsl/docker-desktop-bind-mounts/[hash]...` instead of correct path
- Issue is in `wslservice.exe` runtime state (not registry or cache)
- Only affects DEFAULT WSL distro (marked with `*` in `wsl -l -v`)
- 4+ year old bug in Docker Desktop, still present in v4.48 (Dec 2024)

**Solution**:
- Install Alpine Linux as `BitBot-Alpine` (non-default distro)
- Non-default distros are immune to Docker Desktop corruption
- Only 8 MB footprint
- Completely isolated from user's WSL environment

**Implementation**:
```powershell
# Auto-install on first BitBot run (Windows only)
.\install-bitbot-wsl.ps1

# All BitBot commands use BitBot-Alpine
wsl -d BitBot-Alpine bash -l -c "..."
```

**Benefits**:
- ✅ Immune to Docker Desktop corruption
- ✅ User's WSL (Ubuntu/Debian/etc) completely untouched
- ✅ Small footprint (8 MB vs 100-300 MB)
- ✅ Clean separation: user's dev env vs BitBot's env
- ✅ Easy to reset if issues occur (`wsl --unregister BitBot-Alpine`)
- ✅ 99% Linux code maintained (cross-platform goal)

**User Impact**:
- Transparent: User doesn't need to know about corruption issue
- First-run: "Installing BitBot environment (8 MB)..."
- Zero conflict with user's existing WSL setup
- User's default WSL stays default (no changes)

**Technical Details**:
- Alpine Linux v3.19+
- Installed via `wsl --import`
- Contains: bash, git, docker-cli, nodejs, npm, @devcontainers/cli
- Docker Desktop integration: Yes (can run docker commands)
- Default shell: bash (for cross-platform scripts)

**Alternatives Rejected**:
- ❌ Fix Docker Desktop: Not BitBot's responsibility, bug still unfixed after 4+ years
- ❌ Restart wslservice.exe: Breaks Docker Desktop containers
- ❌ Use user's default WSL: Gets corrupted by Docker Desktop
- ❌ Windows-only approach: Defeats 99% Linux code goal
- ❌ Disable Docker integration: Need docker commands from WSL

**References**:
- DOCKER-DESKTOP-CORRUPTION-ANALYSIS.md (full technical analysis)
- install-bitbot-wsl.ps1 (installer)
- Stack Overflow: https://stackoverflow.com/questions/62396010/ (same bug, 2020)

**Platform-Specific**:
- Windows: BitBot-Alpine required
- macOS: Use default shell (no Docker Desktop corruption issue)
- Linux: Use default shell (native Docker, no corruption)

---

## Decision Matrix

| Decision | Priority | Status | MVP |
|----------|----------|--------|-----|
| D-01: Container orchestration | P0 | ✅ Tested | Yes |
| D-02: Security/modes | P0 | ✅ Decided | Yes |
| D-03: CLI structure | P0 | ✅ Decided | Yes |
| D-04: Windows integration | P0 | ✅ Tested | Yes |
| D-05: MCP architecture | P1 | ✅ Decided | Partial |
| D-06: Session management | P1 | ✅ Decided | Basic |
| D-07: Template system | P1 | ✅ Decided | Basic |
| D-08: First-run | P1 | ✅ Decided | Yes |
| D-09: Installation | P0 | ✅ Decided | Yes |
| D-10: Terminal output | P2 | ✅ Tested | Yes |
| D-11: Prerequisites | P0 | ✅ Tested | Yes |
| D-12: BitBot WSL (Windows) | P0 | ✅ Tested | Yes |

---

## Next Steps

1. ✅ All critical decisions made
2. ✅ Windows→WSL→Container flow tested
3. → Implement MVP based on these decisions
4. → Create detailed implementation specs (01-10)

---

**Status**: All architectural decisions finalized
**Ready for**: Implementation phase
