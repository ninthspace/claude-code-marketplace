# Story-Driven Development Plugin

A comprehensive Claude Code plugin providing 30+ commands for story-driven agile development, from ideation through production deployment.

All commands are implemented as prompts that Claude Code executes directly. No additional setup or programming languages required.

## Quick Start

After installation, you have two approaches:

### Approach 1: Project Setup First (Recommended for new projects)

```bash
# 1. Initialize project structure and context
/sdd:project-init

# 2. Create comprehensive project brief with story breakdown
/sdd:project-brief "E-commerce Platform"

# 3. Start with automated workflow
/sdd:story-flow STORY-2025-001

# Or use individual commands for more control
/sdd:story-start STORY-2025-001
/sdd:story-implement STORY-2025-001
/sdd:story-save "Implement user authentication"
/sdd:story-review STORY-2025-001
/sdd:story-qa STORY-2025-001
/sdd:story-validate STORY-2025-001
/sdd:story-ship STORY-2025-001

# 4. OPTIONAL: Plan next development phase (iterative development)
/sdd:project-phase "Phase 2"
```

### Approach 2: Jump Right In (Works with smart defaults)

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

## Project Setup Workflow

### Why Set Up Your Project First?

While you can jump straight into story creation with smart defaults, initializing your project provides significant benefits:

**Benefits of `/sdd:project-init`:**
- Creates organized directory structure (`/project-context/`, `/stories/`)
- Documents your technical stack (frameworks, testing tools, deployment)
- Establishes coding standards and conventions
- Defines development process and quality gates
- Customizes all templates to match your tech stack

**Benefits of `/sdd:project-brief`:**
- Breaks down complex features into multiple related stories
- Documents story dependencies and implementation order
- Provides comprehensive acceptance criteria for each story
- Establishes project objectives and success metrics
- Creates version-controlled project documentation

### When to Use Project Setup

**Use project setup when:**
- Starting a new project from scratch
- Beginning a major feature set with multiple related stories
- Want to establish team standards and conventions
- Need to document technical decisions and rationale
- Planning complex features with dependencies

**Skip project setup when:**
- Making quick fixes or single-story changes
- Working in an established codebase with existing patterns
- Prototyping or experimenting
- Time constraints require immediate action

### Phase-Based Development (Optional)

For ongoing projects that evolve through multiple development cycles, use phase planning:

**Benefits of `/sdd:project-phase`:**
- Interactive planning for next development iteration
- User-driven feature prioritization and requirements gathering
- Analyzes completed work to inform next phase
- Creates phase-specific documentation and story queues
- Organizes features by: iteration (improve existing), extension (build new), foundation (technical improvements)
- Requires explicit user approval before creating documentation

**When to use phase planning:**
- After completing initial project stories and planning next iteration
- Managing multiple related features across development cycles
- Coordinating feature releases with dependencies
- Long-term projects with distinct phases (MVP → v2.0 → v3.0)
- Need to analyze completed work before planning next steps

**When to skip phase planning:**
- First time setting up project (use `/sdd:project-brief` instead)
- Working on single isolated feature
- Continuing existing work without major direction changes
- Small projects with linear development

## What's Included

This plugin adds a complete story-driven development workflow with:

- **Project Setup Commands** - Initialize project structure, create comprehensive project briefs, and manage context documents
- **Phase Planning** - Interactive planning for iterative development cycles with user-driven requirements
- **Story Management** - Create, track, and manage development stories
- **Workflow Automation** - Single-command automation for entire story lifecycle
- **Development Workflow** - Start, implement, and save work with git integration
- **Code Review** - Automated quality checks and refactoring
- **QA & Testing** - Automated test execution and validation
- **Deployment** - Ship features and handle rollbacks
- **Analysis & Metrics** - Track velocity, patterns, and technical debt
- **Daily Workflow** - Commands for daily standup and planning

## Command Categories

### 📦 Project Setup (Run First for New Projects)
- `/sdd:project-init` - **FOUNDATION:** Initialize directory structure, create context documents, customize based on your tech stack
- `/sdd:project-brief [title]` - **PLANNING:** Create comprehensive project brief with intelligent story breakdown and dependencies
- `/sdd:project-context-update` - Update tech stack, standards, or process docs
- `/sdd:project-status` - Show all projects and completion status
- `/sdd:project-stories [id]` - List stories for a project with dependencies

### 🔄 Phase Planning (Optional Iterative Development)
- `/sdd:project-phase [phase_name]` - **ITERATIVE:** Interactively plan next development phase with user-driven requirements
  - Analyzes completed work and current project state
  - Gathers user input on desired features and improvements
  - Creates phase-specific documentation and story queues
  - Organizes features by iteration, extension, and foundation categories
  - Supports `--analyze-only` flag for analysis without file creation

### 📝 Story Management
- `/sdd:story-new [title]` - **CORE:** Create new story with template
- `/sdd:story-status` - Show all stories and their stages
- `/sdd:story-continue` - Resume last worked on story

### ⚡ Workflow Automation
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

**Complete Workflow (with Project Setup):**
```bash
# 0a. Initialize project (one-time setup)
/sdd:project-init

# 0b. Create project brief with story breakdown (optional)
/sdd:project-brief "E-commerce Platform"

# 1. Create story (or use story from project brief)
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

**Or use automated workflow:**
```bash
# After project setup, automate steps 1-8
/sdd:story-flow "Add user authentication"
```

**Iterative Development Workflow (with Phase Planning):**
```bash
# After completing initial stories, plan next phase
/sdd:project-phase "Phase 2"

# Interactive prompts will ask:
# - What features do you want to focus on?
# - Any technical areas to address?
# - What constraints should we consider?
# - Approval to create phase documentation

# Then work through phase stories
/sdd:story-flow STORY-2025-005  # First story from Phase 2
/sdd:story-flow STORY-2025-006  # Second story from Phase 2

# Repeat for subsequent phases
/sdd:project-phase "Phase 3"
```

**Optional commands can be used as needed:**
- `/sdd:story-save` can also be used anytime during development for incremental commits
- `/sdd:story-status` to check progress
- `/sdd:story-rollback` if issues arise
- `/sdd:project-phase --analyze-only` to analyze without creating phase documentation

## Project Context

The `/project-context/` directory stores project documentation that all commands use for context-aware behavior.

**Created automatically by `/sdd:project-init`:**
- `technical-stack.md` - Your technology choices and versions
- `coding-standards.md` - Your coding standards and conventions
- `development-process.md` - Your workflow stages and quality gates
- `project-glossary.md` - Domain-specific terminology
- `project-brief.md` - Project overview (empty template)

**Created by `/sdd:project-brief`:**
- `project-brief.md` - Comprehensive project brief with story breakdown
- `story-relationships.md` - Story dependencies and implementation order
- `versions/` - Version history of project documentation

**Created by `/sdd:project-phase`:**
- `phases/[phase_name]/` - Phase-specific documentation for iterative development
  - `phase-brief.md` - Phase goals, feature categories, timeline, and success criteria
  - `story-queue.md` - Prioritized story backlog with dependencies

**All commands read these files and adapt to your project's specific needs.**

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
