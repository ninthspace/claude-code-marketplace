# Claude Planning Method (CPM)

Facilitated planning skills for Claude Code. Brings structured discovery, specification, and work breakdown into your development workflow — guiding you through understanding problems before jumping to solutions.

Inspired by the [BMAD-METHOD](https://github.com/bmad-method) (Breakthrough Method for Agile AI-Driven Development), adapted for Claude Code's native capabilities.

## Quick Start

After installation, use any skill independently or as a pipeline:

```
/cpm:party → /cpm:discover → /cpm:spec → /cpm:epics → /cpm:do → /cpm:retro
                                                  ↕            ↕
                                           /cpm:review    /cpm:pivot
                                                                          ↓
                                                                   /cpm:archive
/cpm:library (import reference docs used by all skills)
```

`/cpm:review` sits between planning and execution — review an epic before or after `/cpm:do`. `/cpm:pivot` amends any artefact mid-flow. `/cpm:archive` cleans up completed artefacts.

Each step is optional. Use what fits your situation:

- Want diverse perspectives on an idea? Start with `/cpm:party`
- Starting a new product? Begin with `/cpm:discover`
- Problem is clear, need requirements? Jump to `/cpm:spec`
- Have a plan, need epics? Go straight to `/cpm:epics`
- Ready to implement? `/cpm:do` works through tasks one by one
- Want a critical review before starting? `/cpm:review` runs adversarial review of epics/stories
- Have reference docs (coding standards, architecture decisions)? `/cpm:library` imports them for all skills
- Small bug fix? Skip planning entirely — Claude Code's native plan mode is enough

## Skills

### `/cpm:party` — Multi-Perspective Discussion

Launch a team discussion where named agent personas respond in character, building on each other's ideas and constructively disagreeing. Useful for brainstorming, decision-making, or exploring trade-offs before committing to a direction.

The default roster includes 8 personas: Jordan (PM), Margot (Architect), Kai (Developer), Priya (UX Designer), Tomasz (QA), Sable (DevOps), Ellis (Tech Writer), and Ren (Scrum Master). Each has a distinct personality and communication style.

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

### `/cpm:spec` — Requirements & Architecture

Builds a structured specification through facilitated conversation. Covers functional requirements (MoSCoW prioritisation), non-functional requirements, architecture decisions, and scope boundaries.

At the **Architecture Decisions** and **Scope Boundary** sections, agent personas present competing trade-offs to help you make informed choices.

**Input**: A problem brief from `/cpm:discover`, a file path, or a description.
**Output**: `docs/specifications/01-spec-{slug}.md` (auto-numbered)

```
/cpm:spec docs/plans/01-plan-customer-portal.md
```

### `/cpm:epics` — Work Breakdown

Converts a spec into epic documents — one per major work area — each containing stories with acceptance criteria and tasks.

**Input**: A spec from `/cpm:spec`, a brief, or a description.
**Output**: `docs/epics/{nn}-epic-{slug}.md` (one per epic)

```
/cpm:epics docs/specifications/01-spec-customer-portal.md
```

### `/cpm:do` — Task Execution

Works through stories and tasks defined in epic documents. Hydrates one story at a time into Claude Code's native task system, then for each task: reads the epic doc for context and acceptance criteria, does the implementation work, verifies criteria are met, updates the story's status, and moves on to the next unblocked task. Loops until all stories are done.

**Input**: An epic doc path, or auto-detects epics with remaining work. Optionally a task ID to start with.

```
/cpm:do        # pick up the next task
/cpm:do 3      # work on task #3 specifically
```

The epic doc is updated as work progresses — statuses move from Pending → In Progress → Complete. Acceptance criteria are checked before marking any task done.

During execution, `/cpm:do` captures per-task observations when something noteworthy happens (scope surprises, criteria gaps, complexity underestimates, codebase discoveries). These feed into `/cpm:retro`.

### `/cpm:review` — Adversarial Review

Run a critical review of an epic doc or a specific story using the party agent roster. Each persona examines the artifact through their professional lens — challenging assumptions, spotting gaps, and flagging risks. Produces a structured review document with severity-tagged findings (critical, warning, suggestion) and an optional autofix that generates remediation tasks.

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

Reads a completed epic doc, synthesises observations captured during task execution, and produces a retro file that feeds forward into the next planning cycle.

**Input**: An epic doc path, or auto-detects the most recent one.
**Output**: `docs/retros/01-retro-{slug}.md` (auto-numbered)

```
/cpm:retro docs/epics/01-epic-customer-portal.md
/cpm:retro        # auto-detect most recent epic doc
```

**On exit**: Offers to hand off into `/cpm:discover`, `/cpm:spec`, or `/cpm:epics` with the retro as input context — closing the feedback loop for the next planning cycle.

### `/cpm:pivot` — Course Correction

Revisit any planning artefact (brief, spec, or epic), surgically amend it, and cascade changes through downstream documents. Lighter than re-running the original skill — edit what exists rather than starting over.

**Input**: A file path to any planning document, or auto-discovers artefact chains for selection.

```
/cpm:pivot docs/specifications/01-spec-customer-portal.md
/cpm:pivot        # discover and select from existing artefacts
```

The workflow: select a document, describe your changes in natural language, review a change summary, then walk downstream documents with guided per-section updates. Tasks affected by changed epic stories are flagged (but never auto-modified).

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

2. `/cpm:spec` — Reads the brief, builds requirements
   - Facilitates MoSCoW prioritisation, architecture decisions
   - Produces `docs/specifications/01-spec-multi-tenancy.md`

3. `/cpm:epics` — Reads the spec, creates epic docs
   - Breaks into epics, stories, and tasks with dependencies
   - Produces `docs/epics/01-epic-multi-tenancy.md` (one per epic)

4. `/cpm:review` (optional) — Review before implementing
   - Agents challenge the epic from different perspectives
   - Produces `docs/reviews/01-review-multi-tenancy.md`

5. `/cpm:do` — Works through tasks one by one
   - Hydrates stories into Claude Code tasks automatically
   - Implements each task, verifies criteria, updates status
   - Loops until all stories are complete

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
