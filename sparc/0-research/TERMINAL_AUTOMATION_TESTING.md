# Terminal Automation Testing Options

Research for implementing in-container and user flow tests with better output capture.

## Problem

Current user flow tests use tmux for:
- Running BitBot in isolated sessions
- Sending input via `tmux send-keys`
- Capturing output via `tmux capture-pane -p`

**Issues:**
- Nested tmux (running tmux inside a container already in tmux) can be problematic
- Timing issues require brittle sleep-based waits
- Output capture is snapshot-based, not stream-based

## Options Evaluated

### 1. Expect (TCL-based)

**Purpose:** Automate interactions with interactive programs

**Pros:**
- Specifically designed for automating interactive CLI programs
- Pattern matching for output (`expect "pattern"`)
- Built-in timeout handling
- Captures output in buffers (`$expect_out(buffer)`)
- Industry standard for automation (telnet, ssh, passwd, etc.)
- Better timing - waits for specific patterns instead of fixed sleep

**Cons:**
- Requires TCL knowledge
- Different language from our bash scripts
- More complex for simple cases
- Not always installed by default

**Use Case:** Best for complex interactive workflows with conditional branching

**Example:**
```tcl
#!/usr/bin/expect -f

spawn ./bitbot init
expect "Select template:" { send "1\r" }
expect "Continue?" { send "y\r" }
expect eof
```

### 2. GNU Screen

**Purpose:** Terminal multiplexer (like tmux)

**Pros:**
- Can send commands: `screen -X stuff 'command'`
- Session management
- Widely available

**Cons:**
- Very similar to tmux (same nested session issues)
- Less modern API than tmux
- Harder to script than tmux
- No significant advantage over current tmux approach

**Use Case:** Not recommended - no benefit over tmux

### 3. Unix `script` Command

**Purpose:** Record terminal sessions to file

**Pros:**
- Simple: `script -c "command" output.txt`
- Captures all output including formatting
- Available on all Unix systems
- No nested session issues
- Can run in background or foreground

**Cons:**
- Non-interactive (can't send input during execution)
- Captures raw terminal codes (may need stripping)
- No pattern matching
- Less control over timing

**Use Case:** Good for simple non-interactive command output capture

**Example:**
```bash
script -c "bitbot --version" /tmp/output.txt
# Later analyze output.txt
grep "BitBot version" /tmp/output.txt
```

### 4. Pseudo-TTY (pty) with Script Wrappers

**Purpose:** Programmatic control of pseudo-terminals

**Pros:**
- Full control over I/O
- Can be interactive or scripted
- No session multiplexer needed
- Better for in-container testing

**Cons:**
- More complex to implement
- Requires careful pty handling
- May need external tools (socat, unbuffer)

**Tools:**
- `unbuffer` (from expect-dev) - run program without buffering
- `socat` - bidirectional pipe with pty support
- Python `pty` module

**Example:**
```bash
unbuffer bitbot init < input.txt > output.txt
```

### 5. Combination: Tmux + Script + Expect

**Purpose:** Use each tool for its strength

**Pros:**
- Tmux for session isolation (host-level tests)
- Script for simple output capture (non-interactive)
- Expect for complex interactions (wizard flows)
- Can mix and match based on test needs

**Cons:**
- Multiple tools to maintain
- Different syntax per tool

## Recommendations

### For Different Test Types

| Test Type | Recommended Tool | Reason |
|-----------|-----------------|--------|
| **Host-level user flows** | Tmux (current) | Works well, familiar, good output capture |
| **In-container interactive** | Expect | Best for complex wizards, handles timing better |
| **In-container simple commands** | Script command | Simple, no nesting issues, captures all output |
| **Background process testing** | Script + signals | Run in background, capture output, send signals |

### Specific Implementations

#### 1. Keep Tmux for Host-Level Tests
Current `test-user-flow-*.sh` tests work well with tmux. Keep them.

**When to use:**
- Testing BitBot from host
- Multiple parallel sessions
- Long-running interactive tests

#### 2. Add Expect for Container Wizard Tests
For testing inside containers where we need interactive input.

**When to use:**
- `bitbot init` wizard inside container
- `bitbot work` with prompts
- Template selection flows

**Example test:**
```bash
# Launch container and run expect script inside
docker exec -it test-container expect /test/init-wizard.exp
```

#### 3. Add Script for Simple Container Commands
For non-interactive command output verification.

**When to use:**
- `bitbot --version`
- `bitbot status`
- Simple command tests

**Example test:**
```bash
# Run in container and capture output
docker exec test-container script -qc "bitbot --version" /tmp/output.txt
docker exec test-container cat /tmp/output.txt | grep "BitBot version"
```

#### 4. Hybrid Approach for Complex Flows
Use tmux to manage container lifecycle, expect for interactions inside.

**Example:**
```bash
# Start container in tmux session
tmux new-session -d -s test "docker run -it test-container"

# Run expect script that attaches to container
docker exec test-container /test/workflow.exp

# Capture results
docker exec test-container cat /test/results.log
```

## Implementation Plan

### Phase 1: Research & Document (Current)
- ✓ Research options
- ✓ Document pros/cons
- ✓ Create recommendations

### Phase 2: Add Script-based Tests
- Add simple command tests using `script`
- Test in-container without nesting issues
- Verify output capture works

### Phase 3: Add Expect-based Tests
- Create expect scripts for wizard flows
- Test interactive prompts in containers
- Handle timing with pattern matching

### Phase 4: Refactor Existing Tests
- Keep tmux tests for host-level
- Migrate container tests to script/expect
- Document patterns for future tests

## Test Scenarios to Add

### Global Init Tests (Existing - Improve)
- ✓ First run wizard (tmux)
- ✓ Moved installation (tmux)
- → Add: Config migration from old location
- → Add: Multiple shell types (bash, zsh, fish)
- → Add: Platform-specific tests (WSL, Linux, macOS)

### Workspace Init Tests (New)
- `bitbot init` in empty directory
- `bitbot init` in existing git repo
- `bitbot init` with custom template
- `bitbot init --template bitbot-dev`
- Template selection wizard
- DevContainer generation
- Mount verification

### Container Launch Tests (New)
- `bitbot work` from workspace
- `bitbot config` from workspace
- Container start/stop/restart
- Volume mounts verification
- Wrapper script activation
- Claude Code startup

### Cross-Context Tests (New)
- Global context → Workspace context transition
- Workspace detection when cd'ing
- Multiple workspaces from same global install
- Workspace in nested directories

### Error Handling Tests (New)
- Missing prerequisites
- Docker not running
- Invalid template selection
- Corrupted config recovery
- Permission errors

### Integration Tests (New - In Container)
- Run `bitbot` commands inside container
- Verify wrapper infrastructure available
- Test skill execution
- Test hook execution
- Verify mounted paths

## References

- BATS (Bash Automated Testing System): https://github.com/sstephenson/bats
- Expect documentation: https://wiki.tcl-lang.org/page/Expect
- Script command: `man script`
- Tmux scripting: `man tmux`
- Testing CLI tools: https://spin.atomicobject.com/2016/01/11/command-line-interface-testing-tools/
