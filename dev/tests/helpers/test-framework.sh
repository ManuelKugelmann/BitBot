#!/usr/bin/env bash
#
# Test Framework Helper
# Provides standardized test infrastructure for BitBot tests
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/helpers/test-framework.sh"
#   test_suite_begin "My Test Suite"
#   test_pass "Feature works correctly"
#   test_fail "Feature failed" "Expected X, got Y"
#   test_skip "Feature test" "Not applicable on this platform"
#   test_suite_end
#

# ============================================================================
# Color Definitions
# ============================================================================

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m'  # No Color

# ============================================================================
# Test Counters
# ============================================================================

TEST_TOTAL=0
TEST_PASSED=0
TEST_FAILED=0
TEST_SKIPPED=0

# Suite name (set by test_suite_begin)
TEST_SUITE_NAME=""

# ============================================================================
# Test Result Functions
# ============================================================================

# Pass a test
# Usage: test_pass "test description"
test_pass() {
    local test_name="$1"
    echo -e "${GREEN}✓${NC} ${test_name}"
    TEST_PASSED=$((TEST_PASSED + 1))
    TEST_TOTAL=$((TEST_TOTAL + 1))
}

# Fail a test
# Usage: test_fail "test description" ["optional reason"]
test_fail() {
    local test_name="$1"
    local reason="${2:-}"
    echo -e "${RED}✗${NC} ${test_name}"
    if [[ -n "$reason" ]]; then
        echo -e "  ${RED}Reason: ${reason}${NC}"
    fi
    TEST_FAILED=$((TEST_FAILED + 1))
    TEST_TOTAL=$((TEST_TOTAL + 1))
}

# Skip a test
# Usage: test_skip "test description" ["optional reason"]
test_skip() {
    local test_name="$1"
    local reason="${2:-}"
    echo -e "${YELLOW}⊘${NC} ${test_name} ${YELLOW}(skipped)${NC}"
    if [[ -n "$reason" ]]; then
        echo -e "  ${YELLOW}Reason: ${reason}${NC}"
    fi
    TEST_SKIPPED=$((TEST_SKIPPED + 1))
    TEST_TOTAL=$((TEST_TOTAL + 1))
}

# ============================================================================
# Backward Compatibility Aliases
# ============================================================================

# Alias for test_pass (used in some tests as test_passed)
test_passed() {
    test_pass "$@"
}

# Alias for test_fail (used in some tests as test_failed)
test_failed() {
    test_fail "$@"
}

# ============================================================================
# Test Suite Functions
# ============================================================================

# Begin a test suite
# Usage: test_suite_begin "Suite Name"
test_suite_begin() {
    TEST_SUITE_NAME="${1:-Test Suite}"

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    printf "${CYAN}║%-40s║${NC}\n" "   ${TEST_SUITE_NAME}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

# End a test suite and print summary
# Usage: test_suite_end
test_suite_end() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Test Suite Summary            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Total:   ${BLUE}${TEST_TOTAL}${NC}"
    echo -e "  Passed:  ${GREEN}${TEST_PASSED}${NC}"
    echo -e "  Failed:  ${RED}${TEST_FAILED}${NC}"

    if [[ $TEST_SKIPPED -gt 0 ]]; then
        echo -e "  Skipped: ${YELLOW}${TEST_SKIPPED}${NC}"
    fi

    echo ""

    # Calculate success rate (excluding skipped tests)
    local tested=$((TEST_TOTAL - TEST_SKIPPED))
    if [[ $tested -gt 0 ]]; then
        local success_rate=$((TEST_PASSED * 100 / tested))
        echo -e "  Success Rate: ${success_rate}%"
        echo ""
    fi

    # Final result
    if [[ $TEST_FAILED -eq 0 ]]; then
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║     ALL TESTS PASSED! ✓                ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo ""
        exit 0
    else
        echo -e "${RED}╔════════════════════════════════════════╗${NC}"
        echo -e "${RED}║     SOME TESTS FAILED ✗                ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════╝${NC}"
        echo ""
        exit 1
    fi
}

# ============================================================================
# Test Group Functions
# ============================================================================

# Begin a test group (visual separator)
# Usage: test_group_begin "Group Name"
test_group_begin() {
    local group_name="$1"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}[Test Group]${NC} ${group_name}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Simple test section header
# Usage: test_section "Section Name"
test_section() {
    local section_name="$1"
    echo ""
    echo -e "${BLUE}[Test]${NC} ${section_name}"
}

# ============================================================================
# Utility Functions
# ============================================================================

# Check if command exists
# Usage: if test_command_exists "tmux"; then ... fi
test_command_exists() {
    command -v "$1" &>/dev/null
}

# Run a test and capture result automatically
# Usage: test_run "test name" command arg1 arg2
test_run() {
    local test_name="$1"
    shift

    if "$@" &>/dev/null; then
        test_pass "$test_name"
        return 0
    else
        test_fail "$test_name" "Command failed: $*"
        return 1
    fi
}

# Check if file exists
# Usage: test_file_exists "description" "/path/to/file"
test_file_exists() {
    local description="$1"
    local file_path="$2"

    if [[ -f "$file_path" ]]; then
        test_pass "$description"
        return 0
    else
        test_fail "$description" "File not found: $file_path"
        return 1
    fi
}

# Check if directory exists
# Usage: test_dir_exists "description" "/path/to/dir"
test_dir_exists() {
    local description="$1"
    local dir_path="$2"

    if [[ -d "$dir_path" ]]; then
        test_pass "$description"
        return 0
    else
        test_fail "$description" "Directory not found: $dir_path"
        return 1
    fi
}

# Export functions for use in subshells
export -f test_pass
export -f test_fail
export -f test_skip
export -f test_passed
export -f test_failed
export -f test_suite_begin
export -f test_suite_end
export -f test_group_begin
export -f test_section
export -f test_command_exists
export -f test_run
export -f test_file_exists
export -f test_dir_exists
