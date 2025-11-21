#!/bin/bash
set -e

# Merges all BitBot devcontainer templates
# Runs merge-devcontainer.sh for each template directory

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Merging All BitBot DevContainer Templates ==="
echo ""

TEMPLATES=(
    "bitbot-config"
    "bitbot-dev"
    "bitbot-work"
)

FAILED=()
SUCCEEDED=()

for template in "${TEMPLATES[@]}"; do
    TEMPLATE_DIR="$TEMPLATES_DIR/$template"

    if [ ! -d "$TEMPLATE_DIR" ]; then
        echo "⚠ Template not found: $template (skipping)"
        continue
    fi

    if [ ! -f "$TEMPLATE_DIR/.devcontainer/details.devcontainer.json" ]; then
        echo "⚠ No .devcontainer/details.devcontainer.json in $template (skipping)"
        continue
    fi

    echo "--- Merging: $template ---"
    if bash "$SCRIPT_DIR/merge-devcontainer.sh" "$TEMPLATE_DIR"; then
        SUCCEEDED+=("$template")
    else
        FAILED+=("$template")
    fi
    echo ""
done

# Summary
echo "=== Summary ==="
echo "✓ Succeeded: ${#SUCCEEDED[@]}"
for template in "${SUCCEEDED[@]}"; do
    echo "  - $template"
done

if [ ${#FAILED[@]} -gt 0 ]; then
    echo "✗ Failed: ${#FAILED[@]}"
    for template in "${FAILED[@]}"; do
        echo "  - $template"
    done
    exit 1
else
    echo ""
    echo "All templates merged successfully!"
fi
