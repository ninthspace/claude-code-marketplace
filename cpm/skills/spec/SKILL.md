---
name: cpm:spec
description: Build a structured requirements and architecture specification through facilitated conversation. Takes a problem brief or user description as input and produces a spec document with functional requirements, architecture decisions, and scope boundaries. Triggers on "/cpm:spec".
---

# Requirements & Architecture Specification

Build a structured spec through facilitated conversation. Each section uses AskUserQuestion to gate progression — never dump everything at once.

## Input

Check for input in this order:

1. If `$ARGUMENTS` references a file path, read that file as the starting context.
2. If `$ARGUMENTS` contains a description, use that as the starting context.
3. If neither, look for product briefs first, then problem briefs:
   a. **Glob** `docs/briefs/[0-9]*-brief-*.md` to find product briefs. If found, present them with AskUserQuestion — show each brief's title and date. Product briefs are the preferred input since they already contain vision, value propositions, and key features.
   b. If no product briefs, look for the most recent `docs/plans/[0-9]*-plan-*.md` file and ask the user if they want to use it.
4. If no briefs exist, ask the user to describe what they want to build.

### ADR Discovery (Startup)

After resolving the input source and before starting Section 1, discover existing Architecture Decision Records:

1. **Glob** `docs/architecture/[0-9]*-adr-*.md`. If no files found or directory doesn't exist, skip silently — the spec will facilitate architecture decisions from scratch in Section 4.
2. If ADRs exist, read each one and present a summary to the user: "Found {N} existing ADRs: {titles}. I'll reference these during architecture decisions (Section 4) and only facilitate new decisions for gaps."
3. Store the ADR paths and summaries for use in Section 4.

**Graceful degradation**: If ADRs don't exist, Section 4 works as before — facilitating architecture decisions from scratch. The spec skill must work without `cpm:architect` having been run.

## Process

Work through these sections **one at a time**. Use AskUserQuestion for every gate.

**State tracking**: Before starting Section 1, create the progress file (see State Management below). Each section below ends with a mandatory progress file update — do not skip it. After saving the final spec, delete the file.

### Retro Check (Startup)

Before beginning Section 1, check for recent retro files using Glob: `docs/retros/[0-9]*-retro-*.md`. If one or more retro files exist:

1. Read the most recent retro file.
2. Present a brief summary of its key recommendations to the user.
3. Use AskUserQuestion to ask: "A recent retro has recommendations that may be relevant. Incorporate as additional context?"
   - **Yes, incorporate** — Treat the retro's recommendations as additional context throughout the spec sections (especially functional requirements and scope)
   - **No, skip** — Proceed normally without retro context

If no retro files exist, skip this check silently and proceed to the Library Check.

### Library Check (Startup)

After the Retro Check and before Section 1, check the project library for reference documents:

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip silently and proceed to Section 1.
2. **Read front-matter** of each file found (the YAML block between `---` delimiters, typically the first ~10 lines). Filter to documents whose `scope` array includes `spec` or `all`.
3. **Report to user**: "Found {N} library documents relevant to this spec: {titles}. I'll reference these as context." If none match the scope filter, skip silently.
4. **Deep-read selectively** during spec sections when a library document's content is relevant — especially during architecture decisions (Section 4) where architecture docs and coding standards directly inform choices, and during scope boundaries (Section 5) where existing constraints may affect what's feasible.

**Graceful degradation**: If any library document has malformed or missing front-matter, fall back to using the filename as context. Never block the spec process due to a malformed library document.

**Compaction resilience**: Include library scan results (files found, scope matches) in the progress file so post-compaction continuation doesn't re-scan.

### Template Hint (Startup)

After startup checks and before Section 1, display:

> Output format is fixed (used by downstream skills). Run `/cpm:templates preview spec` to see the format.

### Section 1: Problem Recap

Briefly summarise the problem from the input (brief or description). Confirm understanding with the user. If starting from a brief, this should be quick — just verify nothing has changed.

**Update progress file now** — write the full `.cpm-progress.md` with Section 1 summary before continuing.

### Section 2: Functional Requirements

Facilitate conversation about what the system must do. Use MoSCoW prioritisation:

- **Must have**: Core functionality without which the system fails
- **Should have**: Important but the system works without them
- **Could have**: Nice-to-haves if time allows
- **Won't have**: Explicitly out of scope for this iteration

Present a draft list and refine with the user. Don't try to capture everything at once — iterate.

**Update progress file now** — write the full `.cpm-progress.md` with Section 2 summary before continuing.

### Section 3: Non-Functional Requirements

Only cover what's relevant to this project. Skip anything that doesn't apply.

Areas to consider:
- Performance (response times, throughput)
- Security (auth, data protection, access control)
- Scalability (expected load, growth)
- Reliability (uptime, error handling, data integrity)
- Usability (accessibility, device support)

**Update progress file now** — write the full `.cpm-progress.md` with Section 3 summary before continuing.

### Section 4: Architecture Decisions

If ADRs were discovered during the ADR Discovery startup check, this section references them rather than doing architecture from scratch.

**When ADRs exist**: Present the existing ADRs as context for the spec. For each ADR, summarise the decision, rationale, and consequences. Ask the user if the existing decisions still hold for this spec's scope. Then identify any **gaps** — architecture areas needed for this spec that aren't covered by existing ADRs. Only facilitate new decisions for gaps.

**When no ADRs exist**: Facilitate architecture decisions from scratch, as before. For each decision, capture:
- What was chosen
- Why (brief rationale)
- What alternatives were considered

If there's an existing codebase, explore it first with Read, Glob, and Grep to understand existing patterns and constraints before proposing architecture.

Areas to cover as relevant:
- Tech stack / framework choices
- Data storage approach
- Key integrations
- Deployment model
- Major structural patterns

**Perspectives**: Before presenting each major architecture decision to the user (whether referencing an existing ADR or facilitating a new one), have 2-3 agents weigh in with competing trade-offs. The architect might advocate for one approach, the developer might flag implementation cost, DevOps might raise deployment concerns, and QA might highlight testability. Present these as brief agent perspectives (1-2 sentences each) using the format: `{icon} **{name}**: {perspective}`. This surfaces trade-offs the user should consider before deciding.

**Update progress file now** — write the full `.cpm-progress.md` with Section 4 summary before continuing.

### Section 5: Scope Boundary

Consolidate from the conversation:
- What's **in scope** for this iteration
- What's **explicitly out of scope**
- What's **deferred** to future iterations

**Perspectives**: Before finalising scope, have 2-3 agents weigh in on what should be in or out. The PM might push to keep scope tight for delivery, the architect might argue for including foundational work, and the developer might flag dependencies that force certain items in. Keep each perspective to 1-2 sentences. Format: `{icon} **{name}**: {perspective}`.

**Update progress file now** — write the full `.cpm-progress.md` with Section 5 summary before continuing.

### Section 6: Testing Strategy

Outline how the system will be verified. This section bridges the spec and implementation by making testability explicit.

- **Acceptance criteria mapping**: For each must-have functional requirement, confirm it has at least one testable acceptance criterion. Flag any requirements that are vague or untestable.
- **Integration boundaries**: If ADRs were discovered, identify the key integration boundaries between architectural components (e.g. API contracts, event schemas, data flows between services). These become the seams where integration tests should focus.
- **Unit testing**: Confirm that unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.

Present the testing strategy to the user and refine. This section should be lightweight — a checklist of what to test and where, not a full test plan.

**Update progress file now** — write the full `.cpm-progress.md` with Section 6 summary before continuing.

### Section 7: Review

Present the complete spec to the user for review. Use AskUserQuestion to confirm or request changes.

## Output

Save the spec to `docs/specifications/{nn}-spec-{slug}.md` in the current project.

- `{nn}` is a zero-padded auto-incrementing number. Use the Glob tool to list existing `docs/specifications/[0-9]*-spec-*.md` files, find the highest number, and increment by 1. If none exist, start at `01`.
- `{slug}` matches the brief slug if one was used as input, or is derived from the project name.

Create the `docs/specifications/` directory if it doesn't exist.

Use this format:

```markdown
# Spec: {Title}

**Date**: {today's date}
**Brief**: {link to brief if applicable}

## Problem Summary
{One-paragraph recap}

## Functional Requirements

### Must Have
- {requirement}

### Should Have
- {requirement}

### Could Have
- {requirement}

### Won't Have (this iteration)
- {item}

## Non-Functional Requirements
{Only sections that are relevant}

## Architecture Decisions

### {Decision Title}
**Choice**: {what was chosen}
**Rationale**: {why}
**Alternatives considered**: {what else was evaluated}

## Scope

### In Scope
- {item}

### Out of Scope
- {item}

### Deferred
- {item}

## Testing Strategy

### Acceptance Criteria Coverage
{Mapping of must-have requirements to their acceptance criteria — confirms each requirement is testable}

### Integration Boundaries
{Key integration points between architectural components, derived from ADRs if available}

### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
```

After saving, suggest next steps:
- `/cpm:epics` to break the spec into epic documents with stories and tasks (recommended)
- `/cpm:architect` to explore architecture first, if no ADRs exist yet and the system has non-trivial architectural decisions
- `/plan` (native plan mode) if the scope is small enough to skip planning artifacts entirely

## State Management

Maintain `docs/plans/.cpm-progress.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-conversation.

**Path resolution**: All paths in this skill are relative to the current Claude Code session's working directory. When calling Write, Glob, Read, or any file tool, construct the absolute path by prepending the session's primary working directory. Never write to a different project's directory or reuse paths from other sessions.

**Create** the file before starting Section 1 (ensure `docs/plans/` exists). **Update** it after each section completes. **Delete** it only after the final spec has been saved and confirmed written — never before. If compaction fires between deletion and a pending write, all session state is lost.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:spec
**Section**: {N} of 7 — {Section Name}
**Output target**: docs/specifications/{nn}-spec-{slug}.md
**Input source**: {path to brief or description used as input}

## Completed Sections

### Section 1: Problem Recap
{Concise summary — confirmed problem statement, any changes from brief}

### Section 2: Functional Requirements
{Concise summary — key must-haves, should-haves, won't-haves decided}

{...continue for each completed section...}

## Next Action
{What to ask or do next in the facilitation}
```

The "Completed Sections" section grows as sections complete. Each summary should capture the key decisions, requirements, and priorities in enough detail for seamless continuation — not a transcript, but enough that no question needs to be re-asked.

The "Next Action" field tells the post-compaction context exactly where to pick up.

## Perspectives

Some sections include a **Perspectives** block where agent personas briefly weigh in. To use perspectives:

1. Load the agent roster: check `docs/agents/roster.yaml` in the project first, then fall back to the plugin's `agents/roster.yaml` (at `../../agents/roster.yaml` relative to this file).
2. Select 2-3 agents whose expertise is relevant to the current section and topic.
3. Each agent provides a brief perspective (1-2 sentences) in character, using the format: `{icon} **{displayName}**: {perspective}`.
4. Perspectives should add value — surface trade-offs, challenge assumptions, or highlight concerns. If a perspective would just echo what's already been said, skip it.
5. Present perspectives as a natural part of the facilitation, woven in before the user makes a decision.

If the roster cannot be loaded, skip perspectives and continue the facilitation normally.

## Guidelines

- **Facilitate, don't prescribe.** Present options and trade-offs. Let the user decide.
- **Build on existing context.** If there's a brief or existing code, use it. Don't re-ask what's already known.
- **Stay practical.** Skip sections that don't add value for the project's scale.
- **One section at a time.** Complete each before moving on.
- **Match depth to complexity.** A small feature needs a lean spec. A new product needs more detail.
