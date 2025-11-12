#!/usr/bin/env bash
#
# Test: Helper Functions
# Tests core utility functions in helpers.sh
#
# MIGRATED TO USE: test-framework.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
export BITBOT_HOME="$BITBOT_ROOT"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# Source the helpers to test
source "${BITBOT_ROOT}/core/util/helpers.sh"

# ============================================================================
# Test Suite
# ============================================================================

test_suite_begin "BitBot Helper Function Tests"

# Create temp directory for tests
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

# ============================================================================
# Test 1: File system helpers
# ============================================================================

test_section "Test 1: File system helpers"

# Test directory_exists
mkdir -p "$TEST_DIR/testdir"
if directory_exists "$TEST_DIR/testdir"; then
    test_pass "directory_exists: correctly identifies existing directory"
else
    test_fail "directory_exists: failed to identify existing directory"
fi

if ! directory_exists "$TEST_DIR/nonexistent"; then
    test_pass "directory_exists: correctly identifies non-existent directory"
else
    test_fail "directory_exists: false positive for non-existent directory"
fi

# Test file_exists
touch "$TEST_DIR/testfile"
if file_exists "$TEST_DIR/testfile"; then
    test_pass "file_exists: correctly identifies existing file"
else
    test_fail "file_exists: failed to identify existing file"
fi

# Test create_directory
create_directory "$TEST_DIR/newdir"
if [[ -d "$TEST_DIR/newdir" ]]; then
    test_pass "create_directory: successfully created directory"
else
    test_fail "create_directory: failed to create directory"
fi

# ============================================================================
# Test 2: JSON helpers - SECURITY CRITICAL
# ============================================================================

test_section "Test 2: JSON helpers (security-critical)"

# Create test JSON file
cat > "$TEST_DIR/test.json" << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "debug": true,
  "path": "/home/user/project"
}
EOF

# Test read_json_value - basic functionality
if command_exists jq; then
    value=$(read_json_value "$TEST_DIR/test.json" "name")
    if [[ "$value" == "test-project" ]]; then
        test_pass "read_json_value: correctly reads string value with jq"
    else
        test_fail "read_json_value: failed to read string value (got: $value)"
    fi

    # Test with boolean
    value=$(read_json_value "$TEST_DIR/test.json" "debug")
    if [[ "$value" == "true" ]]; then
        test_pass "read_json_value: correctly reads boolean value"
    else
        test_fail "read_json_value: failed to read boolean value (got: $value)"
    fi

    # SECURITY TEST: Injection attempt in key name
    # This should safely fail/return empty, not execute code
    value=$(read_json_value "$TEST_DIR/test.json" "name\"; touch /tmp/hacked; echo \"" 2>/dev/null || echo "")
    if [[ ! -f /tmp/hacked ]]; then
        test_pass "read_json_value: SECURITY - prevented command injection in key"
    else
        test_fail "read_json_value: SECURITY - VULNERABLE to command injection!"
        rm -f /tmp/hacked
    fi
fi

# Test without jq (fallback mode)
if ! command_exists jq; then
    test_info "jq not available, testing fallback JSON parsing"
    value=$(read_json_value "$TEST_DIR/test.json" "name")
    if [[ "$value" == "test-project" ]]; then
        test_pass "read_json_value (fallback): correctly reads value"
    else
        test_fail "read_json_value (fallback): failed (got: $value)"
    fi
fi

# Test update_json_value
if command_exists jq; then
    cp "$TEST_DIR/test.json" "$TEST_DIR/test2.json"
    update_json_value "$TEST_DIR/test2.json" "version" "2.0.0"

    new_value=$(read_json_value "$TEST_DIR/test2.json" "version")
    if [[ "$new_value" == "2.0.0" ]]; then
        test_pass "update_json_value: successfully updated value"
    else
        test_fail "update_json_value: failed to update (got: $new_value)"
    fi

    # SECURITY TEST: Injection in value
    cp "$TEST_DIR/test.json" "$TEST_DIR/test3.json"
    # Try to inject code in the value - should be safely stored as string
    update_json_value "$TEST_DIR/test3.json" "path" "\$(touch /tmp/hacked2)" 2>/dev/null || true

    if [[ ! -f /tmp/hacked2 ]]; then
        test_pass "update_json_value: SECURITY - prevented code injection in value"
    else
        test_fail "update_json_value: SECURITY - VULNERABLE to code execution!"
        rm -f /tmp/hacked2
    fi
fi

# ============================================================================
# Test 3: Path helpers
# ============================================================================

test_section "Test 3: Path helpers"

# Test get_absolute_path
abs_path=$(get_absolute_path "$TEST_DIR")
if [[ "$abs_path" == "$TEST_DIR" ]]; then
    test_pass "get_absolute_path: correctly resolves path"
else
    test_fail "get_absolute_path: failed (got: $abs_path)"
fi

# Test get_basename
basename_result=$(get_basename "/path/to/file.txt")
if [[ "$basename_result" == "file.txt" ]]; then
    test_pass "get_basename: correctly extracts basename"
else
    test_fail "get_basename: failed (got: $basename_result)"
fi

# Test get_dirname
dirname_result=$(get_dirname "/path/to/file.txt")
if [[ "$dirname_result" == "/path/to" ]]; then
    test_pass "get_dirname: correctly extracts dirname"
else
    test_fail "get_dirname: failed (got: $dirname_result)"
fi

# ============================================================================
# Test 4: Command helpers
# ============================================================================

test_section "Test 4: Command helpers"

if command_exists bash; then
    test_pass "command_exists: correctly identifies existing command"
else
    test_fail "command_exists: failed to identify bash"
fi

if ! command_exists nonexistentcommand123456; then
    test_pass "command_exists: correctly identifies non-existent command"
else
    test_fail "command_exists: false positive"
fi

# ============================================================================
# Test 5: Config merging
# ============================================================================

test_section "Test 5: Config merging"

if command_exists jq; then
    # Create global and workspace configs
    cat > "$TEST_DIR/global.json" << 'EOF'
{
  "default_mode": "terminal",
  "debug": false,
  "color": "blue"
}
EOF

    cat > "$TEST_DIR/workspace.json" << 'EOF'
{
  "debug": true,
  "project": "my-project"
}
EOF

    merged=$(merge_configs "$TEST_DIR/global.json" "$TEST_DIR/workspace.json")

    # Check that workspace overrides global
    debug_value=$(echo "$merged" | jq -r '.debug')
    if [[ "$debug_value" == "true" ]]; then
        test_pass "merge_configs: workspace value overrides global"
    else
        test_fail "merge_configs: merge failed (debug=$debug_value)"
    fi

    # Check that global values are preserved
    mode_value=$(echo "$merged" | jq -r '.default_mode')
    if [[ "$mode_value" == "terminal" ]]; then
        test_pass "merge_configs: preserves global values"
    else
        test_fail "merge_configs: lost global values"
    fi

    # Check that workspace-only values are included
    project_value=$(echo "$merged" | jq -r '.project')
    if [[ "$project_value" == "my-project" ]]; then
        test_pass "merge_configs: includes workspace-only values"
    else
        test_fail "merge_configs: lost workspace values"
    fi
fi

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
