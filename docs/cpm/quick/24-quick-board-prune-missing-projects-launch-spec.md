# Board: prune missing projects from the registry at launch

**Date**: 2026-07-20  
**Status**: Complete

## Context

Registered projects whose directories had been deleted lingered on the board as "unreachable" rows with no way to clear them short of the manual `remove`. Chris asked for them to be dropped automatically at launch, explicitly accepting the trade-off that a project on a temporarily-unmounted drive is also dropped (and must be re-added) — the opposite of the registry's default "surface, don't drop" stance.

## Acceptance Criteria

- Launching the board removes registered paths that aren't directories; the registry file no longer contains them. — **Met** (`test_launch_prunes_missing_projects_from_the_registry`, `test_prune_removes_missing_and_keeps_existing`)
- A path that still exists is kept and shown. — **Met** (same tests; survivor asserted on board and on disk)
- When every registered path exists, the registry file is not rewritten (no churn). — **Met** (`test_prune_does_not_rewrite_when_all_exist` — `save_registry` monkeypatched, asserted never called)
- Pruning happens only on the TUI launch path — `add`/`remove`/`list` CLI and `refresh` unchanged. — **Met** (prune guarded by `self._entries is None` in `on_mount`; `refresh_cli` untouched; CLI tests still green)
- The `cpm/tools/board` test suite passes. — **Met** (**209 passed**)

## Changes Made

- `cpm/tools/board/registry.py` — added `prune_missing(registry_file=None)`: loads the registry, keeps entries whose `.exists()` is True, rewrites the file **only if** something was removed, and returns the survivors. Module docstring updated to document the launch-time prune as the one deliberate exception to "surface, don't drop".
- `cpm/tools/board/board.py` — `BoardApp.on_mount` now calls `registry.prune_missing(registry_file=self._registry_file)` before `refresh_projects()`, guarded by `self._entries is None` so it targets the persisted registry (injected entries used by tests are left alone).
- `cpm/tools/board/tests/test_registry.py` — four tests: removes-missing/keeps-existing, preserves survivor labels, no-rewrite-when-all-exist (monkeypatched `save_registry`), empty-registry writes-nothing.
- `cpm/tools/board/tests/test_board_scaffold.py` — a launch test: a board booted against a disk registry with one live + one deleted path shows only the live project and rewrites the file without the dead entry.
- `cpm/tools/board/README.md` — noted under the Registry section that launch prunes missing projects (with the unmounted-drive caveat).

## Verification

Ran `cd cpm/tools/board && uv run pytest` — **209 passed** (204 prior + 5 new). Confirmed by inspection that the prune runs once at `on_mount` on the real-registry path only, the no-op guard prevents disk churn when nothing is missing, and the `refresh` cache-rebuild subcommand (`board.py:1297`) does not prune.

## Retro

**Smooth delivery**: The existing `RegistryEntry.exists()` render-time flag and the `self._entries is None` load seam made this a clean, well-contained addition — the prune reused the exact predicate the board already trusted for the "unreachable" label, so behaviour stayed consistent between the flag and the sweep.
