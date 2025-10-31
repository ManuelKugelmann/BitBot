# BitBot User Flow Tests

Comprehensive user flow tests that simulate real user interactions with BitBot across different contexts and environments.

## Overview

These tests verify end-to-end user flows from initial setup through container usage, testing the complete BitBot experience.

## Test Architecture

### Testing Approaches

We use different tools for different types of tests:

| Tool | Use Case | Best For | Limitations |
|------|----------|----------|-------------|
| **tmux** | Host-level interactive tests | Global setup, PATH configuration | Can't nest easily in containers |
| **script** | Simple command output capture | Non-interactive container commands | No interactive input |
| **expect** | Complex interactive flows | Wizards, multi-step prompts | Requires TCL knowledge |

See `sparc/0-research/TERMINAL_AUTOMATION_TESTING.md` for detailed analysis.

## Test Suites

### 1. Global Initialization Flow
**File:** `test-user-flow-init.sh`
**Tool:** tmux
**Tests:**
- First-run detection
- Prerequisites check
- Launch mode selection wizard
- PATH configuration
- Shell config modification
- Duplicate prevention

**Usage:**
```bash
# Test mode (isolated environment)
./test-user-flow-init.sh

# Dev mode (tests against current BitBot)
./test-user-flow-init.sh --dev

# Keep artifacts for inspection
./test-user-flow-init.sh --no-cleanup
```

### 2. Moved Installation
**File:** `test-user-flow-moved.sh`
**Tool:** tmux
**Tests:**
- Initial setup at location A
- Move BitBot to location B
- Config migration verification
- PATH update detection
- Config validity after move

**Usage:**
```bash
# Always runs in test mode (isolated)
./test-user-flow-moved.sh

# Keep artifacts
./test-user-flow-moved.sh --no-cleanup
```

### 3. Workspace Initialization
**File:** `test-user-flow-workspace-init.sh`
**Tool:** tmux
**Tests:**
- `bitbot init` wizard
- Template selection (base, config, work)
- Workspace structure creation
- devcontainer.json generation
- BitBot infrastructure copying
- .claude configuration
- Re-initialization detection

**Usage:**
```bash
# Test mode (isolated workspace)
./test-user-flow-workspace-init.sh

# Dev mode
./test-user-flow-workspace-init.sh --dev

# Keep artifacts
./test-user-flow-workspace-init.sh --no-cleanup
```

### 4. Context Switching
**File:** `test-user-flow-context-switch.sh`
**Tool:** tmux
**Tests:**
- Global context (from BitBot install dir)
- Workspace context (from workspace dir)
- Context switching when changing directories
- Multiple workspace isolation
- Nested directory context detection
- No cross-contamination

**Usage:**
```bash
# Test mode (creates 2 isolated workspaces)
./test-user-flow-context-switch.sh

# Dev mode
./test-user-flow-context-switch.sh --dev

# Keep artifacts
./test-user-flow-context-switch.sh --no-cleanup
```

### 5. In-Container Commands
**File:** `test-user-flow-container-commands.sh`
**Tool:** script command (no nested tmux!)
**Tests:**
- Container build and start
- BitBot availability in PATH
- `bitbot --version`
- `bitbot --help`
- Directory structure verification
- Environment variables
- Exit code handling
- Multi-line output capture

**Usage:**
```bash
# Requires Docker running
./test-user-flow-container-commands.sh

# Keep container for inspection
./test-user-flow-container-commands.sh --no-cleanup
```

**Why script command?**
- Avoids nested tmux issues
- Clean output capture
- Works well for non-interactive commands
- Simpler than tmux for this use case

### 6. In-Container Interactive
**File:** `test-user-flow-container-interactive.sh` + `.exp`
**Tool:** expect
**Tests:**
- Yes/No prompts
- Number selection menus
- Multi-step wizard flows
- Timeout handling
- Pattern matching in output
- Interactive input processing

**Usage:**
```bash
# Requires Docker + expect
./test-user-flow-container-interactive.sh

# Keep container for inspection
./test-user-flow-container-interactive.sh --no-cleanup
```

**Why expect?**
- Better than tmux for complex interactions
- Built-in timeout handling
- Pattern matching for output validation
- Industry standard for interactive automation

## Master Test Runner

**File:** `test-user-flows.sh`

Runs all user flow tests in sequence.

**Usage:**
```bash
# Run all tests in test mode
./test-user-flows.sh

# Run all tests in dev mode
./test-user-flows.sh --dev

# Keep all artifacts
./test-user-flows.sh --no-cleanup
```

**Features:**
- Continues on failure (all tests run)
- Summary report at end
- Skips expect tests if expect not installed
- Pass/fail tracking across all suites

## Test Modes

### Test Mode (Default)
- Creates isolated temporary environment
- Copies BitBot to `/tmp/bitbot-test-*`
- Safe - no impact on dev environment
- Clean slate for each test
- Automatic cleanup

### Dev Mode (`--dev`)
- Tests against current BitBot directory
- Requires clean git state
- Shows git diffs after test
- Template sync analysis
- Manual cleanup required

### No Cleanup (`--no-cleanup`)
- Leaves all artifacts for inspection
- Useful for debugging
- Shows cleanup commands
- Works in both test and dev mode

## Prerequisites

### All Tests
- Bash 4.0+
- tmux (for host-level tests)
- Git

### Container Tests
- Docker running
- devcontainer CLI (for some tests)

### Interactive Tests
- expect (`apt-get install expect`)

### Optional
- jq (for JSON validation)
- dos2unix (for line ending checks)

## Test Structure

All test files follow consistent patterns:

### Common Functions
```bash
test_pass()    # Log passing test
test_fail()    # Log failing test
test_info()    # Log informational message
test_warning() # Log warning
log_tmux_output() # Capture tmux session output
```

### Test Phases
1. **Prerequisites Check** - Verify requirements
2. **Setup** - Create test environment
3. **Tests** - Execute test scenarios
4. **Verification** - Check results
5. **Cleanup** - Remove artifacts (unless --no-cleanup)

### Exit Codes
- `0` - All tests passed
- `1` - One or more tests failed

## Adding New Tests

### 1. Choose Testing Tool

- **Host-level interactive:** Use tmux (existing pattern)
- **Container non-interactive:** Use script command
- **Container interactive:** Use expect

### 2. Create Test File

```bash
# Follow naming convention
test-user-flow-<feature>.sh

# Use existing test as template
cp test-user-flow-context-switch.sh test-user-flow-mynewtest.sh
```

### 3. Update Master Runner

Add to `test-user-flows.sh`:

```bash
run_test_suite \
    "My New Test" \
    "$SCRIPT_DIR/test-user-flow-mynewtest.sh" \
    || true
```

### 4. Document

Add section to this README with:
- Purpose
- What it tests
- Usage examples
- Prerequisites

### 5. Fix Line Endings & Syntax

```bash
.claude/skills/fix-line-endings-check-bash/scripts/fix-line-endings-check-bash.sh \
    dev/tests/test-user-flow-mynewtest.sh
```

## Troubleshooting

### Tests timing out
- Increase `max_wait` values
- Check `sleep` durations
- Look for `log_tmux_output` in failures

### Container tests failing
- Verify Docker running: `docker info`
- Check disk space: `df -h`
- Look for port conflicts

### Expect tests failing
- Verify expect installed: `which expect`
- Check timeout values (default 30s)
- Review expect script output

### Git state errors (dev mode)
- Commit or stash changes: `git status`
- Only run dev mode on clean state
- Use test mode for experimentation

## Best Practices

### Writing Tests
1. Use descriptive test names
2. Log context with `test_info`
3. Capture output on failure with `log_tmux_output`
4. Handle both success and failure paths
5. Clean up resources in trap handler

### Running Tests
1. Start with test mode (safer)
2. Use --no-cleanup when debugging
3. Check prerequisites before full suite
4. Read output carefully - warnings matter

### Debugging Tests
1. Run individual test with --no-cleanup
2. Examine tmux output logs
3. Check created files/directories
4. Verify git diffs in dev mode
5. Use `set -x` for verbose bash output

## Future Enhancements

### Planned Tests
- [ ] Multi-user workspace sharing
- [ ] Container restart/recovery
- [ ] Network connectivity tests
- [ ] Volume persistence tests
- [ ] Custom template tests
- [ ] Error recovery flows

### Tool Improvements
- [ ] BATS integration for unit tests
- [ ] Parallel test execution
- [ ] HTML test reports
- [ ] CI/CD integration
- [ ] Performance benchmarking

## References

- **Research:** `sparc/0-research/TERMINAL_AUTOMATION_TESTING.md`
- **Testing Process:** `sparc/0-research/TESTING_PROCESS.md`
- **Directory Structure:** `sparc/3-architecture/01-directory-structure.md`
- **Expect Documentation:** https://wiki.tcl-lang.org/page/Expect
- **BATS:** https://github.com/sstephenson/bats

## Contributing

When adding or modifying user flow tests:

1. Follow existing patterns
2. Document thoroughly
3. Test in both modes
4. Update this README
5. Run full suite before committing
6. Check line endings and syntax

## Support

For issues with tests:
- Check troubleshooting section above
- Review test output logs
- Run with --no-cleanup for inspection
- Check prerequisites

For BitBot issues found by tests:
- File GitHub issue with test output
- Include test file name and line number
- Provide git diff if using dev mode
- Attach test artifacts if helpful
