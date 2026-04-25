---
name: cpm2:architect
description: Facilitated architecture exploration. Takes a product brief as input, identifies key architectural decisions derived from the product, explores trade-offs per decision, captures dependencies between decisions, and produces Architecture Decision Records (ADRs). Triggers on "/cpm2:architect".
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

Work through these phases **one at a time**. Complete each phase before moving to the next. Use AskUserQuestion for every gate — present only one phase of questions per turn.

**State tracking**: Create the progress file before Phase 1 and update it after each phase completes. See State Management below for the format and rationale. Delete the file once the final ADRs have been saved.

### Retro Check (Startup)

Follow the shared **Retro Awareness** procedure before beginning Phase 1.

**Retro incorporation** (this skill):
- **Codebase discoveries**: Inform Phase 1 (decision identification) — surfaced limitations and patterns may be load-bearing decisions worth promoting to ADRs.
- **Complexity underestimates**: Inform Phase 3 (option evaluation) — past underestimates flag option complexity the team tends to miss.
- **Patterns worth reusing**: Inform Phase 3 — promote proven patterns to recommended options.
- **Testing gaps**: Inform Phase 4 (operational concerns) — surfaced testing limitations may shape architecture choices around testability.

### Roster Loading (Startup)

Follow the shared **Roster Loading** procedure (from the CPM Shared Skill Conventions loaded at session start). The roster is needed for Perspectives in Phase 2.

### Library Check (Startup)

Follow the shared **Library Check** procedure with scope keyword `architect`. Deep-read selectively during exploration phases — especially architecture docs, infrastructure docs, or coding standards that constrain decisions.

### Template Hint (Startup)

After startup checks and before Phase 1, display the template hint:

> Using default template. To customise, place your template at `docs/templates/architect.md`.

If a project-level override exists at `docs/templates/architect.md`, read it and use that format for the output ADRs instead of the embedded default. Full replacement — no merging.

### Codebase Grounding (Startup)

Architectural decisions must be grounded in the current codebase. Phase 1 (Context & Codebase Exploration) performs the detailed exploration — use Glob, Grep, and Read to survey project structure, frameworks, existing patterns, and infrastructure before proposing any decisions. Carry findings from Phase 1 into all subsequent phases.

If the project has no existing codebase (greenfield), note that in Phase 1 and derive context from the product brief instead.

### Phase 1: Context & Codebase Exploration

Before proposing any architecture, understand what already exists. If there's an existing codebase:

1. Use Glob and Grep to explore the project structure, key directories, configuration files, and dependency manifests.
2. Read key files to understand existing patterns, frameworks, conventions, and infrastructure.
3. Summarise findings to the user: existing technology stack, patterns in use, deployment setup, and any architectural decisions already embedded in the code.

If there's no existing codebase (greenfield), note that and move on.

Also summarise the product context from the input (product brief or description) — the vision, key features, and constraints that will drive architectural decisions.

Confirm understanding with the user.

### Phase 2: Identify Architectural Decisions

Analyse the product brief and codebase findings to identify the key architectural decisions that need to be made. Each decision should be **derived from the product's actual needs** — not generic boilerplate like "should we use microservices?"

For each decision, capture:
- **What** needs to be decided (concise label)
- **Why** this decision matters for this specific product
- **Which features or requirements** drive it

Present the decision list to the user with AskUserQuestion. Refine — they may add decisions you missed or remove ones that apply. Aim for 3-8 decisions for a typical product. Only include decisions that are genuinely needed for this product.

**Anti-pattern**: Decisions like "choose a database" or "pick a framework" without product-specific context are boilerplate. Instead: "How to handle booking availability with concurrent access" or "Where to run image processing given the latency requirements."

**Perspectives**: After identifying decisions, follow the shared **Perspectives** procedure. Select 2-3 agents from the loaded roster whose expertise is relevant — e.g. the Software Architect on missing structural decisions, the DevOps Engineer on operational concerns, or the Senior Developer on whether a decision is premature.

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

*Cadence note: save the progress file after each decision is resolved (per-decision, not per-phase).*

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

### Phase 5: Decision Dependencies

Present a summary of all decisions and their dependencies. Show how decisions relate to each other — which constrain others, which must be made first, which are independent.

If any circular dependencies or conflicts emerge, flag them and work through resolution with the user.

Use AskUserQuestion for confirmation before proceeding to output.

### Phase 6: Produce ADRs

Generate one ADR per architectural decision. For each ADR, render its full content in the message body, then use AskUserQuestion as a short gate (e.g. "Approve this ADR?" with options `Approve` / `Request changes` / `Stop`) before saving. See the shared **Gate Presentation** convention.

After all ADRs are saved, suggest next steps:
- `/cpm2:spec` to build requirements using these ADRs as architectural context
- `/cpm2:epics` if a spec already exists and needs architectural alignment

## Output

Save each ADR to `docs/architecture/{nn}-adr-{slug}.md` in the current project.

- `{nn}` is assigned by the shared **Numbering** procedure (from the CPM Shared Skill Conventions loaded at session start).
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

Follow the shared **Progress File Management** procedure.

**Lifecycle**:
- **Create**: before starting Phase 1 (ensure `docs/plans/` exists).
- **Update**: after each phase completes.
- **Delete**: only after the final ADRs have been saved and confirmed written.

**Format**:

```markdown
# CPM Session State

**Skill**: cpm2:architect
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

## Graceful Degradation

Every scenario below specifies an explicit action sequence ending with a visible result. No silent fallbacks.

- **No input resolved** (no briefs, plans, or description) → **Action**: Use AskUserQuestion to ask the user to describe the system they want to explore architecturally. **Result**: The user provides a description and exploration proceeds from that input.

- **No existing codebase** (greenfield project) → **Action**: Skip codebase exploration in Phase 1. Note the greenfield context. **Result**: Report to the user: "No existing codebase found — starting architecture exploration from scratch."

- **No retro files found** → **Action**: Skip the retro check. Proceed directly to the Library Check. **Result**: Report to the user: "No retro files found — proceeding without retro context."

- **No roster found** → **Action**: Skip agent perspectives in Phases 2 and 4. Proceed with facilitation without persona-driven commentary. **Result**: Report to the user: "Agent roster not found — proceeding without perspectives."

- **ADRs directory doesn't exist** → **Action**: Create `docs/architecture/` when saving the first ADR. **Result**: Report to the user: "Created docs/architecture/ for ADR output."

## Guidelines

- **Explore before proposing.** Always understand the existing codebase and constraints before suggesting architecture.
- **Product-derived decisions.** Every decision should trace back to a product need. If you can't explain why a decision matters for this specific product, it's boilerplate — skip it.
- **Honest trade-offs.** Present every option with its genuine costs. Every choice has downsides worth acknowledging.
- **Operational architecture is architecture.** Deployment, monitoring, failure handling, and security are not afterthoughts — they're architectural decisions that deserve the same rigour.
- **Dependencies matter.** Architectural decisions don't exist in isolation. Capture what constrains what.
- **Facilitate, let the user lead.** The user knows their domain. Present analysis, not prescriptions.
- **One decision at a time.** In Phase 3, work through each decision individually with the user before moving to the next.
