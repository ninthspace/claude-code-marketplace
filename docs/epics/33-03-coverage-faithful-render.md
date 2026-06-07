# Coverage Matrix: Faithful Artifact Render

**Source spec**: docs/specifications/33-spec-html-artifact-projection.md
**Epic**: docs/epics/33-03-epic-faithful-render.md
**Date**: 2026-06-02

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | Faithful render of substrate artifacts | On request, a whole `spec`, `architect` ADR, or `review` is rendered to a navigable HTML view generated *from* its Markdown, written to a conventional location, without modifying or replacing the Markdown. | On request, a whole `spec`, `architect` ADR, or `review` is rendered to a navigable HTML view generated from its Markdown | Story 1 | `[manual]` | ✓ |
| 2 | Faithful render of substrate artifacts | (as above — "written to a conventional location") | The render is written to `docs/{type}/html/{nn}-{slug}.html` and consumes the shared template, not a forked stylesheet | Story 1 | `[integration]` | ✓ |
| 3 | Generate-from-source, never replace | No HTML generation step ever mutates the source Markdown. Markdown remains the parsed source of truth. | A render must NOT modify or replace the source Markdown file | Story 1 | `[integration]` | ✓ |
| 4 | Self-contained output | Rendered views, companion assets, and `present` HTML communications are single files with inline CSS/SVG — shareable by sending one file, openable in any browser, no server or build step. | The render is self-contained — a single file with no external CSS/JS/image references | Story 1 | `[integration]` | ✓ |
| 5 | Artifact-appropriate navigation in faithful renders | contents sidebar for large specs; side-by-side option/trade-off columns for ADRs; severity grouping/sorting for review findings. Static only (no stateful JS). | Large `spec` renders include a contents sidebar; ADR renders present options/trade-offs side-by-side; `review` renders group and sort findings by severity — static only, no stateful JS | Story 2 | `[manual]` | ✓ |
| 6 | Regeneration in place | Re-rendering after the source Markdown changes updates the existing HTML view rather than spawning duplicates; traceable to its source artifact. | Re-rendering after the source Markdown changes updates the existing HTML view rather than creating a duplicate | Story 2 | `[integration]` | ✓ |
