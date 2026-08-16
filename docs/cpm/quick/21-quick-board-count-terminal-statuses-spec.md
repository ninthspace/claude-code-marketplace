# Board: count Done/Superseded/Withdrawn as done (normalise terminal statuses)

**Date**: 2026-07-20  
**Status**: Complete

## Context

The cross-project board hard-coded exact-match `"Complete"`, so a hand-authored `**Status**: Done` counted as 0 and was never hidden by the `z` toggle (the screenshot bug), and in-flight work to exclude retired (`Superseded`/`Withdrawn`) epics dropped their stories from progress entirely. Following the `/cpm:consult` with Bella (discussion record 26), Chris chose: everything counts, `Done`/`Superseded`/`Withdrawn` all read as done — except that `Superseded`/`Withdrawn` permanently block dependents (that work will never be done). Done via quick execution because the semantics were fully pinned and the change is one predicate pair replacing scattered string matches.

## Acceptance Criteria

### Fix criteria

- A `**Status**: Done` story counts toward the progress fraction (`1/1`, not `0/1`) — **Met** (`test_done_story_counts_toward_progress`).
- A fully-`Done` epic classifies as complete and is hidden by the `z` toggle — **Met** (`test_all_done_stories_resolve_to_complete_state`; `visible_stories` now uses `_is_done`).

### Regression criteria

- No board code path uses a bare `status == "Complete"` for counting/hiding — **Met** (grep: only a `_STORY_STYLE` key, beside `"Done"`, and a type comment remain).

### Change criteria

- A 2-story `Withdrawn` epic reads `2/2` and folds into the project total — **Met** (`derive_project` counts a terminal epic's stories all done; `test_retired_epic_stories_count_as_done` → 3/4).
- An epic depending on a `Superseded`/`Withdrawn` epic stays blocked — **Met** (`test_dependency_on_retired_epic_stays_permanently_blocked`).
- A `Superseded`/`Withdrawn` epic produces no `/cpm:retro` nudge; a `Done` epic without a retro still does — **Met** (`test_retired_epic_does_not_nudge_a_retro`; `_epic_state` returns `complete` for a `Done` epic → retro candidate).
- The `cpm/tools/board` test suite passes — **Met** (191 passed).
- The shared contract and five reader skills describe the count model and accept `Done` — **Met**.

## Changes Made

- `cpm/tools/board/status_model.py` — added `_DONE_STATUSES` + `_is_done()` (case-insensitive Complete/Done) and `_epic_is_terminal()`; flipped `derive_project` progress from exclude→count (terminal epics count all stories as done); `derive_state`, `_epic_state`, and `_deps_satisfied` now use `_is_done` (dependency satisfaction stays Complete/Done only, so retired epics permanently block).
- `cpm/tools/board/board_view.py` — imported `_is_done`; `_progress`, `_is_in_progress`, and `visible_stories` accept `Done`; added `"Done": "green"` to `_STORY_STYLE`; `_inactive_row` kept (status-word label for retired epics).
- `cpm/tools/board/tests/test_derivation.py` — inverted the retired-stories count test (now 3/4); added tests for Done counting, all-Done→complete, Done-dependency-satisfied, retired-dependency-permanently-blocked, and retired-epic-no-retro.
- `cpm/shared/status-model.md` — documented the read-tolerant `Done` rule, the count model (all epics, terminal epics count all stories done), the updated states table, and the dependency split in *Retired epics*.
- `cpm/skills/{status,do,ralph,archive,epics}/SKILL.md` — readers accept `Done` as a `Complete` synonym; `status` skill's "excluded from counts" flipped to "count as done"; `do` unblock rule notes retired deps never satisfy; `epics` keeps write-strict (`Done` never emitted).

## Verification

Ran `cd cpm/tools/board && uv run pytest` — 191 passed. Grepped board `.py` for residual exact `"Complete"` matches (only a style-dict key beside `"Done"` and a type comment remain — neither is a counting/hiding path). Grepped contract and skills for stale "excluded from counts" prose — none remain (the sole match is the corrected epics line, which now says stories count as done). Self-assessed each criterion against the code and the new tests.

## Retro

**Codebase discovery**: The change landed on top of Chris's in-flight "retired = excluded" implementation and had to *reverse* its counting half while preserving its dependency-blocking half — the consult surfaced that "treat as complete" splits into two distinct predicates (done-for-counting vs satisfies-dependency), which is what kept the reversal from breaking the permanent-block behaviour.
