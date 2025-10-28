# Type C I/O Deadlock Detection

## Overview

Type C stalls occur when Claude Code becomes stuck in **uninterruptible sleep (D state)** waiting for an I/O operation that never completes. These are the most severe type of stall because the process cannot be killed with signals (even SIGKILL).

## Symptoms

- **CPU Usage:** 0% (process is idle, waiting)
- **Process State:** D (uninterruptible sleep)
- **Responsiveness:** Completely unresponsive to all signals
- **Recovery:** Only restart or waiting for I/O completion
- **Duration:** Can last indefinitely

## Root Causes

Based on research from GitHub issues:

1. **Failed Disk I/O**
   - Disk failure or timeout
   - RAID degradation
   - USB drive disconnect

2. **Network Filesystem Stalls**
   - NFS mount timeout
   - SMB/CIFS share disconnect
   - Network interruption during file operation

3. **File Descriptor Issues**
   - FD exhaustion
   - Deadlock on file locks
   - Page writeback blocked

## Detection Strategy

The watchdog monitors **3 indicators** from `/proc/$PID/`:

### 1. Process State (Field 3 of `/proc/$PID/stat`)

```bash
state=$(cat /proc/$CLAUDE_PID/stat | awk '{print $3}')

# States:
# R = Running (normal)
# S = Sleeping (normal, interruptible)
# D = Disk sleep (I/O wait - BAD if sustained)
# Z = Zombie
# T = Stopped
```

**Threshold:** D state for >60 seconds = I/O deadlock

### 2. Wait Channel (`/proc/$PID/wchan`)

Shows which kernel function is causing the wait:

```bash
wchan=$(cat /proc/$CLAUDE_PID/wchan)

# Problematic patterns:
# - rpc_wait_bit_killable  = NFS/RPC timeout
# - io_schedule            = Disk I/O wait
# - wait_on_page_writeback = Disk write blocked
# - sync_buffer            = Disk sync blocked
```

### 3. Block I/O Delay Counter (Field 42 of `/proc/$PID/stat`)

Cumulative I/O wait time in clock ticks (10ms each):

```bash
blkio_ticks=$(cat /proc/$CLAUDE_PID/stat | awk '{print $42}')

# Rapid increase = significant I/O wait
# Delta > 100 ticks per check = warning
```

## Implementation

See `watchdog.sh` function `check_io_deadlock()` (lines 129-171):

**Logic:**
1. Read `/proc/$PID/stat` to get process state
2. If state = 'D':
   - Read wchan to identify blocking kernel function
   - Read blkio_ticks to track I/O delay accumulation
   - Start timer if first detection
   - Trigger restart if D state sustained for >60 seconds
3. If state != 'D':
   - Clear timer
   - Log if D state was previously active

## Configuration

```bash
# watchdog.sh line 20
IO_BLOCK_DURATION=60  # 60 seconds in D state = I/O deadlock (Type C)
```

**Tuning Guidance:**
- **Conservative:** 120 seconds (2 minutes) - Fewer false positives
- **Default:** 60 seconds (1 minute) - Balanced
- **Aggressive:** 30 seconds - Faster recovery, more false positives

**Note:** D state is usually transient (<1 second). Sustained D state is almost always a real problem.

## Why 60 Seconds?

From research:

1. **Normal I/O:** Disk operations complete in milliseconds
2. **Slow I/O:** Even slow HDDs complete in <5 seconds
3. **Network FS:** NFS default timeout is 60 seconds
4. **Kernel Behavior:** D state lasting >30 seconds is abnormal

**60 seconds balances:**
- Long enough to avoid false positives from slow operations
- Short enough to detect real deadlocks before user frustration

## Monitoring Output

When I/O deadlock detected, watchdog logs:

```
[2025-10-28 17:30:45] WATCHDOG[12345]: Process in D state (I/O wait), wchan: io_schedule, blkio_ticks: 1542
[2025-10-28 17:30:45] WATCHDOG[12345]: I/O block detected: D:io_schedule
[2025-10-28 17:31:15] WATCHDOG[12345]: Significant I/O delay: +230 ticks
[2025-10-28 17:31:45] WATCHDOG[12345]: STALL DETECTED: I/O deadlock detected (D state for 60s): D:io_schedule
[2025-10-28 17:31:45] WATCHDOG[12345]: Triggering restart via pipe...
```

## Limitations

### Cannot Kill D State Processes

D state processes are **uninterruptible** - they ignore ALL signals:
- `kill -TERM $PID` - Ignored
- `kill -KILL $PID` - Ignored
- `kill -9 $PID` - Ignored

**Workaround:** The watchdog triggers a wrapper restart, which:
1. Attempts SIGTERM (will be ignored if in D state)
2. Waits 5 seconds
3. Attempts SIGKILL (will be ignored if in D state)
4. Times out and force-kills wrapper
5. Wrapper restart launches new Claude instance

### False Positives

Rare but possible:
- Very slow network filesystem (>60s read)
- Disk with extreme latency (failing but not failed)
- Large file sync operations

**Mitigation:** Increase `IO_BLOCK_DURATION` if false positives occur

### Detection Gaps

Cannot detect:
- Stuck I/O that completes just before 60s threshold
- Intermittent D state (enters/exits D state rapidly)
- D state caused by suspend/resume

## Testing

### Simulate Type C Stall

**Test 1: Block on NFS timeout**
```bash
# Mount NFS share
sudo mount -t nfs server:/share /mnt/test

# Start Claude with operations on NFS
cd /mnt/test

# Disconnect network
sudo ip link set eth0 down

# Wait for operations to stall
# Watchdog should detect D state and restart
```

**Test 2: Fill disk during write**
```bash
# Create file that fills disk
dd if=/dev/zero of=bigfile bs=1M

# Claude operations on full disk will stall
# Watchdog should detect D state
```

**Test 3: USB drive disconnect**
```bash
# Start Claude with CWD on USB drive
cd /media/usb

# Physically disconnect USB drive
# Any file operations enter D state
# Watchdog should detect and restart
```

## Comparison with Type A/B

| Type | Symptom | CPU | State | Detection | Threshold |
|------|---------|-----|-------|-----------|-----------|
| **A** | Infinite loop | 100% | R | CPU usage | 300s |
| **B** | API timeout | 0-5% | S | Session staleness | 120s (warning) |
| **C** | I/O deadlock | 0% | D | Process state | 60s |

## Related Files

- `watchdog.sh:129-171` - I/O deadlock detection function
- `watchdog.sh:251-273` - Integration into monitoring loop
- `README.md` - Watchdog documentation
- `claude-wrapper.sh:356-364` - Watchdog auto-launch

## References

- [Baeldung: Uninterruptible Process in Linux](https://www.baeldung.com/linux/uninterruptible-process)
- [GitHub Issue #10481: ReadFileUtf8 I/O Block](https://github.com/anthropics/claude-code/issues/10481)
- [proc(5) man page](https://man7.org/linux/man-pages/man5/proc.5.html)
- [Stack Overflow: Determining cause of stuck D state](https://serverfault.com/questions/940805/)

## Status

- ✅ Detection logic implemented
- ✅ Syntax validated
- ✅ Documentation complete
- ⏳ Real-world testing needed
- ⏳ False positive tuning needed

---

**Last Updated:** 2025-10-28
