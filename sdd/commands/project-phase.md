# /sdd:project-phase

## Meta
- Version: 1.2
- Category: project-management
- Complexity: high
- Purpose: Interactively plan project development phases based on user requirements and preferences

## Definition
**Purpose**: Interactively plan the next development phase by gathering user input on desired features and improvements, with optional completion analysis of previous work.

**Syntax**: `/sdd:project-phase [phase_name] [--analyze-only]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| phase_name | string | No | Auto-generate (e.g., "Phase 2", "v2.0") | Name for the new development phase | Non-empty if provided |
| --analyze-only | flag | No | false | Only perform analysis without creating new phase documentation | Boolean flag |

## INSTRUCTION: Interactive Phase Planning with User Input

### INPUTS
- phase_name: New phase identifier (optional, auto-generated if not provided)
- current_brief: Main project brief at `/docs/project-context/project-brief.md`
- user_requirements: Interactive input from user about desired features and improvements
- existing_phases: Previous phase documentation in `/docs/project-context/phases/`
- analyze_only: Flag to perform analysis without creating new phase
- Optional context: Stories in `/docs/stories/completed/`, `/docs/stories/development/`, `/docs/stories/review/`, `/docs/stories/qa/`

### PROCESS

#### Phase 1: Environment Setup and Discovery
1. **VERIFY** main project brief exists at `/docs/project-context/project-brief.md`
2. **CREATE** `/docs/project-context/phases/` directory if missing
3. **SCAN** existing phase directories to determine version number
4. **OPTIONAL CONTEXT GATHERING**:
   - Count stories in each directory (`/docs/stories/development/`, `/docs/stories/review/`, `/docs/stories/qa/`, `/docs/stories/completed/`)
   - Identify recent development patterns for context only

#### Phase 2: User Consultation for New Phase
1. **PRESENT PROJECT STATUS**:
   - **SHOW** current project state and recent development activity
   - **SUMMARIZE** any incomplete work in development/review/qa
   - **HIGHLIGHT** recent completed features and achievements

2. **ASK USER ABOUT NEW PHASE**:
   - **ASK**: "Based on the current project state, do you want to plan a new development phase?"
   - **EXPLAIN** what a new phase would involve (planning features, organizing stories, setting goals)
   - **PROVIDE OPTIONS**:
     * "Yes, I want to plan a new phase with specific features and improvements"
     * "No, I want to continue with existing work or make smaller adjustments"
     * "I'm not sure, help me understand what a new phase would look like"

3. **IF USER SAYS NO or UNSURE**:
   - **SUGGEST** alternatives like:
     * Continuing existing stories in development
     * Making incremental improvements without formal phase planning
     * Reviewing current work and identifying immediate next steps
   - **EXIT** without creating new phase documentation
   - **PROVIDE** guidance on other available commands for incremental work

4. **IF USER SAYS YES**:
   - **GENERATE** phase identifier:
     - IF phase_name provided: USE provided name
     - ELSE: AUTO-GENERATE as "phase-N" where N is next sequential number
   - **PROCEED** to Phase 3 (Interactive Requirements Gathering)

#### Phase 3: Interactive Requirements Gathering (Only if User Approved New Phase)
1. **USER CONSULTATION - PRIMARY FEATURES**:
   - **ASK**: "What are the main features or improvements you want to focus on in this phase?"
   - **PROMPT** for specific areas:
     * New functionality you'd like to add
     * Existing features that need improvement
     * User experience enhancements
     * Performance or technical improvements
   - **GATHER** priority ranking from user input

2. **USER CONSULTATION - TECHNICAL PREFERENCES**:
   - **ASK**: "Are there any technical areas you'd like to address?"
     * Code refactoring or cleanup
     * Testing improvements
     * Performance optimizations
     * Security enhancements
     * Accessibility improvements
   - **UNDERSTAND** user's technical comfort level and preferences

3. **USER CONSULTATION - CONSTRAINTS**:
   - **ASK**: "What constraints should we consider for this phase?"
     * Time limitations
     * Complexity preferences (simple vs. ambitious)
     * Dependencies on external factors
     * Resource availability
   - **CLARIFY** realistic scope expectations

4. **FEATURE CATEGORIZATION** (Based on user input):
   - **Iteration Features**: User-identified improvements to existing functionality
   - **Extension Features**: User-requested new capabilities
   - **Foundation Features**: User-approved technical improvements

#### Phase 4: Optional Context Analysis
1. **IF USER REQUESTS CONTEXT** from previous work:
   - REVIEW completed stories for relevant patterns
   - ASSESS current technical foundation capabilities
   - IDENTIFY any blockers from incomplete work

2. **TECHNICAL FOUNDATION REVIEW** (only if relevant to user goals):
   - EVALUATE current stack capabilities against user requirements
   - IDENTIFY necessary technical prerequisites
   - ASSESS feasibility of user-requested features

3. **SUCCESS CRITERIA DEFINITION** (collaborative):
   - WORK WITH USER to define measurable goals
   - SET realistic timelines based on user constraints
   - ESTABLISH clear completion criteria for each feature

#### Phase 5: User Confirmation for Documentation
1. **IF analyze_only flag is TRUE**:
   - GENERATE analysis report to console
   - PROVIDE recommendations without creating files
   - SUGGEST optimal phase planning approach
   - EXIT without file creation

2. **MANDATORY USER CONFIRMATION** (for full phase creation):
   - **PRESENT** complete phase plan summary to user including:
     * Proposed phase name and scope
     * Feature categories and priorities (based on user input)
     * Estimated timeline and effort
     * Technical approach and considerations
     * Story breakdown and dependencies
   - **ASK EXPLICITLY**: "Should I proceed with creating the phase documentation files based on this plan?"
   - **REQUIRE** explicit user approval (yes/no response)
   - **IF USER DECLINES**: Exit without creating any files, suggest refinements
   - **IF USER APPROVES**: Proceed to Phase 6 (Documentation Generation)

#### Phase 6: Phase Documentation Generation (User Approved Only)
1. **ONLY EXECUTE if user explicitly approved in Phase 5**:
   - **CREATE** phase directory: `/docs/project-context/phases/[phase_name]/`
   - **GENERATE** phase brief at `/docs/project-context/phases/[phase_name]/phase-brief.md`:
     ```markdown
     # Phase Brief: [phase_name]

     **Phase Name:** [phase_name]
     **Created:** [date]
     **Previous Phase Completion:** [completion_percentage]%
     **Estimated Duration:** [duration]

     ## Phase Overview
     [Description of this development phase goals and focus]

     ## Previous Phase Summary
     ### Recent Development Context
     [Brief summary of recent work for context, if relevant]

     ### Current Project State
     [Assessment of current capabilities and foundation]

     ## Phase Goals & Objectives
     ### Primary Focus
     [Main goal for this phase]

     ### Success Criteria
     [Measurable outcomes and quality gates]

     ## Feature Categories

     ### Iteration Features (Improve Existing)
     [User-identified improvements to existing functionality with effort estimates]

     ### Extension Features (Build New)
     [User-requested new capabilities with effort estimates and dependencies]

     ### Foundation Features (Technical Improvements)
     [User-approved technical improvements with effort estimates]

     ## Technical Considerations
     ### Required Refactoring
     [Technical debt and refactoring needs]

     ### Performance Targets
     [Specific performance goals and metrics]

     ### Quality Improvements
     [Testing, accessibility, and code quality goals]

     ## Dependencies and Prerequisites
     [What must be completed before starting each feature category]

     ## Risk Assessment
     [Specific risks for this phase with mitigation strategies]

     ## Estimated Timeline
     [Phase-based implementation plan with milestones]

     ## Story Planning
     [List of stories to be created for this phase]

     ## Success Metrics
     [How to measure phase completion and success]
     ```

   - **CREATE** story queue at `/docs/project-context/phases/[phase_name]/story-queue.md`:
     ```markdown
     # Story Queue: [phase_name]

     ## Ready for Development
     [Stories ready to move to /docs/stories/development/]

     ## Blocked/Waiting
     [Stories waiting for dependencies or decisions]

     ## Future Consideration
     [Stories for later in the phase or next phase]

     ## Story Dependencies
     [Dependency relationships between new stories]
     ```

   - **UPDATE** main project brief:
     - ADD phase summary based on user input
     - UPDATE timeline with new phase
     - REFERENCE new phase documentation

#### Phase 7: Story Planning and Organization
1. **USER STORY DEFINITION** (based on user requirements):
   - CONVERT user requirements into actionable stories
   - BREAK DOWN complex features into implementable chunks
   - PRIORITIZE based on user preferences and dependencies

2. **STORY QUEUE POPULATION**:
   - POPULATE story queue with user-defined priorities
   - ORGANIZE by user-specified implementation order
   - ESTIMATE effort based on user constraints and complexity preferences

3. **EXISTING WORK INTEGRATION**:
   - REVIEW any incomplete stories for relevance to new phase
   - SUGGEST continuation only if aligned with user goals
   - IDENTIFY conflicts between existing work and new direction

#### Phase 8: Final Summary and Next Steps
1. **COMPLETION SUMMARY**:
   - CONFIRM phase documentation has been created successfully
   - SUMMARIZE what was implemented based on user requirements
   - HIGHLIGHT key files created and their purposes

2. **GENERATE** operation summary with:
   - User-defined feature goals and categories
   - Estimated timeline based on user constraints
   - Implementation approach aligned with user preferences
   - Recommended next steps for development

3. **PROVIDE** actionable next steps:
   - Commands to run to start new phase development
   - Story creation recommendations based on user priorities
   - Technical setup requirements for user-requested features

### OUTPUTS
- `/docs/project-context/phases/[phase_name]/phase-brief.md`: Focused phase documentation
- `/docs/project-context/phases/[phase_name]/story-queue.md`: Prioritized story backlog
- Updated `/docs/project-context/project-brief.md`: Phase completion summary
- Console summary: Completion analysis and phase planning results

### RULES
- **MUST** preserve all existing project documentation
- **MUST** prioritize user input over automated analysis
- **MUST** ask clarifying questions to understand user requirements
- **MUST** get explicit user approval before creating any new phase documentation
- **MUST** exit gracefully if user does not want a new phase
- **MUST NOT** create individual story files (only queue them)
- **SHOULD** focus on user-defined priorities and goals
- **SHOULD** build upon technical foundation already established
- **MUST** maintain consistency with main project brief
- **SHOULD** provide realistic effort estimates based on user constraints

### ERROR HANDLING
- **Missing project brief**: Error and suggest running `/sdd:project-brief` first
- **Insufficient user input**: Ask clarifying questions to gather requirements
- **File system errors**: Report specific error and suggest manual intervention
- **Invalid phase name**: Sanitize and suggest corrected version

### PERFORMANCE CONSIDERATIONS
- **Large story collections**: Process incrementally to avoid memory issues
- **Complex dependency analysis**: Limit analysis to direct dependencies
- **File I/O optimization**: Batch read operations for story analysis

### SECURITY CONSIDERATIONS
- **File permissions**: Ensure write access to project-context directory
- **Path validation**: Sanitize all file paths and directory names
- **Data integrity**: Validate story file parsing before analysis

### INTEGRATION WITH EXISTING WORKFLOW
- **Before**: Must have existing project brief
- **After**: Use `/sdd:story-new` to create individual stories from queue
- **Complements**: Works with `/sdd:project-brief` for major updates
- **Feeds into**: Standard story development workflow

### RELATED COMMANDS
- `/sdd:project-brief`: Update main project documentation
- `/sdd:story-new`: Create individual stories from phase queue
- `/sdd:project-status`: View current development state
- `/sdd:story-relationships`: Manage dependencies between stories

### VERSION HISTORY
- **v1.0**: Initial implementation with completion analysis and phase planning
- **v1.1**: Updated to prioritize interactive user input over automated analysis
- **v1.2**: Added mandatory user consultation before phase creation and explicit approval before documentation
