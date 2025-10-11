# /sdd:project-status

## Meta
- Version: 2.0
- Category: project-management
- Complexity: medium
- Purpose: Display comprehensive project status with story breakdown and progress tracking

## Definition
**Purpose**: Show current project status including story breakdown, progress metrics, and actionable next steps.

**Syntax**: `/sdd:project-status`

## Parameters
None

## Behavior

### Step 1: Project Context Loading
1. CHECK if `/project-context/` directory exists
2. IF missing:
   - SUGGEST running `/sdd:project-init` first
   - EXIT with guidance message
3. LOAD project-specific requirements from:
   - `/project-context/project-brief.md` (project title, timeline, objectives)
   - `/project-context/technical-stack.md` (technology information)
   - `/project-context/development-process.md` (stage definitions, workflows)

### Step 2: Project Brief Analysis
1. READ `/project-context/project-brief.md`
2. EXTRACT:
   - Project title and current status
   - Project objectives and goals
   - Target completion date (if specified)
   - Total planned stories count
3. IF no project brief exists:
   - SUGGEST using `/sdd:project-brief` to create one
   - PROCEED with simplified view (Step 7)

### Step 3: Story Collection and Analysis
1. SCAN all story directories for project stories:
   - `/stories/development/` - Active implementation
   - `/stories/review/` - Code review stage
   - `/stories/qa/` - Quality assurance stage
   - `/stories/completed/` - Finished stories
   - `/stories/backlog/` - Planned stories (if exists)

2. FOR EACH story:
   - COUNT stories by status category
   - IDENTIFY blocked or stalled stories
   - EXTRACT priority and effort estimates
   - NOTE dependencies and relationships

3. CALCULATE metrics:
   - Total stories across all stages
   - Completion percentage
   - Stories by priority (Core/Enhancement/Future)
   - Active vs pending stories

### Step 4: Progress Analysis
1. CALCULATE completion metrics:
   - Percentage complete: `(completed / total) × 100`
   - Core stories progress
   - Enhancement stories progress
   - Future stories status

2. IDENTIFY current focus:
   - Stories actively in development
   - Stories ready to start (no blockers)
   - Stories waiting on dependencies

3. ANALYZE timeline:
   - Days since project start
   - Days remaining to target
   - Estimated completion based on velocity

### Step 5: Issue Detection
1. HIGHLIGHT concerns:
   - Stories behind schedule
   - Blocked stories with dependencies
   - Missing critical dependencies
   - Critical path bottlenecks
   - Long-running stories (potential issues)

### Step 6: Formatted Status Display
GENERATE comprehensive status report:

```
📊 PROJECT STATUS
=================

🏗️  [PROJECT TITLE]
├── Status: Active (Started: [Date], Target: [Date])
├── Progress: ████████░░ 75% (6/8 stories complete)
├── Core Stories: ✅ 4/4 complete
├── Enhancement: 🔄 2/3 in progress
├── Future: ⏳ 0/1 pending
└── Next: STORY-XXX-007 (Feature name) - Ready to start

📊 STORY BREAKDOWN BY STATUS
- ✅ Completed: 3 stories
- 🔄 In Development: 2 stories
- 🔍 In Review: 1 story
- 🧪 In QA: 1 story
- ⏳ Backlog: 1 story
- ⚠️  Blocked: 0 stories

🎯 CURRENT FOCUS
- Active: STORY-XXX-005 (Feature name) - In development
- Ready to start: STORY-XXX-007 (Feature name)
- Waiting: STORY-XXX-008 (depends on STORY-XXX-005)

📅 TIMELINE
- Started: [Start Date]
- Target: [Target Date]
- Estimated completion: [Calculated Date]
- Days remaining: [X days]

💡 NEXT ACTIONS
1. Continue STORY-XXX-005 (Feature name)
2. Start STORY-XXX-007 when ready
3. Review completed stories in /qa

🔗 USEFUL COMMANDS
1. /sdd:story-continue     # Resume current work
2. /sdd:story-next         # Get next recommended story
3. /sdd:story-status       # See all individual story details
```

### Step 7: Simplified View (No Project Brief)
IF no project brief exists, DISPLAY simplified metrics:

```
📊 PROJECT STATUS (SIMPLIFIED)
===============================

📁 Story Distribution:
- Development: [count] stories
- Review: [count] stories
- QA: [count] stories
- Completed: [count] stories
- Total: [count] stories

💡 RECOMMENDATION
Create a project brief for better organization and tracking:
→ /sdd:project-brief

Available commands:
1. /sdd:story-new      # Create new story
2. /sdd:story-status   # View story details
3. /sdd:project-brief  # Create project structure
```

### Step 8: Command Suggestions
SUGGEST relevant commands based on current state:

IF stories ready to start:
- `/sdd:story-implement [id]` for ready stories

IF work in progress:
- `/sdd:story-continue` for resuming work

IF no project structure:
- `/sdd:project-brief` to create organization

## Output Format

### Success Output
Comprehensive status display with:
- Visual progress indicators (████░░)
- Story breakdown by status (✅ 🔄 🔍 🧪 ⏳ ⚠️)
- Timeline information
- Actionable next steps
- Relevant command suggestions

### Simplified Output
Basic metrics when project brief is missing:
- Story counts by directory
- Total story count
- Suggestions for creating structure

## Examples

### Example 1: Active Project with Full Brief
```bash
INPUT:
/sdd:project-status

OUTPUT:
📊 PROJECT STATUS
=================

🏗️  E-commerce Checkout Flow
├── Status: Active (Started: 2025-09-01, Target: 2025-10-15)
├── Progress: ████████░░ 75% (6/8 stories complete)
├── Core Stories: ✅ 4/4 complete
├── Enhancement: 🔄 2/3 in progress
├── Future: ⏳ 0/1 pending
└── Next: STORY-CHK-007 (Tax calculation) - Ready to start

📊 STORY BREAKDOWN BY STATUS
- ✅ Completed: 4 stories
- 🔄 In Development: 2 stories
- 🔍 In Review: 0 stories
- 🧪 In QA: 1 story
- ⏳ Backlog: 1 story
- ⚠️  Blocked: 0 stories

🎯 CURRENT FOCUS
- Active: STORY-CHK-005 (Payment integration) - In development
- Ready to start: STORY-CHK-007 (Tax calculation)
- Waiting: STORY-CHK-008 (depends on STORY-CHK-007)

📅 TIMELINE
- Started: 2025-09-01
- Target: 2025-10-15
- Estimated completion: 2025-10-12
- Days remaining: 14 days

💡 NEXT ACTIONS
1. Continue STORY-CHK-005 (Payment integration)
2. Start STORY-CHK-007 when ready
3. Review completed STORY-CHK-004 in /qa

🔗 USEFUL COMMANDS
1. /sdd:story-continue     # Resume current work
2. /sdd:story-next         # Get next recommended story
3. /sdd:story-status       # See all individual story details
```

### Example 2: Project Without Brief
```bash
INPUT:
/sdd:project-status

OUTPUT:
📊 PROJECT STATUS (SIMPLIFIED)
===============================

📁 Story Distribution:
- Development: 2 stories
- Review: 1 story
- QA: 1 story
- Completed: 3 stories
- Total: 7 stories

💡 RECOMMENDATION
Create a project brief for better organization and tracking:
→ /sdd:project-brief

Available commands:
1. /sdd:story-new      # Create new story
2. /sdd:story-status   # View story details
3. /sdd:project-brief  # Create project structure
```

### Example 3: No Project Context
```bash
INPUT:
/sdd:project-status

OUTPUT:
⚠️  PROJECT CONTEXT NOT FOUND

The /project-context/ directory does not exist.

To set up the story-driven development system, run:
→ /sdd:project-init

This will create:
- Project context files
- Story directory structure
- Development workflow templates
```

## Edge Cases

### No Stories Found
IF no stories exist in any directory:
- DISPLAY message about empty project
- SUGGEST creating first story with `/sdd:story-new`
- PROVIDE link to `/sdd:project-brief` for planning

### Blocked Stories Only
IF all pending stories are blocked:
- HIGHLIGHT critical blocker in status
- IDENTIFY which story is blocking others
- SUGGEST focusing on unblocking work

### All Stories Complete
IF all stories are completed:
- CONGRATULATE on project completion
- SUGGEST running `/sdd:project-phase` for next phase
- PROVIDE option to archive or start new phase

## Error Handling
- **Missing /project-context/**: Suggest `/sdd:project-init` with clear instructions
- **Unreadable project brief**: Continue with simplified view, warn user
- **Corrupted story files**: Skip corrupted files, log warning, continue
- **Permission errors**: Report specific file/directory with permission issue

## Performance Considerations
- Story scanning optimizes by reading only metadata, not full content
- Large story collections (100+) process incrementally
- File I/O batched for efficiency
- Timeline calculations cached during single invocation

## Related Commands
- `/sdd:project-brief` - Create or update project documentation
- `/sdd:project-stories` - Detailed story list with dependencies
- `/sdd:project-phase` - Plan new development phase
- `/sdd:story-status` - Individual story details
- `/sdd:story-continue` - Resume active work
- `/sdd:story-next` - Get next recommended story

## Constraints
- ✅ MUST handle missing project context gracefully
- ✅ MUST provide actionable next steps
- ✅ MUST display progress visually
- 📊 SHOULD calculate accurate completion percentages
- 🎯 SHOULD identify ready-to-start stories
- ⚠️ MUST highlight blockers and issues clearly
