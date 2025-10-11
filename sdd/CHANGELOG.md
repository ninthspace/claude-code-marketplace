# Changelog

All notable changes to the Story-Driven Development plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
