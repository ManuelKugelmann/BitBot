#!/usr/bin/env bash
#
# Filesystem Performance Test - WSL vs Windows mount
# Tests performance impact of project location on Windows/WSL
#
# Usage: ./test-filesystem-performance.sh [--quick]
#
# MIGRATED TO USE: test-framework.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# Parse arguments
QUICK=false
if [[ "${1:-}" == "--quick" ]]; then
    QUICK=true
fi

test_suite_begin "Filesystem Performance Test - WSL vs Windows Mount"

# Check if running on WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    test_skip "All tests" "Only runs on WSL - compares ext4 vs 9P filesystem performance"
    test_suite_end
fi

# Test locations
WSL_TEST_DIR="$HOME/bitbot-perf-test-wsl"
WIN_TEST_DIR="/mnt/c/bitbot-perf-test-win"

# Cleanup on exit
cleanup() {
    echo ""
    echo "Cleaning up test directories..."
    rm -rf "$WSL_TEST_DIR" 2>/dev/null || true
    rm -rf "$WIN_TEST_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Create test directories
echo "Creating test directories..."
mkdir -p "$WSL_TEST_DIR"
mkdir -p "$WIN_TEST_DIR"
echo ""

# ============================================================================
# Test 1: File Creation Speed
# ============================================================================

test_file_creation() {
    local test_dir="$1"
    local location_name="$2"
    local file_count=1000

    if [[ "$QUICK" == "true" ]]; then
        file_count=100
    fi

    echo "Test 1: File Creation Speed ($location_name)" >&2
    echo "Creating $file_count files..." >&2

    local start_time=$(date +%s.%N)

    for i in $(seq 1 $file_count); do
        touch "$test_dir/file$i.txt" 2>/dev/null
    done

    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)

    echo "Time: ${duration}s" >&2
    echo "" >&2

    # Return duration (stdout only)
    echo "$duration"
}

test_section "Test 1: File Creation Speed"

WSL_FILE_TIME=$(test_file_creation "$WSL_TEST_DIR" "WSL filesystem")
WIN_FILE_TIME=$(test_file_creation "$WIN_TEST_DIR" "Windows mount")

# Calculate ratio
FILE_RATIO=$(echo "scale=1; $WIN_FILE_TIME / $WSL_FILE_TIME" | bc)
echo "Result: Windows mount is ${FILE_RATIO}x slower for file creation"
echo ""

# ============================================================================
# Test 2: Git Operations
# ============================================================================

test_git_operations() {
    local test_dir="$1"
    local location_name="$2"

    echo "Test 2: Git Operations ($location_name)" >&2

    cd "$test_dir"

    # Initialize git repo
    git init -q
    git config user.email "test@bitbot.dev"
    git config user.name "BitBot Test"

    # Create some files
    for i in $(seq 1 50); do
        echo "test content $i" > "file$i.txt"
    done

    # Test git add
    local start_time=$(date +%s.%N)
    git add . 2>/dev/null
    local end_time=$(date +%s.%N)
    local add_time=$(echo "$end_time - $start_time" | bc)
    echo "git add: ${add_time}s" >&2

    # Test git commit
    start_time=$(date +%s.%N)
    git commit -q -m "Test commit" 2>/dev/null
    end_time=$(date +%s.%N)
    local commit_time=$(echo "$end_time - $start_time" | bc)
    echo "git commit: ${commit_time}s" >&2

    # Modify files
    for i in $(seq 1 50); do
        echo "modified content $i" >> "file$i.txt"
    done

    # Test git status
    start_time=$(date +%s.%N)
    git status >/dev/null 2>&1
    end_time=$(date +%s.%N)
    local status_time=$(echo "$end_time - $start_time" | bc)
    echo "git status: ${status_time}s" >&2

    # Test git diff
    start_time=$(date +%s.%N)
    git diff >/dev/null 2>&1
    end_time=$(date +%s.%N)
    local diff_time=$(echo "$end_time - $start_time" | bc)
    echo "git diff: ${diff_time}s" >&2

    local total_time=$(echo "$add_time + $commit_time + $status_time + $diff_time" | bc)
    echo "Total: ${total_time}s" >&2
    echo "" >&2

    # Return total time (stdout only)
    echo "$total_time"
}

test_section "Test 2: Git Operations"

WSL_GIT_TIME=$(test_git_operations "$WSL_TEST_DIR" "WSL filesystem")
WIN_GIT_TIME=$(test_git_operations "$WIN_TEST_DIR" "Windows mount")

GIT_RATIO=$(echo "scale=1; $WIN_GIT_TIME / $WSL_GIT_TIME" | bc)
echo "Result: Windows mount is ${GIT_RATIO}x slower for git operations"
echo ""

# ============================================================================
# Test 3: Sequential I/O (dd benchmark)
# ============================================================================

test_sequential_io() {
    local test_dir="$1"
    local location_name="$2"
    local block_count=100

    if [[ "$QUICK" == "true" ]]; then
        block_count=50
    fi

    echo "Test 3: Sequential I/O ($location_name)" >&2
    echo "Writing ${block_count}MB with dd..." >&2

    local output=$(dd if=/dev/zero of="$test_dir/test.dat" bs=1M count=$block_count conv=fdatasync 2>&1)
    local throughput=$(echo "$output" | grep -oP '\d+(\.\d+)? MB/s' | head -1 | grep -oP '\d+(\.\d+)?')

    if [[ -z "$throughput" ]]; then
        # Try alternative format (bytes/sec)
        throughput=$(echo "$output" | grep -oP '\d+(\.\d+)? [kMG]B/s' | head -1)
    fi

    echo "Throughput: ${throughput} MB/s" >&2
    echo "" >&2

    # Return throughput (stdout only)
    echo "$throughput"
}

test_section "Test 3: Sequential I/O (dd)"

WSL_IO_SPEED=$(test_sequential_io "$WSL_TEST_DIR" "WSL filesystem")
WIN_IO_SPEED=$(test_sequential_io "$WIN_TEST_DIR" "Windows mount")

echo "WSL filesystem: ${WSL_IO_SPEED} MB/s"
echo "Windows mount:  ${WIN_IO_SPEED} MB/s"
echo ""

# ============================================================================
# Test 4: Filesystem Type Detection
# ============================================================================

test_section "Test 4: Filesystem Type"

echo "WSL Test Directory:"
df -T "$WSL_TEST_DIR" | tail -1
echo ""

echo "Windows Mount Directory:"
df -T "$WIN_TEST_DIR" | tail -1
echo ""

# ============================================================================
# Summary
# ============================================================================

test_section "Performance Summary"

echo "Test                  | WSL vs /mnt/c/ Ratio"
echo "----------------------|---------------------"
echo "File Creation         | ${FILE_RATIO}x slower"
echo "Git Operations        | ${GIT_RATIO}x slower"
echo "Sequential I/O        | WSL: ${WSL_IO_SPEED} MB/s, Win: ${WIN_IO_SPEED} MB/s"
echo ""

# Determine overall result
OVERALL_SLOW=$(echo "$FILE_RATIO > 5 || $GIT_RATIO > 5" | bc)

if [[ "$OVERALL_SLOW" == "1" ]]; then
    echo "⚠ Windows mount (/mnt/c/) shows significant performance degradation"
    echo ""
    echo "Recommendation:"
    echo "  ✅ Store BitBot projects in WSL filesystem: ~/projects/"
    echo "  ⚠️  Avoid using /mnt/c/ for development"
    echo ""
    echo "Why the difference?"
    echo "  - WSL filesystem: Native ext4, direct kernel access"
    echo "  - Windows mount: 9P protocol translation layer"
    echo ""
fi

test_pass "Filesystem performance test completed"

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
