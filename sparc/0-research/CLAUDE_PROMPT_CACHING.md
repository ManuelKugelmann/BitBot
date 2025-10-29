# Claude Prompt Caching

Research on how prompt caching works in Claude API and Claude Code.

## What Are Cached Tokens?

Prompt caching introduces **three token types** in Claude API responses:

| Token Type | Description | Cost |
|------------|-------------|------|
| **Cache write tokens** | New content written to cache | 1.25× base price (5-min TTL)<br>2× base price (1-hour TTL) |
| **Cache read tokens** | Previously cached content reused | 0.1× base price (90% savings) |
| **Regular input tokens** | Uncached content processed normally | 1× base price |

## How Prompt Caching Works

### The Problem It Solves

Normally, when Claude processes a prompt, it builds "attention states" (internal maps of how words and concepts connect). **Without caching**, the model rebuilds these maps every time—even for identical prompts.

**With caching**, those attention states are saved and reused for repeated content.

### Cache Mechanism

1. **Cache breakpoints**: You mark content with `cache_control: {type: "ephemeral"}`
2. **Automatic checking**: System checks if prompt prefix matches recent queries
3. **Cache hit**: Reuses cached version (fast + cheap)
4. **Cache miss**: Processes full prompt and caches for next time

### Cache Hierarchy

Cache prefixes are created in this order:
1. **Tools** (function definitions)
2. **System** (instructions, context)
3. **Messages** (conversation history)

### Cache Lifetime

- **TTL**: 5 minutes (default) or 1 hour (premium)
- **Refresh**: Resets with each cache hit (no additional cost)
- **Expiration**: Cache lost if unused for TTL period

### Requirements & Limits

**Minimum cacheable content:**
- Claude Opus 4, Sonnet 4/4.5: **1024 tokens**
- Claude Haiku 3.5: **2048 tokens**

**Limits:**
- Max cache breakpoints: **4**
- Max cached tokens: **32,000 tokens**

## In Claude Code

**Automatic caching**: Claude Code automatically uses prompt caching to optimize performance and reduce costs.

### What Gets Cached

Claude Code likely caches:
- System instructions (your CLAUDE.md, skill descriptions, tool definitions)
- Large file contents that remain unchanged
- Conversation context that repeats

### Environment Variables

Control caching behavior:

```bash
# Disable caching globally
DISABLE_PROMPT_CACHING=true

# Disable for specific models
DISABLE_PROMPT_CACHING_HAIKU=true
DISABLE_PROMPT_CACHING_SONNET=true
DISABLE_PROMPT_CACHING_OPUS=true
```

**Note**: Global setting takes precedence over model-specific settings.

### Monitoring Cache Usage

Token counts visible in:
- Status line (via ccstatusline wrapper)
- API responses in `usage` field:
  - `cache_creation_input_tokens` - Tokens written to cache
  - `cache_read_input_tokens` - Tokens retrieved from cache
  - `input_tokens` - Regular uncached tokens

## Cost Impact Example

**Scenario**: 10,000 token prompt used 10 times

**Without caching:**
- Cost: 10,000 tokens × 10 calls × base price = **100,000 token-equivalents**

**With caching (first call writes, rest read):**
- First call: 10,000 × 1.25 = 12,500 token-equivalents (write)
- Next 9 calls: 10,000 × 0.1 × 9 = 9,000 token-equivalents (read)
- Total: **21,500 token-equivalents** (78.5% savings)

## Why Cached Tokens Matter

### For Cost
- **90% cheaper** to read cached content vs. processing fresh
- Large CLAUDE.md files cached once, read many times
- Tool definitions cached across conversation

### For Speed
- **85% faster** responses when cache hits
- No need to rebuild attention states
- Better user experience

### For Development
- Longer context files become practical (specs, docs)
- Can include more examples and guidance
- Skills with detailed instructions cost less per use

## Best Practices

### What to Cache
✅ System instructions that don't change
✅ Large documentation or codebases
✅ Tool/skill definitions
✅ Examples and templates
✅ Long conversation history

### What NOT to Cache
❌ Frequently changing content
❌ Very short content (< min threshold)
❌ User-specific data that varies per call
❌ Real-time data or timestamps

### Optimization Tips

1. **Structure for caching**: Put stable content (instructions, tools) before variable content (user messages)
2. **Batch similar requests**: Reuse cache within 5-minute window
3. **Monitor usage**: Check cache hit rates in API responses
4. **Right-size breakpoints**: Don't create tiny cached segments (overhead)

## BitBot Context

In BitBot, prompt caching is beneficial for:

- **CLAUDE.md**: Large instruction files cached across session
- **Skills**: Skill descriptions cached when loaded
- **Templates**: Template documentation cached
- **Tools**: Tool definitions (Bash, Read, Edit, etc.) cached

Since Claude Code manages caching automatically, BitBot doesn't need special handling—just organize content to maximize cache reuse.

## References

- [Claude API Prompt Caching Documentation](https://docs.claude.com/en/docs/build-with-claude/prompt-caching)
- [Claude Code Model Configuration](https://docs.claude.com/en/docs/claude-code/model-config.md)
- [Anthropic Prompt Caching Announcement](https://www.anthropic.com/news/prompt-caching)
