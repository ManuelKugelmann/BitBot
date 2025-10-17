# Workspace Template System Specification

**Feature ID**: SPEC-08
**Priority**: P2 (Nice to Have)
**Status**: Draft
**Depends On**: SPEC-01 (Container Orchestration), SPEC-05 (Cross-Platform CLI)
**Created**: 2025-10-17
**Last Updated**: 2025-10-17

---

## Executive Summary

Template system for quick workspace initialization. Provides pre-configured devcontainer setups for common stacks (Python, Node.js, Go, etc.). User-extensible template library.

**Key Design**: Built-in templates + user templates + CLI wizard = fast workspace setup.

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
├── .devcontainer/
│   ├── devcontainer.json     # VS Code config
│   └── Dockerfile            # Container image
├── .bitbot/
│   ├── config.yml            # BitBot config
│   ├── docker-compose.work.yml
│   ├── docker-compose.setup.yml
│   └── mcp/
│       └── docker-compose.yml
├── .vscode/
│   ├── settings.json
│   ├── extensions.json
│   └── launch.json
├── .gitignore
├── README.md                 # Template documentation
└── files/                    # Optional starter files
    ├── src/
    └── tests/
```

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

## 3. Built-in Templates

### 3.1 Template Library

**Python templates**:
- `python-basic`: Python 3.11 with pip
- `python-fastapi`: FastAPI web app
- `python-django`: Django web app
- `python-data-science`: Jupyter, pandas, numpy, scikit-learn

**Node.js templates**:
- `node-basic`: Node.js 20 with npm
- `node-express`: Express.js web app
- `node-react`: React frontend with Vite
- `node-nextjs`: Next.js full-stack app

**Go templates**:
- `go-basic`: Go 1.21 with go mod
- `go-web`: Go web app with Gin
- `go-cli`: Go CLI application

**Rust templates**:
- `rust-basic`: Rust with Cargo
- `rust-web`: Actix-web application

**Polyglot templates**:
- `fullstack-python-react`: Python backend + React frontend
- `microservices`: Multi-service architecture
- `monorepo`: Monorepo with multiple projects

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

### 9.1 Python FastAPI Template

**template.yml**:
```yaml
name: python-fastapi
display_name: Python FastAPI
base_image: python:3.11-slim
version: 1.0.0

prompts:
  - name: project_name
    prompt: "Project name"
    default: "my-api"

  - name: enable_postgres
    prompt: "Enable PostgreSQL?"
    type: boolean
    default: false

post_init: |
  pip install fastapi uvicorn
  mkdir -p src/{{project_name}}
  touch src/{{project_name}}/__init__.py
  cat > src/{{project_name}}/main.py <<EOF
  from fastapi import FastAPI

  app = FastAPI()

  @app.get("/")
  def read_root():
      return {"message": "Hello from {{project_name}}"}
  EOF
```

### 9.2 Node.js Express Template

**template.yml**:
```yaml
name: node-express
display_name: Node.js Express
base_image: node:20-alpine
version: 1.0.0

prompts:
  - name: project_name
    prompt: "Project name"
    default: "my-app"

  - name: use_typescript
    prompt: "Use TypeScript?"
    type: boolean
    default: true

post_init: |
  npm init -y
  npm install express
  if [ "{{use_typescript}}" = "true" ]; then
    npm install -D typescript @types/node @types/express
    npx tsc --init
  fi
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
- SPEC-09: First-Run Experience (wizard integration)

**External Resources**:
- devcontainer templates: https://containers.dev/templates
- Cookiecutter: https://cookiecutter.readthedocs.io/

**Research Sources**:
- User requirement: Quick workspace setup
- Industry best practices for project templates

---

**Status**: **Draft**
**Implementation Priority**: P2 (Nice to have)
**Next Steps**: SPEC-09 (First-Run Experience & Wizard)
