# Changelog

All notable changes to the Story-Driven Development plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.1.0] - 2025-10-12

### Added

- **Enhanced `/sdd:story-flow`**: Added `/sdd:story-complete` as final step (Step 9) after shipping
  - Complete workflow sequence is now: new → start → implement → review → qa → validate → save → ship → **complete**
  - Story completion automatically populates retrospective, lessons learned, and metrics
  - Stories are now archived with comprehensive documentation after shipping
  - Default `--stop-at` parameter changed from "ship" to "complete" for full lifecycle
  - Interactive mode prompts "Complete story and archive?" after successful deployment

- **Story Index Management**: `/sdd:story-complete` now always creates and maintains `/docs/stories/completed/INDEX.md`
  - Automatically creates index file if it doesn't exist
  - Adds story summary with link to archived file
  - Includes key metrics (duration, test coverage, business impact)
  - Provides centralized view of all completed stories

### Changed

- `/sdd:story-flow` default behavior now includes story completion and archival
  - Previous behavior of stopping at "ship" can be restored with `--stop-at=ship`
  - Updated all examples to reflect 9-step workflow
  - Total workflow time estimate updated to 13 minutes (was 12 minutes)

## [3.0.0] - 2025-10-12

### Changed

- **BREAKING**: Moved all artifacts out of root into the `./docs/` directory for better organization.
- You'll need to move any existing files from:
    - `project-context/`
    - `releases/`
    - `stories/`
into `./docs/` manually after updating.

## [2.0.1] - 2025-10-11

### Fixed
- Corrected file path references that incorrectly used `/sdd:` prefix
  - `/project-context/sdd:project-glossary.md` → `/project-context/project-glossary.md`
  - `/stories/templates/sdd:story-template.md` → `/stories/templates/story-template.md`
  - Note: Only command names should use `/sdd:` prefix, not file paths

## [2.0.0] - 2025-10-11

### Changed
- **BREAKING**: All commands now use `/sdd:` namespace prefix
  - Commands like `/story-new` are now `/sdd:story-new`
  - Commands like `/project-init` are now `/sdd:project-init`
  - This change prevents naming conflicts with other plugins in the marketplace
- Updated all command cross-references to use `/sdd:` prefix
- Updated README files with new command syntax
- Directory paths (e.g., `/project-context/`) remain unchanged

### Migration Guide
Users upgrading from 1.0.0 should update their command usage:
- Replace `/story-*` with `/sdd:story-*`
- Replace `/project-*` with `/sdd:project-*`
- Replace `/command-*` with `/sdd:command-*`

## [1.0.0] - 2025-10-11

### Added
- Initial release of Story-Driven Development plugin
- 34 comprehensive commands for agile development workflow
- Project setup commands (`/project-init`, `/project-brief`, etc.)
- Story management commands (`/story-new`, `/story-status`, etc.)
- Development workflow commands (`/story-start`, `/story-implement`, `/story-save`)
- Code review commands (`/story-review`, `/story-refactor`, `/story-document`)
- QA and testing commands (`/story-qa`, `/story-validate`, `/story-test-integration`)
- Deployment commands (`/story-ship`, `/story-rollback`, `/story-complete`)
- Analysis commands (`/story-metrics`, `/story-patterns`, `/story-tech-debt`)
- Daily workflow commands (`/story-today`, `/story-next`, `/story-quick-check`, etc.)
- Context-aware command execution
- Git integration for version control
- Automated testing support
- Browser testing support (Playwright/Pest)
- Tech stack agnostic implementation
- Progressive enhancement with project context

### Features
- Linear workflow from ideation to production
- Optional supporting commands for specific needs
- Reads from `/project-context/` for customization
- Works with defaults, no configuration required
- Full git workflow integration
- Automated test execution
- Quality checks and validation
- Deployment automation
