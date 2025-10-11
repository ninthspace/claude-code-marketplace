# /story-new

## Meta
- Version: 2.0
- Category: story-management
- Complexity: medium
- Purpose: Create new story with auto-populated template and place in backlog

## Definition
**Purpose**: Create a new story using project context and place it in the backlog folder for future development.

**Syntax**: `/story-new [story_id_number]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| story_id_number | number | No | auto-increment | Story number (used as STORY-YYYY-NNN) | Positive integer |

## INSTRUCTION: Create New Story

### INPUTS
- story_id_number: Optional story number (auto-increments if not provided)
- Project context from `/project-context/` directory
- User-provided story details (if not in project brief)

### PROCESS

#### Phase 1: Project Context Loading
1. **CHECK** if `/project-context/` directory exists
2. IF missing:
   - SUGGEST running `/project-init` first
   - EXIT with initialization guidance
3. **LOAD** project context from:
   - `/project-context/project-brief.md` - Existing story definitions, goals
   - `/project-context/technical-stack.md` - Technology implementation requirements
   - `/project-context/coding-standards.md` - Testing and quality requirements

#### Phase 2: Story ID Generation
1. **GENERATE** story ID in format `STORY-YYYY-NNN`:
   - YYYY = current year
   - NNN = sequential number (001, 002, etc.)

2. IF user provides story_id_number:
   - USE as basis: `STORY-YYYY-[story_id_number]`
   - EXAMPLE: Input "5" → "STORY-2025-005"

3. **CHECK** for existing IDs across all directories:
   - SCAN `/stories/backlog/`
   - SCAN `/stories/development/`
   - SCAN `/stories/review/`
   - SCAN `/stories/qa/`
   - SCAN `/stories/completed/`
   - CHECK `/project-context/project-brief.md` for planned stories

4. IF no specific number provided:
   - INCREMENT to next available number
   - ENSURE uniqueness across all locations

#### Phase 3: Story Information Gathering
1. **SEARCH** `/project-context/project-brief.md` for story with generated ID
2. IF story exists in project brief:
   - EXTRACT comprehensive story details:
     * Story title and description
     * User scenarios and use cases
     * Technical implementation requirements
     * Acceptance criteria (pass/fail conditions)
     * Edge cases and error handling requirements
     * UI/UX considerations
     * Testing requirements and test scenarios
     * Integration points with other stories/systems
     * Dependencies on other stories

3. IF story NOT found in project brief:
   - **ASK** user for story title
   - **ASK** user for story description and purpose
   - **ASK** user for acceptance criteria
   - **ASK** user for technical approach (optional)
   - **ASK** user for dependencies (optional)

#### Phase 4: Story File Creation
1. **ENSURE** `/stories/backlog/` directory exists
   - CREATE directory if missing
   - ADD `.gitkeep` file if directory was created

2. **CREATE** story file at `/stories/backlog/[story-id].md`

3. **POPULATE** template with:
   - Story ID and title
   - Status: backlog
   - Today's date as "Started" date
   - Empty "Completed" date
   - Note: "(none - in backlog)" for branch
   - What & Why section (from project brief or user input)
   - Success Criteria (from project brief or user input)
   - Technical Notes with:
     * Approach (from project brief or user input)
     * Stack (auto-populated from technical-stack.md)
     * Concerns (from project brief edge cases or user input)
     * Dependencies (from project brief or user input)
   - Implementation Checklist (standard items)
   - Progress Log with creation entry
   - Test Cases (from project brief or default scenarios)
   - UI/UX Considerations (from project brief if applicable)
   - Integration Points (from project brief if applicable)
   - Rollback Plan section (empty template)
   - Lessons Learned section (empty template)

4. **REFERENCE** project context in template:
   - Pull technology stack from technical-stack.md
   - Note coding standards that will apply
   - Reference testing framework requirements
   - Include project goals and constraints from project-brief.md

#### Phase 5: Completion Summary
1. **DISPLAY** creation summary:
   ```
   ✅ Story Created
   ═══════════════════════════════════

   Story ID: [STORY-YYYY-NNN]
   Title: [Story Title]
   Location: /stories/backlog/[story-id].md
   Status: backlog

   [If from project brief:]
   Source: Extracted from project brief
   - Acceptance criteria: [count] criteria defined
   - Test scenarios: [count] scenarios defined
   - Dependencies: [list or "None"]

   [If from user input:]
   Source: User-provided details
   - Ready for refinement before development
   ```

2. **SUGGEST** next steps:
   ```
   💡 NEXT STEPS:
   1. /story-start [story-id]     # Move to development and create branch
   2. /story-implement [story-id]  # Generate implementation code
   3. /project-status              # View all project stories
   ```

### OUTPUTS
- `/stories/backlog/[story-id].md` - New story file with populated template
- `.gitkeep` file in `/stories/backlog/` if directory was created

### RULES
- MUST generate unique story ID across all story directories
- MUST create backlog directory if it doesn't exist
- MUST auto-populate template with project context
- SHOULD extract story details from project brief if available
- SHOULD reference technical stack in story template
- NEVER create feature branch (stories start in backlog)
- ALWAYS add progress log entry for creation
- MUST include today's date as "Started" date

## Story Template Structure

```markdown
# [STORY-ID]: [Title]

## Status: backlog
**Started:** [Today's Date]
**Completed:**
**Branch:** (none - in backlog)

## What & Why
[Story description and purpose]

## Success Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Technical Notes
**Approach:** [Implementation approach]
**Stack:** [Auto-populated from technical-stack.md]
**Concerns:** [Risks and edge cases]
**Dependencies:** [External services/libraries/other stories]

## Implementation Checklist
- [ ] Feature implementation
- [ ] Unit tests
- [ ] Integration tests
- [ ] Error handling
- [ ] Loading states
- [ ] Documentation
- [ ] Performance optimization
- [ ] Accessibility
- [ ] Security review

## Progress Log
- [Today]: Created story, added to backlog

## Test Cases
1. Happy path: [scenario]
2. Error case: [scenario]
3. Edge case: [scenario]

## UI/UX Considerations
[User interface and experience requirements]

## Integration Points
[Dependencies and integration with other systems]

## Rollback Plan
[How to rollback if issues arise]

## Lessons Learned
[To be filled when complete]
```

## Examples

### Example 1: Create from Project Brief
```bash
INPUT:
/story-new

OUTPUT:
→ Checking project context...
→ Generating story ID: STORY-2025-001
→ Found story definition in project brief

✅ Story Created
═══════════════════════════════════

Story ID: STORY-2025-001
Title: User Authentication System
Location: /stories/backlog/STORY-2025-001.md
Status: backlog

Source: Extracted from project brief
- Acceptance criteria: 5 criteria defined
- Test scenarios: 8 scenarios defined
- Dependencies: None

💡 NEXT STEPS:
1. /story-start STORY-2025-001     # Move to development and create branch
2. /story-implement STORY-2025-001  # Generate implementation code
3. /project-status                  # View all project stories
```

### Example 2: Create with Specific ID
```bash
INPUT:
/story-new 10

OUTPUT:
→ Checking project context...
→ Using story ID: STORY-2025-010
→ Story not found in project brief, gathering details...

What is the story title?
> Add Dark Mode Toggle

What are you building and why?
> Implement a dark mode toggle in the settings page to allow users to switch between light and dark themes.

What are the acceptance criteria? (Enter each, then empty line when done)
> Toggle is visible in settings page
> Theme persists across sessions
> All UI components support both themes
>

✅ Story Created
═══════════════════════════════════

Story ID: STORY-2025-010
Title: Add Dark Mode Toggle
Location: /stories/backlog/STORY-2025-010.md
Status: backlog

Source: User-provided details
- Ready for refinement before development

💡 NEXT STEPS:
1. /story-start STORY-2025-010      # Move to development and create branch
2. /story-implement STORY-2025-010   # Generate implementation code
3. /project-status                   # View all project stories
```

### Example 3: Auto-Increment ID
```bash
INPUT:
/story-new

OUTPUT:
→ Checking project context...
→ Found existing stories: STORY-2025-001 through STORY-2025-005
→ Auto-incrementing to: STORY-2025-006
→ Story not found in project brief, gathering details...

[Interactive prompts for story details...]

✅ Story Created
═══════════════════════════════════

Story ID: STORY-2025-006
Title: Payment Processing Integration
Location: /stories/backlog/STORY-2025-006.md
Status: backlog
```

## Edge Cases

### No Project Context
- DETECT missing `/project-context/` directory
- SUGGEST running `/project-init`
- OFFER to create story with minimal template
- WARN that template won't be auto-populated

### Duplicate Story ID
- DETECT ID conflict across all directories
- INCREMENT to next available number automatically
- LOG warning about skipped number
- ENSURE final ID is unique

### Empty Project Brief
- DETECT missing story definitions
- GATHER all details from user interactively
- CREATE story with user-provided information
- SUGGEST adding stories to project brief

### Malformed Project Brief
- DETECT parsing errors
- LOG warning about brief issues
- FALL BACK to user input mode
- CONTINUE with story creation

## Error Handling
- **Missing /project-context/**: Suggest `/project-init` with guidance
- **Permission errors**: Report specific file/directory with access issue
- **Invalid story ID**: Sanitize and suggest corrected version
- **User cancels**: Clean up partial creation, exit gracefully

## Performance Considerations
- Story ID checking optimizes by scanning directories once
- Project brief parsing caches results for session
- Template population is fast (< 100ms typically)
- Interactive prompts allow user to control pace

## Related Commands
- `/project-init` - Initialize project structure first
- `/project-brief` - Create/update project documentation with stories
- `/story-start [id]` - Begin development on story
- `/story-implement [id]` - Generate implementation code
- `/project-status` - View all project stories

## Constraints
- ✅ MUST generate unique story ID
- ✅ MUST create story in backlog directory
- ⚠️ NEVER create feature branch (stories start in backlog)
- 📋 MUST auto-populate from project context when available
- 🔧 SHOULD extract from project brief before asking user
- 💾 MUST add creation entry to progress log
- 📅 MUST include today's date as "Started" date
