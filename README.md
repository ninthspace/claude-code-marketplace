# Claude Code Marketplace

A Claude Code plugin marketplace providing development tools and productivity utilities.

## Overview

This marketplace contains plugins for facilitated planning, note searching, PHP code intelligence, and JavaScript/TypeScript code simplification. All tools are designed to work seamlessly with Claude Code.

## Installation

### Install from Marketplace (inside Claude Code)

```bash
# Install the marketplace
/plugin marketplace add ninthspace/claude-code-marketplace

# Install individual plugins
/plugin install noteplan@claude-code-marketplace
/plugin install php-lsp@claude-code-marketplace
/plugin install cpm@claude-code-marketplace
/plugin install js-simplifier@claude-code-marketplace
```

## Available Plugins

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

### Claude Planning Method (v1.19.3)

**Facilitated planning with multi-perspective party mode and focused consultation for Claude Code**

Structured discovery, product ideation, architecture exploration, specification, work breakdown, task execution, retrospectives, and course correction through guided conversation. Includes party mode — a multi-agent discussion where named specialist personas (PM, Architect, Developer, UX Designer, QA, DevOps, Tech Writer, Scrum Master) debate trade-offs and surface blind spots — and consult mode for focused one-to-one expert dialogue with dynamic membership. Inspired by the BMAD-METHOD.

**Seventeen skills forming a pipeline:**

| Skill | Purpose | Output |
|-------|---------|--------|
| `/cpm:party` | Multi-perspective discussion with agent personas | Discussion summary + optional pipeline handoff |
| `/cpm:consult` | Focused one-to-one consultation with a chosen expert | `docs/discussions/{nn}-discussion-{slug}.md` |
| `/cpm:discover` | Facilitated problem discovery | `docs/plans/01-plan-{slug}.md` |
| `/cpm:brief` | Product ideation — vision, features, user journeys | `docs/briefs/01-brief-{slug}.md` |
| `/cpm:architect` | Architecture exploration — ADRs with trade-offs | `docs/architecture/01-adr-{slug}.md` |
| `/cpm:spec` | Requirements & architecture specification | `docs/specifications/01-spec-{slug}.md` |
| `/cpm:epics` | Work breakdown into epic documents | `docs/epics/{nn}-epic-{slug}.md` |
| `/cpm:do` | Task execution with acceptance criteria | Updated epic doc + implemented code |
| `/cpm:review` | Adversarial review with agent personas | `docs/reviews/{nn}-review-{slug}.md` + optional autofix |
| `/cpm:retro` | Lightweight retrospective from completed work | `docs/retros/01-retro-{slug}.md` |
| `/cpm:pivot` | Course correction — amend any planning artefact | Surgically edited docs + cascaded downstream updates |
| `/cpm:present` | Audience-aware artifact transformation | `docs/communications/{nn}-{format}-{slug}.md` |
| `/cpm:templates` | Template discoverability & scaffolding | Template previews + override files at `docs/templates/` |
| `/cpm:library` | Import reference docs for all skills to use | `docs/library/{name}.md` with YAML front-matter |
| `/cpm:archive` | Archive completed or stale planning documents | Files moved to `docs/archive/` |
| `/cpm:quick` | Lightweight execution for small changes | `docs/quick/{nn}-quick-{slug}.md` |
| `/cpm:status` | Project status reconnaissance and next-step recommendations | Ephemeral (stdout only) |

**Quick Start:**
```bash
# Brainstorm with your team of agent personas
/cpm:party should we use a monorepo or separate repos?

# Focused consultation with one expert
/cpm:consult Margot

# Full pipeline: discover → brief → architect → spec → epics → do → retro
/cpm:discover build a customer portal for our booking system
/cpm:brief docs/plans/01-plan-customer-portal.md
/cpm:architect docs/briefs/01-brief-customer-portal.md
/cpm:spec docs/briefs/01-brief-customer-portal.md
/cpm:epics docs/specifications/01-spec-customer-portal.md
/cpm:do
/cpm:retro

# Import reference docs for skills to use as context
/cpm:library docs/architecture-decisions.md

# Review planning artifacts before or after execution
/cpm:review docs/epics/01-epic-customer-portal.md

# Course correct mid-flow
/cpm:pivot docs/specifications/01-spec-customer-portal.md

# Transform artifacts for stakeholders
/cpm:present docs/specifications/01-spec-customer-portal.md

# Explore and customise templates
/cpm:templates preview brief

# Clean up completed artefacts
/cpm:archive

# Small change? Skip the full pipeline
/cpm:quick add a --verbose flag to the deploy script

# Check project status and get next-step recommendations
/cpm:status

# Or jump to any step independently
/cpm:spec I need a REST API for inventory management
/cpm:do 3  # work on a specific task
```

**Key Features:**
- Party mode — named agent personas discuss, debate, and disagree constructively
- Consult mode — focused one-to-one expert dialogue with invite/dismiss and lead transfer
- Multi-perspective insights woven into discover and spec phases
- Product ideation — explore vision, value propositions, and user journeys before requirements
- Architecture exploration — facilitated ADRs with trade-off analysis and dependency mapping
- Facilitated conversations, not forms — builds on your answers
- One topic at a time with user-gated progression
- Scales depth to complexity — skips phases that don't add value
- MoSCoW prioritisation for requirements
- Architecture decisions with rationale and alternatives (references existing ADRs)
- Spec requirement traceability — stories link back to the requirements they satisfy
- Right-sized epics and stories with acceptance criteria and dependencies
- Testing thread through the pipeline — spec defines test approach tags, epics propagate them to criteria and generate testing tasks, do discovers and runs tests in verification gates
- Task execution loop with acceptance criteria verification and ADR awareness
- Test runner discovery — convention-based detection from project config files, cached per session
- Epic-level verification — completed epics are checked against their source spec
- Spec, ADR, and test coverage compliance review dimensions
- Lightweight retros with testing gap analysis that feed forward into the next planning cycle
- Adversarial review — agent personas challenge assumptions, spot gaps, and flag risks with optional autofix
- Course correction — surgically amend any artefact with cascading downstream updates (5 artifact types)
- Audience-aware artifact transformation — present planning artifacts to any audience in any format
- Two-tier template system — structural (fixed data contracts) and presentational (overridable)
- Project reference library — import docs that skills auto-discover and use as context
- Archive — clean up completed artefacts with staleness heuristics and chain detection
- Project status reconnaissance — scan artifacts and git history, produce a narrative briefing with next steps
- Customisable agent roster — override default personas per project
- Compaction resilience — seamlessly survives Claude Code context compaction

[View full documentation](./cpm/README.md) | [Interactive Training Guide](./cpm-training-guide.html)

---

### JS/TS Simplifier (v1.0.0)

**Simplify and improve JavaScript and TypeScript code across an entire codebase**

A skill that scans all JS/TS files (or a configurable subset) and applies clarity, consistency, and maintainability improvements while preserving exact functionality. Unlike targeted simplification of recently changed files, this skill works across the whole codebase.

**Three parallel analysis agents:**
- **Modern Syntax** — ES2015+ and ES2020+ upgrades (optional chaining, nullish coalescing, async/await, const/let)
- **Code Quality** — Dead code removal, conditional simplification, naming improvements, error handling
- **Structure & Reuse** — DRY violations, module organisation, function complexity, async patterns

**Quick Start:**
```bash
# Simplify all JS/TS files in the project
/js-simplify

# Narrow to a specific directory
/js-simplify src/

# Only git-modified files
/js-simplify only changed

# Focus on a specific pattern
/js-simplify focus on async patterns
```

**Key Features:**
- Parallel three-agent analysis for comprehensive coverage
- Respects project conventions (CLAUDE.md, ESLint, Prettier, tsconfig)
- Configurable scope — all files, specific directories, globs, or git-changed only
- Safety-first — never changes what the code does, only how it does it
- Flags ambiguous cases for manual review rather than auto-applying

**Supported File Types:**
- `.js`, `.mjs`, `.cjs`, `.jsx`, `.ts`, `.tsx`

[View full documentation](./js-simplifier/SKILL.md)

## Removing Plugins (when in Claude Code)

```bash
# Uninstall individual plugins
/plugin uninstall noteplan@claude-code-marketplace
/plugin uninstall php-lsp@claude-code-marketplace
/plugin uninstall cpm@claude-code-marketplace
/plugin uninstall js-simplifier@claude-code-marketplace

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
