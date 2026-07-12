# Retro: Status Derivation Engine

**Source**: docs/epics/39-02-epic-status-derivation-engine.md
**Date**: 2026-07-11

## Summary

Epic 39-02 delivered the board's derivation engine: read-only project-state
derivation from `docs/` + git, the ordered multi-action candidate list, and
graceful degradation for unreachable/malformed projects. All 3 stories completed;
coverage matrix 5/5 verified; 31 tests pass. A smooth batch — the multi-action
criteria gap flagged in retro 07 was consumed here without friction, so no new
criteria gap surfaced.

## Observations

### Patterns worth reusing

- **Contract conformance tested as a table-driven parametrized case** (scenario →  
  expected `State`), and the read-only guarantee proven by snapshotting `git HEAD`  
  then asserting `git status --porcelain` is empty after a sweep. Both are cheap,  
  precise, and directly reusable for the remaining board epics that also touch  
  the contract and tracked repos.
- **Per-epic classification reuses the project-level precedence** — `_epic_state`  
  mirrors `derive_state`'s ordering rather than inventing a second one. One  
  precedence definition read at two call sites means the primary candidate action  
  can never contradict the overall RAG state. Reuse this "one rule, two callers"  
  shape wherever the roll-up and the drill-down must agree.

### Smooth delivery

- **The 39-01 downstream ripple was consumed cleanly.** Retro 07 flagged that the  
  contract's single "recommended next command" had to become an ordered candidate  
  list. That extension landed in Story 2 as `compute_next_actions()` with no  
  rework — the `NextAction` record shape (with `command: None` for  
  `attention:unblock`) absorbed the multi-action model exactly as the pivoted  
  contract specified.

## Recommendations

- **Build 39-04's roll-up and drill-down off the same `NextAction` list.** The  
  engine already emits primary + rest in priority order; the TUI should render the  
  primary in the roll-up row and the full list in the drill-down, not re-derive  
  ordering. Keep the "one rule, two callers" discipline — the TUI reads the list,  
  it does not recompute it.
- **Reuse the HEAD-snapshot + `--porcelain` assertion** as the standard read-only  
  guard in 39-03 (freshness cache) and 39-05 (launcher), both of which touch git  
  and must stay non-mutating.
