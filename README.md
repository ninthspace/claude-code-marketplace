# Claude Code Marketplace

A Claude Code plugin marketplace providing development tools and productivity utilities.

## Overview

This marketplace contains plugins for story-driven development, facilitated planning, note searching, and PHP code intelligence. All tools are designed to work seamlessly with Claude Code.

## Installation

### Install from Marketplace (inside Claude Code)

```bash
# Install the marketplace
/plugin marketplace add ninthspace/claude-code-marketplace

# Install individual plugins
/plugin install sdd@claude-code-marketplace
/plugin install noteplan@claude-code-marketplace
/plugin install php-lsp@claude-code-marketplace
/plugin install cpm@claude-code-marketplace
```

## Available Plugins

### Story-Driven Development (v3.1.0)

**30+ commands for complete agile development workflow**

A comprehensive plugin providing:
- Project setup and initialization
- Story management and tracking
- Development workflow automation
- Code review and quality checks
- Automated testing and QA
- Deployment and rollback
- Metrics and analysis
- Daily workflow helpers

**Key Features:**
- Context-aware commands that adapt to your tech stack
- Git integration for version control
- Automated testing support
- Browser testing (Playwright/Pest)
- Progressive enhancement with project context
- Works immediately, no configuration required

**Tech Stack Support:**
- Laravel/TALL stack
- React/Next.js
- Vue.js
- Node.js/Express
- Python/Django
- Ruby on Rails
- Any tech stack with adaptation

**Quick Start:**
```bash
# Automated workflow (single command for entire lifecycle)
/sdd:story-flow "Add user authentication"

# Or use individual commands for more control
/sdd:story-new "Add user authentication"
/sdd:story-start STORY-2025-001
/sdd:story-implement STORY-2025-001
/sdd:story-save "Implement user authentication"
/sdd:story-review STORY-2025-001
/sdd:story-qa STORY-2025-001
/sdd:story-validate STORY-2025-001
/sdd:story-ship STORY-2025-001
/sdd:story-complete STORY-2025-001
```

[View full documentation](./sdd/README.md)

---

### NotePlan Search (v1.0.0)

**Search and query NotePlan notes from Claude Code**

A skill for searching NotePlan content across:
- **Notes folder** - Standalone notes
- **Calendar folder** - Daily/weekly/monthly notes
- **Spaces** - Team/shared notes (SQLite database)
- **iCloud** - If syncing via iCloud Drive

Results are sorted by most recently modified first.

**Quick Start:**
```bash
# Search for a term
/noteplan coffee

# List all Spaces notes
/noteplan --list --spaces

# Fetch full note by ID
/noteplan --get UUID

# Search with date filters
/noteplan meeting --after 2025-01-01

# Natural language queries
/noteplan find me everything about project planning
```

**Key Features:**
- Full-text search across all NotePlan sources
- Date filtering (--after, --before)
- JSON output for AI tools
- Direct noteplan:// URLs to open notes in the app
- Excludes @Templates, @Trash, @Archive by default (use --all to include)

**Requirements:**
- macOS with NotePlan 3 installed
- Python 3

[View full documentation](./noteplan/SKILL.md)

---

### PHP LSP (v1.0.0)

**PHP semantic code intelligence for Claude Code**

Adds 24 LSP tools to Claude Code for PHP files via [intelephense](https://intelephense.com/) and the [lsp-mcp-server](https://github.com/ProfessioneIT/lsp-mcp-server) bridge.

**Capabilities:**
- Go-to-definition, find references, find implementations
- Hover info (type signatures, documentation)
- Code completion and signature help
- Diagnostics (errors, warnings) per file and project-wide
- Safe rename across entire codebase
- Code actions (quick fixes, refactoring)
- Call hierarchy and type hierarchy
- File analysis (imports, exports, related files)
- Document formatting

**Quick Start:**
```bash
# One-time setup (installs intelephense + lsp-mcp-server, configures project)
/php-lsp:setup

# Restart Claude Code — LSP auto-starts on first use

# Check everything is working
/php-lsp:status
```

**Requirements:**
- Node.js >= 18
- Git

[View full documentation](./php-lsp/README.md)

---

### Claude Planning Method (v1.0.0)

**Facilitated planning skills for Claude Code**

Structured discovery, specification, and work breakdown through guided conversation. Helps you understand problems before jumping to solutions — inspired by the BMAD-METHOD.

**Three skills forming a pipeline:**

| Skill | Purpose | Output |
|-------|---------|--------|
| `/cpm:discover` | Facilitated problem discovery | `docs/plans/{slug}.md` |
| `/cpm:spec` | Requirements & architecture specification | `docs/specifications/{slug}.md` |
| `/cpm:stories` | Work breakdown into tracked tasks | `docs/stories/{slug}.md` + Claude Code tasks |

**Quick Start:**
```bash
# Full pipeline: discover → spec → stories
/cpm:discover build a customer portal for our booking system
/cpm:spec docs/plans/customer-portal.md
/cpm:stories docs/specifications/customer-portal.md

# Or jump to any step independently
/cpm:spec I need a REST API for inventory management
/cpm:stories docs/specifications/inventory-api.md
```

**Key Features:**
- Facilitated conversations, not forms — builds on your answers
- One topic at a time with user-gated progression
- Scales depth to complexity — skips phases that don't add value
- MoSCoW prioritisation for requirements
- Architecture decisions with rationale and alternatives
- Right-sized stories with acceptance criteria and dependencies

[View full documentation](./cpm/README.md)

---

## Using the SDD Plugin

### Complete Workflow

#### Getting Started: Project Setup (Optional but Recommended)

Before creating stories, establish your project foundation:

1. **Initialize Project**: `/sdd:project-init`
   - Creates directory structure (`/docs/project-context/`, `/docs/stories/`)
   - Sets up context documents (technical stack, coding standards, development process)
   - Customizes templates based on your tech stack

2. **Create Project Brief**: `/sdd:project-brief [title]`
   - Defines project objectives and scope
   - Breaks down features into multiple related stories
   - Documents story dependencies and implementation order
   - Provides comprehensive story definitions with acceptance criteria

**Note**: These setup commands are optional. You can jump straight to story creation with smart defaults, but project setup provides better context-aware behavior.

#### Iterative Phase Planning (Optional)

For ongoing projects with multiple development cycles:

**Plan Development Phases**: `/sdd:project-phase [phase_name]`
- Interactive planning for next development phase
- Gathers user input on desired features and improvements
- Analyzes completed work and current project state
- Creates phase-specific documentation and story queues
- Organizes features by iteration, extension, and foundation categories
- Requires user approval before creating documentation

**When to use phases:**
- Planning next iteration after completing initial stories
- Organizing multiple related features into cohesive releases
- Managing long-term projects with distinct development cycles
- Coordinating feature rollout with dependencies

#### Story Development Workflow (9 Steps)

1. **Create Story**: Define what you're building
2. **Start Development**: Create branch and setup
3. **Implement**: Generate code with AI assistance
4. **Save**: Commit with formatted messages
5. **Review**: Quality checks and refactoring
6. **QA**: Automated testing
7. **Validate**: Final checks before shipping
8. **Ship**: Deploy to production
9. **Complete**: Archive story with retrospective and learnings

### Workflow Automation with /sdd:story-flow

The `/sdd:story-flow` command automates the entire story lifecycle, executing all 9 steps sequentially with a single command. This provides:

- **Time Savings**: Run the complete workflow (new → start → implement → review → qa → validate → save → ship → complete) with one command
- **Complete Documentation**: Automatically captures retrospective, lessons learned, and metrics after deployment
- **Consistency**: Ensures all quality gates are executed in the correct order
- **Flexibility**: Use `--start-at` and `--stop-at` to run specific portions of the workflow
- **Control**: Interactive mode (default) pauses between steps; use `--auto` flag for full automation
- **Resume Capability**: Resume from any step if interrupted or after fixing issues
- **Error Handling**: Automatically halts on test or validation failures with clear recovery options

**Examples:**
```bash
# Full automated workflow from new story
/sdd:story-flow "Add user authentication"

# Resume existing story from QA step in auto mode
/sdd:story-flow STORY-2025-001 --start-at=qa --auto

# Partial workflow (stop before shipping)
/sdd:story-flow "Fix responsive layout" --stop-at=review
```

### Command Categories

- **📦 Project Setup** - Initialize projects, create project briefs, and manage context (run first)
- **🔄 Phase Planning** - Plan iterative development phases with user-driven requirements (optional)
- **📝 Story Management** - Create, track, and manage individual stories
- **⚡ Workflow Automation** - Automate complete lifecycle with `/sdd:story-flow`
- **🛠️ Development** - Start, implement, and save work
- **🔍 Review** - Quality checks and refactoring
- **✅ QA & Testing** - Automated testing and validation
- **🚀 Shipping** - Deploy features and handle rollbacks
- **📊 Analysis** - Metrics, patterns, and technical debt
- **📅 Daily Workflow** - Daily standup and planning

## Requirements

- **Claude Code CLI** - Required for the plugin
- **Git** - Required for version control commands
- **Test Framework** - Required for QA commands (project-specific)

## Project Context

The plugin uses a `/docs/project-context/` directory for context-aware behavior. You can create this automatically or manually:

**Automatic Setup (Recommended):**
```bash
# Initialize project structure with interactive setup
/sdd:project-init

# Create comprehensive project brief
/sdd:project-brief [title]
```

**Files Created:**
- `technical-stack.md` - Technology choices and versions
- `coding-standards.md` - Code quality standards
- `development-process.md` - Workflow stages and quality gates
- `project-glossary.md` - Domain terminology
- `project-brief.md` - Project overview and story breakdown
- `story-relationships.md` - Story dependencies (if applicable)
- `phases/[phase_name]/` - Phase-specific documentation (created by `/sdd:project-phase`)
  - `phase-brief.md` - Phase goals, features, and timeline
  - `story-queue.md` - Prioritized story backlog for the phase

The plugin automatically reads these files and adapts its behavior to match your project's needs.

## Key Principles

- **No Prerequisites**: Commands work immediately with smart defaults
- **Tech Stack Agnostic**: Adapts to your actual technology choices
- **Context-Aware**: Reads project configuration when available
- **Independent**: Each command works standalone
- **Full Lifecycle**: From idea to production deployment

## Removing Plugins (when in Claude Code)

```bash
# Uninstall individual plugins
/plugin uninstall sdd@claude-code-marketplace
/plugin uninstall noteplan@claude-code-marketplace
/plugin uninstall php-lsp@claude-code-marketplace
/plugin uninstall cpm@claude-code-marketplace

# Remove the entire marketplace
/plugin marketplace remove ninthspace-marketplace
```

## License

MIT - See [LICENSE](LICENSE) for details

## Contributing

Contributions welcome! Please:
1. Follow the existing plugin structure
2. Include comprehensive documentation
3. Add tests where applicable
4. Update the marketplace manifest
5. Submit a pull request

## Support

For issues or questions:
- Open an issue on GitHub
- Check plugin-specific documentation
- Review the [Claude Code plugin docs](https://docs.claude.com/en/docs/claude-code/plugins)

## Changelog

See individual plugin CHANGELOG.md files for version history.

## Author

Chris Aves

## Links

- [Plugin Documentation](https://docs.claude.com/en/docs/claude-code/plugins)
- [Marketplace Documentation](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces)
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
