# /sdd:story-document

## Meta
- Version: 2.0
- Category: story-management
- Complexity: medium
- Purpose: Generate comprehensive documentation for implemented story features

## Definition
**Purpose**: Analyze story implementation and generate user, technical, and testing documentation with examples and inline code comments.

**Syntax**: `/sdd:story-document [story_id]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| story_id | string | No | current active | Story ID to document (format: STORY-YYYY-NNN) | Must be valid story ID |

## INSTRUCTION: Generate Story Documentation

### INPUTS
- story_id: Story to document (defaults to current active story)
- Story file from `/docs/stories/development/` or `/docs/stories/review/`
- Implemented code files referenced in story
- Project context from `/docs/project-context/`

### PROCESS

#### Phase 1: Story Location and Validation
1. **DETERMINE** which story to document:
   - IF story_id provided: USE specified story
   - IF no story_id: FIND current active story in `/docs/stories/development/`
2. **LOCATE** story file:
   - CHECK `/docs/stories/development/[story-id].md`
   - CHECK `/docs/stories/review/[story-id].md`
   - CHECK `/docs/stories/qa/[story-id].md`
3. IF story not found:
   - EXIT with error message
   - SUGGEST using `/sdd:project-status` to find valid story IDs

#### Phase 2: Story Analysis
1. **READ** story file to extract:
   - Feature title and description (from "What & Why" section)
   - Implementation details (from "Technical Notes")
   - Success criteria (acceptance criteria)
   - Test cases defined
   - UI/UX considerations
   - Integration points

2. **SCAN** codebase to identify implementation:
   - LOCATE files referenced in progress log
   - IDENTIFY new/modified components, functions, classes
   - EXTRACT public APIs and interfaces
   - MAP dependencies and imports
   - NOTE configuration files affected

3. **LOAD** project context:
   - `/docs/project-context/technical-stack.md` - Framework conventions
   - `/docs/project-context/coding-standards.md` - Documentation style
   - `/docs/project-context/development-process.md` - Doc requirements

#### Phase 3: Documentation Generation

**Generate Multiple Documentation Types:**

1. **USER DOCUMENTATION** (if user-facing feature):
   - CREATE `/docs/features/[feature-name].md`
   - INCLUDE:
     * Feature overview and purpose
     * How to use the feature (step-by-step)
     * Common use cases with examples
     * Troubleshooting guide
     * Screenshots or diagrams (note if needed)

2. **TECHNICAL DOCUMENTATION**:
   - CREATE `/docs/technical/[feature-name].md`
   - INCLUDE:
     * Architecture overview
     * Component/module descriptions
     * API reference (if applicable)
     * Configuration options
     * Integration guide
     * Data flow diagrams (note if needed)

3. **TESTING DOCUMENTATION**:
   - CREATE `/docs/testing/[feature-name].md`
   - INCLUDE:
     * How to test the feature
     * Test scenarios covered
     * Known edge cases
     * Performance benchmarks (if applicable)
     * Manual testing checklist

4. **INLINE CODE DOCUMENTATION**:
   - ADD framework-appropriate comments:
     * PHP: PHPDoc blocks
     * JavaScript/TypeScript: JSDoc/TSDoc
     * Python: Docstrings
     * [DISCOVERED language]: Appropriate style
   - DOCUMENT:
     * Public functions and methods
     * Component props/parameters
     * Complex logic explanations
     * Configuration constants
     * Event handlers and callbacks

5. **CODE EXAMPLES**:
   - CREATE `/docs/examples/[feature-name]/`
   - INCLUDE:
     * Basic usage snippets
     * Configuration examples
     * Integration examples
     * Common patterns
     * Copy-paste ready code

#### Phase 4: Update Existing Documentation
1. **UPDATE** project-level docs:
   - `/README.md` - Add feature to feature list (if user-facing)
   - `/docs/api.md` - Add API endpoints (if applicable)
   - `/docs/configuration.md` - Add new config options
   - `/CHANGELOG.md` - Document changes
   - `/docs/migration.md` - Add migration guide (if breaking changes)

2. **PRESERVE** existing content:
   - APPEND new sections rather than replace
   - MAINTAIN existing formatting style
   - KEEP version history intact

#### Phase 5: Story Documentation Update
1. **UPDATE** story file with documentation summary:
   ```markdown
   ## Documentation

   ### Generated Documentation
   - User Guide: /docs/features/[feature-name].md
   - Technical: /docs/technical/[feature-name].md
   - Testing: /docs/testing/[feature-name].md
   - Examples: /docs/examples/[feature-name]/

   ### Updated Documentation
   - README.md: Added feature to feature list
   - CHANGELOG.md: Documented changes for v[version]

   ### Inline Documentation
   - Added PHPDoc blocks to [count] functions
   - Documented [count] component props
   - Added complex logic comments in [file:line]

   ### Documentation Status
   - [x] User documentation complete
   - [x] Technical documentation complete
   - [x] Testing documentation complete
   - [x] Inline code comments added
   - [x] Examples created
   - [ ] Screenshots needed (optional)
   - [ ] Diagrams needed (optional)
   ```

2. **CHECK** documentation completion criteria:
   - [ ] All public APIs documented
   - [ ] User-facing features have user guide
   - [ ] Complex logic has inline comments
   - [ ] Examples demonstrate key use cases
   - [ ] Configuration options documented
   - [ ] Breaking changes documented in migration guide

#### Phase 6: Completion Summary
1. **DISPLAY** documentation summary:
   ```
   ✅ Documentation Generated
   ═══════════════════════════════════

   Story: [STORY-YYYY-NNN] - [Title]

   DOCUMENTATION CREATED:
   ✓ User Guide: /docs/features/[feature-name].md
   ✓ Technical: /docs/technical/[feature-name].md
   ✓ Testing: /docs/testing/[feature-name].md
   ✓ Examples: /docs/examples/[feature-name]/

   DOCUMENTATION UPDATED:
   ✓ README.md (feature list)
   ✓ CHANGELOG.md (version notes)
   [✓ Migration guide (if breaking changes)]

   INLINE DOCUMENTATION:
   ✓ [count] functions documented
   ✓ [count] components documented
   ✓ [count] complex logic comments

   DOCUMENTATION DEBT:
   [- Screenshots recommended for user guide]
   [- Sequence diagram would help explain flow]

   Story Updated: Documentation section added
   ```

2. **SUGGEST** next steps:
   ```
   💡 NEXT STEPS:
   1. Review generated documentation for accuracy
   2. Add screenshots/diagrams if noted
   3. /sdd:story-review [story-id]    # Move to code review
   4. Share docs with team for feedback
   ```

### OUTPUTS
- `/docs/features/[feature-name].md` - User-facing documentation
- `/docs/technical/[feature-name].md` - Technical documentation
- `/docs/testing/[feature-name].md` - Testing documentation
- `/docs/examples/[feature-name]/` - Code examples
- Updated project documentation (README, CHANGELOG, etc.)
- Inline code comments in implementation files
- Updated story file with documentation summary

### RULES
- MUST analyze story to understand what was built
- MUST generate appropriate doc types based on feature type
- MUST use framework-appropriate inline documentation style
- MUST update story file with documentation summary
- SHOULD create user docs for user-facing features
- SHOULD include code examples for all public APIs
- SHOULD update project README and CHANGELOG
- NEVER remove existing documentation
- ALWAYS preserve existing formatting style
- MUST check all public APIs are documented

## Documentation Templates

### User Documentation Template
```markdown
# [Feature Name]

## Overview
[What the feature does and why it exists]

## Prerequisites
[What user needs before using this feature]

## Getting Started

### Quick Start
[Simplest possible example to get started]

### Step-by-Step Guide
1. [First step with clear instructions]
2. [Second step]
3. [Continue...]

## Usage Examples

### Example 1: [Common Use Case]
[Description of scenario]

```[language]
[Code example]
```

[Expected result]

### Example 2: [Another Use Case]
[Description]

```[language]
[Code example]
```

## Configuration

### Available Options
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| [option] | [type] | [default] | [what it does] |

### Configuration Example
```[format]
[Example configuration]
```

## Troubleshooting

### Common Issues

#### [Issue 1]
**Problem**: [Description]
**Solution**: [How to fix]

#### [Issue 2]
**Problem**: [Description]
**Solution**: [How to fix]

## Related Features
- [Related feature 1]
- [Related feature 2]

## Additional Resources
- [Link to technical docs]
- [Link to API reference]
```

### Technical Documentation Template
```markdown
# [Feature Name] - Technical Documentation

## Architecture Overview
[High-level architecture description]

## Components

### [Component 1]
**Purpose**: [What it does]
**Location**: [File path]
**Dependencies**: [What it depends on]

**Public Interface**:
```[language]
[Key methods/functions]
```

**Usage**:
```[language]
[How to use it]
```

### [Component 2]
[Same structure]

## Data Flow
[Description of how data flows through the system]

```
[Diagram or flowchart in text/Mermaid format]
```

## API Reference

### [Function/Method Name]
```[language]
[Full signature]
```

**Parameters**:
- `param1` ([type]): [Description]
- `param2` ([type]): [Description]

**Returns**: [Return type and description]

**Throws**: [Exceptions that can be thrown]

**Example**:
```[language]
[Usage example]
```

## Configuration

### Environment Variables
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| [VAR] | [Yes/No] | [default] | [what it does] |

### Configuration Files
[List of config files and their purpose]

## Integration Guide

### Integrating with [System/Feature]
[Step-by-step integration instructions]

### Event Hooks
[Available hooks/events for extending functionality]

## Performance Considerations
- [Performance tip 1]
- [Performance tip 2]

## Security Considerations
- [Security concern 1]
- [Security concern 2]

## Testing
[Link to testing documentation]

## Troubleshooting
[Link to user documentation troubleshooting section]
```

### Testing Documentation Template
```markdown
# Testing: [Feature Name]

## Test Coverage Summary
- Unit Tests: [count] tests, [X]% coverage
- Integration Tests: [count] tests
- E2E Tests: [count] tests
- Manual Tests: [count] scenarios

## Running Tests

### All Tests
```bash
[Command to run all tests]
```

### Unit Tests Only
```bash
[Command to run unit tests]
```

### Integration Tests
```bash
[Command to run integration tests]
```

## Test Scenarios

### Scenario 1: [Happy Path]
**Given**: [Initial state]
**When**: [Action taken]
**Then**: [Expected result]

**Test**: [Test file and function name]

### Scenario 2: [Error Case]
**Given**: [Initial state]
**When**: [Action taken]
**Then**: [Expected error handling]

**Test**: [Test file and function name]

## Edge Cases Tested
1. [Edge case 1] - [How it's tested]
2. [Edge case 2] - [How it's tested]

## Known Limitations
- [Limitation 1]
- [Limitation 2]

## Manual Testing Checklist
- [ ] [Manual test step 1]
- [ ] [Manual test step 2]
- [ ] [Verify on different browsers/devices]

## Performance Benchmarks
[If applicable, performance test results]

## Test Data
[How to set up test data or where test fixtures are located]
```

## Examples

### Example 1: Document Current Active Story
```bash
INPUT:
/sdd:story-document

OUTPUT:
→ Finding active story...
→ Located: STORY-2025-003 in /docs/stories/development/
→ Analyzing implemented features...
→ Scanning codebase for TaskManager component...
→ Generating documentation...

✅ Documentation Generated
═══════════════════════════════════

Story: STORY-2025-003 - Task Management System

DOCUMENTATION CREATED:
✓ User Guide: /docs/features/task-management.md
✓ Technical: /docs/technical/task-management.md
✓ Testing: /docs/testing/task-management.md
✓ Examples: /docs/examples/task-management/

DOCUMENTATION UPDATED:
✓ README.md (added to feature list)
✓ CHANGELOG.md (documented for v1.2.0)

INLINE DOCUMENTATION:
✓ 12 functions documented with PHPDoc
✓ 3 Livewire components documented
✓ 5 complex logic sections commented

DOCUMENTATION DEBT:
- Screenshots recommended for user guide
- Consider adding sequence diagram for task lifecycle

Story Updated: Documentation section added

💡 NEXT STEPS:
1. Review generated documentation for accuracy
2. Add screenshots to user guide
3. /sdd:story-review STORY-2025-003    # Move to code review
4. Share docs with team for feedback
```

### Example 2: Document Specific Story
```bash
INPUT:
/sdd:story-document STORY-2025-005

OUTPUT:
→ Locating story: STORY-2025-005...
→ Found in /docs/stories/review/
→ Analyzing authentication implementation...
→ Generating documentation...

✅ Documentation Generated
═══════════════════════════════════

Story: STORY-2025-005 - User Authentication

DOCUMENTATION CREATED:
✓ User Guide: /docs/features/authentication.md
✓ Technical: /docs/technical/authentication.md
✓ Testing: /docs/testing/authentication.md
✓ Examples: /docs/examples/authentication/
✓ Migration Guide: /docs/migration-v2.md (breaking changes)

DOCUMENTATION UPDATED:
✓ README.md (security section)
✓ CHANGELOG.md (v2.0.0 breaking changes)
✓ docs/api.md (auth endpoints)

INLINE DOCUMENTATION:
✓ 8 controller methods documented
✓ 4 middleware classes documented
✓ Security notes added to sensitive functions

Story Updated: Documentation section added

💡 NEXT STEPS:
1. Review security documentation carefully
2. /sdd:story-review STORY-2025-005    # Continue review process
```

### Example 3: API Documentation
```bash
INPUT:
/sdd:story-document STORY-2025-007

OUTPUT:
→ Locating story: STORY-2025-007...
→ Found in /docs/stories/development/
→ Analyzing REST API implementation...
→ Extracting API endpoints and schemas...
→ Generating OpenAPI specification...

✅ Documentation Generated
═══════════════════════════════════

Story: STORY-2025-007 - REST API for Tasks

DOCUMENTATION CREATED:
✓ API Reference: /docs/api/tasks.md
✓ Technical: /docs/technical/api-tasks.md
✓ Testing: /docs/testing/api-tasks.md
✓ OpenAPI Spec: /docs/openapi/tasks.yaml
✓ Postman Collection: /docs/examples/tasks.postman.json

DOCUMENTATION UPDATED:
✓ docs/api.md (added tasks endpoints)
✓ README.md (API section)
✓ CHANGELOG.md (new API endpoints)

INLINE DOCUMENTATION:
✓ 6 API endpoints documented
✓ Request/response schemas defined
✓ Error responses documented

Story Updated: Documentation section added

💡 NEXT STEPS:
1. Test with Postman collection
2. Share OpenAPI spec with frontend team
3. /sdd:story-review STORY-2025-007
```

## Edge Cases

### Story Not Found
- DETECT invalid story ID
- SUGGEST using `/sdd:project-status` to list valid stories
- EXIT with helpful error message

### Story Has No Implementation Yet
- DETECT story in backlog with no code
- WARN that documentation requires implemented code
- SUGGEST using `/sdd:story-implement [id]` first
- EXIT gracefully

### No User-Facing Changes
- DETECT backend-only or infrastructure changes
- SKIP user documentation generation
- FOCUS on technical and testing documentation
- NOTE decision in story update

### Documentation Already Exists
- DETECT existing documentation files
- ASK user: Update existing or create new version?
- IF update: Merge new content with existing
- IF new: Create versioned documentation
- PRESERVE all existing content

### Complex API with Many Endpoints
- DETECT large API surface area
- GENERATE comprehensive API reference
- CREATE OpenAPI/Swagger specification
- ORGANIZE by resource/domain
- PROVIDE Postman/Insomnia collections

## Error Handling
- **Story not found**: Show available stories from `/sdd:project-status`
- **No implementation found**: Guide user to implement first
- **Permission errors**: Report specific file/directory issue
- **Documentation write errors**: Log error, continue with other docs

## Performance Considerations
- Documentation generation typically takes 10-30 seconds
- Inline documentation added via file editing (may take longer for many files)
- Show progress indicators for multi-file operations
- Cache story analysis for session

## Related Commands
- `/sdd:story-implement [id]` - Generate implementation first
- `/sdd:story-review [id]` - Move to code review after documentation
- `/sdd:story-test [id]` - Verify tests before documenting
- `/sdd:project-status` - Find stories to document

## Constraints
- ✅ MUST analyze story to understand implementation
- ✅ MUST generate docs appropriate to feature type
- ✅ MUST use framework-appropriate inline doc style
- ✅ MUST update story with documentation summary
- 📋 SHOULD create user docs for user-facing features
- 🔧 SHOULD include code examples for public APIs
- 💾 MUST preserve existing documentation content
- ⚠️ NEVER remove or replace existing docs without confirmation
- 🧪 MUST document all test scenarios covered