# BitBot Test Suite

Automated and manual tests for BitBot MVP.

## Quick Start

### Run All Tests

```bash
cd tests
./run-tests.sh
```

### Run Tests with Clean Slate

```bash
./run-tests.sh --clean
```

### Run Quick Tests (Skip Integration)

```bash
./run-tests.sh --quick
```

## Test Structure

```
tests/
├── run-tests.sh              # Main test runner (orchestrates all tests)
├── clean-slate.sh            # Environment reset script
├── test-prerequisites.sh     # Check required tools (Docker, git, etc.)
├── test-workspace-init.sh    # Test workspace initialization
├── test-workspace/           # Sample workspace for testing
│   ├── README.md
│   ├── .gitignore
│   └── sample-code/
└── README.md                 # This file
```

## Individual Test Scripts

### Prerequisites Test (`test-prerequisites.sh`)

**Purpose**: Verify all required tools are installed and available

**Checks**:
- ✓ bash availability
- ✓ Docker installation and daemon status
- ✓ DevContainer CLI (devcontainer.cmd on WSL)
- ✓ git availability
- ℹ VS Code (optional)
- ℹ Node.js and npm (optional, for standalone CLI)

**Run**:
```bash
./test-prerequisites.sh
```

### Workspace Init Test (`test-workspace-init.sh`)

**Purpose**: Test workspace initialization logic

**Tests**:
1. Detect uninitialized workspace
2. Create workspace structure (.bitbot/internal, .bitbot/cache)
3. Detect initialized workspace
4. Verify gitignore patterns
5. Create and validate config.json
6. Test subdirectory detection (MVP: should fail)

**Run**:
```bash
./test-workspace-init.sh
```

## Clean Slate Script

Resets the testing environment to a fresh state.

### Basic Usage

```bash
./clean-slate.sh              # Interactive prompts
./clean-slate.sh --full       # Clean everything without prompts
```

### Options

- `--full` - Clean everything without prompts
- `--keep-containers` - Keep Docker containers
- `--stop-docker-only` - Only stop Docker

### What It Cleans

1. **Docker Desktop** - Stops the daemon
2. **DevContainers** - Removes all BitBot containers
3. **Test Workspace** - Removes `.bitbot` folder from test workspace
4. **Global Config** - Optionally removes `config.json`
5. **DevContainer CLI** - Optionally removes standalone CLI

## Manual Testing

For tests that cannot be easily automated, refer to the manual test scenarios below.

### Test Scenario 1: Global Init (First Run)

**Setup**: Clean environment, no `config.json` exists

**Steps**:
```bash
cd /path/to/bitbot/install
./bitbot
```

**Expected**:
- Welcome banner
- Prerequisites check
- Prompt for default launch mode (terminal/vscode)
- Prompt to add to PATH
- Creates `config.json`

### Test Scenario 2: Workspace Init

**Setup**: Fresh workspace (no `.bitbot` folder)

**Steps**:
```bash
cd tests/test-workspace
../../bitbot init
```

**Expected**:
- Git safety recommendations (if git repo)
- Creates `.bitbot/` structure
- Launches config mode devcontainer
- Enters container for `.devcontainer` setup

### Test Scenario 3: Work Mode (Terminal)

**Prerequisites**: Workspace initialized, `.devcontainer/` exists

**Steps**:
```bash
cd tests/test-workspace
../../bitbot work
# or just:
../../bitbot
```

**Expected**:
- Prerequisites validated
- Devcontainer built (first time)
- Enters container at `/workspace`

### Test Scenario 4: Work Mode (VS Code)

**Prerequisites**: VS Code installed, workspace initialized

**Steps**:
```bash
cd tests/test-workspace
../../bitbot vscode
```

**Expected**:
- VS Code launches
- Opens directly in devcontainer (no "Reopen in Container" popup)
- Bottom-left shows "Dev Container: [name]"

### Test Scenario 5: Config Mode

**Prerequisites**: Workspace initialized

**Steps**:
```bash
cd tests/test-workspace
../../bitbot config
```

**Expected**:
- Launches config mode devcontainer
- Read-write access to `.devcontainer/`
- Can edit devcontainer.json

## Test Workspace

The `test-workspace/` directory is a minimal project for testing BitBot functionality.

### Features

- Sample code files
- Pre-configured .gitignore
- Can be initialized with `bitbot init`
- Safe to delete and recreate

### Usage

```bash
cd test-workspace

# Initialize
../../bitbot init

# Enter work mode
../../bitbot work

# Enter config mode
../../bitbot config

# Clean up
rm -rf .bitbot
```

## CI/CD Integration

To integrate with CI/CD:

```bash
# Example GitHub Actions
- name: Run BitBot Tests
  run: |
    cd tests
    ./run-tests.sh --quick
```

## Troubleshooting

### Docker Not Starting

**Symptom**: Tests fail with "Docker daemon not running"

**Solution**:
```bash
# Start Docker manually first
# WSL:
powershell.exe -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'"

# macOS:
open -a Docker

# Wait for Docker to start, then run tests
```

### Clean Slate Issues

**Symptom**: Clean slate script cannot remove containers

**Solution**:
```bash
# Stop Docker completely first
./clean-slate.sh --stop-docker-only

# Wait 10 seconds
sleep 10

# Then run full clean
./clean-slate.sh --full
```

### Permission Errors

**Symptom**: Cannot remove test workspace `.bitbot` folder

**Solution**:
```bash
# Fix permissions
chmod -R u+w test-workspace/.bitbot
rm -rf test-workspace/.bitbot
```

## Adding New Tests

To add a new test script:

1. Create test script: `test-<name>.sh`
2. Follow the template pattern (see existing tests)
3. Add to `run-tests.sh` test suite
4. Update this README

### Test Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass_count=0
fail_count=0

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((pass_count++))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((fail_count++))
}

echo "=== Your Test Name ==="

# Your tests here

echo "=== Test Summary ==="
echo "  Passed: ${pass_count}"
echo "  Failed: ${fail_count}"

[[ $fail_count -eq 0 ]] && exit 0 || exit 1
```

## Test Coverage

| Component              | Automated | Manual | Status |
|------------------------|-----------|--------|--------|
| Prerequisites          | ✓         | -      | ✓      |
| Workspace Init         | ✓         | -      | ✓      |
| Global Init            | -         | ✓      | Pending|
| Work Mode (Terminal)   | -         | ✓      | Pending|
| Work Mode (VS Code)    | -         | ✓      | Pending|
| Config Mode            | -         | ✓      | Pending|
| Git Safety             | -         | ✓      | Pending|
| Docker Auto-Start      | -         | ✓      | Pending|

## Future Test Additions

- [ ] Integration test (full workflow)
- [ ] Git safety recommendations test
- [ ] Docker auto-start test
- [ ] Config mode devcontainer test
- [ ] UID synchronization test
- [ ] Shell history persistence test
- [ ] Error handling tests
- [ ] Cross-platform tests (Linux, macOS, WSL)

## Contributing

When adding tests:
1. Use consistent formatting (see template)
2. Add colored output for readability
3. Test on all supported platforms when possible
4. Document manual test procedures
5. Update test coverage table

---

**Last Updated**: 2025-10-21
**BitBot Version**: MVP (0.1.0)
