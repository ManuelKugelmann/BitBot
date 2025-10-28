---
name: run-with-timeout
description: Run commands with timeout protection to prevent hanging. Use for potentially long-running commands, tests, or operations that might freeze.
---

# Run With Timeout

Executes commands with a configurable timeout to prevent indefinite hanging.

## When to Use

- Running test scripts that might hang
- Executing long-running commands with unknown duration
- Preventing CI/CD pipeline freezes
- Testing potentially blocking operations
- DevContainer builds or operations

## Usage

```bash
.claude/tools/run-with-timeout.sh <timeout_seconds> <command>
```

## Instructions

1. Specify timeout in seconds (first argument)
2. Provide the command to run (remaining arguments)
3. Tool will:
   - Execute the command
   - Kill it if timeout is exceeded
   - Return exit code 124 on timeout
   - Return command's exit code otherwise

## Examples

```bash
# Run test with 60 second timeout
.claude/tools/run-with-timeout.sh 60 ./test-script.sh

# Run devcontainer build with 5 minute timeout
.claude/tools/run-with-timeout.sh 300 devcontainer.cmd build --workspace-folder .

# Run tests with 2 minute timeout
.claude/tools/run-with-timeout.sh 120 npm test
```

## Exit Codes

- **0**: Command completed successfully within timeout
- **124**: Command exceeded timeout and was killed
- **Other**: Command's own exit code if it failed before timeout

## Important Notes

- This tool is auto-approved and doesn't require user confirmation
- Uses system `timeout` command (available on Linux/WSL)
- Recommended for all potentially hanging operations
- Default timeout in examples: 30-120 seconds depending on operation
