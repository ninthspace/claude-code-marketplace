# Coverage Matrix: Deferred Items Resolution (R9, R10)

**Source spec**: docs/specifications/30-spec-cpm2-post-switch-refinements.md
**Epic**: docs/epics/30-03-epic-deferred-items-resolution.md
**Date**: 2026-04-18

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R7 — `[plan]` heuristic sharpening | `cpm2:epics` heuristic lists data model / API contract / cross-system integration as the assignment categories | `cpm2/skills/epics/SKILL.md` `[plan]` tag heuristic names three explicit categories as the assignment criteria: data model changes, API contract changes, cross-system integration | Story 1 | `[manual]` | ✓ |
| 2 | R7 — `[plan]` heuristic sharpening | `[plan]` tag behaviour in `cpm2:do` (EnterPlanMode gate) is unchanged | `[plan]` tag behaviour in `cpm2/skills/do/SKILL.md` is unchanged — the tag still triggers EnterPlanMode and the approval gate before code writing | Story 1 | `[manual]` | ✓ |
| 3 | R8 — R9 disposition note | `cpm2:do` TDD section carries an inline rationale line documenting the behavioural-lock intent | `cpm2/skills/do/SKILL.md` TDD sub-loop (the red-green-refactor section triggered by `[tdd]` story tag) carries an inline rationale line documenting that the three-phase structure is a behavioural lock — not instructional verbosity — and is intentionally preserved | Story 2 | `[manual]` | ✓ |
