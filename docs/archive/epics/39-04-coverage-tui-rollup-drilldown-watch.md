# Coverage Matrix: TUI: Roll-up, Drill-down, Watch

**Source spec**: docs/specifications/39-spec-cross-project-cpm-board.md
**Epic**: docs/epics/39-04-epic-tui-rollup-drilldown-watch.md
**Date**: 2026-07-11

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | Cross-project roll-up | one screen, one row per project: name, overall state, story progress (e.g. 4/7), recommended next action. | Renders one row per registered project showing name, overall state, story progress (e.g. 4/7), and its **primary** recommended next action; when a project has more than one candidate next action, the row shows a count of the additional candidates (e.g. `+2`) | Story 1 | `[feature]` | ✓ |
| 2 | RAG colour indicators | green / amber / red per project state for at-a-glance scanning. | RAG colour indicators map green / amber / red to project state | Story 1 | `[feature]` | ✓ |
| 3 | Attention-first ordering | projects needing action (blocked, in-progress, spec-waiting-on-epics) sort above idle/complete ones. | Projects needing action (blocked, in-progress, spec-waiting-on-epics) sort above idle/complete ones | Story 1 | `[feature]` | ✓ |
| 4 | Per-project drill-down | expand a row in place to see its epics/stories and their statuses without leaving the board. | A row expands in place to show its epics/stories and their statuses, without leaving the board | Story 2 | `[feature]` | ✓ |
| 4b | Per-project drill-down (multi-action) | expand a row in place to see its epics/stories and their statuses without leaving the board. | When a project has multiple candidate next actions, the expanded region lists the full ordered candidate set (primary first), each with its command and target, so the user can choose which one to act on | Story 2 | `[feature]` | ✓ |
| 5 | Watch mode | auto-refresh on an interval using the cheap HEAD+mtime invalidation (not a full re-parse each tick). | Auto-refreshes on an interval using the cheap HEAD+mtime invalidation (not a full re-parse each tick); the screen updates without a full reprint/flicker | Story 3 | `[manual]` | ✓ |
| 6 | Manual refresh | a keypress forces a full re-derive, bypassing the cache. | A keypress forces a full re-derive, bypassing the cache | Story 3 | `[feature]` | ✓ |
