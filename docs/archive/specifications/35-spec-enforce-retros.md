# Spec: Enforce Retro Generation & Application (do-centric)

**Date**: 2026-06-07
**Brief**: docs/discussions/20-discussion-enforce-retros.md

## Problem Summary

The cpm2 retro loop is broken at both ends of the execution lifecycle. **Generation** is severed: `cpm2:do` Step 8 already collects every `**Retro**:` observation, runs epic-level spec verification, and synthesises a `## Lessons` block — then its exit gate offers only "Continue / Stop" and walks past it, so a retro file is produced only if the user separately remembers to run `/cpm2:retro`. **Application** is advisory: the shared Retro Awareness procedure is wired into `do` as a non-blocking Yes/No that the conventions doc explicitly calls *"advisory input, not a gate,"* so the last epic's lessons rarely shape the next. The fix is a closed, `do`-centric loop — `do` generates the retro at epic completion and gates on prior-epic retros at startup with a forced disposition — leaving `epics`/`spec` untouched (specs are one-off bodies of work) and degrading the gate to a logged trace under `cpm2:ralph` so autonomous loops never stall.

## Functional Requirements

### Must Have

- **FR1 — Tail generation.** `do` Step 8 produces the retro file at epic completion, via the shared synthesis procedure (AD1).
- **FR2 — Signal capture.** `do` records retro-trigger flags at the moment they occur during the loop: a verification gate resolved fail-then-continue, repeated `[tdd]` reds, test-command failures, blocked/stuck stories, an epic-level spec gap, or `**Inline change**` breadcrumbs.
- **FR3 — Mandatory-vs-skip.** Generation is mandatory when the flag set is non-empty; auto-skip is permitted only when empty, and the skip is logged with its reason in the batch summary — never silent.
- **FR4 — Consumption gate.** `do`'s startup Retro Check becomes a hard disposition gate over relevant prior-epic retro observations — each shown verbatim with its category, forcing *Applied / Deferred-with-reason / Obsolete*. A single acknowledgement must not satisfy it.
- **FR5 — Auditable trace.** Each disposition writes `**Retro applied**: {nn} · {category} · {disposition} — {note}` onto the epic being worked.
- **FR6 — Ralph degrade-path.** Under autonomous execution the gate must not block: it auto-records `deferred (autonomous run, unreviewed)` and surfaces every such deferral in the run summary. Generation still fires under ralph.
- **FR7 — Ralph contract upkeep.** `cpm2:ralph`'s gate-override table *and* its autonomous-behaviour prompt clause gain an explicit defer-and-log entry for the new gate (honouring the line-242 maintenance contract).

### Should Have

- **FR8 — Outcome reporting.** `do`'s batch/run summary reports the retro outcome (generated; or auto-skipped + reason; or deferred-unreviewed count under ralph).

### Could Have

- **FR9 — Staleness nudge.** Surface "this observation has been deferred N cycles running" from the `**Retro applied**:` traces.

### Won't Have (this iteration)

- Gates on `epics` or `spec`; changes to the other 9 skills' advisory Retro Awareness usage; cross-spec planning feed-forward; any new skill-execution test harness.

## Non-Functional Requirements

- **Reliability**: the consumption gate must never deadlock the `cpm2:ralph` loop — FR6 is the hard constraint.
- **Usability**: the gate must resist rubber-stamping — disposition-not-acknowledgement (each observation needs a real Applied/Deferred/Obsolete choice).

## Architecture Decisions

### AD1 — Shared retro-synthesis procedure
**Choice**: Extract the "collected observations → retro-file body, then write" core into a shared procedure in `cpm2/shared/skill-conventions.md`. Both `do` Step 8 and `/cpm2:retro` Steps 2–3 call it.
**Rationale**: `do` Step 8 already duplicates ~80% of `/cpm2:retro` Step 2's synthesis; reconnecting via one procedure is DRY and makes generation a near-free extension of work `do` already does.
**Scope boundary**: the shared procedure owns synthesis + file write only. Source-gathering (epic doc vs `docs/quick`) and downstream handoff (library write-back, pivot offer) remain skill-specific wrappers, so `/cpm2:retro` keeps its richer tail and its `docs/quick` support.
**Alternatives considered**: `do` writes the file inline (less refactor, mild duplication retained); `do` invokes `/cpm2:retro` as a sub-step (rejected — drags in retro's own user gates, reintroducing ralph-stall risk).

### AD2 — Hard gate local to `do`
**Choice**: `do`'s `## Retro Check` section defines the hard disposition gate directly; the shared Retro Awareness convention stays advisory for the other 9 skills.
**Rationale**: Smallest blast radius; honours the do-centric scope and avoids reopening the advisory-vs-gate question across 10 skills.
**Alternatives considered**: amend the shared Retro Awareness convention to add a gating mode (rejected for this iteration — ripples too widely).

### AD3 — Ralph contract update
**Choice**: Update `cpm2:ralph`'s gate-override table (~SKILL.md line 224) and the assembled autonomous prompt's behaviour clause to resolve the new gate via explicit defer-and-log, not the generic "choose the most reasonable option."
**Rationale**: The line-242 contract states a new `do` gate not added to the table will stall the loop; a generic auto-resolution would also pick arbitrary dispositions and lose the unreviewed-trace signal.
**Alternatives considered**: rely on ralph's generic autonomous instruction (rejected — stalls or mis-resolves).

## Scope

### In Scope

- FR1–FR8; AD1–AD3.
- Edits: shared synthesis procedure in `skill-conventions.md`; `do`'s `## Retro Check` (gate) and Step 8 (generation + signal capture + reporting); `/cpm2:retro` Steps 2–3 refactored onto the shared procedure; `cpm2:ralph` override table + prompt clause.

### Out of Scope

- Gates on `epics`/`spec`; the other 9 skills' advisory Retro Awareness; cross-spec feed-forward; a skill-execution test harness.

### Deferred

- FR9 staleness nudge; `cpm2:status` parsing of `**Retro applied**:` traces.

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag (e.g. `[tdd] [unit]`). Orthogonal — describes how to work, not what kind of test.

This change is skill-prose plus a documentation table; no harness executes a skill end-to-end, so verification is genuinely `[manual]` — dry-run walkthroughs and documentation review, treated as real human-read gates (per retro-02's lesson "treat `[manual]` documentation criteria as genuine review gates"), not structural-presence checks.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| FR1/FR3 | `/cpm2:do` run to epic completion **with** a signal present produces a `docs/retros/` file via the shared procedure | `[manual]` |
| FR3 | A **clean** epic (empty flag set) skips the file and logs the skip+reason in the batch summary; must NOT skip silently | `[manual]` |
| FR2 | Each trigger (fail-then-continue gate, repeated `[tdd]` red, test failure, blocked story, spec gap, inline-change breadcrumb) is recorded when it occurs | `[manual]` |
| FR4 | `/cpm2:do` startup with a relevant prior retro presents each observation verbatim + category and forces a disposition; must NOT resolve on a single acknowledgement | `[manual]` |
| FR5 | A `**Retro applied**: {nn} · {category} · {disposition} — {note}` line is written to the worked epic | `[manual]` (grep-checkable shape) |
| FR6 | `cpm2:ralph` autonomous run records `deferred (autonomous run, unreviewed)`, surfaces it in the run summary, and must NOT block the loop | `[manual]` |
| FR7 | `/cpm2:ralph --dry-run` shows the new gate in the override table + a defer-and-log prompt clause; must NOT leave it to the generic "most reasonable option" | `[manual]` |
| AD1 | Both `do` Step 8 and `/cpm2:retro` reference the one shared synthesis procedure; no duplicated synthesis logic remains | `[manual]` |

### Integration Boundaries
Documentation contracts, not code interfaces: (a) `do` ↔ shared synthesis procedure ↔ `/cpm2:retro`; (b) `do`'s new gate ↔ `cpm2:ralph`'s override table (the line-242 maintenance contract).

### Test Infrastructure
**None required.** The existing `cpm2/hooks/tests/` bash suites cover hooks, not skill-prose behaviour; adding a skill-execution harness is out of scope. Verification is dry-run + documentation review.

### Unit Testing
Unit testing of individual components is handled at the `cpm2:do` task level — n/a here, as the change is skill-prose with no isolated code units.
