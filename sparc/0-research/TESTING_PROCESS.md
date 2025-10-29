# BitBot Testing Process

Step-by-step testing guidelines with todo list tracking.

## Process Overview

1. Create Tests
2. Run Tests in WSL
3. Fix Issues
4. Commit After Success
5. Use Test Framework

## 1. Create Tests

- Write test script in `dev/tests/test-<feature>.sh`
- Include bash syntax check, unit tests, integration tests
- Use clear test names and section headers
- Follow existing test structure (see `dev/tests/test-container-bitbot.sh`)

## 2. Run Tests in WSL

- Fix line endings + check syntax: `.claude/skills/fix-line-endings-check-bash/scripts/fix-line-endings-check-bash.sh dev/tests/test-<feature>.sh`
- Run with timeout: `.claude/skills/run-with-timeout/scripts/run-with-timeout.sh 60 dev/tests/test-<feature>.sh`
- Debug failures individually before moving on

## 3. Fix Issues

- Fix line endings: `.claude/skills/fix-line-endings/scripts/fix-line-endings.sh file.sh` (or use fix-line-endings-check-bash)
- Check syntax only: `.claude/skills/check-bash/scripts/check-bash.sh file.sh`
- Fix logic errors one at a time
- Rerun tests after each fix
- Don't commit until all tests pass

## 4. Commit After Success

- Commit line ending fixes separately
- Commit test suite with results in commit message
- Add test to `dev/tests/run-tests.sh` if appropriate

## 5. Test Framework

- Use `run_test()`, `test_passed()`, `test_failed()` helpers
- Show colored output (GREEN=pass, RED=fail, BLUE=section)
- Print summary with success rate
- Exit 0 if all pass, exit 1 if any fail

## Example Workflow

```bash
# 1. Create test
vim dev/tests/test-feature.sh
chmod +x dev/tests/test-feature.sh

# 2. Fix line endings and check syntax (use skills!)
.claude/skills/fix-line-endings-check-bash/scripts/fix-line-endings-check-bash.sh dev/tests/test-feature.sh
.claude/skills/fix-line-endings-check-bash/scripts/fix-line-endings-check-bash.sh feature/script.sh

# 3. Run tests with timeout to prevent hangs
.claude/skills/run-with-timeout/scripts/run-with-timeout.sh 60 dev/tests/test-feature.sh

# 4. Fix issues and rerun
# ... fix logic errors ...
.claude/skills/run-with-timeout/scripts/run-with-timeout.sh 60 dev/tests/test-feature.sh

# 5. Commit
git add feature/script.sh
git commit -m "Fix line endings"
git add dev/tests/test-feature.sh
git commit -m "Add feature test suite (28/28 pass)"
```

## See Also

- `dev/tests/` - Existing test suites
- `.claude/skills/fix-line-endings-check-bash/` - Line ending fix skill
- `.claude/skills/run-with-timeout/` - Timeout wrapper skill
