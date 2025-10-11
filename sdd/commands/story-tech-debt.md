# /sdd:story-tech-debt

## Meta
- Version: 2.0
- Category: story-analysis
- Complexity: high
- Purpose: Identify, categorize, prioritize, and track technical debt from stories to inform debt reduction efforts

## Definition
**Purpose**: Scan all stories for technical debt indicators, categorize by severity and type, calculate impact metrics, and generate actionable debt reduction plan.

**Syntax**: `/sdd:story-tech-debt [priority]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| priority | string | No | "all" | Debt priority filter (critical, important, nice-to-have, all) | One of: critical, important, nice-to-have, all |

## INSTRUCTION: Analyze Technical Debt

### INPUTS
- priority: Optional priority filter (defaults to all)
- Story files from all directories:
  - `/stories/development/` - Active stories
  - `/stories/review/` - Stories in review
  - `/stories/qa/` - Stories in testing
  - `/stories/completed/` - Finished stories
- Optional: Project codebase for TODO scanning

### PROCESS

#### Phase 1: Debt Indicator Detection
1. **SCAN** all story files for debt indicators:
   - "TODO" mentions in technical notes
   - "FIXME" mentions in technical notes
   - "HACK" mentions in technical notes
   - "Technical debt" explicit mentions
   - "Deferred" items in implementation checklist
   - "Temporary solution" in progress log
   - "Skipped tests" in test cases
   - "Performance concern" in technical notes
   - "Security risk" mentions
   - "Needs refactor" mentions

2. **EXTRACT** debt details:
   - Description of debt item
   - Source story ID
   - Date created (from story started date)
   - Severity indicators
   - Impact description

3. **OPTIONAL**: Scan codebase for TODOs:
   - Search `*.php` files for TODO comments
   - Search `*.blade.php` files for TODO comments
   - Search `*.js` files for TODO comments
   - Link to stories when possible

#### Phase 2: Debt Categorization
1. **CLASSIFY** debt by severity:
   - Critical: Security/Stability issues
   - Important: Performance/Maintenance issues
   - Nice to have: Cleanup/Refactor items

2. **CLASSIFY** debt by type:
   - Security debt
   - Performance debt
   - Code quality debt
   - Test debt
   - Documentation debt
   - Infrastructure debt

3. **CALCULATE** impact scores:
   - User impact (High/Medium/Low)
   - Developer impact (High/Medium/Low)
   - Business impact (High/Medium/Low)

4. **ESTIMATE** effort:
   - Hours for small items
   - Days for medium items
   - Weeks for large items

5. **DISPLAY** debt inventory:
   ```
   🏗️  TECHNICAL DEBT INVENTORY
   ══════════════════════════════════

   🔴 CRITICAL (Security/Stability)
   ────────────────────────────────
   [DEBT-001] Security: Unencrypted Sensitive Data Storage
   - Story: STORY-2025-012
   - Created: Sep 15, 2025
   - Impact: High - PII at risk, compliance violation
   - Effort: Medium (2 days)
   - Priority: P0 - Fix immediately
   - Description: User passwords stored in plain text in logs

   [DEBT-002] Stability: Memory Leak in Background Service
   - Story: STORY-2025-023
   - Created: Sep 20, 2025
   - Impact: High - Application crashes after 24h
   - Effort: Low (1 day)
   - Priority: P0 - Fix immediately
   - Description: Queue worker accumulates memory over time

   🟡 IMPORTANT (Performance/Maintenance)
   ────────────────────────────────────
   [DEBT-003] Performance: Unoptimized Database Queries
   - Story: STORY-2025-018
   - Created: Sep 18, 2025
   - Impact: Medium - 3-5s page load times
   - Effort: Medium (2 days)
   - Priority: P1 - Fix soon
   - Description: N+1 queries in user dashboard

   [DEBT-004] Maintenance: Duplicated Business Logic
   - Story: STORY-2025-025
   - Created: Sep 22, 2025
   - Impact: Medium - Hard to update, bug prone
   - Effort: High (3 days)
   - Priority: P2 - Plan for next sprint
   - Description: Payment validation duplicated in 5 places

   🟢 NICE TO HAVE (Cleanup/Refactor)
   ──────────────────────────────────
   [DEBT-005] Cleanup: Unused Dependencies
   - Story: STORY-2025-010
   - Created: Sep 10, 2025
   - Impact: Low - Larger bundle size
   - Effort: Low (2 hours)
   - Priority: P3 - When time permits
   - Description: 3 unused npm packages in package.json

   [DEBT-006] Refactor: Complex Livewire Component
   - Story: STORY-2025-021
   - Created: Sep 21, 2025
   - Impact: Low - Maintainability concern
   - Effort: Medium (1 day)
   - Priority: P3 - When time permits
   - Description: TaskManager component has 15 methods
   ```

#### Phase 3: Debt Metrics Calculation
1. **COUNT** total debt items by category
2. **SUM** estimated effort (convert to days)
3. **CALCULATE** debt ratio:
   - Total debt effort / Total development time
   - Percentage of development capacity

4. **DISPLAY** debt metrics:
   ```
   📊 DEBT METRICS
   ══════════════════════════════════

   Total Debt Items: 24
   Estimated Effort: 32 days

   By Severity:
   - Critical: 3 items (6 days)
   - Important: 8 items (18 days)
   - Nice to have: 13 items (8 days)

   By Category:
   - Security debt: 2 items (4 days)
   - Performance debt: 5 items (12 days)
   - Code quality debt: 9 items (10 days)
   - Test debt: 4 items (3 days)
   - Documentation debt: 3 items (2 days)
   - Infrastructure debt: 1 item (1 day)

   Debt Ratio: 28% of development capacity
   (32 debt days / 115 total development days)

   Status: ⚠️  High debt load - prioritize reduction
   ```

#### Phase 4: Impact Assessment
1. **ANALYZE** user impact:
   - Items affecting user experience
   - Items affecting performance
   - Items invisible to users

2. **ANALYZE** developer impact:
   - Items slowing development
   - Items causing confusion
   - Items increasing bug rate

3. **ANALYZE** business impact:
   - Items affecting scalability
   - Items increasing costs
   - Items risking compliance

4. **DISPLAY** impact assessment:
   ```
   ⚡ IMPACT ASSESSMENT
   ══════════════════════════════════

   User Impact:
   - 8 items affect user experience
   - 5 items affect performance
   - 11 items are invisible to users

   Developer Impact:
   - 12 items slow development
   - 7 items cause confusion
   - 9 items increase bug likelihood

   Business Impact:
   - 4 items affect scalability
   - 3 items increase operational costs
   - 2 items risk compliance/security

   Risk Level: 🔴 High
   Recommendation: Address critical items immediately
   ```

#### Phase 5: Priority Matrix Generation
1. **PLOT** debt items on impact/effort matrix:
   - High impact + Low effort: Quick wins
   - High impact + High effort: Strategic projects
   - Low impact + Low effort: Backlog items
   - Low impact + High effort: Defer or eliminate

2. **PRIORITIZE** within each quadrant
3. **GENERATE** priority recommendations

4. **DISPLAY** priority matrix:
   ```
   📈 PRIORITY MATRIX
   ══════════════════════════════════

   🎯 HIGH IMPACT + LOW EFFORT (DO FIRST)
   ────────────────────────────────────
   [DEBT-002] Memory leak fix (1 day)
   [DEBT-005] Remove unused dependencies (2 hours)
   [DEBT-007] Add missing indexes (4 hours)

   Total effort: 1.75 days
   Expected impact: High stability, reduced costs

   📋 HIGH IMPACT + HIGH EFFORT (PLAN & SCHEDULE)
   ──────────────────────────────────────────────
   [DEBT-001] Implement data encryption (2 days)
   [DEBT-004] Refactor duplicated logic (3 days)
   [DEBT-008] Migrate to new API version (5 days)

   Total effort: 10 days
   Expected impact: Security, maintainability

   ⚡ LOW IMPACT + LOW EFFORT (QUICK WINS)
   ───────────────────────────────────────
   [DEBT-006] Simplify complex component (1 day)
   [DEBT-009] Update deprecated API calls (2 hours)
   [DEBT-010] Fix linting warnings (1 hour)

   Total effort: 1.5 days
   Expected impact: Code quality, dev experience

   ⏸️  LOW IMPACT + HIGH EFFORT (DEFER)
   ────────────────────────────────────
   [DEBT-011] Achieve 100% test coverage (5 days)
   [DEBT-012] Complete architectural refactor (10 days)

   Total effort: 15 days
   Recommendation: Defer or break into smaller items
   ```

#### Phase 6: Debt Story Generation
1. **GROUP** related debt items
2. **CREATE** debt reduction story proposals:
   - Story title
   - Combined debt items
   - Total effort estimate
   - Expected value/benefit

3. **SUGGEST** story descriptions

4. **DISPLAY** debt stories:
   ```
   📝 DEBT REDUCTION STORIES
   ══════════════════════════════════

   Suggested Stories to Create:

   [DEBT-STORY-001] Security Hardening Sprint
   - Combines: DEBT-001, DEBT-013, DEBT-015
   - Items: 3 security issues
   - Effort: 5 days
   - Value: Critical security and compliance
   - Priority: P0 - Must do next sprint

   [DEBT-STORY-002] Performance Optimization Sprint
   - Combines: DEBT-003, DEBT-007, DEBT-014, DEBT-016
   - Items: 4 performance issues
   - Effort: 6 days
   - Value: 50% faster page loads, better UX
   - Priority: P1 - High value

   [DEBT-STORY-003] Code Quality Refactor
   - Combines: DEBT-004, DEBT-006, DEBT-017
   - Items: 3 maintainability issues
   - Effort: 5 days
   - Value: Easier maintenance, faster features
   - Priority: P2 - Medium value

   Create these stories? (y/n)
   ```

#### Phase 7: Debt Reduction Plan
1. **ORGANIZE** debt items into sprint-sized chunks
2. **CREATE** timeline for debt reduction:
   - Immediate: Critical items
   - Short-term: Important items
   - Medium-term: Nice to have items
   - Ongoing: Continuous improvements

3. **CALCULATE** capacity allocation:
   - Percentage of sprint for debt work
   - Expected completion timeline

4. **DISPLAY** reduction plan:
   ```
   📅 DEBT REDUCTION PLAN
   ══════════════════════════════════

   IMMEDIATE (This Week)
   ────────────────────────────────
   Sprint Focus: Critical security and stability
   - Fix data encryption (2 days)
   - Patch memory leak (1 day)
   - Add authentication checks (1 day)

   Total: 4 days
   Team capacity: 2 developers × 2 days each

   SHORT-TERM (Next 2 Sprints)
   ────────────────────────────────
   Sprint 1: Performance optimization
   - Optimize database queries (2 days)
   - Add caching layer (2 days)
   - Add missing indexes (0.5 days)

   Sprint 2: Code quality improvement
   - Refactor duplicated logic (3 days)
   - Simplify complex components (1 day)
   - Add missing tests (2 days)

   Total: 10.5 days

   MEDIUM-TERM (Month 2-3)
   ────────────────────────────────
   - Documentation updates (2 days)
   - Dependency upgrades (1 day)
   - Architectural improvements (5 days)

   Total: 8 days

   ONGOING PREVENTION
   ────────────────────────────────
   - Allocate 20% of each sprint to debt
   - Address new TODOs within 2 weeks
   - Code review checklist for debt
   - Monthly debt review meeting

   ESTIMATED COMPLETION
   ────────────────────────────────
   All critical debt: 1 week
   All high-priority debt: 6 weeks
   All tracked debt: 12 weeks

   With 20% ongoing capacity: Sustainable
   ```

#### Phase 8: Trend Analysis
1. **TRACK** debt over time:
   - New debt created (from recent stories)
   - Debt resolved (from progress logs)
   - Net change

2. **CALCULATE** debt velocity:
   - Rate of debt creation
   - Rate of debt resolution
   - Projected timeline

3. **DISPLAY** trend analysis:
   ```
   📉 DEBT TRENDS
   ══════════════════════════════════

   Last 30 Days:
   - New debt created: 8 items (12 days effort)
   - Debt resolved: 3 items (4 days effort)
   - Net change: +5 items (+8 days) ⚠️

   Monthly Rate:
   - Debt creation: 8 items/month
   - Debt resolution: 3 items/month
   - Net accumulation: 5 items/month

   Current Trajectory:
   - At current rate: Debt increasing
   - Projected debt in 3 months: 39 items (56 days)
   - Status: 🔴 Unsustainable

   With 20% Sprint Capacity (4 days/sprint):
   - Debt resolution: 8 items/month
   - Net change: Even or reducing
   - Clear current debt: 8 sprints (4 months)
   - Status: ✅ Sustainable

   Recommendation:
   Allocate 20% of sprint capacity to debt reduction
   to prevent accumulation and clear backlog.
   ```

#### Phase 9: Prevention Recommendations
1. **ANALYZE** root causes of debt
2. **SUGGEST** process improvements:
   - Code review additions
   - Definition of done criteria
   - Quality gates
   - Standards enforcement

3. **RECOMMEND** preventive measures:
   - Performance budgets
   - Complexity limits
   - Coverage requirements
   - Documentation standards

4. **DISPLAY** prevention recommendations:
   ```
   🛡️  DEBT PREVENTION
   ══════════════════════════════════

   PROCESS IMPROVEMENTS:

   Code Review Checklist:
   ✓ Add debt check to review template
   ✓ Block PRs with new TODO comments
   ✓ Require justification for technical debt
   ✓ Link debt to tracking story

   Definition of Done:
   ✓ All tests passing
   ✓ No new TODO/FIXME comments
   ✓ Performance benchmarks met
   ✓ Security checks passed
   ✓ Documentation updated

   Quality Gates:
   ✓ Automated: Lint, format, test coverage
   ✓ Manual: Security review for auth changes
   ✓ Manual: Performance review for queries

   STANDARDS TO ENFORCE:

   Performance Budgets:
   - Max page load: 2 seconds
   - Max API response: 500ms
   - Max database queries: 10 per request
   - Max N+1 queries: 0

   Complexity Limits:
   - Max cyclomatic complexity: 10
   - Max method length: 30 lines
   - Max class length: 300 lines
   - Max method parameters: 4

   Coverage Requirements:
   - Minimum test coverage: 80%
   - All public methods tested
   - Edge cases covered
   - Browser tests for critical paths

   Documentation Standards:
   - All public APIs documented
   - Complex logic explained
   - Setup instructions complete
   - Deployment process documented

   TOOL RECOMMENDATIONS:

   Automated Checks:
   - Laravel Pint for code style
   - Pest for testing
   - PHPStan for static analysis
   - GitHub Actions for CI/CD

   Monitoring:
   - Laravel Telescope for debugging
   - Performance monitoring
   - Error tracking
   - Log aggregation
   ```

#### Phase 10: Report Export
1. **COMPILE** all debt data into comprehensive report
2. **GENERATE** debt backlog stories
3. **CREATE** tracking documents

4. **OFFER** export options:
   ```
   💾 EXPORT OPTIONS
   ══════════════════════════════════

   Export debt report to:
   1. /tech-debt/report-2025-10-01.md
      - Complete debt inventory
      - Metrics and trends
      - Reduction plan
      - Prevention recommendations

   2. Create debt stories in /stories/backlog/:
      - DEBT-STORY-001.md (Security sprint)
      - DEBT-STORY-002.md (Performance sprint)
      - DEBT-STORY-003.md (Code quality sprint)

   3. Create debt tracking dashboard:
      - /tech-debt/dashboard.md
      - Updated weekly with latest status

   Export all? (y/n)
   ```

5. **DISPLAY** export summary:
   ```
   ✅ EXPORT COMPLETE
   ══════════════════════════════════

   Files Created:
   ✓ /tech-debt/report-2025-10-01.md
   ✓ /tech-debt/dashboard.md
   ✓ /stories/backlog/DEBT-STORY-001.md
   ✓ /stories/backlog/DEBT-STORY-002.md
   ✓ /stories/backlog/DEBT-STORY-003.md

   NEXT STEPS:
   1. Review and prioritize debt stories
   2. Schedule critical items for this sprint
   3. Allocate 20% capacity for debt work
   4. Update debt dashboard weekly
   5. Track debt velocity monthly

   💡 QUICK START:
   /sdd:story-start DEBT-STORY-001  # Begin security sprint
   ```

### OUTPUTS
- Console display of complete debt analysis
- Optional: `/tech-debt/report-[date].md` - Comprehensive debt report
- Optional: `/tech-debt/dashboard.md` - Tracking dashboard
- Optional: `/stories/backlog/DEBT-STORY-*.md` - Debt reduction stories

### RULES
- MUST scan all story directories (not just completed)
- MUST categorize debt by severity (critical/important/nice-to-have)
- MUST calculate effort estimates (hours/days)
- MUST prioritize by impact/effort matrix
- SHOULD link debt items to source stories
- SHOULD provide timeline for debt reduction
- SHOULD suggest prevention measures
- NEVER modify story files (read-only operation)
- ALWAYS show debt sources and dates
- ALWAYS provide actionable recommendations
- MUST handle missing data gracefully

## Debt Severity Levels

### Critical (P0)
- Security vulnerabilities
- Stability/crash issues
- Data loss risks
- Compliance violations
- **Action**: Fix immediately

### Important (P1)
- Performance degradation
- Maintainability issues
- Moderate bug risks
- User experience problems
- **Action**: Fix within 1-2 sprints

### Nice to Have (P2/P3)
- Code cleanup
- Minor refactoring
- Documentation gaps
- Optimization opportunities
- **Action**: Address when capacity allows

## Examples

### Example 1: All Debt
```bash
INPUT:
/sdd:story-tech-debt

OUTPUT:
→ Scanning all story directories...
→ Found 24 debt items across 18 stories
→ Categorizing and prioritizing...

🏗️  TECHNICAL DEBT INVENTORY
══════════════════════════════════

🔴 CRITICAL (3 items)
[DEBT-001] Security: Unencrypted sensitive data
[DEBT-002] Stability: Memory leak in queue worker
[DEBT-003] Security: Missing authentication check

🟡 IMPORTANT (8 items)
[DEBT-004] Performance: N+1 query issues
[DEBT-005] Maintenance: Duplicated business logic
[... 6 more ...]

🟢 NICE TO HAVE (13 items)
[DEBT-006] Cleanup: Unused dependencies
[... 12 more ...]

[Additional sections...]

📝 DEBT REDUCTION STORIES

Create 3 debt stories in backlog? (y/n)
```

### Example 2: Critical Debt Only
```bash
INPUT:
/sdd:story-tech-debt critical

OUTPUT:
→ Scanning for critical debt only...
→ Found 3 critical items

🔴 CRITICAL DEBT (3 items, 6 days)
══════════════════════════════════

[DEBT-001] Security: Unencrypted Sensitive Data
- Story: STORY-2025-012
- Impact: High - PII at risk
- Effort: 2 days
- Description: User data stored without encryption

[DEBT-002] Stability: Memory Leak
- Story: STORY-2025-023
- Impact: High - Crashes after 24h
- Effort: 1 day
- Description: Queue worker memory accumulation

[DEBT-003] Security: Missing Auth Check
- Story: STORY-2025-028
- Impact: High - Unauthorized access possible
- Effort: 3 days
- Description: Admin endpoints lack verification

⚠️  ACTION REQUIRED
──────────────────────────────────
These critical items should be addressed immediately.
Estimated effort: 6 days total

Create emergency debt story? (y/n)
```

### Example 3: No Debt Found
```bash
INPUT:
/sdd:story-tech-debt

OUTPUT:
→ Scanning all story directories...
→ Analyzing debt indicators...

✅ NO TECHNICAL DEBT DETECTED
══════════════════════════════════

No debt indicators found in stories:
- No TODO/FIXME comments
- No deferred items
- No temporary solutions
- No skipped tests

Status: 🎉 Clean codebase!

PREVENTION:
Continue following best practices:
- Code review process
- Test-driven development
- Performance monitoring
- Security checks

Run /sdd:story-metrics to see quality metrics.
```

## Edge Cases

### No Stories Available
- DETECT empty story directories
- DISPLAY no data message
- SUGGEST creating stories first
- PROVIDE guidance on starting

### All Debt Resolved
- DETECT zero debt items
- CELEBRATE clean codebase
- SHOW prevention recommendations
- SUGGEST ongoing practices

### Incomplete Debt Information
- PARSE flexibly from available data
- MARK incomplete items for review
- ESTIMATE effort conservatively
- CONTINUE with best-effort analysis

### Very High Debt Load
- DETECT debt > 50% of development time
- DISPLAY warning alert
- PRIORITIZE ruthlessly (critical only)
- SUGGEST process intervention

## Error Handling
- **No story directories**: Report missing structure, suggest `/sdd:project-init`
- **Permission errors**: Report specific file access issues
- **Malformed story files**: Skip problematic files, log warnings
- **Invalid priority parameter**: Show valid options, use default
- **Export directory conflicts**: Ask to overwrite or merge

## Performance Considerations
- Efficient file scanning (single pass per directory)
- Lazy parsing (only parse when needed)
- Pattern matching with regex for debt indicators
- Streaming output for large debt lists
- Typical completion time: < 3 seconds for 50 stories

## Related Commands
- `/sdd:story-metrics` - Development velocity and quality metrics
- `/sdd:story-patterns` - Identify recurring patterns
- `/sdd:project-status` - Current project state
- `/sdd:story-new [id]` - Create debt reduction story

## Constraints
- ✅ MUST be read-only (no story modifications)
- ✅ MUST categorize by severity (critical/important/nice-to-have)
- ✅ MUST provide effort estimates
- ⚠️ SHOULD link debt to source stories
- 📊 SHOULD include impact assessment
- 💡 SHOULD generate reduction plan
- 🛡️ SHOULD suggest prevention measures
- ⏱️ MUST complete analysis in reasonable time (< 5s)
- 📁 SHOULD offer to export and create stories
