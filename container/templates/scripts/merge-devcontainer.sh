#!/bin/bash
set -e

# Merges base.devcontainer.json + details.devcontainer.json => devcontainer.json
#
# Usage: ./merge-devcontainer.sh <template-dir>
# Example: ./merge-devcontainer.sh templates/workspace

TEMPLATE_DIR="${1:-.}"
TEMPLATES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BASE_FILE="$TEMPLATES_DIR/bitbot-base/.devcontainer/devcontainer.json"
DETAILS_FILE="$TEMPLATE_DIR/.devcontainer/details.devcontainer.json"
OUTPUT_FILE="$TEMPLATE_DIR/.devcontainer/devcontainer.json"

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
# - EXCEPT: "mounts" array - intelligently merged:
#   - Concatenate base + details mounts
#   - If same target path appears in both, details mount wins (replaces base)
#   - This allows config mode to override .devcontainer mount to RW
#
# jq merge formula:
#   1. Merge base * details (arrays replaced)
#   2. Mounts handling: concatenate base + details, dedup by target

jq -s '
  # Merge everything except mounts
  (.[0] * .[1]) as $merged |

  # Handle mounts specially
  if (.[0].mounts or .[1].mounts) then
    # Helper function to extract target from mount string
    def get_target: . | capture("target=(?<path>[^,]+)") | .path;

    # Start with base mounts (or empty array)
    (.[0].mounts // []) as $base_mounts |
    (.[1].mounts // []) as $details_mounts |

    # Get targets from details mounts (these override base)
    ($details_mounts | map(get_target)) as $details_targets |

    # Filter base mounts: keep only those NOT overridden by details
    ($base_mounts | map(select(get_target as $t | ($details_targets | index($t)) == null))) as $filtered_base |

    # Concatenate: filtered base + all details
    $merged | .mounts = ($filtered_base + $details_mounts)
  else
    $merged
  end
' "$BASE_FILE" "$DETAILS_FILE" > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "✓ Successfully merged devcontainer.json"
    echo ""
    echo "Generated: $OUTPUT_FILE"
else
    echo "✗ Merge failed"
    exit 1
fi
