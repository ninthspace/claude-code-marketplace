# Spec Mode Input

**Source spec**: docs/specifications/45-spec-delivery-autonomy.md
**Date**: 2026-07-26
**Status**: Complete
**Blocked by**: —
**Retro applied**: 21 · Testing gap · Applied — Story 3's must-NOT quotes the very message it forbids, so every `assert_not_contains` is scoped to Step 1a's stop condition, where the string would be an instruction, never to the whole file.
**Retro applied**: 25 · Codebase discovery · Applied — Story 2's "no documented invocation changed" is checked by reading each shape out of `ralph`'s Input section at test time rather than re-typing it into an assertion.
**Retro applied**: 24 · Pattern worth reusing · Applied — Story 2 looks for the one behavioural assertion with a real oracle rather than surveying the Input section, per 44-03's Story 2.
**Retro applied**: 25 · Pattern worth reusing · Applied — Story 4 derives the shape list and the outcome list from opposite ends and enumerates all eight combinations, so a fifth shape fails the count until it is given an outcome.

## Resolve a spec path as the fourth input shape
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR1

**Acceptance Criteria**:

- A path under `docs/specifications/` resolves spec mode; epic paths or a range resolve epic mode; nothing resolves auto-discovery [integration]
- must NOT require a flag to select the mode [integration]

### Add spec-path detection to Input and Step 1a
**Task**: 1.1
**Description**: Covers both criteria. Mode detection comes from the path itself, which is what makes the flag unnecessary — `cpm:ralph`'s Input already parses three shapes, so this adds a fourth branch rather than a new parameter. Scoped to *resolving* the mode; what pre-flight then does with zero epics is Story 3.
**Status**: Complete

### Write tests for Resolve a spec path as the fourth input shape
**Task**: 1.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Complete

**Retro**: [Testing gap] `test-ralph-promise.sh` pinned the fallback sentence *"If no epic paths are provided"* verbatim as an FR2 regression net, so the suite would have defended the exact wording that routes a spec path into auto-discovery — a verbatim net protects a sentence's defects alongside its behaviour, and only reading the sentence against the new shape caught it.

---

## Preserve every existing invocation
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR2

**Acceptance Criteria**:

- Empty arguments still auto-discover all incomplete epics [integration]
- must NOT change the behaviour of any existing documented invocation [integration]

### Assert each existing shape against its documented behaviour
**Task**: 2.1
**Description**: Adds nothing; it fences what Story 1 could break. The same shape as epic 44-03's Story 2, which is the precedent worth copying — including its finding that the behaviour worth asserting is the one place the change actually couples to the existing shapes, not a survey of the whole Input section.
**Status**: Complete

### Write tests for Preserve every existing invocation
**Task**: 2.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Complete

**Retro**: [Testing gap] Both defects this story found were in its own assertions rather than in `cpm:ralph` — a classifier that read only the first directory a table row named, and a flag extractor that counted every mention of `--story-filter` on a line as a separate flag — and neither surfaced as a failure: the first was caught by a control that refused to trip, the second by reading three identically-named PASS lines in the output.

---

## Tolerate zero epics in spec mode
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: FR3

**Acceptance Criteria**:

- With a spec path and zero epics on disk, pre-flight proceeds to phase 1 [integration]
- must NOT emit "No incomplete epics found. Nothing to run." when a spec path was given [integration]

### Branch Step 1a's zero-epic stop on mode
**Task**: 3.1
**Description**: Covers both criteria. Step 1a step 3 currently stops unconditionally on zero runnable epics; in spec mode that state is the starting line. The stop must survive unchanged for the other three input shapes — a mode-blind removal would break FR2.
**Status**: Complete

### Write tests for Tolerate zero epics in spec mode
**Task**: 3.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Complete

**Retro**: [Pattern worth reusing] Pinning a string that must exist in one branch and not in its sibling took **three** assertions from different directions — absent from the spec bullet, present in the epic bullet, and present exactly once in the whole step — because any one of them alone is satisfied by a wrong edit that the other two catch; this is the shape to reuse whenever a must-NOT forbids a string that a neighbouring rule requires.

---

## Verify cross-story integration for Spec Mode Input
**Story**: 4
**Status**: Complete
**Blocked by**: Story 1, Story 2, Story 3
**Satisfies**: FR1, FR2, FR3

**Acceptance Criteria**:

- Each of the four input shapes reaches its documented pre-flight outcome, with zero epics on disk and with epics present [integration]

### Write integration tests for Spec Mode Input
**Task**: 4.1
**Description**: The cross-story point is the matrix of four shapes against two disk states. Story 3 changes what zero epics means, but only for one of the four shapes — the combination is where a mode-blind edit shows up, and no single story's criteria reach it.
**Status**: Complete

**Retro**: [Criteria gap] The first cross-story measurement written — *how many shapes are sensitive to the disk state* — reads like the right one and does not discriminate, because a spec branch that wrongly stops is still different from the same branch with epics present; only *how many shapes stop on an empty disk* moves under a mode-blind edit, and the difference surfaced solely because the control was written to fail and then checked.

**Inline change**: recorded the undocumented cell — explicit epic paths or a range that resolve to zero files have no documented pre-flight outcome — in this epic's Notes rather than repairing it, being pre-existing and outside spec 45's scope (2026-07-27)

---

## Notes

**The four shapes and the two states are the real subject.** Stories 1–3 each assert one shape's behaviour; the failure this epic is most exposed to is a change that is correct for the shape it was written for and wrong for one of the other three. Story 4 asserts the eight combinations rather than restating any story's criterion.

**Epic 44-03's Story 2 is the precedent for Story 2 here**, including its lesson: asserting "nothing changed" across a whole documented surface is mostly regression netting, and the one assertion with a real oracle was the behavioural one — running the thing for a shape that produces more than one value. Look for that assertion here rather than settling for a survey.

**One cell of Story 4's matrix has no documented outcome, and it predates this epic.** Explicit epic paths or a range that resolve to *zero* files reach Step 1a's "resolve them (expand globs)" and nothing else: the zero-epic stop lives in the auto-discovery branch, which explicit paths bypass, so a mistyped path launches a loop over an empty list rather than stopping. Story 4's per-cell assertions pass on this because the instruction that fires *is* documented — what is missing is a stop, not a sentence. Left alone deliberately: the behaviour is unchanged from before spec mode, so repairing it would be the mode-blind edit FR2's must-NOT forbids, and spec 45 covers spec mode rather than argument validation. Recorded so a later reader sees the cell was examined rather than overlooked.
