# TODO: Hash Matching for Standalone Containers

**Priority**: Low (Future Enhancement)
**Status**: Research Phase
**Goal**: Build containers via `devcontainer up` that VS Code will reuse

---

## 🎯 Objective

Enable BitBot to pre-build dev containers (e.g., in CI/CD) that VS Code will recognize and reuse, eliminating duplicate builds and enabling faster developer onboarding.

---

## 🔬 Current State

### Container Hash Differences

**Manual CLI Build:**
```bash
$ devcontainer up --workspace-folder /workspace

Image: vsc-test-windows-launch-78977c62...
Hash:  78977c6207e7375e6aba7e5717e0a4b1...
```

**VS Code Build:**
```bash
$ code --folder-uri="vscode-remote://dev-container+..."

Image: vsc-test-windows-launch-a4656483...
Hash:  a4656483ab6394e337d31cc56e165941...
```

### Key Differences (from docker inspect)

| Feature | Manual CLI | VS Code |
|---------|-----------|---------|
| `/vscode` volume | ❌ | ✅ |
| Wayland socket | ❌ | ✅ |
| Extra ExecIDs | 0 | 6+ (VS Code Server processes) |
| Path case | `C:\` (uppercase) | `c:\` (lowercase) |

---

## 📋 Research Tasks

### Phase 1: Understanding VS Code's Build Process

- [ ] **Inspect VS Code Extension Source**
  - Location: `~/.vscode/extensions/ms-vscode-remote.remote-containers-*/`
  - Find: `devcontainer build` invocation code
  - Extract: Exact CLI flags and parameters used

- [ ] **Monitor VS Code's Runtime Behavior**
  ```bash
  # Windows (WSL)
  strace -f code.exe --folder-uri="..." 2>&1 | grep -i devcontainer

  # Linux/macOS
  dtruss -f code --folder-uri="..." 2>&1 | grep -i devcontainer
  ```

- [ ] **Compare Docker Configurations**
  ```bash
  # Build via CLI
  devcontainer up --workspace-folder .
  docker inspect <cli-container> > cli-container.json

  # Open via VS Code
  code --folder-uri="..."
  docker inspect <vscode-container> > vscode-container.json

  # Detailed diff
  diff -u cli-container.json vscode-container.json
  ```

- [ ] **Analyze Image Layers**
  ```bash
  docker history vsc-test-78977c62...
  docker history vsc-test-a4656483...
  ```

### Phase 2: Hash Calculation Analysis

- [ ] **Identify Hash Input**
  - VS Code uses SHA-256 of devcontainer.json content (base-32 encoded)
  - Does it include mounts? volumes? labels?
  - Order dependency? Whitespace sensitivity?

- [ ] **Test Hash Variations**
  ```bash
  # Test 1: Add /vscode mount to devcontainer.json
  {
    "mounts": [
      "source=${localWorkspaceFolder},target=/workspace,type=bind",
      "source=vscode,target=/vscode,type=volume"
    ]
  }

  # Test 2: Add labels
  {
    "containerEnv": {...},
    "customizations": {...}
  }

  # Compare resulting hashes
  ```

### Phase 3: VS Code Server Requirements

- [ ] **Identify Essential Mounts**
  - `/vscode` volume - Is it pre-created or on-demand?
  - Wayland socket - Platform-specific? Required?
  - Any other hidden volumes?

- [ ] **Test Minimal VS Code Server**
  ```bash
  # Can we run VS Code Server without /vscode mount?
  docker run -it --rm \
    -v "$(pwd):/workspace" \
    vsc-test-windows-launch-78977c62... \
    /bin/sh

  # Try to start VS Code Server manually
  ```

---

## 💡 Potential Solutions

### Solution A: Inject VS Code Configuration

**Approach:** Modify `devcontainer.json` before build to include VS Code's mounts

```bash
#!/bin/bash
# bitbot-prebuild.sh - Build with VS Code compatibility

# 1. Read original devcontainer.json
config=$(cat .devcontainer/devcontainer.json)

# 2. Inject VS Code mounts
config=$(echo "$config" | jq '.mounts += [
  "source=vscode,target=/vscode,type=volume"
]')

# 3. Write temporary config
echo "$config" > .devcontainer/devcontainer.vscode.json

# 4. Build with modified config
devcontainer up --config .devcontainer/devcontainer.vscode.json

# 5. Cleanup
rm .devcontainer/devcontainer.vscode.json
```

**Pros:**
- ✅ Explicit configuration
- ✅ Easy to version control

**Cons:**
- ❌ Modifies user's config
- ❌ May break non-VS Code workflows
- ❌ Platform-specific mounts (Wayland)

### Solution B: Use CLI Flags

**Approach:** Pass VS Code's mounts via devcontainer CLI flags

```bash
devcontainer up \
  --workspace-folder . \
  --mount "type=volume,source=vscode,target=/vscode" \
  --mount "type=bind,source=/run/desktop/mnt/...,target=/tmp/vscode-wayland-*.sock"
```

**Pros:**
- ✅ No config modification
- ✅ Flexible per-build

**Cons:**
- ❌ Complex flag management
- ❌ Platform detection needed
- ❌ May not match hash (flags might not be in hash calculation)

### Solution C: Pre-create VS Code Infrastructure

**Approach:** Create VS Code's required volumes/resources before build

```bash
# 1. Create VS Code volume
docker volume create vscode

# 2. Detect Wayland socket (Linux)
if [ -d "/run/desktop/mnt/host/wsl" ]; then
  WAYLAND_SOCK=$(find /run/desktop/mnt/host/wsl -name "vscode-wayland-*.sock" | head -1)
fi

# 3. Build (VS Code detects pre-existing resources)
devcontainer up --workspace-folder .

# Result: VS Code reuses same container?
```

**Pros:**
- ✅ Non-invasive
- ✅ Matches VS Code's runtime environment

**Cons:**
- ❌ Uncertain if hash will match
- ❌ Platform-specific detection

### Solution D: Reverse Engineer VS Code CLI

**Approach:** Call VS Code's internal build API directly

```bash
# 1. Find VS Code's devcontainer CLI
VSCODE_CLI="$HOME/.vscode/extensions/.../cli"

# 2. Call with VS Code's internal flags (to be discovered)
$VSCODE_CLI build \
  --workspace-folder . \
  --include-vscode-server \
  --output-format json

# 3. Result: Same hash as VS Code GUI
```

**Pros:**
- ✅ Guaranteed hash match
- ✅ Official VS Code tooling

**Cons:**
- ❌ VS Code internals may change
- ❌ Not documented/supported
- ❌ Tight coupling to VS Code version

---

## 🧪 Experiment Plan

### Experiment 1: Simple Mount Addition

```bash
# Modify devcontainer.json
{
  "image": "ubuntu:22.04",
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",
    "source=vscode,target=/vscode,type=volume"  # ← Add this
  ]
}

# Build
devcontainer up --workspace-folder .

# Open in VS Code
code --folder-uri="vscode-remote://dev-container+..."

# Check: Same container ID?
docker ps --filter="label=devcontainer.local_folder"
```

**Expected Result:** If hash matches, VS Code reuses container

### Experiment 2: Path Case Sensitivity

```bash
# Test if C:\ vs c:\ affects hash

# Build 1: Uppercase
devcontainer up --workspace-folder C:\Projects\BitBot

# Build 2: Lowercase
devcontainer up --workspace-folder c:\projects\bitbot

# Compare hashes
```

**Expected Result:** Determine if path normalization affects hash

### Experiment 3: Label Matching

```bash
# Add VS Code labels to CLI build
docker build \
  --label "vscode.devcontainer=true" \
  --label "devcontainer.metadata={...}" \
  ...

# Compare with VS Code build
```

**Expected Result:** Identify if labels affect hash

---

## 📊 Success Criteria

### Minimum Viable
- [ ] Containers built via CLI can be opened in VS Code (even if new container)
- [ ] No conflicts or errors when opening

### Ideal
- [ ] **Hash matches** - VS Code reuses exact same container
- [ ] Works across platforms (Windows, macOS, Linux)
- [ ] Documented process for developers

### Stretch Goals
- [ ] CI/CD integration - Pre-build in GitHub Actions
- [ ] Multi-developer sharing - Team reuses same pre-built containers
- [ ] Version pinning - Lock container hash for reproducibility

---

## 📚 Resources

### VS Code Extension Source
- GitHub: `microsoft/vscode-remote-release`
- Extension: `ms-vscode-remote.remote-containers`
- CLI: `~/.vscode/extensions/ms-vscode-remote.remote-containers-*/`

### Devcontainer Specification
- Spec: https://containers.dev/
- Schema: https://containers.dev/implementors/json_schema/

### Community Tools
- `devcontainer-cli` by Stuart Leeks
- `@devcontainers/cli` official standalone

### Existing Research
- Stack Overflow: "VS Code dev container from CLI"
- Blog: "Reverse engineering dev container CLI"
- GitHub Issues: microsoft/vscode-remote-release

---

## ⏱️ Time Estimates

| Phase | Effort | Timeline |
|-------|--------|----------|
| Research VS Code internals | Medium | 1-2 weeks |
| Hash calculation analysis | High | 2-3 weeks |
| Prototype solutions | Medium | 1-2 weeks |
| Cross-platform testing | Medium | 1 week |
| Documentation | Low | 2-3 days |

**Total:** ~6-8 weeks for complete implementation

---

## 🚦 Dependencies

**Blockers:**
- None (independent research)

**Nice-to-have:**
- Access to VS Code source code (public)
- Multiple platforms for testing
- Community collaboration

---

## 🎯 Next Actions

1. **Immediate (When priority increases):**
   - [ ] Clone VS Code extension source
   - [ ] Run Experiment 1 (simple mount addition)
   - [ ] Document initial findings

2. **Future:**
   - [ ] Engage with VS Code team (GitHub issues)
   - [ ] Prototype Solution A (inject config)
   - [ ] Test on CI/CD (GitHub Actions)

---

**Last Updated:** 2025-10-20
**Status:** Documented, not started
**Priority:** Low (current direct URI approach works well)
