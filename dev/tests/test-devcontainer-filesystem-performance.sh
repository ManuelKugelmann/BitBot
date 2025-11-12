#!/usr/bin/env bash
#
# DevContainer Filesystem Performance Test - WSL vs Windows mount
# Tests filesystem performance from inside a devcontainer
#
# Usage: ./test-devcontainer-filesystem-performance.sh [--quick]
#
# MIGRATED TO USE: test-framework.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_HOME="$(cd "$SCRIPT_DIR/.." && pwd)"
export BITBOT_HOME

# Source test framework
source "${SCRIPT_DIR}/helpers/test-framework.sh"

# Source BitBot utilities for prerequisite checks
# shellcheck source=../core/util/helpers.sh
source "${BITBOT_HOME}/core/util/helpers.sh"
# shellcheck source=../core/util/prerequisites.sh
source "${BITBOT_HOME}/core/util/prerequisites.sh"

# Parse arguments
QUICK=false
if [[ "${1:-}" == "--quick" ]]; then
    QUICK=true
fi

test_suite_begin "DevContainer Filesystem Performance Test"

# Check if running on WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    test_skip "All tests" "Only runs on WSL - compares devcontainer filesystem performance between ext4 and 9P"
    test_suite_end
fi

# Check Docker using BitBot prerequisites
if ! check_docker; then
    exit 1
fi

# Test locations
WSL_TEST_DIR="$HOME/bitbot-devcontainer-perf-wsl"
WIN_TEST_DIR="/mnt/c/bitbot-devcontainer-perf-win"

# Cleanup on exit
cleanup() {
    echo ""
    echo "Cleaning up test directories and containers..."

    # Stop and remove containers
    docker ps -a | grep "bitbot-perf-test" | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true

    # Remove test directories
    rm -rf "$WSL_TEST_DIR" 2>/dev/null || true
    rm -rf "$WIN_TEST_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Create minimal workspace
create_test_workspace() {
    local test_dir="$1"

    mkdir -p "$test_dir"

    # Create benchmark script to run inside container
    cat > "$test_dir/benchmark.sh" <<'BENCHMARK_EOF'
#!/bin/bash
set -uo pipefail

QUICK=${1:-false}

echo "═══ DevContainer Filesystem Benchmark ═══"
echo "Working directory: $(pwd)"
echo "Filesystem type: $(df -T /workspace | tail -1 | awk '{print $2}')"
echo ""

# Test 1: File Creation
echo "Test 1: File Creation Speed"
FILE_COUNT=1000
if [[ "$QUICK" == "true" ]]; then
    FILE_COUNT=100
fi

mkdir -p /workspace/perf-test-files
start_time=$(date +%s.%N)
for i in $(seq 1 $FILE_COUNT); do
    touch "/workspace/perf-test-files/file$i.txt" 2>/dev/null || true
done
end_time=$(date +%s.%N)
duration=$(awk "BEGIN {print $end_time - $start_time}")
echo "  Created $FILE_COUNT files in ${duration}s"

# Test 2: Git Operations
echo ""
echo "Test 2: Git Operations"
git_dir="/workspace/perf-test-git"
mkdir -p "$git_dir"
cd "$git_dir" || exit 1
git init -q 2>/dev/null
git config user.email "test@bitbot.dev" 2>/dev/null
git config user.name "BitBot Test" 2>/dev/null

# Create test files
for i in $(seq 1 50); do
    echo "test content $i" > "file$i.txt"
done

# Time git operations
start_time=$(date +%s.%N)
git add . 2>/dev/null
end_time=$(date +%s.%N)
add_time=$(awk "BEGIN {print $end_time - $start_time}")

start_time=$(date +%s.%N)
git commit -q -m "Test commit" 2>/dev/null
end_time=$(date +%s.%N)
commit_time=$(awk "BEGIN {print $end_time - $start_time}")

# Modify files
for i in $(seq 1 50); do
    echo "modified $i" >> "file$i.txt"
done

start_time=$(date +%s.%N)
git status >/dev/null 2>&1
end_time=$(date +%s.%N)
status_time=$(awk "BEGIN {print $end_time - $start_time}")

total_git=$(awk "BEGIN {print $add_time + $commit_time + $status_time}")
echo "  git add: ${add_time}s"
echo "  git commit: ${commit_time}s"
echo "  git status: ${status_time}s"
echo "  Total: ${total_git}s"

# Test 3: Sequential I/O
echo ""
echo "Test 3: Sequential I/O (dd)"
BLOCK_COUNT=100
if [[ "$QUICK" == "true" ]]; then
    BLOCK_COUNT=50
fi

io_output=$(dd if=/dev/zero of=/workspace/perf-test.dat bs=1M count=$BLOCK_COUNT conv=fdatasync 2>&1)
throughput=$(echo "$io_output" | grep -oP '\d+(\.\d+)? [kMG]?B/s' | tail -1 || echo "N/A")
echo "  Throughput: $throughput"

# Output parseable results
echo ""
echo "RESULTS:"
echo "FILE_CREATION=$duration"
echo "GIT_OPERATIONS=$total_git"
echo "IO_THROUGHPUT=$throughput"
BENCHMARK_EOF

    chmod +x "$test_dir/benchmark.sh"
}

# Run benchmark in container using Docker directly
run_container_benchmark() {
    local test_dir="$1"
    local location_name="$2"
    local container_name="bitbot-perf-test-$(basename "$test_dir")"

    echo -e "${BLUE}═══ Running benchmark: $location_name"
    echo "Location: $test_dir"
    echo ""

    # Pull base image if needed
    if ! docker image inspect mcr.microsoft.com/devcontainers/base:ubuntu >/dev/null 2>&1; then
        echo "Pulling base image..."
        docker pull mcr.microsoft.com/devcontainers/base:ubuntu >/dev/null 2>&1
        echo -e "✓ Image pulled"
    fi

    # Run container with bind mount
    echo "Starting container with bind mount..."
    if ! docker run -d \
        --name "$container_name" \
        -v "$test_dir:/workspace" \
        mcr.microsoft.com/devcontainers/base:ubuntu \
        sleep infinity >/dev/null 2>&1; then
        echo -e "✗ Failed to start container"
        return 1
    fi
    echo -e "✓ Started"

    # Run benchmark inside container
    echo "Running filesystem benchmarks inside container..."
    echo ""

    local quick_arg="false"
    if [[ "$QUICK" == "true" ]]; then
        quick_arg="true"
    fi

    local results
    results=$(docker exec "$container_name" bash /workspace/benchmark.sh "$quick_arg" 2>&1) || true

    # Display results to user (stderr so it doesn't get captured)
    echo "$results" >&2
    echo "" >&2

    # Stop and remove container
    docker rm -f "$container_name" >/dev/null 2>&1 || true

    # Return results for parsing (stdout)
    echo "$results"
}

# ============================================================================
# Setup Test Workspaces
# ============================================================================

test_section "Setting up test workspaces"
echo ""

echo "Creating WSL test workspace..."
create_test_workspace "$WSL_TEST_DIR"
echo -e "✓ WSL workspace: $WSL_TEST_DIR"

echo "Creating Windows mount test workspace..."
create_test_workspace "$WIN_TEST_DIR"
echo -e "✓ Windows workspace: $WIN_TEST_DIR"
echo ""

# ============================================================================
# Run Benchmarks
# ============================================================================

test_section "Running Benchmarks"
echo ""

WSL_RESULTS=$(run_container_benchmark "$WSL_TEST_DIR" "WSL Filesystem (~)")

if [[ "$QUICK" != "true" ]]; then
    WIN_RESULTS=$(run_container_benchmark "$WIN_TEST_DIR" "Windows Mount (/mnt/c)")
else
    echo -e "⊘ Skipping Windows mount test (quick mode)"
    WIN_RESULTS=""
fi

# ============================================================================
# Parse and Compare Results
# ============================================================================

test_section "Performance Summary"

# Extract timing values
WSL_FILE=$(echo "$WSL_RESULTS" | grep "FILE_CREATION=" | cut -d= -f2 || echo "")
WSL_GIT=$(echo "$WSL_RESULTS" | grep "GIT_OPERATIONS=" | cut -d= -f2 || echo "")
WSL_IO=$(echo "$WSL_RESULTS" | grep "IO_THROUGHPUT=" | cut -d= -f2 || echo "")

if [[ "$QUICK" != "true" ]] && [[ -n "$WIN_RESULTS" ]]; then
    WIN_FILE=$(echo "$WIN_RESULTS" | grep "FILE_CREATION=" | cut -d= -f2 || echo "")
    WIN_GIT=$(echo "$WIN_RESULTS" | grep "GIT_OPERATIONS=" | cut -d= -f2 || echo "")
    WIN_IO=$(echo "$WIN_RESULTS" | grep "IO_THROUGHPUT=" | cut -d= -f2 || echo "")

    # Calculate ratios
    if [[ -n "$WSL_FILE" ]] && [[ -n "$WIN_FILE" ]] && [[ "$WSL_FILE" != "0" ]]; then
        FILE_RATIO=$(awk "BEGIN {printf \"%.1f\", $WIN_FILE / $WSL_FILE}")
        echo "File Creation:  Windows mount is ${FILE_RATIO}x slower"
    else
        FILE_RATIO="0"
    fi

    if [[ -n "$WSL_GIT" ]] && [[ -n "$WIN_GIT" ]] && [[ "$WSL_GIT" != "0" ]]; then
        GIT_RATIO=$(awk "BEGIN {printf \"%.1f\", $WIN_GIT / $WSL_GIT}")
        echo "Git Operations: Windows mount is ${GIT_RATIO}x slower"
    else
        GIT_RATIO="0"
    fi

    echo ""
    echo "Test Location              | File Creation | Git Ops   | I/O"
    echo "---------------------------|---------------|-----------|----------"
    printf "WSL (~)                    | %-13s | %-9s | %s\n" "${WSL_FILE}s" "${WSL_GIT}s" "${WSL_IO}"
    printf "Windows (/mnt/c)           | %-13s | %-9s | %s\n" "${WIN_FILE}s" "${WIN_GIT}s" "${WIN_IO}"
    echo ""

    # Determine if performance is significantly worse
    OVERALL_SLOW=$(awk "BEGIN {print ($FILE_RATIO > 3 || $GIT_RATIO > 3) ? 1 : 0}")

    if [[ "$OVERALL_SLOW" == "1" ]]; then
        echo "⚠ WARNING: Windows mount (/mnt/c/) shows significant performance impact"
        echo ""
        echo "Recommendation for DevContainers:"
        echo "  ✅ Clone repos to WSL filesystem: ~/projects/"
        echo "  ⚠️  Avoid cloning to /mnt/c/ for devcontainer work"
        echo ""
        echo "Why the difference?"
        echo "  - WSL location: Direct ext4 access, minimal overhead"
        echo "  - Windows mount: 9P protocol adds latency to every I/O"
        echo "  - DevContainers amplify this with frequent file access"
        echo ""
    fi
else
    echo "WSL Filesystem Results:"
    echo "  File Creation: ${WSL_FILE}s"
    echo "  Git Operations: ${WSL_GIT}s"
    echo "  I/O Throughput: ${WSL_IO}"
    echo ""
fi

test_pass "DevContainer filesystem performance test completed"

# ============================================================================
# Test Suite Complete
# ============================================================================

test_suite_end
