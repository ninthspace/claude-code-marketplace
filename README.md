# Story-Driven Development Marketplace

A Claude Code plugin marketplace providing comprehensive tools for story-driven agile development workflows.

## Overview

This marketplace contains a plugin that enable complete story-driven development workflows, from ideation through production deployment. All tools are designed to work seamlessly with Claude Code.

## Installation

### Install from Marketplace (inside Claude Code)

```bash
# Install the marketplace
/plugin marketplace add ninthspace/claude-code-marketplace

# Then install this plugin
/plugin install sdd@claude-code-marketplace
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
```

[View full documentation](./sdd/README.md)

## Using the Plugin

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

## Removing the Plugin (when in Claude Code)

```bash
# Uninstall this plugin
/plugin uninstall sdd@claude-code-marketplace

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
