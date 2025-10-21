# Version Command Pseudocode (Universal)

**Component**: Version Command (Universal)
**Script**: `scripts/lib/bitbot-version.sh`
**Purpose**: Display BitBot version

---

## Main Version Function

```pseudocode
FUNCTION bitbot_version():
    SET version = "0.1.0-mvp"

    PRINT "BitBot version " + version
    PRINT ""
    PRINT "A secure development environment manager"
    PRINT "https://bitbot.dev"
END FUNCTION
```

---

## Implementation Notes

**Universal Command**: Works in both global and workspace contexts

**Version Format**: Semantic versioning (MAJOR.MINOR.PATCH-label)

**MVP**: Hardcoded version string

**Future**:
- Read from VERSION file
- Show build info (commit hash, build date)
- Show installed components (devcontainer CLI, Docker, etc.)
