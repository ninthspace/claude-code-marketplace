# /sdd:story-review

## Meta
- Version: 2.0
- Category: quality-gates
- Complexity: high
- Purpose: Move story to review stage and execute comprehensive quality checks

## Definition
**Purpose**: Execute comprehensive code review with project-specific quality gates, linting, testing, security checks, and standards compliance before QA.

**Syntax**: `/sdd:story-review [story_id]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| story_id | string | No | current branch | Story ID (STORY-YYYY-NNN) | Must match format STORY-YYYY-NNN |

## INSTRUCTION: Execute Story Review

### INPUTS
- story_id: Story identifier (auto-detected from branch if not provided)
- Project context from `/project-context/` directory
- Story file from `/stories/development/[story-id].md`
- Codebase changes since story started

### PROCESS

#### Phase 1: Project Context Loading
1. **CHECK** if `/project-context/` directory exists
2. IF missing:
   - SUGGEST running `/sdd:project-init` first
   - EXIT with initialization guidance
3. **LOAD** project-specific review standards from:
   - `/project-context/technical-stack.md` - Technology stack and tools
   - `/project-context/coding-standards.md` - Quality standards and thresholds
   - `/project-context/development-process.md` - Review stage requirements

#### Phase 2: Story Identification & Validation
1. IF story_id NOT provided:
   - **DETECT** current git branch
   - **EXTRACT** story ID from branch name
   - EXAMPLE: Branch `feature/STORY-2025-001-auth` → ID `STORY-2025-001`

2. **VALIDATE** story exists:
   - CHECK `/stories/development/[story-id].md` exists
   - IF NOT found in development:
     - CHECK if already in `/stories/review/`
     - INFORM user and ask to proceed with re-review
   - IF NOT found anywhere:
     - ERROR: "Story [story-id] not found"
     - EXIT with guidance

3. **READ** story file for:
   - Current status
   - Implementation checklist state
   - Acceptance criteria
   - Technical approach

#### Phase 3: Directory Preparation
1. **ENSURE** `/stories/review/` directory exists
   - CREATE directory if missing
   - ADD `.gitkeep` file if directory was created

2. **MOVE** story file:
   - FROM: `/stories/development/[story-id].md`
   - TO: `/stories/review/[story-id].md`
   - PRESERVE all content and formatting

3. **UPDATE** story metadata:
   - Change status from "development" to "review"
   - KEEP existing dates and branch information
   - ADD review start timestamp to progress log

#### Phase 4: Quality Gate Execution

##### 4.1 Linting & Formatting (Discovered Tools)
1. **IDENTIFY** linter from technical-stack.md:
   - PHP/Laravel: `vendor/bin/pint`
   - Node.js: ESLint, Prettier
   - Python: Black, flake8, pylint
   - Go: gofmt, golint
   - Rust: rustfmt, clippy

2. **RUN** discovered linter:
   ```bash
   # Example for Laravel:
   vendor/bin/pint --dirty

   # Example for Node.js:
   npm run lint
   npm run format
   ```

3. **CAPTURE** results:
   - COUNT style violations
   - IDENTIFY auto-fixable issues
   - LIST files modified by auto-fix
   - REPORT remaining manual fixes needed

##### 4.2 Testing (Discovered Framework)
1. **IDENTIFY** test framework from technical-stack.md:
   - PHP/Laravel: Pest, PHPUnit
   - Node.js: Jest, Vitest, Mocha
   - Python: pytest, unittest
   - Go: go test
   - Java: JUnit, TestNG

2. **RUN** discovered test suite:
   ```bash
   # Example for Laravel Pest:
   vendor/bin/pest --coverage

   # Example for Node.js:
   npm test -- --coverage
   ```

3. **ANALYZE** test results:
   - PASS/FAIL status for all test types
   - Coverage percentage (unit, feature, browser)
   - Identify untested code paths
   - CHECK coverage meets standards from coding-standards.md

##### 4.3 Security Checks (Discovered Tools)
1. **IDENTIFY** security tools from technical-stack.md:
   - PHP/Laravel: `composer audit`
   - Node.js: `npm audit`, `yarn audit`
   - Python: `safety check`, `bandit`
   - Go: `go mod audit`, `gosec`
   - Java: `mvn dependency-check`

2. **RUN** discovered security scanners:
   ```bash
   # Example for Laravel:
   composer audit

   # Example for Node.js:
   npm audit --production
   ```

3. **SCAN** for exposed secrets:
   - CHECK for API keys, tokens, passwords
   - VALIDATE environment variable usage
   - REVIEW configuration files

4. **FRAMEWORK-SPECIFIC** security checks:
   - Laravel: CSRF tokens, SQL injection prevention, XSS protection
   - React: XSS via dangerouslySetInnerHTML, dependency vulnerabilities
   - Express: Helmet middleware, rate limiting, input validation

##### 4.4 Dependencies Analysis (Discovered Package Manager)
1. **IDENTIFY** package manager from technical-stack.md:
   - PHP: Composer
   - Node.js: npm, yarn, pnpm
   - Python: pip, poetry
   - Go: go modules
   - Rust: cargo

2. **CHECK** for unused dependencies:
   ```bash
   # Example for Node.js:
   npx depcheck

   # Example for PHP:
   composer show --tree
   ```

3. **IDENTIFY** outdated packages:
   ```bash
   # Example for Laravel:
   composer outdated

   # Example for Node.js:
   npm outdated
   ```

4. **ANALYZE** bundle size impact (if frontend):
   - MEASURE before/after bundle sizes
   - IDENTIFY large dependencies
   - SUGGEST optimization opportunities

##### 4.5 Standards Compliance (Discovered Coding Standards)
1. **LOAD** naming conventions from coding-standards.md
2. **LOAD** file organization patterns
3. **LOAD** error handling requirements
4. **LOAD** performance guidelines

5. **FRAMEWORK-SPECIFIC** compliance checks:
   - **React**: Component structure, hooks rules, prop-types/TypeScript
   - **Vue**: Composition API patterns, template conventions, ref naming
   - **Laravel**: Eloquent usage, Blade conventions, Livewire patterns, route naming
   - **Django**: Model/View/Template patterns, DRF conventions, ORM best practices
   - **Express**: Middleware patterns, route organization, error handling

6. **VALIDATE** against standards:
   - CHECK naming conventions (files, functions, variables)
   - VERIFY file organization matches project structure
   - ENSURE error handling follows patterns
   - CONFIRM performance guidelines met

##### 4.6 Accessibility Checks (If UI Changes)
1. **DETECT** if story includes UI changes
2. IF UI changes present:
   - **CHECK** for ARIA labels per coding-standards.md
   - **VERIFY** keyboard navigation support
   - **TEST** color contrast ratios (WCAG AA/AAA)
   - **VALIDATE** semantic HTML usage
   - **CHECK** screen reader compatibility

3. **FRAMEWORK-SPECIFIC** accessibility:
   - React: jsx-a11y rules, focus management
   - Vue: Template accessibility, v-focus directive
   - Laravel Livewire: wire:loading states, wire:target accessibility

#### Phase 5: Report Generation
1. **COMPILE** all check results
2. **GENERATE** review report:

```
📊 CODE REVIEW REPORT
════════════════════════════════════════════════
Story: [STORY-ID] - [Title]
Stack: [Discovered Framework/Language/Tools]
Reviewed: [Timestamp]

✅ PASSED CHECKS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Linting]
  ✓ Laravel Pint: All files formatted (X files checked)
  ✓ No style violations found

[Testing]
  ✓ Pest tests: XX/XX passed
  ✓ Unit coverage: XX% (target: YY% from standards)
  ✓ Feature coverage: XX% (target: YY% from standards)
  ✓ Browser coverage: XX% (target: YY% from standards)

[Security]
  ✓ Composer audit: No vulnerabilities
  ✓ No exposed secrets detected
  ✓ CSRF protection implemented

[Dependencies]
  ✓ No unused dependencies
  ✓ All packages up to date

[Standards]
  ✓ Naming conventions followed
  ✓ File organization matches project structure
  ✓ Error handling implemented
  ✓ Performance guidelines met

[Accessibility] (if UI)
  ✓ ARIA labels present
  ✓ Keyboard navigation functional
  ✓ Color contrast: WCAG AA compliant

⚠️ WARNINGS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Dependencies]
  ⚠ Package "X" has minor update available (current: 1.2.3, latest: 1.2.4)
  ⚠ Bundle size increased by XKB (+Y%)

[Performance]
  ⚠ Method X complexity is high (cyclomatic complexity: N)

❌ FAILURES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Testing]
  ✗ Coverage below threshold: 75% (target: 80%)
  ✗ Missing tests for: ErrorHandlingService.handleTimeout()

[Security]
  ✗ High severity vulnerability in package "Y" (CVE-2024-XXXX)

📈 METRICS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test Coverage:       XX% (target: YY% from standards)
Code Quality Score:  X/10 (using discovered metrics)
Bundle Size Impact:  +XKB (+Y%)
Performance Score:   X/100 (using discovered tools)
Complexity Score:    X (average cyclomatic complexity)

🔧 SUGGESTED IMPROVEMENTS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Laravel-specific]
  → Consider eager loading to prevent N+1 queries in TaskController
  → Extract complex query logic to repository pattern
  → Add database indexes for frequently queried columns

[Performance]
  → Cache expensive computations in method X
  → Lazy load heavy components

[Testing]
  → Add browser test for error scenario in feature Y
  → Increase coverage for edge cases in service Z
```

#### Phase 6: Story File Updates
1. **UPDATE** Implementation Checklist based on review:
   - `[x]` Feature implementation - IF core functionality complete
   - `[x]` Unit tests - IF tests pass AND coverage meets standards
   - `[x]` Integration tests - IF integration tests pass
   - `[x]` Error handling - IF error scenarios properly handled
   - `[x]` Loading states - IF UI loading states implemented
   - `[x]` Performance optimization - IF performance requirements met
   - `[x]` Accessibility - IF accessibility standards met
   - `[x]` Security review - IF security checks pass

2. **ADD** to Progress Log:
   ```markdown
   - [Today]: Moved to review stage
   - [Today]: Executed quality gates - [PASSED/FAILED]
     * Linting: [status]
     * Testing: [status] - [XX]% coverage
     * Security: [status]
     * Standards: [status]
   ```

3. **RECORD** review results:
   - Which tools were used
   - Which standards were applied
   - Coverage percentages achieved
   - Issues found and resolution status

4. **ONLY** mark items `[x]` if they truly pass review criteria
   - BE STRICT with validation
   - PARTIAL completion = NOT checked
   - MUST meet coding-standards.md thresholds

#### Phase 7: Next Actions
1. **DETERMINE** review outcome:
   - IF all critical checks PASS → Ready for `/sdd:story-qa`
   - IF any failures → Requires `/sdd:story-refactor`
   - IF documentation needed → Run `/sdd:story-document`

2. **DISPLAY** next steps:
   ```
   💡 NEXT STEPS:
   ════════════════════════════════════════════════

   [IF PASSED:]
   ✅ All quality gates passed
   1. /sdd:story-qa [story-id]           # Move to QA and run test suite

   [IF FAILED:]
   ⚠️ X critical issues must be fixed
   1. /sdd:story-refactor [story-id]     # Return to development
   2. Fix identified issues:
      - [Issue 1]
      - [Issue 2]
   3. /sdd:story-review [story-id]       # Re-run review after fixes

   [IF WARNINGS:]
   ⚠️ X warnings (non-blocking)
   1. /sdd:story-qa [story-id]           # Proceed to QA (warnings won't block)
   2. Consider addressing warnings in future iteration

   [AVAILABLE COMMANDS:]
   - /sdd:story-document [story-id]      # Add/update documentation
   - /sdd:story-status [story-id]        # View detailed story status
   ```

3. **SHOW** relevant debugging commands for discovered stack:
   ```bash
   # Laravel:
   vendor/bin/pint --test          # Check formatting without fixing
   vendor/bin/pest --filter=Unit   # Run specific test suite
   composer audit                   # Re-run security scan

   # Node.js:
   npm run lint:fix                 # Auto-fix linting issues
   npm test -- --coverage           # Run tests with coverage
   npm audit fix                    # Fix security vulnerabilities
   ```

### OUTPUTS
- `/stories/review/[story-id].md` - Updated story file with review results
- Code review report (displayed to user)
- Updated Implementation Checklist with validation status
- Progress log entry with review timestamp

### RULES
- MUST load project context before running any checks
- MUST use discovered tools from technical-stack.md
- MUST validate against coding-standards.md thresholds
- MUST move story file from development to review
- SHOULD run all applicable quality gates for stack
- SHOULD capture detailed metrics for analysis
- NEVER mark checklist items complete unless they truly pass
- NEVER skip security checks
- ALWAYS update progress log with review results
- ALWAYS provide actionable feedback for failures

## Examples

### Example 1: Review with All Checks Passing
```bash
INPUT:
/sdd:story-review STORY-2025-001

OUTPUT:
→ Loading project context...
  ✓ technical-stack.md: Laravel + Pest + Playwright
  ✓ coding-standards.md: 80% coverage target, Laravel Pint
  ✓ development-process.md: Review stage requirements

→ Moving story to review...
  ✓ Moved STORY-2025-001.md to /stories/review/

→ Running quality gates...
  [Linting] Running Laravel Pint...
    ✓ 15 files formatted, 0 violations

  [Testing] Running Pest...
    ✓ Unit tests: 45/45 passed
    ✓ Feature tests: 23/23 passed
    ✓ Browser tests: 8/8 passed
    ✓ Coverage: 87% (target: 80%)

  [Security] Running Composer audit...
    ✓ No vulnerabilities found
    ✓ No exposed secrets

  [Standards] Checking Laravel conventions...
    ✓ Eloquent usage follows best practices
    ✓ Livewire patterns correct
    ✓ Blade conventions followed

📊 CODE REVIEW REPORT
════════════════════════════════════════════════
Story: STORY-2025-001 - User Authentication System
Stack: Laravel 12, Livewire 3, Pest 4, Playwright
Reviewed: 2025-10-01 14:23:45

✅ ALL CHECKS PASSED

📈 METRICS:
Test Coverage:       87% (target: 80%)
Code Quality Score:  9.2/10
Bundle Size Impact:  +12KB (+3%)
Performance Score:   94/100

💡 NEXT STEPS:
════════════════════════════════════════════════
✅ All quality gates passed
1. /sdd:story-qa STORY-2025-001          # Move to QA and run test suite
```

### Example 2: Review with Failures
```bash
INPUT:
/sdd:story-review

OUTPUT:
→ Detecting story from current branch...
  ✓ Current branch: feature/STORY-2025-003-dark-mode
  ✓ Story ID: STORY-2025-003

→ Loading project context...
  ✓ technical-stack.md: Laravel + Pest + Playwright
  ✓ coding-standards.md: 80% coverage target

→ Moving story to review...
  ✓ Moved STORY-2025-003.md to /stories/review/

→ Running quality gates...
  [Testing] Running Pest...
    ✓ Unit tests: 12/12 passed
    ✗ Feature tests: 4/5 passed (1 failed)
    ✓ Browser tests: 3/3 passed
    ✗ Coverage: 68% (target: 80%)

  [Security] Running Composer audit...
    ✗ 1 high severity vulnerability found

📊 CODE REVIEW REPORT
════════════════════════════════════════════════
Story: STORY-2025-003 - Dark Mode Toggle
Stack: Laravel 12, Livewire 3, Pest 4
Reviewed: 2025-10-01 15:45:12

❌ FAILURES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Testing]
  ✗ Coverage below threshold: 68% (target: 80%)
  ✗ Missing tests for: DarkModeService.applyTheme()
  ✗ Feature test failed: tests/Feature/DarkModeTest.php

[Security]
  ✗ High severity vulnerability in package "laravel/framework"
    CVE-2024-12345 - Update to v12.1.5

💡 NEXT STEPS:
════════════════════════════════════════════════
⚠️ 3 critical issues must be fixed
1. /sdd:story-refactor STORY-2025-003     # Return to development
2. Fix identified issues:
   - Add tests for DarkModeService.applyTheme()
   - Fix failing feature test
   - Update Laravel framework to v12.1.5
3. /sdd:story-review STORY-2025-003       # Re-run review after fixes

[DEBUGGING COMMANDS:]
vendor/bin/pest --filter=DarkMode      # Run specific test
composer update laravel/framework      # Update vulnerable package
```

### Example 3: Re-review Already in Review
```bash
INPUT:
/sdd:story-review STORY-2025-002

OUTPUT:
→ Loading project context...
  ✓ technical-stack.md loaded

→ Validating story location...
  ⚠️ Story STORY-2025-002 already in review stage
  ℹ️ Running re-review with updated checks

→ Running quality gates...
  [All checks execute...]

📊 CODE REVIEW REPORT (RE-REVIEW)
════════════════════════════════════════════════
Story: STORY-2025-002 - Payment Integration
Stack: Laravel 12, Stripe SDK
Reviewed: 2025-10-01 16:12:33 (2nd review)

✅ ALL CHECKS PASSED
```

## Edge Cases

### No Project Context
- DETECT missing `/project-context/` directory
- SUGGEST running `/sdd:project-init`
- OFFER to run basic checks without discovered standards
- WARN that review will be incomplete

### Story Not in Development
- CHECK if story in `/stories/review/`
- IF found: ASK user if they want to re-review
- IF in `/stories/qa/`: ERROR and suggest `/sdd:story-refactor` first
- IF in `/stories/completed/`: ERROR "Story already shipped"

### Missing Test Framework
- DETECT if testing tool not installed
- PROVIDE installation instructions for discovered stack
- SKIP test checks with warning
- MARK review as INCOMPLETE

### Security Vulnerabilities Found
- BLOCK progression to QA if HIGH/CRITICAL severity
- ALLOW progression if LOW/MEDIUM with warning
- PROVIDE update/fix commands
- LOG all vulnerabilities in review report

### Coverage Below Threshold
- CALCULATE gap to target (e.g., 68% vs 80% = 12% gap)
- IDENTIFY specific untested files/methods
- SUGGEST test cases to add
- BLOCK progression if below threshold

### Tool Execution Failures
- CATCH and log tool errors
- CONTINUE with remaining checks
- MARK affected section as INCOMPLETE
- SUGGEST manual verification

## Error Handling
- **Missing /project-context/**: Suggest `/sdd:project-init`, offer basic review
- **Story file not found**: Check all directories, provide helpful guidance
- **Tool not installed**: Provide installation commands for stack
- **Permission errors**: Report specific file/directory access issue
- **Git errors**: Validate git state, suggest resolution
- **Test failures**: Capture full output, suggest debugging steps

## Performance Considerations
- Run linting/formatting in parallel with security scans
- Cache project context for session (don't re-read every time)
- Stream test output in real-time (don't wait for completion)
- Limit coverage analysis to changed files when possible

## Related Commands
- `/sdd:story-refactor [id]` - Return to development to fix issues
- `/sdd:story-qa [id]` - Proceed to QA after passing review
- `/sdd:story-document [id]` - Add documentation before QA
- `/sdd:story-status [id]` - Check current story state
- `/sdd:project-context` - Update project standards

## Constraints
- ✅ MUST load project context before any checks
- ✅ MUST move story file to review directory
- ✅ MUST run all applicable quality gates
- ✅ MUST validate against coding-standards.md
- ⚠️ NEVER skip security checks
- ⚠️ NEVER mark checklist items complete without validation
- 📋 SHOULD provide actionable feedback for all failures
- 🔧 SHOULD suggest framework-specific improvements
- 💾 MUST update progress log with timestamp
- 🚫 BLOCK QA progression if critical checks fail
