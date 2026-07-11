# Retro: TUI — Roll-up, Drill-down, Watch

**Source**: docs/epics/39-04-epic-tui-rollup-drilldown-watch.md
**Date**: 2026-07-11

## Summary

Epic 39-04 built the board's Textual UI: the cross-project roll-up, the
per-project drill-down, and watch mode + manual refresh. All 3 stories completed;
coverage matrix 7/7 verified; 75 tests pass. The multi-action model landed
cleanly in both views. A smooth epic — the only friction was a one-line Textual
API mismatch in a test, fixed immediately.

## Observations

### Patterns worth reusing

- **Textual-free view module.** RAG mapping, attention ordering, and next-action  
  formatting live in `board_view.py` with no Textual import, so they're unit-tested  
  without a Pilot event loop; the `[feature]` Pilot tests then assert only the  
  DataTable wiring. Fast pure tests + a thin integration layer — carry this into  
  the launcher.
- **One derive, both views.** Threading the parsed `epics` onto `ProjectStatus`  
  (and round-tripping them through the freshness cache) let the drill-down read  
  epic/story detail from the *same* cached engine result the roll-up uses, instead  
  of re-parsing on expand. The rule of thumb: put everything a view needs on the  
  cached status object once, so every view is a projection, not a re-computation.
- **In-place update shares the watch and manual-refresh paths.** The refresh  
  updates cells in place when the row order is unchanged and rebuilds only on a  
  structural change — preserving cursor and the open drill-down. This delivers the  
  flicker-free watch *feel* and puts the manual `force=True` refresh on the same  
  code path, so the `[manual]` and `[feature]` criteria share one implementation.

### Codebase discoveries

- **Textual 8.x test-surface APIs.** Reading a `Static`'s content is  
  `str(widget.render())` (a `Content` object, also `.plain`) — **not**  
  `.renderable`, which doesn't exist in 8.x. DataTable cells are read with  
  `table.get_cell_at(Coordinate(row, col))`, and a styled cell stored as  
  `rich.text.Text` exposes `.plain` and `.style`. Pin future Textual feature tests  
  to these accessors rather than guessing from older-version docs.

## Recommendations

- **Apply the pure-module split to 39-05 (launcher).** Put the shell-safe  
  copy/launch logic in a Textual-free module with an injectable boundary  
  (clipboard writer, subprocess runner) so the security-critical paths are  
  unit-tested directly; let the TUI call into it. This is the same split that made  
  `board_view` and `registry` testable.
- **Reuse the Textual test accessors** (`str(Static.render())`,  
  `get_cell_at(Coordinate)`, `Text.plain`/`.style`) for any launcher UI feedback  
  (e.g. a "copied" toast) so those `[feature]` tests don't re-discover the API.
