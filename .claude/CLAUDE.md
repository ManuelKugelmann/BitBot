## Project Structure

BitBot follows a clean separation between core functionality, development artifacts, templates, and documentation.

### Top-Level Organization

```
BitBot/
├── bitbot              # Main launcher (bash)
├── bitbot.cmd          # Windows CMD launcher
├── bitbot.exe          # Windows compiled launcher
├── core/               # Host-side BitBot implementation (shell scripts)
├── container/          # Container-related files
│   ├── bitbot/        # Container-side BitBot runtime (commands, utilities)
│   └── templates/     # DevContainer templates
│       ├── base/      # Minimal BitBot container
│       ├── config/    # BitBot with configuration tools
│       ├── bitbotdev/ # BitBot development container
│       ├── workspace/ # AI-powered workspace container
│       ├── custom/    # User custom templates
│       └── shared/    # Shared scripts and configs
├── dev/                # Development artifacts (scripts, src, tests)
├── sparc/              # SPARC methodology documentation
├── .claude/            # Claude Code configuration (CLAUDE.md, tools/)
├── .devcontainer/      # BitBot development container
└── .github/            # GitHub workflows
```

### Core Directories

| Directory                      | Purpose                              | Naming Convention   |
| ------------------------------ | ------------------------------------ | ------------------- |
| `/core/`                       | Host-side BitBot (shell)             | kebab-case.sh       |
| `/container/bitbot/`           | Container-side BitBot runtime        | kebab-case.sh       |
| `/container/templates/`        | DevContainer templates               | lowercase/          |
| `/container/templates/shared/` | Shared scripts and configs           | kebab-case          |
| `/dev/`                        | Development artifacts                | kebab-case          |
| `/sparc/`                      | SPARC documentation                  | (see SPARC section) |
| `/.claude/`                    | Claude Code config                   | kebab-case          |
| `/.devcontainer/`              | BitBot dev container                 | lowercase           |

### Development Artifacts (/dev/)

Development-related files organized under `/dev/`:

| Directory       | Purpose                              | Examples                          |
| --------------- | ------------------------------------ | --------------------------------- |
| `/dev/scripts/` | Release and build scripts            | `create-release-branch.sh`        |
| `/dev/src/`     | Source code (e.g., Windows launcher) | `launcher_windows/launcher.c`     |
| `/dev/tests/`   | Test suites                          | `test-container-bitbot.sh`        |

### Naming Conventions

**Shell Scripts** (`.sh` files):
- Use **kebab-case**: `fix-line-endings.sh`, `test-prerequisites.sh`
- Always include `.sh` extension
- Mark executable with `chmod +x`

**Documentation** (`.md` files):
- Root docs: **kebab-case** (`README.md`, `README-EXTENDED.md`)
- SPARC research: **UPPERCASE_UNDERSCORE** (`AI_AGENT_RESEARCH.md`)
- SPARC specs: **Numbered UPPERCASE** (`01_CONTAINER_ORCHESTRATION.md`)
- Architecture: **numbered-kebab-case** (`01-system-overview.md`)

**Directories**:
- Use **lowercase** or **kebab-case**: `core/`, `container-bitbot/`, `sparc/`
- Template types: lowercase single words (`base/`, `config/`, `dev/`, `workspace/`)

**Configuration Files**:
- JSON: lowercase or dot-separated (`devcontainer.json`, `settings.local.json`)
- Dockerfile: `Dockerfile` (standard naming)
- YAML: kebab-case (`.github/workflows/release.yml`)

### Container Templates

Templates under `container/templates/`:

| Template     | Purpose                     | Features                          |
| ------------ | --------------------------- | --------------------------------- |
| `base/`      | Minimal BitBot              | Core only, no extras              |
| `config/`    | BitBot with configuration   | + Config tools, JSON editing      |
| `bitbotdev/` | BitBot development          | + Build tools, shared home        |
| `workspace/` | AI-powered workspaces       | + Claude Code, AI tools, MCP      |
| `custom/`    | User custom templates       | User-defined (uses workspace base)|
| `shared/`    | Shared resources            | Scripts, configs used by all      |

Each template contains:
- `Dockerfile` - Container image definition
- `devcontainer.json` - VS Code DevContainer config (generated from base + details)
- `details.devcontainer.json` - Template-specific settings
- `README.md` - Template documentation

**Template Merging**:
- Templates are built by merging `shared/base.devcontainer.json` + `details.devcontainer.json`
- Custom templates use `workspace/` as their base template
- Container runtime scripts in `container/bitbot/` are mounted at `/usr/local/bitbot`
- During `bitbot init`, scripts are copied to `.devcontainer/bitbot/` in user workspace

## SPARC Process

BitBot follows the **SPARC** methodology for structured development:

| Phase                   | Folder                   | Purpose                                      |
| ----------------------- | ------------------------ | -------------------------------------------- |
| **0. Research**         | `sparc/0-research/`      | Background research, standards, constraints  |
| **1. Specification**    | `sparc/1-specification/` | Requirements, use cases, acceptance criteria |
| **2. Pseudocode**       | `sparc/2-pseudocode/`    | Algorithm design, logic flows                |
| **3. Architecture**     | `sparc/3-architecture/`  | System design, diagrams, component structure |
| **4. Refinement**       | `sparc/4-refinement/`    | POCs, tests, iterations, optimizations       |
| **5. Completion**       | `sparc/5-completion/`    | Completion metadata, TODOs, progress tracking |

**Usage Guidelines**:
- Research findings → `sparc/0-research/`
- Specifications → `sparc/1-specification/`
- Design docs → `sparc/3-architecture/`
- POC tests → `sparc/4-refinement/poc-tests/`
- Completion metadata → `sparc/5-completion/` (TODO-TRACKER.md, SPEC-TODO.md, progress docs)
- Release scripts → `dev/scripts/`
- Source code (e.g. launcher) → `dev/src/`
- Test suites → `dev/tests/`
- Core implementation → `/core/` (host-side BitBot shell scripts)
- Container runtime → `/container/bitbot/` (container-side BitBot)
- Container templates → `container/templates/` (base, config, bitbotdev, workspace)
- Custom templates → `container/templates/custom/` (user workload templates)
- DO NOT put core implementation code in sparc/ folders
- DO reference sparc/ docs when implementing features

## General Guidelines

- **Specs**: Use bulletpoints/pseudocode only, no extensive code
- **Clarity** Use concise text. Use lists, colors and symbols to structure.
- **Missing tools**: Install if you have rights, else guide user (apt/curl/wget)
- **Questions**: One at a time, use unicode symbols/colors for pros/cons in tables
- **Tables**: Align in monospace, keep narrow for terminals (unicode = 2 chars width)
- **Follow-up**: Ask for thoughts after answers, give hints
- **Line endings**: bash/sh=LF, ps1/bat/cmd=CRLF (use `.gitattributes` + tools below)
- **Syntax**: Check bash scripts after editing (use tools below)

**IMPORTANT**: **DO** use `devcontainer.cmd` on Windows or WSL! **DO** wrap it with `cmd.exe` if running from WSL.

**WARNING: DO NOT USE**: `devcontainer` on Windows or WSL - it corrupts WSL paths and breaks docker!

- **DO NOT** create copies of files when interation on the implementation. Only create copies  when explicitely requested.
- **DO NOT** overengineer or add unasked for features
- **DO NOT** add backward compatibility for previous implementation iteration steps
- **DO NOT** create copies of files when iterating. Only create copies when explicitly requested
- **DO** align columns in .md tables
- **DO** use mermaid for flow diagrams
- **DO** take small steps to avoid getting overwhelmed
- **DO NOT** attempt big refactorings or implementation steps in one go
- **DO NOT** use pwsh to run PowerShell scripts
- **DO NOT** add 🤖 Generated with [Claude Code] or Co-Authored-By to commits
- DO step by step, small steps, create TODO list for steps. test after steps. fix. commit if working.
- DON'T: large changes, multiple changes, large combined commits
- DO use worktrees when doing more complex git work like e.g. a release.
- **DO** ask the user for manual execution of any commands requiring `sudo`. `sudo`does not work in claude code TUI.
- **DO NOT** use bash echo to output instructions to the user, just directly use claude code text output.

## DevContainer Context

**IMPORTANT**: BitBot has two separate devcontainer contexts - do NOT confuse them!

| Context                | Location                            | Purpose               | Notes                                      |
| ---------------------- | ----------------------------------- | --------------------- | ------------------------------------------ |
| **BitBot Development** | `/.devcontainer/`                   | Develop BitBot itself | MinGW, BitBot dev tools                    |
| **BitBot Dev Template**| `/container/templates/bitbotdev/`   | BitBot dev container  | Template for BitBot development            |
| **User Workspace**     | `/container/templates/workspace/`   | User AI workspaces    | Claude Code, AI tools, shared home folders |

**Key Points**:

- `/.devcontainer/` = **For Claude Code dev** (developing BitBot with Claude Code)
- `container/templates/bitbotdev/` = **BitBot dev template** (for building dev containers)
- `container/templates/workspace/` = **For BitBot users** (AI-powered development)
- Do NOT modify root `/.devcontainer/` unless working on BitBot itself
- Workspace templates include shared home folders for AI tool configs
- See `container/templates/workspace/README.md` for workspace template docs

## Git Worktree Workflow for Multi-Agent Development

**IMPORTANT**: Each Claude Code instance should work in its own isolated git worktree to prevent conflicts when multiple agents work simultaneously.

### Why Worktrees?

| Problem | Solution with Worktrees |
|---------|-------------------------|
| Multiple Claude instances conflict | Each has isolated directory |
| Branch switching loses context | Each worktree has dedicated branch |
| Parallel feature development | Work on multiple tasks simultaneously |
| Merge conflicts between agents | Clean separation, sync when ready |

### Quick Start

```bash
# Create new worktree for this Claude instance
.claude/tools/worktree-manager.sh create

# Sync with main branch (get latest changes from other agents)
.claude/tools/worktree-manager.sh sync

# Check status of all worktrees
.claude/tools/worktree-manager.sh status

# Clean up finished work
.claude/tools/worktree-manager.sh clean
```

### Recommended Workflow

**1. Create Isolated Worktree**
```bash
# Auto-generated timestamped branch (claude-YYYYMMDD-HHMMSS)
.claude/tools/worktree-manager.sh create

# Or named feature branch (becomes claude-feature-name)
.claude/tools/worktree-manager.sh create feature-name
```

**2. Work in Worktree**
```bash
# Switch to your worktree
cd ~/.bitbot-worktrees/claude-20251025-214500

# Do your work, make commits
git add .
git commit -m "Add feature"
```

**3. Sync Regularly**
```bash
# Pull latest changes from main branch (trunk)
.claude/tools/worktree-manager.sh sync

# Resolve any conflicts if they occur
```

**4. Create PR or Merge**
```bash
# Push your branch
git push -u origin claude-20251025-214500

# Create PR via gh CLI or web interface
gh pr create --title "Feature description" --body "Details..."
```

**5. Clean Up After Merge**
```bash
# Remove worktree and branch after PR is merged
.claude/tools/worktree-manager.sh clean
```

### Worktree Manager Commands

| Command | Description | Example |
|---------|-------------|---------|
| `create [name]` | Create new worktree with timestamped branch | `.claude/tools/worktree-manager.sh create` |
| `list` | List all worktrees | `.claude/tools/worktree-manager.sh list` |
| `sync` | Sync current worktree with main branch | `.claude/tools/worktree-manager.sh sync` |
| `status` | Show status of all worktrees | `.claude/tools/worktree-manager.sh status` |
| `remove <name>` | Remove specific worktree | `.claude/tools/worktree-manager.sh remove claude-xxx` |
| `clean` | Remove merged worktrees | `.claude/tools/worktree-manager.sh clean` |

### Configuration

Environment variables (optional):

```bash
# Base directory for worktrees (default: ~/.bitbot-worktrees)
export WORKTREE_BASE="$HOME/projects/bitbot-work"

# Branch name prefix (default: claude)
export BRANCH_PREFIX="agent"

# Main branch to sync with (default: trunk)
export MAIN_BRANCH="main"
```

### Best Practices

**DO:**
- ✓ Create new worktree for each Claude instance/task
- ✓ Sync regularly with main branch (multiple times per session)
- ✓ Use timestamped branches for automatic naming
- ✓ Clean up merged worktrees to save space
- ✓ Commit frequently within your worktree

**DON'T:**
- ✗ Work directly in main project directory with multiple instances
- ✗ Share worktrees between Claude instances
- ✗ Forget to sync before starting major work
- ✗ Leave worktrees around after merging

### Troubleshooting

**Merge conflicts during sync:**
```bash
# After running sync, if conflicts occur:
# 1. Fix conflicts in files
# 2. Stage resolved files
git add <resolved-files>
# 3. Complete merge
git commit
```

**Can't remove worktree (files in use):**
```bash
# Force remove
git worktree remove <path> --force
```

**Lost track of worktrees:**
```bash
# List all worktrees
.claude/tools/worktree-manager.sh list

# Show detailed status
.claude/tools/worktree-manager.sh status
```

## Available Tools

**IMPORTANT**: ALWAYS use these tools instead of raw `dos2unix` or `sed` commands. These are auto-approved and don't require user confirmation.

**fix-line-endings**

- Converts CRLF→LF only (no syntax check)
- Use when: `/bin/bash: line 1: $'\r': command not found`
- Example: `.claude/tools/fix-line-endings script.sh another.sh`
- Auto-approved

**check-bash**

- Validates bash syntax without execution or modifications
- Use before committing bash scripts
- Example: `.claude/tools/check-bash script.sh`
- Auto-approved

**fix-line-endings-check-bash** ⭐ (recommended)

- Fixes CRLF→LF then checks bash syntax in one step
- Use after creating/editing bash scripts
- Example: `.claude/tools/fix-line-endings-check-bash script.sh another.sh`
- Auto-approved

**run-with-timeout**

- Runs a command with timeout to prevent hangs
- Use for potentially long-running test commands
- Example: `.claude/tools/run-with-timeout 30 ./test-script.sh`
- Auto-approved

**worktree-manager** ⭐ (multi-agent workflow)

- Manages git worktrees for isolated Claude instances
- Creates timestamped branches automatically
- Syncs with main branch to get updates from other agents
- Example: `.claude/tools/worktree-manager.sh create`
- Auto-approved for all operations
- See "Git Worktree Workflow" section above for full guide

**DO NOT USE**: `dos2unix file.sh` or `sed -i 's/\r$//' file.sh` directly - use tools above instead!

## PowerShell/CMD from WSL

**PowerShell commands**:

- Single command: `powershell.exe -Command "command"`
- Run script: `powershell.exe -File "script.ps1"`
- Faster (no profile): `powershell.exe -NoProfile -Command "..."`

**CMD files (.cmd/.bat)**:

- ALWAYS use cmd.exe: `cmd.exe /c "command.cmd args"`
- For devcontainer: `cmd.exe /c "cd /d C:\Path && devcontainer.cmd build --workspace-folder ."`
- **DO NOT** call .cmd files via PowerShell - use cmd.exe wrapper

**Paths**:

- WSL paths work: `/mnt/c/Projects/...`
- Windows paths: `C:\Projects\...` (escape backslashes in quotes)

## Testing Guidelines

**Process**: Step-by-step testing with todo list tracking

1. **Create Tests**:

   - Write test script in `dev/tests/test-<feature>.sh`
   - Include bash syntax check, unit tests, integration tests
   - Use clear test names and section headers
   - Follow existing test structure (see `dev/tests/test-container-bitbot.sh`)
1. **Run Tests in WSL**:

   - Fix line endings + check syntax: `.claude/tools/fix-line-endings-check-bash dev/tests/test-<feature>.sh`
   - Run with timeout: `.claude/tools/run-with-timeout 60 dev/tests/test-<feature>.sh`
   - Debug failures individually before moving on
1. **Fix Issues**:

   - Fix line endings: `.claude/tools/fix-line-endings file.sh` (or use fix-line-endings-check-bash)
   - Check syntax only: `.claude/tools/check-bash file.sh`
   - Fix logic errors one at a time
   - Rerun tests after each fix
   - Don't commit until all tests pass
1. **Commit After Success**:

   - Commit line ending fixes separately
   - Commit test suite with results in commit message
   - Add test to `dev/tests/run-tests.sh` if appropriate
1. **Test Framework**:

   - Use `run_test()`, `test_passed()`, `test_failed()` helpers
   - Show colored output (GREEN=pass, RED=fail, BLUE=section)
   - Print summary with success rate
   - Exit 0 if all pass, exit 1 if any fail

**Example Workflow**:

```bash
# 1. Create test
vim dev/tests/test-feature.sh
chmod +x dev/tests/test-feature.sh

# 2. Fix line endings and check syntax (use tools!)
.claude/tools/fix-line-endings-check-bash dev/tests/test-feature.sh
.claude/tools/fix-line-endings-check-bash feature/script.sh

# 3. Run tests with timeout to prevent hangs
.claude/tools/run-with-timeout 60 dev/tests/test-feature.sh

# 4. Fix issues and rerun
# ... fix logic errors ...
.claude/tools/run-with-timeout 60 dev/tests/test-feature.sh

# 5. Commit
git add feature/script.sh
git commit -m "Fix line endings"
git add dev/tests/test-feature.sh
git commit -m "Add feature test suite (28/28 pass)"
```

## Mermaid Diagram Guidelines

**Color Scheme** (simplified from FLOW_INNER_BITBOT):

```
Entry/CLI:       #4a9eff  (blue)     - User input, CLI, entry points
Decisions:       #ffa726  (orange)   - Prompts, checks, config, warnings
Success/Work:    #66bb6a  (green)    - Work mode, done, safe operations
Errors:          #ef5350  (red)      - Errors only
```

**Text Color Rules**:

- Blue (#4a9eff): No color needed (dark enough)
- Orange (#ffa726): ALWAYS add `color:#333` (dark text on bright background)
- Green (#66bb6a): ALWAYS add `color:#333` (dark text on bright background)
- Red (#ef5350): ALWAYS add `color:#333` (dark text on bright background)
- Format: `fill:#COLOR,stroke:#333,stroke-width:2px,color:#333`

**Width**: Keep diagrams narrow (~60 chars per line) for terminal viewing

**Example**:

```mermaid
graph LR
    A[User Input] --> B[Decision]
    B --> C[Work Mode]
    style A fill:#4a9eff,stroke:#333,stroke-width:2px
    style B fill:#ffa726,stroke:#333,stroke-width:2px,color:#333
    style C fill:#66bb6a,stroke:#333,stroke-width:2px,color:#333
```