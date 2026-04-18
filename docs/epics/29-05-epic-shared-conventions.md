# Shared Conventions

**Source spec**: docs/specifications/29-spec-opus-4-7-compatibility.md
**Date**: 2026-04-18
**Status**: Complete
**Blocked by**: Epic 29-02-epic-positive-voice-rewrite

## Add effort calibration table
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R6 — Effort calibration

**Acceptance Criteria**:

- Effort table in `cpm2/shared/skill-conventions.md` covers all CPM skills [manual]
- Reasoning-heavy skills (do, epics, spec, architect, ralph, consult, party, review) are xhigh [manual]
- Mechanical/lightweight skills (archive, library mechanical paths, retro, present, status, templates) are medium [manual]
- Each row has a one-line rationale [manual]

**Retro**: [Smooth delivery] Straightforward table addition — categorisation was clear from skill descriptions, brief and discover naturally joined the xhigh group, pivot and quick fit high as intermediate reasoning skills.

### Add effort recommendations table to skill-conventions.md
**Task**: 1.1
**Description**: Add a new "Effort Recommendations" section with a table covering all skills. Map each to xhigh/high/medium based on reasoning intensity, with a one-line rationale per row.
**Status**: Complete

---

## Add subagent delegation guidance
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: R7 — Delegation guidance

**Acceptance Criteria**:

- Shared conventions includes a "Subagent Delegation" section referencing Anthropic's guidance [manual]
- Section distinguishes when to delegate (fan-out across items, reading multiple files) from when to work inline (single response, code you can already see) [manual]
- At least one skill file has an explicit subagent fan-out added where it would parallelise independent work [manual]

**Retro**: [Smooth delivery] Review skill was the natural fan-out candidate — each agent perspective is independent analysis of the same artifact, making it a textbook parallelisation opportunity.

### Add subagent delegation section to skill-conventions.md
**Task**: 2.1
**Description**: Add a "Subagent Delegation" section referencing Anthropic's rule. Distinguish fan-out (parallel reads, per-item work) from inline work (single response, visible code).
**Status**: Complete

### Add explicit subagent fan-out to at least one skill
**Task**: 2.2
**Description**: Identify the best candidate (e.g. discover Phase 3 for parallel codebase exploration, or epics Step 3 for parallel per-epic breakdown) and add an explicit fan-out instruction.
**Status**: Complete

## Lessons

### Smooth Deliveries

- Story 1: Effort table categorisation was clear from skill descriptions — 10 xhigh, 2 high, 6 medium.
- Story 2: Review skill's per-agent analysis was the natural fan-out candidate — independent perspectives on the same artifact is textbook parallelisation.
