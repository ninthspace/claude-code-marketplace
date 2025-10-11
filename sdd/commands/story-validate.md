# /sdd:story-validate

## Meta
- Version: 2.0
- Category: quality-gates
- Complexity: medium
- Purpose: Final validation of story against acceptance criteria before production deployment

## Definition
**Purpose**: Execute comprehensive final validation to ensure all acceptance criteria are met, all tests pass, and story is production-ready.

**Syntax**: `/sdd:story-validate [story_id]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| story_id | string | No | current branch | Story ID (STORY-YYYY-NNN) | Must match format STORY-YYYY-NNN |

## INSTRUCTION: Execute Final Story Validation

### INPUTS
- story_id: Story identifier (auto-detected from branch if not provided)
- Project context from `/project-context/` directory
- Story file from `/stories/qa/[story-id].md`
- Complete test suite results from QA
- Acceptance criteria from story file

### PROCESS

#### Phase 1: Project Context Loading
1. **CHECK** if `/project-context/` directory exists
2. IF missing:
   - SUGGEST running `/sdd:project-init` first
   - EXIT with initialization guidance
3. **LOAD** project-specific validation requirements from:
   - `/project-context/technical-stack.md` - Testing tools and validation methods
   - `/project-context/coding-standards.md` - Quality thresholds and criteria
   - `/project-context/development-process.md` - Validation stage requirements

#### Phase 2: Story Identification & Validation
1. IF story_id NOT provided:
   - **DETECT** current git branch
   - **EXTRACT** story ID from branch name
   - EXAMPLE: Branch `feature/STORY-2025-001-auth` → ID `STORY-2025-001`

2. **VALIDATE** story exists and is ready:
   - CHECK `/stories/qa/[story-id].md` exists
   - IF NOT found in QA:
     - CHECK if in `/stories/development/` or `/stories/review/`
     - ERROR: "Story must complete QA before validation"
     - SUGGEST appropriate command to progress
   - IF in `/stories/completed/`:
     - ERROR: "Story already completed and shipped"
   - IF NOT found anywhere:
     - ERROR: "Story [story-id] not found"
     - EXIT with guidance

3. **READ** story file for:
   - Success Criteria (acceptance criteria)
   - Implementation Checklist
   - QA Checklist
   - Technical Notes and concerns
   - Rollback Plan

#### Phase 3: Acceptance Criteria Validation

##### 3.1 Load and Parse Criteria
1. **EXTRACT** all acceptance criteria from Success Criteria section
2. **COUNT** total criteria
3. **IDENTIFY** browser test mappings from QA results

##### 3.2 Validate Each Criterion
1. FOR each acceptance criterion:
   ```
   ✓ [Criterion]: PASSED/FAILED
     How tested: [Discovered browser testing framework]
     Evidence: [Test file path and line number]
     Screenshots: [Screenshot path]
     Validation method: [Automated browser test/Manual verification]
   ```

2. **MAP** criteria to browser tests:
   - Laravel: `tests/Browser/[StoryId]Test.php`
   - Node.js Playwright: `tests/e2e/[story-id].spec.js`
   - Python Playwright: `tests/browser/test_[story_id].py`

3. **VERIFY** test evidence:
   - READ test file to confirm test exists
   - CHECK QA results for test pass status
   - VALIDATE screenshot exists (if applicable)
   - CONFIRM test actually validates the criterion

4. **MARK** criterion validation:
   ```markdown
   ## Success Criteria
   - [x] User can toggle dark mode
     * Tested by: tests/Browser/DarkModeTest.php::line 45
     * Evidence: Browser test passed, screenshot saved
     * Validated: 2025-10-01
   ```

#### Phase 4: Implementation Completeness Check

##### 4.1 Core Features Validation
1. **CHECK** Implementation Checklist:
   ```
   ✅ Core Features (using discovered standards):
   - [x] Feature implementation → Code complete and functional
   - [x] Unit tests → 87% coverage (target: 80% from standards)
   - [x] Integration tests → All feature tests passing
   - [x] Browser test coverage → 100% of acceptance criteria
   - [x] All discovered tests passing → Unit + Feature + Browser
   ```

2. **VALIDATE** each checklist item:
   - Feature implementation: CODE exists and works
   - Unit tests: COVERAGE meets threshold from coding-standards.md
   - Integration tests: ALL feature tests PASS
   - Browser tests: 100% acceptance criteria coverage
   - All tests passing: NO failures in any test suite

##### 4.2 Quality Standards Validation
1. **CHECK** quality items:
   ```
   ✅ Quality Standards:
   - [x] Error handling → Try/catch blocks, graceful failures
   - [x] Loading states → Spinners, skeleton screens implemented
   - [x] Documentation → Code comments, README updated
   ```

2. **VALIDATE**:
   - Error handling: CHECK for try/catch, error boundaries, validation
   - Loading states: VERIFY wire:loading, spinners, feedback
   - Documentation: CONFIRM inline docs, updated README/CHANGELOG

##### 4.3 Non-Functional Requirements
1. **CHECK** non-functional items:
   ```
   ✅ Non-Functional:
   - [x] Performance → Response times meet targets
   - [x] Accessibility → WCAG AA compliance
   - [x] Security → No vulnerabilities, auth working
   ```

2. **VALIDATE** from QA results:
   - Performance: METRICS from QA meet story targets
   - Accessibility: ARIA labels, keyboard nav, contrast checked
   - Security: NO vulnerabilities in audit, auth/authz verified

#### Phase 5: Rollback Plan Verification
1. **CHECK** if Rollback Plan section is populated
2. IF empty or minimal:
   - WARN: "Rollback plan should be documented"
   - SUGGEST rollback steps based on changes
   - OFFER to populate from git diff

3. **VALIDATE** rollback plan contains:
   - Clear steps to revert changes
   - Database migration rollback (if applicable)
   - Cache clearing instructions
   - Service restart procedures (if needed)
   - Verification steps after rollback

4. **TEST** rollback feasibility (if possible):
   - Verify migrations are reversible
   - Check for data loss risks
   - Confirm no breaking changes to shared code

#### Phase 6: Final Checks

##### 6.1 Production Readiness Checklist
1. **EXECUTE** final readiness validation:
   ```
   🚀 READY FOR PRODUCTION?
   ════════════════════════════════════════════════

   ☑ All acceptance criteria met
   ☑ All tests passing
   ☑ All acceptance criteria covered by automated browser tests
   ☑ Browser test suite passes completely
   ☑ Code reviewed and approved
   ☑ Documentation complete
   ☑ Performance acceptable
   ☑ Security verified
   ☑ Rollback plan ready
   ☑ Monitoring configured (if applicable)

   CONFIDENCE LEVEL: [High/Medium/Low]
   ```

2. **CALCULATE** confidence level:
   - HIGH: All items ✓, no warnings, comprehensive tests
   - MEDIUM: All items ✓, some warnings, adequate tests
   - LOW: Missing items, concerns, or gaps in testing

##### 6.2 Risk Assessment
1. **IDENTIFY** remaining risks:
   ```
   RISKS:
   - [Risk 1]: [Description] - Mitigation: [How to handle]
   - [Risk 2]: [Description] - Mitigation: [How to handle]
   ```

2. **ASSESS** risk levels:
   - Database migrations: Risk of data loss?
   - API changes: Breaking changes for consumers?
   - Dependency updates: Compatibility issues?
   - Performance impact: Degradation possible?
   - Security changes: New attack vectors?

##### 6.3 Dependency Validation
1. **CHECK** external dependencies:
   ```
   DEPENDENCIES:
   - [Dependency 1]: [Status - Ready/Not Ready]
   - [Dependency 2]: [Status - Ready/Not Ready]
   ```

2. **VALIDATE**:
   - External services: Available and tested?
   - Third-party APIs: Credentials configured?
   - Database migrations: Run on staging?
   - Feature flags: Configured correctly?
   - Environment variables: Set in production?

#### Phase 7: Validation Report Generation
1. **COMPILE** all validation results
2. **DETERMINE** overall status:
   - ✅ READY TO SHIP: All checks pass, high confidence
   - ⚠️ NEEDS WORK: Critical items missing or failing

3. **GENERATE** validation report:

```
📄 VALIDATION SUMMARY
════════════════════════════════════════════════
Story: [STORY-ID] - [Title]
Validated: [Timestamp]
Validator: Claude Code (Automated)

RESULT: ✅ READY TO SHIP / ⚠️ NEEDS WORK

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 ACCEPTANCE CRITERIA: 5/5 PASSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ User can toggle dark mode
  → tests/Browser/DarkModeTest.php::line 45 ✅
✓ Theme persists across sessions
  → tests/Browser/DarkModeTest.php::line 67 ✅
✓ All UI components support both themes
  → tests/Browser/DarkModeTest.php::line 89 ✅
✓ Keyboard shortcut (Cmd+Shift+D) works
  → tests/Browser/DarkModeTest.php::line 112 ✅
✓ Preference syncs across browser tabs
  → tests/Browser/DarkModeTest.php::line 134 ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 QUALITY METRICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Passed Criteria:     5/5 (100%)
Test Coverage:       87% (target: 80% ✅)
Quality Score:       9.2/10
Performance:         All targets met ✅
Security:            No vulnerabilities ✅
Accessibility:       WCAG AA compliant ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 PRODUCTION READINESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ All acceptance criteria met
✅ All tests passing (76/76)
✅ Browser test coverage: 100%
✅ Code reviewed and approved
✅ Documentation complete
✅ Performance acceptable
✅ Security verified
✅ Rollback plan documented

CONFIDENCE LEVEL: ✅ HIGH

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ RISKS & MITIGATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Low Risk: CSS changes may affect custom themes
  Mitigation: Browser tests cover theme switching,
              rollback plan ready

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 DEPENDENCIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ No external dependencies

[IF NOT READY:]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ BLOCKING ISSUES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Acceptance criterion "X" not validated by browser test
   → Create browser test in tests/Browser/
2. Rollback plan not documented
   → Add rollback steps to story file
3. Performance target not met (450ms vs 200ms)
   → Optimize database queries

[IF READY:]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ SHIP CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. /sdd:story-ship [story-id]             # Deploy to production
2. Monitor application after deployment
3. Be ready to execute rollback plan if needed
4. Document lessons learned after ship
```

#### Phase 8: Story File Updates
1. **UPDATE** Success Criteria with validation evidence:
   ```markdown
   ## Success Criteria
   - [x] User can toggle dark mode
     * Tested by: tests/Browser/DarkModeTest.php::line 45
     * Evidence: Browser test passed on 2025-10-01
     * Screenshot: /storage/screenshots/STORY-2025-003/toggle.png
   - [x] Theme persists across sessions
     * Tested by: tests/Browser/DarkModeTest.php::line 67
     * Evidence: Browser test passed on 2025-10-01
   ```

2. **MARK** remaining checklist items:
   - Implementation Checklist: `[x]` any newly validated items
   - QA Checklist: `[x]` any newly validated items

3. **ADD** validation entry to Progress Log:
   ```markdown
   - [Today]: Final validation completed
     * All 5 acceptance criteria validated ✅
     * Test coverage: 87% (exceeds 80% target)
     * Performance: All targets met
     * Security: No vulnerabilities
     * Rollback plan: Documented and verified
     * Confidence level: HIGH
     * Status: READY TO SHIP
   ```

4. **RECORD** validation results:
   - Validation timestamp
   - Confidence level
   - Risk assessment
   - Dependency status
   - Any conditions for shipping

#### Phase 9: Next Steps
1. **DISPLAY** validation outcome:
   ```
   💡 NEXT STEPS:
   ════════════════════════════════════════════════

   [IF READY TO SHIP:]
   ✅ Story validated and ready for production

   1. /sdd:story-ship [story-id]             # Deploy to production
      - Creates PR (if not created)
      - Merges to main branch
      - Moves story to completed
      - Tags release

   2. Post-Deployment Actions:
      - Monitor application logs
      - Watch performance metrics
      - Be ready for rollback
      - Document lessons learned

   [IF NEEDS WORK:]
   ⚠️ X critical issues prevent shipping

   1. /sdd:story-refactor [story-id]         # Return to development
   2. Address blocking issues:
      - [Issue 1]
      - [Issue 2]
   3. /sdd:story-review [story-id]           # Re-run review
   4. /sdd:story-qa [story-id]               # Re-run QA
   5. /sdd:story-validate [story-id]         # Re-validate

   [MONITORING COMMANDS:]
   # Laravel:
   php artisan pail                      # Watch logs in real-time
   php artisan telescope:clear           # Clear old monitoring data

   # System:
   tail -f storage/logs/laravel.log     # Follow application logs
   ```

### OUTPUTS
- Updated `/stories/qa/[story-id].md` with validation results
- Validation summary report (displayed to user)
- Updated Success Criteria with test evidence
- Updated checklists with final validation status
- Progress log entry with validation timestamp

### RULES
- MUST load project context before validation
- MUST validate ALL acceptance criteria with evidence
- MUST verify 100% browser test coverage of criteria
- MUST check rollback plan is documented
- MUST assess production readiness
- SHOULD identify risks and mitigations
- SHOULD validate external dependencies
- NEVER mark story ready with failing tests
- NEVER skip acceptance criteria validation
- ALWAYS provide test evidence for each criterion
- ALWAYS update Success Criteria with validation details
- ALWAYS record confidence level in validation

## Examples

### Example 1: Validation Ready to Ship
```bash
INPUT:
/sdd:story-validate STORY-2025-003

OUTPUT:
→ Loading project context...
  ✓ technical-stack.md: Laravel + Pest + Playwright
  ✓ coding-standards.md: 80% coverage target
  ✓ development-process.md: Validation requirements

→ Loading story requirements...
  ✓ Story: STORY-2025-003 - Dark Mode Toggle
  ✓ Success Criteria: 5 criteria
  ✓ Implementation Checklist: 9/9 complete
  ✓ QA Checklist: 6/6 complete

→ Validating acceptance criteria...
  ✓ [1/5] User can toggle dark mode
    → tests/Browser/DarkModeTest.php::line 45 ✅
  ✓ [2/5] Theme persists across sessions
    → tests/Browser/DarkModeTest.php::line 67 ✅
  ✓ [3/5] All UI components support both themes
    → tests/Browser/DarkModeTest.php::line 89 ✅
  ✓ [4/5] Keyboard shortcut works
    → tests/Browser/DarkModeTest.php::line 112 ✅
  ✓ [5/5] Preference syncs across tabs
    → tests/Browser/DarkModeTest.php::line 134 ✅

→ Checking implementation completeness...
  ✓ Feature implementation: Complete
  ✓ Unit tests: 87% coverage (target: 80%)
  ✓ Browser tests: 100% criteria coverage
  ✓ All tests passing: 76/76

→ Verifying rollback plan...
  ✓ Rollback plan documented
  ✓ Migrations are reversible

→ Final production readiness checks...
  ✓ All acceptance criteria met
  ✓ All tests passing
  ✓ Code reviewed
  ✓ Documentation complete
  ✓ Performance acceptable
  ✓ Security verified
  ✓ Rollback plan ready

📄 VALIDATION SUMMARY
════════════════════════════════════════════════
Story: STORY-2025-003 - Dark Mode Toggle
Validated: 2025-10-01 17:45:23

RESULT: ✅ READY TO SHIP

Passed Criteria: 5/5 (100%)
Test Coverage: 87%
Quality Score: 9.2/10

CONFIDENCE LEVEL: ✅ HIGH

💡 NEXT STEPS:
════════════════════════════════════════════════
✅ Story validated and ready for production

1. /sdd:story-ship STORY-2025-003             # Deploy to production
2. Monitor application after deployment
3. Be ready to execute rollback if needed
```

### Example 2: Validation with Blocking Issues
```bash
INPUT:
/sdd:story-validate STORY-2025-004

OUTPUT:
→ Loading project context...
  ✓ technical-stack.md loaded

→ Loading story requirements...
  ✓ Story: STORY-2025-004 - Notification System
  ✓ Success Criteria: 4 criteria

→ Validating acceptance criteria...
  ✓ [1/4] Notifications appear on events
    → tests/Browser/NotificationTest.php::line 23 ✅
  ✓ [2/4] Notifications can be dismissed
    → tests/Browser/NotificationTest.php::line 45 ✅
  ✗ [3/4] Notifications persist across sessions
    → NO BROWSER TEST FOUND ❌
  ✗ [4/4] Email notifications sent
    → NO BROWSER TEST FOUND ❌

→ Checking rollback plan...
  ✗ Rollback plan not documented

📄 VALIDATION SUMMARY
════════════════════════════════════════════════
Story: STORY-2025-004 - Notification System
Validated: 2025-10-01 18:12:45

RESULT: ⚠️ NEEDS WORK

Passed Criteria: 2/4 (50%)
Test Coverage: 78% (below 80% target)

❌ BLOCKING ISSUES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Acceptance criterion "Notifications persist across sessions" not validated
   → Create browser test in tests/Browser/NotificationTest.php

2. Acceptance criterion "Email notifications sent" not validated
   → Create browser test for email sending

3. Rollback plan not documented
   → Add rollback steps to story file

4. Test coverage 78% below target 80%
   → Add tests to increase coverage

💡 NEXT STEPS:
════════════════════════════════════════════════
⚠️ 4 critical issues prevent shipping

1. /sdd:story-refactor STORY-2025-004         # Return to development
2. Address blocking issues:
   - Add browser test for session persistence
   - Add browser test for email notifications
   - Document rollback plan
   - Increase test coverage to 80%+
3. /sdd:story-review STORY-2025-004           # Re-run review
4. /sdd:story-qa STORY-2025-004               # Re-run QA
5. /sdd:story-validate STORY-2025-004         # Re-validate
```

### Example 3: Validation with Warnings (Still Ship-Ready)
```bash
INPUT:
/sdd:story-validate

OUTPUT:
→ Detecting story from current branch...
  ✓ Current branch: feature/STORY-2025-005-search
  ✓ Story ID: STORY-2025-005

→ Loading story requirements...
  ✓ Success Criteria: 3 criteria

→ Validating acceptance criteria...
  ✓ All 3 criteria validated by browser tests

→ Assessing risks...
  ⚠️ Database migration changes column type
  ⚠️ Bundle size increased by 15KB

📄 VALIDATION SUMMARY
════════════════════════════════════════════════
Story: STORY-2025-005 - Advanced Search
Validated: 2025-10-01 19:23:11

RESULT: ✅ READY TO SHIP (with warnings)

Passed Criteria: 3/3 (100%)
Test Coverage: 91%

CONFIDENCE LEVEL: ⚠️ MEDIUM

⚠️ WARNINGS (non-blocking):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Database migration changes column type
   Risk: Potential data loss on rollback
   Mitigation: Backup database before deployment

2. Bundle size increased by 15KB
   Risk: Slightly slower page loads
   Mitigation: Monitor performance metrics

💡 NEXT STEPS:
════════════════════════════════════════════════
✅ Story validated - Ready to ship with awareness

1. /sdd:story-ship STORY-2025-005             # Deploy to production
2. Backup database before deployment
3. Monitor performance after deployment
```

## Edge Cases

### No Project Context
- DETECT missing `/project-context/` directory
- SUGGEST running `/sdd:project-init`
- OFFER to validate with basic checks
- WARN that validation will be incomplete

### Story Not in QA
- CHECK if story in `/stories/development/` or `/stories/review/`
- ERROR: "Story must complete QA before validation"
- PROVIDE workflow guidance to reach QA stage
- SUGGEST appropriate command

### Missing Browser Tests
- DETECT acceptance criteria without browser test evidence
- COUNT uncovered criteria
- BLOCK validation if coverage < 100%
- PROVIDE test file examples for stack

### Incomplete Checklists
- DETECT unchecked items in Implementation/QA checklists
- LIST incomplete items
- ASSESS if items are truly incomplete or just not checked
- WARN if critical items unchecked

### Rollback Plan Empty
- DETECT missing or minimal rollback plan
- SUGGEST rollback steps based on git diff
- OFFER to auto-generate basic rollback plan
- WARN that deployment without rollback plan is risky

### External Dependencies Not Ready
- DETECT external dependencies in story
- CHECK if dependencies are ready (if possible)
- WARN about deployment risks
- SUGGEST coordinating with dependency owners

## Error Handling
- **Missing /project-context/**: Suggest `/sdd:project-init`, offer basic validation
- **Story not in QA**: Provide clear workflow, suggest correct command
- **Missing tests**: Block validation, provide test creation guidance
- **Git errors**: Validate git state, suggest resolution
- **File read errors**: Report specific file issue, suggest fix

## Performance Considerations
- Validation is primarily file reading and analysis (fast)
- Browser test evidence lookup is file-based (< 1s typically)
- No expensive operations unless re-running tests
- Cache story file contents for session

## Related Commands
- `/sdd:story-qa [id]` - Must complete before validation
- `/sdd:story-ship [id]` - Run after validation passes
- `/sdd:story-refactor [id]` - Return to development if validation fails
- `/sdd:story-status [id]` - Check current story state

## Constraints
- ✅ MUST load project context for validation standards
- ✅ MUST validate ALL acceptance criteria with evidence
- ✅ MUST verify 100% browser test coverage
- ✅ MUST check rollback plan exists
- ✅ MUST assess production readiness
- ⚠️ NEVER mark story ready with incomplete criteria validation
- ⚠️ NEVER skip browser test evidence requirement
- 📋 SHOULD identify and document risks
- 🔧 SHOULD validate external dependencies
- 💾 MUST update Success Criteria with validation details
- 🚫 BLOCK shipping if critical issues found
