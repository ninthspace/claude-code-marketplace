# Claude Code Marketplace

A Claude Code plugin marketplace providing development tools and productivity utilities.

## Overview

This marketplace contains plugins for facilitated planning (CPM), database-backed planning artefacts (DPM), note searching, PHP code intelligence, JavaScript/TypeScript code simplification, and Filament v5 admin mockups. All tools are designed to work seamlessly with Claude Code.

## Installation

### Install from Marketplace (inside Claude Code)

```bash
# Install the marketplace
/plugin marketplace add ninthspace/claude-code-marketplace

# Install individual plugins
/plugin install noteplan@ninthspace-marketplace
/plugin install php-lsp@ninthspace-marketplace
/plugin install cpm@ninthspace-marketplace
/plugin install dpm@ninthspace-marketplace
/plugin install js-simplifier@ninthspace-marketplace
/plugin install filament-mockup@ninthspace-marketplace
```

**The suffix is the marketplace's name, not the repository's.** `marketplace.json` declares
`ninthspace-marketplace`, and that is what every installed plugin is keyed by — so
`cpm@claude-code-marketplace` resolves to nothing however the repository is spelled in the
`marketplace add` line above it.

### Also needed for `/cpm:ralph` — the ralph-loop fork

CPM's autonomous loop (`/cpm:ralph`) does not implement the loop itself. It writes a state
file and relies on a **Stop hook** supplied by a separate plugin. Install ours:

```bash
/plugin marketplace add ninthspace/ralph-loop
/plugin install ralph-loop@ninthspace-ralph
```

This is a fork of Anthropic's [`ralph-loop`](https://github.com/anthropics/claude-plugins-public/tree/main/plugins/ralph-loop)
(Apache-2.0), which is itself the maintained line descended from Daisy Hollman's
`ralph-wiggum`. The fork's first commit is the upstream plugin unmodified, so every change
is visible as a diff against it.

**One behavioural change, and it is the reason to prefer the fork**: the Stop hook no longer
deletes the loop's state file when it cannot read the transcript. Upstream treats a missing
transcript, a failed `grep` for assistant records, and a `jq` parse error as reasons to end
the run — and the state file *is* the loop, so ending it that way exits 0 with no promise
and no state file, which is indistinguishable from a completed run. The fork continues on
all three: failing to read a turn's output means *no promise this iteration*, not *the work
is finished*. An unattended overnight run is precisely where that difference is invisible
and expensive.

CPM works with any of the three — `cpm/hooks/lib/ralph-hook-probe.sh` detects the hook
whichever plugin provides it, and warns when none is present. The upstream plugins remain
usable; the fork is what `/cpm:ralph` is developed and tested against.

**Do not enable more than one at a time.** All three register a Stop hook, both fire on the
same session, and the state file only has to be deleted by one of them for the loop to end.

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

### Claude Planning Method (v3.11.0)

**Facilitated planning with multi-perspective party mode and focused consultation for Claude Code**

Structured discovery, product ideation, architecture exploration, specification, work breakdown, task execution, retrospectives, and course correction through guided conversation. Includes party mode — a multi-agent discussion where named specialist personas (PM, Architect, Developer, UX Designer, QA, DevOps, Tech Writer, Scrum Master) debate trade-offs and surface blind spots — and consult mode for focused one-to-one expert dialogue with dynamic membership. Inspired by the BMAD-METHOD.

v3 is tuned for Opus 5 and later: all skills use positive-voice instructions, explicit stop criteria, outcome-oriented procedural guidance, and a reduced token footprint.

**Twenty-two skills forming a pipeline:**

| Skill | Purpose | Output |
|-------|---------|--------|
| `/cpm:party` | Multi-perspective discussion with agent personas | Discussion summary + optional pipeline handoff |
| `/cpm:consult` | Focused one-to-one consultation with a chosen expert | `docs/discussions/{nn}-discussion-{slug}.md` |
| `/cpm:discover` | Facilitated problem discovery | `docs/plans/01-plan-{slug}.md` |
| `/cpm:brief` | Product ideation — vision, features, user journeys | `docs/briefs/01-brief-{slug}.md` |
| `/cpm:architect` | Architecture exploration — ADRs with trade-offs | `docs/architecture/01-adr-{slug}.md` |
| `/cpm:spec` | Requirements & architecture specification | `docs/specifications/01-spec-{slug}.md` |
| `/cpm:epics` | Work breakdown into epic documents | `docs/epics/{parent}-{seq}-epic-{slug}.md` + coverage matrix |
| `/cpm:do` | Task execution with acceptance criteria | Updated epic doc + implemented code |
| `/cpm:ralph` | Autonomous execution — a set of epics, or a whole spec end to end | Ralph loop command + execution log |
| `/cpm:review` | Adversarial review with agent personas | `docs/reviews/{nn}-review-{slug}.md` + optional autofix |
| `/cpm:audit` | Independent codebase health audit across nine dimensions | `docs/audits/{nn}-audit-{slug}.md` |
| `/cpm:inspect` | What a change set did, and where it sits in the repo | Ephemeral (+ optional published artifact) |
| `/cpm:retro` | Lightweight retrospective from completed work | `docs/retros/01-retro-{slug}.md` |
| `/cpm:pivot` | Course correction — amend any planning artefact | Surgically edited docs + cascaded downstream updates |
| `/cpm:present` | Audience-aware artifact transformation | `docs/communications/{nn}-{format}-{slug}.md` (+ optional HTML, + optional published artifact) |
| `/cpm:templates` | Template discoverability & scaffolding | Template previews + override files at `docs/templates/` |
| `/cpm:library` | Import reference docs for all skills to use | `docs/library/{name}.md` with YAML front-matter |
| `/cpm:archive` | Archive completed or stale planning documents | Files moved to `docs/archive/` |
| `/cpm:quick` | Lightweight execution for small changes | `docs/quick/{nn}-quick-{slug}-spec.md` |
| `/cpm:status` | Project status reconnaissance and next-step recommendations | Ephemeral (stdout only) |
| `/cpm:clean` | On-demand cleanup of leftover session-state files | None (removes files, reports what was deleted) |
| `/cpm:artifact` | Register published artifacts against the work that produced them | `docs/artifacts/index.md` + backlinks in associated documents |

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

# Hand a whole spec to the autonomous loop — epics first, then the work
/cpm:ralph docs/specifications/01-spec-customer-portal.md

# Small change? Skip the full pipeline
/cpm:quick add a --verbose flag to the deploy script

# Check project status and get next-step recommendations
/cpm:status

# Clean up leftover session-state files on demand
/cpm:clean

# Register a published artifact against the work that produced it
/cpm:artifact https://claude.ai/code/artifact/... auth flow explorer, from spec 12

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
- Spec coverage roll-up — one command joins every epic's coverage matrix back to the spec's requirements and answers "is this spec fully delivered?", naming untraced requirements first
- Autonomous spec delivery — point `/cpm:ralph` at a spec and it generates the epics, then works them; the loop stops on the roll-up script's verdict, not on its own judgement
- Spec, ADR, and test coverage compliance review dimensions
- Lightweight retros with testing gap analysis that feed forward into the next planning cycle
- Adversarial review — agent personas challenge assumptions, spot gaps, and flag risks with optional autofix
- Independent codebase audit — nine dimensions of code health with `file:line` citations, prioritised findings, and handoff to spec/library/quick
- Course correction — surgically amend any artefact with cascading downstream updates (5 artifact types)
- Audience-aware artifact transformation — present planning artifacts to any audience in any format
- Two-tier template system — structural (fixed data contracts) and presentational (overridable)
- Project reference library — import docs that skills auto-discover and use as context
- Archive — clean up completed artefacts with staleness heuristics and chain detection
- Project status reconnaissance — scan artifacts and git history, produce a narrative briefing with next steps
- Customisable agent roster — override default personas per project
- Compaction resilience — seamlessly survives Claude Code context compaction, with `/cpm:clean` for on-demand cleanup of leftover session-state files

**Companion tool — cpm board:** a standalone terminal UI (`cpm/tools/board/`) that shows the CPM status of every project you register — a three-column Projects → Epics → Stories browser — and launches the right `/cpm:*` session for each without leaving the board. It reads each project's `docs/` planning artifacts read-only. See [the board README](./cpm/tools/board/README.md).

**`/cpm:ralph` needs a Stop hook, and CPM does not ship one.** The autonomous loop is driven by a Stop hook from a separate plugin; every other skill works without one. Install:

```
/plugin marketplace add ninthspace/ralph-loop
/plugin install ralph-loop@ninthspace-ralph
```

**`ralph-loop@ninthspace-ralph` 1.2.0 or later** is the supported configuration — it is what CPM's documented loop behaviour is written against. The loop also runs on `ralph-loop@claude-plugins-official` and `ralph-wiggum@claude-code-plugins`, and `/cpm:ralph` probes whichever hook is installed rather than checking a name or a version. What you lose below 1.2.0 is not an error message: an unreadable transcript ends the run silently and looks like a clean finish, every `<promise>` in the transcript is the hook's own reminder rather than the model's, and `active: false` in the loop's state file does nothing at all. See [the fork's README](https://github.com/ninthspace/ralph-loop) for what each change does.

[View full documentation](./cpm/README.md) | [Interactive Training Guide](./cpm-training-guide.html)

---

### DPM — Data-Modelled Planning Method (v0.3.0)

**Planning artefacts as database rows, with markdown as a generated projection**

CPM's pipeline with a different substrate. Every artefact — spec, epic, story, requirement, coverage row — is a row with typed columns, and every cross-artefact reference is a foreign key rather than a path in prose. The markdown under `docs/` is a generated, one-way projection: it is committed so pull requests still show a readable diff, but it is never read back. Skills write exclusively through typed MCP tools, so no skill contains SQL and nothing parses prose.

**What the substrate buys:**
- **Referential integrity** — a story cannot point at an epic that does not exist, and a renumber updates every reference by construction rather than by search-and-replace
- **Queryable state** — "which requirements have no covering criterion" is a query, not a grep across four hundred files
- **A guard that cannot be fooled** — a pre-commit hook regenerates both artefacts and refuses a commit that disagrees with the database, so a hand-edit to a generated file is caught rather than silently overwritten at the next render
- **Restorable from text** — `.dpm/dpm.sql` is the committed form; the binary database is derived and gitignored

**Quick Start:**
```bash
# After installing, in each repository DPM keeps artefacts in:
# (an absolute <plugin path> — a symlink resolves its target from .git/hooks/)
ln -s <plugin path>/dpm/hooks/pre-commit .git/hooks/pre-commit

# Then, after any skill run that wrote something:
/dpm:publish
```

**Re-make that symlink after each DPM upgrade.** A release installs beside the previous one and re-points nothing, so the link keeps running the version you installed it from. The guard notices — it refuses a database whose schema is newer than it understands, rather than reporting on a comparison it can only half make — but re-linking is yours to do.

The database is created on the first tool call rather than at launch, so a session in a directory that does not use DPM leaves no `.dpm/` behind. When one is created, `.dpm/.gitignore` is written before the database file exists — keeping the binary out of your commits is not a step you perform. On a fresh clone the first tool call finds the committed `.dpm/dpm.sql` and builds the database from it.

**Requires:** Node 22.5.0 or later. DPM reaches SQLite through `node:sqlite` in the standard library — no native module, no `node-gyp`, no build step.

**Companion tool — DPM board:** a standalone terminal UI (`dpm/tools/board/`) showing the state of every project you register — a three-column Projects → Epics → Stories browser — and launching the right `/dpm:*` session for each without leaving the board. Unlike CPM's board it reads nothing off disk: it is an MCP client, so a blocked epic *names* its blocker from a `dependency` row instead of having one guessed from a `**Blocked by**` line, and it can answer questions a markdown corpus cannot — `Ctrl+G` lists every requirement no coverage row traces, and a per-project badge carries what `check_integrity` reported. Servers are spawned read-only, so observing a project leaves it byte-identical. See [the board README](./dpm/tools/board/README.md).

**Status:** in use, still settling. The skill corpus, the tool surface, the database lifecycle and the board are in place — specs `47-spec-dpm-sqlite-persistence.md`, `48-spec-dpm-board.md` and `49-spec-dpm-database-lifecycle.md` under `docs/specifications/`, with the work broken down across `docs/epics/47-*`, `48-*` and `49-*`.

[View full documentation](./dpm/README.md)

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

### Filament Mockup (v1.1.0)

**Build high-fidelity Filament v5 admin mockups for stakeholder sign-off**

A skill that turns a product brief or spec into a single self-contained HTML file that looks pixel-accurate to a real Filament v5 admin panel — clickable enough to walk a stakeholder through every screen and flow, and throwaway by design (the real Filament build regenerates all of it natively). Mockups use the real captured Filament theme CSS and Filament's exact `fi-*` markup, so what stakeholders sign off on is what gets built. **Not** for production Filament code or customer-facing/front-end mockups.

**Workflow:**
- **Capture** — lift the compiled theme CSS and design tokens from a real Filament v5 panel
- **Inventory** — build an FR → screen matrix so every element traces back to a numbered functional requirement
- **Build** — reuse Filament's exact `fi-*` grammar; mark genuinely custom components with the `mk-` namespace
- **Verify** — measure with Playwright rather than eyeballing, then sign off with a coverage audit
- **Hand off** — write the durable routing table (`docs/mockups/surface-routing.md`) so the downstream builder `mockup-to-filament` knows which surfaces it owns (works stand-alone — no `brief-to-mockups` prerequisite)

**Quick Start:**
```bash
# Turn a brief/spec into clickable admin screens
create a Filament mockup from docs/specifications/05-spec-admin-panel.md

# Or describe it directly
mock up the admin panel for this PRD
```

**Key Features:**
- Single self-contained HTML file — opens by `file://`, zero environment to stand up
- Maximum fidelity to Filament's real design language (captured theme, Albert Sans, standard layouts)
- Every element traces to a functional requirement — invented UI is flagged, not silently added
- Visible `mk-` vs `fi-*` boundary distinguishes mockup scaffolding from real Filament
- Bundled scaffold, capture/verify scripts, and an `fi-*` grammar cheat-sheet
- Part of the mockup→build family — a *producer* whose output the *builders* consume (`mockup-to-filament` for Filament, `mockup-to-blade` for bespoke); emits a routing handoff naming the lane per surface

**Requires:** Node + Playwright for the capture/verify scripts (`npm i -D playwright && npx playwright install chromium`).

[View full documentation](./filament-mockup/SKILL.md)

## Removing Plugins (when in Claude Code)

```bash
# Uninstall individual plugins
/plugin uninstall noteplan@ninthspace-marketplace
/plugin uninstall php-lsp@ninthspace-marketplace
/plugin uninstall cpm@ninthspace-marketplace
/plugin uninstall dpm@ninthspace-marketplace
/plugin uninstall js-simplifier@ninthspace-marketplace
/plugin uninstall filament-mockup@ninthspace-marketplace

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
