# /sdd:story-start

## Meta
- Version: 2.0
- Category: workflow
- Complexity: comprehensive
- Purpose: Initialize story development with branch creation, context loading, and boilerplate generation

## Definition
**Purpose**: Start development on a specified story by creating a feature branch, loading project context, optionally generating boilerplate, and preparing the development environment.

**Syntax**: `/sdd:story-start <story_id> [--boilerplate]`

## Parameters
| Parameter | Type | Required | Default | Description | Validation |
|-----------|------|----------|---------|-------------|------------|
| story_id | string | Yes | - | Story identifier (e.g., "STORY-001") | Must match pattern STORY-\d{3,} |
| --boilerplate | flag | No | false | Generate initial boilerplate files | Boolean flag |

## Behavior
```
INSTRUCTION: Initialize story development environment with context-aware setup

INPUTS:
- story_id: Story identifier from /stories/development/ or /stories/backlog/
- --boilerplate: Optional flag to generate framework-specific starter files

PROCESS:

Phase 1: Project Context Loading
1. CHECK if /project-context/ directory exists
2. IF missing:
   - SUGGEST running /sdd:project-init first
   - HALT execution
3. ELSE:
   - LOAD /project-context/technical-stack.md
   - LOAD /project-context/coding-standards.md
   - LOAD /project-context/development-process.md
4. PARSE technical stack to identify:
   - ACTUAL frontend framework (React/Vue/Svelte/Laravel Blade/etc.)
   - ACTUAL backend framework and runtime
   - ACTUAL testing framework and tools
   - ACTUAL build tools and package manager
   - ACTUAL database system

Phase 2: Story File Discovery
1. SEARCH for story file in order:
   - CHECK /stories/development/[story_id].md
   - IF NOT FOUND: CHECK /stories/backlog/[story_id].md
   - IF NOT FOUND: OFFER to create with /sdd:story-new
2. READ story file and extract:
   - Branch name (or generate from story ID)
   - Success criteria
   - Technical requirements
   - Implementation approach

Phase 3: Git Branch Setup
1. CHECK if feature branch exists:
   - RUN: git branch --list [branch-name]
2. IF branch exists:
   - SWITCH to existing branch
   - SHOW: "Switched to existing branch: [branch-name]"
3. ELSE:
   - CREATE new branch from main/master
   - CHECKOUT new branch
   - SHOW: "Created and switched to: [branch-name]"
4. DISPLAY current branch status:
   - Branch name
   - Last commit
   - Uncommitted changes (if any)

Phase 4: Boilerplate Generation (IF --boilerplate flag present)
1. IDENTIFY framework from technical-stack.md
2. GENERATE framework-specific files:

   IF React:
   - Component files (.jsx/.tsx)
   - Hook files (use[Feature].js)
   - Style files (CSS/SCSS/Tailwind)
   - Test files (.test.jsx/.spec.tsx)

   IF Vue:
   - Component files (.vue)
   - Composable files (use[Feature].js)
   - Style files (scoped styles)
   - Test files (.spec.js)

   IF Laravel + Livewire:
   - Livewire component classes (app/Livewire/)
   - Blade view files (resources/views/livewire/)
   - Migration files (database/migrations/)
   - Test files (tests/Feature/, tests/Browser/)

   IF Django:
   - View files (views.py)
   - Model files (models.py)
   - Template files (templates/)
   - Form files (forms.py)
   - Test files (tests/)

   IF Express:
   - Route files (routes/)
   - Controller files (controllers/)
   - Middleware files (middleware/)
   - Test files (.test.js)

   IF Next.js:
   - Page/route files (pages/ or app/)
   - API route files (api/)
   - Component files
   - Test files

3. APPLY coding standards from coding-standards.md:
   - Follow DISCOVERED file naming conventions
   - Apply DISCOVERED directory structure
   - Use DISCOVERED code formatting
   - Include DISCOVERED file headers/comments

4. GENERATE test structure for DISCOVERED testing framework:
   - Jest/Vitest: .test.js/.spec.js with describe/it blocks
   - Pest: .php test files with it() syntax
   - Pytest: test_*.py with test_ functions
   - JUnit: *Test.java with @Test annotations

5. SET UP development environment:
   - Install dependencies using DISCOVERED package manager
   - Run initial build using DISCOVERED build tools
   - Verify setup with basic test

Phase 5: Story File Update
1. UPDATE story file with:
   - Progress log entry: "Development started - [timestamp]"
   - Status: "development" (if was "backlog")
   - Branch name: [branch-name]
   - Tech stack used: [list of technologies from context]
2. IF boilerplate generated:
   - LIST generated files in progress log
   - NOTE initial setup completion

Phase 6: Next Steps Display
1. SHOW next steps in numbered format:
   1. Review success criteria
   2. Use /sdd:story-implement to generate code for DISCOVERED stack
   3. Use /sdd:story-save to commit progress
   4. Use /sdd:story-review when ready
2. MENTION relevant development commands for DISCOVERED stack:
   - npm run dev / composer dev / python manage.py runserver / etc.
   - Test commands for DISCOVERED framework
   - Linting commands for DISCOVERED tools

OUTPUT FORMAT:
```
✅ STORY DEVELOPMENT STARTED
============================
Story: [story_id] - [Title]
Branch: [branch-name]
Stack: [DISCOVERED framework + technologies]

Project Context Loaded:
- Frontend: [DISCOVERED frontend framework]
- Backend: [DISCOVERED backend framework]
- Testing: [DISCOVERED testing tools]
- Build: [DISCOVERED build system]

[IF boilerplate generated:]
Generated Files:
- [list of created files with paths]

Next Steps:
1. Review success criteria
2. /sdd:story-implement to generate implementation
3. /sdd:story-save to commit progress
4. /sdd:story-review when ready for review

Development Commands:
- Server: [DISCOVERED dev server command]
- Tests: [DISCOVERED test command]
- Lint: [DISCOVERED lint command]
```

RULES:
- MUST load project context before proceeding
- MUST adapt all generated code to DISCOVERED stack
- NEVER assume framework - ALWAYS read technical-stack.md
- MUST create branch if it doesn't exist
- MUST update story file with start timestamp
- SHOULD generate boilerplate only if --boilerplate flag present
- MUST follow DISCOVERED coding standards exactly
```

## Examples

### Example 1: Start Story Without Boilerplate
```bash
INPUT:
/sdd:story-start STORY-AUTH-001

PROCESS:
→ Loading project context from /project-context/
→ Technical stack: Laravel + Livewire + Tailwind + Pest
→ Found story: /stories/backlog/STORY-AUTH-001.md
→ Creating branch: feature/auth-001-login-form
→ Switched to new branch

OUTPUT:
✅ STORY DEVELOPMENT STARTED
============================
Story: STORY-AUTH-001 - Implement Login Form
Branch: feature/auth-001-login-form
Stack: Laravel 12 + Livewire 3 + Tailwind CSS 4 + Pest 4

Project Context Loaded:
- Frontend: Laravel Blade + Livewire + Alpine.js
- Backend: Laravel 12 (PHP 8.4)
- Testing: Pest (Unit, Feature, Browser)
- Build: Vite 7

Next Steps:
1. Review success criteria in story file
2. /sdd:story-implement to generate Livewire component
3. /sdd:story-save to commit progress
4. /sdd:story-review when ready for code review

Development Commands:
- Server: composer dev (or php artisan serve)
- Tests: vendor/bin/pest
- Lint: vendor/bin/pint
```

### Example 2: Start Story With Boilerplate
```bash
INPUT:
/sdd:story-start STORY-PROFILE-002 --boilerplate

PROCESS:
→ Loading project context
→ Technical stack: React + TypeScript + Vite + Jest
→ Found story: /stories/development/STORY-PROFILE-002.md
→ Branch already exists: feature/profile-002-settings
→ Switched to existing branch
→ Generating React boilerplate...

OUTPUT:
✅ STORY DEVELOPMENT STARTED
============================
Story: STORY-PROFILE-002 - User Profile Settings
Branch: feature/profile-002-settings (existing)
Stack: React 18 + TypeScript + Vite + Jest

Project Context Loaded:
- Frontend: React 18 (TypeScript)
- State: Redux Toolkit
- Testing: Jest + React Testing Library
- Build: Vite 5

Generated Files:
- src/components/ProfileSettings.tsx
- src/components/ProfileSettings.module.css
- src/hooks/useProfileSettings.ts
- src/tests/ProfileSettings.test.tsx

Next Steps:
1. Review success criteria in story file
2. /sdd:story-implement to add implementation logic
3. /sdd:story-save to commit boilerplate
4. /sdd:story-review when feature complete

Development Commands:
- Server: npm run dev
- Tests: npm test
- Lint: npm run lint
```

### Example 3: Story Not Found
```bash
INPUT:
/sdd:story-start STORY-UNKNOWN-999

PROCESS:
→ Loading project context
→ Searching for STORY-UNKNOWN-999
→ Not found in /stories/development/
→ Not found in /stories/backlog/
→ Story does not exist

OUTPUT:
❌ Story Not Found
==================
Story ID: STORY-UNKNOWN-999

The story file was not found in:
- /stories/development/
- /stories/backlog/

Would you like to create this story?
→ Use: /sdd:story-new "Story title and description"
```

### Example 4: Missing Project Context
```bash
INPUT:
/sdd:story-start STORY-API-003

PROCESS:
→ Checking for /project-context/ directory
→ Directory not found

OUTPUT:
⚠️ Project Context Missing
==========================

Cannot start story without project context.

The /project-context/ directory does not exist.
This directory defines your technical stack and coding standards.

Please run: /sdd:project-init

This will create:
- /project-context/technical-stack.md
- /project-context/coding-standards.md
- /project-context/development-process.md

After initialization, run /sdd:story-start again.
```

## Edge Cases

### Story Already in Development
```
IF story found in /stories/development/:
- SWITCH to story branch
- SHOW: "Story already in development"
- DISPLAY: Current progress
- SUGGEST: /sdd:story-continue to resume
```

### Branch Exists But Diverged
```
IF branch exists AND has diverged from main:
- SHOW: Warning about diverged branch
- OFFER options:
  1. Continue on current branch
  2. Rebase on main
  3. Create new branch with suffix (-v2)
```

### Boilerplate with Existing Files
```
IF --boilerplate flag AND files already exist:
- CHECK for conflicts
- SHOW: List of existing files
- ASK: Overwrite, skip, or merge?
- PROCEED based on user choice
```

## Error Handling
- **Story ID missing**: Return "Error: Story ID required. Usage: /sdd:story-start <story_id>"
- **Invalid story ID format**: Return "Error: Invalid story ID format. Expected: STORY-XXX-NNN"
- **Project context missing**: Halt and suggest /sdd:project-init
- **Context files corrupted**: Show error and suggest manual review
- **Git branch error**: Show git error and suggest manual resolution
- **File generation error**: Show which files failed and suggest manual creation

## Performance Considerations
- Load project context files only once at start
- Cache parsed technical stack for session
- Generate boilerplate asynchronously to avoid blocking
- Skip dependency installation if package.json/composer.json unchanged

## Related Commands
- `/sdd:story-new` - Create a new story before starting
- `/sdd:story-continue` - Resume work on existing story
- `/sdd:story-implement` - Generate implementation code
- `/sdd:story-save` - Commit progress
- `/sdd:project-init` - Initialize project context

## Notes
- Project context is mandatory for story development
- Branch naming follows convention: feature/[story-id-kebab-case]
- Boilerplate generation is framework-aware and respects coding standards
- All generated code must match the DISCOVERED technical stack
- Never assume technology choices - always read and adapt
