# Board add-project picker: remember last browsed location

**Date**: 2026-07-20  
**Status**: Complete

## Context

Follow-up to the "up a level" key (record 18): climbing up with `backspace` was forgotten as soon as the picker modal closed, because `_add_picker_root()` re-derived the start directory from the board's highlighted project every open — the picker kept no memory of its own browsing location. Added that memory so browsing sticks between adds. Remembered location always wins over the selection-derived default (Chris's call). Done via quick execution.

## Acceptance Criteria

- After browsing to a directory (up or down) and closing the picker, the next open re-roots there. — Met
- Remembered location always takes priority over the selected project's parent once set. — Met
- On the very first open in a session (no prior browsing), behaviour is unchanged: selected project's parent, else home. — Met
- A remembered directory that no longer exists falls back gracefully to the prior logic. — Met

## Changes Made

- `cpm/tools/board/board.py`:
  - `AddProjectScreen` now tracks a `final_root` attribute (initialised to the start root, updated in `action_go_up` when the tree re-roots).
  - `BoardApp` gains `_last_picker_dir` (init `None`), set in `action_add_project`'s `_apply` callback whenever the modal closes — on cancel as well as add — from `screen.final_root`.
  - `_add_picker_root()` prefers `_last_picker_dir` when it is set and still a directory, before falling back to the selected project's parent, injected root, then home.
- `cpm/tools/board/README.md` — clarified that the first open starts from the selected project's parent, and thereafter the picker resumes where you last browsed.
- `cpm/tools/board/tests/test_add_project.py` — added `test_picker_resumes_from_the_last_browsed_directory` (climb up, close, reopen → resumes at the higher dir).

## Verification

Ran the picker suite (`tests/test_add_project.py`, 6 passed) and the full board suite (`tests/`, 178 passed) via `uv run --with textual --with pytest --with pytest-asyncio pytest`. The new test proves the resume: after `backspace` + `escape`, reopening roots at the parent (`tmp_path`), not the original `workspace`. The `is_dir()` guard covers the stale-directory fallback by inspection; first-open behaviour is preserved because `_last_picker_dir` is `None` until the picker has closed once.

## Retro

**Codebase discovery**: The original picker had no self-memory at all — it re-derived its root from board selection every open, which is why upward navigation felt lost while downward (same root, just expanded nodes) felt retained. Capturing the tree's live root on close, rather than inferring from the added path, was the clean fix and also handles the cancel case.
