# Registry & Freshness Cache

**Source spec**: docs/specifications/39-spec-cross-project-cpm-board.md
**Date**: 2026-07-11
**Status**: Complete
**Blocked by**: Epic 39-02-epic-status-derivation-engine
**Retro applied**: 08 · Patterns worth reusing · Applied — Story 2's freshness tests use the HEAD-snapshot + `git status --porcelain` empty assertion to prove the cache never mutates a tracked repo.

## Project registry CRUD
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Opt-in registry

**Acceptance Criteria**:

- `add` / `remove` / `list` persist correctly to `~/.config/cpm-board/registry.json` as a list of `{ path, label? }` [unit]
- Adding a non-existent path is permitted but flagged at render time, not rejected at `add` time [unit]

### Read and write the XDG registry file
**Task**: 1.1
**Description**: Covers the persistence criterion — load/save `~/.config/cpm-board/registry.json` (XDG-aware), creating it on first use.
**Status**: Complete

### Implement add / remove / list subcommands
**Task**: 1.2
**Description**: The CLI surface over the registry file; `add` accepts a path (and optional label) without validating existence, deferring the flag to render.
**Status**: Complete

### Write tests for the registry
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged [unit] — round-trip add/remove/list and the accept-but-defer-flag behaviour.
**Status**: Complete

**Retro**: [Pattern worth reusing] Keeping `registry.py` free of Textual imports made the CLI surface fully unit-testable via `run_cli(argv, registry_file=...)` with `capsys` — no TUI boot needed; the same "pure module + thin board.py dispatch" split will suit the launcher epic.

---

## Freshness cache with HEAD and mtime invalidation
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Freshness by construction

**Acceptance Criteria**:

- Re-derives a project after its `git HEAD` or max `docs/` mtime changes; serves cache when unchanged [unit]
- Cache lives under `~/.cache/cpm-board/` keyed by project path, never inside a tracked repo [unit]
- must NOT show stale state after a tracked project changes (bounded by watch interval / refresh) [integration]

### Compute the freshness stamp
**Task**: 2.1
**Description**: Covers the invalidation input — derive the per-project stamp from `git rev-parse HEAD` + max mtime under `docs/`.
**Status**: Complete

### Read and write the central cache
**Task**: 2.2
**Description**: Covers the cache-location criterion — persist derived status under `~/.cache/cpm-board/` keyed by project path, with nothing written into tracked repos.
**Status**: Complete

### Invalidate and re-derive changed projects only, with a force-bypass flag
**Task**: 2.3
**Description**: Compares stamps to serve cache or re-derive; exposes a force flag (consumed by manual refresh in the TUI epic) that bypasses the cache entirely.
**Status**: Complete

### Write tests for freshness and cache
**Task**: 2.4
**Description**: Write automated tests covering the story's acceptance criteria tagged [unit] and [integration] — cache-hit on unchanged, re-derive on HEAD/mtime change, cache path isolation, no-stale-after-change.
**Status**: Complete

**Retro**: [Pattern worth reusing] Combining `git HEAD` and max `docs/` mtime into one stamp lets the two invalidation triggers be tested independently — a committed edit exercises the HEAD component, an uncommitted edit exercises the mtime component — and the cache-served path was proven by monkeypatching `derive_project` to raise, so a false cache miss fails loudly.

---
