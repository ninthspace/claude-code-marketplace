# /cpm:retro triage — waive clean epics

**Date**: 2026-07-20  
**Status**: Complete

## Context

Clean epics (finished with no `cpm:do` retro-trigger signal) legitimately have no retro, yet the board and `/cpm:status` flag every retro-less completed epic as "retro pending" forever — with no way to dismiss it short of writing a retro or archiving. This adds a `/cpm:retro triage` verb to scan completed epics and waive the clean ones, plus a `**Retro waived**:` marker the board/status/contract honour so the nag stops.

## Acceptance Criteria

- `/cpm:retro triage` lists complete epics, waives only clean ones after confirmation, and writes `**Retro waived**:` idempotently after the epic's `**Status**:`. — **Met** (Triage section in `retro/SKILL.md`: Step T1 scan/classify, Step T2 confirm-per-epic + insert-after-Status + idempotency guard)
- Epics with substantive inline observations are reported as "consider `/cpm:retro <epic>`" but not waived; epics with an existing retro are left alone. — **Met** (Step T1 classification: waivable vs has-observations vs already-settled)
- A complete epic bearing `**Retro waived**:` produces no `/cpm:retro` next-action and no board retro row/summary; an un-waived one still does. — **Met** (`test_retro_waived_epic_yields_no_retro_candidate`, `test_complete_epic_without_waiver_or_retro_still_recommends_retro`, `test_waived_complete_epic_shows_no_retro_row_or_summary`)
- `parse_epic` exposes the marker via `Epic.retro_waived`. — **Met** (`test_parse_epic_reads_the_retro_waived_marker`)
- The contract (`status-model.md`) and `/cpm:status` document/honour the marker; bare `/cpm:retro` (no-arg synthesis) is unchanged. — **Met** (status-model *Retro waiver* section + rule-5 amendment; status skill deep-read note + decision-table rows; synthesis input path untouched)
- The `cpm/tools/board` test suite passes. — **Met** (**213 passed**)

## Changes Made

- `cpm/skills/retro/SKILL.md` — added `triage` as a fourth mutually-exclusive mode (Input list + mode-selection bullet) and a **Triage (`triage` action)** section: Step T1 scans completed epics and classifies them (already-settled / waivable-clean / has-observations) using only durable signals (no retro file, inline `**Retro**:` categories, `**Inline change**` breadcrumbs); Step T2 confirms per-epic and writes the idempotent `**Retro waived**: {date} — clean epic…` marker after the epic-level `**Status**:`.
- `cpm/tools/board/status_model.py` — added `Epic.retro_waived: bool`; `parse_epic` sets it from `_field(preamble, "Retro waived")`; next-action step 5 skips the retro candidate when `epic.retro_waived` (alongside the existing `_epic_has_retro`).
- `cpm/shared/status-model.md` — new *Retro waiver* section; rule 5 amended to "lacking a retro **and not waived**".
- `cpm/skills/status/SKILL.md` — epic deep-read honours the marker; decision-table rows updated (waived complete epic = retro-satisfied, no suggestion).
- `cpm/tools/board/tests/test_derivation.py` — `epic_md` gained an optional `retro_waived` arg; added `test_parse_epic_reads_the_retro_waived_marker`.
- `cpm/tools/board/tests/test_next_actions.py` — added waived-epic-no-candidate and un-waived-still-nudges tests.
- `cpm/tools/board/tests/test_board_view.py` — added an end-to-end `derive_project`→`epic_rows` test that a waived epic shows no retro row/summary.

## Verification

Ran `cd cpm/tools/board && uv run pytest` — **213 passed** (209 prior + 4 new). The board change is minimal and mirrors the existing retired-epic exclusion and `_epic_has_retro` guard; the waiver flows through to the board's cyan-row/summary logic automatically (a waived epic emits no retro `NextAction`, so `epic_rows` renders neither). Skill/contract prose cross-references `cpm/shared/status-model.md` *Retro waiver* as the single source of truth.

## Retro

**Pattern worth reusing**: Threading the waiver through a single chokepoint — suppressing the retro `NextAction` in `compute_next_actions` step 5 — meant the board's cyan row *and* the record-23 "retro pending" summary both stopped for waived epics with no board_view change at all; killing the signal at its source beats teaching every downstream renderer about the new state.
