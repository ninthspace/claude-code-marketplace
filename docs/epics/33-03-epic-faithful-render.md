# Faithful Artifact Render

**Source spec**: docs/specifications/33-spec-html-artifact-projection.md
**Date**: 2026-06-02
**Status**: Pending
**Blocked by**: Epic 33-01-epic-shared-template-foundation

## Add on-request faithful render to spec, architect, and review
**Story**: 1
**Status**: Pending
**Blocked by**: Epic 33-01-epic-shared-template-foundation
**Satisfies**: Faithful render of substrate artifacts; Self-contained output; Generate-from-source, never replace

**Acceptance Criteria**:

- On request, a whole `spec`, `architect` ADR, or `review` is rendered to a navigable HTML view generated from its Markdown [manual] — visual/navigational judgement
- The render is written to `docs/{type}/html/{nn}-{slug}.html` and consumes the shared template, not a forked stylesheet [integration]
- A render must NOT modify or replace the source Markdown file [integration]
- The render is self-contained — a single file with no external CSS/JS/image references [integration]

### Add a faithful-render step to the spec skill
**Task**: 1.1
**Description**: On request, render the spec Markdown to navigable HTML at the convention path using the shared template; read-only on the source.
**Status**: Pending

### Add a faithful-render step to the architect skill
**Task**: 1.2
**Description**: Render an ADR to HTML under the same path/template/read-only rules as the spec render.
**Status**: Pending

### Add a faithful-render step to the review skill
**Task**: 1.3
**Description**: Render a review file to HTML under the same path/template/read-only rules.
**Status**: Pending

### Write tests for faithful render
**Task**: 1.4
**Description**: Assert output path, shared-template use, self-containment, and source immutability. Covers the story's [integration] criteria.
**Status**: Pending

---

## Add artifact-appropriate navigation and regeneration-in-place
**Story**: 2
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: Artifact-appropriate navigation in faithful renders; Regeneration in place

**Acceptance Criteria**:

- Large `spec` renders include a contents sidebar; ADR renders present options/trade-offs side-by-side; `review` renders group and sort findings by severity — static only, no stateful JS [manual] — visual/navigation judgement
- Re-rendering after the source Markdown changes updates the existing HTML view rather than creating a duplicate [integration]

### Add artifact-appropriate navigation to the renders
**Task**: 2.1
**Description**: Contents sidebar for specs, side-by-side option columns for ADRs, severity grouping/sorting for reviews.
**Status**: Pending

### Add regeneration-in-place
**Task**: 2.2
**Description**: Re-render updates the existing HTML file rather than spawning duplicates; traceable to its source.
**Status**: Pending

### Write tests for regeneration-in-place
**Task**: 2.3
**Description**: Assert a re-render updates the existing file rather than creating a duplicate. Covers the story's [integration] criterion.
**Status**: Pending

---
