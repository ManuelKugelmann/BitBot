## General Guidelines

- **Specs**: Use bulletpoints/pseudocode only, no extensive code
- **Missing tools**: Install if you have rights, else guide user (apt/curl/wget)
- **Questions**: One at a time, use unicode symbols/colors for pros/cons in tables
- **Tables**: Align in monospace, keep narrow for terminals (unicode = 2 chars width)
- **Follow-up**: Ask for thoughts after answers, give hints
- **Line endings**: bash/sh=LF, ps1/bat/cmd=CRLF (use `.gitattributes` + tools below)
- **Syntax**: Check bash scripts after editing (use tools below)

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

**Color Scheme** (keep diagrams consistent, optimized for dark text):
```
User/Entry:      #4a9eff  (blue)     - CLI, user interface
Secure/Work:     #66bb6a  (green)    - Work mode, safe operations
Config/Infra:    #ffb6c1  (pink)     - Config mode, infrastructure
Router/Key:      #ffd700  (gold)     - Main routers, key components
Warning/Error:   #ef5350  (red)      - Errors, security boundaries
Notice/Prompt:   #ffa726  (orange)   - Prompts, decisions
```

**Text Color Rules**:
- Bright backgrounds (green, pink, gold, red, orange): Use `color:#333` (dark text)
- Dark backgrounds (blue): Can omit color or use white text
- Always include: `fill:#COLOR,stroke:#333,stroke-width:2px,color:#333`

**Width**: Keep diagrams narrow (~60 chars per line) for terminal viewing

**Example**:
```mermaid
graph LR
    A[User Input] --> B[Router]
    B --> C[Work Mode]
    style A fill:#4a9eff,stroke:#333,stroke-width:2px
    style B fill:#ffd700,stroke:#333,stroke-width:2px,color:#333
    style C fill:#66bb6a,stroke:#333,stroke-width:2px,color:#333
```
- DO step by step, small steps, create TODO list for steps. test after steps. fix. commit if working.\
DON'T: large changes, multiple changes, large combined commits