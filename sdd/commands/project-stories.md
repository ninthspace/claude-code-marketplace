# /project-stories

## Meta
- Version: 2.0
- Category: project-management
- Complexity: medium
- Purpose: Display detailed story breakdown with dependencies and implementation order

## Definition
**Purpose**: List all stories for the current project with comprehensive dependency analysis, status tracking, and implementation recommendations.

**Syntax**: `/project-stories`

## Parameters
None

## Behavior

### Step 1: Project Brief Verification
1. CHECK for project brief at `/project-context/project-brief.md`
2. IF no project brief exists:
   - SUGGEST using `/project-brief` to create one
   - EXIT with guidance message

### Step 2: Project Context Loading
1. READ project brief to extract:
   - Project title and objectives
   - Story categorization (Core/Enhancement/Future)
   - Overall timeline and implementation phases
   - Project goals and success criteria

2. READ story relationships file at `/project-context/story-relationships.md`:
   - Dependency mapping between stories
   - Priority matrix with effort estimates
   - Implementation phase groupings
   - Critical path identification

### Step 3: Story Collection
SCAN all story directories to collect all project stories:

**Directories**:
- `/stories/development/` - Active implementation
- `/stories/review/` - Code review stage
- `/stories/qa/` - Quality assurance testing
- `/stories/completed/` - Finished and shipped
- `/stories/backlog/` - Planned but not started (if exists)

FOR EACH story file:
- EXTRACT story ID, title, status
- READ dependencies and effort estimates
- IDENTIFY priority level (Core/Enhancement/Future)
- NOTE current stage in workflow

### Step 4: Story Analysis and Categorization
1. GROUP stories by priority:
   - **Core Stories**: Must-have functionality (highest priority)
   - **Enhancement Stories**: Should-have features (medium priority)
   - **Future Stories**: Could-have improvements (lower priority)

2. ANALYZE dependencies:
   - BUILD dependency graph
   - IDENTIFY blocked stories (waiting on dependencies)
   - FIND ready-to-start stories (all dependencies met)
   - DETECT circular dependencies (if any)

3. CALCULATE metrics:
   - Total story count by category
   - Completion percentage per category
   - Overall project progress
   - Stories per status (Done/In Progress/Ready/Blocked)

### Step 5: Formatted Story Display
GENERATE comprehensive story breakdown:

```
🏗️  PROJECT: [Title]
====================

📊 OVERVIEW
- Total Stories: 8
- Completed: 3 ✅
- In Progress: 2 🔄
- Pending: 3 ⏳
- Overall Progress: 37% ████░░░░░░

🎯 CORE STORIES (Must Have)
┌─────────────┬──────────────────────────────┬──────────────┬─────────┬──────────┐
│ Story ID    │ Title                        │ Dependencies │ Status  │ Effort   │
├─────────────┼──────────────────────────────┼──────────────┼─────────┼──────────┤
│ STORY-001   │ Shopping cart persistence    │ None         │ ✅ Done │ Medium   │
│ STORY-002   │ Payment processing           │ STORY-001    │ ✅ Done │ Large    │
│ STORY-003   │ Order confirmation           │ STORY-002    │ 🔄 Dev  │ Medium   │
│ STORY-004   │ Inventory validation         │ STORY-001    │ ⏳ Ready│ Small    │
└─────────────┴──────────────────────────────┴──────────────┴─────────┴──────────┘

🚀 ENHANCEMENT STORIES (Should Have)
┌─────────────┬──────────────────────────────┬──────────────┬─────────┬──────────┐
│ STORY-005   │ Tax calculation              │ STORY-003    │ ⏳ Wait │ Medium   │
│ STORY-006   │ Shipping options             │ STORY-003    │ ⏳ Wait │ Large    │
│ STORY-007   │ Promo code system            │ STORY-002    │ ✅ Done │ Medium   │
└─────────────┴──────────────────────────────┴──────────────┴─────────┴──────────┘

🔮 FUTURE STORIES (Could Have)
┌─────────────┬──────────────────────────────┬──────────────┬─────────┬──────────┐
│ STORY-008   │ Order tracking               │ STORY-003    │ ⏳ Wait │ Large    │
└─────────────┴──────────────────────────────┴──────────────┴─────────┴──────────┘

🗂️  DEPENDENCY FLOW
STORY-001 (✅) → STORY-002 (✅) → STORY-003 (🔄)
    ↓                              ↓
STORY-004 (⏳)                  STORY-005 (⏳)
                                   ↓
                               STORY-006 (⏳)
                                   ↓
                               STORY-008 (⏳)

STORY-007 (✅) ← STORY-002 (✅)

📅 SUGGESTED NEXT ACTIONS
1. 🔄 Continue STORY-003 (Order confirmation) - Currently in development
2. ✅ Ready: STORY-004 (Inventory validation) - No blockers
3. ⏸️  Blocked: STORY-005, STORY-006, STORY-008 - Wait for STORY-003

💡 COMMANDS TO USE
1. /story-implement STORY-004  # Start ready story
2. /story-continue STORY-003   # Resume current work
3. /story-status               # Check individual story details
```

### Step 6: Opportunity Identification
1. IDENTIFY ready-to-start stories:
   - All dependencies completed
   - No blockers present
   - Can be started immediately

2. FIND blocked stories:
   - List dependencies that must complete first
   - Show which story is blocking each blocked story
   - Estimate when blockers might be resolved

3. HIGHLIGHT current work in progress:
   - Active development stories
   - Stories in review or QA
   - Recently completed stories

4. DETECT parallelization opportunities:
   - Stories with no shared dependencies
   - Independent work streams
   - Team capacity considerations

### Step 7: Branch and Integration Information
IF git branch information available:
- LIST active branches for in-progress stories
- IDENTIFY merge conflicts or integration points
- SUGGEST branch cleanup for completed stories

### Step 8: Project Health Metrics
CALCULATE and DISPLAY:

**Velocity Metrics**:
- Stories completed per week (average)
- Current sprint/phase progress
- Estimated completion date

**Risk Factors**:
- Number of blocked stories
- Large unstarted critical stories
- Dependencies on slow-moving work
- Long-running stories (potential issues)

**Quality Metrics**:
- Stories awaiting review
- Stories in QA
- Recent failure rates (if available)

### Step 9: Simplified View (No Project Brief)
IF no project brief exists, DISPLAY simplified listing:

```
📊 STORY OVERVIEW (SIMPLIFIED)
===============================

📁 Stories Found:
- Development: [count] stories
- Review: [count] stories
- QA: [count] stories
- Completed: [count] stories
- Total: [count] stories

[List of all stories with basic info]

💡 RECOMMENDATION
Create a project brief for better organization:
→ /project-brief

This will enable:
- Story prioritization
- Dependency tracking
- Timeline planning
- Progress metrics
```

## Output Format

### Standard Output
Comprehensive story display including:
- Overview with progress metrics
- Categorized story tables (Core/Enhancement/Future)
- Visual dependency flow diagram
- Status indicators (✅ 🔄 ⏳ ⏸️)
- Suggested next actions
- Relevant commands

### Simplified Output
Basic story listing when project brief is missing:
- Count by directory
- Simple list of all stories
- Recommendation to create project structure

## Examples

### Example 1: E-commerce Checkout Project
```bash
INPUT:
/project-stories

OUTPUT:
🏗️  PROJECT: E-commerce Checkout Flow
====================================

📊 OVERVIEW
- Total Stories: 8
- Completed: 3 ✅
- In Progress: 2 🔄
- Pending: 3 ⏳
- Overall Progress: 37% ████░░░░░░

🎯 CORE STORIES (Must Have)
┌─────────────┬──────────────────────────────┬──────────────┬─────────┬──────────┐
│ STORY-CHK-001 │ Shopping cart persistence  │ None         │ ✅ Done │ Medium   │
│ STORY-CHK-002 │ Payment processing         │ STORY-CHK-001│ ✅ Done │ Large    │
│ STORY-CHK-003 │ Order confirmation         │ STORY-CHK-002│ 🔄 Dev  │ Medium   │
│ STORY-CHK-004 │ Inventory validation       │ STORY-CHK-001│ ⏳ Ready│ Small    │
└─────────────┴──────────────────────────────┴──────────────┴─────────┴──────────┘

🚀 ENHANCEMENT STORIES (Should Have)
┌─────────────┬──────────────────────────────┬──────────────┬─────────┬──────────┐
│ STORY-CHK-005 │ Tax calculation            │ STORY-CHK-003│ ⏳ Wait │ Medium   │
│ STORY-CHK-006 │ Shipping options           │ STORY-CHK-003│ ⏳ Wait │ Large    │
│ STORY-CHK-007 │ Promo code system          │ STORY-CHK-002│ ✅ Done │ Medium   │
└─────────────┴──────────────────────────────┴──────────────┴─────────┴──────────┘

🔮 FUTURE STORIES (Could Have)
┌─────────────┬──────────────────────────────┬──────────────┬─────────┬──────────┐
│ STORY-CHK-008 │ Order tracking             │ STORY-CHK-003│ ⏳ Wait │ Large    │
└─────────────┴──────────────────────────────┴──────────────┴─────────┴──────────┘

🗂️  DEPENDENCY FLOW
STORY-CHK-001 (✅) → STORY-CHK-002 (✅) → STORY-CHK-003 (🔄)
    ↓                                        ↓
STORY-CHK-004 (⏳)                      STORY-CHK-005 (⏳)
                                             ↓
                                        STORY-CHK-006 (⏳)
                                             ↓
                                        STORY-CHK-008 (⏳)

STORY-CHK-007 (✅) ← STORY-CHK-002 (✅)

📅 SUGGESTED NEXT ACTIONS
1. 🔄 Continue STORY-CHK-003 (Order confirmation) - Currently in development
2. ✅ Ready: STORY-CHK-004 (Inventory validation) - No blockers, can start immediately
3. ⏸️  Blocked: STORY-CHK-005, STORY-CHK-006, STORY-CHK-008 - Waiting for STORY-CHK-003

💡 COMMANDS TO USE
1. /story-implement STORY-CHK-004  # Start ready story
2. /story-continue STORY-CHK-003   # Resume current work
3. /story-status                   # Check individual story details
```

### Example 2: Project Without Brief
```bash
INPUT:
/project-stories

OUTPUT:
📊 STORY OVERVIEW (SIMPLIFIED)
===============================

📁 Stories Found:
- Development: 2 stories
- Review: 1 story
- QA: 1 story
- Completed: 3 stories
- Total: 7 stories

Stories:
1. STORY-001: User authentication (✅ Completed)
2. STORY-002: Dashboard layout (✅ Completed)
3. STORY-003: Data export (✅ Completed)
4. STORY-004: Advanced filters (🔄 Development)
5. STORY-005: Report generation (🔄 Development)
6. STORY-006: Email notifications (🔍 Review)
7. STORY-007: Mobile responsive (🧪 QA)

💡 RECOMMENDATION
Create a project brief for better organization:
→ /project-brief

This will enable:
- Story prioritization (Core/Enhancement/Future)
- Dependency tracking and visualization
- Timeline planning and velocity metrics
- Progress tracking and health metrics
```

### Example 3: All Stories Blocked
```bash
INPUT:
/project-stories

OUTPUT:
🏗️  PROJECT: Mobile App Dashboard
==================================

📊 OVERVIEW
- Total Stories: 5
- Completed: 1 ✅
- In Progress: 1 🔄
- Blocked: 3 ⚠️
- Overall Progress: 20% ██░░░░░░░░

⚠️  CRITICAL: Multiple Blocked Stories

🎯 CORE STORIES (Must Have)
┌─────────────┬──────────────────────────────┬──────────────┬─────────┬──────────┐
│ STORY-001   │ API authentication           │ None         │ ✅ Done │ Large    │
│ STORY-002   │ Data synchronization         │ STORY-001    │ 🔄 Dev  │ Large    │
│ STORY-003   │ Offline mode                 │ STORY-002    │ ⚠️  Wait│ XLarge   │
│ STORY-004   │ Push notifications           │ STORY-002    │ ⚠️  Wait│ Medium   │
│ STORY-005   │ Analytics dashboard          │ STORY-002    │ ⚠️  Wait│ Large    │
└─────────────┴──────────────────────────────┴──────────────┴─────────┴──────────┘

🗂️  DEPENDENCY FLOW
STORY-001 (✅) → STORY-002 (🔄) → STORY-003 (⚠️)
                     ↓
                 STORY-004 (⚠️)
                     ↓
                 STORY-005 (⚠️)

⚠️  BLOCKER ANALYSIS
- 3 stories blocked by STORY-002 (Data synchronization)
- Focus needed on completing STORY-002 to unblock pipeline
- Large story (STORY-003) waiting - may need breakdown

📅 RECOMMENDED ACTIONS
1. 🔥 PRIORITY: Complete STORY-002 to unblock 3 downstream stories
2. 💡 Consider breaking down STORY-003 (XLarge) into smaller stories
3. 📋 Review STORY-002 progress and identify any blockers

💡 COMMANDS TO USE
1. /story-continue STORY-002   # Focus on unblocking work
2. /story-status STORY-002     # Check detailed progress
3. /project-status             # Overall project health check
```

## Edge Cases

### No Stories Found
- DISPLAY message about empty project
- SUGGEST creating first story with `/story-new`
- RECOMMEND running `/project-brief` for planning

### Circular Dependencies
- DETECT circular dependency loops
- HIGHLIGHT stories involved in cycle
- SUGGEST breaking circular dependencies
- PROVIDE guidance on refactoring story structure

### All Stories Complete
- CONGRATULATE on completion
- SHOW final statistics and velocity
- SUGGEST next phase planning with `/project-phase`
- RECOMMEND project retrospective

### Large Number of Stories
- GROUP stories by phase/sprint if available
- PROVIDE filtering options
- SUMMARIZE rather than showing full tables
- SUGGEST using `/story-status` for individual details

## Error Handling
- **Missing project brief**: Suggest `/project-brief`, continue with simplified view
- **Corrupted story files**: Skip corrupted files, log warnings, continue processing
- **Missing dependencies**: Highlight unresolved dependencies, suggest fixes
- **Permission errors**: Report specific files with access issues

## Performance Considerations
- Story file reads optimized with metadata-only scanning
- Large collections (50+ stories) use progressive loading
- Dependency graph calculation cached per invocation
- Table formatting optimizes for terminal width

## Related Commands
- `/project-brief` - Create or update project documentation
- `/project-status` - High-level project progress view
- `/project-phase` - Plan next development phase
- `/story-status` - Individual story detailed view
- `/story-implement [id]` - Start working on a ready story
- `/story-continue` - Resume active work

## Constraints
- ✅ MUST group stories by priority category
- ✅ MUST show dependency relationships visually
- ✅ MUST identify ready-to-start and blocked stories
- 📊 SHOULD calculate accurate progress metrics
- 🎯 SHOULD provide actionable next steps
- ⚠️ MUST highlight critical blockers clearly
- 🔄 SHOULD show parallelization opportunities
