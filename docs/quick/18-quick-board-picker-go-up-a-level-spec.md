# Board add-project picker: go up a level

**Date**: 2026-07-20  
**Status**: Complete

## Context

The board TUI's add-project directory picker (`AddProjectScreen`) roots its tree at a fixed directory (the selected project's parent, else home) and Textual's `DirectoryTree` only ever descends from its root — so there was no way to browse above the starting directory. Added an "up a level" key. Done via quick execution: a single, well-scoped UI affordance.

## Acceptance Criteria

- Pressing `backspace` in the picker re-roots the tree at the parent directory and reloads its contents. — Met
- At the filesystem root, `backspace` is a no-op (no crash, no pointless reload). — Met
- The picker header lists the up-a-level key alongside the existing hints. — Met
- Backspace still edits text normally when the "Label" input is focused. — Met

## Changes Made

- `cpm/tools/board/board.py` — added a `("backspace", "go_up", "Up a level")` binding and an `action_go_up` method to `AddProjectScreen`; the action re-roots the tree by assigning `tree.path = str(parent)` (guarded by `parent != current` so the filesystem root is a no-op). Updated the picker header Label to include `⌫ up a level`.
- `cpm/tools/board/README.md` — documented `⌫` to go up a level in the picker key list.
- `cpm/tools/board/tests/test_add_project.py` — added `test_backspace_climbs_to_the_parent_directory` (and imported `Path`), driving the picker with Pilot and asserting the tree re-roots at the parent.

## Verification

Ran the picker suite (`tests/test_add_project.py`, 5 passed) and the full board suite (`tests/`, 177 passed) via `uv run --with textual --with pytest --with pytest-asyncio pytest`. The new test confirms re-rooting: after `backspace`, `tree.path` equals the parent and the former root appears as a child. The root no-op and the input-focus behaviour are covered by code inspection — the `parent != current` guard, and Textual's `Input` consuming backspace before it reaches the screen binding.

## Retro

**Smooth delivery**: Textual's reactive `path` var made re-rooting a one-line assignment, and the existing Pilot test harness made verification straightforward — delivered exactly as scoped.
