# /sdd:story-qa

## Meta
- Version: 2.0
- Category: quality-gates
- Complexity: high
- Purpose: Move story to QA stage and execute comprehensive test validation pipeline

## Definition
**Purpose**: Execute comprehensive automated QA test suite including unit, integration, browser, and performance tests before final validation.

**Syntax**: `/sdd:story-qa [story_id]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| story_id | string | No | current branch | Story ID (STORY-YYYY-NNN) | Must match format STORY-YYYY-NNN |

## INSTRUCTION: Execute Story QA

### INPUTS
- story_id: Story identifier (auto-detected from branch if not provided)
- Project context from `/project-context/` directory
- Story file from `/stories/review/[story-id].md`
- Complete test suite (unit, feature, browser)
- Performance benchmarks (if defined)

### PROCESS

#### Phase 1: Project Context Loading
1. **CHECK** if `/project-context/` directory exists
2. IF missing:
   - SUGGEST running `/sdd:project-init` first
   - EXIT with initialization guidance
3. **LOAD** project-specific QA requirements from:
   - `/project-context/technical-stack.md` - Testing tools and frameworks
   - `/project-context/coding-standards.md` - QA standards and thresholds
   - `/project-context/development-process.md` - QA stage requirements

#### Phase 2: Story Identification & Validation
1. IF story_id NOT provided:
   - **DETECT** current git branch
   - **EXTRACT** story ID from branch name
   - EXAMPLE: Branch `feature/STORY-2025-001-auth` → ID `STORY-2025-001`

2. **VALIDATE** story exists:
   - CHECK `/stories/review/[story-id].md` exists
   - IF NOT found in review:
     - CHECK if already in `/stories/qa/`
     - INFORM user and ask to proceed with re-QA
   - IF in development:
     - ERROR: "Story must pass review first"
     - SUGGEST: `/sdd:story-review [story-id]`
   - IF NOT found anywhere:
     - ERROR: "Story [story-id] not found"
     - EXIT with guidance

3. **READ** story file for:
   - Current status
   - Success criteria (will map to browser tests)
   - Implementation checklist state
   - QA checklist requirements

#### Phase 3: Directory Preparation
1. **ENSURE** `/stories/qa/` directory exists
   - CREATE directory if missing
   - ADD `.gitkeep` file if directory was created

2. **MOVE** story file:
   - FROM: `/stories/review/[story-id].md`
   - TO: `/stories/qa/[story-id].md`
   - PRESERVE all content and formatting

3. **UPDATE** story metadata:
   - Change status from "review" to "qa"
   - KEEP existing dates and branch information
   - ADD QA start timestamp to progress log

#### Phase 4: Test Suite Execution

##### 4.1 Unit Tests (Discovered Framework)
1. **IDENTIFY** unit test framework from technical-stack.md:
   - PHP/Laravel: Pest, PHPUnit
   - Node.js: Jest, Vitest, Mocha
   - Python: pytest, unittest
   - Go: go test
   - Java: JUnit, TestNG
   - .NET: xUnit, NUnit, MSTest

2. **RUN** unit tests with coverage:
   ```bash
   # Example for Laravel Pest:
   vendor/bin/pest --filter=Unit --coverage --min=80

   # Example for Node.js Jest:
   npm test -- --coverage --testPathPattern=unit

   # Example for Python pytest:
   pytest tests/unit/ --cov --cov-report=term-missing
   ```

3. **CAPTURE** results:
   - PASS/FAIL count
   - Execution time
   - Coverage percentage (overall, per file)
   - Failed test details with stack traces
   - Slowest tests (performance indicators)

##### 4.2 Feature/Integration Tests (Discovered Patterns)
1. **IDENTIFY** integration test patterns from technical-stack.md:
   - Laravel: Feature tests with database interactions
   - Node.js: Integration tests with API calls
   - Python: Integration tests with service layer
   - Java: Integration tests with Spring context

2. **RUN** integration tests:
   ```bash
   # Example for Laravel Pest:
   vendor/bin/pest --filter=Feature --parallel

   # Example for Node.js:
   npm test -- --testPathPattern=integration

   # Example for Python:
   pytest tests/integration/ -v
   ```

3. **VALIDATE** integrations:
   - API endpoints returning correct responses
   - Database operations (CRUD, transactions)
   - Service-to-service communication
   - External API integrations (with mocks/stubs)
   - Queue/job processing
   - Cache operations

##### 4.3 Browser/E2E Tests (Discovered Browser Testing Tools)
1. **IDENTIFY** browser testing framework from technical-stack.md:
   - Laravel: Laravel Dusk, Pest Browser
   - Node.js: Playwright, Cypress, Puppeteer
   - Python: Playwright, Selenium
   - Java: Selenium, Playwright

2. **LOCATE** browser test files:
   - Laravel: `tests/Browser/[StoryId]Test.php`
   - Node.js: `tests/e2e/[story-id].spec.js`
   - Python: `tests/browser/test_[story_id].py`
   - Java: `src/test/java/**/[StoryId]Test.java`

3. **RUN** browser tests:
   ```bash
   # Example for Laravel Pest Browser:
   vendor/bin/pest --filter=Browser

   # Example for Playwright (Node.js):
   npx playwright test tests/e2e/sdd:story-2025-001

   # Example for Python Playwright:
   pytest tests/browser/test_story_2025_001.py --headed
   ```

4. **VALIDATE** against Success Criteria:
   - MAP each acceptance criterion to browser test
   - VERIFY each criterion has passing test
   - CAPTURE screenshots of test execution
   - RECORD video of test runs (if tool supports)
   - VALIDATE all user workflows end-to-end

5. **TEST** across environments (if specified in standards):
   - Different browsers (Chrome, Firefox, Safari)
   - Different devices (desktop, tablet, mobile)
   - Different viewports (responsive design)
   - Light/dark mode (if applicable)

##### 4.4 Performance Tests (Discovered Performance Tools)
1. **CHECK** if performance requirements defined in story
2. IF performance criteria exist:
   - **IDENTIFY** performance tools from technical-stack.md:
     * Laravel: Laravel Debugbar, Telescope, Blackfire
     * Node.js: Artillery, k6, Apache Bench
     * Python: Locust, pytest-benchmark
     * Java: JMeter, Gatling

3. **RUN** performance benchmarks:
   ```bash
   # Example for Laravel:
   php artisan serve &
   ab -n 1000 -c 10 http://localhost:8000/api/endpoint

   # Example for Node.js k6:
   k6 run performance/sdd:story-2025-001.js
   ```

4. **VALIDATE** performance targets:
   - Response time < target (e.g., 200ms)
   - Throughput > target (e.g., 100 req/sec)
   - Memory usage < target
   - No memory leaks
   - Database query count optimal

##### 4.5 Security Testing (Discovered Security Tools)
1. **RUN** security validation:
   ```bash
   # Example for Laravel:
   composer audit

   # Example for Node.js:
   npm audit --production
   ```

2. **VALIDATE** security requirements:
   - No HIGH/CRITICAL vulnerabilities
   - Authentication/Authorization working
   - CSRF protection enabled
   - XSS prevention implemented
   - SQL injection prevention verified
   - Rate limiting functional (if applicable)

#### Phase 5: Quality Gate Validation
1. **APPLY** quality gates from coding-standards.md:
   - BLOCK progression if ANY critical test fails
   - BLOCK progression if coverage below threshold
   - BLOCK progression if performance targets not met
   - BLOCK progression if security vulnerabilities found

2. **CAPTURE** test artifacts:
   - Test reports (XML, JSON, HTML)
   - Coverage reports
   - Screenshots from browser tests
   - Videos from browser tests (if available)
   - Performance benchmark results
   - Log files from test runs

#### Phase 6: QA Report Generation
1. **COMPILE** all test results
2. **GENERATE** automated QA report:

```
✅ AUTOMATED QA RESULTS
════════════════════════════════════════════════
Story: [STORY-ID] - [Title]
Stack: [Discovered Framework/Language/Tools]
QA Executed: [Timestamp]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 FUNCTIONAL TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Acceptance Criteria: 5/5 verified by browser tests
   ✓ User can toggle dark mode → tests/Browser/DarkModeTest.php::line 45
   ✓ Theme persists on refresh → tests/Browser/DarkModeTest.php::line 67
   ✓ All components support dark mode → tests/Browser/DarkModeTest.php::line 89
   ✓ Keyboard shortcut works → tests/Browser/DarkModeTest.php::line 112
   ✓ Preference syncs across tabs → tests/Browser/DarkModeTest.php::line 134

📸 Screenshots: /storage/screenshots/sdd:story-2025-003/
🎥 Videos: /storage/videos/sdd:story-2025-003/ (if applicable)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧪 UNIT TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Tests Passed: 45/45 (100%)
✅ Coverage: 87% (target: 80%)
⏱️  Execution Time: 2.34s

Top Coverage Files:
  ✓ DarkModeService.php: 95%
  ✓ ThemeController.php: 92%
  ✓ UserPreferenceRepository.php: 88%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 INTEGRATION TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Feature Tests: 23/23 passed
   ✓ API endpoints: 8/8 passed
   ✓ Database operations: 10/10 passed
   ✓ Service integrations: 5/5 passed

Operations Tested:
  ✓ GET /api/user/theme → 200 OK (45ms)
  ✓ POST /api/user/theme → 200 OK (67ms)
  ✓ Theme preference persisted to database
  ✓ Cache invalidation on theme change

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌐 COMPATIBILITY TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Browsers: Chrome, Firefox, Safari (all passed)
✅ Devices: Desktop (1920x1080), Tablet (768x1024), Mobile (375x667)
✅ Viewports: All responsive breakpoints validated

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡ PERFORMANCE TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Response Times: Within targets
   ✓ Theme toggle: 45ms (target: <100ms)
   ✓ Initial page load: 234ms (target: <500ms)
✅ Throughput: 250 req/sec (target: >100 req/sec)
✅ Memory: Stable (no leaks detected)
✅ Database Queries: Optimized (N+1 prevented)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 SECURITY TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Vulnerability Scan: No issues (composer audit)
✅ Authentication: All protected routes secure
✅ CSRF Protection: Enabled and functional
✅ XSS Prevention: Input sanitization verified
✅ Rate Limiting: 60 requests/minute enforced

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ALL QUALITY GATES PASSED

Total Tests: 76/76 passed
Total Coverage: 87%
Total Execution Time: 45.67s
Browser Test Coverage: 100% of acceptance criteria
Performance: All targets met
Security: No vulnerabilities
```

#### Phase 7: Story File Updates
1. **UPDATE** QA Checklist based on test results:

   **FUNCTIONAL TESTING:**
   - `[x]` Each acceptance criterion validated by browser tests
   - `[x]` All user workflows tested end-to-end
   - `[x]` Error scenarios handled gracefully
   - `[x]` Edge cases covered

   **INTEGRATION TESTING:**
   - `[x]` API endpoints return correct responses
   - `[x]` Database operations work correctly
   - `[x]` Service integrations functional
   - `[x]` External APIs integrated properly

   **COMPATIBILITY TESTING:**
   - `[x]` Works across target browsers
   - `[x]` Responsive on all devices
   - `[x]` Accessible via keyboard
   - `[x]` Screen reader compatible

   **PERFORMANCE TESTING:**
   - `[x]` Response times within targets
   - `[x]` No memory leaks
   - `[x]` Optimized database queries
   - `[x]` Bundle size acceptable

   **REGRESSION TESTING:**
   - `[x]` Existing features still work
   - `[x]` No unintended side effects

   **SECURITY TESTING:**
   - `[x]` No vulnerabilities introduced
   - `[x]` Authentication/Authorization working
   - `[x]` Input validation functional

2. **UPDATE** Implementation Checklist remaining items:
   - `[x]` Browser tests (if now at 100% acceptance criteria coverage)
   - `[x]` Documentation (if QA revealed complete docs)

3. **ADD** to Progress Log:
   ```markdown
   - [Today]: Moved to QA stage
   - [Today]: Executed comprehensive test suite
     * Unit tests: 45/45 passed (87% coverage)
     * Feature tests: 23/23 passed
     * Browser tests: 8/8 passed (100% criteria coverage)
     * Performance: All targets met
     * Security: No vulnerabilities
   - [Today]: All quality gates PASSED
   ```

4. **RECORD** test artifacts:
   - Test report locations
   - Screenshot/video paths
   - Coverage report path
   - Performance benchmark results

#### Phase 8: Next Steps
1. **DETERMINE** QA outcome:
   - IF all tests PASS → Ready for `/sdd:story-validate`
   - IF any critical failures → Requires `/sdd:story-refactor`
   - IF performance issues → Optimize and re-run QA

2. **DISPLAY** next actions:
   ```
   💡 NEXT STEPS:
   ════════════════════════════════════════════════

   [IF ALL PASSED:]
   ✅ All QA tests passed - Ready for validation
   1. /sdd:story-validate [story-id]     # Final validation before ship
   2. /sdd:story-ship [story-id]         # Deploy to production (after validation)

   [IF FAILURES:]
   ⚠️ X test(s) failed
   1. /sdd:story-refactor [story-id]     # Return to development
   2. Fix failing tests:
      - [Test 1 that failed]
      - [Test 2 that failed]
   3. /sdd:story-review [story-id]       # Re-run review
   4. /sdd:story-qa [story-id]           # Re-run QA after fixes

   [ARTIFACT LOCATIONS:]
   📸 Screenshots: /storage/screenshots/[story-id]/
   🎥 Videos: /storage/videos/[story-id]/
   📊 Coverage: /storage/coverage/[story-id]/
   📈 Performance: /storage/benchmarks/[story-id]/
   ```

3. **SHOW** debugging commands for discovered stack:
   ```bash
   # Laravel:
   vendor/bin/pest --filter=Browser --parallel=false  # Run browser tests sequentially
   vendor/bin/pest --filter=Feature::testName         # Run specific test
   php artisan telescope:prune                         # Clear performance logs

   # Node.js Playwright:
   npx playwright test --debug                         # Debug mode
   npx playwright show-report                          # View HTML report
   npx playwright codegen                              # Generate new test code

   # Python Pytest:
   pytest tests/browser/ -v -s                         # Verbose with print output
   pytest tests/browser/ --headed --slowmo=1000        # Visual debugging
   ```

### OUTPUTS
- `/stories/qa/[story-id].md` - Updated story file with QA results
- Automated QA report (displayed to user)
- Test artifacts (screenshots, videos, reports)
- Updated QA Checklist with validation status
- Progress log entry with QA timestamp

### RULES
- MUST load project context before running any tests
- MUST use discovered testing tools from technical-stack.md
- MUST validate against coding-standards.md thresholds
- MUST move story file from review to qa
- MUST run ALL test types (unit, feature, browser)
- MUST validate 100% of acceptance criteria via browser tests
- SHOULD capture test artifacts for documentation
- SHOULD test across browsers/devices if specified
- NEVER skip browser tests (critical for acceptance criteria)
- NEVER allow QA to pass if critical tests fail
- ALWAYS block progression if quality gates fail
- ALWAYS update checklist items accurately
- ALWAYS record test artifact locations

## Examples

### Example 1: QA with All Tests Passing
```bash
INPUT:
/sdd:story-qa STORY-2025-003

OUTPUT:
→ Loading project context...
  ✓ technical-stack.md: Laravel + Pest + Playwright
  ✓ coding-standards.md: 80% coverage, all browsers
  ✓ development-process.md: QA requirements

→ Moving story to QA...
  ✓ Moved STORY-2025-003.md to /stories/qa/

→ Executing test suite...
  [Unit Tests] Running Pest...
    ✓ 45/45 passed (87% coverage) - 2.34s

  [Feature Tests] Running Pest...
    ✓ 23/23 passed - 5.67s

  [Browser Tests] Running Pest Browser...
    ✓ 8/8 passed - 34.21s
    ✓ All 5 acceptance criteria validated
    📸 Screenshots saved to /storage/screenshots/STORY-2025-003/

  [Performance] Running benchmarks...
    ✓ Theme toggle: 45ms (target: <100ms)
    ✓ Page load: 234ms (target: <500ms)

  [Security] Running Composer audit...
    ✓ No vulnerabilities

✅ AUTOMATED QA RESULTS
════════════════════════════════════════════════
Story: STORY-2025-003 - Dark Mode Toggle
Stack: Laravel 12, Livewire 3, Pest 4, Playwright
QA Executed: 2025-10-01 16:45:23

✅ ALL QUALITY GATES PASSED

Total Tests: 76/76 passed
Total Coverage: 87%
Browser Test Coverage: 100% of acceptance criteria
Performance: All targets met
Security: No vulnerabilities

💡 NEXT STEPS:
════════════════════════════════════════════════
✅ All QA tests passed - Ready for validation
1. /sdd:story-validate STORY-2025-003     # Final validation before ship
2. /sdd:story-ship STORY-2025-003         # Deploy to production (after validation)
```

### Example 2: QA with Browser Test Failures
```bash
INPUT:
/sdd:story-qa

OUTPUT:
→ Detecting story from current branch...
  ✓ Current branch: feature/STORY-2025-004-notifications
  ✓ Story ID: STORY-2025-004

→ Loading project context...
  ✓ technical-stack.md loaded

→ Moving story to QA...
  ✓ Moved STORY-2025-004.md to /stories/qa/

→ Executing test suite...
  [Unit Tests] Running Pest...
    ✓ 32/32 passed (92% coverage) - 1.87s

  [Feature Tests] Running Pest...
    ✓ 18/18 passed - 4.23s

  [Browser Tests] Running Pest Browser...
    ✗ 2/5 passed - 3 failed
    ✗ Failed tests:
      - NotificationTest::test_notification_appears
      - NotificationTest::test_notification_dismisses
      - NotificationTest::test_notification_persistence

✅ AUTOMATED QA RESULTS
════════════════════════════════════════════════
Story: STORY-2025-004 - Notification System
Stack: Laravel 12, Pest 4, Playwright
QA Executed: 2025-10-01 17:12:45

❌ QUALITY GATES FAILED

Unit Tests: ✅ 32/32 passed
Feature Tests: ✅ 18/18 passed
Browser Tests: ❌ 2/5 passed (3 failed)
Acceptance Criteria Coverage: 40% (2/5 criteria validated)

❌ BLOCKING ISSUES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Browser Tests:
  ✗ NotificationTest::test_notification_appears
    Element not found: [wire:id="notification-toast"]

  ✗ NotificationTest::test_notification_dismisses
    Click failed: Element not visible

  ✗ NotificationTest::test_notification_persistence
    Timeout waiting for element

💡 NEXT STEPS:
════════════════════════════════════════════════
⚠️ 3 browser tests failed
1. /sdd:story-refactor STORY-2025-004     # Return to development
2. Fix failing browser tests:
   - Verify notification component is rendered
   - Check Livewire component IDs are correct
   - Ensure dismiss button is visible
3. /sdd:story-review STORY-2025-004       # Re-run review
4. /sdd:story-qa STORY-2025-004           # Re-run QA after fixes

[DEBUGGING COMMANDS:]
vendor/bin/pest --filter=Browser::NotificationTest  # Run specific test
vendor/bin/pest --filter=Browser --parallel=false   # Run sequentially
php artisan serve                                    # Start server for manual testing
```

### Example 3: QA with Performance Issues
```bash
INPUT:
/sdd:story-qa STORY-2025-005

OUTPUT:
→ Loading project context...
  ✓ technical-stack.md: Laravel + Pest + k6

→ Moving story to QA...
  ✓ Moved STORY-2025-005.md to /stories/qa/

→ Executing test suite...
  [Unit Tests] ✓ 28/28 passed (85% coverage)
  [Feature Tests] ✓ 15/15 passed
  [Browser Tests] ✓ 6/6 passed

  [Performance] Running k6 benchmarks...
    ⚠️ Search endpoint: 450ms (target: <200ms)
    ⚠️ Database queries: 15 queries (N+1 detected)

✅ AUTOMATED QA RESULTS
════════════════════════════════════════════════
Story: STORY-2025-005 - Advanced Search
Stack: Laravel 12, Pest 4, k6
QA Executed: 2025-10-01 18:34:12

⚠️ PERFORMANCE ISSUES DETECTED

All tests: ✅ PASSED
Performance: ⚠️ Below targets

❌ BLOCKING ISSUES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Performance:
  ✗ Search response time: 450ms (target: <200ms)
  ✗ N+1 query problem detected in SearchController

🔧 SUGGESTED OPTIMIZATIONS:
  → Add eager loading: ->with(['category', 'user'])
  → Add database index on search_terms column
  → Implement search results caching

💡 NEXT STEPS:
════════════════════════════════════════════════
1. /sdd:story-refactor STORY-2025-005     # Optimize performance
2. Add eager loading and indexes
3. /sdd:story-qa STORY-2025-005           # Re-run QA with optimizations
```

## Edge Cases

### No Project Context
- DETECT missing `/project-context/` directory
- SUGGEST running `/sdd:project-init`
- ERROR: Cannot determine testing tools without context
- EXIT with guidance

### Story Not in Review
- CHECK if story in `/stories/development/`
- IF found: ERROR "Story must pass review first"
- SUGGEST: `/sdd:story-review [story-id]` first
- IF in `/stories/qa/`: ASK if user wants to re-run QA

### No Browser Tests Found
- DETECT missing browser test files
- ERROR: "Browser tests required for acceptance criteria validation"
- PROVIDE test file path examples for stack
- SUGGEST: Create browser tests before QA

### Browser Test Coverage < 100% Criteria
- COUNT acceptance criteria in story
- COUNT passing browser tests
- CALCULATE coverage gap
- BLOCK QA progression
- LIST uncovered criteria

### Performance Benchmarks Not Defined
- CHECK if performance targets in story
- IF missing: SKIP performance testing
- WARN: "No performance targets defined"
- CONTINUE with other tests

### Test Framework Not Installed
- DETECT missing testing tools
- PROVIDE installation commands for stack
- ERROR: Cannot proceed without test framework
- EXIT with setup instructions

### Flaky Browser Tests
- DETECT intermittent failures
- RETRY failed tests (up to 3 times)
- IF still failing: MARK as FAILED
- SUGGEST: Investigate timing/race conditions

## Error Handling
- **Missing /project-context/**: Suggest `/sdd:project-init`, exit gracefully
- **Story not in review**: Provide clear workflow guidance
- **Test framework errors**: Capture full error, suggest fixes
- **Browser test timeouts**: Increase timeout, suggest element inspection
- **Performance test failures**: Provide optimization suggestions
- **Security vulnerabilities**: Block with specific CVE details

## Performance Considerations
- Run unit, feature, and browser tests in parallel when possible
- Stream test output in real-time (don't wait for all tests)
- Cache test database between feature tests
- Reuse browser instances in browser tests
- Limit performance benchmarks to changed endpoints

## Related Commands
- `/sdd:story-review [id]` - Must pass before QA
- `/sdd:story-validate [id]` - Run after QA passes
- `/sdd:story-refactor [id]` - Return to development if QA fails
- `/sdd:story-ship [id]` - Deploy after validation
- `/sdd:story-status [id]` - Check current state

## Constraints
- ✅ MUST load project context before tests
- ✅ MUST move story file to qa directory
- ✅ MUST run ALL test types (unit, feature, browser)
- ✅ MUST validate 100% acceptance criteria via browser tests
- ⚠️ NEVER skip browser tests
- ⚠️ NEVER allow QA to pass with critical failures
- 📋 MUST capture test artifacts (screenshots, videos)
- 🔧 SHOULD test across browsers/devices if specified
- 💾 MUST update progress log with test results
- 🚫 BLOCK validation if quality gates fail
