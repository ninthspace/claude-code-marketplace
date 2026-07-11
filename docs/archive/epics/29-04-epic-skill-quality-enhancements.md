# Skill Quality Enhancements

**Source spec**: docs/specifications/29-spec-opus-4-7-compatibility.md
**Date**: 2026-04-18
**Status**: Complete
**Blocked by**: Epic 29-02-epic-positive-voice-rewrite

## Add must-NOT clauses to acceptance criteria templates
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R5 — Must-NOT clauses

**Acceptance Criteria**:

- `cpm2:spec` Section 6b asks "Are there behaviours this criterion explicitly allows that you would reject?" and captures responses as `must NOT` lines paired with positive criteria [manual]
- `cpm2:epics` Step 3 propagates `must NOT` clauses from spec when present [manual]
- `cpm2:epics` Step 3 proposes `must NOT` clauses when absent on stories touching security, data integrity, or external systems [manual]

**Retro**: [Smooth delivery] Spec and epics skills received complementary additions — spec creates must-NOTs, epics propagates and suggests them — with clean separation of concerns.

### Add must-NOT prompting to spec/SKILL.md Section 6b
**Task**: 1.1
**Description**: During tag assignment, add a question asking whether the criterion explicitly allows behaviours the user would reject. Capture responses as paired `must NOT` lines alongside positive criteria.
**Status**: Complete

### Add must-NOT propagation and suggestion to epics/SKILL.md Step 3
**Task**: 1.2
**Description**: Propagate `must NOT` clauses from spec when present. When absent on stories touching security, data integrity, or external systems, propose them proactively.
**Status**: Complete

---

## Add codebase grounding sections to exploratory skills
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: R8 — Codebase grounding

**Acceptance Criteria**:

- `cpm2:spec` has an explicit grounding instruction requiring codebase exploration before user-facing responses [manual]
- `cpm2:discover` has an explicit grounding instruction requiring codebase exploration before user-facing responses [manual]
- `cpm2:architect` has an explicit grounding instruction requiring codebase exploration before user-facing responses [manual]
- All grounding instructions use positive framing (no negative-only instructions) [manual]

**Retro**: [Smooth delivery] All three skills received consistent "Codebase Grounding (Startup)" sections with the same structure — architect's existing Phase 1 already provided coverage, so its grounding section just made the principle explicit.

### Add codebase grounding section to spec/SKILL.md, discover/SKILL.md, and architect/SKILL.md
**Task**: 2.1
**Description**: Add a "Codebase grounding" section to each skill requiring Read/Glob/Grep against the current codebase before answering user questions. Use positive framing consistent with Epic 29-02's voice rewrite.
**Status**: Complete

## Lessons

### Smooth Deliveries

- Story 1: Spec and epics skills received complementary must-NOT additions with clean separation of concerns — spec creates, epics propagates and suggests.
- Story 2: Codebase grounding sections followed a consistent pattern across all three skills; architect's existing Phase 1 already had coverage so its section just made the principle explicit.
