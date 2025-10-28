# Template Merge System Pseudocode

**Purpose**: Merge base devcontainer config with template-specific details
**Location**: `container/templates/shared/scripts/merge-devcontainer.sh`
**Status**: Implemented

---

## Overview

BitBot templates use a two-file system to avoid duplication:
- `shared/base.devcontainer.json` - Common settings for all templates
- `{template}/details.devcontainer.json` - Template-specific settings

The merge script combines these into the final `devcontainer.json`.

---

## merge-devcontainer.sh

**Purpose**: Merge base + details → devcontainer.json

**Implementation**: `container/templates/shared/scripts/merge-devcontainer.sh`

```bash
#!/bin/bash
set -e

# Parse arguments
TEMPLATE_DIR = "${1:-.}"  # Default to current directory if not provided

# Calculate paths
SCRIPT_DIR = directory_of_this_script
SHARED_DIR = "$SCRIPT_DIR/.."  # Go up to shared/
BASE_FILE = "$SHARED_DIR/base.devcontainer.json"
DETAILS_FILE = "$TEMPLATE_DIR/details.devcontainer.json"
OUTPUT_FILE = "$TEMPLATE_DIR/devcontainer.json"

# Check for jq
IF NOT command_exists(jq):
    ERROR: "jq is required for merging devcontainer.json files"
    ERROR: "Install: apt-get install jq (or brew install jq on macOS)"
    EXIT 1

# Validate base file exists
IF NOT file_exists(BASE_FILE):
    ERROR: "Base devcontainer.json not found at: $BASE_FILE"
    EXIT 1

# Validate details file exists
IF NOT file_exists(DETAILS_FILE):
    ERROR: "Template details file not found at: $DETAILS_FILE"
    ERROR: "Create $DETAILS_FILE with template-specific configuration"
    EXIT 1

# Show what we're doing
ECHO "Merging devcontainer.json..."
ECHO "  Base:    $BASE_FILE"
ECHO "  Details: $DETAILS_FILE"
ECHO "  Output:  $OUTPUT_FILE"

# Merge strategy:
# - Deep recursive merge for objects (.[0] * .[1])
# - Arrays are REPLACED by default (not merged) to avoid duplicates
# - EXCEPTION: "mounts" array is CONCATENATED (base + details)
# - Details override base values
#
# jq merge formula:
#   1. Merge base * details (arrays replaced)
#   2. Special handling: if both have mounts, concatenate them

jq -s '
  (.[0] * .[1]) as $merged |
  # If both base and details have mounts, concatenate them
  if (.[0].mounts and .[1].mounts) then
    $merged | .mounts = (.[0].mounts + .[1].mounts)
  else
    $merged
  end
' "$BASE_FILE" "$DETAILS_FILE" > "$OUTPUT_FILE"

IF exit_code == 0:
    ECHO "✓ Successfully merged devcontainer.json"
    ECHO ""
    ECHO "Generated: $OUTPUT_FILE"
ELSE:
    ECHO "✗ Merge failed"
    EXIT 1

EXIT 0
```

### JSON Merge Behavior

**jq strategy**: `.[0] * .[1]` (recursive merge, right wins) + special mounts handling

**Example 1: Basic Merge**

```json
// base.devcontainer.json
{
  "name": "Base",
  "image": "ubuntu:22.04",
  "features": {
    "git": {}
  },
  "customizations": {
    "vscode": {
      "extensions": ["dbaeumer.vscode-eslint"]
    }
  }
}

// details.devcontainer.json
{
  "name": "Python Dev",
  "features": {
    "python": {"version": "3.11"}
  },
  "customizations": {
    "vscode": {
      "extensions": ["ms-python.python"]
    }
  }
}

// Result: devcontainer.json
{
  "name": "Python Dev",              // details wins
  "image": "ubuntu:22.04",            // from base
  "features": {
    "git": {},                        // from base
    "python": {"version": "3.11"}     // from details
  },
  "customizations": {
    "vscode": {
      "extensions": ["ms-python.python"]  // details wins (full array replace)
    }
  }
}
```

**Example 2: Mounts Concatenation (Special Case)**

```json
// base.devcontainer.json
{
  "name": "Base",
  "mounts": [
    "source=${localWorkspaceFolder}/.bitbot,target=/workspace/.bitbot,type=bind"
  ]
}

// details.devcontainer.json
{
  "name": "Python Dev",
  "mounts": [
    "source=${localWorkspaceFolder}/.venv,target=/workspace/.venv,type=bind"
  ]
}

// Result: devcontainer.json
{
  "name": "Python Dev",
  "mounts": [
    "source=${localWorkspaceFolder}/.bitbot,target=/workspace/.bitbot,type=bind",
    "source=${localWorkspaceFolder}/.venv,target=/workspace/.venv,type=bind"
  ]
  // mounts are CONCATENATED (base + details), not replaced!
}
```

**Key Points**:
- **Objects**: Merged recursively (base values preserved unless details overrides)
- **Arrays**: Replaced completely (details wins)
- **Exception**: `mounts` array is concatenated (base + details)
- **Scalars**: Details wins (strings, numbers, booleans)

---

## merge-all.sh

**Purpose**: Merge all templates in one command

**Implementation**: `container/templates/shared/scripts/merge-all.sh`

```bash
#!/bin/bash
set -e

# Calculate paths
SCRIPT_DIR = directory_of_this_script
TEMPLATES_DIR = "$SCRIPT_DIR/../.."  # Go up to templates/

ECHO "=== Merging All BitBot DevContainer Templates ==="
ECHO ""

# Templates to merge (hardcoded list)
TEMPLATES = [
    "base",
    "config",
    "workspace"
]

# Track results
FAILED = []
SUCCEEDED = []

# Process each template
FOR template IN TEMPLATES:
    TEMPLATE_DIR = "$TEMPLATES_DIR/$template"

    # Skip if directory doesn't exist
    IF NOT directory_exists(TEMPLATE_DIR):
        ECHO "⚠ Template not found: $template (skipping)"
        CONTINUE

    # Skip if no details file
    IF NOT file_exists("$TEMPLATE_DIR/details.devcontainer.json"):
        ECHO "⚠ No details.devcontainer.json in $template (skipping)"
        CONTINUE

    # Run merge
    ECHO "--- Merging: $template ---"
    "$SCRIPT_DIR/merge-devcontainer.sh" "$TEMPLATE_DIR"

    IF exit_code == 0:
        APPEND template TO SUCCEEDED
    ELSE:
        APPEND template TO FAILED

    ECHO ""

# Print summary
ECHO "=== Summary ==="
ECHO "✓ Succeeded: ${#SUCCEEDED[@]}"
FOR template IN SUCCEEDED:
    ECHO "  - $template"

IF FAILED is not empty:
    ECHO "✗ Failed: ${#FAILED[@]}"
    FOR template IN FAILED:
        ECHO "  - $template"
    EXIT 1
ELSE:
    ECHO ""
    ECHO "All templates merged successfully!"
    EXIT 0
```

---

## Template Structure

### Base Template

**File**: `container/templates/shared/base.devcontainer.json`

**Contains**:
- Common settings for all templates
- Standard features (git, curl, node)
- Base VS Code extensions
- Default environment variables
- Common mounts

**Example**:
```json
{
  "name": "BitBot Base",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/devcontainers/features/git:1": {}
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "editorconfig.editorconfig"
      ]
    }
  },
  "mounts": [
    "source=${localWorkspaceFolder}/.bitbot,target=/workspace/.bitbot,type=bind"
  ]
}
```

### Template Details

**File**: `{template}/details.devcontainer.json`

**Contains**:
- Template-specific name
- Additional features
- Template-specific extensions
- Custom mounts or settings

**Example** (Python template):
```json
{
  "name": "BitBot Python",
  "features": {
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.11"
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance"
      ]
    }
  },
  "postCreateCommand": "pip install -r requirements.txt"
}
```

---

## Usage Workflows

### Development Workflow

```bash
# 1. Edit base config
vim container/templates/shared/base.devcontainer.json

# 2. Edit template details
vim container/templates/base/details.devcontainer.json

# 3. Merge
container/templates/shared/scripts/merge-devcontainer.sh container/templates/base

# 4. Test
devcontainer build --workspace-folder .
```

### Merge All Templates

```bash
# After editing shared base
container/templates/shared/scripts/merge-all.sh

# Verify all merged correctly
git diff container/templates/*/devcontainer.json
```

### CI/CD Integration

```bash
# In GitHub Actions or pre-commit hook
container/templates/shared/scripts/merge-all.sh

IF exit_code != 0:
    ERROR: "Template merge failed"
    EXIT 1

# Check if devcontainer.json files were modified
IF git_has_changes("container/templates/*/devcontainer.json"):
    ERROR: "devcontainer.json files out of sync"
    ERROR: "Run: container/templates/shared/scripts/merge-all.sh"
    EXIT 1
```

---

## Array Merge Behavior

**Default**: jq's `*` operator replaces arrays instead of merging them.

**Example**:
```json
// Base
{
  "customizations": {
    "vscode": {
      "extensions": ["ext1", "ext2"]
    }
  }
}

// Details
{
  "customizations": {
    "vscode": {
      "extensions": ["ext3"]
    }
  }
}

// Result (arrays replaced)
{
  "customizations": {
    "vscode": {
      "extensions": ["ext3"]  // ext1, ext2 lost!
    }
  }
}
```

**Workaround for extensions**: Details files must include ALL extensions they want, not just additions.

**Exception: Mounts Array**

The `mounts` array is special-cased to concatenate instead of replace:

```bash
jq -s '
  (.[0] * .[1]) as $merged |
  if (.[0].mounts and .[1].mounts) then
    $merged | .mounts = (.[0].mounts + .[1].mounts)
  else
    $merged
  end
'
```

**Why**: Mounts need to be additive (base mounts + template-specific mounts), but extensions/other arrays should be explicit (to avoid duplicates or unintended inclusions).

**Future Enhancement**: Could add similar special-casing for other arrays if needed (e.g., features, forwardPorts).

---

## Testing

### Manual Test

```bash
# Create test files
echo '{"name":"Base","features":{"git":{}}}' > /tmp/base.json
echo '{"name":"Test","features":{"python":{}}}' > /tmp/details.json

# Merge
jq -s '.[0] * .[1]' /tmp/base.json /tmp/details.json

# Expected output:
{
  "name": "Test",
  "features": {
    "git": {},
    "python": {}
  }
}
```

### Automated Test

```bash
#!/usr/bin/env bash
# Test template merge

TEST_DIR="/tmp/template-merge-test"
mkdir -p "$TEST_DIR"

# Create base
cat > "$TEST_DIR/base.json" <<'EOF'
{
  "name": "Base",
  "image": "ubuntu:22.04",
  "features": {"git": {}}
}
EOF

# Create details
cat > "$TEST_DIR/details.json" <<'EOF'
{
  "name": "Test",
  "features": {"python": {"version": "3.11"}}
}
EOF

# Merge
RESULT=$(jq -s '.[0] * .[1]' "$TEST_DIR/base.json" "$TEST_DIR/details.json")

# Verify
echo "$RESULT" | jq -e '.name == "Test"' || echo "FAIL: name"
echo "$RESULT" | jq -e '.image == "ubuntu:22.04"' || echo "FAIL: image"
echo "$RESULT" | jq -e '.features.git' || echo "FAIL: git feature"
echo "$RESULT" | jq -e '.features.python.version == "3.11"' || echo "FAIL: python feature"

# Cleanup
rm -rf "$TEST_DIR"
```

---

## Integration with bitbot init

**When user runs** `bitbot init`:

```bash
1. Select template (or use default)
2. Copy template to workspace .devcontainer/
   - Dockerfile → .devcontainer/Dockerfile
   - devcontainer.json → .devcontainer/devcontainer.json
   - Scripts, home folders, etc.
3. User can now customize .devcontainer/ directly
4. No need to understand merge system
```

**Key Point**: Users never deal with base/details split. They get the merged `devcontainer.json` and customize it directly.

---

## Success Criteria

**Template Merge System**:
- [x] Merges base + details → devcontainer.json
- [x] Handles nested objects correctly
- [x] Works for all templates
- [x] Can merge all templates with one command
- [x] Provides clear error messages

**User Experience**:
- [x] Users never see base/details split
- [x] Users get merged devcontainer.json
- [x] Users can customize without understanding merge
- [x] Changes persist across container rebuilds

**Developer Experience**:
- [x] Easy to update common settings (edit base)
- [x] Easy to customize per-template (edit details)
- [x] Automated merge prevents sync issues
- [x] Can test merge before committing

---

## Related Files

**Implementation**:
- `container/templates/shared/scripts/merge-devcontainer.sh`
- `container/templates/shared/scripts/merge-all.sh`

**Base Config**:
- `container/templates/shared/base.devcontainer.json`

**Template Details**:
- `container/templates/base/details.devcontainer.json`
- `container/templates/config/details.devcontainer.json`
- `container/templates/bitbotdev/details.devcontainer.json`
- `container/templates/workspace/details.devcontainer.json`

**Generated Output**:
- `container/templates/{template}/devcontainer.json`
