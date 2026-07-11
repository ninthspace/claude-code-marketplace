# Deferred Items Resolution (R9, R10)

**Source spec**: docs/specifications/30-spec-cpm2-post-switch-refinements.md
**Date**: 2026-04-18
**Status**: Complete
**Blocked by**: —

> **Note**: Spec 29 deferred R9 (TDD compression), R10 (`[plan]` heuristic), and R11 (ralph scaffolding). R11 is resolved by Epic 30-02 Story 1 (ralph Permissions Check removal). This epic resolves R9 and R10.

## Sharpen `[plan]` tag assignment heuristic in epics
**Story**: 1
**Status**: Complete
**Retro**: [Smooth delivery] Surgical change — replaced three vague categories (Architectural/Security-sensitive/Multi-system) with three explicit ones (Data model/API contract/Cross-system) and added workflow-lock rationale. do/SKILL.md confirmed unchanged via zero-diff baseline check.
**Blocked by**: —
**Satisfies**: R7 — `[plan]` heuristic sharpening (resolves Spec-29 R10)

**Acceptance Criteria**:

- `cpm2/skills/epics/SKILL.md` `[plan]` tag heuristic names three explicit categories as the assignment criteria: data model changes, API contract changes, cross-system integration [manual]
- The prior phrasing ("architecture, security, or multi-system integration" or equivalent loose phrasing) is removed [manual]
- `[plan]` tag behaviour in `cpm2/skills/do/SKILL.md` is unchanged — the tag still triggers EnterPlanMode and the approval gate before code writing [manual]
- The heuristic update includes a one-sentence rationale explaining that the tag's function is a workflow lock (forced pause before implementation), not a signal that the story is hard [manual]
- must NOT: the sharpened heuristic removes the user's ability to add `[plan]` manually to any story they want gated — the categories are defaults, not restrictions [manual]

### Update `[plan]` heuristic in cpm2:epics
**Task**: 1.1
**Description**: Edit `cpm2/skills/epics/SKILL.md` to replace the current `[plan]` tag assignment heuristic with the three explicit categories (data model changes, API contract changes, cross-system integration). Add a one-sentence rationale clarifying the tag's function as a workflow lock. Confirm that the skill's instruction permits manual tag addition beyond the default categories when the user wants additional stories gated.
**Status**: Complete

### Verify `[plan]` tag behaviour in cpm2:do is unchanged
**Task**: 1.2
**Description**: Diff `cpm2/skills/do/SKILL.md` against the Spec-29 baseline (commit 513656c) for the `[plan]` tag handling section. Confirm the EnterPlanMode gate, the approval-before-code-writing requirement, and the tag-absent inline mode are unchanged. This is the `[manual]` verification that R7 is a surgical change scoped to epics.
**Status**: Complete
**Retro**: [Smooth delivery] Zero diff on [plan]-related lines between baseline and current — the change was correctly scoped to epics only.

---

## Document TDD sub-loop disposition (intentionally preserved)
**Story**: 2
**Status**: Complete
**Retro**: [Smooth delivery] Single 2-sentence blockquote added before Phase 1. Zero diff on all three TDD phases confirmed via baseline comparison — the rationale note is purely additive.
**Blocked by**: —
**Satisfies**: R8 — R9 disposition note (resolves Spec-29 R9)

**Acceptance Criteria**:

- `cpm2/skills/do/SKILL.md` TDD sub-loop (the red-green-refactor section triggered by `[tdd]` story tag) carries an inline rationale line documenting that the three-phase structure is a behavioural lock — not instructional verbosity — and is intentionally preserved [manual]
- The rationale line is short (one to two sentences) and placed adjacent to the three-phase structure so a future refactor reviewer encounters it in context [manual]
- No change to the TDD sub-loop's instructional content — the red, green, and refactor phases still carry their mandatory test outcomes (must fail before implementation, must pass after implementation, must still pass after refactor) [manual]

### Add rationale note to TDD sub-loop
**Task**: 2.1
**Description**: Edit `cpm2/skills/do/SKILL.md` to add a brief inline rationale line adjacent to the TDD sub-loop's three-phase structure. The line should record that the three phases (red / green / refactor) and their mandatory test outcomes are preserved deliberately to enforce test-before-implementation ordering, not because 4.7 needs the detail spelled out. Target length: one to two sentences. Place it before the red phase so readers encounter the rationale first.
**Status**: Complete

## Lessons

### Context

Spec 29 shipped R9 (TDD compression), R10 (`[plan]` heuristic review), and R11 (ralph scaffolding review) as deferred items — they required 4.7 observation before resolution. Post-switch review (captured in the audit that produced Spec 30) concluded:

- **R9 → keep as-is**: The 25-line red-green-refactor structure is a behavioural lock on test-before-implementation ordering, not an instructional scaffold. Compression risks losing the ordering guarantee.
- **R10 → sharpen the heuristic**: The tag's EnterPlanMode gate remains load-bearing; the assignment criteria can tighten to three explicit categories.
- **R11 → remove Permissions Check**: Pre-flight validation of uncommitted permissions state is speculative under 4.7; runtime graceful degradation is deterministic. Resolved by Epic 30-02 Story 1.

### Smooth Deliveries

- Story 1: Surgical change — replaced three vague categories with three explicit ones and added workflow-lock rationale. do/SKILL.md confirmed unchanged via zero-diff.
- Story 2: Single 2-sentence blockquote added before Phase 1. Zero diff on all three TDD phases — purely additive change.
