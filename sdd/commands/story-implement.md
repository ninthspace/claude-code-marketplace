# /sdd:story-implement

## Meta
- Version: 2.0
- Category: workflow
- Complexity: comprehensive
- Purpose: Generate context-aware implementation code, tests, and browser tests based on story requirements

## Definition
**Purpose**: Generate complete implementation including production code, unit tests, integration tests, and browser tests using the project's actual technical stack and coding standards.

**Syntax**: `/sdd:story-implement [story_id]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| story_id | string | No | current branch | Story identifier (e.g., "STORY-001") | Must match pattern STORY-\d{3,} |

## INSTRUCTION: Generate Story Implementation

### INPUTS
- story_id: Optional story identifier (auto-detected from current branch if omitted)
- Story file from `/stories/development/[story-id].md`
- Project context from `/project-context/` directory
- Technical stack configuration
- Coding standards and patterns

### PROCESS

#### Phase 1: Project Context Loading
1. **CHECK** if `/project-context/` directory exists
2. IF missing:
   - SUGGEST running `/sdd:project-init` first
   - HALT execution with clear guidance
   - EXIT with initialization instructions
3. **LOAD** and **PARSE** project context:
   - `/project-context/technical-stack.md`:
     * IDENTIFY actual frontend framework (React/Vue/Svelte/Laravel Blade/etc.)
     * IDENTIFY actual state management (Redux/Vuex/Pinia/Livewire/Alpine.js/etc.)
     * IDENTIFY actual primary language (TypeScript/JavaScript/PHP/Python/Go/etc.)
     * IDENTIFY actual styling approach (Tailwind/CSS Modules/Styled Components/etc.)
     * IDENTIFY actual backend runtime and framework
     * IDENTIFY actual database system
     * IDENTIFY actual testing framework
     * IDENTIFY actual browser testing tools
     * IDENTIFY actual build tools and package manager
   - `/project-context/coding-standards.md`:
     * EXTRACT file organization patterns
     * EXTRACT naming conventions
     * EXTRACT error handling approach
     * EXTRACT testing patterns
     * EXTRACT code formatting rules
     * EXTRACT comment and documentation standards
   - `/project-context/development-process.md`:
     * EXTRACT stage requirements
     * EXTRACT quality gates
     * EXTRACT review criteria

#### Phase 2: Story File Discovery and Analysis
1. **DETERMINE** story ID:
   - IF story_id parameter provided: USE it
   - ELSE: EXTRACT from current git branch name
   - ELSE: FIND most recent story in `/stories/development/`
   - IF NOT FOUND: HALT with error and suggest `/sdd:story-start`

2. **READ** story file at `/stories/development/[story-id].md`
3. **EXTRACT** story requirements:
   - Success criteria (acceptance criteria)
   - Technical approach and constraints
   - Implementation checklist status
   - Dependencies and integration points
   - Edge cases and error scenarios
   - UI/UX considerations
   - Performance requirements
   - Accessibility requirements
   - Security considerations

4. **VALIDATE** story is in development status:
   - IF in "backlog": SUGGEST running `/sdd:story-start` first
   - IF in "review" or "qa": WARN about overwriting reviewed code
   - IF in "completed": HALT with error

#### Phase 3: Implementation Generation
1. **GENERATE** production code using DISCOVERED stack:

   **Frontend Components:**
   - CREATE component files for DISCOVERED framework:
     * React: .jsx/.tsx components with hooks
     * Vue: .vue single-file components
     * Laravel Blade + Livewire: Livewire component classes + Blade views
     * Svelte: .svelte components
     * Angular: .ts components with templates
   - APPLY DISCOVERED state management patterns
   - USE DISCOVERED styling approach
   - IMPLEMENT error boundaries/error handling
   - ADD loading states and feedback
   - ENSURE accessibility features (ARIA, keyboard nav, focus management)
   - OPTIMIZE for performance (memoization, lazy loading)

   **Backend Components:**
   - CREATE backend files for DISCOVERED framework:
     * Laravel: Controllers, Models, Migrations, Policies
     * Express: Routes, Controllers, Middleware, Models
     * Django: Views, Models, Forms, Serializers
     * FastAPI: Routes, Models, Schemas, Dependencies
   - IMPLEMENT business logic
   - ADD validation and sanitization
   - INCLUDE error handling
   - ADD logging using DISCOVERED tools
   - IMPLEMENT security measures (CSRF, XSS, SQL injection prevention)
   - OPTIMIZE database queries (eager loading, indexing)

   **Database Changes:**
   - CREATE migrations for DISCOVERED database system
   - DEFINE models with relationships
   - ADD indexes for performance
   - INCLUDE rollback instructions
   - SEED data if needed

2. **APPLY** coding standards from coding-standards.md:
   - FOLLOW DISCOVERED file organization
   - USE DISCOVERED naming conventions
   - APPLY DISCOVERED formatting rules
   - ADD DISCOVERED comment patterns
   - RESPECT DISCOVERED error handling approach

3. **VERIFY** generated code quality:
   - CHECK syntax correctness
   - ENSURE imports and dependencies are correct
   - VALIDATE against DISCOVERED linting rules
   - CONFIRM adherence to coding standards

#### Phase 4: Unit Test Generation
1. **GENERATE** unit tests using DISCOVERED test framework:

   **Test Framework Detection:**
   - Jest/Vitest: Create .test.js/.spec.js files
   - Pest: Create .php test files in tests/Unit/ or tests/Feature/
   - Pytest: Create test_*.py files
   - JUnit: Create *Test.java files
   - Go: Create *_test.go files

2. **CREATE** test cases covering:
   - Each success criterion
   - Happy path scenarios
   - Edge cases and boundary conditions
   - Error scenarios and error handling
   - Validation rules
   - State management logic
   - Business logic correctness
   - Component rendering (for frontend)
   - API responses (for backend)

3. **APPLY** DISCOVERED testing patterns:
   - USE DISCOVERED test structure (describe/it, it(), test functions)
   - FOLLOW DISCOVERED mocking patterns
   - USE DISCOVERED assertion methods
   - INCLUDE DISCOVERED test setup/teardown

4. **ORGANIZE** tests logically:
   - GROUP related tests
   - NAME tests descriptively
   - ADD comments for complex scenarios

#### Phase 5: Integration Test Generation
1. **GENERATE** integration tests for:
   - API endpoints (if applicable)
   - Database interactions
   - Component integration
   - Service integration
   - External dependencies

2. **CREATE** test scenarios covering:
   - Full request/response cycles
   - Database transactions
   - Authentication/authorization flows
   - Multi-step user interactions
   - Cross-component communication

3. **USE** DISCOVERED integration testing tools:
   - Laravel: Feature tests with RefreshDatabase
   - Express: Supertest for API testing
   - Django: TestCase with database fixtures
   - React: Testing Library integration tests

#### Phase 6: Browser Test Generation
1. **PARSE** acceptance criteria from story file
2. **GENERATE** browser test file using DISCOVERED browser testing framework:

   **Framework-Specific Paths:**
   - Laravel: `tests/Browser/[StoryId]Test.php` (Dusk/Playwright)
   - Node.js: `tests/e2e/[story-id].spec.js` (Playwright/Cypress)
   - Python: `tests/browser/test_[story_id].py` (Playwright/Selenium)
   - Ruby: `spec/features/[story_id]_spec.rb` (Capybara)

3. **CREATE** test methods for each acceptance criterion:
   - USER INTERACTIONS: Click, type, select, submit
   - VISUAL VERIFICATION: Assert elements, text, styles
   - NAVIGATION: Page transitions, routing
   - FORMS: Input validation, submission, error display
   - RESPONSIVE DESIGN: Test on different viewports
   - ACCESSIBILITY: Keyboard navigation, screen reader support

4. **INCLUDE** browser test patterns:
   - Page object models (if applicable)
   - Reusable test helpers
   - Setup and teardown logic
   - Screenshots on failure
   - Proper wait strategies

#### Phase 7: Test Execution
1. **RUN** unit tests using DISCOVERED commands:
   - Examples: `npm test`, `vendor/bin/pest`, `pytest`, `go test`
   - EXECUTE with appropriate filters if available
   - CAPTURE output and test results

2. **RUN** integration tests:
   - EXECUTE using DISCOVERED integration test commands
   - VERIFY database interactions
   - CHECK API responses

3. **RUN** browser tests:
   - EXECUTE using DISCOVERED browser testing commands
   - VERIFY all acceptance criteria are met
   - CAPTURE screenshots/videos on failure

4. **ANALYZE** test results:
   - IF tests PASS:
     * SHOW success summary
     * DISPLAY coverage metrics
     * PROCEED to Phase 8
   - IF tests FAIL:
     * IDENTIFY failing tests
     * ANALYZE failure reasons
     * FIX implementation issues
     * RE-RUN tests
     * REPEAT until all tests pass

5. **RUN** linter using DISCOVERED tool:
   - Examples: `vendor/bin/pint`, `npm run lint`, `black`, `gofmt`
   - AUTO-FIX formatting issues if possible
   - REPORT any remaining issues

#### Phase 8: Story File Update
1. **UPDATE** Implementation Checklist in story file:
   - `[x]` Feature implementation (when core functionality complete)
   - `[x]` Unit tests (when unit test suite passes)
   - `[x]` Integration tests (when integration tests pass)
   - `[x]` Browser tests (when browser tests pass)
   - `[x]` Error handling (when error scenarios are handled)
   - `[x]` Loading states (when UI loading states implemented)
   - `[x]` Performance optimization (when performance requirements met)
   - `[x]` Accessibility (when accessibility features implemented)
   - `[x]` Security review (when security checks pass)
   - `[x]` Documentation (when inline docs complete)

2. **ADD** progress log entry:
   - TIMESTAMP: Current date/time
   - DESCRIPTION: What was implemented
   - FILES CREATED: List of new files
   - FILES MODIFIED: List of changed files
   - TECHNOLOGIES USED: Which parts of stack were utilized
   - TEST RESULTS: Test pass/fail status
   - DEVIATIONS: Any changes from original plan

3. **NOTE** implementation decisions:
   - KEY DECISIONS: Important architectural choices
   - TRADE-OFFS: Compromises made
   - FUTURE IMPROVEMENTS: Identified tech debt or enhancements

#### Phase 9: Implementation Summary
1. **DISPLAY** comprehensive summary:
   ```
   ✅ IMPLEMENTATION COMPLETE
   ============================
   Story: [story-id] - [Title]
   Stack: [Technologies Used]

   Generated Files:
   📄 Production Code:
   - [list of production files with paths]

   🧪 Unit Tests:
   - [list of unit test files]

   🔗 Integration Tests:
   - [list of integration test files]

   🌐 Browser Tests:
   - [list of browser test files]

   Test Results:
   ✅ Unit Tests: [X/X passed]
   ✅ Integration Tests: [X/X passed]
   ✅ Browser Tests: [X/X passed]
   ✅ Linting: Passed

   Coverage: [X%]

   Key Implementation Decisions:
   - [Decision 1]
   - [Decision 2]

   Next Steps:
   1. /sdd:story-save to commit implementation
   2. /sdd:story-review to move to code review
   3. Manual testing in browser at [URL]
   ```

### OUTPUTS
- Production code files (components, controllers, models, etc.)
- Unit test files with comprehensive coverage
- Integration test files for API/database/service interactions
- Browser test files covering all acceptance criteria
- Updated story file with progress and checklist updates
- Test execution results and coverage metrics

### RULES
- MUST load project context before generating any code
- MUST adapt ALL generated code to DISCOVERED stack
- NEVER assume framework - ALWAYS read technical-stack.md
- MUST generate tests for DISCOVERED testing framework
- MUST run tests and ensure they pass before completion
- MUST update story file with implementation progress
- MUST follow DISCOVERED coding standards exactly
- MUST generate browser tests for all acceptance criteria
- SHOULD run linter and fix formatting issues
- MUST NOT proceed if project context is missing
- MUST NOT modify code in "review", "qa", or "completed" stories without confirmation

## Examples

### Example 1: Laravel + Livewire Implementation
```bash
INPUT:
/sdd:story-implement STORY-AUTH-001

PROCESS:
→ Loading project context from /project-context/
→ Detected stack: Laravel 12 + Livewire 3 + Tailwind CSS 4 + Pest 4
→ Reading story: /stories/development/STORY-AUTH-001.md
→ Story: Implement Login Form
→ Generating Livewire component...
→ Generating unit tests...
→ Generating feature tests...
→ Generating browser tests...
→ Running tests: vendor/bin/pest
→ All tests passing ✅
→ Running linter: vendor/bin/pint
→ Code formatted ✅
→ Updating story file...

OUTPUT:
✅ IMPLEMENTATION COMPLETE
============================
Story: STORY-AUTH-001 - Implement Login Form
Stack: Laravel 12, Livewire 3, Tailwind CSS 4, Alpine.js, Pest 4

Generated Files:
📄 Production Code:
- app/Livewire/Auth/LoginForm.php
- resources/views/livewire/auth/login-form.blade.php
- app/Http/Controllers/Auth/LoginController.php

🧪 Unit Tests:
- tests/Unit/Livewire/LoginFormTest.php

🔗 Integration Tests:
- tests/Feature/Auth/LoginTest.php

🌐 Browser Tests:
- tests/Browser/Auth/LoginFormTest.php

Test Results:
✅ Unit Tests: 8/8 passed
✅ Feature Tests: 5/5 passed
✅ Browser Tests: 4/4 passed
✅ Linting: Passed

Coverage: 92%

Key Implementation Decisions:
- Used wire:model.live for real-time validation
- Implemented rate limiting (5 attempts per minute)
- Added remember me functionality with 30-day expiry
- Used Livewire validation attributes for clean code

Next Steps:
1. /sdd:story-save to commit implementation
2. /sdd:story-review to move to code review
3. Manual testing in browser at https://ccs-todo.test/login
```

### Example 2: React + TypeScript Implementation
```bash
INPUT:
/sdd:story-implement STORY-PROFILE-002

PROCESS:
→ Loading project context
→ Detected stack: React 18 + TypeScript + Vite + Jest + Playwright
→ Reading story: /stories/development/STORY-PROFILE-002.md
→ Story: User Profile Settings
→ Generating React components...
→ Generating custom hooks...
→ Generating unit tests...
→ Generating integration tests...
→ Generating Playwright tests...
→ Running tests: npm test
→ All tests passing ✅
→ Running linter: npm run lint
→ Code formatted ✅
→ Updating story file...

OUTPUT:
✅ IMPLEMENTATION COMPLETE
============================
Story: STORY-PROFILE-002 - User Profile Settings
Stack: React 18, TypeScript, Redux Toolkit, Vite, Jest, Playwright

Generated Files:
📄 Production Code:
- src/components/ProfileSettings.tsx
- src/components/ProfileSettings.module.css
- src/hooks/useProfileSettings.ts
- src/store/slices/profileSlice.ts
- src/api/profileApi.ts

🧪 Unit Tests:
- src/components/ProfileSettings.test.tsx
- src/hooks/useProfileSettings.test.ts
- src/store/slices/profileSlice.test.ts

🔗 Integration Tests:
- src/tests/integration/profile.test.tsx

🌐 Browser Tests:
- tests/e2e/profile-settings.spec.ts

Test Results:
✅ Unit Tests: 15/15 passed
✅ Integration Tests: 6/6 passed
✅ Browser Tests: 7/7 passed
✅ Linting: Passed

Coverage: 88%

Key Implementation Decisions:
- Implemented optimistic updates for better UX
- Added debounced auto-save (500ms delay)
- Used React.memo to prevent unnecessary re-renders
- Implemented form validation with Zod schema

Next Steps:
1. /sdd:story-save to commit implementation
2. /sdd:story-review to move to code review
3. Manual testing in browser at http://localhost:5173/profile
```

### Example 3: Implementation with Missing Context
```bash
INPUT:
/sdd:story-implement STORY-API-003

PROCESS:
→ Checking for /project-context/ directory
→ Directory not found

OUTPUT:
⚠️ Project Context Missing
==========================

Cannot generate implementation without project context.

The /project-context/ directory does not exist.
This directory defines your technical stack and coding standards,
which determines what code to generate.

Please run: /sdd:project-init

This will create:
- /project-context/technical-stack.md (defines your stack)
- /project-context/coding-standards.md (defines your standards)
- /project-context/development-process.md (defines your workflow)

After initialization, run /sdd:story-implement again.
```

### Example 4: Implementation with Failing Tests
```bash
INPUT:
/sdd:story-implement STORY-CART-004

PROCESS:
→ Loading project context
→ Detected stack: Django 5 + HTMX + Tailwind CSS + Pytest
→ Reading story: /stories/development/STORY-CART-004.md
→ Generating Django views...
→ Generating templates...
→ Generating unit tests...
→ Generating integration tests...
→ Running tests: pytest
→ 2 tests failed ❌
→ Analyzing failures...
→ Fixing cart total calculation...
→ Re-running tests: pytest
→ All tests passing ✅
→ Updating story file...

OUTPUT:
✅ IMPLEMENTATION COMPLETE
============================
Story: STORY-CART-004 - Shopping Cart
Stack: Django 5, HTMX, Tailwind CSS, Pytest, Playwright

Generated Files:
📄 Production Code:
- shop/views/cart.py
- shop/templates/cart/index.html
- shop/templates/cart/_item.html
- shop/models/cart.py
- shop/forms/cart.py

🧪 Unit Tests:
- shop/tests/test_cart_model.py
- shop/tests/test_cart_views.py

🔗 Integration Tests:
- shop/tests/test_cart_integration.py

🌐 Browser Tests:
- tests/browser/test_cart.py

Test Results:
✅ Unit Tests: 12/12 passed (2 fixed)
✅ Integration Tests: 5/5 passed
✅ Browser Tests: 8/8 passed
✅ Linting: Passed

Coverage: 95%

Key Implementation Decisions:
- Used Decimal for currency to avoid floating point errors
- Implemented HTMX for partial updates (no page reload)
- Added optimistic locking for concurrent cart updates
- Used Django signals for cart total recalculation

Issues Fixed During Implementation:
- Cart total calculation had rounding error
- Missing CSRF token in HTMX request

Next Steps:
1. /sdd:story-save to commit implementation
2. /sdd:story-review to move to code review
3. Manual testing in browser at http://localhost:8000/cart
```

## Edge Cases

### Story Not in Development
```
IF story found in /stories/backlog/:
- SUGGEST running /sdd:story-start first
- EXPLAIN that story must be moved to development
- OFFER to start story automatically
```

### Story Already Reviewed
```
IF story found in /stories/review/ or /stories/qa/:
- WARN about modifying reviewed code
- ASK for confirmation to proceed
- IF confirmed: Generate code
- IF declined: Exit gracefully
```

### Tests Fail Repeatedly
```
IF tests fail after 3 fix attempts:
- SHOW detailed error output
- SUGGEST manual debugging steps
- OFFER to save partial implementation
- MARK implementation as incomplete in story file
```

### Missing Dependencies
```
IF required packages not installed:
- DETECT missing dependencies from imports
- LIST missing packages
- SUGGEST installation command for DISCOVERED package manager
- OFFER to continue without those features
```

### Conflicting Files Exist
```
IF files already exist at generation paths:
- SHOW list of conflicting files
- ASK: Overwrite, skip, or merge?
- IF overwrite: Backup existing files first
- IF skip: Generate only non-conflicting files
- IF merge: Attempt intelligent merge
```

## Error Handling
- **Story ID missing and not on feature branch**: Return "Error: Story ID required. Usage: /sdd:story-implement <story_id>"
- **Invalid story ID format**: Return "Error: Invalid story ID format. Expected: STORY-XXX-NNN"
- **Project context missing**: Halt and suggest /sdd:project-init with detailed guidance
- **Story not found**: Return "Error: Story not found. Ensure it exists in /stories/development/"
- **Context files corrupted**: Show specific parsing errors and suggest manual review
- **Test execution fails**: Show error output and offer troubleshooting steps
- **Linter fails**: Show linting errors and auto-fix if possible

## Performance Considerations
- Load and parse project context once at start
- Cache parsed technical stack for session
- Generate files in parallel when possible
- Run tests with appropriate parallelization flags
- Skip unchanged files during re-generation
- Use incremental builds for DISCOVERED build tools

## Related Commands
- `/sdd:story-start` - Begin development before implementing
- `/sdd:story-save` - Commit implementation after completion
- `/sdd:story-review` - Move to code review after implementation
- `/sdd:story-continue` - Resume implementation if interrupted
- `/sdd:project-init` - Initialize project context first

## Constraints
- ✅ MUST load project context before any code generation
- ✅ MUST generate code matching DISCOVERED technical stack
- ✅ MUST create tests for DISCOVERED testing framework
- ✅ MUST run tests and ensure they pass
- ⚠️ NEVER assume technology choices - ALWAYS read context
- 📋 MUST update story file with implementation progress
- 🧪 MUST generate browser tests for acceptance criteria
- 🔧 SHOULD run linter and fix formatting
- 💾 MUST create comprehensive test coverage
