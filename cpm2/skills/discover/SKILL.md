---
name: cpm2:discover
description: Facilitated problem discovery. Understand the problem before proposing solutions. Produces a problem brief through guided conversation. Use when starting a new product, complex feature, or any work where the problem isn't well-defined yet. Triggers on "/cpm2:discover".
---

# Facilitated Problem Discovery

Guide the user through understanding their problem before jumping to solutions. Each phase uses AskUserQuestion to let the user control pace and direction.

## Process

Work through these phases **one at a time**. Complete each phase before moving to the next. Use AskUserQuestion for every gate — present only one phase of questions per turn.

**State tracking**: Create the progress file before Phase 1 and update it after each phase completes. See State Management below for the format and rationale. Delete the file once the final brief has been saved.

### Retro Check (Startup)

Follow the shared **Retro Awareness** procedure before beginning Phase 1.

**Retro incorporation** (this skill):
- **Scope surprises**: Inform Phase 2 (problem boundaries) — past stories that ran larger or smaller than expected suggest the problem definition needs sharper edges.
- **Criteria gaps**: Inform Phase 3 (success criteria) — categories the previous round missed should be probed explicitly this time.
- **Codebase discoveries**: Inform Phase 4 (constraints) — surfaced limitations and patterns are real constraints, not optional context.
- **Testing gaps**: Inform Phase 3 acceptance criteria framing — vague criteria from last round become concrete this round.

### Roster Loading (Startup)

Follow the shared **Roster Loading** procedure (from the CPM Shared Skill Conventions loaded at session start). The roster is needed for Perspectives in Phases 1 and 5.

### Library Check (Startup)

Follow the shared **Library Check** procedure with scope keyword `discover`. Deep-read selectively during discovery phases — e.g. reading an architecture doc when discussing constraints, or a glossary when clarifying terminology.

### Template Hint (Startup)

After startup checks and before Phase 1, display:

> Output format is fixed (used by downstream skills). Run `/cpm2:templates preview discover` to see the format.

### Codebase Grounding (Startup)

Before facilitating discovery, explore the existing codebase to ground the conversation in what already exists:

1. Use Glob and Grep to survey the project structure — key directories, configuration files, and existing code patterns.
2. Read key files to understand the current implementation state, technology choices, and domain model.
3. Carry these findings into all phases — Phase 3 (Current State) benefits most directly, but codebase context informs every phase from problem framing to constraint identification.

If the project has no existing codebase (greenfield), note that and proceed. For projects with code, grounding ensures discovery builds on real technical context rather than assumptions.

### Phase 1: Why

Ask what the user is trying to accomplish and why it matters. Understand the motivation, not just the feature request.

Questions to explore:
- What problem are you trying to solve?
- Why does this matter now?
- What happens if we don't solve this?

**Perspectives**: After the user describes their problem, before moving to Phase 2, follow the shared **Perspectives** procedure. Select 2-3 agents from the loaded roster whose expertise is relevant — e.g. the Product Manager to reframe the problem in terms of user value, the Software Architect to flag technical implications, or the UX Designer to highlight user experience concerns.

### Phase 2: Who

Identify target users and their needs.

Questions to explore:
- Who will use this?
- What are they trying to accomplish?
- How technical are they?

### Phase 3: Current State

Understand how this is solved today.

Questions to explore:
- How is this handled currently?
- What's broken or missing about the current approach?
- Are there existing tools, code, or workarounds in play?

If there's an existing codebase to explore, use Read, Glob, and Grep to understand the current state before asking questions.

### Phase 4: Success Criteria

Define what "done" looks like.

Questions to explore:
- How will we know this works?
- What does the happy path look like?
- Are there measurable outcomes?

### Phase 5: Constraints

Surface technical, business, and timeline constraints.

Questions to explore:
- Any technical constraints (language, framework, infrastructure)?
- Business constraints (budget, timeline, compliance)?
- What's explicitly out of scope?

**Perspectives**: Before finalising constraints, follow the shared **Perspectives** procedure. Select 2-3 agents from the loaded roster whose expertise is relevant — e.g. the Software Architect on scalability concerns, the DevOps Engineer on deployment constraints, or the QA Engineer on testability challenges.

### Phase 6: Summary

Produce a problem brief document. Render the full brief in the message body, then use AskUserQuestion as a short gate (e.g. "Approve this brief?" with options `Approve` / `Request changes` / `Stop`) before saving. See the shared **Gate Presentation** convention.

## Output

Save the brief to `docs/plans/{nn}-plan-{slug}.md` in the current project.

- `{nn}` is assigned by the shared **Numbering** procedure (from the CPM Shared Skill Conventions loaded at session start).
- `{slug}` is a short kebab-case name derived from the problem (e.g., `user-onboarding`).

Create the `docs/plans/` directory if it doesn't exist.

Use this format:

```markdown
# Problem Brief: {Title}

**Date**: {today's date}

## Why
{Motivation and importance}

## Who
{Target users and their needs}

## Current State
{How this is solved today, what's broken or missing}

## Success Criteria
{How we'll know this works}

## Constraints
{Technical, business, and timeline constraints}

## Scope Boundaries
{What's explicitly in and out of scope}
```

After saving, suggest next steps:
- `/cpm2:brief` to explore product ideation — vision, value propositions, and key features (recommended for most problems)
- `/cpm2:spec` to jump straight to requirements if the solution approach is already clear
- `/plan` (native plan mode) if the scope is small enough to skip planning artifacts entirely

## Arguments

If `$ARGUMENTS` is provided, use it as the starting context for Phase 1 instead of asking from scratch. Still confirm understanding with the user before proceeding.

## State Management

Follow the shared **Progress File Management** procedure.

**Lifecycle**:
- **Create**: before starting Phase 1 (ensure `docs/plans/` exists).
- **Update**: after each phase completes.
- **Delete**: only after the final brief has been saved and confirmed written.

**Format**:

```markdown
# CPM Session State

**Skill**: cpm2:discover
**Phase**: {N} of 6 — {Phase Name}
**Output target**: docs/plans/{nn}-plan-{slug}.md

## Completed Phases

### Phase 1: Why
{Concise summary of the user's answers — motivation, importance, consequences of inaction}

### Phase 2: Who
{Concise summary — target users, their goals, technical level}

{...continue for each completed phase...}

## Next Action
{What to ask or do next in the facilitation}
```

The "Completed Phases" section grows as phases complete. Each summary should capture the user's key decisions and answers in 2-4 sentences — enough for seamless continuation, not a transcript.

The "Next Action" field tells the post-compaction context exactly where to pick up.

## Guidelines

- **Facilitate, stay conversational.** These are conversations, not forms.
- **Build on answers.** Each question should respond to what the user just said.
- **Skip what's obvious.** If the user's initial description already covers a phase, acknowledge it and move on.
- **Stay curious.** Ask follow-up questions when answers are vague or assumptions seem risky.
- **One phase at a time.** Present only one phase of questions per turn.
