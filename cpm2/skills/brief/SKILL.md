---
name: cpm2:brief
description: Facilitated product ideation. Takes a problem brief as input, explores solution approaches, and produces a product brief artifact with vision, value propositions, key features, differentiation, and user journey narratives. Triggers on "/cpm2:brief".
---

# Facilitated Product Ideation

Transform a problem brief into a product brief through guided conversation. Each phase uses AskUserQuestion to let the user control pace and direction. The product brief captures *what* we're building and *why* this approach — bridging problem discovery and requirements specification.

## Input

Check for input in this order:

1. If `$ARGUMENTS` references a file path, read that file as the starting context.
2. If `$ARGUMENTS` contains a description, use that as the starting context.
3. If neither, look for problem briefs in `docs/plans/`:
   a. **Glob** `docs/plans/[0-9]*-plan-*.md` to find all problem briefs.
   b. If only one exists, ask the user if they want to use it.
   c. If multiple exist, present them with AskUserQuestion — show each brief's title and date.
   d. If none exist, ask the user to describe the product they want to explore.
4. If no input resolved, ask the user to describe their product idea.

## Process

Work through these phases **one at a time**. Complete each phase before moving to the next. Use AskUserQuestion for every gate — present only one phase of questions per turn.

**State tracking**: Create the progress file before Phase 1 and update it after each phase completes. See State Management below for the format and rationale. Delete the file once the final brief has been saved.

### Retro Check (Startup)

Follow the shared **Retro Awareness** procedure before beginning Phase 1.

**Retro incorporation** (this skill):
- **Patterns worth reusing**: Inform Phase 2 (Solution Approaches) — proven approaches from past work belong in the candidate set, not just net-new ideas.
- **Codebase discoveries**: Inform Phase 6 (Differentiation) — surfaced limitations or strengths in existing implementation shape what this product can credibly claim against alternatives.
- **Scope surprises**: Inform Phase 5 (Key Features) — categories that ran larger or smaller than expected last time suggest where this brief should be sharper about essential vs. enhancing.
- **Criteria gaps**: Inform Phase 4 (Value Propositions) — vague or missed value claims from past rounds become testable, concrete claims this round.

### Roster Loading (Startup)

Follow the shared **Roster Loading** procedure (from the CPM Shared Skill Conventions loaded at session start). The roster is needed for Perspectives in Phases 2 and 5.

### Library Check (Startup)

Follow the shared **Library Check** procedure with scope keyword `brief`. Deep-read selectively during ideation phases — e.g. reading market research when discussing differentiation, or architecture docs when exploring technical feasibility of approaches.

### Template Hint (Startup)

After startup checks and before Phase 1, display the template hint:

> Using default template. To customise, place your template at `docs/templates/brief.md`.

If a project-level override exists at `docs/templates/brief.md`, read it and use that format for the output artifact instead of the embedded default. Full replacement — no merging.

### Phase 1: Problem Recap

Briefly summarise the problem from the input (problem brief or description). Confirm understanding with the user. If starting from a problem brief, this should be quick — just verify the problem statement is still accurate and nothing has changed since discovery.

Questions to explore:
- Is this problem statement still accurate?
- Has anything changed since discovery?
- Any new constraints or context?

### Phase 2: Solution Approaches

Explore different approaches to solving the problem. Keep the field open at this stage — present 2-4 distinct approaches and discuss their trade-offs. Each approach should be a plausible path, not a strawman.

For each approach, consider:
- What would this look like in practice?
- What are the strengths and risks?
- How does it align with the constraints from discovery?

Use AskUserQuestion to present the approaches and let the user discuss, combine, or refine them. The goal is to converge on a direction, not lock in every detail.

**Perspectives**: After presenting approaches, follow the shared **Perspectives** procedure. Select 2-3 agents from the loaded roster whose expertise is relevant — e.g. the Product Manager on user impact, the Software Architect on technical feasibility, or the UX Designer on interaction implications.

### Phase 3: Vision

Frame the product vision based on the chosen approach. The vision should be a concise statement of what the product is, who it's for, and why it matters. Not a tagline — a clear articulation of intent that can guide decisions downstream.

Questions to explore:
- In one paragraph, what is this product and why does it exist?
- What future does this product enable?
- What would success look like in 6-12 months?

Present a draft vision statement and refine with the user.

### Phase 4: Value Propositions

Identify the core value the product delivers to its users. Value propositions answer "why would someone use this instead of the alternative?" Focus on outcomes, not features.

Questions to explore:
- What's the primary value users get?
- What pain does this eliminate or reduce?
- What does this make possible that wasn't before?

Present 2-4 value propositions and refine with the user. Each should be concrete and testable — not generic promises.

### Phase 5: Key Features

Identify the features that deliver the value propositions. Each feature should trace back to at least one value proposition. This is the "what does it actually do?" phase — concrete capabilities, not abstract concepts.

Questions to explore:
- What features are essential to deliver the core value?
- What's the minimum set of features for the first iteration?
- Which features differentiate this from alternatives?

Present a feature list grouped by priority (essential vs. enhancing). Refine with the user.

**Perspectives**: After features are drafted, follow the shared **Perspectives** procedure. Select 2-3 agents from the loaded roster whose expertise is relevant — e.g. the Senior Developer on implementation complexity, the QA Engineer on testability, or the Product Manager on priority.

### Phase 6: Differentiation

Articulate what makes this product different from existing alternatives. Differentiation can be in approach, scope, audience, experience, or technology — not just features.

Questions to explore:
- What exists today that solves a similar problem?
- How is this approach fundamentally different?
- What would be hard for an alternative to replicate?

Present a differentiation analysis and refine with the user. Be honest about where alternatives are stronger — credible differentiation acknowledges trade-offs.

### Phase 7: User Journeys

Describe 2-3 narrative user journeys that illustrate how key personas interact with the product. Each journey should walk through a concrete scenario from trigger to outcome, showing how the product fits into the user's world.

For each journey:
- Who is the user? (persona, context)
- What triggers them to use the product?
- What do they do? (steps, not screens)
- What outcome do they achieve?

Present draft journeys and refine with the user. Journeys should feel like stories, not flowcharts.

### Phase 8: Summary

Produce the product brief document. Present it to the user for confirmation using AskUserQuestion before saving.

After confirmation, suggest next steps:
- `/cpm2:architect` to explore architecture and produce ADRs (recommended for non-trivial products)
- `/cpm2:spec` to jump straight to requirements (for simpler products or when architecture is already clear)

## Output

Save the product brief to `docs/briefs/{nn}-brief-{slug}.md` in the current project.

- `{nn}` is assigned by the shared **Numbering** procedure (from the CPM Shared Skill Conventions loaded at session start).
- `{slug}` is a short kebab-case name derived from the product (e.g., `planning-plugin`, `booking-platform`).

Create the `docs/briefs/` directory if it doesn't exist.

Use this format:

```markdown
# Product Brief: {Title}

**Date**: {today's date}
**Source**: {path to problem brief used as input, or "direct input"}

## Vision

{Product vision — what this product is, who it's for, and why it matters. A clear articulation of intent, not a tagline.}

## Value Propositions

{2-4 concrete, testable value propositions. Each answers "why would someone use this instead of the alternative?"}

1. **{Value prop title}** — {Description focused on user outcome}
2. **{Value prop title}** — {Description focused on user outcome}

## Key Features

### Essential
{Features required to deliver the core value propositions}

- **{Feature name}** — {What it does and which value proposition it serves}

### Enhancing
{Features that strengthen the product but aren't required for first iteration}

- **{Feature name}** — {What it does and which value proposition it serves}

## Differentiation

{What makes this product different from existing alternatives. Honest assessment — acknowledges where alternatives are stronger.}

### Compared to {Alternative 1}
{How this approach differs}

### Compared to {Alternative 2}
{How this approach differs}

## User Journeys

### Journey 1: {Title}
**Persona**: {Who — role, context, technical level}
**Trigger**: {What prompts them to use the product}
**Steps**: {What they do — narrative, not a flowchart}
**Outcome**: {What they achieve}

### Journey 2: {Title}
**Persona**: {Who}
**Trigger**: {What prompts them}
**Steps**: {What they do}
**Outcome**: {What they achieve}
```

After saving, tell the user the document path.

## Arguments

If `$ARGUMENTS` is provided, use it as the starting context for Phase 1 instead of asking from scratch. Still confirm understanding with the user before proceeding.

## State Management

Maintain `docs/plans/.cpm-progress-{session_id}.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-conversation.

Follow the shared **Progress File Management** procedure.

**Lifecycle**:
- **Create**: before starting Phase 1 (ensure `docs/plans/` exists).
- **Update**: after each phase completes.
- **Delete**: only after the final brief has been saved and confirmed written.

**Format**:

```markdown
# CPM Session State

**Skill**: cpm2:brief
**Phase**: {N} of 8 — {Phase Name}
**Output target**: docs/briefs/{nn}-brief-{slug}.md

## Completed Phases

### Phase 1: Problem Recap
{Concise summary — problem statement, any changes from original brief}

### Phase 2: Solution Approaches
{Concise summary — approaches considered, chosen direction, key trade-offs}

### Phase 3: Vision
{The vision statement as drafted}

### Phase 4: Value Propositions
{List of value propositions}

### Phase 5: Key Features
{Feature list with priorities}

### Phase 6: Differentiation
{Key differentiators}

### Phase 7: User Journeys
{Journey summaries — persona, trigger, outcome for each}

{...include only completed phases...}

## Next Action
{What to ask or do next in the facilitation}
```

The "Completed Phases" section grows as phases complete. Each summary should capture the user's key decisions and answers in 2-4 sentences — enough for seamless continuation, not a transcript.

The "Next Action" field tells the post-compaction context exactly where to pick up.

## Guidelines

- **Facilitate, stay conversational.** These are conversations, not forms.
- **Build on answers.** Each question should respond to what the user just said.
- **Skip what's obvious.** If the input brief already covers a phase, acknowledge it and move on.
- **Stay curious.** Ask follow-up questions when answers are vague or assumptions seem risky.
- **One phase at a time.** Present only one phase of questions per turn.
- **Product, not project.** Focus on what the product is and why it matters — not timelines, team structure, or delivery planning.
- **Concrete over abstract.** Value propositions should be testable, features should be describable, differentiation should be honest.
