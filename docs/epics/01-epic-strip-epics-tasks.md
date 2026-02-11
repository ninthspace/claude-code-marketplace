# Strip Planning Tasks from cpm:epics

**Source spec**: docs/specifications/12-spec-task-lifecycle.md
**Date**: 2026-02-11
**Status**: Complete
**Blocked by**: —

## Remove task creation steps from cpm:epics
**Story**: 1
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Steps 4 (Create Tasks) and 5 (Set Dependencies) are removed from SKILL.md
- No references to TaskCreate or TaskUpdate remain in the cpm:epics skill
- Step 6 (Confirm) presents the task tree using story numbers and task dot-notation only — no Claude Code task IDs
- Steps are renumbered correctly (old Step 6 becomes Step 4)
- The State Management section's progress file format no longer includes Step 4/5 entries

### Remove Steps 4 and 5, update confirmation, renumber
**Task**: 1.1
**Status**: Complete

---

## Remove Task ID fields from the epic doc template
**Story**: 2
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- The `**Task ID**: —` field is removed from both story-level (`##`) and task-level (`###`) entries in the Output template
- Any prose in the SKILL.md that references Task ID fields is removed or updated
- The Output section's explanatory text about Task ID fields is removed

### Strip Task ID from template and prose
**Task**: 2.1
**Status**: Complete

---
