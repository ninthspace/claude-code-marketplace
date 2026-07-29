---
name: spec
description: Build a structured requirements and architecture specification through facilitated conversation. Takes a problem brief or user description as input and produces a spec document with functional requirements, architecture decisions, scope boundaries, and a testing strategy. Triggers on "/cpm:spec".
---

# Requirements & Architecture Specification

Build a structured spec through facilitated conversation. Each section uses AskUserQuestion to gate progression — one section at a time.

## Input

Check for input in this order:

1. If `$ARGUMENTS` references a file path, read that file as the starting context.
2. If `$ARGUMENTS` contains a description, use that as the starting context.
3. If neither, look for product briefs first, then problem briefs:
   a. **Glob** `docs/briefs/[0-9]*-brief-*.md` to find product briefs. If found, present them with AskUserQuestion — show each brief's title and date. Product briefs are the preferred input since they already contain vision, value propositions, key features, and constraints.
   b. If no product briefs, look for the most recent `docs/plans/[0-9]*-plan-*.md` file and ask the user if they want to use it.
4. If no briefs exist, ask the user to describe what they want to build.

### ADR Discovery (Startup)

After resolving the input source and before starting Section 1, discover existing Architecture Decision Records:

1. **Glob** `docs/architecture/[0-9]*-adr-*.md`. If no files found or directory doesn't exist, skip silently — the spec will facilitate architecture decisions from scratch in Section 4.
2. If ADRs exist, read each one and present a summary to the user: "Found {N} existing ADRs: {titles}. I'll reference these during architecture decisions (Section 4) and only facilitate new decisions for gaps."
3. Store the ADR paths and summaries for use in Section 4.

**Graceful degradation**: If ADRs are absent, Section 4 works as before — facilitating architecture decisions from scratch. The spec skill works with or without `cpm:architect` having been run.

### Constraint Inheritance (Startup)

After ADR Discovery and before starting Section 1, gather the environmental constraints upstream documents already record, so Step 3a facilitates only the gaps rather than re-asking:

1. **Resolve the problem brief.** This is the one document that holds constraints as first captured, and how it is located matters:
   - If the resolved input is itself a problem brief (`docs/plans/…`), that is the source.
   - If the resolved input is a product brief, read its `**Source**` field and follow it — but **only when the value names a path that exists on disk**. `cpm:brief` writes that field as a path *or* the literal `"direct input"`, so an unresolvable value means there is no problem brief, not an error. This is the same back-reference `cpm:pivot` walks to build its cascade chains (`pivot/SKILL.md:47`), under the same rule.
   - Do not pick the most recent file in `docs/plans/[0-9]*-plan-*.md` instead. Recency answers "which brief is newest", not "which brief is this spec's", and the two diverge the moment a project has more than one line of work.
2. **Glob** `docs/plans/[0-9]*-plan-*.md` to confirm the resolved path is a problem brief this project actually holds, and `docs/architecture/[0-9]*-adr-*.md` for ADRs. If neither yields anything, skip silently.
3. **Read `## Constraints`** from the resolved problem brief, and the Context and Consequences of any ADRs that bear on the environment. Carry both into Step 3a as entries already known.
4. In Step 3a, **present what was inherited for confirmation and facilitate only what is missing.** An inherited entry still has to be falsifiable and still gets a label; inheritance decides what is asked, never what is recorded.

**The product brief is a waypoint, not the source.** It carries a `## Constraints` section of its own, and reading that instead is the mistake this ordering exists to prevent: the product brief's copy is derived, written during ideation, and lossy by the time features have been argued over. The problem brief is where constraints were captured as facts about the world. Reach past it.

**Graceful degradation**: No problem brief, no ADRs, or a brief with no `## Constraints` — this check finds nothing and Step 3a facilitates from scratch, exactly as it would in a project that never ran `cpm:discover`. Absence is never an error and never a prompt.

## Process

Work through these sections **one at a time**. Use AskUserQuestion for every gate.

**State tracking**: Create the progress file before Section 1 and update it after each section completes. See State Management below for the format and rationale. Delete the file once the final spec has been saved.

### Termination

- **Success**: The user approves the section's output via AskUserQuestion — move to the next section. For the overall process: Section 7 review is approved and the spec is saved.
- **Blocker**: The user needs external information not available in the session (stakeholder input, technical investigation, cost data). Note the gap in the section summary, proceed to the next section, and flag the gap for resolution during Section 7 review.
- **Ambiguity**: The user is uncertain or cannot decide on a section's content after one clarification round. Present a recommended default based on the best available information. If the user still cannot decide, note both options in the spec with a "TBD" marker and proceed — the spec is a living document that can be revised before `cpm:epics`. **Except Step 3a**: an environmental constraint that cannot be made falsifiable blocks rather than proceeding. A "TBD" sits in prose `coverage-parse.sh` never reads, so proceeding there is the silent drop that produces a fully verified matrix over software that cannot run on its target — the failure the whole step exists to catch.

**Facilitation depth**: Each section's refinement loop converges in 1-2 rounds of AskUserQuestion. When the user approves a section's content, move on — one final "anything else?" check per section, not an open-ended refinement cycle.

### Stale-Progress Check (Startup)

Follow the shared **Stale-Progress Check** procedure (from the CPM Shared Skill Conventions loaded at session start).

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

> Output format is fixed (used by downstream skills). Run `/cpm:templates preview spec` to see the format.

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

**Give each requirement an `FRn` label as it is agreed**, numbered once across Must, Should and Could rather than restarting under each heading, and carry the label into the draft the user sees. A label assigned during facilitation is one the user can refer to for the rest of the session and one that survives into Section 6b's coverage table and every downstream matrix. Assigning them at write-up instead means the conversation and the document disagree about what `FR4` is. Won't Have entries are ruled out rather than requirements to satisfy and stay unlabelled — see the output template's note.

### Section 3: Non-Functional Requirements

Only cover what's relevant to this project. Skip anything that doesn't apply.

Areas to consider:
- Performance (response times, throughput)
- Security (auth, data protection, access control)
- Scalability (expected load, growth)
- Reliability (uptime, error handling, data integrity)
- Usability (accessibility, device support)

#### Step 3a: Environmental Constraints

Environmental constraints *are* non-functional requirements, which is why they are captured here
rather than in a section of their own. Unlike the areas above, this step is **not skippable**: it
runs on every spec and ends in either labelled entries or an explicit "none apply". A spec that was
never asked is indistinguishable from a spec whose target has no constraints, and it is the first
that ships a fully verified matrix over software that cannot run where it has to.

Cover both environments and both classes:

| | **Requirement** — must be available | **Restriction** — must not be required |
|---|---|---|
| **Development** | test runner, browser automation, language version, test database or fixtures, CI that runs the suite, mock/stub libraries for external services | tooling a contributor cannot install |
| **Production** | runtime version, hosting model, services the host provides | anything the host cannot supply |

Ask about **development tooling explicitly** — which test runner, whether browser automation is
needed — not only about the production environment. On a greenfield project there is no dependency
manifest to infer it from, so `cpm:do`'s Test Runner Discovery finds nothing and proceeds with
`Test command: none`; what is captured here is what drives the installation instead.

**This is the only place test tooling is captured.** Section 6 assigns test approach tags later and
reconciles them against what was recorded here, but it records nothing of its own: a spec's testing
tooling is an environmental requirement, and the label is what carries it into the coverage matrix.

**Which environment an entry names decides its test approach tag.** The table's two rows are not a
presentation device. A **Development** entry is a claim about the machine the work happens on, so
whatever runs there is in a position to check it and it takes an ordinary automated tag — "Pest 3
or later installed and runnable in development" is discharged by the suite running. A
**Production** entry is a claim about a host nobody here has, so it takes `[target]`. The class —
requirement or restriction — does not enter into it; `ENVXn` splits the same way its row does.

Tagging a development entry `[target]` makes it unverifiable by the only thing in a position to
verify it. `cpm:ralph`'s prompt instructs a loop never to self-assess a `[target]` criterion and
never to count it as met, so a spec that tags its own tooling that way cannot reach a clean
verdict however much is built — and the failure names the deployment target, which had nothing to
do with it.

The two classes are not two phrasings of one thing. "Pest is available" is satisfied by installing
something. "Must not require a queue worker" invalidates a design and cannot be retrofitted — it is
the class that yields a passing acceptance matrix and an undeployable result, so it is elicited
directly rather than inferred from the absence of a requirement.

**Every entry states a condition something can check.** `PHP 8.2 or later on the host` is
checkable; "the environment should be modern" is not. An unfalsifiable entry is worse than a
missing one — it takes a label, enters the coverage matrix, and gets marked delivered by whoever
decides it feels satisfied. Refuse it, and **name which entry**: say what about it cannot be
checked and offer the checkable form. A refusal is a refinement round, not a rejection of the
concern behind it.

**Fail closed.** An entry that cannot be parsed, cannot be made falsifiable, or belongs to neither
class is **reported and blocks this step**. It is never dropped, never silently reclassified, and
never carried into the document unlabelled. This is the spec's own subject applied to itself: the
failure being designed against is one that looks like success, so a constraint that could not be
handled has to leave the step visibly unfinished rather than quietly absent.

Record each entry under `## Non-Functional Requirements`, labelled `ENVn` for a requirement and
`ENVXn` for a restriction. Labelled there, they are traced by the coverage roll-up exactly as `NFRn`
entries are, and an unsatisfied one holds the untraced count above zero instead of sitting in prose
nothing reads.

Converge in 1-2 `AskUserQuestion` rounds, as every other section does.

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
- `[target]` — Verified by a mechanical check that can only run against the real deployment target. Not a weaker `[manual]` but a different thing: `[manual]` means a human judges it and no automation is possible in principle, whereas here the check *is* mechanical and only the environment is missing. **Production** environmental entries are the usual case — a runtime version on the host, a service the host provides, something the host cannot supply. A **development** environmental entry is not one, however environmental it looks: the machine running the work *is* the environment it claims, so it takes an automated tag (Step 3a). Self-assessing a genuine `[target]` from a development sandbox — confirming "runs on PHP 8.2 or later" on a machine where it does — is the false pass this tag exists to stop.
- `[tdd]` — Workflow mode: task follows a red-green-refactor loop. Composable with any level tag above (e.g. `[tdd] [unit]`, `[tdd] [integration]`). Orthogonal — describes *how* to work, not *what kind* of test. When present, `cpm:do` writes a failing test first, then implements to pass it, then refactors. `[tdd]` without a level tag defaults to `[tdd] [unit]`.

**Tag propagation**: When present, these tags flow downstream — `cpm:epics` propagates them onto story acceptance criteria and `cpm:do` uses them to select verification approach (run tests vs. self-assess) and workflow mode (standard vs. TDD). When a story introduces criteria beyond the spec, `cpm:epics` proposes tags based on the criterion's nature. If the spec has no Testing Strategy (user opts out below), downstream skills treat all criteria as untagged and verify by self-assessment. Use AskUserQuestion to confirm the vocabulary or let the user adjust it.

**Graceful fallback**: If the user prefers not to tag criteria, skip tag assignment and proceed — acceptance criteria mapping without tags. The rest of Section 6 still runs.

#### Step 6b: Tag Acceptance Criteria

For each must-have functional requirement from Section 2, **and for each non-functional requirement from Section 3**, propose a test approach tag for each acceptance criterion. **Default to automation** — boundary-crossing → `[integration]`, isolated logic → `[unit]`, user-visible workflow → `[feature]`. Propose `[manual]` only when automation is genuinely infeasible (visual/UX judgement, third-party UI you don't control, content review, observability checks against external systems), and when you do, include a one-line justification stating what blocks automation. `[manual]` is the exception, not a peer of the automated tags — see `cpm:epics`'s **Default to automation** guideline for the full automatable/manual category lists. Use AskUserQuestion to confirm or adjust. Flag any criterion too vague to tag and ask the user to refine it.

**An NFR with no row here is admissible to this skill and blocking downstream, which is why it is named.** `coverage-rollup.sh` counts every requirement it can parse — `NFRn` alongside `FRn` — so an NFR that reaches the epics with no acceptance criterion still has to be traced to a matrix row before a spec-mode loop can leave phase 1. `cpm:epics` will close the gap by writing a row with an empty test approach, which is honest (there was no tag to propagate) and leaves `cpm:do` verifying against nothing. The requirement most likely to land here is the one phrased as an absence — *no dependencies*, *no configuration*, *never mutates X* — because there is no artefact to point at. Give it an observable: a check that the absence holds is a criterion; the absence itself is not.

**Probe for must-NOT clauses**: For each criterion, ask: "Are there behaviours this criterion explicitly allows that you would reject?" Capture rejected behaviours as paired `must NOT` lines alongside the positive criterion (e.g. "must NOT allow password reset without rate limiting"). Include must-NOT lines in the Acceptance Criteria Coverage table with their own tags.

Work through requirements one at a time — present tags and must-NOT probes incrementally.

#### Step 6c: Integration Boundaries

If ADRs were discovered, identify the key integration boundaries between architectural components (e.g. API contracts, event schemas, data flows between services). These become the seams where integration tests should focus. If no ADRs exist, derive boundaries from the architecture decisions made in Section 4.

Present the integration boundaries to the user and refine.

#### Step 6d: Reconcile Tags Against the Environmental Constraints

The tags just assigned imply tooling. A `[feature]` criterion implies something that drives a browser or an end-to-end runner; `[integration]` implies a test database or a way to stand up a boundary; `[tdd]` implies a runner fast enough to sit in a red-green loop.

For each kind of tooling the assigned tags imply, check that Step 3a recorded an `ENVn` for it. Where one is missing, **go back to Step 3a and add it there** — labelled, falsifiable, and tagged by the environment it names.

**Everything this step adds is development tooling, so none of it is `[target]`.** A test runner, a browser driver, a test database and a CI job are claims about the machine the work happens on; Step 3a's rule applies to them unchanged and they take an automated tag. Sending them to `[target]` because they were reached from a *reconciliation against environmental constraints* is the routing error that makes a spec's own tooling permanently unverifiable — the entry is environmental, but the environment is this one.

**Record nothing here.** This step has no output of its own and no section in the spec. An entry made here would sit in prose `coverage-parse.sh` never reads, so it would neither reach the coverage matrix nor hold the untraced count above zero — a tooling need captured that way is indistinguishable from one never raised. Step 3a is the single capture site; the tags are later evidence about what an environment has to provide, not a second place to put the answer.

This is why the step is a check rather than an elicitation: Section 3 runs before Section 6, so the tags did not exist when Step 3a asked its questions.

#### Step 6e: Present and Refine

Present the complete testing strategy to the user: tagged criteria, integration boundaries, and any `ENVn` entries Step 6d sent back to Step 3a. Refine with AskUserQuestion before proceeding.

*Progress note: capture tag assignments per requirement and infrastructure needs in the Section 6 summary.*

### Section 7: Review

Render the complete spec in the message body. Then use AskUserQuestion as a short gate (e.g. "Approve this spec?" with options `Approve` / `Request changes` / `Stop`). See the shared **Gate Presentation** convention.

### Companion Assets (when a requirement is inherently visual)

Some requirements are inherently visual — a UI screen the spec describes, a layout, or a data/flow diagram that words only approximate. When a requirement's content **is** visual, generate an HTML **companion asset** so that intent travels downstream intact instead of being omitted, ASCII-approximated, or exiled to a link that dies. Follow the shared **HTML Output** convention for all of the mechanics below — this section only says *when* to generate and *what to record*; it does not restate the storage, self-contained, or template rules.

**Content-driven, not flag-driven.** Generation is triggered by the nature of the requirement, never by an explicit request or flag. You decide an asset is warranted because the requirement is genuinely visual.

**Conservative heuristic — the visual must earn its place.** Generate an asset *only* when a visual genuinely adds something the Markdown cannot carry. Do **not** generate one for non-visual requirements (business rules, data validation, API contracts, process logic). When in doubt, don't. A spec with no inherently-visual requirements produces no companion assets — that is the expected, common case.

**Two kinds of visual, styled differently** (per the shared convention's *shared chrome vs. system-specific mockups*):
- A **documentation diagram** that *explains* the spec (a data-flow or sequence diagram) consumes the shared template (`.cpm-figure`) — it is CPM explaining its own content.
- A **deliverable-functionality mockup** — a preview of the UI of the system being specified — is *system-specific*: build it standalone in the target system's own design language (the `frontend-design` skill is appropriate here), **not** the shared template. It is still self-contained and stored at the same companion-asset path.

**Reference and note (both kinds).** After writing the asset to `docs/specifications/assets/{nn}-{slug}-{label}.html`, do two things in the Markdown:
1. Reference the asset from the requirement it illustrates, by the stable **relative** path (e.g. `See mockup: [booking screen](assets/{nn}-{slug}-booking.html)`).
2. Record a one-line note explaining **why this asset exists** — what the visual carries that the prose cannot (e.g. *"Companion mockup: the multi-step booking flow's screen states are clearer shown than described."*). This note is what keeps generation honest: if you cannot write the one-line justification for what the visual carries that the prose cannot, it has not earned its place — don't generate it.

## Output

Follow the shared **Written Deliverable Length** convention — let the document's length match what the task needs, without padding, redundant summaries, or boilerplate sections.

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
- **FR1 — {Title}.** {requirement}

### Should Have
- **FR2 — {Title}.** {requirement}

### Could Have
- **FR3 — {Title}.** {requirement}

### Won't Have (this iteration)
- {item}

{Every requirement under Must, Should and Could opens with a label — `FRn` — and the numbering runs
once across all three headings rather than restarting under each. The label is what the coverage
roll-up traces: it reads requirements from this section and `## Non-Functional Requirements` only,
and it identifies one by the label the bullet opens with. An unlabelled bullet is read as prose and
produces no record at all — not an untraced requirement but no requirement, which is the one failure
that cannot be seen downstream, because a requirement nothing knows about cannot be reported missing.

Won't Have entries stay unlabelled: they are items ruled out rather than requirements to satisfy, and
prose is what the roll-up should skip. Label one only when it is a real requirement being explicitly
deferred — labelled there, it is recognised and excluded rather than counted as an outstanding gap.}

## Non-Functional Requirements
{Only sections that are relevant}

- **NFR1 — {Title}.** {requirement}
- **ENV1 — {Title}.** {environmental requirement — what the target must provide, e.g. PHP 8.2 or later on the production host, or a test runner available in development}
- **ENVX1 — {Title}.** {environmental restriction — what the work must not require, e.g. must not require a queue worker}

{Environmental constraints are labelled `ENVn` when something must be available and `ENVXn` when
something must not be required, and they live under this heading rather than in a section of their
own — that is what makes the coverage roll-up trace them exactly as it traces `NFRn`, so an
unsatisfied one holds the untraced count above zero. Elicited in Step 3a.}

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
- `[target]` — Mechanical check runnable only against the real deployment target; not a human judgement, and not a development-environment claim
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag (e.g. `[tdd] [unit]`). Orthogonal — describes how to work, not what kind of test.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| {Requirement label} | {Criterion text} | {[tag]} |
| {Requirement label} | {Criterion text} | {[tag]} |

{Each must-have requirement and each non-functional requirement has at least one testable criterion with a tag. Criteria flagged during Section 6b as vague should be refined before inclusion here.}

### Integration Boundaries
{Key integration points between architectural components, derived from ADRs if available}

### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
```

An artifact can be published from this output on request — follow the shared **Artifact Publishing** procedure. It is always separately confirmed, and never the default.

For `spec` the artifact is a requirement explorer: requirements filterable by MoSCoW priority and test approach tag, each shown with its acceptance criteria and paired must-NOTs — so an untagged criterion or a must-have with nothing automated behind it reads as a gap at a glance, rather than being found by counting across Sections 2 and 6. As with companion assets, if you cannot write the one-line justification for what the visual carries that the prose cannot, it has not earned its place.

After saving, suggest next steps:
- `/cpm:epics` to break the spec into epic documents with stories and tasks (recommended)
- `/cpm:architect` to explore architecture first, if no ADRs exist yet and the system has non-trivial architectural decisions
- `/plan` (native plan mode) if the scope is small enough to skip planning artifacts entirely

## State Management

Follow the shared **Progress File Management** procedure, writing to `docs/plans/.cpm-progress-{session_id}.md` — or `docs/plans/.cpm-progress.md` when `CPM_SESSION_ID` is not in context. `/cpm:clean`, the Stale-Progress Check and compaction recovery all locate the file by globbing that exact stem, so one named anything else is invisible to every reader it exists for.

**Lifecycle**:
- **Create**: before starting Section 1 (ensure `docs/plans/` exists).
- **Update**: after each section completes.
- **Delete**: only after confirming the final spec is saved and written.

**Format**:

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

- **Correct yourself sparingly.** Follow the shared **Correcting yourself** convention — narrate a correction to something you said earlier only when the error would change the user's conclusions or decisions.
- **Facilitate, then let the user decide.** Present options and trade-offs. The user owns the decision.
- **Build on existing context.** If there's a brief or existing code, use it. Carry forward what's already established.
- **Stay practical.** Skip sections that are unnecessary at the project's scale.
- **One section at a time.** Complete each before moving on.
- **Match depth to complexity.** A small feature needs a lean spec. A new product needs more detail.
