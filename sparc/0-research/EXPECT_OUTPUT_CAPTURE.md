# Expect Output Capture and Logging

Research on capturing and displaying output from expect scripts to match tmux's `capture-pane` functionality.

## Goal

Make expect tests show output at each step like tmux tests do with `log_tmux_output()`.

## Expect Output Control

### log_user (Control Console Output)

**Default:** `log_user 1` (output shown to user)

```tcl
log_user 0    # Disable output to console (silent)
log_user 1    # Enable output to console (default)
```

**Use case:**
- Keep `log_user 1` to see output in real-time
- Use `log_user 0` when you only want to capture to variables/files

### log_file (Capture to File)

```tcl
log_file /tmp/output.log    # Start logging to file
log_file                     # Stop logging (close file)
```

**Features:**
- Can be called multiple times to switch log files
- Appends by default
- Use `-noappend` to overwrite: `log_file -noappend file.log`

### expect_out(buffer) (Capture Matched Text)

```tcl
expect {
    "pattern" {
        # Everything up to and including match
        set output $expect_out(buffer)

        # Just the matched text
        set match $expect_out(0,string)

        # Captured groups (if using regex)
        set group1 $expect_out(1,string)
    }
}
```

**Important:**
- Buffer is cleared after each match
- Use `expect_out(buffer)` to get accumulated output
- Use before buffer is cleared by next expect

### exp_internal (Debug Expect Itself)

```tcl
exp_internal 1    # Show expect's internal operations
exp_internal 0    # Disable debugging
```

**Use case:** Debugging expect scripts, not for production tests

## Patterns for Output Logging

### Pattern 1: Real-time Display + File Logging

```tcl
#!/usr/bin/expect -f

# Show output to user AND log to file
log_user 1
log_file /tmp/test-output.log

spawn docker exec -it container bash

expect "prompt" {
    send "command\r"
}

expect "result" {
    # Output already shown due to log_user 1
    # Also saved to file
}

log_file    # Close log file
```

### Pattern 2: Capture and Display at Checkpoints

```tcl
#!/usr/bin/expect -f

# Like tmux log_tmux_output - capture and display at specific points
proc log_output {context} {
    global output_buffer

    send_user "\n"
    send_user "\[Output: $context\]\n"
    send_user "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    if {[info exists output_buffer]} {
        send_user "$output_buffer\n"
    } else {
        send_user "(no output captured)\n"
    }

    send_user "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    send_user "\n"
}

# Disable console output to capture manually
log_user 0

set output_buffer ""

spawn docker exec -it container bash

expect {
    -re "(.*)\n" {
        append output_buffer $expect_out(1,string)
        append output_buffer "\n"
        exp_continue
    }
    "prompt" {
        # Checkpoint - show accumulated output
        log_output "After prompt appeared"

        send "command\r"
        set output_buffer ""  # Reset for next capture
    }
}
```

### Pattern 3: Hybrid - Live Output + Checkpoint Captures

```tcl
#!/usr/bin/expect -f

# Show live output + log to file for checkpoints
log_user 1
log_file -noappend /tmp/current-output.log

proc log_output {context} {
    global logfile_name

    send_user "\n"
    send_user "\[Output Checkpoint: $context\]\n"
    send_user "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

    # Read from log file
    if {[file exists $logfile_name]} {
        set fp [open $logfile_name r]
        set content [read $fp]
        close $fp
        send_user "$content"
    } else {
        send_user "(no output captured)\n"
    }

    send_user "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    send_user "\n"

    # Clear log for next checkpoint
    log_file
    log_file -noappend $logfile_name
}

set logfile_name "/tmp/test-checkpoint.log"
log_file -noappend $logfile_name

spawn docker exec -it container bash

expect {
    "Step 1" {
        log_output "After Step 1"
        send "next\r"
        exp_continue
    }
    "Step 2" {
        log_output "After Step 2"
        send "continue\r"
        exp_continue
    }
    "Done" {
        log_output "Final output"
    }
}

log_file
```

### Pattern 4: Simplest - Just Use log_user 1 (Recommended)

```tcl
#!/usr/bin/expect -f

# Simplest approach - let expect show everything in real-time
log_user 1

spawn docker exec -it container bash

send_user "\n[Test 1] Starting test...\n"

expect "prompt" {
    send_user "✓ PASS: Prompt appeared\n"
    send "command\r"
}

expect "result" {
    send_user "✓ PASS: Got expected result\n"
}

# Output is already shown, no need to capture
```

## Empty Tool Alternative

**GitHub:** https://github.com/ierton/empty

Empty is a shell-friendly alternative to expect:

```bash
# Start application under PTY
empty -f -i in.fifo -o out.fifo -p pid.file application

# Send input
echo "command" > in.fifo

# Read output
cat out.fifo

# Wait for pattern
empty -w -i out.fifo "expected pattern"

# Kill application
empty -k $(cat pid.file)
```

**Advantages:**
- Pure shell scripting (no TCL)
- Uses FIFOs for I/O
- Simpler for basic use cases

**Disadvantages:**
- Less mature than expect
- Fewer features
- Not as widely available

## Recommendation for BitBot Tests

### Use Pattern 4 (Simplest) with Modifications

**Best approach for BitBot:**

```tcl
#!/usr/bin/expect -f

# Enable all output
log_user 1

# Colors
set BLUE "\033\[0;34m"
set YELLOW "\033\[1;33m"
set NC "\033\[0m"

proc log_checkpoint {context} {
    global BLUE YELLOW NC

    send_user "\n"
    send_user "${BLUE}\[Checkpoint: $context\]${NC}\n"
    send_user "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    send_user "(Output shown above in real-time)\n"
    send_user "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    send_user "\n"
}

spawn docker exec -it container bash

expect {
    "Step 1 prompt" {
        log_checkpoint "After Step 1 prompt appeared"
        send "input\r"
        exp_continue
    }
    "Step 2 prompt" {
        log_checkpoint "After Step 2 prompt appeared"
        send "more input\r"
        exp_continue
    }
    "Complete" {
        log_checkpoint "Test completed"
    }
}
```

**Why this is best:**
1. ✅ Real-time output (like tmux with capture-pane)
2. ✅ Visual checkpoints for test phases
3. ✅ No complex buffer management
4. ✅ Simple to understand and maintain
5. ✅ Matches existing tmux test patterns

## Implementation Plan

1. Update `test-user-flow-container-interactive.exp`:
   - Add `log_user 1` (already default, but explicit)
   - Add `log_checkpoint` proc similar to `log_tmux_output`
   - Call at key test phases

2. Keep output visible by default (no log_user 0)

3. Use checkpoints to mark test phases (visual separation)

4. Optionally save to file with `log_file` for post-mortem analysis

## Examples

### Before (Current)
```tcl
expect "prompt" {
    test_pass "Prompt shown"
    send "y\r"
}
```

### After (With Checkpoints)
```tcl
expect "prompt" {
    log_checkpoint "Prompt appeared"
    test_pass "Prompt shown"
    send "y\r"
}
```

Output will show:
```
(actual prompt output from container)

[Checkpoint: Prompt appeared]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
(Output shown above in real-time)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ PASS: Prompt shown
```

This matches the tmux pattern where we show output at checkpoints!
