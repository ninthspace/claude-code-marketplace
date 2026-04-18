# Execution Safety

**Source spec**: docs/specifications/29-spec-opus-4-7-compatibility.md
**Date**: 2026-04-18
**Status**: Complete
**Blocked by**: Epic 29-02-epic-positive-voice-rewrite

## Add Termination sections to execution loops
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R2 — Stop criteria

**Acceptance Criteria**:

- `/cpm2:do` per-task workflow loop has a Termination section with Success, Blocker, and Ambiguity exits [manual]
- `/cpm2:do` Step 4 verification gate has explicit round limits before treating as a blocker [manual]
- `/cpm2:spec` facilitation loops have explicit "good enough" termination criteria that prevent 4.7 overthinking [manual]
- `/cpm2:epics` facilitation loops have explicit "good enough" termination criteria [manual]
- All Termination sections follow the same triplet format (consistency NFR) [manual]

**Retro**: [Smooth delivery] Three skills needed Termination sections with a consistent format — the triplet pattern (Success/Blocker/Ambiguity) plus a facilitation-depth clause made it straightforward to adapt to each skill's loop type.

### Add Termination sections to do/SKILL.md loops
**Task**: 1.1
**Description**: Covers the per-task workflow loop (success: no more unblocked tasks; blocker: external dependency; ambiguity: criteria can't be evaluated) and the Step 4 verification gate (explicit AskUserQuestion round limit before treating as blocker).
**Status**: Complete

### Add Termination sections to spec/SKILL.md and epics/SKILL.md facilitation loops
**Task**: 1.2
**Description**: Covers all "refine with the user" loops in both skills. Define when facilitation is "good enough" to prevent 4.7 adaptive thinking from stalling on perfect facilitation.
**Status**: Complete

---

## Rewrite Graceful Degradation sections with explicit fallbacks
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: R4 — Fallback rules

**Acceptance Criteria**:

- Every degradation scenario in `do/SKILL.md` specifies an explicit action sequence ending with a visible result [manual]
- TDD-tagged story without test runner produces a visible artefact via AskUserQuestion (not silent degradation) [manual]
- Every degradation scenario in `pivot/SKILL.md` specifies an explicit action with visible result [manual]
- Every degradation scenario in `review/SKILL.md`, `library/SKILL.md`, and `architect/SKILL.md` specifies explicit fallback actions [manual]
- All Graceful Degradation entries follow the same format: scenario → action → result (consistency NFR) [manual]

**Retro**: [Pattern worth reusing] The `→ **Action**: ... **Result**:` format for degradation scenarios proved highly greppable — one regex confirms consistency across all 31 entries in 5 files.

### Rewrite Graceful Degradation in do/SKILL.md
**Task**: 2.1
**Description**: 7 degradation scenarios (no epic doc, deleted mid-loop, heading not found, test command fails, test failures, no test command, no test + TDD story). Each gets explicit action sequence + visible result. TDD without runner must use AskUserQuestion.
**Status**: Complete

### Rewrite Graceful Degradation in pivot/SKILL.md and review/SKILL.md
**Task**: 2.2
**Description**: pivot has 5 scenarios (no docs, path not found, back-refs fail, no downstream, no tasks). review has its own degradation section. Apply the standard format to both.
**Status**: Complete

### Add explicit fallbacks to library/SKILL.md and architect/SKILL.md
**Task**: 2.3
**Description**: library has scattered graceful degradation notes; architect has ADR-not-found scenarios. Convert to the standard explicit-action-with-visible-result format.
**Status**: Complete

## Lessons

### Smooth Deliveries

- Story 1: Termination sections were straightforward — the triplet pattern plus facilitation-depth clause adapted cleanly to three different skill loop types.

### Patterns Worth Reusing

- Story 2: The `→ **Action**: ... **Result**:` format is highly greppable — one regex confirms consistency across all 31 entries in 5 files. Worth standardising for any future skills.
