# Workspace Template System Specification

**Feature ID**: SPEC-08
**Priority**: P2 (Nice to Have)
**Status**: Complete (Fully updated with 2025 standards)
**Depends On**: SPEC-01 (Container Orchestration), SPEC-05 (Cross-Platform CLI), SPEC-06 (VS Code Integration), SPEC-07 (AI Agent Integration)
**Created**: 2025-10-17
**Last Updated**: 2025-10-20

---

## Executive Summary

Template system for quick workspace initialization. Provides pre-configured devcontainer setups for common stacks (Python, Node.js, Go, etc.). User-extensible template library with 2025 standards integration.

**Key Design**: Built-in templates + user templates + CLI wizard + AGENTS.md standard + AI agent configs + direct dev container opening = fast, modern workspace setup.

**2025 Updates**:
- ✅ AGENTS.md universal standard in all templates
- ✅ AI agent configurations (Claude Code, Continue.dev, Cline, VS Code Agent Mode)
- ✅ VS Code Direct DevContainer Opening integration 
- ✅ Modern VS Code dev container features
- ✅ MCP service configurations pre-configured

---

## 1. Architecture

### 1.1 Template Sources

**Built-in templates** (`/opt/bitbot/templates/`):
- Official BitBot templates
- Common stacks (Python, Node.js, Go, Rust, Java, etc.)
- Maintained by BitBot project

**User templates** (`~/.bitbot/templates/`):
- Personal templates
- Company/team templates
- Custom configurations

**Remote templates** (GitHub, GitLab):
- Community templates
- Shared configurations
- Template repositories

### 1.2 Template Structure

```
template-name/
├── template.yml              # Template metadata
│
├── .devcontainer/
│   ├── devcontainer.json     # VS Code config
│   └── Dockerfile            # Container image
│
├── .bitbot/
│   ├── config.yml            # BitBot config
│   ├── docker-compose.work.yml
│   ├── docker-compose.setup.yml
│   └── mcp/
│       └── docker-compose.yml
│
├── AGENTS.md                 # Universal AI agent instructions (2025 standard)
│
├── .claude/                  # Claude Code configuration
│   ├── settings.json
│   └── commands/
│
├── .continue/                # Continue.dev configuration
│   └── config.json
│
├── .cline/                   # Cline configuration
│   └── config.json
│
├── .vscode/
│   ├── settings.json
│   ├── extensions.json
│   ├── launch.json
│   └── agents.json           # VS Code Agent Mode config
│
├── .gitignore
├── .gitattributes            # Line ending enforcement
├── README.md                 # Template documentation
└── files/                    # Optional starter files
    ├── src/
    └── tests/
```

**Key additions (2025)**:
- `AGENTS.md` - Universal AI agent instructions
- `.claude/` - Claude Code settings
- `.continue/` - Continue.dev settings
- `.cline/` - Cline settings
- `.vscode/agents.json` - VS Code Agent Mode config
- `.gitattributes` - Ensures correct line endings (bash=LF, ps1=CRLF)

---

## 2. Template Metadata

### 2.1 template.yml Format

```yaml
name: python-fastapi
display_name: Python FastAPI
description: FastAPI web application with Python 3.11
version: 1.0.0
author: BitBot Team
tags:
  - python
  - web
  - api
  - fastapi

# Base image
base_image: python:3.11-slim

# Required tools
requirements:
  - python: ">=3.11"
  - pip
  - git

# Optional features
features:
  - postgresql: false
  - redis: false
  - docker-in-docker: false

# MCP services
mcp_services:
  - git-safety
  - filesystem
  - python-tools

# VS Code extensions
vscode_extensions:
  - ms-python.python
  - ms-python.vscode-pylance
  - charliermarsh.ruff
  - continue.continue         # Continue.dev (AI agent)
  - saoudrizwan.claude-dev    # Cline (AI agent)

# Wizard prompts
prompts:
  - name: project_name
    prompt: "Project name"
    default: "my-fastapi-app"

  - name: enable_postgres
    prompt: "Enable PostgreSQL?"
    type: boolean
    default: false

  - name: enable_redis
    prompt: "Enable Redis?"
    type: boolean
    default: false

# Post-init script
post_init: |
  #!/usr/bin/env bash
  echo "Installing Python dependencies..."
  pip install -r requirements.txt
  echo "✓ FastAPI template ready"
```

---

## 2.2 AI Agent Configuration (2025)

### AGENTS.md Template

**All templates include AGENTS.md** with project-specific instructions:

```markdown
# {{project_name}}

## Project Overview
{{project_description}}

## Development Setup

### Prerequisites
- {{base_image}} or compatible runtime
- Docker Desktop (for BitBot)
- VS Code with Dev Containers extension

### Quick Start
\`\`\`bash
bitbot work vscode
\`\`\`

## BitBot Integration

You are operating in a BitBot workspace.

### Mode Detection
Check current mode:
- `BITBOT_MODE=work` - Development mode (can modify code, read-only .devcontainer)
- `BITBOT_MODE=setup` - Infrastructure mode (can modify .devcontainer)

### Available MCP Tools
Query MCP services: `curl http://mcp-discovery-workspace:8080/api/services`

Common tools for this project:
- `git_status_check` - Check Git status before major changes
- `git_create_checkpoint` - Create rollback point
- `read_file`, `write_file` - Filesystem operations
{{#if enable_postgres}}
- `postgres_query` - Database operations
{{/if}}

### Git Safety Protocol
Before major changes (refactoring, implementing features):
1. Run `git_status_check`
2. If uncommitted changes exist, create checkpoint
3. Make changes
4. Inform user of rollback: `git reset --hard <hash>`

### Project-Specific Guidelines

#### Architecture
{{project_architecture_notes}}

#### Testing
Run tests: `{{test_command}}`

#### Code Style
{{code_style_preferences}}

### Restrictions
- Work mode: Cannot modify .devcontainer/ or .bitbot/setup/
- Setup mode: Cannot see .bitbot/setup/ internals

## Troubleshooting
{{troubleshooting_notes}}
```

### Tool-Specific Configurations

**Claude Code** (`.claude/settings.json`):
```json
{
  "mcpServers": {
    "git-safety": {
      "command": "docker",
      "args": ["exec", "mcp-git-safety-${WORKSPACE_HASH}", "mcp-server"]
    },
    "filesystem": {
      "command": "docker",
      "args": ["exec", "mcp-filesystem-${WORKSPACE_HASH}", "mcp-server"]
    }
    {{#if language_specific_mcp}}
    ,
    "{{language}}-tools": {
      "command": "docker",
      "args": ["exec", "mcp-{{language}}-${WORKSPACE_HASH}", "mcp-server"]
    }
    {{/if}}
  },
  "permissions": {
    "deny": [".bitbot/setup/**", ".devcontainer/**"]
  },
  "context": {
    "bitbotMode": "${BITBOT_MODE}",
    "workspaceHash": "${WORKSPACE_HASH}"
  }
}
```

**Continue.dev** (`.continue/config.json`):
```json
{
  "models": [{
    "title": "Claude 3.5 Sonnet",
    "provider": "anthropic",
    "model": "claude-3-5-sonnet-20241022"
  }],
  "contextProviders": [{
    "name": "agents-md",
    "params": {"file": "AGENTS.md"}
  }],
  "mcpServers": [...]
}
```

**Cline** (`.cline/config.json`):
```json
{
  "contextFiles": ["AGENTS.md"],
  "autoCheckGit": true,
  "suggestCheckpoint": true
}
```

---

## 3. Built-in Templates

### 3.1 Template Library

**All templates include 2025 standards**:
- ✅ AGENTS.md with project-specific instructions
- ✅ AI agent configurations (Claude Code, Continue.dev, Cline)
- ✅ VS Code Direct DevContainer Opening support 
- ✅ MCP service pre-configuration
- ✅ Line ending enforcement (.gitattributes)
- ✅ VS Code Agent Mode integration

---

**Python templates**:
- `python-basic`: Python 3.11 with pip + pytest
  - MCP: git-safety, filesystem, python-tools
  - Extensions: Python, Pylance, Continue.dev, Cline
  - AGENTS.md: Python best practices, testing guidelines

- `python-fastapi`: FastAPI web app + PostgreSQL option
  - MCP: git-safety, filesystem, python-tools, postgres-tools
  - Extensions: Python, Pylance, Thunder Client, Continue.dev, Cline
  - AGENTS.md: FastAPI patterns, async/await, DB migrations

- `python-django`: Django web app + admin panel
  - MCP: git-safety, filesystem, python-tools, postgres-tools
  - Extensions: Python, Pylance, Django extension, Continue.dev, Cline
  - AGENTS.md: Django ORM, migrations, admin customization

- `python-data-science`: Jupyter + pandas + numpy + scikit-learn
  - MCP: git-safety, filesystem, python-tools
  - Extensions: Python, Jupyter, Pylance, Continue.dev, Cline
  - AGENTS.md: Notebook best practices, data exploration patterns

**Node.js templates**:
- `node-basic`: Node.js 20 LTS + npm/pnpm
  - MCP: git-safety, filesystem, node-tools
  - Extensions: ESLint, Prettier, Continue.dev, Cline
  - AGENTS.md: Node.js async patterns, error handling

- `node-express`: Express.js web app + TypeScript
  - MCP: git-safety, filesystem, node-tools, postgres-tools
  - Extensions: ESLint, Prettier, Thunder Client, Continue.dev, Cline
  - AGENTS.md: Express routing, middleware patterns, authentication

- `node-react`: React 18 + Vite + TypeScript
  - MCP: git-safety, filesystem, node-tools
  - Extensions: ESLint, Prettier, ES7+ snippets, Continue.dev, Cline
  - AGENTS.md: React hooks, component patterns, state management

- `node-nextjs`: Next.js 14 + App Router
  - MCP: git-safety, filesystem, node-tools, postgres-tools
  - Extensions: ESLint, Prettier, Tailwind CSS, Continue.dev, Cline
  - AGENTS.md: Server components, routing, SSR/SSG patterns

**Go templates**:
- `go-basic`: Go 1.21 + go mod + testing
  - MCP: git-safety, filesystem, go-tools
  - Extensions: Go, Continue.dev, Cline
  - AGENTS.md: Go idioms, error handling, goroutines

- `go-web`: Go web app + Gin framework
  - MCP: git-safety, filesystem, go-tools, postgres-tools
  - Extensions: Go, Thunder Client, Continue.dev, Cline
  - AGENTS.md: Gin routing, middleware, structured logging

- `go-cli`: Go CLI application + Cobra
  - MCP: git-safety, filesystem, go-tools
  - Extensions: Go, Continue.dev, Cline
  - AGENTS.md: CLI design, flag parsing, user experience

**Rust templates**:
- `rust-basic`: Rust stable + Cargo + clippy
  - MCP: git-safety, filesystem, rust-tools
  - Extensions: rust-analyzer, Continue.dev, Cline
  - AGENTS.md: Rust ownership, borrowing, error handling

- `rust-web`: Actix-web + async runtime
  - MCP: git-safety, filesystem, rust-tools, postgres-tools
  - Extensions: rust-analyzer, Thunder Client, Continue.dev, Cline
  - AGENTS.md: Actix patterns, async handlers, middleware

**Polyglot templates**:
- `fullstack-python-react`: Python FastAPI backend + React frontend
  - MCP: git-safety, filesystem, python-tools, node-tools, postgres-tools
  - Extensions: Python, ESLint, Prettier, Continue.dev, Cline
  - AGENTS.md: API design, CORS, authentication, deployment

- `microservices`: Multi-service architecture + Docker Compose
  - MCP: git-safety, filesystem, docker-tools, multiple language tools
  - Extensions: Docker, YAML, Continue.dev, Cline
  - AGENTS.md: Service boundaries, communication patterns, deployment

- `monorepo`: Turborepo/Nx monorepo structure
  - MCP: git-safety, filesystem, node-tools, multiple language tools
  - Extensions: ESLint, Prettier, Monorepo tools, Continue.dev, Cline
  - AGENTS.md: Package dependencies, build caching, versioning

### 3.2 Template Variants

**Example variants**:
```
python-fastapi
├── minimal       # Bare bones
├── standard      # FastAPI + PostgreSQL
├── full          # + Redis + Celery + Docker Compose
└── production    # + monitoring, logging, security
```

---

## 4. CLI Integration

### 4.1 Template Commands

**List templates**:
```bash
bitbot template list

# Output:
# Built-in Templates:
#   python-fastapi      Python FastAPI web app
#   node-express        Express.js web app
#   go-web              Go web app with Gin
#
# User Templates:
#   my-company-stack    Company standard stack
```

**Show template details**:
```bash
bitbot template show python-fastapi

# Output:
# Name: Python FastAPI
# Description: FastAPI web application with Python 3.11
# Version: 1.0.0
# Tags: python, web, api
# Features: PostgreSQL, Redis (optional)
```

**Initialize from template**:
```bash
bitbot init --template python-fastapi

# Interactive wizard:
# Project name: my-api
# Enable PostgreSQL? (y/N): y
# Enable Redis? (y/N): n
#
# ✓ Initialized Python FastAPI workspace
# Run: bitbot work
```

**Non-interactive init**:
```bash
bitbot init --template python-fastapi \
  --project-name my-api \
  --enable-postgres yes \
  --enable-redis no
```

### 4.2 Template Management

**Install template**:
```bash
# From GitHub
bitbot template install https://github.com/user/bitbot-template-xyz

# From local path
bitbot template install ./my-template

# Template installed to ~/.bitbot/templates/xyz
```

**Create template**:
```bash
# Create from current workspace
bitbot template create my-template

# Creates template from current .devcontainer and .bitbot
# Prompts for metadata
# Saves to ~/.bitbot/templates/my-template
```

**Remove template**:
```bash
bitbot template remove my-template

# Built-in templates cannot be removed
```

---

## 5. Initialization Wizard

### 5.1 Interactive Flow

```bash
$ bitbot init

Welcome to BitBot!

? Select a template: (Use arrow keys)
▸ python-fastapi      FastAPI web application
  node-express        Express.js web server
  go-web              Go web app with Gin
  rust-basic          Rust with Cargo
  Browse all...
  Custom (manual setup)

? Project name: my-api

? Enable PostgreSQL? (Y/n): y

? Enable Redis? (y/N): n

Initializing workspace...
✓ Created .devcontainer/
✓ Created .bitbot/ structure
✓ Installed dependencies
✓ Configured MCP services

Workspace ready!
Run: bitbot work
```

### 5.2 Wizard Steps

**Step 1: Template selection**:
- Show template list
- Filter by tags
- Search by name
- Preview template details

**Step 2: Configuration**:
- Project name
- Optional features
- Custom prompts (from template.yml)

**Step 3: Initialization**:
- Copy template files
- Replace variables ({{project_name}}, etc.)
- Run post-init script
- Initialize git repo

**Step 4: Completion**:
- Show next steps
- Suggest commands to run

---

## 6. Template Variables

### 6.1 Variable Substitution

**Available variables**:
- `{{project_name}}`: User-provided project name
- `{{workspace_path}}`: Absolute workspace path
- `{{workspace_hash}}`: Calculated workspace hash
- `{{author_name}}`: From git config user.name
- `{{author_email}}`: From git config user.email
- `{{year}}`: Current year
- Custom variables from wizard prompts

**Example usage in Dockerfile**:
```dockerfile
FROM python:3.11-slim

WORKDIR /workspace

# Install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Set project metadata
LABEL project="{{project_name}}"
LABEL author="{{author_name}} <{{author_email}}>"

CMD ["uvicorn", "{{project_name}}.main:app", "--reload"]
```

**Example in devcontainer.json**:
```json
{
  "name": "{{project_name}} (BitBot)",
  "dockerComposeFile": "../.bitbot/docker-compose.work.yml",
  "workspaceFolder": "/workspace",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python"
      ]
    }
  }
}
```

---

## 7. Template Repository

### 7.1 Remote Template Sources

**GitHub template repo**:
```
https://github.com/bitbot-dev/templates
├── python-fastapi/
├── node-express/
├── go-web/
└── README.md
```

**Install from repo**:
```bash
# Install specific template
bitbot template install https://github.com/bitbot-dev/templates/python-fastapi

# Install all templates from repo
bitbot template install https://github.com/bitbot-dev/templates --all
```

**Template index** (`templates.yml`):
```yaml
templates:
  - name: python-fastapi
    path: python-fastapi/
    version: 1.0.0
    description: FastAPI web application

  - name: node-express
    path: node-express/
    version: 1.0.0
    description: Express.js web server
```

### 7.2 Template Versioning

**Version specification**:
```bash
# Install latest
bitbot template install python-fastapi

# Install specific version
bitbot template install python-fastapi@1.0.0

# Update to latest
bitbot template update python-fastapi
```

---

## 8. Template Customization

### 8.1 Template Hooks

**Hooks** (in template.yml):
```yaml
hooks:
  pre_init:
    - name: validate_environment
      script: |
        #!/usr/bin/env bash
        if ! command -v docker &> /dev/null; then
          echo "Error: Docker not installed"
          exit 1
        fi

  post_init:
    - name: install_dependencies
      script: |
        #!/usr/bin/env bash
        pip install -r requirements.txt

    - name: create_env_file
      script: |
        #!/usr/bin/env bash
        cat > .env <<EOF
        PROJECT_NAME={{project_name}}
        DATABASE_URL={{database_url}}
        EOF

  post_first_start:
    - name: run_migrations
      script: |
        #!/usr/bin/env bash
        alembic upgrade head
```

### 8.2 Conditional Files

**File inclusion based on features**:
```yaml
# In template.yml
conditional_files:
  - path: docker-compose.postgres.yml
    condition: enable_postgres == true

  - path: docker-compose.redis.yml
    condition: enable_redis == true

  - path: src/auth/
    condition: enable_auth == true
```

---

## 9. Template Examples

### 9.1 Python FastAPI Template (2025)

**Complete template structure**:
```
python-fastapi/
├── template.yml
├── .devcontainer/
│   ├── devcontainer.json
│   └── Dockerfile
├── .bitbot/
│   ├── config.yml
│   └── mcp/
│       └── docker-compose.yml
├── AGENTS.md
├── .claude/
│   ├── settings.json
│   └── commands/
│       └── run-tests.md
├── .continue/
│   └── config.json
├── .cline/
│   └── config.json
├── .vscode/
│   ├── settings.json
│   ├── extensions.json
│   └── agents.json
├── .gitignore
├── .gitattributes
└── files/
    ├── requirements.txt
    ├── pyproject.toml
    └── src/
```

**template.yml**:
```yaml
name: python-fastapi
display_name: Python FastAPI Web Application
description: FastAPI web application with Python 3.11, PostgreSQL support, and AI agent integration
base_image: python:3.11-slim
version: 2.0.0
author: BitBot Team
tags:
  - python
  - web
  - api
  - fastapi

requirements:
  - python: ">=3.11"
  - pip
  - git

features:
  - postgresql: false
  - redis: false
  - docker-in-docker: false

mcp_services:
  - git-safety
  - filesystem
  - python-tools
  - postgres-tools  # Conditional on enable_postgres

vscode_extensions:
  - ms-python.python
  - ms-python.vscode-pylance
  - charliermarsh.ruff
  - continue.continue
  - saoudrizwan.claude-dev
  - rangav.vscode-thunder-client

prompts:
  - name: project_name
    prompt: "Project name"
    default: "my-fastapi-app"
    validation: "^[a-z][a-z0-9_-]*$"

  - name: enable_postgres
    prompt: "Enable PostgreSQL database?"
    type: boolean
    default: false

  - name: enable_redis
    prompt: "Enable Redis caching?"
    type: boolean
    default: false

  - name: author_name
    prompt: "Author name"
    default: "{{git_user_name}}"

post_init: |
  #!/usr/bin/env bash
  set -e

  echo "Installing Python dependencies..."
  pip install fastapi uvicorn pytest pytest-asyncio httpx

  {{#if enable_postgres}}
  pip install sqlalchemy asyncpg alembic
  {{/if}}

  {{#if enable_redis}}
  pip install redis aioredis
  {{/if}}

  echo "Creating project structure..."
  mkdir -p src/{{project_name}}
  touch src/{{project_name}}/__init__.py

  cat > src/{{project_name}}/main.py <<EOF
  from fastapi import FastAPI

  app = FastAPI(title="{{project_name}}")

  @app.get("/")
  async def read_root():
      return {"message": "Hello from {{project_name}}"}

  @app.get("/health")
  async def health_check():
      return {"status": "healthy"}
  EOF

  echo "Creating tests..."
  mkdir -p tests
  cat > tests/test_main.py <<EOF
  from fastapi.testclient import TestClient
  from {{project_name}}.main import app

  client = TestClient(app)

  def test_read_root():
      response = client.get("/")
      assert response.status_code == 200
      assert "message" in response.json()
  EOF

  echo "✓ Python FastAPI template ready!"
  echo "Run: bitbot work vscode"

conditional_files:
  - path: files/docker-compose.postgres.yml
    condition: enable_postgres == true

  - path: files/docker-compose.redis.yml
    condition: enable_redis == true

  - path: files/src/{{project_name}}/database.py
    condition: enable_postgres == true
```

**AGENTS.md** (excerpt):
```markdown
# {{project_name}}

## Project Overview
FastAPI web application with Python 3.11{{#if enable_postgres}} and PostgreSQL{{/if}}.

## Development Setup

### Quick Start
\`\`\`bash
bitbot work vscode
\`\`\`

## BitBot Integration

You are operating in a BitBot workspace.

### Mode Detection
Check: `echo $BITBOT_MODE`
- `work` - Development mode (can modify code, read-only .devcontainer)
- `setup` - Infrastructure mode (can modify .devcontainer)

### Available MCP Tools
- `git_status_check` - Check Git status before major changes
- `git_create_checkpoint` - Create rollback point
- `read_file`, `write_file` - Filesystem operations
- `python_run_tests` - Run pytest
{{#if enable_postgres}}
- `postgres_query` - Database operations
- `postgres_migrations` - Alembic migrations
{{/if}}

### Git Safety Protocol
Before major changes:
1. Run `git_status_check`
2. If uncommitted changes, create checkpoint
3. Make changes
4. Inform user: "Rollback: git reset --hard <hash>"

### Project Guidelines

#### Architecture
- FastAPI async/await patterns
- Pydantic models for validation
- Dependency injection for services
{{#if enable_postgres}}
- SQLAlchemy 2.0 async ORM
- Alembic for migrations
{{/if}}

#### Testing
Run tests: `pytest tests/ -v`
Coverage: `pytest --cov={{project_name}} tests/`

#### Code Style
- Format: `ruff format .`
- Lint: `ruff check .`
- Type check: `mypy src/`

### Restrictions
- Work mode: Cannot modify .devcontainer/ or .bitbot/setup/
```

**.claude/settings.json**:
```json
{
  "mcpServers": {
    "git-safety": {
      "command": "docker",
      "args": ["exec", "mcp-git-safety-${WORKSPACE_HASH}", "mcp-server"]
    },
    "filesystem": {
      "command": "docker",
      "args": ["exec", "mcp-filesystem-${WORKSPACE_HASH}", "mcp-server"]
    },
    "python-tools": {
      "command": "docker",
      "args": ["exec", "mcp-python-${WORKSPACE_HASH}", "mcp-server"]
    }
  },
  "tools": [
    {
      "name": "run-tests",
      "description": "Run pytest with coverage",
      "command": "pytest tests/ -v --cov={{project_name}}",
      "autoApprove": false
    }
  ],
  "permissions": {
    "deny": [".bitbot/setup/**", ".devcontainer/**"]
  },
  "context": {
    "bitbotMode": "${BITBOT_MODE}",
    "workspaceHash": "${WORKSPACE_HASH}",
    "projectName": "{{project_name}}"
  }
}
```

**.gitattributes**:
```
# Ensure bash scripts have LF endings
*.sh text eol=lf
*.bash text eol=lf

# Ensure PowerShell scripts have CRLF
*.ps1 text eol=crlf

# Python files use LF
*.py text eol=lf

# Claude tools always LF
.claude/tools/** text eol=lf
```

---

### 9.2 Node.js Express Template (2025)

**template.yml**:
```yaml
name: node-express
display_name: Node.js Express Web Server
description: Express.js web application with TypeScript, PostgreSQL support, and AI agents
base_image: node:20-alpine
version: 2.0.0
author: BitBot Team
tags:
  - nodejs
  - web
  - api
  - express
  - typescript

requirements:
  - node: ">=20"
  - npm

features:
  - typescript: true
  - postgresql: false
  - redis: false

mcp_services:
  - git-safety
  - filesystem
  - node-tools
  - postgres-tools  # Conditional

vscode_extensions:
  - dbaeumer.vscode-eslint
  - esbenp.prettier-vscode
  - continue.continue
  - saoudrizwan.claude-dev
  - rangav.vscode-thunder-client

prompts:
  - name: project_name
    prompt: "Project name"
    default: "my-express-app"
    validation: "^[a-z][a-z0-9_-]*$"

  - name: use_typescript
    prompt: "Use TypeScript?"
    type: boolean
    default: true

  - name: enable_postgres
    prompt: "Enable PostgreSQL?"
    type: boolean
    default: false

post_init: |
  #!/usr/bin/env bash
  set -e

  echo "Initializing Node.js project..."
  npm init -y

  echo "Installing dependencies..."
  npm install express dotenv
  npm install -D nodemon

  {{#if use_typescript}}
  echo "Setting up TypeScript..."
  npm install -D typescript @types/node @types/express
  npm install -D ts-node
  npx tsc --init --rootDir src --outDir dist --esModuleInterop
  {{/if}}

  {{#if enable_postgres}}
  npm install pg
  {{#if use_typescript}}
  npm install -D @types/pg
  {{/if}}
  {{/if}}

  echo "Creating project structure..."
  mkdir -p src

  {{#if use_typescript}}
  cat > src/index.ts <<EOF
  import express, { Request, Response } from 'express';

  const app = express();
  const port = process.env.PORT || 3000;

  app.use(express.json());

  app.get('/', (req: Request, res: Response) => {
    res.json({ message: 'Hello from {{project_name}}' });
  });

  app.listen(port, () => {
    console.log(\`Server running on http://localhost:\${port}\`);
  });
  EOF
  {{else}}
  cat > src/index.js <<EOF
  const express = require('express');

  const app = express();
  const port = process.env.PORT || 3000;

  app.use(express.json());

  app.get('/', (req, res) => {
    res.json({ message: 'Hello from {{project_name}}' });
  });

  app.listen(port, () => {
    console.log(\`Server running on http://localhost:\${port}\`);
  });
  EOF
  {{/if}}

  echo "✓ Node.js Express template ready!"
  echo "Run: bitbot work vscode"
```

**AGENTS.md** (excerpt):
```markdown
# {{project_name}}

## Project Overview
Express.js web application{{#if use_typescript}} with TypeScript{{/if}}.

### Tech Stack
- Node.js 20 LTS
- Express.js{{#if use_typescript}}
- TypeScript{{/if}}{{#if enable_postgres}}
- PostgreSQL{{/if}}

## Development Setup

### Quick Start
\`\`\`bash
bitbot work vscode
\`\`\`

### Project Guidelines

#### Architecture
- RESTful API design
- Express middleware patterns
- Layered architecture (routes → controllers → services)
{{#if use_typescript}}
- TypeScript strict mode
- Interface-driven development
{{/if}}

#### Testing
Run tests: `npm test`
Watch mode: `npm run test:watch`

#### Code Style
{{#if use_typescript}}
- Format: `prettier --write src/`
- Lint: `eslint src/ --ext .ts`
- Type check: `tsc --noEmit`
{{else}}
- Format: `prettier --write src/`
- Lint: `eslint src/`
{{/if}}

### Available MCP Tools
- `git_status_check`, `git_create_checkpoint`
- `read_file`, `write_file`
- `node_run_tests`, `node_lint`
{{#if enable_postgres}}
- `postgres_query`
{{/if}}
```

---

## 10. Testing Strategy

### 10.1 Template Tests

- TM-01: List built-in templates
- TM-02: Show template details
- TM-03: Initialize workspace from template
- TM-04: Variable substitution works
- TM-05: Post-init scripts execute
- TM-06: Conditional files included correctly

### 10.2 Wizard Tests

- WZ-01: Interactive wizard completes
- WZ-02: Non-interactive init works
- WZ-03: Invalid inputs handled gracefully
- WZ-04: Template prompts displayed correctly

---

## 11. Success Criteria

**Functional**:
- [ ] List templates command works
- [ ] Init from template creates workspace
- [ ] Variable substitution accurate
- [ ] Post-init hooks execute
- [ ] Wizard provides good UX
- [ ] User templates can be added

**Usability**:
- [ ] Template discovery easy
- [ ] Wizard intuitive
- [ ] Templates well-documented
- [ ] Fast initialization (<30s)

**Extensibility**:
- [ ] Users can create templates
- [ ] Templates can be shared
- [ ] Remote templates installable
- [ ] Template versioning works

---

## 12. Implementation Phases

**Phase 1: Core System**:
- Template directory structure
- Template loading and parsing
- Variable substitution
- Basic init command

**Phase 2: Built-in Templates**:
- Python templates (basic, FastAPI, Django)
- Node.js templates (Express, React)
- Go and Rust templates
- Template documentation

**Phase 3: Wizard**:
- Interactive prompt system
- Template selection UI
- Configuration prompts
- Progress indicators

**Phase 4: Advanced Features**:
- Remote template installation
- Template creation from workspace
- Template versioning
- Conditional files and hooks

---

## 13. References

**Related Specifications**:
- SPEC-01: Container Orchestration (devcontainer creation)
- SPEC-05: Cross-Platform CLI (template commands)
- SPEC-06: VS Code Integration (VS Code Direct DevContainer Opening - Decision Direct DevContainer Opening)
- SPEC-07: AI Agent Integration (AGENTS.md, Claude Code, Continue.dev, Cline)
- SPEC-09: First-Run Experience (wizard integration)

**Key Decisions**:
- VS Code Direct DevContainer Opening (used in template launch commands)

**External Resources**:
- devcontainer templates: https://containers.dev/templates
- Cookiecutter: https://cookiecutter.readthedocs.io/
- AGENTS.md standard: https://github.com/anthropics/anthropic-cookbook/blob/main/patterns/agents_md.md
- Claude Code docs: https://docs.claude.com/claude-code
- Continue.dev docs: https://continue.dev/docs
- Cline docs: https://github.com/cline/cline

**Research Sources**:
- User requirement: Quick workspace setup
- Industry best practices for project templates
- 2025 AI agent configuration standards

---

**Status**: **Draft**
**Implementation Priority**: P2 (Nice to have)
**Next Steps**: SPEC-09 (First-Run Experience & Wizard)
