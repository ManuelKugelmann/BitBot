# AI Helper - Zero-Setup AI Assistance

Provides intelligent help for absolute beginners with **zero configuration required**.

## Quick Start

```bash
# Source the helper
source "$BITBOT_HOME/core/util/ai-helper/ai-helper.sh"

# Ask for help
ask_ai "Docker error" "How to install Docker on Windows?"

# Show suggestions in error handlers
ai_suggest "Docker" "Docker not installed, how to fix?"
```

## How It Works

1. **Tries free AI APIs** (HuggingFace Inference - no auth required)
2. **Falls back to curated help** (static, high-quality answers)
3. **Always shows something useful** (never fails silently)

## Files

- `ai-helper.js` - Node.js helper (tries AI, provides fallbacks)
- `ai-helper.sh` - Bash wrapper (easy integration)
- `README.md` - This file

## Requirements

**Required:**
- Bash (always available)

**Optional (for AI features):**
- Node.js (enables AI, otherwise uses fallback help)
- Internet connection (for API calls, works offline with fallbacks)

## Usage Examples

### Basic Help Request

```bash
source "$BITBOT_HOME/core/util/ai-helper/ai-helper.sh"

answer=$(ask_ai "WSL setup" "How do I enable WSL on Windows?")
echo "$answer"
```

### Error Handler Integration

```bash
source "$BITBOT_HOME/core/util/ai-helper/ai-helper.sh"

if ! command -v docker &>/dev/null; then
    echo "✗ Docker not found"
    echo ""
    echo "💡 AI Assistant:"
    ask_ai "Docker installation" "How to install Docker Desktop on Windows for beginners?"
    echo ""

    read -p "Continue anyway? [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]] || exit 1
fi
```

### Quick Suggestions

```bash
source "$BITBOT_HOME/core/util/ai-helper/ai-helper.sh"

# Show AI-powered suggestion for any error
if ! docker ps &>/dev/null; then
    ai_suggest "Docker daemon" "Docker daemon not running, how to start?"
fi
```

## Curated Fallback Topics

When AI APIs are rate-limited, curated help is available for:

- **docker** - Docker installation and setup
- **wsl** - WSL enablement and configuration
- **git** - Git installation
- **devcontainer** - DevContainer setup

Add more topics by editing `ai-helper.js` → `getFallbackHelp()`.

## Direct Node.js Usage

```bash
# Call directly (no bash wrapper)
node "$BITBOT_HOME/core/util/ai-helper/ai-helper.js" \
    "context" \
    "question"

# Example
node "$BITBOT_HOME/core/util/ai-helper/ai-helper.js" \
    "Docker error" \
    "How to install Docker Desktop?"
```

## Integration in BitBot Scripts

### First-Run Prerequisites (`core/global/first-run.sh`)

```bash
source "$BITBOT_HOME/core/util/ai-helper/ai-helper.sh"

check_prerequisites() {
    local errors=0

    if ! command -v docker &>/dev/null; then
        echo "✗ Docker not found"
        ai_suggest "Docker" "How to install Docker Desktop on Windows?"
        ((errors++))
    fi

    if ! grep -q microsoft /proc/version 2>/dev/null; then
        echo "✗ Not running in WSL"
        ai_suggest "WSL" "How to enable WSL on Windows?"
        ((errors++))
    fi

    return $errors
}
```

### Workspace Init (`core/workspace/init.sh`)

```bash
source "$BITBOT_HOME/core/util/ai-helper/ai-helper.sh"

if ! docker info &>/dev/null; then
    echo "✗ Docker daemon not running"
    ai_suggest "Docker daemon" "Docker Desktop is not running, how to start it?"
    exit 1
fi
```

### Error Utilities (`core/util/error.sh`)

```bash
source "$BITBOT_HOME/core/util/ai-helper/ai-helper.sh"

# Enhanced error function with AI help
error_with_ai_help() {
    local context="$1"
    local message="$2"

    echo "Error: $message" >&2
    echo "" >&2
    echo "💡 AI Assistant:" >&2
    ask_ai "$context" "$message" >&2
    echo "" >&2

    exit 1
}

# Usage
if [ ! -f "devcontainer.json" ]; then
    error_with_ai_help "DevContainer" "devcontainer.json not found, how to create it?"
fi
```

## Testing

Run the demo:

```bash
./sparc/4-refinement/poc-ai-helper/demo-integration.sh
```

Test components individually:

```bash
# Test Node.js helper
node core/util/ai-helper/ai-helper.js "Docker" "How to install?"

# Test bash wrapper
export BITBOT_HOME="/path/to/BitBot"
source core/util/ai-helper/ai-helper.sh
ask_ai "WSL" "How to enable?"
```

## Architecture

See `sparc/4-refinement/poc-ai-helper/ARCHITECTURE.md` for:
- Location strategy (core vs container)
- Runtime environments
- Node.js dependency handling
- Integration points
- Data flow

## Benefits

✅ **Zero setup** - Works immediately, no API keys
✅ **Beginner-friendly** - Clear, simple answers
✅ **Always works** - Fallback to curated help
✅ **Privacy-respecting** - No tracking, no accounts
✅ **Offline capable** - Fallback works without internet
✅ **Free forever** - No API costs

## Maintenance

### Adding New Fallback Topics

Edit `ai-helper.js` → `getFallbackHelp()`:

```javascript
const fallbacks = {
    'your-topic': `Your Help Text:

    Step 1: Do this
    Step 2: Do that
    Step 3: Verify it worked`,

    // ... existing topics ...
};
```

### Updating AI Models

Edit `ai-helper.js` → `FREE_MODELS`:

```javascript
const FREE_MODELS = [
  'meta-llama/Llama-3.2-3B-Instruct',
  'your-preferred-model',
  // Add more models for fallback rotation
];
```

## Future Enhancements

- [ ] Add Ollama support (if installed locally)
- [ ] Support user API keys (optional, advanced users)
- [ ] Expand fallback help library
- [ ] Add interactive wizards for complex setups
- [ ] Telemetry (opt-in) to improve fallback topics

## License

Part of BitBot, same license as BitBot project.
