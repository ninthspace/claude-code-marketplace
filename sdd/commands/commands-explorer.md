# Commands Explorer

## Meta
- Version: 1.0
- Category: development-tooling
- Complexity: moderate
- Purpose: Interactive command ecosystem exploration and management

## Definition
**Purpose**: Provides an interactive environment for exploring, understanding, modifying, and creating commands within the `.claude/commands/` directory. Enables comprehensive command ecosystem management with guided workflows.

**Syntax**: `/sdd:commands-explorer [query]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| query | string | No | - | Optional natural language query about commands | Free-form text |

## Capabilities

The Commands Explorer provides five primary capabilities:

### 1. Examine Commands
**Purpose**: Inspect and analyze existing command documentation

**Example Queries**:
- "Show me the details of `/sdd:story-new`"
- "What does `/sdd:project-status` actually do?"
- "Compare `/sdd:story-review` and `/sdd:story-qa`"

**Process**:
1. LOCATE the requested command file(s)
2. READ complete command documentation
3. EXTRACT key sections (purpose, parameters, behavior)
4. PRESENT structured analysis
5. IDENTIFY related commands

### 2. Modify Existing Commands
**Purpose**: Update and enhance existing command functionality

**Example Queries**:
- "Update `/sdd:story-implement` to include automated testing"
- "Add error handling to `/sdd:story-ship`"
- "Enhance `/sdd:project-status` with git branch info"

**Process**:
1. READ existing command documentation
2. IDENTIFY sections requiring modification
3. PROPOSE changes with clear rationale
4. PRESERVE existing command structure
5. UPDATE command file with enhancements
6. VALIDATE syntax and completeness

### 3. Create New Commands
**Purpose**: Generate new commands following project conventions

**Example Queries**:
- "Create a `/sdd:story-debug` command for troubleshooting"
- "Add a `/sdd:story-backup` command to save work in progress"
- "Build a `/sdd:project-cleanup` command for maintenance"

**Process**:
1. GATHER requirements from user query
2. DETERMINE command category (project/story/utility)
3. SELECT appropriate naming convention
4. GENERATE command structure:
   - Command name and description
   - Usage patterns
   - Parameter definitions
   - Behavioral specifications
   - Examples and prerequisites
5. CREATE command file in `.claude/commands/`
6. INTEGRATE with existing workflow patterns

### 4. Optimize Workflows
**Purpose**: Streamline and improve command usage patterns

**Example Queries**:
- "Streamline the review process workflow"
- "Add shortcuts for common command sequences"
- "Create aliases for frequently used commands"

**Process**:
1. ANALYZE current workflow patterns
2. IDENTIFY bottlenecks or repetitive sequences
3. PROPOSE optimization strategies
4. IMPLEMENT workflow improvements
5. UPDATE related command documentation

### 5. Analyze Dependencies
**Purpose**: Map command relationships and requirements

**Example Queries**:
- "What commands depend on git being clean?"
- "Which commands modify the filesystem?"
- "Show me commands that require manual input"

**Process**:
1. SCAN all command files
2. EXTRACT dependency information
3. MAP command relationships
4. CATEGORIZE by dependency type
5. PRESENT structured analysis

## Command Categories

The system automatically categorizes commands into logical groups:

### Project Management Commands
**Purpose**: Project-wide operations and initialization
- `project-brief.md` - Project overview and brief generation
- `project-context-update.md` - Update project context and documentation
- `project-init.md` - Initialize new project structure
- `project-status.md` - Check overall project status
- `project-stories.md` - Manage project stories and workflow

### Story Workflow Commands
**Purpose**: Core story-driven development lifecycle
- `story-new.md` - Create new story
- `story-start.md` - Begin working on a story
- `story-continue.md` - Resume work on current story
- `story-implement.md` - Implement story requirements
- `story-review.md` - Review story implementation
- `story-qa.md` - Quality assurance validation
- `story-ship.md` - Ship completed story
- `story-complete.md` - Mark story as complete

### Story Management Commands
**Purpose**: Story state and lifecycle management
- `story-status.md` - Check current story status
- `story-next.md` - Move to next story in workflow
- `story-save.md` - Save current story progress
- `story-document.md` - Document story details
- `story-validate.md` - Validate story implementation
- `story-rollback.md` - Rollback story changes
- `story-blocked.md` - Mark story as blocked

### Development Support Commands
**Purpose**: Code quality and technical operations
- `story-refactor.md` - Refactor existing code
- `story-tech-debt.md` - Address technical debt
- `story-test-integration.md` - Integration testing workflows
- `story-patterns.md` - Code patterns and standards
- `story-metrics.md` - Development metrics tracking

### Utility Commands
**Purpose**: Development tooling and checks
- `story-quick-check.md` - Quick health checks
- `story-full-check.md` - Comprehensive validation
- `story-timebox.md` - Time management utilities
- `story-today.md` - Daily development planning

## Common Workflows

### Starting New Work
```
/sdd:story-new → /sdd:story-start → /sdd:story-implement
```

### Review & Ship
```
/sdd:story-review → /sdd:story-qa → /sdd:story-ship → /sdd:story-complete
```

### Project Management
```
/sdd:project-status → /sdd:project-stories → /sdd:story-next
```

## Command Modification Guidelines

When modifying or creating commands through the explorer:

### Standard Command Structure
```markdown
# Command Name

Brief description of what the command does.

## Usage
How to use the command and when to use it.

## What it does
Detailed steps the command performs.

## Prerequisites (if any)
What needs to be in place before running.

## Examples
Practical usage examples.
```

### Naming Conventions
- **Project commands**: `project-*` - Project-wide operations
- **Story commands**: `story-*` - Story-specific operations
- **Utility commands**: Descriptive names for general utilities

### Integration Requirements
- MUST integrate with existing workflows
- SHOULD consider git state requirements
- MUST document dependencies on other commands
- SHOULD maintain consistency with project patterns

## Interactive Session Features

When Commands Explorer is invoked, it establishes:

1. **Command Discovery**: Comprehensive catalogue of all commands
2. **Workflow Understanding**: Mapped command relationships and sequences
3. **Quick Access**: Identified common command patterns
4. **Documentation Access**: Full command documentation available
5. **Interactive Modification**: Complete editing capabilities
6. **Pattern Consistency**: Guided creation following standards

## Rules

### Command Management
- MUST preserve existing command functionality when modifying
- NEVER remove critical command sections without explicit approval
- SHOULD suggest improvements based on command best practices
- MUST maintain consistent formatting across all commands
- SHOULD validate command syntax before saving

### File Operations
- MUST use `.claude/commands/` directory for all commands
- SHOULD create backups before modifying existing commands
- MUST follow markdown naming convention: `command-name.md`
- NEVER overwrite commands without confirmation

### Documentation Standards
- MUST include purpose and usage for all commands
- SHOULD provide multiple examples for complex commands
- MUST document all parameters with types and defaults
- SHOULD explain command relationships and dependencies
- MUST maintain accurate category assignments

## Usage Examples

### Example 1: Examine a Command
```
User: "Show me how /sdd:story-new works"

Response:
[Reads story-new.md]
[Presents structured analysis]
━━━━━━━━━━━━━━━━━━━━━━━━
Command: /sdd:story-new
Category: Story Workflow
Purpose: Create new story in development workflow
[... detailed breakdown ...]
```

### Example 2: Create New Command
```
User: "Create a /sdd:story-debug command for troubleshooting"

Response:
[Gathers requirements]
[Generates command structure]
[Creates story-debug.md with proper format]
✅ Created: /sdd:story-debug
Category: Development Support
Location: .claude/commands/sdd:story-debug.md
```

### Example 3: Analyze Dependencies
```
User: "Which commands modify the filesystem?"

Response:
Commands that modify the filesystem:
━━━━━━━━━━━━━━━━━━━━━━━━
1. /sdd:story-new - Creates story files
2. /sdd:story-save - Writes progress snapshots
3. /sdd:story-ship - Moves files between directories
4. /sdd:project-init - Creates project structure
[... complete analysis ...]
```

## Getting Started

**Quick Start Queries**:
- "Show me how `/sdd:story-new` works"
- "Create a new command for X"
- "Modify `/sdd:story-implement` to do Y"
- "What's the difference between review and QA commands?"
- "List all commands that create files"

## Notes
- All commands are stored as markdown files in `.claude/commands/`
- Command files use kebab-case naming: `command-name.md`
- Commands are designed to work together in story-driven workflows
- The explorer maintains command ecosystem consistency
- Interactive mode allows natural language queries
- Command modifications follow existing project conventions

## Related Commands
- `/sdd:command-optimise` - Optimize command documentation format
- `/sdd:project-status` - View overall project and command status
- `/sdd:story-patterns` - Understand coding patterns (similar to command patterns)
