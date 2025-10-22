## General Guidelines

- **Specs**: Use bulletpoints/pseudocode only, no extensive code
- **Missing tools**: Install if you have rights, else guide user (apt/curl/wget)
- **Questions**: One at a time, use unicode symbols/colors for pros/cons in tables
- **Tables**: Align in monospace, keep narrow for terminals (unicode = 2 chars width)
- **Follow-up**: Ask for thoughts after answers, give hints
- **Line endings**: bash/sh=LF, ps1/bat/cmd=CRLF (use `.gitattributes` + tools below)
- **Syntax**: Check bash scripts after editing (use tools below)

## DevContainer Context

**IMPORTANT**: BitBot has two separate devcontainer contexts - do NOT confuse them!

| Context                | Location                  | Purpose                      | Notes                        |
|------------------------|---------------------------|------------------------------|------------------------------|
| **BitBot Development** | `/.devcontainer/`         | Develop BitBot itself        | MinGW, BitBot dev tools      |
| **Workspace**          | `/templates/workspace/`   | User AI workspaces           | Claude Code, AI tools, shared home folders |

**Key Points**:
- `/.devcontainer/` = **For BitBot contributors** (developing BitBot)
- `templates/workspace/` = **For BitBot users** (AI-powered development)
- Do NOT modify root `/.devcontainer/` unless working on BitBot itself
- Workspace templates include shared home folders for AI tool configs
- See `templates/workspace/README.md` for workspace template docs

## Available Tools

**IMPORTANT**: ALWAYS use these tools instead of raw `dos2unix` or `sed` commands. These are auto-approved and don't require user confirmation.

**fix-and-check-bash** ⭐ (recommended)
- Fixes CRLF→LF then checks bash syntax in one step
- Use after creating/editing bash scripts
- Example: Use fix-and-check-bash tool with files: ["script.sh"]
- Auto-approved

**fix-line-endings**
- Converts CRLF→LF only
- Use when: `/bin/bash: line 1: $'\r': command not found`
- Example: Use fix-line-endings tool with files: ["script.sh", "another.sh"]
- Auto-approved

**check-bash-syntax**
- Validates bash syntax without execution
- Use before committing bash scripts
- Example: Use check-bash-syntax tool with files: ["script.sh"]
- Auto-approved

**run-with-timeout**
- Runs a command with timeout to prevent hangs
- Use for potentially long-running test commands
- Example: `.claude/tools/run-with-timeout 30 ./test-script.sh`
- Auto-approved

**DO NOT USE**: `dos2unix file.sh` or `sed -i 's/\r$//' file.sh` directly - use tools above instead!


**IMPORTANT**: ALWAYS use `devcontainer.cmd` on Windows or WSL!
**DO NOT USE**: `devcontainer` on Windows or WSL - it corrupts WSL paths and breaks docker!
- **DO NOT** create copies of files when interation on the implementation. Only create copies  when explicitely requested.

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
   - Write test script in `tests/test-<feature>.sh`
   - Include bash syntax check, unit tests, integration tests
   - Use clear test names and section headers
   - Follow existing test structure (see `tests/test-container-bitbot.sh`)

2. **Run Tests in WSL**:
   - Run directly: `./tests/test-<feature>.sh`
   - Fix CRLF issues: `sed -i 's/\r$//' tests/test-<feature>.sh`
   - Debug failures individually before moving on

3. **Fix Issues**:
   - Fix line endings in tested code (use `sed -i 's/\r$//'`)
   - Fix logic errors one at a time
   - Rerun tests after each fix
   - Don't commit until all tests pass

4. **Commit After Success**:
   - Commit line ending fixes separately
   - Commit test suite with results in commit message
   - Add test to `tests/run-tests.sh` if appropriate

5. **Test Framework**:
   - Use `run_test()`, `test_passed()`, `test_failed()` helpers
   - Show colored output (GREEN=pass, RED=fail, BLUE=section)
   - Print summary with success rate
   - Exit 0 if all pass, exit 1 if any fail

**Example Workflow**:
```bash
# 1. Create test
vim tests/test-feature.sh
chmod +x tests/test-feature.sh

# 2. Run and fix line endings
./tests/test-feature.sh  # May fail with CRLF error
sed -i 's/\r$//' tests/test-feature.sh
sed -i 's/\r$//' feature/script.sh

# 3. Rerun until passing
./tests/test-feature.sh  # Fix issues, rerun

# 4. Commit
git add feature/script.sh
git commit -m "Fix line endings"
git add tests/test-feature.sh
git commit -m "Add feature test suite (28/28 pass)"
```

## Additional Guidelines

- **DO NOT** overengineer or add unasked for features
- **DO NOT** add backward compatibility for previous implementation iteration steps
- **DO NOT** create copies of files when iterating. Only create copies when explicitly requested
- **DO** align columns in .md tables
- **DO** use mermaid for flow diagrams
- **DO** take small steps to avoid getting overwhelmed
- **DO NOT** attempt big refactorings or implementation steps in one go
- **DO NOT** use pwsh to run PowerShell scripts
- **DO NOT** add 🤖 Generated with [Claude Code] or Co-Authored-By to commits

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
- DO step by step, small steps, create TODO list for steps. test after steps. fix. commit if working.\
DON'T: large changes, multiple changes, large combined commits
- DO use worktrees when doing more complex git work like e.g. a release.