# AI Coding Agent Configuration Standards Research

**Date:** October 2025
**Purpose:** Survey of unified AI coding and CLI agent settings across major tools

## Executive Summary

The AI coding assistant landscape is consolidating around **AGENTS.md** as an emerging universal standard (announced July 2025 by OpenAI, Sourcegraph, and Google). However, most tools still maintain their own proprietary configuration formats alongside support for the emerging standard.

**Key Finding:** Use AGENTS.md as the primary configuration file and maintain tool-specific files (.claude, .github/copilot-instructions.md, etc.) for advanced features.

---

## Universal Standards

### AGENTS.md (Universal Standard - 2025)

**Status:** Emerging industry standard
**Adoption:** 20,000+ GitHub repositories (as of August 2025)
**Location:** `AGENTS.md` (repository root)
**Supported By:** OpenAI Codex, Google Jules, Cursor, Aider, RooCode, Zed, and growing

#### Purpose
- Consolidates AI agent instructions into a single vendor-neutral location
- Provides machine-readable context complementing human-facing README.md
- Replaces fragmented tool-specific configuration files

#### Key Features
- **Portable:** Works across multiple AI coding tools
- **Hierarchical:** Supports nested files for monorepo package-level instructions
- **Natural Language:** Written in Markdown with no proprietary syntax
- **Predictable:** Single standard location for all AI agents

#### Typical Content
- Setup commands and dependencies
- Testing workflows and validation
- Coding style preferences
- Pull request guidelines
- Architecture decisions
- Build and deployment processes

#### Migration Strategy
For tools not yet supporting AGENTS.md, create tool-specific files that reference it:
```markdown
<!-- CLAUDE.md -->
See ./AGENTS.md for project instructions
```

---

## Tool-Specific Configuration Standards

### 1. Claude Code

**Vendor:** Anthropic
**Configuration Hierarchy:** Global → Project → Local

#### File Structure
```
~/.claude/                          # User-level (global)
  ├── settings.json                 # Global settings
  └── agents/                       # User-defined subagents

<project>/.claude/                  # Project-level
  ├── settings.json                 # Team-shared settings (version controlled)
  ├── settings.local.json           # Personal settings (not version controlled)
  ├── agents/                       # Project-specific subagents
  └── commands/                     # Slash commands

<project>/CLAUDE.md                 # Context file (can be nested in subdirectories)
```

#### Key Configuration Files

##### CLAUDE.md
- **Purpose:** Project instructions and context loaded automatically
- **Location:** Repository root or subdirectories
- **Behavior:** Merges upward in directory tree (subdirectory files layer on parent files)
- **Format:** Markdown, natural language
- **Best Practice:** Can reference AGENTS.md for compatibility

##### .claude/settings.json
- **Scope:** Project-wide, version controlled
- **Content:**
  - Permission rules (`permissions.deny`)
  - Environment variables
  - Tool access controls
  - Custom subagent paths

##### .claude/settings.local.json
- **Scope:** Developer-specific, NOT version controlled
- **Content:** Personal preferences and experimental settings
- **Best Practice:** Add to `.gitignore`

##### .claude/agents/*.md
- **Purpose:** Custom AI subagents with specialized capabilities
- **Format:** Markdown with YAML frontmatter
- **Example Structure:**
  ```yaml
  ---
  name: test-runner
  description: Specialized agent for running and fixing tests
  ---
  # Agent instructions here
  ```

#### Configuration Access
- Interactive: `/config` command in REPL
- File-based: Edit JSON files directly

#### Key Settings
- `permissions.deny` - Block file access patterns
- Environment variables
- Custom subagent definitions
- Tool permissions

---

### 2. Cursor AI

**Vendor:** Cursor
**Primary IDE:** VS Code fork

#### File Structure (Modern - Recommended)
```
.cursor/
  ├── index.mdc                     # Main configuration (Rule Type: "Always")
  └── rules/
      ├── coding-standards.mdc
      ├── framework-specific.mdc
      └── testing.mdc
```

#### File Structure (Legacy - Still Supported)
```
.cursorrules                        # Root-level config file
```

#### File Formats

##### .cursor/rules/*.mdc (Recommended)
- **Format:** MDC (Markdown Components)
- **Purpose:** Modular, per-rule configuration
- **Scope:** Project-level
- **Best Practice:** One rule per file for organization

##### .cursorrules (Legacy)
- **Format:** Plain text / Markdown
- **Purpose:** Single-file project configuration
- **Scope:** Project-level
- **Status:** Backward compatible, not recommended for new projects

##### Global Rules
- **Location:** Cursor Settings → General → Rules for AI
- **Scope:** All projects
- **Use Case:** Coding standards and preferences applicable everywhere

#### Best Practices
- Global rules: Universal coding standards
- Project rules: Framework-specific conventions
- Keep rules concise to avoid overwhelming context
- Prefer `.cursor/rules/` structure over legacy `.cursorrules`

---

### 3. GitHub Copilot

**Vendor:** Microsoft/GitHub
**Integration:** GitHub ecosystem

#### File Structure
```
.github/
  ├── copilot-instructions.md       # Primary configuration
  └── instructions/                 # Advanced: Directory-specific configs
      ├── backend.md
      ├── frontend.md
      └── infra.md
```

#### Primary Configuration

##### .github/copilot-instructions.md
- **Purpose:** Repository-wide Copilot instructions
- **Format:** Markdown with natural language
- **Content:**
  - Build and test instructions
  - Coding standards
  - Project context
  - Validation procedures

#### Advanced Configuration

##### .github/instructions/*.md
- **Purpose:** Directory or file-specific instructions
- **Format:** Markdown with YAML frontmatter
- **Frontmatter Spec:**
  ```yaml
  ---
  applies-to:
    - path: "src/backend/**"
    - path: "*.py"
  ---
  ```
- **Behavior:** Different instructions for different codebase areas

#### IDE-Specific

##### JetBrains IDEs
- **Project File:** `.github/copilot-instructions.md`
- **Global File:** `global-copilot-instructions.md` (local storage)

#### Key Features
- Natural language instructions
- Markdown formatting for readability
- Directory-scoped configurations
- Integration with GitHub workflow

---

### 4. Aider

**Vendor:** Aider-AI (Open Source)
**Interface:** Terminal-based

#### File Structure
```
<project>/
  ├── .aider.conf.yml               # Project configuration
  ├── CONVENTIONS.md                # Coding conventions (recommended name)
  └── .env                          # API keys and environment variables
```

#### Configuration Files

##### .aider.conf.yml
- **Purpose:** Command-line defaults and settings
- **Format:** YAML
- **Location:** Repository root or home directory (`~/.aider.conf.yml`)
- **Content:**
  ```yaml
  # Example configuration
  read:
    - CONVENTIONS.md
  auto-commits: true
  model: gpt-4
  ```

##### CONVENTIONS.md
- **Purpose:** Coding standards and style guide
- **Format:** Markdown, natural language
- **Usage:** Load with `/read CONVENTIONS.md` or configure auto-load in YAML
- **Best Practice:** Define in `.aider.conf.yml` for automatic loading

##### .env
- **Purpose:** API keys and sensitive configuration
- **Format:** Environment variable key-value pairs
- **Security:** Never commit to version control

#### Configuration Methods
1. Command-line arguments
2. YAML config file (`.aider.conf.yml`)
3. Environment variables (shell or `.env`)

#### Key Settings
- Model selection
- Auto-commit behavior
- File watch patterns
- Convention file references

---

### 5. Windsurf (Codeium)

**Vendor:** Codeium
**Product:** First "agentic IDE"

#### File Structure
```
.windsurf/
  └── rules/                        # Custom rules files
      ├── always-on-rule.md
      ├── mention-rule.md
      └── glob-pattern-rule.md

~/.codeium/
  └── .codeiumignore                # Enterprise: Global ignore patterns
```

#### Configuration Files

##### .windsurf/rules/*.md
- **Purpose:** Granular AI behavior rules
- **Activation Types:**
  - Always-on rules
  - @mention-able rules
  - Requested by Cascade (AI agent)
  - Attached to file globs (pattern-based)
- **Format:** Markdown
- **Scope:** Workspace-level

##### .codeiumignore
- **Purpose:** Enterprise-wide file/folder exclusions
- **Location:** `~/.codeium/` (global)
- **Scope:** All repositories (enforced)
- **Use Case:** Security, compliance, sensitive files

#### Configuration Access
- **Quick Settings:** Bottom-right "Windsurf - Settings" button
- **Advanced Settings:** Profile dropdown → "Windsurf Settings"
- **Custom API Keys:** Bring your own Anthropic/OpenAI keys

#### Key Features
- **Model Selection:** Configure Claude, GPT, and other providers
- **Memory:** AI remembers custom rules and learned patterns
- **Cascade Settings:** Access to .gitignore, preview controls
- **Rule Flexibility:** Granular control over when rules apply

---

## Comparison Matrix

| Tool            | Primary Config File(s)                | Format        | Hierarchy | AGENTS.md Support | Version Control |
|-----------------|---------------------------------------|---------------|-----------|-------------------|-----------------|
| **AGENTS.md**   | `AGENTS.md`                          | Markdown      | Nested    | Native            | Yes             |
| **Claude Code** | `CLAUDE.md`, `.claude/settings.json` | MD + JSON     | Merging   | Via reference     | Partial*        |
| **Cursor**      | `.cursor/rules/*.mdc`                | MDC           | Flat      | Planned           | Yes             |
| **GitHub Copilot** | `.github/copilot-instructions.md` | Markdown      | Nested    | Planned           | Yes             |
| **Aider**       | `.aider.conf.yml`, `CONVENTIONS.md`  | YAML + MD     | Single    | Manual            | Yes (YAML), Recommended (MD) |
| **Windsurf**    | `.windsurf/rules/*.md`               | Markdown      | Glob-based| Planned           | Yes             |

\* `.claude/settings.json` is version controlled; `.claude/settings.local.json` is not

---

## Common Patterns Across Tools

### 1. Markdown for Human-Readable Instructions
- All tools support natural language Markdown for instructions
- No proprietary syntax required
- Easy to read and maintain

### 2. Hierarchical Configuration
- Global (user-level) settings
- Project (team-shared) settings
- Local (developer-specific) settings

### 3. Separation of Concerns
```
Instructions:    AGENTS.md, CLAUDE.md, CONVENTIONS.md
Settings:        .claude/settings.json, .aider.conf.yml
Secrets:         .env, API key prompts
Ignore Patterns: .gitignore integration, custom ignore files
```

### 4. Tool-Specific Advanced Features
- **Subagents:** Claude Code, Windsurf
- **Directory-scoped rules:** GitHub Copilot, Windsurf
- **Custom model selection:** Aider, Windsurf

---

## Recommendations for BitBot Project

### 1. Adopt AGENTS.md as Primary Standard
```markdown
# AGENTS.md
# AI Agent Instructions for BitBot

## Project Overview
BitBot is a container orchestration and devcontainer management CLI...

## Build Instructions
...

## Testing
...

## Coding Standards
...
```

### 2. Maintain Tool-Specific Files for Advanced Features

#### For Claude Code Support
```
CLAUDE.md                           # Reference to AGENTS.md + Claude-specific notes
.claude/
  ├── settings.json                 # Team permissions, env vars
  └── settings.local.json           # In .gitignore
```

#### For Cursor Users
```
.cursor/
  └── rules/
      └── bitbot-standards.mdc
```

#### For GitHub Copilot
```
.github/
  └── copilot-instructions.md       # Can reference AGENTS.md
```

### 3. Update .gitignore
```gitignore
# AI Agent Local Settings
.claude/settings.local.json
.env
.aider.env
```

### 4. Documentation Strategy
- **AGENTS.md:** Machine-readable project instructions
- **README.md:** Human-readable project introduction and quick start
- **CLAUDE.md:** Optional, references AGENTS.md with Claude-specific additions
- **Contributing guidelines:** Reference AGENTS.md for AI-assisted contributions

---

## Migration Path for Existing Projects

### Phase 1: Create AGENTS.md
1. Consolidate common instructions from tool-specific files
2. Write in natural, clear Markdown
3. Focus on: setup, testing, standards, architecture

### Phase 2: Update Tool-Specific Files
1. Keep existing files for backward compatibility
2. Add references to AGENTS.md
3. Retain only tool-specific advanced features

### Phase 3: Team Communication
1. Document in README that project uses AGENTS.md
2. Guide developers to configure their preferred tools
3. Maintain AGENTS.md as single source of truth

---

## Future Trends

### Industry Direction
- **Consolidation:** Movement toward AGENTS.md as universal standard
- **Interoperability:** Tools adding AGENTS.md support incrementally
- **Vendor Neutrality:** Resistance to tool lock-in

### Expected Timeline
- **2025 Q4:** Major tools add AGENTS.md support
- **2026:** AGENTS.md becomes de facto standard
- **2026+:** Tool-specific files become optional/advanced-only

### Watch List
- OpenAI, Sourcegraph, Google spec updates
- Claude Code AGENTS.md integration
- Cursor AGENTS.md roadmap
- Community adoption metrics

---

## References

### Official Documentation
- [Claude Code Settings](https://docs.claude.com/en/docs/claude-code/settings)
- [GitHub Copilot Instructions](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- [Aider Documentation](https://aider.chat/docs/)
- [Cursor Rules](https://docs.cursor.com/context/rules)
- [Windsurf Documentation](https://docs.windsurf.com/)

### AGENTS.md Resources
- [AGENTS.md Specification (InfoQ)](https://www.infoq.com/news/2025/08/agents-md/)
- [Builder.io AGENTS.md Guide](https://www.builder.io/blog/agents-md)
- [Complete Guide to AGENTS.md](https://www.remio.ai/post/what-is-agents-md-a-complete-guide-to-the-new-ai-coding-agent-standard-in-2025)

### Community Resources
- [Awesome Cursor Rules](https://github.com/PatrickJS/awesome-cursorrules)
- [Claude Code Settings Examples](https://github.com/feiskyer/claude-code-settings)
- [.claude Community Guide](https://dotclaude.com/)

---

## Appendix: Example Configuration Files

### Example AGENTS.md
```markdown
# AI Agent Instructions - BitBot

## Overview
BitBot is a cross-platform CLI for managing devcontainers with AI agent integration.

## Architecture
- Go-based CLI (cross-platform: Windows, macOS, Linux)
- Docker/Podman container orchestration
- MCP (Model Context Protocol) for AI integration

## Build & Test
```bash
# Build
go build -o bitbot ./cmd/bitbot

# Test
go test ./...

# Integration tests
./tests/integration.sh
```

## Coding Standards
- Language: Go 1.21+
- Style: gofmt, golangci-lint
- Testing: Table-driven tests preferred
- Documentation: Godoc comments for public APIs

## Security Guidelines
- No credentials in code
- Container isolation required
- Validate all user inputs
- Follow least-privilege principle

## Pull Request Checklist
- [ ] Tests pass
- [ ] Documentation updated
- [ ] No security vulnerabilities
- [ ] Follows project conventions
```

### Example CLAUDE.md
```markdown
# Claude Code Instructions for BitBot

See AGENTS.md for general project instructions.

## Claude-Specific Notes
- Use Go subagent for Go-related tasks
- Docker knowledge available via MCP server
- Security reviews required for container operations

## Custom Subagents
Located in `.claude/agents/` for specialized tasks.
```

### Example .claude/settings.json
```json
{
  "permissions": {
    "deny": [
      "**/.env",
      "**/credentials.json",
      "**/*.key",
      "**/*.pem"
    ]
  },
  "environment": {
    "BITBOT_ENV": "development"
  }
}
```

---

**Document Version:** 1.0
**Last Updated:** October 2025
**Maintained By:** BitBot Project Team
