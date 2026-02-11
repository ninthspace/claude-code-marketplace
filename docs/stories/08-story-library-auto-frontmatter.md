# Stories: Library Auto Front-Matter

**Date**: 2026-02-11
**Source**: docs/specifications/08-spec-library-auto-frontmatter.md

## Epic: Routing & Scan

### Add no-arg consolidate routing and batch scan
**Story**: 1
**Task ID**: 5
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- The Input section routes `consolidate` (no file path) to a new "Batch Front-Matter Workflow" section
- The existing `consolidate <file-path>` route is unchanged
- The workflow globs `docs/library/*.md` and reads each file
- Files starting with `---` are identified as having front-matter (skipped)
- Files not starting with `---` are identified as bare (queued for processing)
- If `docs/library/` doesn't exist or is empty, the user is told and the workflow stops
- If all files already have front-matter, the user is told and the workflow stops

#### Update Input section routing for no-arg consolidate
**Task**: 1.1
**Task ID**: 1
**Status**: Complete

#### Write batch scan workflow section
**Task**: 1.2
**Task ID**: 2
**Status**: Complete

---

## Epic: Front-Matter Generation & Write

### Implement per-document front-matter generation and write
**Story**: 2
**Task ID**: 6
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- A batch summary is shown upfront: "Found N documents without front-matter: {filenames}"
- For each bare document: content is analysed and all six front-matter fields are generated
- Auto-scope suggestion uses the same heuristics table as intake
- `source` field is set to the document's current file path
- `added` and `last-reviewed` are set to today's date
- Generated front-matter is presented to the user for approval (accept or adjust scope)
- On approval, front-matter is prepended to the file — original body content is not modified
- Documents that can't be analysed are skipped with a warning, not aborting the batch
- State management (progress file) tracks batch progress for compaction resilience

#### Write batch summary and per-document generation steps
**Task**: 2.1
**Task ID**: 3
**Status**: Complete

#### Write in-place write step and state management
**Task**: 2.2
**Task ID**: 4
**Status**: Complete

---
