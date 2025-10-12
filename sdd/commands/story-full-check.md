# /sdd:story-full-check

Comprehensive 5-minute validation suite for production-ready quality assurance.

---

## Meta

**Category**: Testing & Validation
**Format**: Imperative (Comprehensive)
**Execution Time**: 4-6 minutes
**Prerequisites**: Story in `/docs/stories/development/` or `/docs/stories/review/`
**Destructive**: No (read-only analysis)

**Related Commands**:
- `/sdd:story-quick-check` - Fast 30s validation (run first)
- `/sdd:story-test-integration` - Integration + E2E tests only
- `/sdd:story-validate` - Final story validation before ship

**Context Requirements**:
- `/docs/project-context/technical-stack.md` (validation tools)
- `/docs/project-context/coding-standards.md` (compliance rules)
- `/docs/project-context/development-process.md` (quality gates)

---

## Parameters

**Validation Scope**:
```bash
# Full comprehensive check (default)
/sdd:story-full-check

# Scoped validation
--scope=tests|quality|security|performance|all  # Default: all
--story-id=STORY-XXX-NNN                        # Specific story
--export                                        # Save report to file
--compare=<commit-hash>                         # Compare with previous state
```

**Test Configuration**:
```bash
--coverage                   # Generate coverage reports
--browsers=chrome,firefox    # Multi-browser E2E testing
--parallel=N                 # Parallel execution (default: 4)
--strict                     # Fail on warnings (production mode)
```

**Examples**:
```bash
/sdd:story-full-check                                # Full 5min check
/sdd:story-full-check --export                       # Save detailed report
/sdd:story-full-check --scope=tests --coverage       # Tests + coverage only
/sdd:story-full-check --compare=abc123 --strict      # Compare + strict mode
```

---

## Process

### Phase 1: Full Test Suite (2-3 min)

**Execute All Tests**:
```bash
# Run comprehensive test suite
php artisan test --parallel --coverage

# Includes:
✓ Unit tests (all)
✓ Feature tests (all)
✓ Integration tests (API, database)
✓ Browser tests (E2E workflows)
```

**Output**:
```
🧪 COMPREHENSIVE TESTING
========================

Unit Tests
  ✅ 24/24 passed                          (0.8s)
  Coverage: 94%

Feature Tests
  ✅ 18/18 passed                          (2.1s)
  Coverage: 88%

Integration Tests
  🔗 API: 12/12 passed                     (1.4s)
  💾 Database: 8/8 passed                  (0.6s)
  Coverage: 85%

Browser Tests (Chrome)
  🌐 E2E: 6/7 passed, 1 skipped            (12.3s)
  ⚠️  Skipped: Safari-specific test
  Coverage: 76%

┌──────────────────┬────────┬────────┬─────────┬──────────┐
│ Test Type        │ Passed │ Failed │ Skipped │ Coverage │
├──────────────────┼────────┼────────┼─────────┼──────────┤
│ Unit             │   24   │   0    │    0    │   94%    │
│ Feature          │   18   │   0    │    0    │   88%    │
│ Integration      │   20   │   0    │    0    │   85%    │
│ Browser          │    6   │   0    │    1    │   76%    │
├──────────────────┼────────┼────────┼─────────┼──────────┤
│ TOTAL            │   68   │   0    │    1    │   87%    │
└──────────────────┴────────┴────────┴─────────┴──────────┘

Overall Coverage: 87% (target: 80%+)  ✅
  Lines: 1,247/1,432
  Branches: 94/112
  Functions: 156/178

Duration: 17.2s
Status: ✅ ALL TESTS PASSING
```

---

### Phase 2: Code Quality Analysis (1 min)

**Static Analysis**:
```bash
# Laravel Pint (formatting)
vendor/bin/pint --test

# PHPStan (static analysis) - if configured
vendor/bin/phpstan analyse

# Check:
✓ Code formatting
✓ Type safety
✓ Complexity metrics
✓ Duplicate code detection
```

**Output**:
```
📊 CODE QUALITY ANALYSIS
========================

Code Formatting (Pint)
  ✅ All files PSR-12 compliant
  ✅ No style violations

Static Analysis
  ⚠️  3 warnings found
    1. TaskManager::updateOrder() - Missing return type
       Location: app/Livewire/TaskManager.php:87
    2. Category::tasks() - @param missing
       Location: app/Models/Category.php:42
    3. Unused variable $order
       Location: app/Http/Controllers/TaskController.php:23

Complexity Metrics
  ✅ Cyclomatic complexity: 4.2 avg (target: <10)
  ✅ Cognitive complexity: 6.8 avg (target: <15)
  ✅ No files over threshold

  Highest complexity:
    TaskManager::reorderTasks() - Complexity: 8

Code Duplication
  ✅ No duplicate code blocks detected
  ✅ Similar code: 2 locations (acceptable)
    - Task creation in TaskManager vs TaskController
    - Recommendation: Extract to service class

Dependencies
  ✅ All dependencies up to date
  ✅ No vulnerabilities detected
  ✅ No unused dependencies

Quality Score: B+ (88/100)
```

---

### Phase 3: Performance Profiling (30-60s)

**Build & Runtime Metrics**:
```bash
# Frontend build analysis
npm run build -- --analyze

# Backend profiling
php artisan route:list --compact
php artisan optimize

# Check:
✓ Build size and timing
✓ Route efficiency
✓ Query performance
✓ Memory usage
```

**Output**:
```
⚡ PERFORMANCE PROFILING
========================

Frontend Build
  Bundle size: 248 KB (gzipped: 82 KB)  ✅
  Build time: 4.2s
  Chunks:
    - app.js: 156 KB
    - vendor.js: 92 KB

  Compared to baseline:
    Bundle: +8 KB (+3.3%)
    Build: -0.3s (faster)

Backend Performance
  Routes: 24 registered
  Avg response time: 45ms  ✅

Database Queries
  Average: 12ms
  Slowest: Task::with('categories', 'tags') - 48ms
  N+1 queries: None detected  ✅

Memory Usage
  Average: 48 MB
  Peak: 72 MB  ✅
  Target: < 128 MB

Page Load Metrics (E2E)
  Initial load: 680ms  ✅
  Time to interactive: 920ms  ✅
  First contentful paint: 340ms  ✅

Performance Grade: A (94/100)

⚠️  Recommendations:
  - Consider lazy loading categories for large lists
  - Add index on tasks.order column for sorting
```

---

### Phase 4: Security Audit (30s)

**Security Scanning**:
```bash
# Dependency vulnerabilities
composer audit

# Laravel security checks
php artisan config:cache --check
php artisan route:cache --check

# Check:
✓ Dependency vulnerabilities
✓ Exposed secrets (.env validation)
✓ CSRF protection
✓ SQL injection prevention
```

**Output**:
```
🔒 SECURITY AUDIT
=================

Dependency Vulnerabilities
  ✅ 0 vulnerabilities found
  Last scan: 2025-10-01 14:45:22

Code Security
  ✅ No exposed secrets detected
  ✅ CSRF protection enabled
  ✅ SQL injection prevention (Eloquent ORM)
  ✅ XSS protection enabled

Laravel Security
  ✅ Debug mode: OFF (production)
  ✅ APP_KEY set and secure
  ✅ HTTPS enforced
  ✅ Session secure: true

Authentication
  ✅ Password hashing: bcrypt
  ✅ Rate limiting: configured
  ✅ Authorization policies: implemented

⚠️  Recommendations:
  - Enable Content Security Policy headers
  - Add rate limiting to API endpoints
  - Consider implementing 2FA

Security Score: A- (92/100)
```

---

### Phase 5: Standards Compliance (30s)

**Validate Against Project Standards**:
```bash
# Load coding standards
source /docs/project-context/coding-standards.md

# Check:
✓ TALL stack conventions
✓ Naming conventions
✓ File organization
✓ Error handling patterns
✓ Accessibility requirements
```

**Output**:
```
📐 STANDARDS COMPLIANCE
=======================

TALL Stack Conventions
  ✅ Livewire components properly structured
  ✅ Alpine.js patterns followed
  ✅ Tailwind utility-first approach
  ✅ Laravel best practices

Naming Conventions
  ✅ Models: PascalCase
  ✅ Controllers: PascalCase + Controller suffix
  ✅ Routes: kebab-case
  ✅ Variables: camelCase

File Organization
  ✅ PSR-4 autoloading
  ✅ Livewire components in App\Livewire
  ✅ Tests mirror app structure
  ✅ Resources organized by type

Error Handling
  ✅ Try-catch blocks where needed
  ✅ Validation using Form Requests
  ✅ User-friendly error messages
  ⚠️  Missing error logging in TaskManager::delete()

Accessibility (WCAG AA)
  ✅ Semantic HTML
  ✅ ARIA attributes present
  ✅ Keyboard navigation
  ✅ Color contrast: 4.5:1+
  ✅ Focus indicators

Responsive Design
  ✅ Mobile-first approach
  ✅ Touch targets: 44px min
  ✅ Viewport meta tag
  ✅ Fluid typography

Compliance Score: A (96/100)

⚠️  Minor Issues:
  - Add error logging to deletion operations
  - Document API endpoints in OpenAPI spec
```

---

### Phase 6: Documentation Check (20s)

**Documentation Validation**:
```bash
# Check documentation completeness
ls -la README.md CHANGELOG.md

# Check inline docs
grep -r "@param" app/ | wc -l
grep -r "@return" app/ | wc -l

# Check:
✓ README completeness
✓ Inline PHPDoc blocks
✓ Story documentation
✓ API documentation
```

**Output**:
```
📚 DOCUMENTATION CHECK
======================

Project Documentation
  ✅ README.md: Present and updated
  ✅ CHANGELOG.md: Updated with v1.3.0
  ⚠️  API documentation: Missing OpenAPI spec

Story Documentation
  ✅ Story file: Complete with acceptance criteria
  ✅ Progress log: Updated
  ✅ Test results: Documented

Code Documentation
  ✅ PHPDoc blocks: 156/178 methods (88%)
  ⚠️  Missing @param: 14 methods
  ⚠️  Missing @return: 8 methods

  Classes needing docs:
    - TaskManager::updateOrder() (missing @param)
    - Category::tasks() (missing @return)

Inline Comments
  ✅ Complex logic documented
  ✅ TODOs tracked: 3 found
    - TODO: Add pagination to large lists
    - TODO: Implement caching for categories
    - TODO: Add bulk operations

Documentation Score: B+ (87/100)

Recommendations:
  - Add PHPDoc to remaining 22 methods
  - Generate OpenAPI spec for API endpoints
  - Document environment variables
```

---

### Phase 7: Generate Full Report (10s)

**Comprehensive Validation Report**:
```
📋 FULL VALIDATION REPORT
=========================
Story: STORY-DUE-002 - Due Date Management
Validated: 2025-10-01 14:48:35
Duration: 4 minutes 52 seconds

OVERALL GRADE: A- (91/100)
STATUS: ✅ READY FOR PRODUCTION

┌─────────────────────┬───────┬────────┬──────────────┐
│ Validation Area     │ Score │ Status │ Grade        │
├─────────────────────┼───────┼────────┼──────────────┤
│ Test Suite          │ 100%  │   ✅   │ A+           │
│ Code Quality        │  88%  │   ✅   │ B+           │
│ Performance         │  94%  │   ✅   │ A            │
│ Security            │  92%  │   ✅   │ A-           │
│ Standards           │  96%  │   ✅   │ A            │
│ Documentation       │  87%  │   ⚠️   │ B+           │
├─────────────────────┼───────┼────────┼──────────────┤
│ OVERALL             │  91%  │   ✅   │ A-           │
└─────────────────────┴───────┴────────┴──────────────┘

✅ HIGHLIGHTS (23):
  ✓ All 68 tests passing (1 skipped)
  ✓ Test coverage: 87% (exceeds 80% target)
  ✓ No security vulnerabilities
  ✓ Performance within targets
  ✓ WCAG AA accessibility compliant
  ✓ Mobile-responsive design validated
  ✓ No N+1 query issues
  ✓ Code formatting compliant (Pint)
  ✓ All dependencies up to date
  ✓ CSRF/XSS protection enabled
  ... (13 more)

⚠️  WARNINGS (8):
  1. Missing return type: TaskManager::updateOrder()
     Priority: LOW | Fix time: 2 min
     Impact: Type safety, IDE autocomplete

  2. Missing @param docs: 14 methods
     Priority: LOW | Fix time: 10 min
     Impact: Developer experience

  3. Bundle size +8KB from baseline
     Priority: LOW | Fix time: N/A
     Impact: Acceptable growth for new features

  4. Missing OpenAPI spec for API
     Priority: MEDIUM | Fix time: 30 min
     Impact: API documentation

  ... (4 more)

❌ FAILURES (0):
  None - all critical checks passed!

📈 COMPARED TO LAST CHECK (STORY-DUE-001):
  Improved:
    ✓ Test coverage: 83% → 87% (+4%)
    ✓ Performance: B → A (response times -12ms)
    ✓ Code quality: B → B+ (complexity reduced)

  Degraded:
    ⚠️  Bundle size: 240KB → 248KB (+3.3%)
    ⚠️  Documentation: A- → B+ (new code needs docs)

  Maintained:
    → Security: A- (consistent)
    → Standards: A (consistent)

🎯 ACTION ITEMS (Prioritized):

  PRIORITY 1: MUST FIX BEFORE SHIP
    (None)

  PRIORITY 2: SHOULD FIX BEFORE REVIEW
    1. Add OpenAPI spec for API endpoints (30 min)
       Benefit: Better API documentation for consumers

    2. Add missing PHPDoc blocks (10 min)
       Benefit: Improved code maintainability

  PRIORITY 3: CONSIDER FOR FUTURE
    1. Implement lazy loading for large category lists
       Benefit: Performance optimization for edge cases

    2. Add Content Security Policy headers
       Benefit: Enhanced security posture

    3. Implement API rate limiting
       Benefit: Prevent abuse, improve stability

✅ PRODUCTION READINESS: YES
   All critical checks passed. Minor warnings acceptable.

🎯 NEXT STEPS:
  1. (Optional) Fix Priority 2 warnings
  2. Run /sdd:story-validate for final sign-off
  3. Move to /docs/stories/qa/ for final QA
  4. Ship to production

VALIDATION CONFIDENCE: HIGH (91%)
```

---

### Phase 8: Export Report (if --export flag)

**Save Detailed Report**:
```bash
# Create report file
mkdir -p /reports
cat > /reports/full-check-$(date +%Y%m%d-%H%M%S).md <<EOF
[... full report content ...]
EOF

# Output location
echo "Report saved: /reports/full-check-20251001-144835.md"
```

**Output**:
```
📄 REPORT EXPORTED
==================
Location: /reports/full-check-20251001-144835.md
Size: 24 KB
Format: Markdown

Report includes:
  ✓ Detailed test results
  ✓ Code quality metrics
  ✓ Performance benchmarks
  ✓ Security findings
  ✓ Compliance checklist
  ✓ Action items with priorities
  ✓ Historical comparison

Share with: git add reports/ && git commit -m "Add validation report"
```

---

## Examples

### Example 1: Perfect Score

```bash
$ /sdd:story-full-check

[... full validation ...]

📋 FULL VALIDATION REPORT
=========================
OVERALL GRADE: A+ (98/100)
STATUS: ✅ PRODUCTION READY

✅ All checks passed
⚠️  0 warnings
❌ 0 failures

🎯 NEXT STEPS:
  Run /sdd:story-validate → Ship to production

VALIDATION CONFIDENCE: VERY HIGH (98%)
```

### Example 2: Warnings Present

```bash
$ /sdd:story-full-check

[... full validation ...]

OVERALL GRADE: B+ (86/100)
STATUS: ⚠️  READY WITH WARNINGS

✅ 65 highlights
⚠️  12 warnings (8 low, 4 medium priority)
❌ 0 critical failures

🎯 RECOMMENDED ACTIONS:
  1. Fix 4 medium-priority warnings (est. 45 min)
  2. Re-run /sdd:story-full-check
  3. Then proceed to /sdd:story-validate

Accept warnings and ship? [y/n]:
```

### Example 3: Comparison Mode

```bash
$ /sdd:story-full-check --compare=abc123

[... full validation ...]

📈 COMPARED TO abc123:
  Improved:
    ✓ Test coverage: 78% → 87%
    ✓ Performance: C+ → A
    ✓ Security: B → A-

  Degraded:
    ⚠️  Code quality: A → B+ (new complex logic)
    ⚠️  Bundle size: +12KB

Net change: +8 points (improvement)
```

### Example 4: Export Report

```bash
$ /sdd:story-full-check --export

[... full validation ...]

📄 REPORT EXPORTED
==================
Location: /reports/full-check-20251001-144835.md

View report:
  cat /reports/full-check-20251001-144835.md

Share report:
  git add reports/ && git commit -m "Add validation"
```

### Example 5: Scoped Check (Tests Only)

```bash
$ /sdd:story-full-check --scope=tests --coverage

🧪 COMPREHENSIVE TESTING
========================
[... test results ...]

Coverage Report: /tests/coverage/index.html

OVERALL: ✅ ALL TESTS PASSING
Skipping: quality, security, performance, docs

Run full check: /sdd:story-full-check (no --scope)
```

---

## Success Criteria

**Command succeeds when**:
- All validation phases complete within 6 minutes
- Comprehensive report generated (grade A-F)
- Action items prioritized (P1, P2, P3)
- Clear production readiness verdict
- Historical comparison available

**Grade Scale**:
- **A+ (95-100%)**: Exceptional, production-ready
- **A (90-94%)**: Excellent, minor improvements
- **B (80-89%)**: Good, address warnings
- **C (70-79%)**: Acceptable, fix medium-priority issues
- **D (60-69%)**: Poor, significant issues
- **F (<60%)**: Failing, critical issues

**Command fails when**:
- Context files missing
- Critical test failures
- Security vulnerabilities detected
- Performance significantly degraded

---

## Output Files

**Generated Reports** (if `--export`):
- Full validation report: `/reports/full-check-YYYYMMDD-HHMMSS.md`
- Coverage report: `/tests/coverage/index.html` (if `--coverage`)
- Performance profile: `/reports/performance-YYYYMMDD.json` (if profiling enabled)

**No New Files** (default): Updates existing story documentation only

---

## Notes

- **Execution Time**: 4-6 minutes (varies by project size)
- **Comprehensive**: Includes all validation aspects (tests, quality, security, performance, standards, docs)
- **Production Gate**: Validates story is production-ready
- **Historical Tracking**: Compares against previous checks
- **Actionable**: Prioritized action items with fix time estimates

**Best Practices**:
1. Run `/sdd:story-quick-check` before this (catch obvious issues fast)
2. Run before moving story to `/docs/stories/review/`
3. Use `--export` for documentation trail
4. Use `--compare` to track quality improvements
5. Address P1 (must fix) and P2 (should fix) items before ship

**When to Use**:
- ✅ Before code review (move to `/docs/stories/review/`)
- ✅ Before final validation (`/sdd:story-validate`)
- ✅ After major refactoring
- ✅ Before production deployment
- ✅ Weekly quality check for long-running stories

**When NOT to Use**:
- ❌ During active development (use `/sdd:story-quick-check`)
- ❌ For quick validation (use `/sdd:story-quick-check`)
- ❌ Multiple times per day (too slow)

**Next Steps After Success**:
```bash
A+ (95-100%) → /sdd:story-validate → Ship
A  (90-94%)  → /sdd:story-validate → Ship (minor improvements optional)
B  (80-89%)  → Fix P2 warnings → Re-run → /sdd:story-validate
C  (70-79%)  → Fix P1+P2 issues → Re-run
D-F (<70%)   → Fix critical issues → Re-run entire workflow
```

**Quick Reference**:
```bash
# Fast check first (30s)
/sdd:story-quick-check

# Then comprehensive validation (5min)
/sdd:story-full-check

# Fix issues, then final validation
/sdd:story-validate
```