---
name: test-workflow
description: Run BitBot's standard test workflow: fix line endings, check syntax, run tests with timeout. Use PROACTIVELY after creating/modifying shell scripts or test files.
---

Running BitBot test workflow...

This workflow:
1. Fixes line endings (CRLF → LF)
2. Checks bash syntax
3. Runs tests with timeout protection
4. Reports results

## Usage

Provide the script/test file to process:

```bash
.claude/skills/test-workflow/scripts/test-workflow.sh <file>
```

## What It Does

**Step 1: Fix Line Endings & Check Syntax**
- Converts CRLF → LF
- Validates bash syntax
- Reports any syntax errors

**Step 2: Run Tests (if test file)**
- Executes with 60-second timeout
- Prevents hanging tests
- Shows pass/fail results

**Step 3: Report Status**
- Shows success/failure
- Next steps if errors found

## When to Use Proactively

**After creating shell scripts:**
```bash
# Just wrote new script
.claude/skills/test-workflow/scripts/test-workflow.sh core/util/new-script.sh
```

**After modifying existing scripts:**
```bash
# Updated implementation
.claude/skills/test-workflow/scripts/test-workflow.sh core/workspace/bitbot-work.sh
```

**After creating test files:**
```bash
# Created new test suite
.claude/skills/test-workflow/scripts/test-workflow.sh dev/tests/test-new-feature.sh
```

## See Also

- `sparc/0-research/TESTING_PROCESS.md` - Full testing guidelines
- `.claude/skills/fix-line-endings-check-bash/` - Individual fix+check
- `.claude/skills/run-with-timeout/` - Timeout wrapper
