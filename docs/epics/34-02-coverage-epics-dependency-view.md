# Coverage Matrix: epics Dependency View

**Source spec**: docs/specifications/34-spec-interactive-tracking-dashboards.md
**Epic**: docs/epics/34-02-epic-epics-dependency-view.md
**Date**: 2026-06-02

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | `epics` dependency view | A projection over the Markdown epic docs rendering story/task dependencies (graph or unblocked-first ordering) showing what is ready to pick up. Epic docs remain the Markdown source of truth and are read-only. | The dependency view renders unblocked vs blocked stories correctly from epic-doc data | Story 1 | `[integration]` | |
| 2 | Reuse the Spec 1 foundation / Build-free output | The HTML document and the `epics` view consume Spec 1's shared HTML/CSS template asset for styling/layout — no forked or divergent scaffolding. / Each document is a single self-contained file ... | The view is a self-contained HTML file using the Spec 1 shared template, generated from the Markdown epic docs | Story 1 | `[integration]` | |
| 3 | `epics` dependency view (read-only) | Epic docs remain the Markdown source of truth and are read-only. | The view must NOT modify the source epic Markdown (read-only) | Story 1 | `[integration]` | |
| 4 | Graceful schema tolerance | When an epic doc's structure varies (missing status field, partial completion data), the document renders what it can and visibly flags what it couldn't parse, rather than breaking. | Given an epic doc with a missing or partial field, the view renders what it can and visibly flags the gap rather than erroring | Story 2 | `[integration]` | |
