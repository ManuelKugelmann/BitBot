# Installing jq

`jq` is a lightweight command-line JSON processor required for merging devcontainer.json files in BitBot templates.

## Why jq?

BitBot uses a merge system to combine `base.devcontainer.json` + `details.devcontainer.json` => `devcontainer.json`. This allows shared configuration across all templates while keeping template-specific details separate.

## Installation

### Ubuntu / Debian / WSL

```bash
sudo apt-get update
sudo apt-get install jq
```

### Alpine Linux

```bash
apk add jq
```

### macOS

**Using Homebrew**:
```bash
brew install jq
```

**Using MacPorts**:
```bash
sudo port install jq
```

### Windows

**Using Chocolatey**:
```powershell
choco install jq
```

**Using Scoop**:
```powershell
scoop install jq
```

**Manual (using winget)**:
```powershell
winget install jqlang.jq
```

### Arch Linux

```bash
sudo pacman -S jq
```

### Fedora / CentOS / RHEL

```bash
sudo dnf install jq
# or
sudo yum install jq
```

## Verification

After installation, verify jq is working:

```bash
jq --version
```

You should see output like:
```
jq-1.6
```

## Usage in BitBot

Once jq is installed, you can use the merge scripts:

```bash
# Merge single template
./templates/shared/scripts/merge-devcontainer.sh templates/workspace

# Merge all templates
./templates/shared/scripts/merge-all.sh
```

## In BitBot Devcontainers

All BitBot devcontainer templates include jq pre-installed:
- ✅ Root `.devcontainer/` (BitBot development)
- ✅ `templates/base/`
- ✅ `templates/config/`
- ✅ `templates/workspace/`

So if you're working inside a BitBot devcontainer, jq is already available.

## Troubleshooting

### jq: command not found

**Problem**: jq is not installed or not in PATH

**Solution**:
1. Install jq using the instructions above
2. Verify installation: `which jq`
3. If installed but not found, add to PATH:
   ```bash
   export PATH="/usr/local/bin:$PATH"
   ```

### Permission denied

**Problem**: Cannot install jq due to permissions

**Solution**: Use `sudo` for system installation:
```bash
sudo apt-get install jq
```

### jq works but merge script fails

**Problem**: Script can't find base.devcontainer.json

**Solution**: Run merge script from project root:
```bash
cd /path/to/BitBot
./templates/shared/scripts/merge-devcontainer.sh templates/workspace
```

## Alternative: Manual Merge

If you cannot install jq, you can manually merge devcontainer.json files:

1. Copy `templates/shared/base.devcontainer.json`
2. Manually add fields from template's `details.devcontainer.json`
3. Save as template's `devcontainer.json`

**Note**: This is error-prone and not recommended for regular use.

## See Also

- [jq Official Website](https://jqlang.github.io/jq/)
- [jq Manual](https://jqlang.github.io/jq/manual/)
- [BitBot Shared README](README.md)
