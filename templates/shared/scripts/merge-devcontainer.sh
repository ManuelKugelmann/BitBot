#!/bin/bash
set -e

# Merges base.devcontainer.json + details.devcontainer.json => devcontainer.json
#
# Usage: ./merge-devcontainer.sh <template-dir>
# Example: ./merge-devcontainer.sh templates/workspace

TEMPLATE_DIR="${1:-.}"
SHARED_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BASE_FILE="$SHARED_DIR/base.devcontainer.json"
DETAILS_FILE="$TEMPLATE_DIR/details.devcontainer.json"
OUTPUT_FILE="$TEMPLATE_DIR/devcontainer.json"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required for merging devcontainer.json files"
    echo "Install: apt-get install jq (or brew install jq on macOS)"
    exit 1
fi

# Check if base file exists
if [ ! -f "$BASE_FILE" ]; then
    echo "Error: Base devcontainer.json not found at: $BASE_FILE"
    exit 1
fi

# Check if details file exists
if [ ! -f "$DETAILS_FILE" ]; then
    echo "Error: Template details file not found at: $DETAILS_FILE"
    echo "Create $DETAILS_FILE with template-specific configuration"
    exit 1
fi

echo "Merging devcontainer.json..."
echo "  Base:    $BASE_FILE"
echo "  Details: $DETAILS_FILE"
echo "  Output:  $OUTPUT_FILE"

# Merge strategy:
# - Deep recursive merge for objects
# - Arrays are REPLACED (not merged) to avoid duplicates
# - Details override base values
#
# jq merge formula: base * details
# This does a recursive merge where details values override base values

jq -s '.[0] * .[1]' "$BASE_FILE" "$DETAILS_FILE" > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "✓ Successfully merged devcontainer.json"
    echo ""
    echo "Generated: $OUTPUT_FILE"
else
    echo "✗ Merge failed"
    exit 1
fi
