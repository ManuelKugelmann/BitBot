# AI Helper Architecture - Early-Stage Integration

## The Challenge

AI help is needed **BEFORE** containers exist:

```
User runs bitbot.exe
    ↓
WSL Alpine setup         ← Need AI help HERE
    ↓
Docker check             ← Need AI help HERE
    ↓
Container creation       ← Need AI help HERE
    ↓
DevContainer work        ← AI help also useful here
```

## Solution: Core-Based AI Helper

### Location Strategy

```
core/util/ai-helper/
├── ai-helper.js         # Node.js helper (pure, no dependencies)
├── ai-helper.sh         # Bash wrapper (auto-detects location)
└── README.md            # Usage documentation
```

**Not** in `container/bitbot/` because:
- ❌ Containers don't exist yet during first-run
- ❌ BitBot Alpine image may not have Node.js
- ❌ Need help before any Docker operations

**In** `core/util/ai-helper/` because:
- ✅ Available on host (Windows/WSL)
- ✅ Can be called from bash scripts immediately
- ✅ No Docker required

### Runtime Environments

#### 1. WSL Alpine (First-Run Setup)

**Context**: User runs `bitbot.exe` → WSL Alpine → `first-run.sh`

**Requirements**:
- Node.js must be available in WSL Alpine
- AI helper at `$BITBOT_HOME/core/util/ai-helper/ai-helper.js`

**Installation**:
```bash
# In WSL Alpine setup (first-run.sh or prerequisites check)
if ! command -v node &>/dev/null; then
    echo "Installing Node.js for AI assistance..."
    apk add --no-cache nodejs npm
fi
```

**Usage**:
```bash
# From core/global/first-run.sh
source "$BITBOT_HOME/core/util/ai-helper/ai-helper.sh"

if ! command -v docker &>/dev/null; then
    echo "✗ Docker not found"
    ai_suggest "Docker" "Docker not installed, how to install Docker Desktop?"
fi
```

#### 2. Inside Work Containers

**Context**: User working in DevContainer

**Requirements**:
- Node.js in container (already in bitbot-work template)
- AI helper copied to `/usr/local/bitbot/util/ai-helper/`

**Installation** (during container build):
```dockerfile
# In container/templates/bitbot-*/.devcontainer/Dockerfile
COPY container/bitbot/util/ai-helper/ /usr/local/bitbot/util/ai-helper/
```

**Usage**:
```bash
# Inside container
source /usr/local/bitbot/util/ai-helper/ai-helper.sh
ask_ai "Git error" "How to fix detached HEAD?"
```

## Node.js Dependency Strategy

### Option 1: Require Node.js in Alpine (Simple)

**Pros**:
- Simple, straightforward
- Node.js is small (~50MB)
- Enables rich AI features

**Cons**:
- Adds dependency to BitBot Alpine
- Slows first-run slightly

**Implementation**:
```bash
# core/global/first-run.sh
ensure_node() {
    if ! command -v node &>/dev/null; then
        echo "Setting up AI assistance..."
        apk add --no-cache nodejs
    fi
}
```

### Option 2: Pure Bash Fallback (Complex)

**Pros**:
- No new dependencies
- Works everywhere

**Cons**:
- No AI, only static fallback
- More limited help

**Implementation**:
```bash
# ai-helper.sh checks for Node.js
ask_ai() {
    if command -v node &>/dev/null; then
        node "$BITBOT_AI_HELPER" "$@"
    else
        # Pure bash fallback
        show_static_help "$@"
    fi
}
```

### Recommendation: Option 1

Add Node.js to BitBot Alpine. It's worth the small dependency for **dramatically better** beginner experience.

## Integration Points

### 1. First-Run Prerequisites (`core/global/first-run.sh`)

```bash
source "$BITBOT_HOME/core/util/ai-helper/ai-helper.sh"

check_docker() {
    if ! command -v docker &>/dev/null; then
        echo "✗ Docker not found"
        ai_suggest "Docker" "How to install Docker Desktop on Windows?"
        return 1
    fi
}

check_wsl() {
    if ! grep -q microsoft /proc/version; then
        echo "✗ Not running in WSL"
        ai_suggest "WSL" "How to enable WSL on Windows?"
        return 1
    fi
}
```

### 2. Container Init (`core/workspace/init.sh`)

```bash
source "$BITBOT_HOME/core/util/ai-helper/ai-helper.sh"

if ! docker ps &>/dev/null; then
    echo "✗ Docker daemon not running"
    ai_suggest "Docker daemon" "Docker Desktop not running, how to start it?"
    exit 1
fi
```

### 3. Error Utilities (`core/util/error.sh`)

```bash
source "$BITBOT_HOME/core/util/ai-helper/ai-helper.sh"

error_with_help() {
    local context="$1"
    local error_msg="$2"

    echo "Error: $error_msg"
    ai_suggest "$context" "$error_msg"
    exit 1
}
```

## Data Flow

```
┌─────────────────────────────────────────────────────┐
│ User runs bitbot.exe (Windows)                      │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ WSL Alpine: core/global/first-run.sh                │
│ - Checks Docker                                     │
│ - Checks WSL                                        │
│ - Checks prerequisites                              │
└─────────────────────────────────────────────────────┘
                    ↓ (error detected)
┌─────────────────────────────────────────────────────┐
│ source core/util/ai-helper/ai-helper.sh             │
│ ask_ai "Docker" "How to install?"                   │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ ai-helper.sh → ai-helper.js                         │
│ - Check if Node.js available                        │
│ - Try free AI API (HuggingFace)                     │
│ - Fallback to curated help                          │
└─────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────┐
│ Display help to user                                │
│ "💡 AI Assistant: Download Docker Desktop from..." │
└─────────────────────────────────────────────────────┘
```

## File Structure

```
BitBot/
├── core/
│   ├── util/
│   │   └── ai-helper/
│   │       ├── ai-helper.js    # Node.js helper (core logic)
│   │       ├── ai-helper.sh    # Bash wrapper (auto-detect location)
│   │       └── README.md       # Usage docs
│   ├── global/
│   │   └── first-run.sh        # Uses ai-helper for prerequisites
│   └── workspace/
│       └── init.sh             # Uses ai-helper for setup errors
├── container/
│   ├── bitbot/
│   │   └── util/
│   │       └── ai-helper/      # Symlink or copy from core/
│   └── templates/
│       └── bitbot-*/
│           └── Dockerfile      # COPY ai-helper to container
└── sparc/
    └── 4-refinement/
        └── poc-ai-helper/      # PoC and documentation
```

## Next Steps

1. **Add Node.js to BitBot Alpine**
   - Update first-run to install Node.js
   - Document in prerequisites

2. **Integrate into all error handlers**
   - `core/global/first-run.sh`
   - `core/workspace/init.sh`
   - `core/util/error.sh`

3. **Copy to containers**
   - Add to Dockerfiles
   - Mount or copy during init

4. **Expand fallback help**
   - More topics
   - Better formatting
   - Links to docs

## Benefits of This Architecture

✅ **Works from first click** - Help available before containers
✅ **Consistent everywhere** - Same helper in host and containers
✅ **Zero user setup** - BitBot handles Node.js installation
✅ **Graceful degradation** - Falls back if Node.js unavailable
✅ **Simple integration** - Just source and call `ask_ai()`
