---
name: discover
description: Facilitated problem discovery. Understand the problem before proposing solutions. Produces a problem brief through guided conversation. Use when starting a new product, complex feature, or any work where the problem isn't well-defined yet. Triggers on "/discover".
---

# Facilitated Problem Discovery

Guide the user through understanding their problem before jumping to solutions. Each phase uses AskUserQuestion to let the user control pace and direction.

## Process

Work through these phases **one at a time**. Complete each phase before moving to the next. Use AskUserQuestion for every gate — never dump multiple phases of questions at once.

### Phase 1: Why

Ask what the user is trying to accomplish and why it matters. Understand the motivation, not just the feature request.

Questions to explore:
- What problem are you trying to solve?
- Why does this matter now?
- What happens if we don't solve this?

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

### Phase 6: Summary

Produce a problem brief document. Present it to the user for confirmation using AskUserQuestion before saving.

## Output

Save the brief to `docs/plans/{slug}.md` in the current project, where `{slug}` is a short kebab-case name derived from the problem (e.g., `user-onboarding.md`).

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

After saving, suggest next steps: `/spec` to build requirements, or `/plan` (native plan mode) if the scope is clear enough to jump straight to implementation planning.

## Arguments

If `$ARGUMENTS` is provided, use it as the starting context for Phase 1 instead of asking from scratch. Still confirm understanding with the user before proceeding.

## Guidelines

- **Facilitate, don't interrogate.** These are conversations, not forms.
- **Build on answers.** Each question should respond to what the user just said.
- **Skip what's obvious.** If the user's initial description already covers a phase, acknowledge it and move on.
- **Stay curious.** Ask follow-up questions when answers are vague or assumptions seem risky.
- **One phase at a time.** Never combine phases into a single question block.
