# Add Hydration to cpm:do

**Source spec**: docs/specifications/12-spec-task-lifecycle.md
**Date**: 2026-02-11
**Status**: Complete
**Blocked by**: —

## Add per-story hydration gating check
**Story**: 1
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Before task selection, cpm:do checks whether pending unblocked Claude Code tasks exist
- If no pending unblocked tasks exist, cpm:do reads the epic doc, identifies the next unblocked story, and creates Claude Code tasks (TaskCreate) for that story's tasks plus its verification gate
- Intra-story dependencies are set (verification gate blocked by its tasks) via TaskUpdate
- Hydration is incremental — only one story's tasks are created at a time, not the entire epic
- The hydration logic tolerates both old-format epic docs (with Task ID fields) and new-format (without)
- Cross-story dependencies from the epic doc's Blocked by declarations are respected when identifying the "next unblocked story"

### Write per-story hydration logic
**Task**: 1.1
**Description**: Parse the epic doc to identify the next unblocked story, create Claude Code tasks for its tasks and verification gate, and set intra-story dependencies
**Status**: Complete

### Integrate hydration as gating check in the work loop
**Task**: 1.2
**Description**: Wire the hydration logic into the existing workflow — it fires before task selection, covering both initial entry and story-to-story transitions
**Status**: Complete

---

## Merge completion and progress write
**Story**: 2
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Current Step 6 (Mark Complete) and Step 7 (Update Progress File) are merged into a single step
- The merged step performs: epic doc status update, TaskUpdate to completed, and Write to .cpm-progress.md — all in one instruction block
- Subsequent steps are renumbered correctly
- The State Management section reflects the merged step
- No standalone "update progress file" step remains that could be skipped

### Merge Steps 6 and 7, renumber subsequent steps
**Task**: 2.1
**Status**: Complete

---

## Add idempotent hydration
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Before creating tasks during hydration, cpm:do checks TaskList for existing tasks matching the current story/epic
- If matching tasks already exist (from a previous partial run), hydration skips creation and uses the existing tasks
- A second invocation of cpm:do against the same epic/story does not produce duplicate Claude Code tasks

### Add duplicate detection before task creation
**Task**: 3.1
**Description**: Check TaskList for existing tasks whose descriptions reference the same epic doc and story number before calling TaskCreate
**Status**: Complete

---
