# epics Dependency View

**Source spec**: docs/specifications/34-spec-interactive-tracking-dashboards.md
**Date**: 2026-06-02
**Status**: Pending
**Blocked by**: Epic 33-01-epic-shared-template-foundation, Epic 34-01-epic-status-tracking-dashboard

## Build the epics dependency view
**Story**: 1
**Status**: Pending
**Blocked by**: Epic 33-01-epic-shared-template-foundation, Epic 34-01-epic-status-tracking-dashboard
**Satisfies**: epics dependency view; Reuse the Spec 1 foundation; Build-free output; Read-only, export-only behaviour

**Acceptance Criteria**:

- The dependency view renders unblocked vs blocked stories correctly from epic-doc data [integration]
- The view is a self-contained HTML file using the Spec 1 shared template, generated from the Markdown epic docs [integration]
- The view must NOT modify the source epic Markdown (read-only) [integration]

### Add dependency-view generation to the epics skill
**Task**: 1.1
**Description**: Read the epic docs, render an unblocked/blocked dependency HTML view via the shared template, read-only on the source.
**Status**: Pending

### Write tests for the dependency view
**Task**: 1.2
**Description**: Assert correct unblocked/blocked rendering, self-containment + shared-template use, and source immutability. Covers the story's [integration] criteria.
**Status**: Pending

---

## Add graceful schema tolerance
**Story**: 2
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: Graceful schema tolerance

**Acceptance Criteria**:

- Given an epic doc with a missing or partial field, the view renders what it can and visibly flags the gap rather than erroring [integration]

### Add schema-tolerant parsing to the dependency view
**Task**: 2.1
**Description**: Render partial data and flag unparseable fields instead of erroring.
**Status**: Pending

### Write tests for schema tolerance
**Task**: 2.2
**Description**: Fixture with missing/partial fields renders and flags the gap with no error. Covers the story's [integration] criterion.
**Status**: Pending

---
