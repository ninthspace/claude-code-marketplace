---
name: cpm:discover
description: Facilitated problem discovery. Understand the problem before proposing solutions. Produces a problem brief through guided conversation. Use when starting a new product, complex feature, or any work where the problem isn't well-defined yet. Triggers on "/cpm:discover".
---

# Facilitated Problem Discovery

Guide the user through understanding their problem before jumping to solutions. Each phase uses AskUserQuestion to let the user control pace and direction.

## Process

Work through these phases **one at a time**. Complete each phase before moving to the next. Use AskUserQuestion for every gate — never dump multiple phases of questions at once.

**State tracking**: Before starting Phase 1, create the progress file (see State Management below). Each phase below ends with a mandatory progress file update — do not skip it. After saving the final brief, delete the file.

### Phase 1: Why

Ask what the user is trying to accomplish and why it matters. Understand the motivation, not just the feature request.

Questions to explore:
- What problem are you trying to solve?
- Why does this matter now?
- What happens if we don't solve this?

**Perspectives**: After the user describes their problem, before moving to Phase 2, briefly present 2-3 agent perspectives on the problem statement. Load the agent roster (see Perspectives below) and have relevant agents weigh in — e.g. the PM might reframe the problem in terms of user value, the architect might flag technical implications, or the UX designer might highlight user experience concerns. Keep each perspective to 1-2 sentences. Format: `{icon} **{name}**: {perspective}`. This enriches the discovery without slowing it down.

**Update progress file now** — write the full `.cpm-progress.md` with Phase 1 summary before continuing.

### Phase 2: Who

Identify target users and their needs.

Questions to explore:
- Who will use this?
- What are they trying to accomplish?
- How technical are they?

**Update progress file now** — write the full `.cpm-progress.md` with Phase 2 summary before continuing.

### Phase 3: Current State

Understand how this is solved today.

Questions to explore:
- How is this handled currently?
- What's broken or missing about the current approach?
- Are there existing tools, code, or workarounds in play?

If there's an existing codebase to explore, use Read, Glob, and Grep to understand the current state before asking questions.

**Update progress file now** — write the full `.cpm-progress.md` with Phase 3 summary before continuing.

### Phase 4: Success Criteria

Define what "done" looks like.

Questions to explore:
- How will we know this works?
- What does the happy path look like?
- Are there measurable outcomes?

**Update progress file now** — write the full `.cpm-progress.md` with Phase 4 summary before continuing.

### Phase 5: Constraints

Surface technical, business, and timeline constraints.

Questions to explore:
- Any technical constraints (language, framework, infrastructure)?
- Business constraints (budget, timeline, compliance)?
- What's explicitly out of scope?

**Perspectives**: Before finalising constraints, have 2-3 agents weigh in on what constraints they see from their domain. The architect might flag scalability concerns, DevOps might raise deployment constraints, QA might identify testability challenges. This helps surface constraints the user might not have considered. Keep each perspective to 1-2 sentences. Format: `{icon} **{name}**: {perspective}`.

**Update progress file now** — write the full `.cpm-progress.md` with Phase 5 summary before continuing.

### Phase 6: Summary

Produce a problem brief document. Present it to the user for confirmation using AskUserQuestion before saving.

## Output

Save the brief to `docs/plans/{nn}-plan-{slug}.md` in the current project.

- `{nn}` is a zero-padded auto-incrementing number. Use the Glob tool to list existing `docs/plans/[0-9]*-plan-*.md` files, find the highest number, and increment by 1. If none exist, start at `01`.
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

After saving, suggest next steps: `/cpm:spec` to build requirements, or `/plan` (native plan mode) if the scope is clear enough to jump straight to implementation planning.

## Arguments

If `$ARGUMENTS` is provided, use it as the starting context for Phase 1 instead of asking from scratch. Still confirm understanding with the user before proceeding.

## State Management

Maintain `docs/plans/.cpm-progress.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-conversation.

**Create** the file before starting Phase 1 (ensure `docs/plans/` exists). **Update** it after each phase completes. **Delete** it after saving the final brief.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:discover
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

## Perspectives

Some phases include a **Perspectives** block where agent personas briefly weigh in. To use perspectives:

1. Load the agent roster: check `docs/agents/roster.yaml` in the project first, then fall back to the plugin's `agents/roster.yaml` (at `../../agents/roster.yaml` relative to this file).
2. Select 2-3 agents whose expertise is relevant to the current phase and topic.
3. Each agent provides a brief perspective (1-2 sentences) in character, using the format: `{icon} **{displayName}**: {perspective}`.
4. Perspectives should add value — surface blind spots, challenge assumptions, or highlight concerns the user might not have considered. If a perspective would just echo what the user already said, skip it.
5. Present perspectives as a natural part of the facilitation, not as a separate section. Weave them in after the user's answer and before moving to the next phase.

If the roster cannot be loaded, skip perspectives and continue the facilitation normally.

## Guidelines

- **Facilitate, don't interrogate.** These are conversations, not forms.
- **Build on answers.** Each question should respond to what the user just said.
- **Skip what's obvious.** If the user's initial description already covers a phase, acknowledge it and move on.
- **Stay curious.** Ask follow-up questions when answers are vague or assumptions seem risky.
- **One phase at a time.** Never combine phases into a single question block.
