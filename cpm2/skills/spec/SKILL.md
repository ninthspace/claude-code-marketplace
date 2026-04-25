---
name: cpm2:spec
description: Build a structured requirements and architecture specification through facilitated conversation. Takes a problem brief or user description as input and produces a spec document with functional requirements, architecture decisions, and scope boundaries. Triggers on "/cpm2:spec".
---

# Requirements & Architecture Specification

Build a structured spec through facilitated conversation. Each section uses AskUserQuestion to gate progression — one section at a time.

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

**Graceful degradation**: If ADRs are absent, Section 4 works as before — facilitating architecture decisions from scratch. The spec skill works with or without `cpm2:architect` having been run.

## Process

Work through these sections **one at a time**. Use AskUserQuestion for every gate.

**State tracking**: Create the progress file before Section 1 and update it after each section completes. See State Management below for the format and rationale. Delete the file once the final spec has been saved.

### Termination

- **Success**: The user approves the section's output via AskUserQuestion — move to the next section. For the overall process: Section 7 review is approved and the spec is saved.
- **Blocker**: The user needs external information not available in the session (stakeholder input, technical investigation, cost data). Note the gap in the section summary, proceed to the next section, and flag the gap for resolution during Section 7 review.
- **Ambiguity**: The user is uncertain or cannot decide on a section's content after one clarification round. Present a recommended default based on the best available information. If the user still cannot decide, note both options in the spec with a "TBD" marker and proceed — the spec is a living document that can be revised before `cpm2:epics`.

**Facilitation depth**: Each section's refinement loop converges in 1-2 rounds of AskUserQuestion. When the user approves a section's content, move on — one final "anything else?" check per section, not an open-ended refinement cycle.

### Retro Check (Startup)

Follow the shared **Retro Awareness** procedure before beginning Section 1.

**Retro incorporation** (this skill):
- **Criteria gaps**: Inform Section 2 (functional requirements) and Section 6b (acceptance criteria tagging) — gaps from last round become explicit must-haves and tagged criteria this round.
- **Scope surprises**: Inform Section 3 (scope boundaries) — surface and address the boundary issue that caused the surprise.
- **Testing gaps**: Inform Section 6 (testing strategy) — past untestable criteria get rewritten or upgraded to integration boundaries.
- **Patterns worth reusing**: Inform Section 4 (architecture decisions) — surfaced patterns may already answer architecture questions.

### Roster Loading (Startup)

Follow the shared **Roster Loading** procedure (from the CPM Shared Skill Conventions loaded at session start). The roster is needed for Perspectives in Sections 4 and 5.

### Library Check (Startup)

Follow the shared **Library Check** procedure with scope keyword `spec`. Deep-read selectively during spec sections — especially architecture decisions (Section 4) where architecture docs and coding standards directly inform choices, and scope boundaries (Section 5) where existing constraints may affect what's feasible.

### Template Hint (Startup)

After startup checks and before Section 1, display:

> Output format is fixed (used by downstream skills). Run `/cpm2:templates preview spec` to see the format.

### Codebase Grounding (Startup)

Before facilitating requirements, explore the existing codebase to ground the conversation in what already exists:

1. Use Glob and Grep to survey the project structure — key directories, configuration files, dependency manifests, and existing patterns.
2. Read key files to understand the technology stack, architectural conventions, and domain model in use.
3. Carry these findings into all sections — propose requirements and architecture decisions that build on what exists rather than starting from assumptions.

If the project has no existing codebase (greenfield), note that and proceed. For projects with code, grounding ensures that requirements reflect real constraints and architecture decisions align with established patterns.

### Section 1: Problem Recap

Briefly summarise the problem from the input (brief or description). Confirm understanding with the user. If starting from a brief, this should be quick — just verify nothing has changed.

### Section 2: Functional Requirements

Facilitate conversation about what the system must do. Use MoSCoW prioritisation:

- **Must have**: Core functionality without which the system fails
- **Should have**: Important but the system works without them
- **Could have**: Nice-to-haves if time allows
- **Won't have**: Explicitly out of scope for this iteration

Present a draft list and refine with the user. Iterate — refine progressively rather than trying to capture everything at once.

### Section 3: Non-Functional Requirements

Only cover what's relevant to this project. Skip anything that doesn't apply.

Areas to consider:
- Performance (response times, throughput)
- Security (auth, data protection, access control)
- Scalability (expected load, growth)
- Reliability (uptime, error handling, data integrity)
- Usability (accessibility, device support)

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

**Perspectives**: Before presenting each major architecture decision to the user, follow the shared **Perspectives** procedure. Select 2-3 agents from the loaded roster whose expertise is relevant — e.g. the Software Architect on structural trade-offs, the Senior Developer on implementation cost, the DevOps Engineer on deployment concerns, or the QA Engineer on testability. This surfaces trade-offs the user should consider before deciding.

### Section 5: Scope Boundary

Consolidate from the conversation:
- What's **in scope** for this iteration
- What's **explicitly out of scope**
- What's **deferred** to future iterations

**Perspectives**: Before finalising scope, follow the shared **Perspectives** procedure. Select 2-3 agents from the loaded roster whose expertise is relevant — e.g. the Product Manager on keeping scope tight for delivery, the Software Architect on foundational work, or the Senior Developer on dependencies that force certain items in.

### Section 6: Testing Strategy

Outline how the system will be verified. This section bridges the spec and implementation by making testability explicit — not just what to test, but how each requirement will be verified.

#### Step 6a: Define Tag Vocabulary

Present the test approach tag vocabulary to the user:

- `[unit]` — Verified by unit tests targeting individual components in isolation
- `[integration]` — Verified by integration tests that exercise boundaries between components (API contracts, event flows, data layer interactions)
- `[feature]` — Verified by feature/end-to-end tests that exercise complete user-facing workflows
- `[manual]` — Verified by manual inspection, observation, or user confirmation (no automated test)
- `[tdd]` — Workflow mode: task follows a red-green-refactor loop. Composable with any level tag above (e.g. `[tdd] [unit]`, `[tdd] [integration]`). Orthogonal — describes *how* to work, not *what kind* of test. When present, `cpm2:do` writes a failing test first, then implements to pass it, then refactors. `[tdd]` without a level tag defaults to `[tdd] [unit]`.

**Tag propagation**: When present, these tags flow downstream — `cpm2:epics` propagates them onto story acceptance criteria and `cpm2:do` uses them to select verification approach (run tests vs. self-assess) and workflow mode (standard vs. TDD). When a story introduces criteria beyond the spec, `cpm2:epics` proposes tags based on the criterion's nature. If the spec has no Testing Strategy (user opts out below), downstream skills treat all criteria as untagged and verify by self-assessment. Use AskUserQuestion to confirm the vocabulary or let the user adjust it.

**Graceful fallback**: If the user prefers not to tag criteria, skip tag assignment and proceed — acceptance criteria mapping without tags. The rest of Section 6 still runs.

#### Step 6b: Tag Acceptance Criteria

For each must-have functional requirement from Section 2, propose a test approach tag for each acceptance criterion. **Default to automation** — boundary-crossing → `[integration]`, isolated logic → `[unit]`, user-visible workflow → `[feature]`. Propose `[manual]` only when automation is genuinely infeasible (visual/UX judgement, third-party UI you don't control, content review, observability checks against external systems), and when you do, include a one-line justification stating what blocks automation. `[manual]` is the exception, not a peer of the automated tags — see `cpm2:epics`'s **Default to automation** guideline for the full automatable/manual category lists. Use AskUserQuestion to confirm or adjust. Flag any criterion too vague to tag and ask the user to refine it.

**Probe for must-NOT clauses**: For each criterion, ask: "Are there behaviours this criterion explicitly allows that you would reject?" Capture rejected behaviours as paired `must NOT` lines alongside the positive criterion (e.g. "must NOT allow password reset without rate limiting"). Include must-NOT lines in the Acceptance Criteria Coverage table with their own tags.

Work through requirements one at a time — present tags and must-NOT probes incrementally.

#### Step 6c: Integration Boundaries

If ADRs were discovered, identify the key integration boundaries between architectural components (e.g. API contracts, event schemas, data flows between services). These become the seams where integration tests should focus. If no ADRs exist, derive boundaries from the architecture decisions made in Section 4.

Present the integration boundaries to the user and refine.

#### Step 6d: Test Infrastructure

Assess whether the project needs any testing infrastructure that doesn't already exist:

- Test frameworks (e.g. PHPUnit, Pest, Jest, pytest)
- Test databases or fixtures
- CI configuration for running tests
- Mock/stub libraries for external services

If infrastructure is needed, capture it — these become stories in `cpm2:epics`. If the project already has adequate test infrastructure, note that and move on. Use AskUserQuestion to confirm.

#### Step 6e: Present and Refine

Present the complete testing strategy to the user: tagged criteria, integration boundaries, and infrastructure needs. Refine with AskUserQuestion before proceeding.

*Progress note: capture tag assignments per requirement and infrastructure needs in the Section 6 summary.*

### Section 7: Review

Render the complete spec in the message body. Then use AskUserQuestion as a short gate (e.g. "Approve this spec?" with options `Approve` / `Request changes` / `Stop`). See the shared **Gate Presentation** convention.

## Output

Save the spec to `docs/specifications/{nn}-spec-{slug}.md` in the current project.

- `{nn}` is assigned by the shared **Numbering** procedure (from the CPM Shared Skill Conventions loaded at session start).
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

### Tag Vocabulary
Test approach tags used in this spec:
- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag (e.g. `[tdd] [unit]`). Orthogonal — describes how to work, not what kind of test.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| {Requirement label} | {Criterion text} | {[tag]} |
| {Requirement label} | {Criterion text} | {[tag]} |

{Each must-have requirement has at least one testable criterion with a tag. Criteria flagged during Section 6b as vague should be refined before inclusion here.}

### Integration Boundaries
{Key integration points between architectural components, derived from ADRs if available}

### Test Infrastructure
{Testing infrastructure the project needs — frameworks, test databases, fixtures, CI configuration, mock libraries. "None required" if the project already has adequate infrastructure. Items listed here become stories in `cpm2:epics`.}

### Unit Testing
Unit testing of individual components is handled at the `cpm2:do` task level — each story's acceptance criteria drive test coverage during implementation.
```

After saving, suggest next steps:
- `/cpm2:epics` to break the spec into epic documents with stories and tasks (recommended)
- `/cpm2:architect` to explore architecture first, if no ADRs exist yet and the system has non-trivial architectural decisions
- `/plan` (native plan mode) if the scope is small enough to skip planning artifacts entirely

## State Management

Follow the shared **Progress File Management** procedure.

**Lifecycle**:
- **Create**: before starting Section 1 (ensure `docs/plans/` exists).
- **Update**: after each section completes.
- **Delete**: only after confirming the final spec is saved and written.

**Format**:

```markdown
# CPM Session State

**Skill**: cpm2:spec
**Section**: {N} of 7 — {Section Name}
**Output target**: docs/specifications/{nn}-spec-{slug}.md
**Input source**: {path to brief or description used as input}

## Completed Sections

### Section 1: Problem Recap
{Concise summary — confirmed problem statement, any changes from brief}

### Section 2: Functional Requirements
{Concise summary — key must-haves, should-haves, won't-haves decided}

{...continue for each completed section...}

### Section 6: Testing Strategy
{Tag vocabulary confirmed or skipped. Per-requirement tag assignments:
- Requirement 1: [tag] criterion summary, [tag] criterion summary
- Requirement 2: [tag] criterion summary
...
Integration boundaries identified. Test infrastructure needs: {list or "none"}.}

## Next Action
{What to ask or do next in the facilitation}
```

The "Completed Sections" section grows as sections complete. Each summary should capture the key decisions, requirements, and priorities in enough detail for seamless continuation — not a transcript, but enough that no question needs to be re-asked.

The "Next Action" field tells the post-compaction context exactly where to pick up.

## Guidelines

- **Facilitate, then let the user decide.** Present options and trade-offs. The user owns the decision.
- **Build on existing context.** If there's a brief or existing code, use it. Carry forward what's already established.
- **Stay practical.** Skip sections that are unnecessary at the project's scale.
- **One section at a time.** Complete each before moving on.
- **Match depth to complexity.** A small feature needs a lean spec. A new product needs more detail.
