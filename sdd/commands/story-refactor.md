# /story-refactor

## Meta
- Version: 2.0
- Category: story-management
- Complexity: high
- Purpose: Create refactoring story based on code analysis and project standards

## Definition
**Purpose**: Analyze codebase against project standards and create a prioritized refactoring story with specific, actionable requirements.

**Syntax**: `/story-refactor [objective]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| objective | string | No | comprehensive | Refactoring focus area or general analysis | Any text phrase |

## INSTRUCTION: Create Refactoring Story

### INPUTS
- objective: Optional refactoring focus (e.g., "improve performance", "reduce complexity")
- Project context from `/project-context/` directory
- Current codebase state
- Active stories from `/stories/development/`

### PROCESS

#### Phase 1: Project Context Loading
1. **CHECK** if `/project-context/` directory exists
2. IF missing:
   - SUGGEST running `/project-init` first
   - EXIT with initialization guidance
3. **LOAD** project context from:
   - `/project-context/coding-standards.md` - Code quality rules and thresholds
   - `/project-context/technical-stack.md` - Framework patterns and best practices
   - `/project-context/development-process.md` - Quality requirements

#### Phase 2: Objective Definition
1. **PARSE** optional objective parameter
2. IF no objective provided:
   - SET analysis mode = comprehensive
   - ANALYZE all code quality dimensions
3. IF objective provided:
   - MAP objective to analysis focus areas:
     * "improve performance" → Database queries, N+1, caching, assets
     * "reduce complexity" → Cyclomatic complexity, nesting, method length
     * "extract reusable components" → Duplicate code, large components
     * "improve accessibility" → ARIA, keyboard nav, screen readers
     * "optimize for mobile" → Responsive design, touch, performance
     * Custom → Interpret and adapt analysis
   - PRIORITIZE findings aligned with objective

#### Phase 3: Code Analysis
1. **ANALYZE** codebase using DISCOVERED standards from project context:

   **Structure Issues**:
   - SCAN for functions exceeding length limits (from coding-standards.md)
   - CHECK nesting depth against complexity thresholds
   - IDENTIFY duplicate code blocks
   - FLAG complex conditionals

   **Naming Conventions**:
   - VERIFY variables follow naming patterns
   - CHECK consistency with style guide
   - VALIDATE function naming conventions

   **Framework Patterns** (from technical-stack.md):
   - Laravel: Eloquent patterns, validation, authorization
   - React: Hooks patterns, prop validation
   - Vue: Composition API, reactivity
   - Django: MVT patterns, form validation
   - Express: Middleware patterns, error handling
   - [DISCOVERED framework]: Apply specific patterns

   **Error Handling**:
   - CHECK error boundaries exist (per framework)
   - VERIFY comprehensive error handling
   - VALIDATE loading states present

   **Performance**:
   - IDENTIFY database N+1 queries
   - CHECK for missing caching opportunities
   - ANALYZE asset optimization
   - MEASURE component render efficiency

   **Accessibility** (if relevant):
   - VERIFY ARIA attributes present
   - CHECK keyboard navigation support
   - VALIDATE screen reader compatibility
   - TEST focus management

2. **PRIORITIZE** findings:

   IF comprehensive mode:
   - Priority 1: Security/bug issues requiring immediate attention
   - Priority 2: Maintainability issues affecting development velocity
   - Priority 3: Style and optimization improvements

   IF objective-focused mode:
   - Priority 1: Changes directly supporting objective
   - Priority 2: Critical security/bug issues (non-conflicting)
   - Priority 3: Supporting improvements complementing objective

#### Phase 4: Story ID Generation
1. **GENERATE** story ID in format `STORY-YYYY-NNN`:
   - YYYY = current year
   - NNN = next available number
2. **CHECK** for existing IDs across all story directories
3. **ENSURE** uniqueness

#### Phase 5: Story File Creation
1. **ENSURE** `/stories/backlog/` directory exists
2. **CREATE** story file at `/stories/backlog/[story-id].md`
3. **POPULATE** refactoring story template with:

   - Story ID and title (auto-generated based on objective)
   - Status: backlog
   - Today's date as "Started" date
   - Refactoring objective (clear goal statement)
   - Background (why refactoring needed, analysis summary)
   - Analysis Findings (organized by priority, with file:line references)
   - Requirements (specific, actionable refactoring tasks)
   - Acceptance Criteria (testable completion criteria)
   - Implementation Notes (technical guidance, patterns to follow)
   - Testing Requirements (verify functionality maintained)
   - Risk Assessment (potential risks, mitigation strategies)
   - Impact Analysis (affected components, tests, dependencies)

4. **REFERENCE** analysis findings:
   - Include file paths and line numbers
   - Show before/after code examples
   - Note pattern violations with framework references
   - Link to relevant coding standard sections

#### Phase 6: Completion Summary
1. **DISPLAY** refactoring summary:
   ```
   ✅ Refactoring Story Created
   ═══════════════════════════════════

   Story ID: [STORY-YYYY-NNN]
   Title: [Auto-generated Title]
   Location: /stories/backlog/[story-id].md
   Status: backlog

   Analysis Mode: [Comprehensive / Objective-focused: {objective}]

   Findings:
   - Priority 1 (Critical): [count] issues
   - Priority 2 (Important): [count] issues
   - Priority 3 (Nice to have): [count] improvements

   Files Affected: [count] files
   Estimated Complexity: [Low/Medium/High]
   ```

2. **SUGGEST** next steps:
   ```
   💡 NEXT STEPS:
   1. Review story in /stories/backlog/[story-id].md
   2. /story-start [story-id]      # Move to development when ready
   3. /project-status               # View all stories
   ```

### OUTPUTS
- `/stories/backlog/[story-id].md` - New refactoring story with comprehensive analysis
- Analysis summary with prioritized findings

### RULES
- MUST generate unique story ID across all directories
- MUST analyze using DISCOVERED project standards (no assumptions)
- MUST prioritize findings by objective if provided
- MUST include file paths and line numbers in findings
- MUST provide specific, actionable refactoring tasks
- SHOULD include before/after code examples
- SHOULD reference framework patterns from technical-stack.md
- NEVER suggest refactoring without analysis evidence
- ALWAYS include risk assessment for breaking changes
- MUST verify all existing tests will pass post-refactoring

## Refactoring Story Template

```markdown
# [STORY-ID]: [Refactoring Title]

## Status: backlog
**Started:** [Today's Date]
**Completed:**
**Branch:** (none - in backlog)

## Objective
[Clear statement of refactoring goal based on analysis]

## Background
[Why this refactoring is needed - analysis context, pain points, violations found]

## Analysis Findings

### Priority 1: Critical
- [ ] **[File:Line]**: [Issue description]
  - Current: [Code example or pattern]
  - Standard: [Expected pattern from coding-standards.md]
  - Impact: [Why this matters]

### Priority 2: Important
- [ ] **[File:Line]**: [Issue description]
  - Current: [Code example]
  - Suggested: [Improved pattern]
  - Benefit: [Improvement gained]

### Priority 3: Nice to Have
- [ ] **[File:Line]**: [Improvement opportunity]
  - Enhancement: [What to improve]
  - Justification: [Why it helps]

## Requirements

### R1: [Requirement Title]
**What**: [Specific change needed]
**Why**: [Business/technical justification]
**How**: [Suggested approach or pattern]
**Tests**: [Impact on existing tests]
**Dependencies**: [Related components]

### R2: [Requirement Title]
[Same structure as R1]

## Acceptance Criteria
- [ ] All Priority 1 issues resolved
- [ ] Code quality metrics maintained or improved
- [ ] All existing functionality works identically
- [ ] All tests pass (no failures introduced)
- [ ] Code follows [framework] patterns from technical-stack.md
- [ ] Performance metrics maintained or improved
- [ ] Documentation updated where necessary

## Implementation Notes

**Approach**: [Recommended refactoring strategy]
**Stack**: [Auto-populated from technical-stack.md]
**Patterns**: [Framework-specific patterns to apply]
**Tools**: [Linters, formatters, static analysis tools to use]

## Testing Requirements

### Existing Tests
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All E2E tests pass
- [ ] No regressions in test coverage

### New Tests
- [ ] [New test scenario 1]
- [ ] [New test scenario 2]

### Manual Testing
- [ ] [Manual verification step 1]
- [ ] [Manual verification step 2]

## Risk Assessment

### High Risk
- **[Risk description]**: [Mitigation strategy]

### Medium Risk
- **[Risk description]**: [Mitigation strategy]

### Low Risk
- **[Risk description]**: [Mitigation strategy]

## Impact Analysis

**Components Affected**: [List of components/modules]
**Tests Affected**: [List of test files]
**Dependencies**: [External dependencies or other stories]
**Breaking Changes**: [Yes/No - details if yes]

## Progress Log
- [Today]: Created refactoring story from code analysis

## Rollback Plan
[How to rollback if issues arise during refactoring]

## Lessons Learned
[To be filled when complete]
```

## Examples

### Example 1: Comprehensive Refactoring
```bash
INPUT:
/story-refactor

OUTPUT:
→ Checking project context...
→ Loading coding standards and framework patterns...
→ Analyzing codebase comprehensively...
→ Found 23 issues across 8 files

✅ Refactoring Story Created
═══════════════════════════════════

Story ID: STORY-2025-012
Title: Comprehensive Code Quality Improvements
Location: /stories/backlog/STORY-2025-012.md
Status: backlog

Analysis Mode: Comprehensive

Findings:
- Priority 1 (Critical): 3 issues
- Priority 2 (Important): 12 issues
- Priority 3 (Nice to have): 8 improvements

Files Affected: 8 files
Estimated Complexity: High

💡 NEXT STEPS:
1. Review story in /stories/backlog/STORY-2025-012.md
2. /story-start STORY-2025-012      # Move to development when ready
3. /project-status                   # View all stories
```

### Example 2: Performance-Focused Refactoring
```bash
INPUT:
/story-refactor improve performance

OUTPUT:
→ Checking project context...
→ Loading coding standards and framework patterns...
→ Analyzing for performance issues...
→ Scanning database queries, caching, assets...
→ Found 7 performance issues across 5 files

✅ Refactoring Story Created
═══════════════════════════════════

Story ID: STORY-2025-013
Title: Performance Optimization Refactoring
Location: /stories/backlog/STORY-2025-013.md
Status: backlog

Analysis Mode: Objective-focused (improve performance)

Findings:
- Priority 1 (Performance): 7 issues
  • 3 N+1 query problems
  • 2 missing cache opportunities
  • 2 unoptimized asset loads
- Priority 2 (Critical): 0 issues
- Priority 3 (Supporting): 2 improvements

Files Affected: 5 files
Estimated Complexity: Medium

💡 NEXT STEPS:
1. Review story in /stories/backlog/STORY-2025-013.md
2. /story-start STORY-2025-013      # Move to development when ready
3. /project-status                   # View all stories
```

### Example 3: Accessibility Refactoring
```bash
INPUT:
/story-refactor improve accessibility

OUTPUT:
→ Checking project context...
→ Analyzing ARIA, keyboard nav, screen reader support...
→ Found 15 accessibility issues across 6 components

✅ Refactoring Story Created
═══════════════════════════════════

Story ID: STORY-2025-014
Title: Accessibility Compliance Refactoring
Location: /stories/backlog/STORY-2025-014.md
Status: backlog

Analysis Mode: Objective-focused (improve accessibility)

Findings:
- Priority 1 (Accessibility): 15 issues
  • 8 missing ARIA attributes
  • 4 keyboard navigation gaps
  • 3 screen reader issues
- Priority 2 (Critical): 0 issues
- Priority 3 (Supporting): 5 improvements

Files Affected: 6 components
Estimated Complexity: Medium

💡 NEXT STEPS:
1. Review story in /stories/backlog/STORY-2025-014.md
2. /story-start STORY-2025-014      # Move to development when ready
3. /project-status                   # View all stories
```

## Edge Cases

### No Project Context
- DETECT missing `/project-context/` directory
- SUGGEST running `/project-init`
- CANNOT proceed without coding standards
- EXIT with clear guidance

### No Code Issues Found
- REPORT clean codebase status
- SUGGEST code is already well-refactored
- OFFER to create story anyway for future improvements
- DOCUMENT analysis results even if no issues

### Framework Not Recognized
- DETECT framework from technical-stack.md
- FALL BACK to generic code analysis if unknown
- WARN that framework-specific patterns unavailable
- CONTINUE with structure/naming analysis

### Conflicting Standards
- DETECT contradictions in project context
- LOG warnings about conflicts
- ASK user to clarify which standard applies
- DOCUMENT decision in story

## Error Handling
- **Missing /project-context/**: Exit with suggestion to run `/project-init`
- **No coding-standards.md**: Cannot analyze - critical file missing
- **Analysis errors**: Log specific files causing issues, continue with others
- **Invalid objective**: Interpret broadly or ask user for clarification

## Performance Considerations
- Code analysis may take 30-60 seconds for large codebases
- Show progress indicators during analysis
- Cache project context for session
- Analyze only relevant files based on objective

## Related Commands
- `/project-init` - Initialize project structure with standards
- `/project-brief` - Define project goals and constraints
- `/story-new` - Create feature story
- `/story-start [id]` - Begin refactoring work
- `/project-status` - View all stories

## Constraints
- ✅ MUST use DISCOVERED standards (no assumptions)
- ✅ MUST include file:line references in findings
- ✅ MUST prioritize by objective when provided
- ⚠️ NEVER suggest refactoring without evidence
- 📋 MUST provide specific, actionable tasks
- 🔧 SHOULD include before/after examples
- 💾 MUST assess risk for breaking changes
- 🧪 MUST verify existing tests will pass