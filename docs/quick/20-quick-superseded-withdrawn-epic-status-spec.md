# Add Superseded and Withdrawn epic statuses

**Date**: 2026-07-20  
**Status**: Complete

## Context

Chris wanted a way to retire epics whose work is no longer necessary, so they can be swept up during a docs cleanup. Added two terminal, **user-set** epic statuses — `Superseded` (work replaced by other work) and `Withdrawn` (work dropped) — recognised as inactive everywhere active work is enumerated, and swept by `/cpm:archive`. CPM never sets them itself. Done via quick execution (broad but shallow, additive, follows the existing status pattern).

## Acceptance Criteria

- The board treats a `Superseded`/`Withdrawn` epic as inactive: excluded from project state, next actions, and story-progress totals, never an actionable candidate. — Met
- Inactive epics render dimmed/reference-only, shown only under `show_complete`, labelled with their status word. — Met
- A project whose only remaining epics are inactive (or complete) resolves to `complete`. — Met
- `/cpm:do`, `/cpm:ralph`, `/cpm:status` skip inactive epics when looking for work (documented). — Met
- `/cpm:archive` flags `Superseded`/`Withdrawn` epics as stale (new Signal 5; Signal 4 also treats retired epics as resolved). — Met
- `/cpm:epics` documents both values as manual, terminal, never auto-derived. — Met
- The shared status-model contract documents the statuses and their handling. — Met
- Board test suite passes, including new inactive-epic tests. — Met (185 passed)

## Changes Made

- `cpm/tools/board/status_model.py` — added `INACTIVE_EPIC_STATUSES = {"Superseded", "Withdrawn"}` and `_is_inactive`. `derive_state` excludes inactive epics (all-inactive → `COMPLETE`); dependency resolution still sees the full epic list. `_epic_state` returns `"inactive"` (no next-action branch matches). `derive_project` counts progress over active epics only.
- `cpm/tools/board/board_view.py` — imported `INACTIVE_EPIC_STATUSES`; added `_inactive_row` (dimmed, action-less, labelled with the status word); `epic_rows` renders inactive epics via it under `show_complete`.
- `cpm/shared/status-model.md` — updated the Epic-status input row, story-progress definition, and `complete` state condition; added a **Retired epics** section documenting the full contract.
- `cpm/skills/epics/SKILL.md` — documented `Superseded`/`Withdrawn` as terminal, user-set, never auto-derived.
- `cpm/skills/do/SKILL.md` — both epic-selection filters (initial + continue-to-next) exclude retired epics; "nothing to do" covers them.
- `cpm/skills/ralph/SKILL.md` — incomplete-epic discovery excludes retired epics.
- `cpm/skills/status/SKILL.md` — "remaining work" filter excludes retired epics; they're summarised as a count with an archive suggestion.
- `cpm/skills/archive/SKILL.md` — four → five signals; new **Signal 5 — Retired epic**; Signal 4 broadened to "resolved" (Complete or retired); added `[epic superseded]`/`[epic withdrawn]` labels. **Follow-up correction**: Signal 5 initially flagged the retired epic's *whole chain* as stale, which would archive the spec and live sibling epics on a mixed chain. Tightened so a retired epic on a chain that still has active epics is a **standalone archivable unit** (just the epic doc + its coverage) — the spec and live siblings stay; only Signal 4 (whole chain resolved) pulls the spec. Updated the Step 3 presentation, the individual-selection flow, and the Step 4 completeness guard (standalone-move exception) to match.
- Tests — `tests/test_derivation.py`: retired-epic exclusion from state (parametrized over both statuses), all-retired → complete, progress-count exclusion, next-action exclusion. `tests/test_board_view.py`: dimmed reference-row rendering labelled by status.

## Verification

Full board suite via `uv run --with textual --with pytest --with pytest-asyncio pytest tests/` — **185 passed** (was 178; +7 new). New tests assert: a retired epic alongside a Complete epic yields `COMPLETE` (not in-progress); an all-retired project is `COMPLETE`; retired stories don't count toward progress (`1/2`, not `1/4`); retired epics never appear in `next_actions`; and they render dimmed/reference-only labelled "Superseded". Skill/contract changes verified by re-reading each edited region; a repo-wide grep confirmed no other "not Complete" epic filter was left unpatched.

## Retro

**Scope surprise**: A conceptually tiny feature (two new status strings) had a wide blast radius because "is this epic active work?" is asked independently in the board code and in four separate skills plus the shared contract. The clean seam was a single `INACTIVE_EPIC_STATUSES` set + `_is_inactive` helper in the board, mirrored by one consistent phrase ("not `Complete` and not retired") across the skills — keeping the vocabulary in one place per layer stopped the change from fragmenting.
