#!/bin/bash
set -e

# Sync CLAUDE.md universal content to templates
# Usage: ./sync-claude-md-to-templates.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROOT_CLAUDE="$PROJECT_ROOT/CLAUDE.md"
TEMPLATES_DIR="$PROJECT_ROOT/container/templates"

# Universal sections (for all users)
UNIVERSAL_SECTIONS=(
    "Stop Hook Automation"
    "Context Management"
    "Available Skills"
    "Statusline (Optional)"
    "PowerShell/CMD from WSL"
    "Mermaid Diagram Guidelines"
)

# BitBot dev sections (NOT synced)
DEV_SECTIONS=(
    "Project Structure"
    "SPARC Process"
    "DevContainer Context"
    "Testing Guidelines"
    "Container Templates"
    "Naming Conventions"
    "Development Artifacts"
    "Core Directories"
    "Top-Level Organization"
)

echo "=== Syncing CLAUDE.md to Templates ==="
echo ""

# Check if root CLAUDE.md exists
if [ ! -f "$ROOT_CLAUDE" ]; then
    echo "Error: Root CLAUDE.md not found at: $ROOT_CLAUDE"
    exit 1
fi

# Check for INBOX section with unsorted content
if grep -q "^## INBOX" "$ROOT_CLAUDE"; then
    echo "Error: INBOX section found in CLAUDE.md"
    echo ""
    echo "The INBOX section contains unsorted content that must be organized first."
    echo "Please:"
    echo "  1. Review content in ## INBOX section"
    echo "  2. Move items to appropriate sections"
    echo "  3. Remove ## INBOX section header"
    echo "  4. Re-run sync script"
    echo ""
    exit 1
fi

# Templates to sync
TEMPLATES=(
    "bitbot-base"
    "bitbot-config"
    "bitbot-dev"
    "bitbot-work"
)

# For each template
for template in "${TEMPLATES[@]}"; do
    TEMPLATE_DIR="$TEMPLATES_DIR/$template"
    CLAUDE_DIR="$TEMPLATE_DIR/.claude"
    TARGET_FILE="$CLAUDE_DIR/CLAUDE.md"
    ADDITIONS_FILE="$CLAUDE_DIR/CLAUDE_ADDITIONS.md"

    echo "--- Syncing to: $template ---"

    # Check if template exists
    if [ ! -d "$TEMPLATE_DIR" ]; then
        echo "⚠ Template directory not found: $template (skipping)"
        continue
    fi

    # Create .claude directory if needed
    mkdir -p "$CLAUDE_DIR"

    # Start with header
    cat > "$TARGET_FILE" <<'EOF'
# BitBot CLAUDE.md

This file contains guidance for Claude Code when working in BitBot containers.

<!-- ============================================================================
     UNIVERSAL CONTENT (synced from root)
     This content is automatically synced from root CLAUDE.md
     ============================================================================ -->

EOF

    # Extract universal sections from root CLAUDE.md
    # For now, extract everything between "Stop Hook Automation" and "BITBOT DEVELOPMENT"
    # This is a simplified approach - full implementation would parse sections properly

    # Find start of universal content (Stop Hook Automation)
    START_LINE=$(grep -n "^## Stop Hook Automation" "$ROOT_CLAUDE" | head -1 | cut -d: -f1)

    # Find end of universal content (BITBOT DEVELOPMENT marker)
    END_LINE=$(grep -n "BITBOT DEVELOPMENT SECTION" "$ROOT_CLAUDE" | head -1 | cut -d: -f1)

    if [ -n "$START_LINE" ] && [ -n "$END_LINE" ]; then
        # Extract universal content
        sed -n "${START_LINE},$((END_LINE-1))p" "$ROOT_CLAUDE" >> "$TARGET_FILE"
    else
        echo "⚠ Could not find section markers in root CLAUDE.md"
    fi

    # Add template-specific marker
    cat >> "$TARGET_FILE" <<'EOF'

<!-- ============================================================================
     TEMPLATE-SPECIFIC CONTENT
     Add template-specific guidance below
     ============================================================================ -->

EOF

    # If template has additions file, append it
    if [ -f "$ADDITIONS_FILE" ]; then
        cat "$ADDITIONS_FILE" >> "$TARGET_FILE"
        echo "  ✓ Included template additions"
    else
        echo "  ℹ No template additions file"
    fi

    echo "  ✓ Synced to: $TARGET_FILE"
    echo ""
done

echo "=== Sync Complete ==="
echo ""
echo "Summary:"
echo "  Root: $ROOT_CLAUDE"
echo "  Templates synced: ${#TEMPLATES[@]}"
echo ""
echo "Next steps:"
echo "  1. Review generated CLAUDE.md files in each template"
echo "  2. Create CLAUDE_ADDITIONS.md files for template-specific content"
echo "  3. Commit changes"
