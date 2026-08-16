# Board: hide complete-but-not-retro'd epics under show/hide-done, keep a retro summary

**Date**: 2026-07-20  
**Status**: Complete

## Context

On a real board (hlh-net-promoter-score) 11 completed epics stayed pinned in cyan and the "show/hide done" toggle couldn't clear them — because a complete-but-not-retro'd epic is surfaced as an actionable `retro` candidate, and the toggle only governs the dimmed complete-AND-retro'd / retired reference rows. Since retros aren't mandatory in CPM, pinning them indefinitely was wrong. Fixed via quick execution: hide them with the toggle, but roll the retro nudge into one summary line so it isn't lost.

## Acceptance Criteria

- With show-complete OFF, a complete-but-not-retro'd epic does not appear as its own row; a single `⟳ N … retro pending` summary row appears instead. — **Met** (`test_toggle_off_collapses_retro_candidates_into_a_summary`)
- The summary row has `action=None` and `epic=None` (not launchable, copyable, or ralph-selectable). — **Met** (`test_retro_summary_row_is_not_launchable`; all consumer paths in `board.py` already guard `action is None`)
- Count is accurate and reads "epic" (singular) for 1, "epics" otherwise. — **Met** (singular asserted in the collapse test; plural in `test_retro_summary_counts_and_pluralises`)
- With show-complete ON, individual cyan retro rows appear as before and no summary row is shown. — **Met** (`test_toggle_on_shows_individual_retro_rows_and_no_summary`)
- Counting, state, and dependency logic are unchanged; the board test suite passes. — **Met** (change is confined to `epic_rows` presentation; **204 passed**)

## Changes Made

- `cpm/tools/board/board_view.py` — `epic_rows` now skips `retro`-kind candidates when `show_complete` is off, counting them into `retro_pending`; when that count is > 0 it appends one `_retro_summary_row(n)`. Added `_retro_summary_row()` helper plus `_RETRO_SUMMARY_STYLE` (cyan, matching the per-epic nudge) and `_RETRO_GLYPH` (`⟳`). The summary carries `action=None`/`epic=None`, so it's inert like the existing dimmed reference rows. Under `show_complete=True` behaviour is unchanged (individual rows shown, no summary).
- `cpm/tools/board/tests/test_board_view.py` — added a `_retro()` helper and four tests (collapse-to-summary, non-launchable, count/pluralise, toggle-on-shows-individual-rows). Updated `test_epic_rows_are_ordered_for_display_not_by_engine_priority` to pass `show_complete=True` — its intent is candidate display-ordering (unchanged `_row_rank`), which is now only visible when retro rows are shown inline; the collapsed default is covered by the new tests.

## Verification

Ran `cd cpm/tools/board && uv run pytest` — **204 passed** (200 prior + 4 new). Confirmed by inspection that `board.py`'s launch/copy/ralph paths (`_is_ralph_eligible:1030`, `action_copy:1156`, `action_launch:1236`) all early-return on `action is None`, so the summary row cannot be acted on. The summary is appended after the ranked candidates, so it reads at the bottom of the epics column — below actionable work, which is the correct priority for a "reflect later" nudge.

## Retro

**Testing gap**: An existing ordering test silently depended on retro rows being shown in the default view; the behaviour change surfaced it as a failure, and the fix was to make the test assert the ordering under the toggle that actually shows those rows. A reminder that "display ordering" tests should pin the view mode they mean to exercise.
