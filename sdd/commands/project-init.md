# /sdd:project-init

## Meta
- Version: 2.0
- Category: project-management
- Complexity: medium
- Purpose: Initialize story-driven development system with folder structure and template documents

## Definition
**Purpose**: Create the complete folder structure and template documents required for story-driven development workflow.

**Syntax**: `/sdd:project-init`

## Parameters
None

## INSTRUCTION: Initialize Project Structure

### INPUTS
- Project root directory (current working directory)
- User responses for technology stack and preferences (gathered interactively)

### PROCESS

#### Phase 1: Directory Structure Creation
1. **CREATE** `/project-context/` directory
   - Root directory for all project documentation
   - Contains technical specifications and standards

2. **CREATE** `/stories/` directory with subdirectories:
   - `/stories/development/` - Active implementation work
   - `/stories/review/` - Code review stage
   - `/stories/qa/` - Quality assurance testing
   - `/stories/completed/` - Finished and shipped stories
   - `/stories/backlog/` - Planned but not started
   - `/stories/templates/` - Story and documentation templates

3. **ADD** `.gitkeep` file to each empty directory:
   - ENSURES directories are tracked in git
   - PREVENTS empty directories from being ignored
   - FORMAT: Empty file named `.gitkeep`

#### Phase 2: Technical Stack Documentation
1. **ASK** user about complete technical stack:

   **Frontend**:
   - Framework: (React, Vue, Svelte, Angular, Laravel Blade, Next.js, Nuxt.js, etc.)
   - State management: (Redux, Zustand, Vuex, Pinia, Livewire, Alpine.js, etc.)
   - Language: (TypeScript, JavaScript, PHP templating, etc.)
   - Styling: (Tailwind CSS, CSS Modules, Styled Components, SCSS, etc.)
   - Build tool: (Vite, Webpack, Rollup, esbuild, Parcel, Laravel Mix, etc.)

   **Backend**:
   - Runtime: (Node.js, Deno, Bun, PHP, Python, Go, Java, .NET, etc.)
   - Framework: (Express, Fastify, Laravel, Symfony, Django, FastAPI, etc.)
   - Language: (TypeScript, JavaScript, PHP, Python, Go, Java, C#, etc.)

   **Database**:
   - Primary database: (PostgreSQL, MySQL, MongoDB, SQLite, Redis, etc.)
   - ORM/Query builder: (Prisma, TypeORM, Eloquent, Django ORM, etc.)
   - Caching: (Redis, Memcached, database cache, etc.)

   **Testing**:
   - Unit testing: (Jest, Vitest, Pest, PHPUnit, Pytest, JUnit, etc.)
   - Integration testing: (Same as unit or separate framework)
   - Browser/E2E testing: (Playwright, Cypress, Selenium, Laravel Dusk, etc.)
   - Test runner commands: (npm test, vendor/bin/pest, pytest, etc.)

   **Development Tools**:
   - Package manager: (npm, yarn, pnpm, composer, pip, go mod, etc.)
   - Code formatting: (Prettier, ESLint, PHP CS Fixer, Black, etc.)
   - Linting: (ESLint, PHPStan, pylint, golangci-lint, etc.)
   - Git hooks: (husky, pre-commit, etc.)

   **Deployment & Hosting**:
   - Hosting platform: (Vercel, Netlify, AWS, Railway, Heroku, etc.)
   - Container platform: (Docker, Podman, none, etc.)
   - CI/CD: (GitHub Actions, GitLab CI, Jenkins, none, etc.)

   **Key Libraries**:
   - Authentication: (Auth0, Firebase Auth, Laravel Sanctum, etc.)
   - HTTP client: (Axios, Fetch, Guzzle, Requests, etc.)
   - Validation: (Zod, Joi, Laravel Validation, Pydantic, etc.)
   - Other important libraries: [User provides list]

2. **CREATE** `/project-context/technical-stack.md`:
   - POPULATE with user's technology choices
   - INCLUDE version numbers if available
   - ADD links to documentation
   - NOTE any specific configuration requirements

#### Phase 3: Development Process Documentation
1. **CREATE** `/project-context/development-process.md`:
   - DEFINE three-stage workflow (Development → Review → QA)
   - SPECIFY entry/exit criteria for each stage
   - DOCUMENT required activities per stage
   - ESTABLISH quality gates and checkpoints
   - OUTLINE story movement rules

2. **INCLUDE** sections:
   - Stage Definitions
   - Stage Requirements
   - Testing Strategy
   - Review Process
   - Quality Gates

#### Phase 4: Coding Standards Documentation
1. **ASK** user about comprehensive coding standards:
   - Naming conventions (camelCase, snake_case, PascalCase patterns)
   - Function/method organization (length limits, complexity)
   - Class/module structure (single responsibility patterns)
   - Comment and documentation standards
   - Framework-specific patterns
   - File organization preferences
   - Testing standards
   - Quality requirements
   - Git workflow conventions

2. **CREATE** `/project-context/coding-standards.md`:
   - DOCUMENT language-specific standards
   - DEFINE framework-specific patterns
   - SPECIFY file organization rules
   - ESTABLISH testing standards
   - SET quality requirements
   - OUTLINE git workflow

#### Phase 5: Project Glossary
1. **CREATE** `/project-context/project-glossary.md`:
   - PROVIDE template for domain-specific terminology
   - INCLUDE sections for:
     * Domain Terms (business-specific vocabulary)
     * Technical Terms (framework-specific terminology)
     * Process Terms (development workflow vocabulary)
   - ENCOURAGE user to populate over time

#### Phase 6: Project Brief Template
1. **CREATE** `/project-context/project-brief.md`:
   - PROVIDE comprehensive project overview template
   - INCLUDE sections:
     * Project Overview (name, description, objectives)
     * Timeline (start date, target completion, milestones)
     * Story Planning (total stories, prioritization)
     * Success Metrics
   - PROMPT user to fill with actual project details

#### Phase 7: Story Template Creation
1. **CREATE** `/stories/templates/story-template.md`:
   - COMPREHENSIVE story template with sections:
     * Story Header (ID, title, status, priority)
     * Description and Context
     * Success Criteria and Acceptance Tests
     * Technical Implementation Notes
     * Implementation Checklist
     * Test Cases (unit, integration, browser)
     * Rollback Plans
     * Lessons Learned
   - REFERENCE project's technical stack from `technical-stack.md`
   - ALIGN with coding standards from `coding-standards.md`
   - MATCH process requirements from `development-process.md`

#### Phase 8: Completion Summary and Next Steps
1. **DISPLAY** creation summary:
   ```
   ✅ Project Structure Initialized
   ═══════════════════════════════════

   📁 Directories Created:
   - /project-context/
   - /stories/development/
   - /stories/review/
   - /stories/qa/
   - /stories/completed/
   - /stories/backlog/
   - /stories/templates/

   📄 Documents Created:
   - /project-context/technical-stack.md
   - /project-context/development-process.md
   - /project-context/coding-standards.md
   - /project-context/project-glossary.md
   - /project-context/project-brief.md
   - /stories/templates/story-template.md

   🔧 Configuration Status:
   - Technical stack: Configured with [user's stack]
   - Coding standards: Customized
   - Development process: Defined
   ```

2. **SUGGEST** next steps:
   - Fill out `project-brief.md` with actual project details
   - Customize `coding-standards.md` with team-specific patterns
   - Update `development-process.md` with workflow preferences
   - Populate `project-glossary.md` with domain terms
   - Create first story: `/sdd:story-new`
   - Begin development: `/sdd:story-start`

3. **PROVIDE** quick start guide:
   - How to create a story
   - How to move story through workflow
   - How to check project status
   - Where to find documentation

### OUTPUTS
**Directories**:
- `/project-context/` - Project documentation root
- `/stories/development/` - Active stories
- `/stories/review/` - Stories in review
- `/stories/qa/` - Stories in QA
- `/stories/completed/` - Finished stories
- `/stories/backlog/` - Planned stories
- `/stories/templates/` - Templates

**Files**:
- `/project-context/technical-stack.md` - Technology choices
- `/project-context/development-process.md` - Workflow definitions
- `/project-context/coding-standards.md` - Quality standards
- `/project-context/project-glossary.md` - Terminology reference
- `/project-context/project-brief.md` - Project overview
- `/stories/templates/story-template.md` - Story template

### RULES
- MUST create all directories before creating files
- MUST add `.gitkeep` to all empty directories
- MUST gather user input for technology stack
- MUST customize templates based on user's stack
- SHOULD reference actual technology choices in templates
- NEVER overwrite existing files without user confirmation
- ALWAYS provide next steps after initialization

## File Structure

### Directory Hierarchy
```
/project-context/
├── technical-stack.md              # Technology choices and versions
├── development-process.md           # Workflow and quality gates
├── coding-standards.md              # Code quality standards
├── project-glossary.md              # Domain terminology
└── project-brief.md                 # Project overview and goals

/stories/
├── /development/                    # Active implementation
│   └── .gitkeep
├── /review/                         # Code review stage
│   └── .gitkeep
├── /qa/                            # Quality assurance
│   └── .gitkeep
├── /completed/                      # Finished stories
│   └── .gitkeep
├── /backlog/                        # Planned stories
│   └── .gitkeep
└── /templates/                      # Templates
    ├── .gitkeep
    └── story-template.md           # Story template
```

## Examples

### Example 1: First-Time Setup
```bash
INPUT:
/sdd:project-init

INTERACTION:
→ Asks about frontend framework
→ Asks about backend framework
→ Asks about database
→ Asks about testing framework
→ Asks about deployment platform

OUTPUT:
✅ Project Structure Initialized
═══════════════════════════════════

📁 Directories Created:
- /project-context/
- /stories/development/
- /stories/review/
- /stories/qa/
- /stories/completed/
- /stories/backlog/
- /stories/templates/

📄 Documents Created:
- /project-context/technical-stack.md (Laravel TALL stack)
- /project-context/development-process.md
- /project-context/coding-standards.md
- /project-context/project-glossary.md
- /project-context/project-brief.md
- /stories/templates/story-template.md

🔧 Configuration Status:
- Technical stack: Laravel 12, Livewire 3, Alpine.js, Tailwind CSS
- Testing: Pest PHP, Playwright
- Deployment: Laravel Herd (local), Forge (production)

💡 NEXT STEPS:
1. Fill out /project-context/project-brief.md with your project details
2. Run /sdd:project-brief to create comprehensive project plan
3. Create your first story with /sdd:story-new
4. Begin development with /sdd:story-start

📚 QUICK START:
- Create story: /sdd:story-new
- View status: /sdd:project-status
- Start work: /sdd:story-start [id]
- Documentation: See /project-context/ directory
```

### Example 2: Already Initialized
```bash
INPUT:
/sdd:project-init

OUTPUT:
⚠️  Project Already Initialized

The following directories already exist:
- /project-context/
- /stories/

Would you like to:
1. Skip initialization (directories exist)
2. Add missing directories/files only
3. Recreate all templates (keeps existing config)
4. Abort

Choose an option [1-4]:
```

### Example 3: Partial Initialization
```bash
INPUT:
/sdd:project-init

DETECTION:
→ Found /project-context/ but missing /stories/

OUTPUT:
ℹ️  Partial Project Structure Detected

Found: /project-context/
Missing: /stories/ and subdirectories

Creating missing directories...

✅ Completed Missing Structure
═══════════════════════════════════

📁 Created:
- /stories/development/
- /stories/review/
- /stories/qa/
- /stories/completed/
- /stories/backlog/
- /stories/templates/

Existing configuration preserved.

💡 NEXT STEPS:
- Create first story: /sdd:story-new
- View project status: /sdd:project-status
```

## Edge Cases

### Existing Project Structure
- DETECT existing directories and files
- OFFER options:
  * Skip initialization completely
  * Add missing directories/files only
  * Recreate templates (preserve config)
  * Abort operation
- NEVER overwrite without confirmation

### Partial Initialization
- IDENTIFY which components exist
- CREATE only missing components
- PRESERVE existing configuration
- LOG what was added vs what existed

### Permission Issues
- CHECK write permissions before creating
- REPORT specific permission errors
- SUGGEST running with appropriate permissions
- PROVIDE manual creation instructions if needed

### Git Not Initialized
- DETECT if .git directory exists
- SUGGEST initializing git if missing
- NOTE that .gitkeep files require git
- CONTINUE with initialization regardless

## Error Handling
- **Permission denied**: Report specific directory/file, suggest fixes
- **Disk space full**: Report error, suggest cleanup
- **Invalid path**: Verify working directory is project root
- **User cancels**: Clean up partial creation, exit gracefully

## Performance Considerations
- Directory creation is fast (< 100ms typically)
- File creation with templates (< 500ms typically)
- Interactive prompts allow user to control pace
- No heavy processing or external dependencies

## Security Considerations
- Verify write permissions before operations
- Sanitize all file paths
- Don't create files outside project root
- Don't overwrite without explicit confirmation

## Related Commands
- `/sdd:project-brief` - Create comprehensive project plan after init
- `/sdd:story-new` - Create first story after initialization
- `/sdd:project-status` - View current project state
- `/sdd:project-context-update` - Update context documents later

## Constraints
- ⚠️ MUST NOT overwrite existing files without confirmation
- ✅ MUST create all directories before files
- ✅ MUST add `.gitkeep` to empty directories
- 📋 MUST gather user input for technology stack
- 🔧 SHOULD customize templates based on stack
- 💾 MUST verify write permissions
- ⚡ SHOULD complete initialization in < 5 seconds (excluding user input)
