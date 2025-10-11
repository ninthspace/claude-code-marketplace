# /sdd:story-test-integration

Execute comprehensive integration and end-to-end tests for story validation.

---

## Meta

**Category**: Testing & Validation
**Format**: Imperative (Comprehensive)
**Execution Time**: 3-8 minutes
**Prerequisites**: Active story in `/stories/development/` or `/stories/review/`
**Destructive**: No (read-only with test execution)

**Related Commands**:
- `/sdd:story-quick-check` - Fast validation before integration tests
- `/sdd:story-full-check` - Comprehensive validation suite (includes this + more)
- `/sdd:story-validate` - Final story validation (runs after this)

**Context Requirements**:
- `/project-context/technical-stack.md` (testing tools, frameworks, database)
- `/project-context/coding-standards.md` (test patterns, coverage requirements)
- `/project-context/development-process.md` (integration testing criteria)

---

## Parameters

**Story Parameters**:
```bash
# Auto-detect from current active story or specify:
--story-id=STORY-XXX-NNN     # Specific story ID
--scope=api|db|e2e|all        # Test scope (default: all)
--performance                 # Include performance profiling
```

**Test Configuration**:
```bash
--browser=chrome|firefox|safari  # Browser for e2e tests (default: chrome)
--parallel=N                     # Parallel test execution (default: 4)
--coverage                       # Generate coverage report
--verbose                        # Detailed test output
```

---

## Process

### Phase 1: Test Scope Discovery (30s)

**Load Context**:
```bash
# Verify project context exists
if ! [ -d /project-context/ ]; then
  echo "⚠️  Missing /project-context/ - run /sdd:project-init first"
  exit 1
fi

# Load testing requirements
source /project-context/technical-stack.md      # Testing tools
source /project-context/coding-standards.md     # Test patterns
source /project-context/development-process.md  # Integration criteria
```

**Identify Test Scope**:
1. Read active story acceptance criteria
2. Extract integration points (API, database, external services)
3. Identify dependent services and components
4. Determine required test types (API, DB, E2E, performance)

**Output**:
```
🎯 INTEGRATION TEST SCOPE
========================
Story: STORY-XXX-NNN - [Title]

Integration Points:
  ✓ API: POST /api/tasks, GET /api/tasks/{id}
  ✓ Database: tasks, categories, task_category pivot
  ✓ Livewire: TaskManager component
  ✓ Browser: Task creation workflow

Test Types: API, Database, E2E, Performance
Estimated Duration: ~5 minutes
```

---

### Phase 2: API Integration Tests (1-2 min)

**Execute API Tests**:
```bash
# Laravel/Pest example
php artisan test --filter=Api --coverage

# Check:
✓ Endpoint functionality (CRUD operations)
✓ Request/response formats (JSON, validation)
✓ Authentication/authorization (gates, policies)
✓ Error responses (422, 404, 403, 500)
✓ Rate limiting (if configured)
```

**Output**:
```
🔗 API INTEGRATION TESTS
=======================
✅ POST /api/tasks creates task          (24ms)
✅ GET /api/tasks returns all tasks      (18ms)
✅ PUT /api/tasks/{id} updates task      (22ms)
✅ DELETE /api/tasks/{id} removes task   (19ms)
❌ POST /api/tasks validates input       (FAILED)
   Expected 422, got 500
   Error: Column 'order' cannot be null

Passed: 4/5 (80%)
Failed: 1
Duration: 0.8s
```

---

### Phase 3: Database Integration Tests (1-2 min)

**Execute Database Tests**:
```bash
# Test database operations
php artisan test --filter=Database

# Check:
✓ CRUD operations (create, read, update, delete)
✓ Transactions (rollback, commit)
✓ Data integrity (constraints, foreign keys)
✓ Migrations (up, down, fresh)
✓ Relationships (eager loading, N+1 prevention)
```

**Output**:
```
💾 DATABASE INTEGRATION
======================
✅ Task model creates records           (12ms)
✅ Categories relationship loads        (8ms)
✅ Soft deletes work correctly          (10ms)
✅ Order column maintains sequence      (15ms)
✅ Transaction rollback on error        (18ms)

Passed: 5/5 (100%)
Duration: 0.6s

Query Performance:
  Average: 8ms
  Slowest: Task::with('categories') - 15ms
```

---

### Phase 4: End-to-End Tests (2-4 min)

**Execute Browser Tests**:
```bash
# Pest v4 Browser Testing
php artisan test --filter=Browser --browser=chrome

# Test workflows:
✓ Complete user workflows (login → create → edit → delete)
✓ Multi-step processes (task creation with categories)
✓ Cross-feature interactions (filtering + sorting)
✓ Data flow validation (form → server → database → UI)
```

**Output**:
```
🌐 END-TO-END TESTS (Chrome)
===========================
✅ User can create task with category      (2.4s)
✅ Task displays in correct order          (1.8s)
✅ Drag-and-drop reorders tasks            (3.1s)
❌ Mobile touch gestures work              (FAILED)
   Element not found: [wire:sortable]
   Screenshot: /tmp/mobile-touch-fail.png

Passed: 3/4 (75%)
Failed: 1
Duration: 8.2s

Console Errors: None
Network Errors: None
```

---

### Phase 5: Performance Testing (1-2 min, optional)

**Execute Performance Tests** (if `--performance` flag):
```bash
# Load testing
ab -n 100 -c 10 https://ccs-todo.test/api/tasks

# Check:
✓ API response times (< 200ms p95)
✓ Database query performance (< 50ms avg)
✓ Memory usage (< 128MB)
✓ Stress test critical paths (100 concurrent users)
```

**Output**:
```
⚡ PERFORMANCE PROFILING
=======================
API Endpoints:
  GET /api/tasks        avg: 45ms   p95: 120ms  ✓
  POST /api/tasks       avg: 68ms   p95: 180ms  ✓
  PUT /api/tasks/{id}   avg: 52ms   p95: 150ms  ✓

Database Queries:
  Average: 12ms
  Slowest: Task::with('categories', 'tags') - 48ms

Memory Usage: 64MB (peak: 82MB)  ✓

Bottlenecks: None detected
```

---

### Phase 6: Test Report Generation (10s)

**Generate Comprehensive Report**:
```
📊 INTEGRATION TEST RESULTS
===========================
Story: STORY-XXX-NNN - [Title]
Executed: 2025-10-01 14:32:15
Duration: 5m 12s

OVERALL: 🟡 PASSING WITH WARNINGS

┌─────────────────────┬────────┬────────┬─────────┬──────────┐
│ Test Suite          │ Passed │ Failed │ Skipped │ Coverage │
├─────────────────────┼────────┼────────┼─────────┼──────────┤
│ API Integration     │   4    │   1    │    0    │   92%    │
│ Database Integration│   5    │   0    │    0    │   88%    │
│ E2E Browser         │   3    │   1    │    0    │   76%    │
│ Performance         │  N/A   │  N/A   │   N/A   │   N/A    │
├─────────────────────┼────────┼────────┼─────────┼──────────┤
│ TOTAL               │  12    │   2    │    0    │   85%    │
└─────────────────────┴────────┴────────┴─────────┴──────────┘

❌ FAILED TESTS (2):
  1. POST /api/tasks validates input
     Error: Column 'order' cannot be null
     Fix: Add default value to 'order' column in migration

  2. Mobile touch gestures work
     Error: Element not found: [wire:sortable]
     Fix: Ensure SortableJS loads on mobile viewport
     Screenshot: /tmp/mobile-touch-fail.png

⚠️  WARNINGS (1):
  - Slowest query: Task::with('categories', 'tags') - 48ms
    Consider adding indexes or reducing eager loading

✅ HIGHLIGHTS:
  ✓ All database operations working correctly
  ✓ API authentication/authorization passing
  ✓ Desktop E2E workflows functional
  ✓ Performance within acceptable ranges

📈 COVERAGE: 85% (target: 80%+)
  Lines: 342/402
  Branches: 28/35
  Functions: 45/48

🎯 NEXT STEPS:
  1. Fix: Add default order value in migration
  2. Fix: Debug mobile touch gesture handling
  3. Re-run: php artisan test --filter="failed"
  4. Then run: /sdd:story-validate
```

---

### Phase 7: Failure Handling & Auto-Fix (if failures)

**Interactive Failure Resolution**:
```
❌ 2 TEST FAILURES DETECTED

Would you like me to:
  [1] Show detailed error logs
  [2] Suggest fixes for each failure
  [3] Implement fixes automatically
  [4] Re-run failed tests only
  [5] Exit (fix manually)

Choose option [1-5]:
```

**If Option 2 (Suggest Fixes)**:
```
🔧 SUGGESTED FIXES
==================

Failure 1: POST /api/tasks validates input
  Problem: Column 'order' has no default value
  Location: database/migrations/xxx_create_tasks_table.php

  Fix:
    $table->integer('order')->default(0);

  Confidence: HIGH (common pattern)

Failure 2: Mobile touch gestures
  Problem: SortableJS not loading on mobile
  Location: resources/js/app.js

  Fix: Check Alpine.js device detection:
    if (window.isDevice('mobile') || window.isDevice('tablet')) {
      loadSortable();
    }

  Confidence: MEDIUM (requires investigation)

Apply fixes? [y/n]:
```

**If Option 3 (Auto-fix)**:
- Apply suggested fixes
- Run Pint formatting
- Re-run failed tests
- Show updated results

---

### Phase 8: Story Update (10s)

**Update Story Documentation**:
```bash
# Append to story's progress log
echo "$(date): Integration tests executed" >> /stories/development/STORY-XXX-NNN.md

# Add test results section
cat >> /stories/development/STORY-XXX-NNN.md <<EOF

## Integration Test Results ($(date +%Y-%m-%d))

**Status**: 🟡 Passing with warnings
**Duration**: 5m 12s
**Coverage**: 85%

### Test Summary
- API Integration: 4/5 passed (1 failed)
- Database Integration: 5/5 passed
- E2E Browser: 3/4 passed (1 failed)

### Failed Tests
1. POST /api/tasks validation - Fixed: Added default order value
2. Mobile touch gestures - In Progress: Debugging SortableJS loading

### Next Actions
- Fix remaining mobile touch issue
- Re-run tests
- Proceed to /sdd:story-validate

EOF
```

**Output**:
```
📝 STORY UPDATED
===============
Progress log updated: /stories/development/STORY-XXX-NNN.md
Test results recorded
Timestamp: 2025-10-01 14:37:27
```

---

## Examples

### Example 1: All Tests Pass

```bash
$ /sdd:story-test-integration

🎯 Integration Test Scope: STORY-DUE-002
   API + Database + E2E + Performance

[... test execution ...]

📊 INTEGRATION TEST RESULTS
===========================
OVERALL: ✅ ALL TESTS PASSING

Total: 15 tests passed (0 failed)
Coverage: 92%
Duration: 4m 38s

✅ Ready for /sdd:story-validate
```

### Example 2: Failures with Auto-Fix

```bash
$ /sdd:story-test-integration

[... test execution ...]

❌ 2 failures detected

Applying auto-fixes...
  ✓ Fixed migration default value
  ✓ Updated SortableJS loading

Re-running failed tests...
  ✅ POST /api/tasks validates input (FIXED)
  ✅ Mobile touch gestures work (FIXED)

📊 FINAL RESULTS: ✅ ALL TESTS PASSING
```

### Example 3: Scoped to API Only

```bash
$ /sdd:story-test-integration --scope=api

🎯 Integration Test Scope: API only

🔗 API INTEGRATION TESTS
=======================
✅ All 8 API tests passed
Duration: 1m 12s

✅ API integration validated
```

### Example 4: Performance Profiling

```bash
$ /sdd:story-test-integration --performance

[... test execution ...]

⚡ PERFORMANCE PROFILING
=======================
⚠️  Bottleneck detected:
   GET /api/tasks with 100+ categories
   Response time: 450ms (target: <200ms)

Recommendation:
  - Add pagination (limit 25 per page)
  - Cache category counts
  - Add database indexes

Would you like me to implement optimizations? [y/n]:
```

---

## Success Criteria

**Command succeeds when**:
- All integration tests pass (or auto-fixed)
- Coverage meets project threshold (typically 80%+)
- Performance within acceptable ranges
- Story progress log updated
- Detailed report generated

**Command fails when**:
- Critical test failures cannot be auto-fixed
- Coverage below minimum threshold
- Performance degradation detected
- Context files missing

---

## Output Files

**Generated Reports**:
- Story progress log updated: `/stories/development/STORY-XXX-NNN.md`
- Failure screenshots: `/tmp/test-failure-*.png` (if applicable)
- Coverage reports: `/tests/coverage/` (if `--coverage` flag)

**No New Files Created**: This command only executes tests and updates existing story documentation.

---

## Notes

- **Execution Time**: Varies by test scope (3-8 minutes typical)
- **Auto-Fix**: Attempts common fixes automatically (with confirmation)
- **Mobile Testing**: Tests responsive design on mobile viewports
- **Performance**: Optional profiling with `--performance` flag
- **Parallel Execution**: Use `--parallel=N` for faster execution
- **Browser Choice**: Defaults to Chrome, supports Firefox/Safari

**Best Practices**:
1. Run `/sdd:story-quick-check` first for fast validation
2. Fix obvious issues before integration tests
3. Use `--scope` to test specific areas during development
4. Run full suite before moving to `/sdd:story-validate`
5. Review performance metrics for critical paths

**Next Steps After Success**:
```bash
✅ Integration tests passing → /sdd:story-validate
⚠️  Minor warnings → Fix, re-run, then /sdd:story-validate
❌ Critical failures → Fix issues, re-run this command
```