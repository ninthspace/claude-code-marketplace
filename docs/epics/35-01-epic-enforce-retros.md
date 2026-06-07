# Enforce Retro Generation & Application (do-centric)

**Source spec**: docs/specifications/35-spec-enforce-retros.md
**Date**: 2026-06-07
**Status**: Pending
**Blocked by**: —

## Add shared retro-synthesis procedure; refactor /cpm2:retro onto it
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: AD1

**Acceptance Criteria**:

- A shared **Retro Synthesis** procedure is added to `cpm2/shared/skill-conventions.md` that, given collected observations and story statuses, produces the retro-file body and writes it to `docs/retros/{nn}-retro-{slug}.md` via the shared Numbering procedure [manual]
- The shared procedure owns synthesis + file write only; source-gathering (epic doc vs `docs/quick`) and downstream handoff (library write-back, pivot offer) remain skill-specific wrappers [manual]
- `/cpm2:retro` Steps 2–3 are refactored to call the shared procedure, retaining its `docs/quick` support and its richer tail (library write-back, pivot offer) [manual]
- Both `do` Step 8 and `/cpm2:retro` reference the one shared procedure; no duplicated synthesis logic remains [manual]

### Author shared Retro Synthesis procedure
**Task**: 1.1
**Description**: Add the shared **Retro Synthesis** procedure to `cpm2/shared/skill-conventions.md` — defines inputs (collected observations + story statuses), the category grouping + recommendations synthesis, and the file write to `docs/retros/{nn}-retro-{slug}.md` via Numbering. Covers the "owns synthesis + write only" boundary criterion.
**Status**: Complete

### Refactor /cpm2:retro onto the shared procedure
**Task**: 1.2
**Description**: Refactor `/cpm2:retro` Steps 2–3 to call the shared procedure, keeping source-gathering (epic vs `docs/quick`) and the tail (library write-back, pivot offer) as skill-specific wrappers. Covers the refactor + no-duplication criteria.
**Status**: Complete

**Retro**: [Criteria gap] Story 1's AD1 criterion bundled "do Step 8 references the shared procedure" with the retro-side refactor, but that wiring lands in Story 2 (Task 2.2) — so full deduplication is only verifiable at epic level, not at Story 1's gate.

---

## `do` tail generation + signal capture
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR1, FR2, FR3, FR8 (generation reporting)

**Acceptance Criteria**:

- `do` Step 8 produces the retro file at epic completion via the shared synthesis procedure [manual]
- `do` records retro-trigger flags at the moment they occur during the loop: a verification gate resolved fail-then-continue, repeated `[tdd]` reds, test-command failures, blocked/stuck stories, an epic-level spec gap, or `**Inline change**` breadcrumbs [manual]
- Generation is mandatory when the flag set is non-empty [manual]
- Auto-skip is permitted only when the flag set is empty, and the skip is logged with its reason in the batch summary — must NOT skip silently [manual]
- `do`'s batch summary reports the retro outcome (generated; or auto-skipped + reason) [manual]

### Add signal capture to the work loop
**Task**: 2.1
**Description**: At each point a trigger already surfaces in the work loop (fail-then-continue verification gate, repeated `[tdd]` red, test-command failure, blocked/stuck story, `**Inline change**` breadcrumb), record a retro-trigger flag in the progress file. Covers the FR2 capture criterion.
**Status**: Complete

### Extend do Step 8 to generate via the shared procedure
**Task**: 2.2
**Description**: Extend `do` Step 8 to call Story 1's shared procedure to write the retro file, treating a non-empty flag set (plus an epic-level spec gap) as mandatory generation. Covers FR1 and the mandatory-when-signals criterion.
**Status**: Complete

### Auto-skip-with-log + batch-summary reporting
**Task**: 2.3
**Description**: Skip file creation only on an empty flag set, logging the skip reason; report the generated/auto-skipped outcome in the batch summary. Covers FR3 (must-NOT-silent) and FR8-generation.
**Status**: Complete

**Retro**: [Pattern worth reusing] Capturing retro-trigger signals into the progress file's accumulating `**Retro signals**:` line at Step 6 Part C — rather than at each scattered trigger site — kept signal capture to one edit point and made the flag set trivially available to Step 8.

---

## `do` consumption disposition gate + auditable trace
**Story**: 3
**Status**: Complete
**Blocked by**: Story 2
**Satisfies**: FR4, FR5, AD2

**Acceptance Criteria**:

- `do`'s startup Retro Check becomes a hard disposition gate over relevant prior-epic retro observations — each shown verbatim with its category, forcing Applied / Deferred-with-reason / Obsolete — must NOT resolve on a single acknowledgement [manual]
- Each disposition writes `**Retro applied**: {nn} · {category} · {disposition} — {note}` onto the epic being worked [manual]
- The gate is defined locally in `do`'s Retro Check; the shared Retro Awareness convention remains advisory for the other 9 skills [manual]

### Upgrade Retro Check to a hard disposition gate
**Task**: 3.1
**Description**: Replace the advisory Yes/No in `do`'s `## Retro Check` with a per-observation Applied/Deferred-with-reason/Obsolete gate showing each observation verbatim + category; define it locally in `do`, leaving the shared Retro Awareness convention advisory. Covers FR4 (must-NOT-single-ack) and AD2.
**Status**: Complete

### Write the disposition trace
**Task**: 3.2
**Description**: On each disposition, append `**Retro applied**: {nn} · {category} · {disposition} — {note}` to the worked epic. Covers FR5.
**Status**: Complete

**Retro**: [Smooth delivery] The hard disposition gate dropped cleanly into the existing `## Retro Check` section — AD2's "override locally, leave the shared convention alone" kept the change to one section with zero ripple to the other 9 skills that use advisory Retro Awareness.

---

## `cpm2:ralph` degrade-path + contract upkeep
**Story**: 4
**Status**: Complete
**Blocked by**: Story 3
**Satisfies**: FR6, FR7, FR8 (ralph reporting), AD3

**Acceptance Criteria**:

- Under autonomous execution the consumption gate does not block: it auto-records `deferred (autonomous run, unreviewed)` and surfaces every such deferral in the run summary — must NOT block the loop [manual]
- Retro generation still fires under ralph (non-interactive) [manual]
- `cpm2:ralph`'s gate-override table and its autonomous-behaviour prompt clause gain an explicit defer-and-log entry for the new gate — must NOT leave the gate to the generic "most reasonable option" [manual]
- `/cpm2:ralph --dry-run` shows the new gate in the override table and a defer-and-log prompt clause [manual]

### Update ralph override table + prompt clause
**Task**: 4.1
**Description**: Add the consumption gate to `cpm2:ralph`'s gate-override table (~SKILL.md line 224) with a defer-and-log resolution, add the matching clause to the assembled autonomous-behaviour prompt, and confirm generation still fires non-interactively. Covers FR7 (must-NOT-generic-resolution) and FR6 generation-under-ralph.
**Status**: Complete

### Add the autonomous degrade branch to do's gate
**Task**: 4.2
**Description**: Extend Story 3's gate so that under autonomous execution it auto-records `deferred (autonomous run, unreviewed)`, surfaces every deferral in the run summary, and never blocks. Covers FR6 (must-NOT-block) and FR8-ralph.
**Status**: Complete

**Retro**: [Codebase discovery] ralph's prompt template already exceeded its documented "under 800 chars" budget (measured 932) before this change — the budget note was aspirational, not enforced; corrected to ~1100 when adding the defer-and-log clause. ralph's existing gate-override table + line-242 maintenance contract made wiring the new gate a clean, documented change.

---

## Lessons

### Smooth Deliveries

- Story 3: The hard disposition gate dropped into the existing `## Retro Check` section with zero ripple — AD2's "override locally, leave the shared convention alone" kept the blast radius to one section.

### Criteria Gaps

- Story 1: The AD1 criterion bundled "do Step 8 references the shared procedure" with the retro-side refactor, but that wiring landed in Story 2 — so full deduplication was only verifiable at epic level, not at Story 1's gate. When a criterion depends on a later story, scope it to that story or to an explicit integration check.

### Codebase Discoveries

- Story 4: ralph's prompt template already exceeded its documented "under 800 chars" budget (measured 932); the note was aspirational rather than enforced. Corrected to ~1100 when adding the defer-and-log clause.

### Patterns Worth Reusing

- Story 2: Capturing retro-trigger signals into the progress file's accumulating `**Retro signals**:` line at Step 6 Part C — rather than at each scattered trigger site — kept signal capture to one edit point and made the flag set trivially available to Step 8.
