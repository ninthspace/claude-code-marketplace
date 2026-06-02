# present HTML Output

**Source spec**: docs/specifications/33-spec-html-artifact-projection.md
**Date**: 2026-06-02
**Status**: Pending
**Blocked by**: Epic 33-01-epic-shared-template-foundation

## Add HTML output to cpm2:present
**Story**: 1
**Status**: Pending
**Blocked by**: Epic 33-01-epic-shared-template-foundation
**Satisfies**: present HTML output

**Acceptance Criteria**:

- `present` can emit a reframed communication (summary memo, onboarding guide, etc.) as styled HTML using the shared template, in addition to its existing Markdown output [manual] — reframed-content + visual judgement
- `present` HTML output is self-contained and uses the shared template, not a forked stylesheet [integration]
- `present` HTML output is written alongside its Markdown output in `docs/communications/` [integration]

### Add an HTML output option to the present skill
**Task**: 1.1
**Description**: Emit the reframed communication as styled HTML via the shared template, alongside the Markdown output in `docs/communications/`.
**Status**: Pending

### Write tests for present HTML output
**Task**: 1.2
**Description**: Assert self-containment, shared-template use, and output path. Covers the story's [integration] criteria.
**Status**: Pending

---
