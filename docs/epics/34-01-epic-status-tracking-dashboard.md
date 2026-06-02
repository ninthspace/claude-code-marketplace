# status Tracking Dashboard

**Source spec**: docs/specifications/34-spec-interactive-tracking-dashboards.md
**Date**: 2026-06-02
**Status**: Pending
**Blocked by**: Epic 33-01-epic-shared-template-foundation

## Build and evaluate the status dashboard validation prototype [plan]
**Story**: 1
**Status**: Pending
**Blocked by**: Epic 33-01-epic-shared-template-foundation
**Satisfies**: Validation-first

**Acceptance Criteria**:

- A prototype standalone HTML dashboard is produced from a real `status` scan and evaluated against "does the full-picture document materially help tracking versus the inline narrative?" [manual] — explicit go/no-go judgement
- The full build must NOT proceed until the prototype evaluation records a go decision [manual]

### Build the status dashboard prototype from a real status scan
**Task**: 1.1
**Description**: A minimal full-picture HTML document built from real status data to test the value hypothesis; throwaway, not production-wired.
**Status**: Pending

### Evaluate the prototype and record a go/no-go decision
**Task**: 1.2
**Description**: Assess "materially helps vs the narrative"; the recorded decision gates Story 2 and the rest of the Tier 2 build.
**Status**: Pending

---

## Generate the standalone full-picture status HTML document
**Story**: 2
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: Standalone full-picture HTML document; status inline output unchanged; Reuse the Spec 1 foundation; Build-free output; Saved on request, ephemeral by default

**Acceptance Criteria**:

- `cpm2:status` can additionally generate a self-contained full-picture HTML document presenting epic/story completion grid, in-progress + blocked panel, RAG indicators, recent git activity, and recommended next steps, using the Spec 1 shared template [manual] — visual/content judgement
- The document is self-contained — a single file with no external script/CSS references — and uses the shared template, not a forked stylesheet [integration]
- The document's completion counts agree with the data the stdout narrative reports [integration]
- `cpm2:status` still produces its stdout narrative; the default path is unchanged [integration]
- The HTML document must NOT be saved unless the user asks (ephemeral default) [manual]

### Add full-picture HTML document generation to cpm2:status
**Task**: 2.1
**Description**: Emit the document (completion grid, blocked panel, RAG, git activity, next steps) via the shared template, alongside the unchanged stdout narrative.
**Status**: Pending

### Wire ephemeral / save-on-request behaviour
**Task**: 2.2
**Description**: Document not saved unless the user asks; regenerate on demand by default, matching status's stateless nature.
**Status**: Pending

### Write tests for the status document
**Task**: 2.3
**Description**: Assert self-containment, shared-template use, data-agreement with the narrative, and that the stdout path is unchanged. Covers the story's [integration] criteria.
**Status**: Pending

---
