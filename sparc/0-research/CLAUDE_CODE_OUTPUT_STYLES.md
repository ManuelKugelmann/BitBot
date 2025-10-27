# Claude Code Output Styles Research

**Date**: 2025-10-27
**Status**: Completed
**Related**: Claude Code Integration, AI Tool Configuration

---

## Executive Summary

Claude Code output styles are system prompt modifications that adapt Claude Code's behavior beyond software engineering. They allow repurposing Claude Code's core capabilities (running scripts, managing files, tracking TODOs) for different workflows while maintaining full tool access.

**Key Finding**: Output styles replace the default engineering-focused system prompt with custom instructions, unlike CLAUDE.md which appends to the existing prompt.

---

## What Are Output Styles?

Output styles are stored system prompts that completely override Claude Code's default software engineering instructions. They enable Claude Code to be repurposed for:

- Documentation writing
- Teaching and learning
- Research tasks
- Domain-specific workflows
- Non-coding applications

Unlike CLAUDE.md files (which append to the system prompt), output styles **replace** the coding-specific portions of the prompt entirely.

---

## Built-In Output Styles

Claude Code provides three built-in styles:

| Style | Purpose | Behavior |
|-------|---------|----------|
| **Default** | Software engineering | Standard coding-focused system prompt |
| **Explanatory** | Educational coding | Provides insights alongside code to explain implementation patterns |
| **Learning** | Interactive teaching | Asks user to complete sections marked with `TODO(human)` labels |

---

## How Output Styles Work

### System Prompt Modification

From the documentation:

> "Non-default output styles exclude instructions specific to code generation and efficient output normally built into Claude Code."

Instead, custom instructions are substituted to tailor behavior for specific workflows.

### Persistence

- Style selection persists in `.claude/settings.local.json` at the project level
- Changes via `/output-style [style-name]` apply to current project
- Each project can have its own active style

### Tool Access Preserved

All Claude Code tools remain available:
- File operations (Read, Write, Edit)
- Command execution (Bash)
- Task management (TodoWrite)
- Web fetching (WebFetch)
- Agents (Task)

Only the **instructions** change, not the **capabilities**.

---

## File Format

Custom output styles use **Markdown with YAML frontmatter**:

```markdown
---
name: My Custom Style
description:
  A brief description of what this style does, to be displayed to the user
---

# Custom Style Instructions

[Your custom instructions here...]

## Specific Behaviors

[Define how the assistant should behave...]

## Examples

[Provide examples of desired output...]
```

**Frontmatter Fields:**
- `name`: Display name for the style
- `description`: Shown in style selection menu

**Content:**
- Markdown instructions defining behavior
- Can include examples, guidelines, formatting rules
- Should specify tone, structure, and approach

---

## Storage Locations

Output styles can be stored at two levels:

| Location | Path | Scope |
|----------|------|-------|
| **User Level** | `~/.claude/output-styles/` | Available across all projects |
| **Project Level** | `.claude/output-styles/` | Specific to one project |

**File Naming**: Use `.md` extension (e.g., `documentation.md`, `teaching.md`)

---

## Creating Custom Styles

### Method 1: Interactive Creation

```bash
/output-style:new [description]
```

Launches interactive setup process that:
1. Asks for style details
2. Helps craft instructions
3. Saves to `~/.claude/output-styles/`

### Method 2: Manual Creation

1. Create directory: `mkdir -p ~/.claude/output-styles/`
2. Create file: `vim ~/.claude/output-styles/my-style.md`
3. Add YAML frontmatter and instructions
4. Save and use: `/output-style my-style`

---

## Using Output Styles

### Switch Styles

```bash
# Switch to specific style
/output-style [style-name]

# Open style selection menu
/output-style

# Return to default
/output-style default
```

### View Current Style

Current style is stored in `.claude/settings.local.json`:

```json
{
  "outputStyle": "explanatory"
}
```

---

## Comparison: Output Styles vs CLAUDE.md vs --append-system-prompt

| Feature | Output Styles | CLAUDE.md | --append-system-prompt |
|---------|---------------|-----------|------------------------|
| **Replaces system prompt** | ✅ Yes (coding parts) | ❌ No (appends) | ❌ No (appends) |
| **Stored as files** | ✅ Yes | ✅ Yes | ❌ CLI flag |
| **Project-specific** | ✅ Yes | ✅ Yes | ✅ Yes (per invocation) |
| **User-global** | ✅ Yes | ❌ No | ❌ No |
| **Built-in options** | ✅ Yes (3) | ❌ N/A | ❌ N/A |
| **Interactive creation** | ✅ Yes | ❌ Manual | ❌ Manual |
| **Best for** | Non-coding workflows | Project guidelines | One-off instructions |

---

## Use Cases for BitBot

### 1. Documentation Mode

Create an output style for writing BitBot documentation:

```markdown
---
name: BitBot Documentation
description: Optimized for writing clear, concise BitBot documentation
---

# BitBot Documentation Style

You are writing documentation for BitBot, a secure AI development environment.

## Tone and Style
- Clear and concise
- Technical but accessible
- Use bullet points and tables
- Include examples for all features

## Structure
- Start with executive summary
- Use hierarchical headings
- Provide code examples
- Link to related docs

## Formatting
- Use GitHub-flavored Markdown
- Keep tables narrow (terminal-friendly)
- Use unicode symbols sparingly
- Include command examples in code blocks
```

**Usage**:
```bash
cd ~/Projects/BitBot
/output-style bitbot-documentation
# Now Claude is optimized for documentation tasks
```

### 2. SPARC Specification Mode

Create style for writing SPARC specifications:

```markdown
---
name: SPARC Specification
description: Format for writing BitBot SPARC specifications
---

# SPARC Specification Writing

You are writing specifications for BitBot using the SPARC methodology.

## Format
- Use bulletpoints and pseudocode only
- No extensive code in specifications
- Clear, structured sections
- Acceptance criteria for each feature

## Structure
1. Overview
2. Requirements
3. Use Cases
4. Acceptance Criteria
5. Dependencies
6. Notes

## Style
- Technical but high-level
- Focus on "what" not "how"
- Reference related specs
- Include diagrams (Mermaid)
```

### 3. Testing Mode

Create style for BitBot test development:

```markdown
---
name: BitBot Testing
description: Optimized for writing and running BitBot tests
---

# BitBot Testing Mode

You are developing tests for BitBot.

## Testing Approach
- Use existing test helpers
- Follow test structure in dev/tests/
- Use .claude/tools for line endings and syntax checks
- Run tests with timeout wrapper

## Test Structure
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITBOT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test helpers
test_pass() { echo -e "${GREEN}✓${NC} $1"; }
test_fail() { echo -e "${RED}✗${NC} $1"; }
```

## Quality Checks
- Always use .claude/tools/fix-line-endings-check-bash
- Run with .claude/tools/run-with-timeout
- Test both success and failure cases
```

---

## BitBot Global Configuration Integration

Output styles fit into BitBot's global AI tool configuration:

```
~/.claude/                          # Global Claude Code config (shared)
├── settings.json                   # Global settings
├── output-styles/                  # User-level output styles
│   ├── bitbot-documentation.md
│   ├── sparc-specification.md
│   └── bitbot-testing.md
└── CLAUDE.md                       # Global preferences (optional)

/workspace/                         # User's project
├── .claude/
│   ├── settings.local.json         # Project settings (active style)
│   ├── output-styles/              # Project-specific styles
│   └── CLAUDE.md                   # Project guidelines
```

**Benefits:**
- Output styles available across all BitBot workspaces
- Per-project style selection
- Combines with project CLAUDE.md for complete customization

---

## Recommendations for BitBot

### 1. Provide Sample Output Styles

Include sample output styles in BitBot's workspace template:

**Location**: `container/templates/bitbot/workspace/home/.claude/output-styles/`

**Samples to include:**
- `bitbot-documentation.md` - Documentation writing
- `sparc-specification.md` - SPARC spec writing
- `bitbot-testing.md` - Test development

### 2. Document Output Styles in User Guide

Add section to README.md or README_EXTENDED.md:

```markdown
## Customizing Claude Code Behavior

BitBot's workspace includes sample output styles for common tasks:

- `/output-style bitbot-documentation` - Documentation writing
- `/output-style sparc-specification` - SPARC specifications
- `/output-style bitbot-testing` - Test development
- `/output-style default` - Standard coding mode

Create custom styles: `/output-style:new my-style`
```

### 3. Add to Global Configuration Spec

Update `sparc/1-specification/GLOBAL_CLAUDE_CONFIG_SPEC.md`:

```markdown
### Output Styles

User-level output styles in `~/.claude/output-styles/` are available across all workspaces:

- BitBot workspace template includes sample styles
- Users can create custom styles with `/output-style:new`
- Active style stored per-project in `.claude/settings.local.json`
- Combines with CLAUDE.md for complete customization
```

---

## Implementation Considerations

### 1. Template Integration

**Action**: Add sample output styles to workspace template

**Files to create:**
- `container/templates/bitbot/workspace/home/.claude/output-styles/bitbot-documentation.md`
- `container/templates/bitbot/workspace/home/.claude/output-styles/sparc-specification.md`
- `container/templates/bitbot/workspace/home/.claude/output-styles/bitbot-testing.md`

### 2. Documentation Updates

**Action**: Document output styles in user guides

**Files to update:**
- `README.md` or `README_EXTENDED.md` - Brief mention
- `container/templates/bitbot/workspace/README.md` - Detailed usage

### 3. SPARC Specification Update

**Action**: Add output styles to global config spec

**File to update:**
- `sparc/1-specification/GLOBAL_CLAUDE_CONFIG_SPEC.md`

---

## References

- [Claude Code Output Styles Documentation](https://docs.claude.com/en/docs/claude-code/output-styles.md)
- [Claude Code Docs Map](https://docs.claude.com/en/docs/claude-code/claude_code_docs_map.md)
- [BitBot Global Configuration Spec](../1-specification/GLOBAL_CLAUDE_CONFIG_SPEC.md)
- [Workspace Template README](../../container/templates/bitbot/workspace/README.md)

---

## Conclusion

Claude Code output styles provide powerful customization for non-coding workflows. For BitBot:

1. **User Experience**: Sample styles make Claude Code more versatile out-of-the-box
2. **Global Configuration**: Styles shared across workspaces via `~/.claude/output-styles/`
3. **Flexibility**: Users can switch styles per-task or create custom styles
4. **Integration**: Works alongside CLAUDE.md for complete customization

**Status**: ✅ Research complete. Ready for implementation planning.
