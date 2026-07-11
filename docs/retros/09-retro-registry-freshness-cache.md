# Retro: Registry & Freshness Cache

**Source**: docs/epics/39-03-epic-registry-freshness-cache.md
**Date**: 2026-07-11

## Summary

Epic 39-03 delivered the board's opt-in project registry and its
freshness-by-construction cache. Both stories completed; coverage matrix 4/4
verified; 51 tests pass. A clean epic — no scope surprises, no criteria gaps, no
retro-trigger signals. Two patterns worth carrying into the launcher and TUI
epics surfaced.

## Observations

### Patterns worth reusing

- **Pure module + thin `board.py` dispatch.** Keeping `registry.py` free of any  
  Textual import made the whole CLI surface unit-testable through  
  `run_cli(argv, registry_file=...)` with `capsys` — no TUI boot, no event loop.  
  `board.py` is only a dispatcher: registry subcommand → `registry.run_cli`, else  
  launch the app. The launcher epic (39-05) should follow the same split so its  
  clipboard/subprocess logic is testable without standing up the TUI.
- **One stamp, two independently-testable invalidation triggers.** Combining  
  `git HEAD` and max `docs/` mtime into a single freshness stamp let each trigger  
  be exercised in isolation — a *committed* edit moves HEAD, an *uncommitted* edit  
  advances mtime — and the cache-hit path was proven by monkeypatching  
  `derive_project` to raise, so a false cache miss fails loudly rather than  
  passing silently. Reuse the "make the wrong path throw" tactic wherever a cache  
  or memoisation layer needs its hit/miss behaviour pinned down.

## Recommendations

- **Adopt the pure-module/thin-dispatch split in 39-05 (launcher).** Put the  
  shell-safe copy/launch logic in a Textual-free module with an injectable  
  boundary (clipboard writer, subprocess runner) so the security-critical paths  
  are unit-tested directly, and let `board.py` / the TUI call into it.
- **Feed the TUI (39-04) off `derive_project_cached`, not `derive_project`.** The  
  watch-mode tick and manual refresh already have their contract: serve cache on  
  unchanged stamp, and pass `force=True` for the manual-refresh bypass. The TUI  
  consumes this; it should not re-implement freshness.
