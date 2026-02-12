# Getting Started with CPM

**Date**: 2026-02-12
**Audience**: Technical staff — engineers, product engineers, and roles adjacent to implementation
**Format**: Onboarding guide
**Source artifacts**:
- cpm/README.md

---

## What is CPM?

CPM (Claude Planning Method) is a planning plugin for Claude Code. It adds a set of slash commands — called "skills" — that guide you through structured planning conversations before (and during) implementation.

Each skill handles a different planning stage. You talk to Claude, answer questions one at a time, and CPM produces written planning documents as output. These documents connect to each other — requirements trace to stories, stories trace to tasks, tasks trace to code.

CPM is conversational, not bureaucratic. It asks questions, builds on your answers, and lets you drive the decisions. Think of it as a structured thinking partner, not a form to fill out.

## The Pipeline

CPM skills form a pipeline. Each step feeds into the next, but every step is optional.

```
/cpm:discover → /cpm:brief → /cpm:architect → /cpm:spec → /cpm:epics → /cpm:do
```

Here's what each skill does:

| Skill | What it does | Output |
|-------|-------------|--------|
| `/cpm:discover` | Understand the problem — why it matters, who it's for, what success looks like | `docs/plans/01-plan-{slug}.md` |
| `/cpm:brief` | Define the product — vision, value propositions, key features, user journeys | `docs/briefs/01-brief-{slug}.md` |
| `/cpm:architect` | Explore key technical decisions — options, trade-offs, dependencies | `docs/architecture/01-adr-{slug}.md` (one per decision) |
| `/cpm:spec` | Build requirements — functional (MoSCoW prioritised), non-functional, scope boundaries | `docs/specifications/01-spec-{slug}.md` |
| `/cpm:epics` | Break work into epic docs — stories with acceptance criteria and tasks | `docs/epics/01-epic-{slug}.md` (one per epic) |
| `/cpm:do` | Execute — picks up tasks one by one, implements, verifies acceptance criteria, updates status | Updates the epic doc in place |

### Supporting Skills

These aren't part of the main pipeline but plug in around it:

| Skill | What it does |
|-------|-------------|
| `/cpm:party` | Multi-perspective brainstorming — simulated team discusses a topic before you commit to a direction |
| `/cpm:review` | Adversarial review of an epic — agents challenge assumptions, check spec/ADR compliance, flag risks |
| `/cpm:retro` | Lightweight retrospective after completing an epic — captures lessons for the next planning cycle |
| `/cpm:pivot` | Course correction — amend any planning artifact and cascade changes downstream |
| `/cpm:present` | Transform artifacts for different audiences (executive summaries, status updates, etc.) |
| `/cpm:library` | Import reference docs (coding standards, architecture docs) that all skills can use as context |
| `/cpm:templates` | Explore and customise the output templates |
| `/cpm:archive` | Move completed planning artifacts to `docs/archive/` |

## When to Use What

**Not everything needs the full pipeline.** Match planning depth to complexity:

- **Typo fix or one-line change** — Don't use CPM. Just do it.
- **Small bug fix** — Claude Code's native `/plan` mode is enough.
- **Clear feature, known scope** — Jump straight to `/cpm:spec` or `/cpm:epics`.
- **Feature with unclear requirements** — Start at `/cpm:discover` to understand the problem first.
- **New product or major initiative** — Use the full pipeline: discover → brief → architect → spec → epics → do.
- **Need to brainstorm before deciding** — Start with `/cpm:party` to get diverse perspectives.
- **Architecture matters** — Use `/cpm:architect` before `/cpm:spec` to nail down key decisions as ADRs.

## How a Skill Session Works

Every CPM skill follows the same pattern:

1. **You invoke a skill** — e.g. `/cpm:discover build a customer portal`
2. **Claude asks questions one at a time** — you answer, Claude builds on your answers
3. **At key moments, agent personas weigh in** — brief perspectives from simulated team roles (PM, architect, QA, etc.) to surface things you might not have considered
4. **Claude presents a draft** — you review and refine
5. **Output is saved** — a markdown document in the appropriate `docs/` subdirectory

Sessions are resilient. If Claude's context compacts mid-conversation (long sessions), CPM automatically saves and restores state. You won't lose progress.

## The Agent Roster

CPM includes 8 simulated team personas that provide perspectives during planning:

| Agent | Role | What they bring |
|-------|------|----------------|
| Jordan | Product Manager | User focus, business value, pushes back on unnecessary complexity |
| Margot | Software Architect | Systems thinking, trade-offs, boundary design |
| Bella | Senior Developer | Implementation reality, hidden complexity, practical concerns |
| Priya | UX Designer | User empathy, interaction quality, simplicity |
| Tomas | QA Engineer | Edge cases, testability, "what could go wrong?" |
| Sable | DevOps Engineer | Deployment, monitoring, operational concerns |
| Elli | Technical Writer | Clarity, naming, documentation quality |
| Ren | Scrum Master | Process, delivery, scope management |

These personas appear automatically at relevant points — you don't need to invoke them. They add 1-2 sentences each, just enough to surface blind spots without slowing you down.

To customise the roster for your project, create `docs/agents/roster.yaml` (this replaces the defaults entirely).

## The Library System

If your project has reference documents — coding standards, architecture decisions, API contracts, business rules — you can import them into CPM's library:

```
/cpm:library docs/coding-standards.md
/cpm:library https://example.com/api-spec
```

This stores them in `docs/library/` with YAML front-matter that tags which skills should reference them. When you run `/cpm:spec`, it picks up architecture constraints. When `/cpm:do` implements a task, it reads relevant coding standards. The right context reaches the right skill automatically.

## File Structure

CPM creates documents in `docs/` subdirectories:

```
docs/
├── plans/              # Problem briefs from /cpm:discover
├── briefs/             # Product briefs from /cpm:brief
├── architecture/       # ADRs from /cpm:architect
├── specifications/     # Specs from /cpm:spec
├── epics/              # Epic docs from /cpm:epics
├── reviews/            # Review files from /cpm:review
├── retros/             # Retro files from /cpm:retro
├── communications/     # Presentations from /cpm:present
├── library/            # Reference docs from /cpm:library
├── templates/          # Project-level template overrides
└── archive/            # Archived planning artifacts
```

All files are markdown. They're designed to be committed to your repo and read by anyone on the team.

## Practical Example: Adding Multi-Tenancy

Here's what a full pipeline looks like for a non-trivial feature:

**1. Discover the problem**
```
/cpm:discover I want to add multi-tenancy to our app
```
Claude asks why, who it's for, how it's solved today, what success looks like, and what constraints exist. Output: `docs/plans/01-plan-multi-tenancy.md`

**2. Define the product**
```
/cpm:brief docs/plans/01-plan-multi-tenancy.md
```
Claude explores vision, value propositions, features, and user journeys. Output: `docs/briefs/01-brief-multi-tenancy.md`

**3. Make architecture decisions**
```
/cpm:architect docs/briefs/01-brief-multi-tenancy.md
```
Claude identifies key decisions (e.g. "how to isolate tenant data"), explores options and trade-offs for each, and captures them as ADRs. Output: `docs/architecture/01-adr-tenant-isolation.md`, etc.

**4. Write requirements**
```
/cpm:spec docs/briefs/01-brief-multi-tenancy.md
```
Claude builds prioritised requirements, references existing ADRs for architecture sections. Output: `docs/specifications/01-spec-multi-tenancy.md`

**5. Break into epics**
```
/cpm:epics docs/specifications/01-spec-multi-tenancy.md
```
Claude creates epic docs with stories, acceptance criteria, and tasks. Output: `docs/epics/01-epic-tenant-setup.md`, etc.

**6. (Optional) Review before implementing**
```
/cpm:review docs/epics/01-epic-tenant-setup.md
```
Agents challenge the epic. Findings are severity-tagged. Optional autofix generates remediation tasks.

**7. Execute**
```
/cpm:do
```
Claude picks up the next unblocked task, implements it, verifies acceptance criteria, updates the epic doc, and moves to the next task. Repeat until done.

**8. Retrospective**
```
/cpm:retro
```
Claude reads the completed epic, synthesises observations from execution, and produces a retro file that feeds into the next planning cycle.

## Tips

- **You can start anywhere.** The pipeline is a suggestion, not a requirement. Jump to whatever skill matches where you are.
- **Pass file paths as arguments.** Most skills accept a file path: `/cpm:spec docs/briefs/01-brief-auth.md`. If you don't pass one, Claude will auto-discover available artifacts.
- **Use `/cpm:pivot` to change course.** Don't start over — amend the existing artifact and cascade changes downstream.
- **Template overrides** let you customise the output format for presentational templates (briefs, ADRs, communications). Run `/cpm:templates` to explore.
- **Commit your docs.** Planning artifacts in the repo mean the whole team can see what was decided and why.
