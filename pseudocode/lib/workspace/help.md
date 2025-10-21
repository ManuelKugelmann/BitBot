# Help Command Pseudocode (Workspace)

**Component**: Help Command (Workspace Context)
**Script**: `scripts/lib/workspace/bitbot-help.sh`
**Purpose**: Display workspace command help

---

## Main Help Function

```pseudocode
FUNCTION bitbot_help():
    PRINT "BitBot - Secure Development Environment Manager"
    PRINT ""
    PRINT "Usage: bitbot [command] [modifiers]"
    PRINT ""
    PRINT "Commands:"
    PRINT "  bitbot work [vscode]     Launch work mode (RO .devcontainer)"
    PRINT "  bitbot config [vscode]   Launch config mode (RW .devcontainer)"
    PRINT "  bitbot init              Initialize workspace"
    PRINT "  bitbot help              Show this help"
    PRINT "  bitbot version           Show version"
    PRINT ""
    PRINT "Modifiers:"
    PRINT "  vscode                   Launch in VS Code"
    PRINT ""
    PRINT "Modes:"
    PRINT "  work   - Development work (.devcontainer is read-only)"
    PRINT "  config - Edit .devcontainer and infrastructure"
    PRINT ""
    PRINT "Examples:"
    PRINT "  bitbot                   # Launch work mode (default)"
    PRINT "  bitbot work              # Launch work mode"
    PRINT "  bitbot work vscode       # Launch work mode in VS Code"
    PRINT "  bitbot config            # Edit devcontainer configuration"
    PRINT "  bitbot init              # Initialize workspace"
    PRINT ""
    PRINT "Global Commands (from BitBot install folder):"
    PRINT "  bitbot config            # Configure global BitBot settings"
    PRINT "  bitbot serve             # Launch global services (future)"
    PRINT ""
    PRINT "For more info, see: https://docs.bitbot.dev/"
END FUNCTION
```

---

## Implementation Notes

**Context**: Workspace-specific help
**Global Help**: Shown when run from BitBot install folder (different)

**MVP Scope**:
- Simple text help
- No man page
- No --help flags for individual commands

**Future**:
- Detailed command help (bitbot help <command>)
- Man page integration
- Interactive help
