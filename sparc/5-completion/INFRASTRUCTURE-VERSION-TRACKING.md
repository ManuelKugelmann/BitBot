# Infrastructure Version Tracking - Design Notes

## Current Problem

**`.bitbot/internal/.version`** contains BitBot version string (e.g., "0.2.0")

**Issues:**
1. **Doesn't reflect actual content**: Version string doesn't indicate what's actually in `.bitbot/internal/`
2. **Mount override breaks it**: When `$BITBOT_HOME` mounts override `.bitbot/internal/global/`, the version file shows wrong info
3. **No verification**: Can't detect if infrastructure is stale or corrupted

## Better Approach: Content Hash

### Design

Store **hash of actual infrastructure content** instead of version string:

```
.bitbot/internal/.infrastructure-hash
```

**Content:**
```
# BitBot Infrastructure Hash
# Generated: 2025-10-30T08:00:00Z
hash=abc123def456...
bitbot_version=0.2.0
```

### What Gets Hashed

```bash
# Hash these directories
.bitbot/internal/container/
.bitbot/internal/global/

# Exclude
.bitbot/internal/.infrastructure-hash  (self)
.bitbot/internal/global/.claude/.credentials.json  (user-specific)
```

### Benefits

✅ **Reflects actual content**: Hash changes when infrastructure changes
✅ **Works with mount overrides**: Hash computed from actual mounted content
✅ **Detects corruption**: Compare hash to detect stale/broken infrastructure
✅ **Version-independent**: Hash is independent of BitBot version

### Implementation

**1. Generate hash during `bitbot init`:**
```bash
generate_infrastructure_hash() {
    local workspace="$1"
    local hash_file="$workspace/.bitbot/internal/.infrastructure-hash"

    # Compute hash of infrastructure
    local hash=$(find "$workspace/.bitbot/internal" \
        -type f \
        ! -name ".infrastructure-hash" \
        ! -name ".credentials.json" \
        -exec sha256sum {} \; | \
        sort | \
        sha256sum | \
        cut -d' ' -f1)

    # Write hash file
    cat > "$hash_file" << EOF
# BitBot Infrastructure Hash
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
hash=$hash
bitbot_version=$(bitbot --version)
EOF
}
```

**2. Verify hash before container start:**
```bash
verify_infrastructure() {
    local workspace="$1"
    local hash_file="$workspace/.bitbot/internal/.infrastructure-hash"

    if [ ! -f "$hash_file" ]; then
        echo "⚠️  No infrastructure hash found - infrastructure may be outdated"
        return 1
    fi

    # Read expected hash
    local expected_hash=$(grep "^hash=" "$hash_file" | cut -d= -f2)

    # Compute current hash
    local current_hash=$(compute_current_hash "$workspace")

    if [ "$expected_hash" != "$current_hash" ]; then
        echo "⚠️  Infrastructure hash mismatch"
        echo "   Expected: $expected_hash"
        echo "   Current:  $current_hash"
        echo ""
        echo "Infrastructure may be outdated or corrupted."
        echo "Run 'bitbot init' to refresh infrastructure."
        return 1
    fi

    return 0
}
```

**3. Optional: Warn on version mismatch**
```bash
# Even if hash matches, warn if BitBot version changed
check_version_drift() {
    local hash_file="$1"
    local stored_version=$(grep "^bitbot_version=" "$hash_file" | cut -d= -f2)
    local current_version=$(bitbot --version)

    if [ "$stored_version" != "$current_version" ]; then
        echo "ℹ️  BitBot version changed: $stored_version → $current_version"
        echo "   Infrastructure hash still valid, but consider updating:"
        echo "   bitbot init"
    fi
}
```

## Alternative: Remove `.version` Entirely

**Simplest approach:**
- Remove `.bitbot/internal/.version` completely
- No need to track version if we're not using it for anything
- `$BITBOT_HOME` mounts always provide latest
- Codespaces uses committed copy (always correct)

**When might we need version tracking?**
- Detecting when infrastructure needs update
- Warning users about version drift
- Debugging infrastructure issues

**Recommendation:** Implement hash-based tracking only when needed for actual verification/debugging use cases.

## Decision: Defer Implementation

**Current state:**
- `.version` exists but not actively used
- No verification logic exists
- Infrastructure sync works via rsync (always fresh)

**TODO:**
- [ ] Document that `.version` is informational only
- [ ] Consider removing it if never used
- [ ] Implement hash-based tracking when verification is needed
- [ ] Add to sparc/TODOS.md for future consideration

## See Also

- `sparc/3-architecture/01-directory-structure.md` - Directory structure
- `sparc/1-specification/13_CODESPACES_INFRASTRUCTURE.md` - Infrastructure sync design
