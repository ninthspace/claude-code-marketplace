# Coverage Matrix: Registry & Freshness Cache

**Source spec**: docs/specifications/39-spec-cross-project-cpm-board.md
**Epic**: docs/epics/39-03-epic-registry-freshness-cache.md
**Date**: 2026-07-11

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | Opt-in registry | `add` / `remove` / `list` the projects the board tracks. Explicit only; nothing auto-discovered. | `add` / `remove` / `list` persist correctly to `~/.config/cpm-board/registry.json` as a list of `{ path, label? }`; adding a non-existent path is permitted but flagged at render time, not rejected at `add` time | Story 1 | `[unit]` | ✓ |
| 2 | Freshness by construction | on each run/tick, re-derive any project whose `git HEAD` or max `docs/` mtime changed since last seen; paint unchanged projects from cache. | Re-derives a project after its `git HEAD` or max `docs/` mtime changes; serves cache when unchanged | Story 2 | `[unit]` | ✓ |
| 3 | Freshness by construction (cache storage) | A single central cache under XDG (`~/.cache/cpm-board/`), keyed by project path. A central cache keeps tracked repos' working trees clean. | Cache lives under `~/.cache/cpm-board/` keyed by project path, never inside a tracked repo | Story 2 | `[unit]` | ✓ |
| 4 | Freshness by construction (no staleness) | so it's instant and always current. | must NOT show stale state after a tracked project changes (bounded by watch interval / refresh) | Story 2 | `[integration]` | ✓ |
