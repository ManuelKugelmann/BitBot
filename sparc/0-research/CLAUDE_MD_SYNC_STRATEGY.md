# CLAUDE.md Sync Strategy

**Purpose**: Define how CLAUDE.md content is organized and synced to templates
**Created**: 2025-10-28

---

## Problem

We have one CLAUDE.md in the root that contains:
- Universal end-user guidance (for ALL BitBot users)
- BitBot development-specific content (for BitBot developers only)

We need to sync the end-user content to templates without syncing dev content.

---

## Solution: Section Markers

Use HTML comment markers to delineate sections:

```markdown
<!-- ============================================================================
     UNIVERSAL END-USER CONTENT (synced to ALL templates)
     Everything above "TEMPLATE-SPECIFIC" marker gets synced
     ============================================================================ -->

[Content about stop hooks, skills, general guidelines, etc.]

<!-- ============================================================================
     TEMPLATE-SPECIFIC CONTENT
     Each template can add custom sections here
     ============================================================================ -->

<!-- ============================================================================
     BITBOT DEVELOPMENT CONTENT (NOT synced to templates)
     Everything below this marker is for BitBot development only
     ============================================================================ -->

[Content about project structure, SPARC, testing, etc.]
```

---

## Content Organization

### Universal End-User Content (Synced to ALL Templates)

**What belongs here**:
- Stop Hook / Do-Not-Stop automation
- Context Management (/compact, /clear)
- Available Skills overview
- General Guidelines (emoji usage, line endings, testing)
- PowerShell/CMD usage (if needed in containers)
- Mermaid diagram guidelines (if applicable)

**Why**: All BitBot users need this regardless of which template they use.

### Template-Specific Content (Added by Each Template)

**What belongs here**:
- Template-specific skills (e.g., bitbot-config-* skills for config template)
- Template-specific workflows
- Special features of that template
- Template customization examples

**Examples**:
- `bitbot-base/` template: Minimal setup guidance
- `bitbot-config/` template: DevContainer customization help
- `bitbot-dev/` template: Cross-compilation, release scripts
- `bitbot-work/` template: AI workspace features, MCP integration

### BitBot Development Content (NOT Synced)

**What belongs here**:
- Project Structure (folder organization)
- Core Directories explanation
- Development Artifacts (/dev/, /sparc/)
- Naming Conventions for BitBot code
- Container Templates internals
- SPARC Process methodology
- Testing Guidelines for BitBot itself
- DevContainer Context (dev vs user)

**Why**: Users don't need to understand BitBot's internal structure.

---

## Sync Script

**File**: `dev/scripts/sync-claude-md-to-templates.sh`

```bash
#!/usr/bin/env bash
# Sync CLAUDE.md universal content to templates

ROOT_CLAUDE="CLAUDE.md"
TEMPLATES_DIR="container/templates"

# Extract universal content (everything before "BITBOT DEVELOPMENT" marker)
UNIVERSAL_CONTENT=$(sed '/BITBOT DEVELOPMENT SECTION/Q' "$ROOT_CLAUDE")

# For each template
for template in base config bitbotdev workspace; do
    TEMPLATE_DIR="$TEMPLATES_DIR/$template/.claude"
    TARGET_FILE="$TEMPLATE_DIR/CLAUDE.md"

    # Create directory if needed
    mkdir -p "$TEMPLATE_DIR"

    # Write universal content
    echo "$UNIVERSAL_CONTENT" > "$TARGET_FILE"

    # Add template-specific marker
    cat >> "$TARGET_FILE" <<'EOF'

<!-- ============================================================================
     TEMPLATE-SPECIFIC CONTENT
     Add template-specific guidance below
     ============================================================================ -->
EOF

    # If template has additions file, append it
    ADDITIONS_FILE="$TEMPLATES_DIR/$template/.claude/CLAUDE_ADDITIONS.md"
    if [ -f "$ADDITIONS_FILE" ]; then
        cat "$ADDITIONS_FILE" >> "$TARGET_FILE"
    fi

    echo "✓ Synced to $template"
done
```

---

## Template Additions Files

Each template can have a `CLAUDE_ADDITIONS.md` file with template-specific content:

### bitbot-base/.claude/CLAUDE_ADDITIONS.md

```markdown
## Base Template

You are working in a minimal BitBot container with:
- Essential tools only (git, curl, node, claude)
- No extra features
- Good for simple projects

To add features, edit `.devcontainer/devcontainer.json`.
```

### bitbot-config/.claude/CLAUDE_ADDITIONS.md

```markdown
## Config Template

This template includes DevContainer customization skills:

**Available Skills**:
- `devcontainer-help` - Help adding packages, extensions, features

**Focus**: Help users customize their devcontainer, not BitBot internals.
```

### bitbot-dev/.claude/CLAUDE_ADDITIONS.md

```markdown
## BitBot Development Template

You are working on BitBot itself. This includes:
- Cross-compilation tools (MinGW for Windows launcher)
- Release scripts in `/dev/scripts/`
- Test suites in `/dev/tests/`
- SPARC documentation in `/sparc/`

**Special Skills**:
- `bitbot-dev-release` - Create release branches
- `bitbot-dev-test` - Run test suites

See root `CLAUDE.md` for full BitBot development guidance.
```

### bitbot-work/.claude/CLAUDE_ADDITIONS.md

```markdown
## AI Workspace Template

This template is optimized for AI-assisted development:
- Shared home folders (`.claude/`, `.opencode/`, etc.)
- MCP service integration
- All AI coding assistant features

**Available Skills**:
- All base skills (stop hook, restart, etc.)
- AI workflow helpers
```

---

## Workflow

### 1. Update Universal Content

```bash
# Edit root CLAUDE.md (before "BITBOT DEVELOPMENT" marker)
vim CLAUDE.md

# Sync to all templates
dev/scripts/sync-claude-md-to-templates.sh

# Commit
git add CLAUDE.md container/templates/*/.claude/CLAUDE.md
git commit -m "Update universal CLAUDE.md content"
```

### 2. Update Template-Specific Content

```bash
# Edit template additions
vim container/templates/config/.claude/CLAUDE_ADDITIONS.md

# Sync (regenerates CLAUDE.md with new additions)
dev/scripts/sync-claude-md-to-templates.sh

# Commit
git add container/templates/config/.claude/
git commit -m "Update config template CLAUDE.md additions"
```

### 3. Update BitBot Dev Content

```bash
# Edit root CLAUDE.md (after "BITBOT DEVELOPMENT" marker)
vim CLAUDE.md

# No sync needed - this content stays in root only
git add CLAUDE.md
git commit -m "Update BitBot development guidance"
```

---

## Benefits

**Separation of Concerns**:
- End users see only what they need
- BitBot developers see everything
- Templates can add custom content

**Easy Maintenance**:
- Update universal content once → syncs everywhere
- Update dev content → stays in root
- Templates control their own additions

**Clear Boundaries**:
- HTML markers make sections obvious
- Sync script enforces structure
- Can't accidentally sync dev content to users

---

## Migration Plan

1. **Identify content type** in current CLAUDE.md:
   - Universal → Keep before marker
   - Template-specific → Move to CLAUDE_ADDITIONS.md
   - Dev-only → Move after marker

2. **Add markers** to CLAUDE.md:
   - Universal content (top)
   - Template marker (middle)
   - Dev content (bottom)

3. **Create additions files** for each template

4. **Create sync script**

5. **Run sync** to generate template CLAUDE.md files

6. **Test** in each template devcontainer

---

## Success Criteria

- [x] CLAUDE.md clearly marked with sections
- [ ] Sync script creates template CLAUDE.md files
- [ ] Template additions preserved during sync
- [ ] Universal content consistent across templates
- [ ] Dev content not in template files
- [ ] Templates can customize their CLAUDE.md

---

## Related

- Root `CLAUDE.md` - Source of truth
- `dev/scripts/sync-claude-md-to-templates.sh` - Sync script
- `container/templates/*/.claude/CLAUDE_ADDITIONS.md` - Template-specific content
- `container/templates/*/.claude/CLAUDE.md` - Generated files (synced)
