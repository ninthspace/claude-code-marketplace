# /story-patterns

## Meta
- Version: 2.0
- Category: story-analysis
- Complexity: high
- Purpose: Identify recurring patterns in completed stories to extract reusable knowledge and improve processes

## Definition
**Purpose**: Analyze completed stories to discover technical patterns, common problems, success strategies, code reusability opportunities, and anti-patterns.

**Syntax**: `/story-patterns [category]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| category | string | No | "all" | Pattern category to analyze (technical, problems, success, code, process, all) | One of: technical, problems, success, code, process, all |

## INSTRUCTION: Analyze Story Patterns

### INPUTS
- category: Optional pattern category filter (defaults to all)
- Completed story files from `/stories/completed/`
- Optional: Stories from other stages for trend analysis

### PROCESS

#### Phase 1: Story Data Collection
1. **SCAN** `/stories/completed/` directory for all `.md` files
2. **PARSE** each story file to extract:
   - Implementation approach (from Technical Notes)
   - Technologies used (from Stack)
   - Problems encountered (from Progress Log)
   - Solutions applied (from Progress Log)
   - Success criteria and outcomes
   - Test cases and results
   - Code patterns (from Implementation Checklist)
   - Dependencies and integrations
   - Lessons learned

3. **CATEGORIZE** extracted data by type:
   - Technical implementations
   - Problem/solution pairs
   - Success factors
   - Code structures
   - Process workflows

4. **FILTER** by category if specified

#### Phase 2: Technical Pattern Analysis
1. **IDENTIFY** common implementation approaches:
   - Group stories by similar technical solutions
   - Count frequency of each approach
   - Extract specific examples

2. **DETECT** recurring architectures:
   - Design patterns (MVC, Repository, etc.)
   - Integration patterns (API, Queue, Event)
   - Data patterns (Migration, Seeding, etc.)

3. **ANALYZE** technology combinations:
   - Frequently paired technologies
   - Successful tech stack patterns

4. **DISPLAY** technical patterns:
   ```
   🔧 TECHNICAL PATTERNS FOUND
   ══════════════════════════════════

   Common Implementations:

   Pattern: JWT Authentication with Refresh Tokens
   - Used in: [X] stories ([STORY-IDs])
   - Success rate: [X]%
   - Avg implementation time: [X] days
   - Reusability: High
   - Action: Extract as auth module

   Pattern: Queue-based Background Processing
   - Used in: [X] stories ([STORY-IDs])
   - Success rate: [X]%
   - Technologies: Laravel Queue, Redis
   - Action: Create template

   Recurring Architectures:
   - Service Layer Pattern: [X] stories
   - Repository Pattern: [X] stories
   - Event-Driven: [X] stories

   Technology Combinations:
   - Livewire + Alpine.js: [X] stories
   - Pest + Browser Tests: [X] stories
   ```

#### Phase 3: Problem Pattern Analysis
1. **EXTRACT** problems from progress logs
2. **CATEGORIZE** problems by type:
   - Technical issues
   - Integration challenges
   - Performance problems
   - Testing difficulties
   - Deployment issues

3. **COUNT** frequency of each problem type
4. **LINK** problems to solutions
5. **IDENTIFY** root causes

6. **DISPLAY** problem patterns:
   ```
   ⚠️  RECURRING CHALLENGES
   ══════════════════════════════════

   Common Problems:

   Problem: N+1 Query Performance Issues
   - Occurred: [X] times
   - Stories: [STORY-IDs]
   - Root cause: Missing eager loading
   - Solution pattern: Add `with()` to queries
   - Prevention: Code review checklist item

   Problem: CORS Issues in API Integration
   - Occurred: [X] times
   - Stories: [STORY-IDs]
   - Root cause: Middleware configuration
   - Solution pattern: Configure cors.php
   - Prevention: API setup template

   Frequent Blockers:
   - Third-party API rate limits: [X] occurrences
     Mitigation: Implement caching layer
   - Test environment setup: [X] occurrences
     Mitigation: Docker compose template
   ```

#### Phase 4: Success Pattern Analysis
1. **IDENTIFY** high-performing stories:
   - Fast completion times
   - Zero bugs in QA
   - First-time pass in review

2. **EXTRACT** success factors:
   - Common approaches
   - Best practices applied
   - Tools and techniques used

3. **CALCULATE** success rates by pattern
4. **DETERMINE** velocity impact

5. **DISPLAY** success patterns:
   ```
   ✅ SUCCESS PATTERNS
   ══════════════════════════════════

   High-Velocity Patterns:

   Approach: TDD with Feature Tests First
   - Used in: [X] stories
   - Success rate: [X]%
   - Avg completion: [X] days faster
   - Key factors:
     • Clear test cases upfront
     • Fewer bugs in QA
     • Confident refactoring
   - Recommendation: Adopt as standard

   Approach: Component-First UI Development
   - Used in: [X] stories
   - Success rate: [X]%
   - Benefits:
     • Reusable components
     • Consistent design
     • Faster iterations
   - Best for: UI-heavy features

   High-Quality Patterns:
   - Livewire component testing: [X]% fewer bugs
   - Browser E2E tests: [X]% fewer production issues
   - Code review with checklist: [X]% first-time pass
   ```

#### Phase 5: Code Pattern Analysis
1. **SCAN** for reusable code structures:
   - Component types
   - Utility functions
   - Service classes
   - Middleware patterns
   - Test helpers

2. **COUNT** instances of each pattern
3. **EVALUATE** reusability potential
4. **SUGGEST** extraction opportunities

5. **DISPLAY** code patterns:
   ```
   💻 CODE PATTERNS
   ══════════════════════════════════

   Reusable Components Identified:

   Pattern: Form Validation Request Classes
   - Instances: [X] similar implementations
   - Stories: [STORY-IDs]
   - Commonality: [X]% code overlap
   - Candidate for: Base FormRequest class
   - Estimated savings: [X] hours per story

   Pattern: Livewire CRUD Components
   - Instances: [X] similar implementations
   - Stories: [STORY-IDs]
   - Commonality: [X]% code overlap
   - Candidate for: CRUD trait or base class
   - Estimated savings: [X] hours per story

   Pattern: API Response Formatters
   - Instances: [X] similar implementations
   - Candidate for: Shared utility package
   - Extraction priority: High

   Common Integrations:
   - External API clients: [X] instances
     Standard approach: Guzzle + DTO pattern
     Template available: No
     Action: Create API client template
   ```

#### Phase 6: Process Pattern Analysis
1. **ANALYZE** workflow patterns:
   - Story progression times
   - Review process effectiveness
   - Testing strategies
   - Deployment approaches

2. **IDENTIFY** effective practices:
   - Time-of-day patterns
   - Day-of-week patterns
   - Story size sweet spots
   - Review timing

3. **CALCULATE** process effectiveness metrics

4. **DISPLAY** process patterns:
   ```
   📋 PROCESS PATTERNS
   ══════════════════════════════════

   Effective Workflows:

   Workflow: Same-day Review
   - Stories: [X] with review within 24h
   - Success rate: [X]%
   - Avg cycle time: [X] days faster
   - Recommendation: Target same-day reviews

   Practice: Incremental Commits
   - Stories: [X] with frequent commits
   - Impact: [X]% easier code review
   - Recommendation: Commit every feature increment

   Timing Patterns:
   - Stories started Monday: [X]% completion rate
   - Stories started Friday: [X]% completion rate
   - Optimal story size: [X] days

   Risk Factors:
   - Stories > 5 days: [X]% higher bug rate
   - Stories with > 3 dependencies: [X]% longer cycle
   ```

#### Phase 7: Pattern Recommendations
1. **ANALYZE** all discovered patterns
2. **PRIORITIZE** by impact and effort:
   - High impact, low effort: Quick wins
   - High impact, high effort: Strategic initiatives
   - Low impact, low effort: Nice to haves

3. **GENERATE** specific, actionable recommendations:
   - Template creation
   - Library extraction
   - Process standardization
   - Documentation needs

4. **DISPLAY** recommendations:
   ```
   💡 PATTERN-BASED RECOMMENDATIONS
   ══════════════════════════════════

   CREATE TEMPLATES FOR:
   Priority: High
   1. Authentication flow template
      - Used in: [X] stories
      - Estimated savings: [X] hours per story
      - Template location: /templates/auth-flow.md

   2. API integration template
      - Used in: [X] stories
      - Estimated savings: [X] hours per story
      - Template location: /templates/api-integration.md

   EXTRACT LIBRARIES FOR:
   Priority: High
   1. Form validation utilities
      - Instances: [X] similar implementations
      - Estimated savings: [X] hours per story
      - Package name: app/Utils/FormValidation

   2. API response formatters
      - Instances: [X] similar implementations
      - Estimated savings: [X] hours per story
      - Package name: app/Http/Responses

   STANDARDIZE PROCESSES:
   Priority: Medium
   1. Code review checklist
      - Include: Performance checks, test coverage
      - Expected impact: [X]% fewer QA bugs

   2. Story sizing guidelines
      - Optimal size: [X] days
      - Expected impact: [X]% faster velocity

   DOCUMENT PATTERNS:
   Priority: Medium
   1. JWT authentication pattern
      - Location: /patterns/auth-jwt.md
      - Include: Setup, usage, edge cases
   ```

#### Phase 8: Pattern Library Generation
1. **COMPILE** patterns into structured library
2. **CATEGORIZE** by domain:
   - Authentication
   - Data Processing
   - API Integration
   - UI Components
   - Testing

3. **TRACK** usage and availability:
   - Times used
   - Template exists (yes/no)
   - Documentation exists (yes/no)
   - Action needed

4. **DISPLAY** pattern library:
   ```
   📚 PATTERN LIBRARY
   ══════════════════════════════════

   Category: Authentication
   ──────────────────────────────────
   Pattern: JWT with Refresh Tokens
   - Used in: 5 stories
   - Success rate: 100%
   - Template available: Yes (/templates/auth-jwt.md)
   - Documentation: Yes (/patterns/auth-jwt.md)

   Pattern: Social OAuth Integration
   - Used in: 3 stories
   - Success rate: 100%
   - Template available: No
   - Action: Create template

   Category: Data Processing
   ──────────────────────────────────
   Pattern: Queue-based Background Jobs
   - Used in: 7 stories
   - Success rate: 95%
   - Template available: Yes (/templates/queue-job.md)
   - Documentation: Yes (/patterns/queue-jobs.md)

   Pattern: Batch Processing with Progress
   - Used in: 3 stories
   - Template available: No
   - Action: Create template

   Category: UI Components
   ──────────────────────────────────
   Pattern: Livewire CRUD Components
   - Used in: 12 stories
   - Template available: No
   - Action: Create base component trait

   [Additional categories...]
   ```

#### Phase 9: Anti-Pattern Detection
1. **IDENTIFY** problematic patterns:
   - Code smells that appear multiple times
   - Approaches with low success rates
   - Solutions that caused later problems

2. **ANALYZE** negative impact:
   - Increased bug rates
   - Longer cycle times
   - Technical debt creation

3. **SUGGEST** better alternatives

4. **DISPLAY** anti-patterns:
   ```
   ❌ ANTI-PATTERNS TO AVOID
   ══════════════════════════════════

   Anti-pattern: Direct DB Queries in Controllers
   - Found in: [X] stories
   - Problems caused:
     • Difficult to test
     • No reusability
     • N+1 query issues
   - Better approach: Use Repository or Query Builder
   - Stories affected: [STORY-IDs]

   Anti-pattern: Missing Validation in Livewire
   - Found in: [X] stories
   - Problems caused:
     • Security vulnerabilities
     • Data integrity issues
     • Poor UX
   - Better approach: Use #[Validate] attributes
   - Stories affected: [STORY-IDs]

   Anti-pattern: Monolithic Livewire Components
   - Found in: [X] stories
   - Problems caused:
     • Hard to maintain
     • Difficult to test
     • Poor reusability
   - Better approach: Break into smaller components
   ```

#### Phase 10: Pattern Export
1. **OFFER** to export patterns to structured files
2. **CREATE** pattern directory structure:
   ```
   /patterns/
   ├── technical-patterns.md
   ├── success-patterns.md
   ├── anti-patterns.md
   └── templates/
       ├── auth-flow.md
       ├── api-integration.md
       └── queue-job.md
   ```

3. **GENERATE** markdown files with:
   - Pattern descriptions
   - Usage examples
   - Code snippets
   - Best practices
   - Related stories

4. **DISPLAY** export summary:
   ```
   💾 EXPORT PATTERNS
   ══════════════════════════════════

   Files created:
   ✓ /patterns/technical-patterns.md (15 patterns)
   ✓ /patterns/success-patterns.md (8 patterns)
   ✓ /patterns/anti-patterns.md (5 patterns)
   ✓ /patterns/process-patterns.md (6 patterns)

   Templates needed:
   → /templates/auth-jwt.md (create)
   → /templates/api-integration.md (create)

   Next steps:
   1. Review exported patterns
   2. Create missing templates
   3. Update coding standards
   4. Share with team
   ```

### OUTPUTS
- Console display of all pattern analysis sections
- Optional: Pattern markdown files in `/patterns/` directory
- Optional: Template files in `/templates/` directory

### RULES
- MUST analyze only completed stories (read from `/stories/completed/`)
- MUST identify patterns with 2+ occurrences (single instance not a pattern)
- MUST calculate accurate frequency and success metrics
- SHOULD provide specific story IDs as evidence
- SHOULD prioritize recommendations by impact
- SHOULD generate actionable insights
- NEVER modify story files (read-only operation)
- ALWAYS show pattern sources (which stories)
- ALWAYS suggest concrete next steps
- MUST handle missing data gracefully

## Pattern Categories

### Technical Patterns
- Implementation approaches (authentication, API, data processing)
- Architecture patterns (MVC, Repository, Event-Driven)
- Technology combinations (framework + library pairs)
- Integration patterns (external services, databases)

### Problem Patterns
- Recurring technical issues
- Common blockers
- Integration challenges
- Performance problems
- Root cause analysis

### Success Patterns
- High-velocity approaches
- High-quality techniques
- Effective workflows
- Best practices

### Code Patterns
- Reusable components
- Utility functions
- Service classes
- Test helpers
- Common structures

### Process Patterns
- Workflow effectiveness
- Timing patterns
- Story sizing
- Review practices
- Testing strategies

## Examples

### Example 1: All Patterns
```bash
INPUT:
/story-patterns

OUTPUT:
→ Scanning completed stories...
→ Found 42 completed stories
→ Analyzing patterns across all categories...

🔧 TECHNICAL PATTERNS FOUND
══════════════════════════════════

Pattern: JWT Authentication with Refresh Tokens
- Used in: 5 stories (STORY-2025-001, 012, 023, 034, 041)
- Success rate: 100%
- Avg implementation time: 2.4 days
- Reusability: High
- Action: Template available at /templates/auth-jwt.md

[Additional sections...]

💡 PATTERN-BASED RECOMMENDATIONS
══════════════════════════════════

CREATE TEMPLATES FOR:
1. API integration with retry logic (used in 8 stories)
2. Livewire form with validation (used in 15 stories)

[Additional recommendations...]

💾 Export patterns to /patterns/ directory? (y/n)
```

### Example 2: Technical Patterns Only
```bash
INPUT:
/story-patterns technical

OUTPUT:
→ Scanning completed stories...
→ Analyzing technical patterns only...

🔧 TECHNICAL PATTERNS FOUND
══════════════════════════════════

Common Implementations:

Pattern: Livewire Component with Alpine.js Enhancement
- Used in: 18 stories
- Technologies: Livewire 3, Alpine.js 3
- Success rate: 95%
- Common structure:
  • Server-side state management
  • Client-side UX enhancements
  • Device-responsive behavior

[Additional technical patterns...]
```

### Example 3: No Patterns Found
```bash
INPUT:
/story-patterns

OUTPUT:
→ Scanning completed stories...
→ Found 3 completed stories
→ Analyzing patterns...

⚠️  INSUFFICIENT DATA
══════════════════════════════════

Not enough completed stories to identify patterns.
Patterns require at least 2 occurrences across multiple stories.

Current completed stories: 3
Minimum recommended: 10

Suggestions:
- Complete more stories to build pattern data
- Run /story-metrics to see development progress
- Check if stories are in /stories/completed/
```

## Edge Cases

### Few Completed Stories
- DETECT insufficient story count (< 5)
- DISPLAY warning about pattern reliability
- SHOW limited patterns found
- SUGGEST completing more stories

### No Common Patterns
- DETECT when stories are highly unique
- DISPLAY "no recurring patterns" message
- SHOW individual story characteristics
- SUGGEST areas for potential standardization

### Inconsistent Story Format
- PARSE flexibly with fallbacks
- EXTRACT patterns from available data
- LOG warnings about incomplete data
- CONTINUE with best-effort analysis

### Missing Technical Notes
- SKIP pattern extraction from incomplete stories
- LOG which stories lack necessary sections
- CALCULATE patterns from complete data only
- SUGGEST standardizing story format

## Error Handling
- **No completed stories**: Inform user, suggest completing stories first
- **Permission errors**: Report specific file access issues
- **Malformed story files**: Skip problematic files, log warnings
- **Invalid category parameter**: Show valid options, use default
- **Export directory exists**: Ask to overwrite or merge

## Performance Considerations
- Efficient file scanning (single pass per directory)
- Lazy parsing (only parse when needed)
- Pattern matching with hash maps for speed
- Streaming output for large datasets
- Typical completion time: < 3 seconds for 50 stories

## Related Commands
- `/story-metrics` - Calculate velocity and quality metrics
- `/story-tech-debt` - Analyze technical debt
- `/project-status` - View current story statuses
- `/story-list` - List and filter stories

## Constraints
- ✅ MUST be read-only (no story modifications)
- ✅ MUST identify patterns with 2+ occurrences
- ✅ MUST provide evidence (story IDs)
- ⚠️ SHOULD prioritize by impact and frequency
- 📊 SHOULD include success rates
- 💡 SHOULD generate actionable recommendations
- 🔍 MUST show pattern sources
- ⏱️ MUST complete analysis in reasonable time (< 5s)
- 📁 SHOULD offer to export findings
