# Spec Mode Input

**Source spec**: docs/specifications/45-spec-delivery-autonomy.md
**Date**: 2026-07-26
**Status**: Pending
**Blocked by**: —

## Resolve a spec path as the fourth input shape
**Story**: 1
**Status**: Pending
**Blocked by**: —
**Satisfies**: FR1

**Acceptance Criteria**:

- A path under `docs/specifications/` resolves spec mode; epic paths or a range resolve epic mode; nothing resolves auto-discovery [integration]
- must NOT require a flag to select the mode [integration]

### Add spec-path detection to Input and Step 1a
**Task**: 1.1
**Description**: Covers both criteria. Mode detection comes from the path itself, which is what makes the flag unnecessary — `cpm:ralph`'s Input already parses three shapes, so this adds a fourth branch rather than a new parameter. Scoped to *resolving* the mode; what pre-flight then does with zero epics is Story 3.
**Status**: Pending

### Write tests for Resolve a spec path as the fourth input shape
**Task**: 1.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Pending

---

## Preserve every existing invocation
**Story**: 2
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: FR2

**Acceptance Criteria**:

- Empty arguments still auto-discover all incomplete epics [integration]
- must NOT change the behaviour of any existing documented invocation [integration]

### Assert each existing shape against its documented behaviour
**Task**: 2.1
**Description**: Adds nothing; it fences what Story 1 could break. The same shape as epic 44-03's Story 2, which is the precedent worth copying — including its finding that the behaviour worth asserting is the one place the change actually couples to the existing shapes, not a survey of the whole Input section.
**Status**: Pending

### Write tests for Preserve every existing invocation
**Task**: 2.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Pending

---

## Tolerate zero epics in spec mode
**Story**: 3
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: FR3

**Acceptance Criteria**:

- With a spec path and zero epics on disk, pre-flight proceeds to phase 1 [integration]
- must NOT emit "No incomplete epics found. Nothing to run." when a spec path was given [integration]

### Branch Step 1a's zero-epic stop on mode
**Task**: 3.1
**Description**: Covers both criteria. Step 1a step 3 currently stops unconditionally on zero runnable epics; in spec mode that state is the starting line. The stop must survive unchanged for the other three input shapes — a mode-blind removal would break FR2.
**Status**: Pending

### Write tests for Tolerate zero epics in spec mode
**Task**: 3.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Pending

---

## Verify cross-story integration for Spec Mode Input
**Story**: 4
**Status**: Pending
**Blocked by**: Story 1, Story 2, Story 3
**Satisfies**: FR1, FR2, FR3

**Acceptance Criteria**:

- Each of the four input shapes reaches its documented pre-flight outcome, with zero epics on disk and with epics present [integration]

### Write integration tests for Spec Mode Input
**Task**: 4.1
**Description**: The cross-story point is the matrix of four shapes against two disk states. Story 3 changes what zero epics means, but only for one of the four shapes — the combination is where a mode-blind edit shows up, and no single story's criteria reach it.
**Status**: Pending

---

## Notes

**The four shapes and the two states are the real subject.** Stories 1–3 each assert one shape's behaviour; the failure this epic is most exposed to is a change that is correct for the shape it was written for and wrong for one of the other three. Story 4 asserts the eight combinations rather than restating any story's criterion.

**Epic 44-03's Story 2 is the precedent for Story 2 here**, including its lesson: asserting "nothing changed" across a whole documented surface is mostly regression netting, and the one assertion with a real oracle was the behavioural one — running the thing for a shape that produces more than one value. Look for that assertion here rather than settling for a survey.
