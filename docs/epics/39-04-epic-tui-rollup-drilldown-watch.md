# TUI: Roll-up, Drill-down, Watch

**Source spec**: docs/specifications/39-spec-cross-project-cpm-board.md
**Date**: 2026-07-11
**Status**: Complete
**Blocked by**: Epic 39-02-epic-status-derivation-engine, Epic 39-03-epic-registry-freshness-cache
**Retro applied**: 08 · Patterns worth reusing · Applied — the roll-up (Story 1) and drill-down (Story 2) read the engine's `next_actions`/`state`/`rag` directly and never recompute precedence, so the two views can't disagree.
**Retro applied**: 09 · Patterns worth reusing · Applied — the TUI derives every row through `derive_project_cached`; watch ticks serve cache on unchanged stamp, the manual-refresh key passes `force=True`.

## Cross-project roll-up view
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Cross-project roll-up, RAG colour indicators, Attention-first ordering

**Acceptance Criteria**:

- Renders one row per registered project showing name, overall state, story progress (e.g. 4/7), and its **primary** recommended next action; when a project has more than one candidate next action (per the `status-model.md` multi-action model), the row shows a count of the additional candidates (e.g. `+2`) [feature]
- RAG colour indicators map green / amber / red to project state [feature]
- Projects needing action (blocked, in-progress, spec-waiting-on-epics) sort above idle/complete ones [feature]

### Build the Textual project list/table
**Task**: 1.1
**Description**: Covers the roll-up criterion — a Textual view rendering one row per registered project with name, state, progress, and its primary next action plus an additional-candidate count when the project has more than one.
**Status**: Complete

### Map states to RAG colours
**Task**: 1.2
**Description**: Covers the RAG criterion — a state→colour mapping applied to each row.
**Status**: Complete

### Implement attention-first ordering
**Task**: 1.3
**Description**: Covers the ordering criterion — sort action-needing projects above idle/complete.
**Status**: Complete

### Write tests for the roll-up view
**Task**: 1.4
**Description**: Write automated tests covering the story's acceptance criteria tagged [feature] — drive the app with Textual Pilot and assert rows, colours, and order.
**Status**: Complete

**Retro**: [Pattern worth reusing] Splitting the pure view logic (RAG mapping, attention ordering, next-action formatting) into a Textual-free `board_view.py` let those rules be unit-tested without a Pilot event loop, leaving the `[feature]` Pilot tests to assert only the DataTable wiring — fast pure tests plus a thin integration layer.

---

## Per-project drill-down
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Per-project drill-down

**Acceptance Criteria**:

- A row expands in place to show its epics/stories and their statuses, without leaving the board [feature]
- When a project has multiple candidate next actions, the expanded region lists the full ordered candidate set (primary first), each with its command and target, so the user can choose which one to act on [feature]

### Add the expandable row / detail region
**Task**: 2.1
**Description**: Covers the in-place expansion interaction on a selected project row.
**Status**: Complete

### Render the project's epics/stories and statuses
**Task**: 2.2
**Description**: Populate the expanded region from the derivation engine's per-epic/story detail, and — when more than one exists — render the full ordered candidate next-action list (primary first) the user can choose from.
**Status**: Complete

### Write tests for drill-down
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged [feature] — expand a row under Pilot and assert the epics/stories render.
**Status**: Complete

**Retro**: [Pattern worth reusing] Threading the parsed `epics` onto `ProjectStatus` (and round-tripping them through the cache) let the drill-down read epic/story detail from the same cached engine result the roll-up uses — one derive, both views — rather than re-parsing on expand.

---

## Watch mode and manual refresh
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Watch mode, Manual refresh

**Acceptance Criteria**:

- Auto-refreshes on an interval using the cheap HEAD+mtime invalidation (not a full re-parse each tick); the screen updates without a full reprint/flicker [manual] — live-refresh *feel* is visual judgement automation can't confirm
- A keypress forces a full re-derive, bypassing the cache [feature]

### Wire an interval timer to the invalidation refresh
**Task**: 3.1
**Description**: Covers watch mode — a Textual interval that triggers the cheap HEAD+mtime invalidation and updates changed rows in place.
**Status**: Complete

### Bind a manual-refresh key to a forced re-derive
**Task**: 3.2
**Description**: Covers the manual-refresh criterion — a keybinding invoking the cache force-bypass flag from epic 39-03.
**Status**: Complete

### Write tests for manual refresh
**Task**: 3.3
**Description**: Write automated tests covering the [feature] criterion — press the refresh key under Pilot and assert a forced re-derive occurs. (The watch-mode *feel* criterion is `[manual]` and not automated.)
**Status**: Complete

**Retro**: [Pattern worth reusing] The refresh path updates cells in place when the row order is unchanged and only rebuilds on a structural change — preserving cursor and open drill-down — which both delivers the flicker-free watch *feel* and keeps the manual-refresh force path on the same code, so the `[manual]` and `[feature]` criteria share one implementation.

---
