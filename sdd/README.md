# Story-Driven Development Plugin

A comprehensive Claude Code plugin providing 30+ commands for story-driven agile development, from ideation through production deployment.

All commands are implemented as prompts that Claude Code executes directly. No additional setup or programming languages required.

## Quick Start

After installation, try these commands:

```bash
# OPTION 1: Automated workflow (single command for entire lifecycle)
/sdd:story-flow "Add user authentication"

# OPTION 2: Individual commands for more control
# Create your first story
/sdd:story-new "Add user authentication"

# Start development
/sdd:story-start STORY-2025-001

# Generate implementation
/sdd:story-implement STORY-2025-001

# Commit your changes
/sdd:story-save "Implement user authentication"

# Run quality checks
/sdd:story-review STORY-2025-001

# Run automated tests
/sdd:story-qa STORY-2025-001

# Validate before shipping
/sdd:story-validate STORY-2025-001

# Ship to production
/sdd:story-ship STORY-2025-001
```

## Core Workflow

**Essential Commands (Linear Process):**
```
/sdd:story-new → /sdd:story-start → /sdd:story-implement → /sdd:story-save →
/sdd:story-review → /sdd:story-qa → /sdd:story-validate → /sdd:story-ship
```

**Note:** `/sdd:story-save` is essential for git commits but can also be used anytime during development

## Workflow Automation with /sdd:story-flow

The `/sdd:story-flow` command is a powerful workflow automation tool that executes the complete story lifecycle with a single command, reducing 8 separate commands into 1.

### Key Benefits

- **Massive Time Savings**: Complete story from creation to production in 10-20 minutes vs. running 8 separate commands
- **Consistency**: Guarantees all quality gates (review, QA, validation) are executed in correct order
- **Flexibility**: Customize workflow scope with `--start-at` and `--stop-at` parameters
- **Two Modes**:
  - **Interactive** (default): Pause between steps for review and confirmation
  - **Auto** (`--auto` flag): Run continuously, reducing interaction time by ~50%
- **Resume Capability**: Pick up from any step after interruption or fixing issues
- **Smart Error Handling**: Automatically halts on test failures or validation issues with clear recovery paths
- **Quality Assurance**: Never skips critical QA or validation steps, ensuring production-ready code

### Usage Examples

```bash
# Full workflow: Create new story and ship to production
/sdd:story-flow "Add user registration with email verification"

# Resume from specific step (e.g., after fixing issues)
/sdd:story-flow STORY-2025-001 --start-at=qa

# Automated mode (no prompts between steps)
/sdd:story-flow STORY-2025-001 --start-at=qa --auto

# Partial workflow (e.g., only implement and review)
/sdd:story-flow "Fix responsive layout" --stop-at=review

# Resume existing story with auto mode
/sdd:story-flow STORY-2025-015 --start-at=validate --auto
```

### When to Use /sdd:story-flow vs Individual Commands

**Use `/sdd:story-flow` when:**
- Starting a new feature from scratch
- You want automated progression through all steps
- Working on straightforward implementations
- Time efficiency is important
- You want guaranteed quality gates

**Use individual commands when:**
- Need fine-grained control over each step
- Working on complex features requiring multiple iterations
- Want to experiment before committing
- Need to run specific steps multiple times

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
- `/sdd:project-init` - Create folder structure and context documents
- `/sdd:project-context-update` - Update tech stack, standards, or process docs
- `/sdd:project-brief [title]` - Create project brief and break into stories
- `/sdd:project-status` - Show all projects and completion status
- `/sdd:project-stories [id]` - List stories for a project with dependencies

### 📝 Story Management
- `/sdd:story-new [title]` - **CORE:** Create new story with template
- `/sdd:story-status` - Show all stories and their stages
- `/sdd:story-continue` - Resume last worked on story

### 🔄 Workflow Automation
- `/sdd:story-flow [prompt|id]` - **POWER TOOL:** Automate complete workflow from creation to deployment
  - Supports `--start-at=step` to resume from specific step
  - Supports `--stop-at=step` to pause at specific step
  - Supports `--auto` flag for continuous execution

### 🛠️ Development
- `/sdd:story-start [id]` - **CORE:** Start development, create branch
- `/sdd:story-implement [id]` - **CORE:** Generate code based on requirements
- `/sdd:story-save [message]` - **CORE:** Commit with formatted message

### 🔍 Review
- `/sdd:story-review [id]` - **CORE:** Move to review, run quality checks
- `/sdd:story-refactor [id]` - Apply improvements based on standards
- `/sdd:story-document [id]` - Generate/update documentation

### ✅ QA & Testing
- `/sdd:story-qa [id]` - **CORE:** Run automated tests and validation
- `/sdd:story-test-integration [id]` - Integration testing
- `/sdd:story-validate [id]` - **CORE:** Final validation before shipping

### 🚀 Shipping
- `/sdd:story-ship [id]` - **CORE:** Merge, deploy, and complete
- `/sdd:story-rollback [id]` - Execute rollback if issues
- `/sdd:story-complete [id]` - Archive and capture lessons

### 📊 Analysis
- `/sdd:story-metrics` - Show velocity and cycle time
- `/sdd:story-patterns` - Identify recurring patterns
- `/sdd:story-tech-debt` - List and prioritize technical debt

### 📅 Daily Workflow
- `/sdd:story-today` - Current focus and next actions
- `/sdd:story-next` - Suggest what to work on next
- `/sdd:story-quick-check` - 30-second validation
- `/sdd:story-full-check` - 5-minute comprehensive check
- `/sdd:story-timebox [hours]` - Set work session timer
- `/sdd:story-blocked [reason]` - Mark story as blocked

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
/sdd:story-new "Add user authentication"

# 2. Start development
/sdd:story-start STORY-2025-001

# 3. Generate implementation with browser tests
/sdd:story-implement STORY-2025-001

# 4. Commit changes
/sdd:story-save "Implement user authentication feature"

# 5. Code review and quality checks
/sdd:story-review STORY-2025-001

# 6. Automated testing and validation
/sdd:story-qa STORY-2025-001

# 7. Final validation before shipping
/sdd:story-validate STORY-2025-001

# 8. Ship to production
/sdd:story-ship STORY-2025-001
```

**Optional commands can be used as needed:**
- `/sdd:story-save` can also be used anytime during development for incremental commits
- `/sdd:story-status` to check progress
- `/sdd:story-rollback` if issues arise

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
