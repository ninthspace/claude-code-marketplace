# Stories: Two-Level Story Model for CPM

**Date**: 2026-02-11
**Source**: docs/specifications/07-spec-two-level-stories.md

## Epic: cpm:stories Skill Update

### Rewrite cpm:stories process steps and output template
**Story**: 1
**Task ID**: 1
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Step 3 instructions describe story-level deliverables (meaningful units of user value), not task-level items
- Step 3b exists and facilitates sub-task identification within each story through user conversation
- Step 4 creates TaskCreate for both stories (verification gates with `Type: verification` marker) and sub-tasks (implementation work with `Stories doc:` / `Story:` / `Task:` references)
- Step 5 applies both dependency rules: intra-story (verification gate `blockedBy` its sub-tasks) and cross-story (sub-tasks `blockedBy` upstream story's verification gate)
- Output template shows the full two-level format: `##` epics, `###` stories (with Story number, Task ID, Status, Blocked by, Acceptance Criteria), `####` tasks (with dot-notation Task number, Task ID, Status)
- Guidelines section explains the distinction between stories (deliverables) and tasks (implementation steps)

---

## Epic: cpm:do Skill Update

### Update cpm:do for two-level story awareness
**Story**: 2
**Task ID**: 2
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Step 1 (Load Context) can locate both `###` stories and `####` tasks in the stories doc by Task ID matching
- Steps 2 and 6 correctly update status for `####` task-level headings in the stories doc
- When a task description contains `Type: verification`, cpm:do treats it as an AC verification gate — reads the parent story's acceptance criteria and verifies them rather than doing implementation work
- Existing behaviour for non-two-level stories docs is unaffected (graceful degradation)
