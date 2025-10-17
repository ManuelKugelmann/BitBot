# BitBot Test Suite

This directory contains the test suite for BitBot, focused on validation of script syntax, Docker files, and core functionality.

## Test Files

### Main Test Suite
- **`test-bitbot.sh`** - Main test suite (bash)
  - Script syntax validation
  - Docker file validation  
  - Docker compose validation
  - DevContainer generation testing
  - MCP services validation
  - Functional workflow testing

### Platform-Specific Tests
- **`test-bitbot.bat`** - Windows-specific functionality tests
  - Polyglot script testing
  - Windows path conversion
  - Environment detection
  - Windows-specific files

### Integration Tests
- **`test-workflow.sh`** - Full workflow integration test
  - Starts real MCP services
  - Creates test workspace
  - Tests complete BitBot workflow
  - Validates service communication

### Test Runner
- **`run-tests.sh`** - Test runner script
  - Runs all test suites
  - Provides consolidated summary
  - Use `--with-workflow` for full testing

## Usage

### Quick Test (Syntax & Structure)
```bash
./tests/test-bitbot.sh
```

### Full Test Suite
```bash
./tests/run-tests.sh --with-workflow
```

### Windows-Specific Tests
```cmd
tests\test-bitbot.bat
```

### Individual Test Components
```bash
# Just syntax validation
./tests/test-bitbot.sh

# Full workflow with real services
./tests/test-workflow.sh
```

## Test Structure

### What Gets Tested
✅ **Script Syntax** - All bash scripts validated with `bash -n`  
✅ **Dockerfiles** - Structure, timezone support, and basic validation  
✅ **Docker Compose** - Syntax validation using `docker-compose config`  
✅ **DevContainer Generation** - Real generation and JSON validation  
✅ **MCP Services** - Configuration and service definitions  
✅ **Path Resolution** - Cross-platform path handling  
✅ **Service Communication** - HTTP endpoints and health checks  

### What Gets Removed
❌ Trivial directory existence checks  
❌ Redundant platform detection  
❌ Overly verbose output  
❌ Duplicate test logic  

## Test Philosophy

- **Focus on Real Functionality** - Tests validate actual script execution and Docker operations
- **Syntax First** - Catch syntax errors before runtime issues
- **Platform Separation** - Bash for main functionality, batch for Windows-specific features
- **Fast Feedback** - Quick syntax validation separate from slower integration tests
- **Real Workspaces** - Test with actual project structures, not toy examples

## Integration with CI

The test suite is designed to be CI-friendly:
- Exit codes indicate success/failure
- Docker requirement detection
- Timeout handling for network operations
- Clean test workspace management