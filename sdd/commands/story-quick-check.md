# /story-quick-check

Lightning-fast 30-second health check for current work in progress.

---

## Meta

**Category**: Testing & Validation
**Format**: Structured (Standard)
**Execution Time**: 15-30 seconds
**Prerequisites**: None (works at any stage)
**Destructive**: No (100% read-only)

**Related Commands**:
- `/story-test-integration` - Comprehensive integration tests (3-8 min)
- `/story-full-check` - Full validation suite (5 min)
- `/story-save` - Save progress with git commit

**Context Requirements**:
- None (uses project defaults)

---

## Parameters

**Check Scope** (optional):
```bash
# Run all checks (default)
/story-quick-check

# Scope to specific checks
--checks=syntax|tests|lint|git|all   # Default: all
--fix                                 # Auto-fix issues when possible
--verbose                             # Show detailed output
```

**Examples**:
```bash
/story-quick-check                    # Full 30s check
/story-quick-check --checks=tests     # Only run tests (~10s)
/story-quick-check --fix              # Auto-fix lint/format issues
```

---

## Process

### Phase 1: Basic Checks (10s)

**Syntax & Compilation**:
```bash
# Laravel: Check for syntax errors
php -l app/**/*.php
php artisan config:clear --quiet

# Check:
✓ PHP syntax valid
✓ Configuration compiles
✓ No fatal errors
✓ Dependencies resolved
```

**Output**:
```
🔍 BASIC CHECKS (8s)
====================
✅ PHP syntax valid (127 files checked)
✅ Config compiles
✅ Autoload working
✅ Env file present
```

**If Errors**:
```
❌ SYNTAX ERROR FOUND
  File: app/Livewire/TaskManager.php:42
  Error: syntax error, unexpected 'public' (T_PUBLIC)

  Quick fix: Missing semicolon on line 41
```

---

### Phase 2: Test Check (10s)

**Run Fast Tests**:
```bash
# Laravel/Pest: Run unit tests only (fastest)
php artisan test --filter=Unit --stop-on-failure

# Check:
✓ Existing tests still pass
✓ No new test failures
✓ Test files valid
```

**Output**:
```
🧪 TEST CHECK (9s)
==================
✅ Unit tests: 24/24 passed
✅ No failures detected
⚠️  New code in TaskManager.php has no tests

Tests run: 24
Duration: 0.8s
```

**If Failures**:
```
❌ TEST FAILURES (2)
  1. Task::updateOrder() - Expected 1, got 0
     Location: tests/Unit/TaskTest.php:45
     Quick fix: Update assertion to expect 0

  2. Category::tasks() - Undefined property
     Location: tests/Unit/CategoryTest.php:28
     Quick fix: Add relationship to Category model
```

---

### Phase 3: Lint & Format Check (5s)

**Code Quality**:
```bash
# Laravel: Run Pint in test mode (no changes)
vendor/bin/pint --test --dirty

# Check:
✓ Code formatting correct
✓ No style violations
✓ Follows Laravel standards
```

**Output**:
```
📋 LINT CHECK (4s)
==================
✅ Formatting correct (Laravel Pint)
✅ No style violations
✅ PSR-12 compliant
```

**If Issues**:
```
⚠️  FORMATTING ISSUES (3 files)
  - app/Livewire/TaskManager.php (12 changes)
  - app/Models/Task.php (3 changes)
  - routes/web.php (1 change)

Auto-fix: vendor/bin/pint --dirty
```

---

### Phase 4: Git Status Check (5s)

**Repository Status**:
```bash
# Check git state
git status --short
git diff --stat

# Check:
✓ Working directory clean (or changes tracked)
✓ No merge conflicts
✓ Branch status
```

**Output**:
```
🚦 GIT CHECK (3s)
=================
Branch: feature/STORY-DUE-002
Status: ⚠️  Uncommitted changes

Modified files:
  M app/Livewire/TaskManager.php
  M resources/views/livewire/task-manager.blade.php
  ?? tests/Feature/TaskDueDateTest.php

✓ No conflicts
✓ Up to date with remote
```

---

### Phase 5: Instant Results Summary (2s)

**Generate Quick Report**:
```
⚡ QUICK CHECK RESULTS
=====================
Completed in 28 seconds

┌──────────────┬────────┬──────────────────────┐
│ Check        │ Status │ Issues               │
├──────────────┼────────┼──────────────────────┤
│ Syntax       │   ✅   │ None                 │
│ Tests        │   ⚠️   │ 2 new tests needed   │
│ Lint/Format  │   ✅   │ None                 │
│ Git Status   │   ⚠️   │ Uncommitted changes  │
└──────────────┴────────┴──────────────────────┘

OVERALL: 🟡 YELLOW - Minor issues

⚠️  ISSUES FOUND (2):
  1. New code missing tests (TaskManager.php)
  2. Uncommitted changes (3 files)

🔧 QUICK FIXES:
  1. Add test: php artisan make:test TaskManagerTest
  2. Commit: /story-save "Add due date feature"

Estimated fix time: 5 minutes
```

---

### Phase 6: Auto-Fix (if --fix flag)

**Automatic Fixes**:
```bash
# If --fix flag provided
/story-quick-check --fix

# Auto-fixes:
✓ Run Pint to format code
✓ Clear config cache
✓ Suggest test creation
✓ Offer to commit changes
```

**Output**:
```
🔧 AUTO-FIX APPLIED
===================
✅ Formatted 3 files (vendor/bin/pint)
✅ Cleared config cache
⚠️  Tests require manual creation
⚠️  Git commit requires manual action

Updated status: 🟢 GREEN (after fixes)
```

---

## Examples

### Example 1: All Clear

```bash
$ /story-quick-check

⚡ QUICK CHECK RESULTS
=====================
Completed in 22 seconds

✅ Syntax: Valid
✅ Tests: 24/24 passed
✅ Lint: No issues
✅ Git: Clean working directory

OVERALL: 🟢 GREEN - All clear!

✅ Safe to proceed
```

### Example 2: Minor Issues (Yellow)

```bash
$ /story-quick-check

⚡ QUICK CHECK RESULTS
=====================
Completed in 28 seconds

OVERALL: 🟡 YELLOW - Minor issues

⚠️  ISSUES (2):
  1. Formatting: 3 files need Pint
  2. Git: 3 uncommitted changes

🔧 Quick fixes:
  vendor/bin/pint --dirty
  /story-save "Add feature"

Estimated fix: 2 minutes
```

### Example 3: Critical Issues (Red)

```bash
$ /story-quick-check

⚡ QUICK CHECK RESULTS
=====================
Completed in 18 seconds

OVERALL: 🔴 RED - Blocking issues

❌ CRITICAL (2):
  1. Syntax error: TaskManager.php:42
     Missing semicolon on line 41

  2. Test failures: 2/24 failed
     Task::updateOrder() - assertion failed
     Category::tasks() - undefined property

🔧 Must fix before continuing:
  1. Fix syntax error
  2. Update failing tests

Do NOT proceed until resolved.
```

### Example 4: Auto-Fix Applied

```bash
$ /story-quick-check --fix

⚡ QUICK CHECK RESULTS
=====================

🔧 AUTO-FIX APPLIED:
  ✅ Formatted 3 files
  ✅ Cleared caches
  ✅ Resolved all auto-fixable issues

OVERALL: 🟢 GREEN - All issues resolved!

Remaining manual actions:
  - Consider adding tests for new code
  - Run /story-save to commit changes

✅ Safe to proceed
```

### Example 5: Tests Only

```bash
$ /story-quick-check --checks=tests

🧪 TEST CHECK (9s)
==================
✅ Unit tests: 24/24 passed
✅ Feature tests: 8/8 passed

OVERALL: 🟢 GREEN

✅ All tests passing
```

---

## Success Criteria

**Command succeeds when**:
- All checks complete within 30 seconds
- Status report generated (green/yellow/red)
- Quick fixes suggested for issues
- Clear next action provided

**Status Levels**:
- 🟢 **GREEN**: No issues, safe to proceed
- 🟡 **YELLOW**: Minor issues, fix before review
- 🔴 **RED**: Blocking issues, must fix immediately

---

## Output Format

**One-Liner Status** (always shown):
```bash
✅ Clear to proceed
# or
⚠️ 3 issues need attention - 2min to fix
# or
❌ STOP: 2 critical errors must be fixed
```

**Detailed Report** (when issues found):
```
Issue breakdown by priority
Quick fix commands
Estimated fix time
Next recommended action
```

---

## Notes

- **Execution Time**: Always under 30 seconds
- **Read-Only**: Never modifies code (unless `--fix` flag)
- **Fast Feedback**: Designed for frequent use during development
- **Minimal Scope**: Only checks critical items (syntax, tests, lint, git)
- **Auto-Fix**: With `--fix` flag, automatically resolves formatting issues

**Best Practices**:
1. Run before every `/story-save` commit
2. Run after making changes to verify stability
3. Use `--fix` to quickly resolve formatting issues
4. Use `--checks=tests` for rapid test validation
5. If RED, fix immediately before continuing work

**When to Use**:
- ✅ Before committing code (`/story-save`)
- ✅ After implementing a feature
- ✅ Before switching tasks
- ✅ Multiple times per hour during active development

**When NOT to Use**:
- ❌ Instead of comprehensive testing (use `/story-test-integration`)
- ❌ For deployment validation (use `/story-full-check`)
- ❌ For final story validation (use `/story-validate`)

**Next Steps**:
```bash
🟢 GREEN → Continue work or /story-save
🟡 YELLOW → Fix issues, re-check, then /story-save
🔴 RED → Fix critical issues immediately
```

**For Deeper Validation**:
```bash
/story-test-integration  # Integration + E2E tests (3-8 min)
/story-full-check        # Complete validation suite (5 min)
```