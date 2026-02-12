# Claude Planning Method (CPM)

Facilitated planning skills for Claude Code. Brings structured discovery, product ideation, architecture exploration, specification, and work breakdown into your development workflow — guiding you through understanding problems before jumping to solutions.

Inspired by the [BMAD-METHOD](https://github.com/bmad-method) (Breakthrough Method for Agile AI-Driven Development), adapted for Claude Code's native capabilities.

## Quick Start

After installation, use any skill independently or as a pipeline:

```
/cpm:party → /cpm:discover → /cpm:brief → /cpm:architect → /cpm:spec → /cpm:epics → /cpm:do → /cpm:retro
                                                                               ↕            ↕
                                                                        /cpm:review    /cpm:pivot
                                                                                                   ↓
                                                                                            /cpm:archive
/cpm:library (import reference docs used by all skills)
/cpm:templates (explore and customise artifact templates)
/cpm:present (transform artifacts for different audiences)
```

`/cpm:review` sits between planning and execution — review an epic before or after `/cpm:do`. `/cpm:pivot` amends any artefact mid-flow. `/cpm:archive` cleans up completed artefacts. `/cpm:present` transforms artifacts for stakeholder consumption. `/cpm:templates` helps you explore and customise the output formats.

Each step is optional. Use what fits your situation:

- Want diverse perspectives on an idea? Start with `/cpm:party`
- Starting a new product? Begin with `/cpm:discover`
- Problem is clear, need product vision? Jump to `/cpm:brief`
- Need architectural decisions before requirements? Use `/cpm:architect`
- Ready for requirements? Jump to `/cpm:spec`
- Have a plan, need epics? Go straight to `/cpm:epics`
- Ready to implement? `/cpm:do` works through tasks one by one
- Want a critical review before starting? `/cpm:review` runs adversarial review of epics/stories
- Need to share planning artifacts with stakeholders? `/cpm:present` transforms them for any audience
- Want to explore or customise artifact templates? `/cpm:templates` lists, previews, and scaffolds overrides
- Have reference docs (coding standards, architecture decisions)? `/cpm:library` imports them for all skills
- Small bug fix? Skip planning entirely — Claude Code's native plan mode is enough

## Skills

### `/cpm:party` — Multi-Perspective Discussion

Launch a team discussion where named agent personas respond in character, building on each other's ideas and constructively disagreeing. Useful for brainstorming, decision-making, or exploring trade-offs before committing to a direction.

The default roster includes 9 personas: Jordan (PM), Margot (Architect), Kai (Developer), Priya (UX Designer), Tomasz (QA), Casey (Test Engineer), Sable (DevOps), Ellis (Tech Writer), and Ren (Scrum Master). Each has a distinct personality and communication style.

```
/cpm:party should we use a monorepo or separate repos?
/cpm:party docs/plans/customer-portal.md
```

**On exit**: Produces a structured discussion summary (key points, agreements, open questions, recommendations) and offers to hand off into `/cpm:discover`, `/cpm:spec`, or `/cpm:epics` with the summary as input.

**Custom roster**: To customise personas, create `docs/agents/roster.yaml` in your project. This completely replaces the default roster. See `agents/roster.yaml` in the plugin for the schema.

### `/cpm:discover` — Problem Discovery

Guided conversation to understand the problem before proposing solutions. Works through six phases:

1. **Why** — Motivation and importance
2. **Who** — Target users and their needs
3. **Current State** — How it's solved today
4. **Success Criteria** — Definition of done
5. **Constraints** — Technical, business, timeline limits
6. **Summary** — Problem brief for confirmation

**Output**: `docs/plans/01-plan-{slug}.md` (auto-numbered)

At the **Why** and **Constraints** phases, agent personas briefly weigh in with diverse viewpoints to surface blind spots before you respond.

```
/cpm:discover build a customer portal for our booking system
```

**On exit**: Suggests `/cpm:brief` as the primary next step for product ideation, with `/cpm:spec` and `/plan` as alternatives for simpler problems.

### `/cpm:brief` — Product Ideation

Facilitated conversation to transform a problem brief into a product brief. Explores solution approaches, value propositions, key features, and user journeys. Bridges problem discovery and requirements specification by capturing *what* we're building and *why* this approach.

Works through five phases:

1. **Vision & Positioning** — What is this product and who is it for?
2. **Value Propositions** — Why would someone use this?
3. **Key Features** — What does it do? (MoSCoW prioritised)
4. **Differentiation** — How does it differ from alternatives?
5. **User Journey Narratives** — Walk through key user flows

**Input**: A problem brief from `/cpm:discover`, a file path, or a description.
**Output**: `docs/briefs/01-brief-{slug}.md` (auto-numbered)

```
/cpm:brief docs/plans/01-plan-customer-portal.md
```

**On exit**: Suggests `/cpm:architect` for architecture exploration or `/cpm:spec` to jump straight to requirements.

### `/cpm:architect` — Architecture Exploration

Facilitated architecture exploration that derives decisions from the product's actual needs rather than boilerplate. For each key decision, explores options, trade-offs, and dependencies before capturing a rationale. Produces Architecture Decision Records (ADRs).

Works through four phases:

1. **Decision Discovery** — What architectural decisions does this product need?
2. **Trade-off Exploration** — For each decision: options, trade-offs, constraints
3. **Dependency Mapping** — How do decisions affect each other?
4. **ADR Production** — Capture each decision as a structured record

**Input**: A product brief from `/cpm:brief`, a problem brief, or a description.
**Output**: `docs/architecture/01-adr-{slug}.md` (one per decision, auto-numbered)

```
/cpm:architect docs/briefs/01-brief-customer-portal.md
```

**On exit**: Suggests `/cpm:spec` to continue with requirements specification.

### `/cpm:spec` — Requirements & Architecture

Builds a structured specification through facilitated conversation. Covers functional requirements (MoSCoW prioritisation), non-functional requirements, architecture decisions, scope boundaries, testing strategy (with test approach tags per acceptance criterion: `[unit]`, `[integration]`, `[feature]`, `[manual]`), and a final review.

When product briefs exist in `docs/briefs/`, they're used as input context. When ADRs exist in `docs/architecture/`, the architecture section references them rather than starting from scratch — only facilitating new decisions for gaps.

At the **Architecture Decisions** and **Scope Boundary** sections, agent personas present competing trade-offs to help you make informed choices.

**Input**: A product brief from `/cpm:brief`, a problem brief from `/cpm:discover`, a file path, or a description.
**Output**: `docs/specifications/01-spec-{slug}.md` (auto-numbered)

```
/cpm:spec docs/briefs/01-brief-customer-portal.md
/cpm:spec docs/plans/01-plan-customer-portal.md
```

**On exit**: Suggests `/cpm:architect` when no ADRs exist, otherwise `/cpm:epics`.

### `/cpm:epics` — Work Breakdown

Converts a spec into epic documents — one per major work area — each containing stories with acceptance criteria and tasks. Stories include traceability to spec requirements, showing which functional requirements each story satisfies. When the spec has a testing strategy, test approach tags are propagated to story acceptance criteria, testing tasks are auto-generated for stories with automated test tags, and integration testing stories are created for epics with significant cross-story interactions. When ADRs exist in `docs/architecture/`, they're referenced when breaking down architectural work.

**Input**: A spec from `/cpm:spec`, a brief, or a description.
**Output**: `docs/epics/{nn}-epic-{slug}.md` (one per epic)

```
/cpm:epics docs/specifications/01-spec-customer-portal.md
```

### `/cpm:do` — Task Execution

Works through stories and tasks defined in epic documents. Hydrates one story at a time into Claude Code's native task system, then for each task: reads the epic doc for context and acceptance criteria, does the implementation work, verifies criteria are met, updates the story's status, and moves on to the next unblocked task. Loops until all stories are done.

At startup, discovers the project's test runner (from library docs, config files like `composer.json`/`package.json`/`Makefile`, or by asking the user) and caches it for the session. Verification gates run the test command when acceptance criteria carry automated test tags (`[unit]`, `[integration]`, `[feature]`), falling back to self-assessment for `[manual]` criteria or when no test runner is available. Task ordering in the epic doc is respected, enabling TDD when testing tasks precede implementation tasks.

When ADRs exist in `docs/architecture/`, tasks that touch architectural boundaries read the relevant ADR for context. When all stories in an epic complete, an integration-level check verifies the completed epic against its source spec's requirements.

**Input**: An epic doc path, or auto-detects epics with remaining work. Optionally a task ID to start with.

```
/cpm:do        # pick up the next task
/cpm:do 3      # work on task #3 specifically
```

The epic doc is updated as work progresses — statuses move from Pending -> In Progress -> Complete. Acceptance criteria are checked before marking any task done.

During execution, `/cpm:do` captures per-task observations when something noteworthy happens (scope surprises, criteria gaps, complexity underestimates, codebase discoveries, testing gaps). These feed into `/cpm:retro`.

### `/cpm:review` — Adversarial Review

Run a critical review of an epic doc or a specific story using the party agent roster. Each persona examines the artifact through their professional lens — challenging assumptions, spotting gaps, and flagging risks. Produces a structured review document with severity-tagged findings (critical, warning, suggestion) and an optional autofix that generates remediation tasks.

Reviews check spec compliance, ADR compliance, and missing test coverage — flagging stories with automated test tags (`[unit]`, `[integration]`, `[feature]`) that lack corresponding testing tasks, or stories that warrant test approach tags but don't have them.

**Input**: An epic doc path, optionally with a story number. Or auto-detects the most recent epic doc.
**Output**: `docs/reviews/01-review-{slug}.md` (auto-numbered)

```
/cpm:review docs/epics/01-epic-customer-portal.md        # review entire epic
/cpm:review docs/epics/01-epic-customer-portal.md 2      # review story 2 only
/cpm:review                                               # auto-detect most recent epic
```

Agent selection is dynamic — 2-3 agents for single stories, 3-4 for full epics, chosen by content relevance. Every review includes at least one agent challenging business value and one challenging technical approach.

**Autofix**: After review, optionally generate remediation tasks from critical and warning findings. For active epics, tasks are appended as a new story in the epic doc. For completed epics, standalone Claude Code tasks are created.

**On exit**: Adaptive pipeline handoff — pre-execution epics offer pivot/do/exit; post-execution epics offer retro/pivot/discover/spec/exit.

### `/cpm:retro` — Lightweight Retrospective

Reads a completed epic doc, synthesises observations captured during task execution, and produces a retro file that feeds forward into the next planning cycle. Observation categories include scope surprises, criteria gaps, complexity underestimates, codebase discoveries, and testing gaps. When library documents exist, relevant observations are offered as amendments back to the library — closing the feedback loop.

**Input**: An epic doc path, or auto-detects the most recent one.
**Output**: `docs/retros/01-retro-{slug}.md` (auto-numbered)

```
/cpm:retro docs/epics/01-epic-customer-portal.md
/cpm:retro        # auto-detect most recent epic doc
```

**On exit**: Offers to hand off into `/cpm:discover`, `/cpm:spec`, or `/cpm:epics` with the retro as input context — closing the feedback loop for the next planning cycle.

### `/cpm:pivot` — Course Correction

Revisit any planning artefact (problem brief, product brief, ADR, spec, or epic), surgically amend it, and cascade changes through downstream documents. Lighter than re-running the original skill — edit what exists rather than starting over.

**Input**: A file path to any planning document, or auto-discovers artefact chains for selection.

```
/cpm:pivot docs/specifications/01-spec-customer-portal.md
/cpm:pivot        # discover and select from existing artefacts
```

The workflow: select a document, describe your changes in natural language, review a change summary, then walk downstream documents with guided per-section updates. The full cascade chain is: problem brief -> product brief -> ADRs -> spec -> epics. Tasks affected by changed epic stories are flagged (but never auto-modified).

### `/cpm:present` — Audience-Aware Artifact Transformation

Transform CPM planning artifacts into audience-appropriate communications. Select source artifacts, choose an audience (executives, engineering team, stakeholders, etc.) and format (memo, slide deck, email, etc.), and get derived content tailored to the readers.

**Input**: One or more CPM artifact file paths, or auto-discovers available artifacts for selection.
**Output**: `docs/communications/{nn}-{format}-{slug}.md` (auto-numbered)

```
/cpm:present docs/specifications/01-spec-customer-portal.md          # transform a spec
/cpm:present docs/briefs/01-brief-customer-portal.md                 # transform a brief
/cpm:present                                                          # discover and select artifacts
```

Content is derived from source artifacts — regenerable when sources change. Multiple presentations from the same sources are encouraged for different audiences.

### `/cpm:templates` — Template Discoverability & Scaffolding

Explore and customise the templates used by CPM artifact-producing skills. CPM uses a two-tier template system:

- **Structural templates** are data contracts parsed by downstream skills — their format is fixed and cannot be overridden (problem briefs, specs, epic docs, review files, retro files).
- **Presentational templates** can be overridden with project-level files at `docs/templates/` — they control how information is presented (product briefs, ADRs, communications).

Three subcommands:

- **list** — Show all templates with their type and override paths
- **preview {skill}** — Display a template skeleton with placeholder content
- **scaffold {skill}** — Create an override file at the project level for presentational templates

```
/cpm:templates                           # list all templates
/cpm:templates preview brief             # preview the brief template
/cpm:templates scaffold architect        # create an ADR template override
```

### `/cpm:library` — Project Reference Library

Import external documents (coding standards, architecture decisions, API contracts, business rules) into a curated `docs/library/` directory with structured YAML front-matter. Other CPM skills automatically discover and reference these documents during planning and execution — specs pick up architectural constraints, stories inherit coding standards, and `/cpm:do` reads relevant docs before implementing.

Three actions:

- **Intake** — Import a local file or URL into the library with auto-generated front-matter (title, scope, summary)
- **Consolidate** — Reconcile accumulated amendments on a library document into a clean version
- **Batch front-matter** — Scan for library documents missing front-matter and add it

```
/cpm:library docs/architecture-decisions.md    # import a file
/cpm:library https://example.com/standards     # import from URL
/cpm:library consolidate docs/library/coding-standards.md  # reconcile amendments
/cpm:library consolidate                       # batch add front-matter
```

**Scope tagging**: Each library document is tagged with which skills should reference it (`discover`, `spec`, `epics`, `do`, `party`, `review`, or `all`). Skills filter by scope during their library check phase — only reading documents relevant to the current workflow.

### `/cpm:archive` — Archive Planning Documents

Move completed or stale planning artifacts out of the active `docs/` directories into `docs/archive/`. Scans for documents across plans, specifications, epics, and retros, groups them into artifact chains by slug, evaluates staleness heuristics, and lets you select which chains to archive.

**Input**: Optional file path to archive a specific document and its chain. Without arguments, scans all planning directories.

```
/cpm:archive                                          # scan and select
/cpm:archive docs/specifications/01-spec-auth.md      # archive a specific chain
```

Staleness signals: epic complete, orphaned plan (no downstream spec), completed retro, spec fully implemented. Files are moved to `docs/archive/` with mirrored subdirectory structure — never deleted.

## Compaction Resilience

CPM skills run long, multi-phase conversations that can trigger Claude Code's auto-compaction. When that happens, mid-skill state (current phase, user decisions, facilitation progress) would normally be lost.

CPM handles this automatically through **on-disk state tracking** and **plugin hooks**:

1. **During a skill**: After each phase/section/step, the skill writes progress to `docs/plans/.cpm-progress.md` — a hidden file capturing the active skill, completed phases with summaries, and what to do next.
2. **On compaction**: A SessionStart hook (matcher: `compact`) re-injects the full state file into the fresh post-compaction context.
3. **On session start/resume/clear**: If a previous session left an incomplete planning session, the state is re-injected and Claude offers to continue where you left off or start fresh.
4. **On skill completion**: The state file is deleted — it only exists while a skill is actively running.

This means compaction is seamless — Claude picks up exactly where it left off without repeating questions or losing decisions.

## How It Works

Each skill is a facilitated conversation, not a form. Claude asks questions one topic at a time, builds on your answers, and gates progression with user confirmation. The core principles baked into each skill:

- **Facilitate, don't prescribe** — Ask why before what, present trade-offs, let the user decide
- **One topic at a time** — Gate progression with user confirmation, never dump all questions at once
- **Match depth to complexity** — A typo fix needs no discovery phase; a new product does
- **Build on answers** — Each question responds to what you just said

## Example Workflow

**New feature with unclear scope:**

1. `/cpm:discover` — "I want to add multi-tenancy to our app"
   - Claude facilitates conversation about why, who, constraints
   - Produces `docs/plans/01-plan-multi-tenancy.md`

2. `/cpm:brief` — Reads the problem brief, explores product vision
   - Facilitates value propositions, key features, user journeys
   - Produces `docs/briefs/01-brief-multi-tenancy.md`

3. `/cpm:architect` — Reads the product brief, explores key decisions
   - Facilitates trade-off exploration for each architectural decision
   - Produces `docs/architecture/01-adr-multi-tenancy.md` (one per decision)

4. `/cpm:spec` — Reads the brief and ADRs, builds requirements
   - Facilitates MoSCoW prioritisation, references existing ADRs
   - Defines testing strategy with test approach tags per criterion
   - Produces `docs/specifications/01-spec-multi-tenancy.md`

5. `/cpm:epics` — Reads the spec, creates epic docs
   - Breaks into epics, stories, and tasks with dependencies
   - Stories trace back to spec requirements
   - Propagates test approach tags, generates testing tasks
   - Produces `docs/epics/01-epic-multi-tenancy.md` (one per epic)

6. `/cpm:review` (optional) — Review before implementing
   - Agents challenge the epic from different perspectives
   - Checks spec compliance, ADR compliance, and test coverage
   - Produces `docs/reviews/01-review-multi-tenancy.md`

7. `/cpm:do` — Works through tasks one by one
   - Discovers test runner at startup, caches for the session
   - Hydrates stories into Claude Code tasks automatically
   - Reads ADRs when touching architectural boundaries
   - Runs tests in verification gates for automated criteria
   - Implements each task, verifies criteria, updates status
   - Loops until all stories are complete

8. `/cpm:present` (optional) — Share results with stakeholders
   - Transform specs or briefs into executive summaries, team updates, etc.
   - Produces `docs/communications/01-memo-multi-tenancy.md`

## What's Included

```
cpm/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── agents/
│   └── roster.yaml          # Default agent personas for party mode and review
├── hooks/
│   ├── hooks.json           # Hook configuration (SessionStart)
│   ├── session-start-compact.sh  # Re-injects state after compaction
│   └── session-start.sh     # Re-injects state on session startup/resume/clear
├── skills/
│   ├── party/
│   │   └── SKILL.md         # Multi-perspective discussion skill
│   ├── discover/
│   │   └── SKILL.md         # Problem discovery skill (with perspectives)
│   ├── brief/
│   │   └── SKILL.md         # Product ideation skill
│   ├── architect/
│   │   └── SKILL.md         # Architecture exploration skill (ADRs)
│   ├── spec/
│   │   └── SKILL.md         # Requirements specification skill (with perspectives)
│   ├── epics/
│   │   └── SKILL.md         # Work breakdown skill
│   ├── do/
│   │   └── SKILL.md         # Task execution skill
│   ├── review/
│   │   └── SKILL.md         # Adversarial review skill
│   ├── retro/
│   │   └── SKILL.md         # Lightweight retrospective skill
│   ├── pivot/
│   │   └── SKILL.md         # Course correction skill
│   ├── present/
│   │   └── SKILL.md         # Audience-aware artifact transformation skill
│   ├── templates/
│   │   └── SKILL.md         # Template discoverability & scaffolding skill
│   ├── library/
│   │   └── SKILL.md         # Project reference library skill
│   └── archive/
│       └── SKILL.md         # Archive planning documents skill
├── README.md
└── LICENSE
```

## Requirements

- Claude Code with skill/plugin support

## Key Principles

- **Facilitate, don't prescribe** — Guide users through structured discovery to bring out their best thinking
- **One topic at a time** — Gate progression with user confirmation
- **Match depth to complexity** — Scale planning to actual need
- **Right-sized output** — Problem briefs, specs, and tasks that are useful, not bureaucratic

## License

MIT
