---
name: cpm:architect
description: Facilitated architecture exploration. Takes a product brief as input, identifies key architectural decisions derived from the product, explores trade-offs per decision, captures dependencies between decisions, and produces Architecture Decision Records (ADRs). Triggers on "/cpm:architect".
---

# Facilitated Architecture Exploration

Explore architectural decisions through guided conversation. Each decision is derived from the product's actual needs — not boilerplate. The skill produces Architecture Decision Records (ADRs) that capture context, options, trade-offs, and rationale for each key decision.

## Input

Check for input in this order:

1. If `$ARGUMENTS` references a file path, read that file as the starting context.
2. If `$ARGUMENTS` contains a description, use that as the starting context.
3. If neither, look for product briefs in `docs/briefs/`:
   a. **Glob** `docs/briefs/[0-9]*-brief-*.md` to find all product briefs.
   b. If only one exists, ask the user if they want to use it.
   c. If multiple exist, present them with AskUserQuestion — show each brief's title and date.
   d. If none exist, fall back to problem briefs in `docs/plans/`:
      - **Glob** `docs/plans/[0-9]*-plan-*.md`.
      - If found, ask the user if they want to use one.
      - If not found, ask the user to describe what they're building.
4. If no input resolved, ask the user to describe the system they want to explore architecturally.

## Process

Work through these phases **one at a time**. Complete each phase before moving to the next. Use AskUserQuestion for every gate — never dump multiple phases of questions at once.

**State tracking**: Before starting Phase 1, create the progress file (see State Management below). Each phase below ends with a mandatory progress file update — do not skip it. After saving the final ADRs, delete the file.

### Retro Check (Startup)

Before beginning Phase 1, check for recent retro files using Glob: `docs/retros/[0-9]*-retro-*.md`. If one or more retro files exist:

1. Read the most recent retro file.
2. Present a brief summary of its key recommendations to the user.
3. Use AskUserQuestion to ask: "A recent retro has recommendations that may be relevant. Incorporate into this architecture exploration?"
   - **Yes, incorporate** — Treat the retro's recommendations as additional context throughout the exploration
   - **No, start fresh** — Proceed normally without retro context

If no retro files exist, skip this check silently and proceed to the Library Check.

### Library Check (Startup)

After the Retro Check and before Phase 1, check the project library for reference documents:

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip silently and proceed to Phase 1.
2. **Read front-matter** of each file found (the YAML block between `---` delimiters, typically the first ~10 lines). Filter to documents whose `scope` array includes `architect` or `all`.
3. **Report to user**: "Found {N} library documents relevant to architecture exploration: {titles}. I'll reference these as context." If none match the scope filter, skip silently.
4. **Deep-read selectively** during exploration phases when a library document's content is relevant — especially architecture docs, infrastructure docs, or coding standards that constrain decisions.

**Graceful degradation**: If any library document has malformed or missing front-matter, fall back to using the filename as context. Never block the exploration process due to a malformed library document.

**Compaction resilience**: Include library scan results (files found, scope matches) in the progress file so post-compaction continuation doesn't re-scan.

### Template Hint (Startup)

After startup checks and before Phase 1, display the template hint:

> Using default template. To customise, place your template at `docs/templates/architect.md`.

If a project-level override exists at `docs/templates/architect.md`, read it and use that format for the output ADRs instead of the embedded default. Full replacement — no merging.

### Phase 1: Context & Codebase Exploration

Before proposing any architecture, understand what already exists. If there's an existing codebase:

1. Use Glob and Grep to explore the project structure, key directories, configuration files, and dependency manifests.
2. Read key files to understand existing patterns, frameworks, conventions, and infrastructure.
3. Summarise findings to the user: existing technology stack, patterns in use, deployment setup, and any architectural decisions already embedded in the code.

If there's no existing codebase (greenfield), note that and move on.

Also summarise the product context from the input (product brief or description) — the vision, key features, and constraints that will drive architectural decisions.

Confirm understanding with the user.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Phase 1 summary before continuing.

### Phase 2: Identify Architectural Decisions

Analyse the product brief and codebase findings to identify the key architectural decisions that need to be made. Each decision should be **derived from the product's actual needs** — not generic boilerplate like "should we use microservices?"

For each decision, capture:
- **What** needs to be decided (concise label)
- **Why** this decision matters for this specific product
- **Which features or requirements** drive it

Present the decision list to the user with AskUserQuestion. Refine — they may add decisions you missed or remove ones that don't apply. Aim for 3-8 decisions for a typical product. Don't force decisions that aren't genuinely needed.

**Anti-pattern**: Decisions like "choose a database" or "pick a framework" without product-specific context are boilerplate. Instead: "How to handle booking availability with concurrent access" or "Where to run image processing given the latency requirements."

**Perspectives**: After identifying decisions, have 2-3 agents weigh in. The architect might flag missing structural decisions, the DevOps engineer might raise operational concerns, or the developer might question whether a decision is premature. Keep each perspective to 1-2 sentences. Format: `{icon} **{name}**: {perspective}`.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Phase 2 summary before continuing.

### Phase 3: Explore Trade-offs (per decision)

For each identified decision, explore options and trade-offs. This phase iterates — work through one decision at a time with the user.

For each decision:

1. **Present 2-4 options** — each a plausible approach, not strawmen.
2. **Analyse trade-offs** across these dimensions:
   - **Complexity**: How much does this add to the system's cognitive load and maintenance burden?
   - **Scalability**: How does this behave under growth — users, data, traffic?
   - **Team capability**: Does the team have experience with this approach? What's the learning curve?
   - **Operational cost**: What does this cost to run, monitor, and maintain in production?
   - **Time to market**: How does this affect delivery speed for the first iteration?
3. **Identify the recommendation** — which option balances the trade-offs best for this product, and why.
4. **Capture dependencies** — does this decision constrain or depend on other decisions? Note these explicitly.

Use AskUserQuestion after each decision to confirm the chosen option and rationale before moving to the next.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` after each decision is resolved.

### Phase 4: Operational Architecture

Give operational concerns first-class treatment rather than treating them as an afterthought. Explore:

- **Deployment**: How will this be deployed? What environments are needed?
- **Monitoring & Observability**: What needs to be monitored? How will you know when something is wrong?
- **Failure modes**: What happens when components fail? What's the recovery strategy?
- **Data lifecycle**: Backups, retention, migration strategy.
- **Security boundaries**: Authentication, authorisation, data protection.

Not every concern applies to every product. Skip what's not relevant. The goal is to surface operational decisions that would otherwise be discovered late in implementation.

Present findings with AskUserQuestion. Some of these may produce additional ADRs; others are just context that informs existing decisions.

**Perspectives**: Have the DevOps engineer and QA engineer weigh in on operational concerns they see. Keep each perspective to 1-2 sentences. Format: `{icon} **{name}**: {perspective}`.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Phase 4 summary before continuing.

### Phase 5: Decision Dependencies

Present a summary of all decisions and their dependencies. Show how decisions relate to each other — which constrain others, which must be made first, which are independent.

If any circular dependencies or conflicts emerge, flag them and work through resolution with the user.

Use AskUserQuestion for confirmation before proceeding to output.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Phase 5 summary before continuing.

### Phase 6: Produce ADRs

Generate one ADR per architectural decision. Present each ADR to the user for confirmation using AskUserQuestion before saving.

After all ADRs are saved, suggest next steps:
- `/cpm:spec` to build requirements using these ADRs as architectural context
- `/cpm:epics` if a spec already exists and needs architectural alignment

## Output

Save each ADR to `docs/architecture/{nn}-adr-{slug}.md` in the current project.

- `{nn}` is a zero-padded auto-incrementing number. Use the Glob tool to list existing `docs/architecture/[0-9]*-adr-*.md` files, find the highest number, and increment by 1. If none exist, start at `01`.
- `{slug}` is a short kebab-case name derived from the decision (e.g., `session-storage`, `image-processing-pipeline`).

Create the `docs/architecture/` directory if it doesn't exist.

Use this format:

```markdown
# ADR: {Decision Title}

**Date**: {today's date}
**Status**: Proposed
**Source**: {path to product brief or input used}

## Context

{Why this decision needs to be made. What product requirements, features, or constraints drive it. Reference specific aspects of the product brief.}

## Options Considered

### Option 1: {Name}
{Description of the approach}

**Trade-offs**:
- **Complexity**: {assessment}
- **Scalability**: {assessment}
- **Team capability**: {assessment}
- **Operational cost**: {assessment}
- **Time to market**: {assessment}

### Option 2: {Name}
{Description and trade-offs in same format}

## Decision

{Which option was chosen}

## Rationale

{Why this option was chosen over alternatives. What trade-offs were accepted and why.}

## Consequences

{What this decision means for the system. What it enables, what it constrains, what follow-on decisions it creates.}

## Dependencies

{Other ADRs this decision depends on or constrains. Use format: "Depends on ADR {nn}: {title}" or "Constrains ADR {nn}: {title}". Leave as "None" if independent.}
```

After saving each ADR, tell the user the document path.

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

**Create** the file before starting Phase 1 (ensure `docs/plans/` exists). **Update** it after each phase completes. **Delete** it only after the final ADRs have been saved and confirmed written — never before. If compaction fires between deletion and a pending write, all session state is lost.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:architect
**Phase**: {N} of 6 — {Phase Name}
**Output target**: docs/architecture/{nn}-adr-{slug}.md (one per decision)

## Completed Phases

### Phase 1: Context & Codebase Exploration
{Concise summary — existing stack, patterns found, product context}

### Phase 2: Identify Architectural Decisions
{List of decisions identified — label and driving requirement for each}

### Phase 3: Explore Trade-offs
{Per-decision summary — chosen option, key trade-off accepted, dependencies noted}

### Phase 4: Operational Architecture
{Operational concerns explored, any additional ADRs identified}

### Phase 5: Decision Dependencies
{Dependency map summary — which decisions constrain others}

{...include only completed phases...}

## Next Action
{What to ask or do next in the facilitation}
```

The "Completed Phases" section grows as phases complete. Each summary should capture the user's key decisions in 2-4 sentences — enough for seamless continuation, not a transcript.

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

- **Explore before proposing.** Always understand the existing codebase and constraints before suggesting architecture.
- **Product-derived decisions.** Every decision should trace back to a product need. If you can't explain why a decision matters for this specific product, it's boilerplate — skip it.
- **Honest trade-offs.** Don't present a preferred option as having no downsides. Every choice has costs.
- **Operational architecture is architecture.** Deployment, monitoring, failure handling, and security are not afterthoughts — they're architectural decisions that deserve the same rigour.
- **Dependencies matter.** Architectural decisions don't exist in isolation. Capture what constrains what.
- **Facilitate, don't lecture.** The user knows their domain. Present analysis, not prescriptions.
- **One decision at a time.** In Phase 3, work through each decision individually with the user before moving to the next.
