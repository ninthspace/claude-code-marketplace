# /project-brief

## Meta
- Version: 2.0
- Category: project-planning
- Complexity: high
- Purpose: Creates comprehensive project briefs with intelligent story breakdown and version management

## Definition
**Purpose**: Generate comprehensive project briefs that intelligently break down complex features into multiple related stories, building upon existing project context when available.

**Syntax**: `/project-brief [project_title]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| project_title | string | No | prompted | Name of the project or feature set | Non-empty string |

## INSTRUCTION: Create Comprehensive Project Brief

### INPUTS
- project_title: Project or feature name (prompted if not provided)
- Existing project context files (if present):
  - `/project-context/project-brief.md` (current brief)
  - `/project-context/story-relationships.md` (story dependencies)
  - `/project-context/versions/` (historical versions)

### PROCESS

#### Phase 1: Version Management & Context Loading
1. CHECK for existing project brief at `/project-context/project-brief.md`
2. IF exists:
   - CREATE `/project-context/versions/` directory if not present
   - ADD `.gitkeep` file to versions directory
   - GENERATE timestamp in format YYYYMMDD-HHMMSS
   - MOVE existing brief to `/project-context/versions/project-brief-v[N]-[timestamp].md`
   - PARSE existing brief to extract:
     * Current stories and their status
     * Timeline and milestones
     * Project objectives
     * Stakeholder information
   - LOG version backup location
3. CHECK for existing `/project-context/story-relationships.md`
4. IF exists:
   - MOVE to `/project-context/versions/story-relationships-v[N]-[timestamp].md`
5. LOAD existing context to build upon (don't start from scratch)

#### Phase 2: Requirements Gathering
1. IF project_title not provided:
   - PROMPT: "What is the title of this project?"
   - VALIDATE: Non-empty string
   - SET project_title from response

2. IF existing brief found:
   - REVIEW existing objectives and expand/refine them
   - ANALYZE existing stakeholders and identify new ones
   - EXAMINE existing features and find gaps or enhancements
   - UPDATE technical constraints based on current context
   - ENHANCE existing success criteria with new metrics

3. ELSE (no existing brief):
   - GATHER initial requirements by asking:
     * "What is the high-level goal of this project?"
     * "Who are the primary users/stakeholders?"
     * "What are the core features that must be delivered?"
     * "What are nice-to-have enhancements?"
     * "Are there any technical constraints or dependencies?"
     * "What are the success criteria?"

#### Phase 3: Intelligent Story Breakdown
1. ANALYZE requirements to identify:
   - Core functionality (must-have stories)
   - Enhancement features (should-have stories)
   - Future considerations (could-have stories)

2. FOR EACH identified story:
   - DEFINE detailed description of what the story accomplishes
   - SPECIFY user scenarios and use cases
   - DOCUMENT technical implementation requirements
   - CREATE acceptance criteria with clear pass/fail conditions
   - IDENTIFY edge cases and error handling requirements
   - NOTE UI/UX considerations (if applicable)
   - LIST testing requirements and test scenarios
   - MAP integration points with other stories or systems

3. DETERMINE logical dependencies between stories
4. ESTIMATE relative effort using scale: S / M / L / XL

#### Phase 4: Project Brief Creation
1. GENERATE project brief content using project brief template
2. INCLUDE sections:
   - Project Overview
   - Objectives (built upon existing if applicable)
   - Stakeholders
   - Core Features
   - Story Breakdown (with comprehensive details)
   - Dependencies
   - Timeline (if applicable)
   - Success Criteria

3. WRITE to `/project-context/project-brief.md`
   - ⚠️ MANDATORY: File MUST be at `/project-context/project-brief.md`
   - ⚠️ MANDATORY: Do NOT create individual story files in `/stories/development/`

#### Phase 5: Story Relationships File (OPTIONAL)
1. IF stories have dependencies:
   - CREATE `/project-context/story-relationships.md`
   - INCLUDE sections:
     * Dependency Graph (ASCII diagram)
     * Story Priority Matrix (table format)
     * Implementation Order (phased breakdown)

2. FORMAT Story Priority Matrix:
   ```markdown
   | Story ID | Title | Priority | Dependencies | Effort | Status |
   |----------|-------|----------|--------------|--------|--------|
   | STORY-XX | ... | Core | None | M | development |
   | STORY-YY | ... | Core | STORY-XX | L | backlog |
   ```

3. GROUP stories by implementation phase:
   - Phase 1 (Core): Foundation stories
   - Phase 2 (Enhancement): Feature expansions
   - Phase 3 (Polish): Nice-to-have improvements

#### Phase 6: Summary & Next Steps
1. DISPLAY summary report:
   ```
   ✅ Project Brief Created
   ═══════════════════════════════════
   Project: [project_title]
   Brief Location: /project-context/project-brief.md
   Relationships: /project-context/story-relationships.md

   Stories Identified: [count]
   - Core Stories: [count]
   - Enhancement Stories: [count]
   - Future Stories: [count]

   Dependencies: [count] identified
   Implementation Phases: [count]
   ```

2. SUGGEST next steps:
   - Run `/project-init` to set up development environment
   - Use `/story-new` to start with core stories
   - Follow suggested implementation order from story-relationships.md

### OUTPUTS
- `/project-context/project-brief.md` - Comprehensive project brief
- `/project-context/story-relationships.md` - Story dependencies and implementation order (if applicable)
- `/project-context/versions/project-brief-v[N]-[timestamp].md` - Versioned backup (if updating existing)
- `/project-context/versions/story-relationships-v[N]-[timestamp].md` - Versioned relationships backup (if exists)

### RULES
- MUST complete version backup before modifying existing files
- MUST preserve all existing project context when building upon it
- NEVER create individual story files in `/stories/development/` directory
- ALWAYS create comprehensive story definitions with all required elements
- SHOULD use existing project context as foundation, not start from scratch
- MUST include acceptance criteria for every story
- MUST document dependencies between related stories
- ALWAYS provide implementation order recommendations

## Story Definition Requirements

Each story MUST include:

1. **Detailed Description**
   - What the story accomplishes
   - Why it's needed (business value)

2. **User Scenarios**
   - Specific use cases
   - User workflows affected

3. **Technical Requirements**
   - Implementation approach
   - Technology choices
   - Architecture considerations

4. **Acceptance Criteria**
   - Clear pass/fail conditions
   - Testable requirements
   - Definition of "done"

5. **Edge Cases & Error Handling**
   - Boundary conditions
   - Failure scenarios
   - Error recovery

6. **UI/UX Considerations** (if applicable)
   - User interface requirements
   - User experience goals
   - Accessibility requirements

7. **Testing Requirements**
   - Test scenarios
   - Test data needed
   - Test coverage expectations

8. **Integration Points**
   - Dependencies on other stories
   - External system integrations
   - API requirements

## File Structure

### Required Files
```
/project-context/
├── project-brief.md              # Main project brief (REQUIRED)
└── story-relationships.md        # Story dependencies (OPTIONAL)
```

### Version Management
```
/project-context/versions/
├── .gitkeep                      # Ensures directory is tracked
├── project-brief-v1-20250101-143000.md
├── project-brief-v2-20250115-091500.md
└── story-relationships-v1-20250101-143000.md
```

## Example Output Structure

### Project Brief Template
```markdown
# Project Brief: [Project Title]

## Overview
[High-level project description]

## Objectives
- [Objective 1]
- [Objective 2]

## Stakeholders
- **Primary Users**: [description]
- **Business Stakeholders**: [description]
- **Technical Team**: [description]

## Core Features
1. [Feature 1]
2. [Feature 2]

## Story Breakdown

### STORY-XXX-001: [Story Title]
**Priority**: Core | **Effort**: M | **Status**: backlog

**Description**: [What this story accomplishes]

**User Scenarios**:
- [Scenario 1]
- [Scenario 2]

**Technical Requirements**:
- [Requirement 1]
- [Requirement 2]

**Acceptance Criteria**:
- [ ] [Criterion 1]
- [ ] [Criterion 2]

**Edge Cases**:
- [Edge case 1 and handling]

**Testing Requirements**:
- [Test scenario 1]

**Dependencies**: None

---

[Additional stories follow same format]

## Success Criteria
- [Success metric 1]
- [Success metric 2]
```

### Story Relationships Template
```markdown
# Story Relationships

## Dependency Graph
```
STORY-XXX-001 (Core)
    └── STORY-XXX-002 (Core, depends on 001)
        ├── STORY-XXX-003 (Enhancement, depends on 002)
        └── STORY-XXX-004 (Enhancement, depends on 002)

STORY-XXX-005 (Core, independent)
    └── STORY-XXX-006 (Polish, depends on 005)
```

## Story Priority Matrix
| Story ID | Title | Priority | Dependencies | Effort | Status |
|----------|-------|----------|--------------|--------|--------|
| STORY-XXX-001 | Foundation Setup | Core | None | M | development |
| STORY-XXX-002 | Core Feature | Core | STORY-XXX-001 | L | backlog |
| STORY-XXX-003 | Enhancement A | Enhancement | STORY-XXX-002 | M | backlog |

## Implementation Order

**Phase 1 (Core - Week 1-2)**
- STORY-XXX-001: Foundation Setup
- STORY-XXX-005: Independent Core Feature

**Phase 2 (Core - Week 3-4)**
- STORY-XXX-002: Core Feature (after 001)

**Phase 3 (Enhancement - Week 5-6)**
- STORY-XXX-003: Enhancement A (after 002)
- STORY-XXX-004: Enhancement B (after 002)

**Phase 4 (Polish - Week 7)**
- STORY-XXX-006: Polish Feature (after 005)
```

## Error Handling
- If project_title is empty after prompt: Return "Error: Project title is required"
- If unable to create versions directory: Return "Warning: Could not create versions directory. Proceeding without backup."
- If existing brief cannot be parsed: Create new brief and log warning
- If no stories can be identified: Return "Error: Unable to identify actionable stories from requirements"

## Constraints
- ⚠️ NEVER skip version management if existing files are present
- ⚠️ NEVER create individual story files in `/stories/development/`
- ✅ ALWAYS create comprehensive story definitions with all required elements
- ✅ ALWAYS preserve existing project context when building upon it
- ✅ MUST include dependency analysis if multiple stories exist
- 📝 SHOULD create story-relationships.md for projects with 3+ stories
- 🔄 MUST follow versioning pattern: project-brief-v[N]-[timestamp].md

## Usage Examples

### Example 1: New Project Brief
```bash
/project-brief

→ Prompts for project title
→ Gathers requirements interactively
→ Creates /project-context/project-brief.md
→ Creates /project-context/story-relationships.md

Output:
✅ Project Brief Created
Project: E-commerce Checkout Flow
Stories Identified: 5
- Core Stories: 3
- Enhancement Stories: 2
```

### Example 2: Updating Existing Brief
```bash
/project-brief "Enhanced Checkout"

→ Finds existing /project-context/project-brief.md
→ Creates backup: /project-context/versions/project-brief-v1-20250101-143000.md
→ Loads existing objectives and stories
→ Builds upon existing content
→ Creates enhanced version

Output:
✅ Project Brief Updated
Previous version backed up to: /project-context/versions/project-brief-v1-20250101-143000.md
New stories added: 3
Updated stories: 2
```

### Example 3: With Title Provided
```bash
/project-brief "Mobile App Dashboard"

→ Uses provided title
→ Gathers requirements
→ Creates comprehensive brief
→ No version management needed (new project)
```

## Performance Considerations
- Large existing briefs (10+ stories) may take longer to parse
- Version management adds minimal overhead (single file copy)
- Interactive requirement gathering allows user to control pace
- Story dependency analysis scales with story count

## Related Commands
- `/project-init` - Initialize development environment after brief creation
- `/story-new` - Create individual story from brief
- `/story-qa` - Quality assurance for completed stories