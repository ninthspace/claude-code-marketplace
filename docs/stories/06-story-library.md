# Stories: CPM Library System

**Date**: 2026-02-10
**Source**: docs/specifications/06-spec-library.md

## Epic: Library Skill

### Create `/cpm:library` intake skill
**Story**: 1
**Task ID**: 1
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- SKILL.md defines the intake action accepting file path or URL
- Document is copied into `docs/library/` with front-matter prepended
- All 6 front-matter fields are generated (title, source, added, last-reviewed, scope, summary)
- Summary is CPM-oriented (actionable constraints, not human abstract)
- Auto-scope suggestion analyses content and proposes scope values to user
- `docs/library/` directory is created if it doesn't exist
- Skill includes progress file management for compaction resilience
- Plugin registration (plugin.json skill entry) is included

---

### Add consolidation action to `/cpm:library`
**Story**: 2
**Task ID**: 2
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Consolidation action parses `## Amendment` blocks from document body
- Produces a reconciled version integrating amendments into original content
- Front-matter `summary` and `last-reviewed` are updated
- Reconciled version is presented to user for approval before writing
- Contradictory amendments are flagged rather than silently resolved
- Works gracefully if document has no amendments (reports nothing to consolidate)

---

## Epic: Consumer Integration

### Add library check preamble to `/cpm:discover`
**Story**: 3
**Task ID**: 3
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Library check runs after input resolution, before Phase 1
- Globs `docs/library/*.md`; skips silently if directory doesn't exist
- Reads front-matter and filters to docs with `discover` or `all` in scope
- Reports found documents to user with titles
- Deep-reads selectively during discovery phases when relevant
- Malformed front-matter falls back to filename-only context
- Library scan results captured in progress file for compaction resilience

---

### Add library check preamble to `/cpm:spec`
**Story**: 4
**Task ID**: 4
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Library check runs after input/retro check, before Section 1
- Filters to docs with `spec` or `all` in scope
- Reports found documents to user
- Deep-reads selectively during spec sections (especially architecture decisions)
- Graceful degradation and compaction resilience as per Story 3

---

### Add library check preamble to `/cpm:stories`
**Story**: 5
**Task ID**: 5
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Library check runs after input resolution, before Step 1
- Filters to docs with `stories` or `all` in scope
- Reports found documents; deep-reads when relevant to work breakdown
- Graceful degradation and compaction resilience

---

### Add library check preamble to `/cpm:do`
**Story**: 6
**Task ID**: 6
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Library check runs after stories doc resolution, before first task
- Filters to docs with `do` or `all` in scope
- Reports found documents to user
- Deep-reads coding standards and architecture docs when executing implementation tasks
- Library scan results persist across task loop in progress file
- Graceful degradation

---

### Add library check preamble to `/cpm:party`
**Story**: 7
**Task ID**: 7
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Library check runs after roster loading, before first orchestration round
- Filters to docs with `party` or `all` in scope
- Reports found documents; agents can reference library content in their responses
- Graceful degradation and compaction resilience

---

## Epic: Retro Write-Back

### Extend `/cpm:retro` with library amendment capability
**Story**: 8
**Task ID**: 8
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- New step added after retro file is written, before pipeline handoff
- Scans library for documents scoped to `do` or `all`
- Matches retro observations to relevant library documents
- Appends `## Amendment — {date} (via retro)` blocks with source path and category
- Updates `last-reviewed` in front-matter of amended documents
- Presents proposed amendments to user for approval before writing
- Original document content is never modified
- Skips silently if no library directory or no relevant documents
- Progress file updated to reflect write-back step
