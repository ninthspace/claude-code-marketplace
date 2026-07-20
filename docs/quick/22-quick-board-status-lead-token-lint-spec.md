# Board: lead-token status parsing + lint unrecognised statuses

**Date**: 2026-07-20  
**Status**: Complete

## Context

Real project statuses carry human notes (`Complete — folded into Story 10; do not execute separately`) and occasionally off-vocabulary prose (`Folded into Story 10 …`). Following the terminal-status counting work (record 21) and a consult with Bella, Chris chose two composed capabilities — read the canonical status by its leading token (ignoring the note tail), and *surface* rather than silently count anything unrecognised — done via quick execution because the change was well-scoped and pattern-following.

## Change

The board now reads a status field as a **canonical leading token plus an ignored human note** (`Complete — folded into Story 10` → `Complete`), applied consistently to every status predicate (pending / in-progress / done). Any non-empty status whose leading token isn't in the recognised vocabulary is **surfaced, not silently counted** — it still counts as not-done (conservative) but is flagged so a human or a `/cpm` skill can normalise it. `/cpm:do` and `/cpm:pivot` preserve an existing `— note` tail through status transitions.

## Files Changed

- `cpm/tools/board/status_model.py` — added `_status_token()` (head before the first `—`/`–`/`(`/`;`/spaced-hyphen delimiter); made `_is_done` and new `_is_pending`/`_is_in_progress` token-based; added `_is_recognised_status(status, *, epic)`; `_is_inactive`, `derive_state`, `_epic_state`, `_unblocked_pending`, `_blocking_deps`, `_deps_satisfied` all route through the token predicates.
- `cpm/tools/board/board_view.py` — token-based `_story_style`/`_is_in_progress`/`blocking_rows`; `story_rows` marks an unrecognised row with `⚠` + `bold red` and shows the raw status; `epic_rows` appends `(!)` to a flagged epic; added `_epic_has_unrecognised()` and `unrecognised_rows(epic)`.
- `cpm/tools/board/board.py` — `_epic_detail_content` prepends an "unrecognised statuses" preface (same mechanism as the "Blocked by" preface).
- `cpm/tools/board/tests/test_derivation.py` — added lead-token counting, token-based pending, unrecognised-not-counted, and `_status_token`/recognition unit tests.
- `cpm/tools/board/tests/test_board_view.py` — added lead-token-not-flagged, story `⚠` flag, story-level Superseded flagged, epic `(!)` marker, and `unrecognised_rows` naming tests.
- `cpm/shared/status-model.md` — documented the lead-token convention and the lint (unrecognised = surfaced, still counts as not-done).
- `cpm/skills/status/SKILL.md` — read statuses by leading token; added the unrecognised-status callout to the report.
- `cpm/skills/do/SKILL.md`, `cpm/skills/pivot/SKILL.md` — made explicit that status transitions match only the status token and preserve an existing `— note` tail.

## Acceptance Criteria — Verified

- ✅ `**Status**: Complete — folded into Story 10` is deemed done (`1/1`); the tail is ignored by logic but remains in the doc/detail. *(`test_lead_token_status_counts_as_done`; `_status_token` strips the tail, source text untouched.)*
- ✅ `**Status**: Pending — waiting on X` is recognised as pending. *(`test_lead_token_applies_to_pending`.)*
- ✅ `**Status**: Folded into Story 10 …` is **not** counted, is flagged with `⚠` on the story row and `(!)` on the epic row, and appears in the epic-detail preface. *(`test_unrecognised_status_is_not_counted`, `test_story_row_flags_an_unrecognised_status`, `test_epic_row_gets_a_marker_when_a_status_is_unrecognised`; `unrecognised_rows` + `board.py` preface.)*
- ✅ A story-level `Superseded`/`Withdrawn` is flagged as unrecognised (epic-level only). *(`test_story_level_superseded_is_flagged`.)*
- ✅ Counting, hiding, and dependency resolution are otherwise unchanged. *(All 200 board tests pass, including the record-21 suite.)*
- ✅ `/cpm:status` documents an unrecognised-status callout; `status-model.md` documents the lead-token convention.
- ✅ `/cpm:do` and `/cpm:pivot` prose states that a status transition preserves an existing `— note` tail.
- ✅ The `cpm/tools/board` test suite passes — **200 passed** (`cd cpm/tools/board && uv run pytest`).

## Notes

- **Read tolerant, write strict, still holds.** Lead-token parsing only affects *reading*; CPM still writes canonical `Complete`. The note tail is a human affordance the tool never generates on its own.
- **Lint, not guess.** The tool deliberately does not infer intent from free prose. An unrecognised status stays not-done and visible until a human (or `/cpm:pivot`/`/cpm:do`) rewrites it to `Complete — note` form — the conservative choice.
