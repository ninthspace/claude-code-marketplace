# Resume and Convergence

**Source spec**: docs/specifications/45-spec-delivery-autonomy.md
**Date**: 2026-07-26
**Status**: Pending
**Blocked by**: Epic 45-03-epic-phase-detection

## Resume a partial phase 1 within a session
**Story**: 1
**Status**: Pending
**Blocked by**: —
**Satisfies**: FR9, NFR6

**Acceptance Criteria**:

- Re-entering phase 1 with epics already on disk continues rather than restarting, and writes no duplicate epic doc [integration]
- Resume duplicates no epic doc and renumbers none [integration]

### Define the same-session resume path
**Task**: 1.1
**Description**: Covers both criteria. `cpm:epics` saves incrementally — each epic doc and its matrix are written before the next epic is started — so an interrupted phase 1 leaves a real partial set plus a progress file recording the plan. Within a session that progress file is the current session's own and is hook-injected as active state, so this task defines what the loop does with it rather than building new detection.
**Status**: Pending

### Write tests for Resume a partial phase 1 within a session
**Task**: 1.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Epic sub-numbers are identifiers rather than ordinals and gaps are preserved deliberately, so a renumbering assertion has to distinguish a preserved gap from a renumber.
**Status**: Pending

---

## Detect a leftover progress file across sessions [plan]
**Story**: 2
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: FR12

**Acceptance Criteria**:

- Spec-mode pre-flight detects a leftover `cpm:epics` progress file for the same spec even when the guard returns `SUPPRESS` [integration]
- must NOT delete or overwrite that progress file without surfacing it [integration]

### Add the cross-session detection to spec-mode pre-flight
**Task**: 2.1
**Description**: Covers both criteria. The Stale-Progress guard prints `SUPPRESS` while `.claude/ralph-loop.local.md` exists — the FR11 autonomous carve-out, deliberate and not to be removed. This task adds a detection path that does not depend on the guard, scoped to spec mode and to a progress file naming the same spec. The shared deletion rule stands: no path auto-executes a delete.
**Status**: Pending

### Write tests for Detect a leftover progress file across sessions
**Task**: 2.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The negative control is the guard still returning `SUPPRESS` — if the change worked by weakening the guard, the carve-out is gone and other skills lose their silence during ralph runs.
**Status**: Pending

---

## Report counts and stop on non-convergence
**Story**: 3
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: FR11

**Acceptance Criteria**:

- Each iteration reports traced and verified counts; a run whose counts are unchanged across N consecutive iterations stops and reports [integration]
- must NOT continue past the non-convergence threshold without reporting [integration]

### Add the per-iteration count report and the threshold
**Task**: 3.1
**Description**: Covers both criteria. Spec 44's FR10 made the counts stable between runs, which is what makes comparing them across iterations meaningful; nothing consumes them yet. This is also the mechanism that turns AD1's stated consequence — a Must Have no epic covers means phase 1 never completes — from fifty silent iterations into a stop with a named cause.
**Status**: Pending

### Write tests for Report counts and stop on non-convergence
**Task**: 3.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Pending

---

## Notes

**No integration testing story, and the reason is not that the epic is small.** Convergence (Story 3) is independent of resume (Stories 1–2). The one genuine cross-story case — resume across sessions, then converge without duplicating — requires a live loop, and nothing in this suite launches one. Asserting it structurally would produce exactly the failure retro 21 named: an assertion that confirms words exist and never that a condition was honoured.

**Story 2 carries `[plan]` because it is the only work in spec 45 that reaches into shipped safety-net behaviour.** The guard's `SUPPRESS` was designed to keep every skill silent during ralph runs; adding a path around it for one skill in one mode is a design decision worth agreeing before implementation, not during it.

**This epic is the safety net over a loop that must first exist**, which is why it is blocked by 45-03 rather than running alongside it. Stories 1 and 3 both assume a phase-1 that can be re-entered and counts that can be compared.
