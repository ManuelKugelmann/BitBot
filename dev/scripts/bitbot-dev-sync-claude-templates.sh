#!/usr/bin/env bash
# sync-claude-to-templates.sh - Sync .claude setup to container templates
#
# Copies .claude configuration to templates with filtering:
# - Base content (hooks, tools, settings.json) → all templates
# - bitbot-dev-* content → bitbot-dev template only
# - bitbot-work-* content → bitbot-work template only
# - bitbot-config-* content → bitbot-config template only
#
# Usage: sync-claude-to-templates.sh

set -euo pipefail

# Find project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SOURCE_CLAUDE="$PROJECT_ROOT/.claude"
TEMPLATES_DIR="$PROJECT_ROOT/container/templates"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   BitBot .claude → Templates Sync${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Validate source exists
if [ ! -d "$SOURCE_CLAUDE" ]; then
    echo -e "${RED}ERROR: Source .claude directory not found: $SOURCE_CLAUDE${NC}"
    exit 1
fi

# Validate templates directory exists
if [ ! -d "$TEMPLATES_DIR" ]; then
    echo -e "${RED}ERROR: Templates directory not found: $TEMPLATES_DIR${NC}"
    exit 1
fi

# Define template targets
declare -A TEMPLATES
TEMPLATES=(
    ["bitbot-base"]="$TEMPLATES_DIR/bitbot-base"
    ["bitbot-config"]="$TEMPLATES_DIR/bitbot-config"
    ["bitbot-dev"]="$TEMPLATES_DIR/bitbot-dev"
    ["bitbot-work"]="$TEMPLATES_DIR/bitbot-work"
)

# Base content (shared by all templates)
BASE_DIRS=("hooks" "tools")
BASE_FILES=("settings.json" ".gitignore")

# Sync base content to a template
sync_base_content() {
    local template_name="$1"
    local target_dir="$2"
    local target_claude="$target_dir/.claude"

    echo -e "${BLUE}→${NC} Syncing base content to ${YELLOW}$template_name${NC}..."

    # Create .claude directory
    mkdir -p "$target_claude"

    # Copy base directories
    for dir in "${BASE_DIRS[@]}"; do
        if [ -d "$SOURCE_CLAUDE/$dir" ]; then
            echo "  Copying $dir/"
            rm -rf "$target_claude/$dir"
            cp -r "$SOURCE_CLAUDE/$dir" "$target_claude/"
        fi
    done

    # Copy base files
    for file in "${BASE_FILES[@]}"; do
        if [ -f "$SOURCE_CLAUDE/$file" ]; then
            echo "  Copying $file"
            cp "$SOURCE_CLAUDE/$file" "$target_claude/"
        fi
    done

    # Copy skills (filtered by prefix)
    echo "  Copying skills (filtered)..."
    mkdir -p "$target_claude/skills"

    # Copy all skills that don't have template-specific prefixes
    for skill_dir in "$SOURCE_CLAUDE/skills"/*; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")

            # Check if skill has a template-specific prefix
            if [[ ! "$skill_name" =~ ^bitbot-(dev|work|config)- ]]; then
                echo "    + $skill_name (shared)"
                rm -rf "$target_claude/skills/$skill_name"
                cp -r "$skill_dir" "$target_claude/skills/"
            fi
        fi
    done
}

# Sync template-specific content
sync_template_specific() {
    local template_name="$1"
    local target_dir="$2"
    local prefix="$3"
    local target_claude="$target_dir/.claude"

    echo -e "${BLUE}→${NC} Syncing ${YELLOW}$prefix*${NC} content to ${YELLOW}$template_name${NC}..."

    mkdir -p "$target_claude/skills"

    local found=0
    for skill_dir in "$SOURCE_CLAUDE/skills"/*; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")

            # Check if skill matches template prefix
            if [[ "$skill_name" =~ ^${prefix}- ]]; then
                echo "    + $skill_name (template-specific)"
                rm -rf "$target_claude/skills/$skill_name"
                cp -r "$skill_dir" "$target_claude/skills/"
                found=1
            fi
        fi
    done

    if [ $found -eq 0 ]; then
        echo "    (no template-specific skills found)"
    fi
}

# Sync to each template
for template_name in "${!TEMPLATES[@]}"; do
    target_dir="${TEMPLATES[$template_name]}"

    if [ ! -d "$target_dir" ]; then
        echo -e "${YELLOW}⚠${NC}  Template directory not found: $target_dir (skipping)"
        continue
    fi

    echo ""

    # Sync base content
    sync_base_content "$template_name" "$target_dir"

    # Sync template-specific content
    case "$template_name" in
        bitbot-dev)
            sync_template_specific "$template_name" "$target_dir" "bitbot-dev"
            ;;
        bitbot-work)
            sync_template_specific "$template_name" "$target_dir" "bitbot-work"
            ;;
        bitbot-config)
            sync_template_specific "$template_name" "$target_dir" "bitbot-config"
            ;;
    esac
done

echo ""
echo -e "${GREEN}✓${NC} Sync complete!"
echo ""
echo "Summary:"
echo "  Base content: hooks, tools, settings.json, shared skills"
echo "  Template-specific: bitbot-{dev,work,config}-* skills"
echo ""
