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

Before beginning Phase 1, check for recent retro files using Glob: `docs/retros/[0-9]*-retro-*.md`. If one or more retro files exist:

1. Read the most recent retro file.
2. Present a brief summary of its key recommendations to the user.
3. Use AskUserQuestion to ask: "A recent retro has recommendations that may be relevant. Incorporate into this discovery session?"
   - **Yes, incorporate** — Treat the retro's recommendations as additional context throughout the discovery phases
   - **No, start fresh** — Proceed normally without retro context

If no retro files exist, skip this check silently and proceed to the Library Check.

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

Produce a problem brief document. Present it to the user for confirmation using AskUserQuestion before saving.

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

Maintain `docs/plans/.cpm-progress-{session_id}.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-conversation.

**Path resolution**: All paths in this skill are relative to the current Claude Code session's working directory. When calling Write, Glob, Read, or any file tool, construct the absolute path by prepending the session's primary working directory. Always write to the current session's working directory only — cross-project or cross-session writes corrupt state.

**Session ID**: The `{session_id}` in the filename comes from `CPM_SESSION_ID` — a unique identifier for the current Claude Code session, injected into context by the CPM hooks on startup and after compaction. Use this value verbatim when constructing the progress file path. If `CPM_SESSION_ID` is not present in context (e.g. hooks not installed), fall back to `.cpm-progress.md` (no session suffix) for backwards compatibility.

**Resume adoption**: When a session is resumed (`--resume`) or context is cleared (`/clear`), `CPM_SESSION_ID` changes to a new value while the old progress file remains on disk. The hooks inject all existing progress files into context — if one matches this skill's `**Skill**:` field but has a different session ID in its filename, adopt it:
1. Read the old file's contents (already visible in context from hook injection).
2. Write a new file at `docs/plans/.cpm-progress-{current_session_id}.md` with the same contents.
3. After the Write confirms success, delete the old file: `rm docs/plans/.cpm-progress-{old_session_id}.md`.
Adoption requires `CPM_SESSION_ID` in context. When absent, the fallback path handles that case.

**Create** the file before starting Phase 1 (ensure `docs/plans/` exists). **Update** it after each phase completes. **Delete** it only after the final brief has been saved and confirmed written. If compaction fires between deletion and a pending write, all session state is lost.

**Also delete** `docs/plans/.cpm-compact-summary-{session_id}.md` if it exists — this companion file is written by the PostCompact hook and should be cleaned up alongside the progress file.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

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
