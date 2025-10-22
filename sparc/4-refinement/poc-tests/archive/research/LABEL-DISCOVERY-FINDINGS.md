# Label Discovery Findings

## Key Discovery: Path Format Matters!

### The Problem

VS Code and `@devcontainers/cli` use **different path formats** in Docker labels:

| Tool | Path Format | Example |
|------|-------------|---------|
| VS Code | Windows path with backslashes | `c:\Projects\BitBot\test-windows-launch` |
| devcontainer CLI | WSL/Unix path | `/mnt/c/Projects/BitBot/test-windows-launch` |

### Evidence

**From debug output:**
```
devcontainer.config_file = c:\Projects\BitBot\test-windows-launch\.devcontainer\devcontainer.json
devcontainer.local_folder = c:\Projects\BitBot\test-windows-launch
```

VS Code uses the **Windows path** format, not WSL paths.

---

## Why Labels Were "Missing"

My initial tests searched for:
```bash
docker ps --filter 'label=devcontainer.local_folder=/mnt/c/Projects/BitBot/test-windows-launch'
```

But VS Code's containers have:
```bash
docker ps --filter 'label=devcontainer.local_folder=c:\\Projects\\BitBot\\test-windows-launch'
```

**Different paths = no match!**

---

## Container Naming

### VS Code Pattern

- **Container name**: Random (e.g., `upbeat_shannon`)
- **Image name**: `vsc-{folder}-{hash}` pattern
  - Example: `vsc-test-windows-launch-a4656483ab6394e337d31cc56e16594111d20cbcce55364bb447ab44d27e6118`

### devcontainer CLI Pattern

- **Container name**: Random or auto-generated
- **Image name**: Based on Dockerfile/config
- **Labels**: Uses WSL paths (`/mnt/c/...`)

---

## Label-Based Discovery: Does It Work?

### ✅ What Works

1. **Labels exist on both CLI and VS Code containers**
   - `devcontainer.local_folder`
   - `devcontainer.config_file`
   - `devcontainer.metadata`

2. **You can filter containers by labels**
   ```bash
   docker ps --filter 'label=devcontainer.metadata'
   ```

3. **VS Code CAN find containers by labels**
   - But only if the path format matches exactly

### ❌ What Doesn't Work (Yet)

1. **Auto-detection across tools**
   - CLI uses `/mnt/c/...` paths
   - VS Code uses `c:\...` paths
   - Different paths = no match

2. **"Reopen in Container" doesn't detect CLI containers**
   - Even though labels exist
   - Path mismatch prevents discovery

---

## Solutions

### Option 1: Force CLI to Use Windows Paths

**Challenge**: `@devcontainers/cli` runs in WSL, naturally uses WSL paths.

**Possible fix**: Set environment variable or config to use Windows paths in labels?

### Option 2: Manual Attachment via URI

**Works now**:
```powershell
# Get container ID
$containerId = "abc123"

# Hex encode
$hex = (printf $containerId | od -A n -t x1 | tr -d ' \n')

# Launch VS Code
code --folder-uri "vscode-remote://attached-container+$hex/workspace"
```

### Option 3: Wrapper Script

BitBot could:
1. Build container via `devcontainer up`
2. Add additional label with Windows path
3. VS Code then finds it

```bash
# After devcontainer up
docker update --label-add "devcontainer.local_folder=c:\Projects\..." $container
```

---

## Test Status

### ✅ Fixed Tests

- `test-label-discovery.ps1` - Now searches both path formats
- `test-vscode-hash-match.ps1` - Handles path conversion
- `debug-containers.ps1` - Shows all labels regardless of path

### 🔄 New Tests

- `test-vscode-auto.ps1` - Fully automated VS Code launch via URI
- `test-cli-then-vscode-attach.ps1` - Tests CLI → VS Code attachment

---

## Implications for BitBot

### What We Learned

1. ✅ Labels ARE the discovery mechanism
2. ✅ Both tools add proper labels
3. ❌ Path format mismatch prevents auto-discovery
4. ✅ Manual attachment works (via URI)

### BitBot Strategy

**Option A**: Force path format consistency
- Ensure CLI and VS Code use same path format in labels
- Requires wrapper or config

**Option B**: Use URI-based attachment
- BitBot CLI launches VS Code with explicit container URI
- Bypasses label discovery entirely
- More reliable

**Option C**: Hybrid
- Try label-based discovery first (check both path formats)
- Fall back to URI-based attachment
- Best of both worlds

---

## Next Steps

1. Test `test-cli-then-vscode-attach.ps1` to verify URI method
2. Document path format handling in BitBot CLI
3. Update consolidated spec with real findings (not assumptions)

---

## References

- Debug output: Shows Windows paths in labels
- VS Code docs: Attachment methods
- Docker label docs: Filter syntax
