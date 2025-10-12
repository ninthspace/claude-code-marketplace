# /sdd:story-complete

## Meta
- Version: 2.0
- Category: workflow
- Complexity: comprehensive
- Purpose: Archive completed story, extract learnings, and update project metrics

## Definition
**Purpose**: Archive a shipped story, capture comprehensive lessons learned, extract reusable components, and update project metrics for continuous improvement.

**Syntax**: `/sdd:story-complete <story_id>`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| story_id | string | Yes | - | Story identifier (e.g., "STORY-2025-001") | Must match pattern STORY-\d{4}-\d{3} |

## INSTRUCTION: Archive Completed Story

### INPUTS
- story_id: Story identifier from /docs/stories/completed/
- Story file with completion data
- Project context from /docs/project-context/

### PROCESS

#### Phase 1: Verification
1. **VERIFY** story is in `/docs/stories/completed/` directory
2. IF NOT in completed:
   - CHECK `/docs/stories/qa/` - suggest running `/sdd:story-ship` first
   - CHECK `/docs/stories/review/` - suggest completing QA and shipping
   - EXIT with appropriate guidance
3. **READ** story file and extract:
   - Start date and completion date
   - All progress log entries
   - Test results and QA outcomes
   - Implementation checklist status
   - Success criteria completion

#### Phase 2: Metrics Collection
1. **CALCULATE** timeline metrics:
   - Total duration (start to completion)
   - Time in each stage (development, review, qa)
   - Calendar days vs active working days

2. **ANALYZE** story progress log to determine:
   - Planning time: Initial setup and design
   - Implementation time: Active coding
   - Testing time: Test writing and debugging
   - Review/QA time: Code review and validation

3. **EXTRACT** quality metrics:
   - Bugs found in review (count from progress log)
   - Bugs found in QA (count from progress log)
   - Test coverage achieved (from test results)
   - Number of commits (from git log)
   - Files changed (from git log)

4. **ASSESS** business impact:
   - Features delivered vs planned
   - User-facing improvements
   - Performance improvements
   - Technical debt addressed

5. **GENERATE** metrics summary:
   ```
   📊 STORY METRICS
   ════════════════

   Timeline:
   - Started: [YYYY-MM-DD]
   - Completed: [YYYY-MM-DD]
   - Total duration: [X] days ([Y] working days)
   - Development: [X] days
   - Review: [Y] days
   - QA: [Z] days

   Effort Breakdown:
   - Planning: [X] hours
   - Implementation: [Y] hours
   - Testing: [Z] hours
   - Review/QA: [W] hours
   - Total: [TOTAL] hours

   Quality Metrics:
   - Commits: [count]
   - Files changed: [count]
   - Bugs found in review: [count]
   - Bugs found in QA: [count]
   - Test coverage: [X%]
   - Tests added: [count]

   Velocity:
   - Story points (if applicable): [points]
   - Actual vs estimated: [comparison]
   ```

#### Phase 3: Lessons Learned Capture
1. **PROMPT** user for lessons learned (if not in story file):
   - What went well?
   - What could be improved?
   - Any surprises or unexpected challenges?
   - Technical insights gained?
   - Process improvements identified?

2. **ANALYZE** story file for:
   - Challenges documented in progress log
   - Solutions that worked well
   - Technical approaches that succeeded/failed
   - Testing strategies effectiveness

3. **COMPILE** comprehensive lessons:
   ```
   📚 LESSONS LEARNED
   ══════════════════

   What Went Well:
   - [Success 1: with specific details]
   - [Success 2: with specific details]
   - [Success 3: with specific details]

   What Could Improve:
   - [Improvement 1: with action items]
   - [Improvement 2: with action items]
   - [Improvement 3: with action items]

   Surprises & Challenges:
   - [Unexpected finding 1]
   - [Unexpected finding 2]

   Technical Insights:
   - [New technique/pattern learned]
   - [Library/tool discovery]
   - [Architecture decision validated/challenged]

   Process Improvements:
   - [Workflow enhancement suggestion]
   - [Tool/automation opportunity]

   For Next Time:
   - [ ] [Specific action item 1]
   - [ ] [Specific action item 2]
   - [ ] [Specific action item 3]
   ```

#### Phase 4: Documentation Updates
1. **IDENTIFY** documentation that needs updating:
   - README files with new features
   - API documentation with new endpoints
   - Architecture diagrams with changes
   - User guides with new workflows

2. **EXTRACT** reusable patterns from implementation:
   - Code patterns to standardize
   - Configuration templates
   - Testing approaches
   - Deployment procedures

3. **UPDATE** project context if needed:
   - Add new tools to `/docs/project-context/technical-stack.md`
   - Document new patterns in `/docs/project-context/coding-standards.md`
   - Update process learnings in `/docs/project-context/development-process.md`

#### Phase 5: Reusable Component Extraction
1. **SCAN** implementation for reusable code:
   - Utility functions to extract
   - Components to generalize
   - Middleware/helpers to share
   - Configuration patterns

2. **IDENTIFY** candidates for:
   - Shared component library
   - Internal utility package
   - Starter templates
   - Boilerplate generators

3. **DOCUMENT** reusable assets:
   ```
   🔧 REUSABLE COMPONENTS
   ═════════════════════

   Created:
   - [Component/utility name]: [path] - [description]
   - [Component/utility name]: [path] - [description]

   Patterns Documented:
   - [Pattern name]: [location] - [use case]

   Suggested Extractions:
   - [ ] [Code to extract]: [benefit]
   - [ ] [Component to generalize]: [benefit]
   ```

#### Phase 6: Story Archival

1. **UPDATE** story file with completion data using **EXACT STRUCTURE**:

   **APPEND** the following sections to the story file in this exact order:

   ```markdown
   ---

   ## 📊 COMPLETION METRICS

   **Archived:** [YYYY-MM-DD HH:MM]
   **Total Duration:** [X] calendar days ([Y] working days)
   **Status:** Completed and Archived

   ### Timeline
   - **Started:** [YYYY-MM-DD]
   - **Completed:** [YYYY-MM-DD]
   - **Development:** [X] days
   - **Review:** [Y] days
   - **QA:** [Z] days

   ### Effort
   - **Planning:** [X] hours
   - **Implementation:** [Y] hours
   - **Testing:** [Z] hours
   - **Review/QA:** [W] hours
   - **Total:** [TOTAL] hours

   ### Quality
   - **Commits:** [count]
   - **Files Changed:** [count]
   - **Tests Added:** [count]
   - **Test Coverage:** [X%]
   - **Bugs in Review:** [count]
   - **Bugs in QA:** [count]

   ### Velocity
   - **Story Points:** [points] (if applicable)
   - **Estimated vs Actual:** [comparison]

   ---

   ## 📚 RETROSPECTIVE

   ### What Went Well
   - [Specific success 1 with details]
   - [Specific success 2 with details]
   - [Specific success 3 with details]

   ### What Could Improve
   - [Specific improvement 1 with action]
   - [Specific improvement 2 with action]
   - [Specific improvement 3 with action]

   ### Surprises & Challenges
   - [Unexpected finding 1]
   - [Unexpected finding 2]

   ### Technical Insights
   - [Technical learning 1]
   - [Technical learning 2]
   - [Technical learning 3]

   ### Process Improvements
   - [Process improvement 1]
   - [Process improvement 2]

   ### Action Items for Next Time
   - [ ] [Specific action 1]
   - [ ] [Specific action 2]
   - [ ] [Specific action 3]

   ---

   ## 🔧 REUSABLE COMPONENTS

   ### Components Created
   - **[Component Name]**: `[file path]` - [description]
   - **[Component Name]**: `[file path]` - [description]

   ### Patterns Documented
   - **[Pattern Name]**: [location] - [use case]
   - **[Pattern Name]**: [location] - [use case]

   ### Extraction Opportunities
   - [ ] **[Code to Extract]**: [benefit]
   - [ ] **[Component to Generalize]**: [benefit]

   ---

   ## 📈 IMPACT ASSESSMENT

   ### User Impact
   [Description of how this benefits end users]

   ### Business Impact
   [Description of business value delivered]

   ### Technical Impact
   [Description of technical improvements or debt addressed]

   ### Performance Metrics (if applicable)
   - [Metric 1]: [baseline] → [achieved]
   - [Metric 2]: [baseline] → [achieved]

   ---

   ## 🎯 KEY ACHIEVEMENTS

   - [Major achievement 1 with specific deliverable]
   - [Major achievement 2 with specific deliverable]
   - [Major achievement 3 with specific deliverable]

   ---

   ## 🚀 TECHNICAL ADDITIONS

   - [New capability/feature 1]
   - [New pattern/approach 2]
   - [Infrastructure/tooling improvement 3]

   ---

   ## 📋 FOLLOW-UP ITEMS

   ### Technical Debt
   - [Technical debt item 1]
   - [Technical debt item 2]

   ### Future Enhancements
   - [Enhancement opportunity 1]
   - [Enhancement opportunity 2]

   ### Related Stories
   - [Dependency or follow-up story 1]
   - [Dependency or follow-up story 2]

   ---

   **Archive Status:** ✅ Complete
   **Indexed:** Yes - `/docs/stories/completed/INDEX.md`
   ```

   **NOTES:**
   - ALL sections are REQUIRED (use "N/A" or "None" if section doesn't apply)
   - Use consistent formatting with exact heading levels shown
   - Always include separator lines (`---`) between major sections
   - Timestamps must use format: YYYY-MM-DD HH:MM
   - Numbers should include units (days, hours, count, %)
   - All lists must use consistent bullet format (- or checkbox [ ])

2. **RENAME** story file:
   - FROM: `/docs/stories/completed/[story-id].md`
   - TO: `/docs/stories/completed/[ARCHIVED]-[story-id].md`

3. **CREATE OR UPDATE** `/docs/stories/completed/INDEX.md`:

   **IF FILE DOESN'T EXIST**, create with this header:
   ```markdown
   # Completed Stories Index

   A chronological index of all completed and archived stories with key metrics.

   ## Stories

   ```

   **THEN ADD** story entry using this EXACT format:
   ```markdown
   ### [STORY-ID] - [Title]

   - **Completed:** [YYYY-MM-DD]
   - **Duration:** [X] days ([Y] working days)
   - **Test Coverage:** [Z%]
   - **Impact:** [one-line business impact summary]
   - **File:** [`[ARCHIVED]-[STORY-ID].md`](./%5BARCHIVED%5D-[STORY-ID].md)

   ```

   **NOTES:**
   - Add newest entries at the TOP (reverse chronological order)
   - Maintain consistent spacing between entries (one blank line)
   - Use URL-encoded file links for [ARCHIVED] prefix

4. **COMPRESS** large artifacts (optional):
   - Screenshots folder
   - Test recordings
   - Large log files

#### Phase 7: Project Metrics Update
1. **UPDATE** project-level metrics:
   - Increment completed stories count
   - Add to velocity tracking
   - Update cycle time averages
   - Calculate success rate

2. **CREATE OR UPDATE** `/docs/project-context/project-metrics.md`:
   - Total stories completed
   - Average cycle time
   - Average time per stage
   - Quality metrics trends
   - Velocity trends

3. **IDENTIFY** trends:
   - Improving or degrading metrics
   - Bottlenecks in process
   - Quality improvements
   - Velocity patterns

#### Phase 8: Completion Report
1. **GENERATE** comprehensive completion report:
   ```
   ✅ STORY COMPLETION REPORT
   ══════════════════════════
   Story: [STORY-ID] - [Title]
   Archived: [YYYY-MM-DD]

   SUMMARY:
   Successfully delivered [description of implementation] which
   [business impact and user value provided].

   KEY ACHIEVEMENTS:
   • [Achievement 1: specific deliverable]
   • [Achievement 2: specific deliverable]
   • [Achievement 3: specific deliverable]

   TECHNICAL ADDITIONS:
   • [New capability/feature added]
   • [New pattern/approach implemented]
   • [Infrastructure/tooling improvement]

   QUALITY METRICS:
   • Duration: [X] days ([Y] working days)
   • Test coverage: [Z%]
   • Bugs found: [review: X, qa: Y]
   • Performance: [metrics if applicable]

   TEAM LEARNINGS:
   • [Key learning 1]
   • [Key learning 2]
   • [Key learning 3]

   REUSABLE ASSETS:
   • [Component/utility created]
   • [Pattern documented]
   • [Template created]

   FOLLOW-UP ITEMS:
   • [Technical debt to address]
   • [Future enhancement opportunity]
   • [Process improvement action]

   IMPACT:
   • Users: [description of user benefit]
   • Business: [description of business value]
   • Technical: [description of technical improvement]
   ```

2. **DISPLAY** next steps:
   ```
   💡 NEXT STEPS:
   1. Review follow-up items for backlog
   2. Share learnings with team
   3. Update related documentation
   4. /sdd:project-status to view remaining stories
   5. /sdd:story-new to begin next story
   ```

### OUTPUTS
- `/docs/stories/completed/[ARCHIVED]-[story-id].md` - Archived story with metrics and learnings
- `/docs/stories/completed/INDEX.md` - Updated story index (created or updated)
- `/docs/project-context/sdd:project-metrics.md` - Updated project metrics (created or updated)
- Updated documentation files (as needed)
- Completion report (displayed to user)

### RULES
- MUST verify story is in `/docs/stories/completed/` before processing
- MUST collect comprehensive metrics from story timeline
- MUST capture lessons learned (prompt user if not documented)
- MUST use EXACT document structure defined in Phase 6 Step 1 (no variation allowed)
- MUST include ALL required sections (use "N/A" or "None" if not applicable)
- MUST maintain consistent formatting: heading levels, bullet styles, separators
- MUST use standard timestamp format: YYYY-MM-DD HH:MM
- SHOULD identify reusable components and patterns
- SHOULD update project-level metrics
- MUST rename file with [ARCHIVED] prefix
- MUST create or update `/docs/stories/completed/INDEX.md` with exact format specified
- MUST add newest INDEX entries at TOP in reverse chronological order
- ALWAYS generate detailed completion report
- SHOULD update project context if new tools/patterns introduced
- NEVER delete story files (archive only)
- NEVER omit required sections from document structure

## Examples

### Example 1: Complete Story with Full Metrics
```bash
INPUT:
/sdd:story-complete STORY-2025-001

PROCESS:
→ Verifying story location...
→ Found in /docs/stories/completed/STORY-2025-001.md
→ Analyzing story timeline and progress log...
→ Calculating metrics...
→ Extracting lessons learned...
→ Identifying reusable components...

OUTPUT:
✅ STORY COMPLETION REPORT
══════════════════════════
Story: STORY-2025-001 - User Authentication System
Archived: 2025-03-15

SUMMARY:
Successfully delivered a complete user authentication system with
email/password login, registration, password reset, and session
management. This provides secure user access and enables all future
user-specific features.

KEY ACHIEVEMENTS:
• Implemented secure authentication with bcrypt hashing
• Added comprehensive test coverage (95% for auth components)
• Created reusable authentication middleware
• Documented authentication patterns for future features

TECHNICAL ADDITIONS:
• AuthMiddleware for route protection
• SessionManager utility for token handling
• Reusable LoginForm and RegistrationForm components
• Comprehensive authentication test suite

QUALITY METRICS:
• Duration: 12 days (9 working days)
• Test coverage: 95%
• Bugs found: review: 2, qa: 1
• Performance: Login < 200ms, avg 150ms

TEAM LEARNINGS:
• JWT implementation was simpler than session-based auth
• Browser testing caught critical edge cases missed in unit tests
• Early security review prevented potential vulnerabilities
• Test-driven approach significantly reduced bugs in QA

REUSABLE ASSETS:
• AuthMiddleware: app/Middleware/AuthMiddleware.php
• SessionManager: app/Utils/SessionManager.php
• Authentication test helpers: tests/Helpers/AuthHelper.php
• LoginForm component: resources/views/components/LoginForm.blade.php

FOLLOW-UP ITEMS:
• Consider adding OAuth providers (Google, GitHub)
• Implement 2FA in future security story
• Add rate limiting to prevent brute force attacks
• Extract auth utilities to shared package

IMPACT:
• Users: Secure account creation and access to personalized features
• Business: Foundation for user-specific features and data
• Technical: Established authentication pattern for all future features

📊 STORY METRICS
════════════════

Timeline:
- Started: 2025-03-03
- Completed: 2025-03-15
- Total duration: 12 days (9 working days)
- Development: 6 days
- Review: 2 days
- QA: 1 day

Effort Breakdown:
- Planning: 4 hours
- Implementation: 28 hours
- Testing: 12 hours
- Review/QA: 6 hours
- Total: 50 hours

Quality Metrics:
- Commits: 24
- Files changed: 18
- Bugs found in review: 2
- Bugs found in QA: 1
- Test coverage: 95%
- Tests added: 36

📚 LESSONS LEARNED
══════════════════

What Went Well:
- Test-driven development caught edge cases early
- Browser testing revealed UX issues unit tests missed
- Early security review prevented auth vulnerabilities
- Modular design made testing straightforward

What Could Improve:
- Could have started with browser tests earlier
- Initial API design needed refinement during review
- Password reset flow took longer than estimated
- Documentation could have been written alongside code

Surprises & Challenges:
- JWT library had better DX than expected
- Session persistence across subdomains required extra config
- Password reset tokens needed expiration strategy
- Browser autofill behavior required special handling

Technical Insights:
- JWT significantly simpler than session-based auth for SPA
- httpOnly cookies provide better security than localStorage
- Middleware composition pattern works well for auth
- Playwright's auto-wait eliminated flaky tests

Process Improvements:
- Start browser tests earlier in development
- Document API contracts before implementation
- Include security review checklist in story template
- Create reusable test data factories upfront

For Next Time:
- [ ] Write API documentation as first step
- [ ] Create browser test scaffold when starting story
- [ ] Review security checklist during implementation
- [ ] Extract utilities earlier to improve testability

💡 NEXT STEPS:
1. Review follow-up items for backlog
2. Share learnings with team
3. Update authentication documentation
4. /sdd:project-status to view remaining stories
5. /sdd:story-new to begin next story

→ Story archived: /docs/stories/completed/[ARCHIVED]-STORY-2025-001.md
→ Story index updated: /docs/stories/completed/INDEX.md
→ Project metrics updated: /docs/project-context/sdd:project-metrics.md
```

### Example 2: Story Not Ready for Archival
```bash
INPUT:
/sdd:story-complete STORY-2025-002

PROCESS:
→ Searching for STORY-2025-002...
→ Found in /docs/stories/qa/

OUTPUT:
❌ Story Not Ready for Completion
═══════════════════════════════

Story: STORY-2025-002 - User Profile Management
Location: /docs/stories/qa/

The story has not been shipped to production yet.

Current Status: qa
Required Status: complete (in /docs/stories/completed/)

NEXT STEPS:
1. /sdd:story-ship STORY-2025-002    # Ship to production
2. /sdd:story-complete STORY-2025-002  # Archive after shipping

Note: Stories must be shipped before archival to ensure
all deployment data and production metrics are captured.
```

### Example 3: Story Missing Lessons Learned
```bash
INPUT:
/sdd:story-complete STORY-2025-003

PROCESS:
→ Verifying story location...
→ Found in /docs/stories/completed/STORY-2025-003.md
→ Analyzing story data...
→ Lessons learned section is empty

What went well in this story? (Enter each, then empty line when done)
> Test-driven approach worked great
> Reused authentication patterns from STORY-001
> Performance exceeded expectations
>

What could be improved? (Enter each, then empty line when done)
> Initial design needed iteration
> Could have communicated progress better
>

Any technical insights gained?
> Discovered excellent caching pattern for profile data
> Learned avatar upload optimization techniques
>

→ Capturing lessons learned...
→ Generating completion report...

OUTPUT:
[Full completion report with user-provided lessons learned integrated]
```

## Edge Cases

### Story in Wrong Directory
- DETECT story not in `/docs/stories/completed/`
- IDENTIFY current location (qa, review, development, backlog)
- SUGGEST appropriate next command to progress story
- OFFER to force complete if user confirms (with warning)

### Missing Metrics Data
- DETECT incomplete progress log
- CALCULATE what metrics are possible
- NOTE missing data in report
- SUGGEST improving progress logging for future stories
- CONTINUE with available data

### Empty Lessons Learned
- DETECT empty "Lessons Learned" section
- PROMPT user for key learnings interactively
- ANALYZE progress log for challenges and solutions
- GENERATE lessons from available story data
- ENCOURAGE documenting lessons during development

### Project Metrics File Doesn't Exist
- CREATE `/docs/project-context/sdd:project-metrics.md` with initial structure
- INITIALIZE with current story as first entry
- SET baseline metrics
- CONTINUE with normal completion

## Error Handling
- **Story ID missing**: Return "Error: Story ID required. Usage: /sdd:story-complete <story_id>"
- **Invalid story ID format**: Return "Error: Invalid story ID format. Expected: STORY-YYYY-NNN"
- **Story not found**: Search all directories and report current location
- **Story not shipped**: Suggest completing QA and shipping before archival
- **File rename error**: Log error, keep original name, note in report
- **Metrics calculation error**: Use available data, note gaps in report

## Performance Considerations
- Parse story file and git log only once
- Cache git log results for session
- Generate report asynchronously if processing large story
- Compress artifacts in background after report generation

## Related Commands
- `/sdd:story-ship` - Ship story to production before archival
- `/sdd:story-metrics` - View project-wide metrics and trends
- `/sdd:project-status` - View all project stories and progress
- `/sdd:story-new` - Create next story to work on

## Constraints
- ✅ MUST verify story is shipped before archival
- ✅ MUST collect comprehensive metrics
- ✅ MUST capture lessons learned (prompt if missing)
- 📋 MUST use exact document structure from Phase 6 Step 1 - NO VARIATION
- 📋 MUST include ALL sections even if content is "N/A" or "None"
- 📋 MUST maintain consistent heading levels, bullet styles, and separators
- 📊 MUST create or update `/docs/stories/completed/INDEX.md` with exact format
- 📊 MUST add newest INDEX entries at TOP (reverse chronological)
- 📊 SHOULD update project-level metrics
- 🔧 SHOULD identify reusable components
- 📝 MUST generate detailed completion report
- 💾 MUST rename file with [ARCHIVED] prefix
- 🚫 NEVER delete story files
- 🚫 NEVER omit required sections
- ⏱️ MUST use standard timestamp format: YYYY-MM-DD HH:MM
