## BitBot Development Template

You are working on BitBot itself. Full access to development documentation.

### What's Included
- Cross-compilation tools (MinGW for Windows launcher)
- Build tools (gcc, make)
- Shared home folders (`.claude/`, `.opencode/`, etc.)
- BitBot development utilities

### Development Areas
- `/core/` - Host-side BitBot scripts
- `/container/` - Container-side runtime and templates
- `/dev/scripts/` - Release and build scripts
- `/dev/tests/` - Test suites
- `/sparc/` - SPARC methodology documentation

### Special Scripts
- `dev/scripts/create-release-branch.sh` - Create release branches
- `dev/scripts/merge-all.sh` - Merge all template devcontainer files
- `dev/scripts/sync-claude-md-to-templates.sh` - Sync CLAUDE.md to templates

### Cross-Compilation
Build Windows launcher:
```bash
cd dev/src/launcher_windows
./build.sh
```

### Testing
Run test suites:
```bash
dev/tests/test-*.sh
```

See root `CLAUDE.md` for full BitBot development guidance including:
- Project Structure
- SPARC Process
- Testing Guidelines
- Template internals
