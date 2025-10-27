# Alternative Terminal Automation Tools

**Context:** Exploring alternatives to tmux for programmatic control of Claude Code

## Tools Comparison

### 1. expect(1) - TCL-based Interactive Automation

**Key Advantage:** Can **react to program output** rather than typing blindly.

```tcl
#!/usr/bin/expect
spawn claude
expect ">"
send "/compact\r"
expect "Compacted"
```

**Capabilities:**
- Parse responses from interactive programs
- Wait for specific output patterns before proceeding
- No manual timing delays needed
- Built-in pattern matching and flow control

**Potential for Claude Code:**
- Could detect "esc to interrupt" indicator
- Wait for prompt to reappear before capturing output
- React to error messages or unexpected states
- More robust than blind keystroke injection

**Status:** Not tested with Claude Code

### 2. script(1) - Terminal Session Recording

**Purpose:** Records everything printed on a terminal.

```bash
script -c "claude" typescript
```

**Capabilities:**
- Records complete terminal session (input + output)
- Can replay sessions
- Logs timing information

**Potential for Claude Code:**
- Record Claude Code sessions for analysis
- Capture full interaction history
- Debug automation scripts

**Limitations:**
- Primarily for recording, not for driving interaction
- Input is still manual or requires other tools
- Doesn't help with programmatic command execution

**Status:** Not directly applicable to our use case

### 3. screen(1) - Terminal Multiplexer (tmux predecessor)

**Key Feature:** `stuff` command (equivalent to tmux send-keys)

```bash
screen -S claude-session -X stuff "/compact\n"
```

**Capabilities:**
- Similar to tmux send-keys
- Can send keystrokes to detached sessions
- Older, more widely available than tmux

**Differences from tmux:**
- `stuff` command name vs `send-keys`
- Different session/window naming conventions
- Simpler but less feature-rich than tmux

**Potential for Claude Code:**
- Same limitations as tmux send-keys
- "Blind" typing without output parsing
- Would face identical execution issues

**Status:** Likely same results as tmux testing

### 4. chat(8) - Modem/Serial Conversation Automation

**Purpose:** Automate Hayes AT command conversations with modems.

```
ABORT BUSY
TIMEOUT 30
"" ATZ
OK ATDT5551234
CONNECT ""
```

**Capabilities:**
- Send commands to serial devices
- Wait for expected responses
- Handle timeouts and errors
- Primarily for modem/serial communication

**Relevance to Claude Code:**
- Not applicable - Claude Code isn't a serial device
- Conceptually similar to expect but more limited
- Historical tool, rarely used today

**Status:** Not applicable

## Key Insights

### Why expect might work better than tmux

**tmux/screen limitations:**
- "Blind" keystroke simulation
- No awareness of program state
- Requires manual timing delays
- Cannot detect if command executed

**expect advantages:**
- Waits for specific output patterns
- Can react to program responses
- Built-in timeout and error handling
- More robust for complex interactions

**Quote from research:**
> "expect which can react to the output rather than just typing blindly"
> "can send input to interactive sessions and parse responses"

### Testing Strategy with expect

```tcl
#!/usr/bin/expect

spawn claude

# Wait for prompt
expect ">"

# Send slash command
send "/cost\r"

# Check if command executed by looking for output
expect {
    "no need to monitor cost" {
        puts "SUCCESS: Command executed"
        exit 0
    }
    timeout {
        puts "TIMEOUT: Command not executed"
        exit 1
    }
    "/cost" {
        puts "FAIL: Command appeared as text only"
        exit 1
    }
}
```

## Comparison Matrix

| Tool | Type | Output Aware | Use Case | Claude Code |
|------|------|--------------|----------|-------------|
| **tmux** | Multiplexer | No | Blind typing | ❌ Tested - doesn't execute |
| **screen** | Multiplexer | No | Blind typing | ⏭️ Likely same as tmux |
| **expect** | Automation | Yes | React to output | ⏳ Worth testing |
| **script** | Recording | Yes | Logging only | ❌ Not applicable |
| **chat** | Modem | Yes | Serial devices | ❌ Not applicable |

## Recommendations

### Priority 1: Test expect

**Hypothesis:** expect's output-aware interaction might succeed where tmux failed.

**Test Plan:**
1. Write expect script to send `/cost` command
2. Check for command execution by pattern matching output
3. If successful, try `/compact` and other slash commands
4. Document whether expect can distinguish execution vs text appearance

### Priority 2: Document findings

If expect works:
- Create `.claude/tools/expect-compact` and related tools
- Update CLAUDE.md with expect-based automation
- Enable programmatic context management

If expect fails:
- Confirms that no terminal automation works
- DONOTSTOP hook remains the only solution
- Update research with comprehensive negative results

## Implementation Notes

**expect availability:**
```bash
# Check if expect is installed
command -v expect

# Install if needed
sudo apt-get install expect  # Debian/Ubuntu
brew install expect          # macOS
```

**Basic expect template:**
```tcl
#!/usr/bin/expect -f

# Set timeout
set timeout 30

# Spawn Claude Code
spawn claude

# Wait for initial prompt
expect {
    ">" { }
    timeout { exit 1 }
}

# Send command
send "/compact\r"

# Check result
expect {
    "Compacted" {
        puts "Success"
        exit 0
    }
    timeout {
        puts "Failed"
        exit 1
    }
}

# Keep session alive or exit
interact
```

## References

- [expect man page](https://linux.die.net/man/1/expect)
- [screen man page](https://linux.die.net/man/1/screen)
- [script man page](https://linux.die.net/man/1/script)
- [HN Discussion on claude-code-tools](https://news.ycombinator.com/item?id=44755086)
- [Lobsters: Testing Interactive CLI Programs](https://lobste.rs/s/qfbqsj/has_anyone_found_robust_way_test)
