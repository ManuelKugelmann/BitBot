# AI Helper for Absolute Beginners - PoC

**Goal**: Provide intelligent help in BitBot for users who just run `bitbot.exe` with **zero setup**.

## The Problem

Absolute beginners need help but:
- ❌ Don't want to sign up for API keys
- ❌ Don't want to install additional software
- ❌ Don't know what Docker, WSL, or DevContainers are
- ❌ Get stuck on first error and give up

## The Solution

**Multi-tier AI assistance** that works immediately:

1. **Try free AI APIs** (HuggingFace, rate-limited but functional)
2. **Fallback to curated help** (static but high-quality)
3. **Always show something useful** (never fails silently)

## Architecture

```
bitbot.exe (Windows)
    ↓
bash scripts (core/*)
    ↓
container/bitbot/util/ai-helper.sh (bash wrapper)
    ↓
container/bitbot/util/ai-helper.js (Node.js helper)
    ↓
┌─────────────────────────────┐
│ Try HuggingFace Free API    │ ← Rate limited but works
│ (no auth required)          │
└─────────────────────────────┘
         ↓ (if rate-limited)
┌─────────────────────────────┐
│ Curated Fallback Help       │ ← Always works
│ (static, high-quality)      │
└─────────────────────────────┘
```

## Files

| File | Purpose |
|------|---------|
| `container/bitbot/util/ai-helper.js` | Node.js AI helper (tries APIs, falls back) |
| `container/bitbot/util/ai-helper.sh` | Bash wrapper for scripts |
| `demo-integration.sh` | Demo showing integration |

## Usage

### From Bash Scripts

```bash
# Source the helper
source /usr/local/bitbot/util/ai-helper.sh

# Ask for help
ask_ai "Docker error" "How to install Docker on Windows?"

# Show suggestions in error handlers
if ! command -v docker &>/dev/null; then
    echo "✗ Docker not found"
    ai_suggest "Docker" "How to install Docker Desktop?"
fi
```

### Direct Node.js Call

```bash
node /usr/local/bitbot/util/ai-helper.js "context" "question"
```

## Integration Example

### Before (no AI help):

```bash
if ! command -v docker &>/dev/null; then
    echo "Error: Docker not found"
    echo "Please install Docker Desktop"
    exit 1
fi
```

### After (AI-powered help):

```bash
if ! command -v docker &>/dev/null; then
    echo "✗ Docker not found"
    echo ""
    echo "💡 AI Assistant:"
    ask_ai "Docker installation" "How to install Docker Desktop on Windows for beginners?"
    echo ""
    echo "Continue anyway? [y/N]"
    # ... interactive prompt ...
fi
```

## User Experience

When a beginner runs `bitbot.exe`:

```
C:\> bitbot.exe

Checking prerequisites...
✗ Docker not found

💡 AI Assistant:
Docker Help:

    Windows/WSL:
    1. Download Docker Desktop: https://docker.com/products/docker-desktop
    2. Install and enable WSL integration
    3. Restart and verify: docker --version

Continue anyway? [y/N]: _
```

## Free AI Backends

### Current: HuggingFace Inference API
- ✅ No signup required
- ✅ No API keys
- ⚠️ Rate limited (~300 requests/hour)
- ✅ Falls back gracefully

### Future Options
- **Ollama** (if user installs locally)
- **OpenRouter** (if user provides API key)
- **Google Gemini** (if user provides API key)

## Fallback Topics

Curated help available for:
- Docker installation
- WSL setup
- Git installation
- DevContainer setup
- General troubleshooting

## Dependencies

**Required:**
- Node.js (included in BitBot containers)
- Bash (always available)

**Optional:**
- Internet connection (for AI APIs)
- Works offline (fallback help)

## Next Steps

1. **Add Node.js to container templates**
   - Already in `bitbot-work`
   - Add to `bitbot-base`, `bitbot-config`

2. **Integrate into error handlers**
   - `core/global/first-run.sh` - Prerequisites check
   - `core/workspace/init.sh` - DevContainer setup
   - All error messages in `core/util/`

3. **Expand fallback help**
   - More topics
   - More detailed guidance
   - Links to docs

4. **Optional: Add more AI backends**
   - Try Ollama if available
   - Support user API keys (advanced users)

## Testing

Run the demo:

```bash
./sparc/4-refinement/poc-ai-helper/demo-integration.sh
```

Test individual components:

```bash
# Test Node.js helper directly
node container/bitbot/util/ai-helper.js "Docker" "How to install?"

# Test bash wrapper
source container/bitbot/util/ai-helper.sh
ask_ai "WSL" "How to enable WSL?"

# Test error handler integration
# See demo-integration.sh for examples
```

## Benefits

✅ **Zero setup** - Works immediately
✅ **Beginner-friendly** - Clear, simple answers
✅ **Always works** - Fallback to curated help
✅ **Privacy-respecting** - No tracking, no accounts
✅ **Offline capable** - Fallback works without internet
✅ **Free forever** - No API costs

## Trade-offs

⚠️ **Rate limits** - Free APIs are limited
⚠️ **Quality varies** - Not as good as GPT-4/Claude
⚠️ **Maintenance** - Fallback help needs updating

But for **absolute beginners**, this is perfect - they get help immediately without any barriers.
