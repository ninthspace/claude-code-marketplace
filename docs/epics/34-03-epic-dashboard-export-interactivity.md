# Dashboard Export & Interactivity

**Source spec**: docs/specifications/34-spec-interactive-tracking-dashboards.md
**Date**: 2026-06-02
**Status**: Pending
**Blocked by**: Epic 34-01-epic-status-tracking-dashboard, Epic 34-02-epic-epics-dependency-view

## Add copy-as-prompt / copy-as-JSON export
**Story**: 1
**Status**: Pending
**Blocked by**: Epic 34-01-epic-status-tracking-dashboard, Epic 34-02-epic-epics-dependency-view
**Satisfies**: Interactive affordances (optional enhancement); Build-free output; Read-only, export-only behaviour

**Acceptance Criteria**:

- When present, an export action produces a valid, copy-pasteable prompt / well-formed JSON [integration]
- Export uses inline vanilla JS only — no external script, framework, or build artifact [integration]
- No document interaction writes back to any source doc (read-only/export-only) [integration]
- Clicking export in a browser copies the expected content [manual] — interaction; browser harness deferred per spec

### Add copy-as-prompt/JSON export to the status document and epics view
**Task**: 1.1
**Description**: Inline-JS export buttons that turn a selection (e.g. "next: `/cpm2:do …`") into a prompt or JSON; export-only, never a write-back path.
**Status**: Pending

### Write tests for export output and isolation
**Task**: 1.2
**Description**: Assert valid prompt/JSON output, inline-JS-only (no external refs), and source immutability. Covers the story's [integration] criteria.
**Status**: Pending

---
