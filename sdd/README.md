# Story-Driven Development Plugin

A comprehensive Claude Code plugin providing 30+ commands for story-driven agile development, from ideation through production deployment.

All commands are implemented as prompts that Claude Code executes directly. No additional setup or programming languages required.

## Quick Start

After installation, try these commands:

```bash
# Create your first story
/story-new "Add user authentication"

# Start development
/story-start STORY-2024-001

# Generate implementation
/story-implement STORY-2024-001

# Commit your changes
/story-save "Implement user authentication"

# Run quality checks
/story-review STORY-2024-001

# Run automated tests
/story-qa STORY-2024-001

# Validate before shipping
/story-validate STORY-2024-001

# Ship to production
/story-ship STORY-2024-001
```

## Core Workflow

**Essential Commands (Linear Process):**
```
/story-new → /story-start → /story-implement → /story-save →
/story-review → /story-qa → /story-validate → /story-ship
```

**Note:** `/story-save` is essential for git commits but can also be used anytime during development

## What's Included

This plugin adds a complete story-driven development workflow with:

- **Project Setup Commands** - Initialize projects and manage context
- **Story Management** - Create, track, and manage development stories
- **Development Workflow** - Start, implement, and save work with git integration
- **Code Review** - Automated quality checks and refactoring
- **QA & Testing** - Automated test execution and validation
- **Deployment** - Ship features and handle rollbacks
- **Analysis & Metrics** - Track velocity, patterns, and technical debt
- **Daily Workflow** - Commands for daily standup and planning

## Command Categories

### 📦 Project Setup
- `/project-init` - Create folder structure and context documents
- `/project-context-update` - Update tech stack, standards, or process docs
- `/project-brief [title]` - Create project brief and break into stories
- `/project-status` - Show all projects and completion status
- `/project-stories [id]` - List stories for a project with dependencies

### 📝 Story Management
- `/story-new [title]` - **CORE:** Create new story with template
- `/story-status` - Show all stories and their stages
- `/story-continue` - Resume last worked on story

### 🛠️ Development
- `/story-start [id]` - **CORE:** Start development, create branch
- `/story-implement [id]` - **CORE:** Generate code based on requirements
- `/story-save [message]` - **CORE:** Commit with formatted message

### 🔍 Review
- `/story-review [id]` - **CORE:** Move to review, run quality checks
- `/story-refactor [id]` - Apply improvements based on standards
- `/story-document [id]` - Generate/update documentation

### ✅ QA & Testing
- `/story-qa [id]` - **CORE:** Run automated tests and validation
- `/story-test-integration [id]` - Integration testing
- `/story-validate [id]` - **CORE:** Final validation before shipping

### 🚀 Shipping
- `/story-ship [id]` - **CORE:** Merge, deploy, and complete
- `/story-rollback [id]` - Execute rollback if issues
- `/story-complete [id]` - Archive and capture lessons

### 📊 Analysis
- `/story-metrics` - Show velocity and cycle time
- `/story-patterns` - Identify recurring patterns
- `/story-tech-debt` - List and prioritize technical debt

### 📅 Daily Workflow
- `/story-today` - Current focus and next actions
- `/story-next` - Suggest what to work on next
- `/story-quick-check` - 30-second validation
- `/story-full-check` - 5-minute comprehensive check
- `/story-timebox [hours]` - Set work session timer
- `/story-blocked [reason]` - Mark story as blocked

## Features

- **Context-Aware**: Commands read from `/project-context/` files if they exist
- **Progressive Enhancement**: Works with defaults, better with configuration
- **Independent**: Each command works standalone, no setup required
- **Tech Stack Agnostic**: Understands your stack and generates appropriate code
- **Git Integration**: Built-in git workflow support
- **Testing Integration**: Automated test execution
- **Browser Testing**: Supports Playwright/Pest browser tests

## Example Workflow

**Core Linear Process:**
```bash
# 1. Create story
/story-new "Add user authentication"

# 2. Start development
/story-start STORY-2024-001

# 3. Generate implementation with browser tests
/story-implement STORY-2024-001

# 4. Commit changes
/story-save "Implement user authentication feature"

# 5. Code review and quality checks
/story-review STORY-2024-001

# 6. Automated testing and validation
/story-qa STORY-2024-001

# 7. Final validation before shipping
/story-validate STORY-2024-001

# 8. Ship to production
/story-ship STORY-2024-001
```

**Optional commands can be used as needed:**
- `/story-save` can also be used anytime during development for incremental commits
- `/story-status` to check progress
- `/story-rollback` if issues arise

## Project Context (Optional)

For best results, create a `/project-context/` directory in your project with:
- `technical-stack.md` - Your technology choices
- `coding-standards.md` - Your coding standards
- `development-process.md` - Your workflow stages

The commands will read these files and adapt to your project's specific needs.

## Requirements

- Claude Code CLI
- Git (for version control commands)
- Your project's test framework (for QA commands)

## Tech Stack Support

Works with any tech stack, with optimizations for:
- Laravel/TALL stack
- React/Next.js
- Vue.js
- Node.js/Express
- Python/Django
- Ruby on Rails

## Key Principles

- **No Prerequisites**: Commands work immediately
- **Smart Defaults**: Sensible behavior without configuration
- **Your Stack**: Reads your actual tech choices, not hardcoded
- **Full Lifecycle**: From idea to production

## License

MIT - See [LICENSE](LICENSE) for details

## Contributing

Contributions welcome! Please open an issue or PR.

## Support

For issues or questions, please open an issue on GitHub.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
