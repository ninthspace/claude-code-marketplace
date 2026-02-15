---
name: cpm:brief
description: Facilitated product ideation. Takes a problem brief as input, explores solution approaches, and produces a product brief artifact with vision, value propositions, key features, differentiation, and user journey narratives. Triggers on "/cpm:brief".
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

Work through these phases **one at a time**. Complete each phase before moving to the next. Use AskUserQuestion for every gate — never dump multiple phases of questions at once.

**State tracking**: Before starting Phase 1, create the progress file (see State Management below). Each phase below ends with a mandatory progress file update — do not skip it. After saving the final brief, delete the file.

### Retro Check (Startup)

Before beginning Phase 1, check for recent retro files using Glob: `docs/retros/[0-9]*-retro-*.md`. If one or more retro files exist:

1. Read the most recent retro file.
2. Present a brief summary of its key recommendations to the user.
3. Use AskUserQuestion to ask: "A recent retro has recommendations that may be relevant. Incorporate into this ideation session?"
   - **Yes, incorporate** — Treat the retro's recommendations as additional context throughout the ideation phases
   - **No, start fresh** — Proceed normally without retro context

If no retro files exist, skip this check silently and proceed to the Library Check.

### Library Check (Startup)

After the Retro Check and before Phase 1, check the project library for reference documents:

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip silently and proceed to Phase 1.
2. **Read front-matter** of each file found (the YAML block between `---` delimiters, typically the first ~10 lines). Filter to documents whose `scope` array includes `brief` or `all`.
3. **Report to user**: "Found {N} library documents relevant to product ideation: {titles}. I'll reference these as context." If none match the scope filter, skip silently.
4. **Deep-read selectively** during ideation phases when a library document's content is relevant — e.g. reading market research when discussing differentiation, or architecture docs when exploring technical feasibility of approaches.

**Graceful degradation**: If any library document has malformed or missing front-matter, fall back to using the filename as context. Never block the ideation process due to a malformed library document.

**Compaction resilience**: Include library scan results (files found, scope matches) in the progress file so post-compaction continuation doesn't re-scan.

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

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Phase 1 summary before continuing.

### Phase 2: Solution Approaches

Explore different approaches to solving the problem. Don't converge on a single solution yet — present 2-4 distinct approaches and discuss their trade-offs. Each approach should be a plausible path, not a strawman.

For each approach, consider:
- What would this look like in practice?
- What are the strengths and risks?
- How does it align with the constraints from discovery?

Use AskUserQuestion to present the approaches and let the user discuss, combine, or refine them. The goal is to converge on a direction, not lock in every detail.

**Perspectives**: After presenting approaches, have 2-3 agents weigh in from their domain. The PM might evaluate user impact, the architect might flag technical feasibility, or the UX designer might highlight interaction implications. Keep each perspective to 1-2 sentences. Format: `{icon} **{name}**: {perspective}`.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Phase 2 summary before continuing.

### Phase 3: Vision

Frame the product vision based on the chosen approach. The vision should be a concise statement of what the product is, who it's for, and why it matters. Not a tagline — a clear articulation of intent that can guide decisions downstream.

Questions to explore:
- In one paragraph, what is this product and why does it exist?
- What future does this product enable?
- What would success look like in 6-12 months?

Present a draft vision statement and refine with the user.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Phase 3 summary before continuing.

### Phase 4: Value Propositions

Identify the core value the product delivers to its users. Value propositions answer "why would someone use this instead of the alternative?" Focus on outcomes, not features.

Questions to explore:
- What's the primary value users get?
- What pain does this eliminate or reduce?
- What does this make possible that wasn't before?

Present 2-4 value propositions and refine with the user. Each should be concrete and testable — not generic promises.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Phase 4 summary before continuing.

### Phase 5: Key Features

Identify the features that deliver the value propositions. Each feature should trace back to at least one value proposition. This is the "what does it actually do?" phase — concrete capabilities, not abstract concepts.

Questions to explore:
- What features are essential to deliver the core value?
- What's the minimum set of features for the first iteration?
- Which features differentiate this from alternatives?

Present a feature list grouped by priority (essential vs. enhancing). Refine with the user.

**Perspectives**: After features are drafted, have 2-3 agents weigh in. The developer might flag implementation complexity, the QA engineer might raise testability concerns, or the PM might challenge priority. Keep each perspective to 1-2 sentences. Format: `{icon} **{name}**: {perspective}`.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Phase 5 summary before continuing.

### Phase 6: Differentiation

Articulate what makes this product different from existing alternatives. Differentiation can be in approach, scope, audience, experience, or technology — not just features.

Questions to explore:
- What exists today that solves a similar problem?
- How is this approach fundamentally different?
- What would be hard for an alternative to replicate?

Present a differentiation analysis and refine with the user. Be honest about where alternatives are stronger — credible differentiation acknowledges trade-offs.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Phase 6 summary before continuing.

### Phase 7: User Journeys

Describe 2-3 narrative user journeys that illustrate how key personas interact with the product. Each journey should walk through a concrete scenario from trigger to outcome, showing how the product fits into the user's world.

For each journey:
- Who is the user? (persona, context)
- What triggers them to use the product?
- What do they do? (steps, not screens)
- What outcome do they achieve?

Present draft journeys and refine with the user. Journeys should feel like stories, not flowcharts.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Phase 7 summary before continuing.

### Phase 8: Summary

Produce the product brief document. Present it to the user for confirmation using AskUserQuestion before saving.

After confirmation, suggest next steps:
- `/cpm:architect` to explore architecture and produce ADRs (recommended for non-trivial products)
- `/cpm:spec` to jump straight to requirements (for simpler products or when architecture is already clear)

## Output

Save the product brief to `docs/briefs/{nn}-brief-{slug}.md` in the current project.

- `{nn}` is a zero-padded auto-incrementing number. Use the Glob tool to list existing `docs/briefs/[0-9]*-brief-*.md` files, find the highest number, and increment by 1. If none exist, start at `01`.
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

**Path resolution**: All paths in this skill are relative to the current Claude Code session's working directory. When calling Write, Glob, Read, or any file tool, construct the absolute path by prepending the session's primary working directory. Never write to a different project's directory or reuse paths from other sessions.

**Session ID**: The `{session_id}` in the filename comes from `CPM_SESSION_ID` — a unique identifier for the current Claude Code session, injected into context by the CPM hooks on startup and after compaction. Use this value verbatim when constructing the progress file path. If `CPM_SESSION_ID` is not present in context (e.g. hooks not installed), fall back to `.cpm-progress.md` (no session suffix) for backwards compatibility.

**Resume adoption**: When a session is resumed (`--resume`), `CPM_SESSION_ID` changes to a new value while the old progress file remains on disk. The hooks inject all existing progress files into context on startup — if one matches this skill's `**Skill**:` field but has a different session ID in its filename, adopt it:
1. Read the old file's contents (already visible in context from hook injection).
2. Write a new file at `docs/plans/.cpm-progress-{current_session_id}.md` with the same contents.
3. After the Write confirms success, delete the old file: `rm docs/plans/.cpm-progress-{old_session_id}.md`.
Do not attempt adoption if `CPM_SESSION_ID` is absent from context — the fallback path handles that case.

**Create** the file before starting Phase 1 (ensure `docs/plans/` exists). **Update** it after each phase completes. **Delete** it only after the final brief has been saved and confirmed written — never before. If compaction fires between deletion and a pending write, all session state is lost.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:brief
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
- **Skip what's obvious.** If the input brief already covers a phase, acknowledge it and move on.
- **Stay curious.** Ask follow-up questions when answers are vague or assumptions seem risky.
- **One phase at a time.** Never combine phases into a single question block.
- **Product, not project.** Focus on what the product is and why it matters — not timelines, team structure, or delivery planning.
- **Concrete over abstract.** Value propositions should be testable, features should be describable, differentiation should be honest.
