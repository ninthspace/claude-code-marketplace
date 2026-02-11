# Stories: Task Descriptions in Stories

**Date**: 2026-02-11
**Source**: docs/specifications/09-spec-task-descriptions.md

## Epic: Generation

### Add task description generation to cpm:stories
**Story**: 1
**Task ID**: 5
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- The stories doc output template includes an optional `**Description**:` field on `####` task blocks, placed after `**Task**:` and before `**Task ID**:`
- Step 3b guidance explains when and how to write task descriptions — scope the task within its parent story, clarify which acceptance criteria or concern it addresses
- Step 3b guidance notes descriptions are a judgement call: omit when the title is self-evident (e.g., single-task stories)
- Step 4 TaskCreate template uses the task description as the `{Description with relevant context}` placeholder value
- Existing stories docs without descriptions remain valid — the field is optional, not required

#### Add Description field to stories doc output template
**Task**: 1.1
**Description**: Update the Output section's markdown template to include the optional `**Description**:` field in the `####` task block, placed after `**Task**:` and before `**Task ID**:`.
**Task ID**: 1
**Status**: Complete

#### Update Step 3b with description guidance
**Task**: 1.2
**Description**: Add guidance to Step 3b on writing task descriptions — scope within parent story, clarify which AC the task addresses, note it's a judgement call to omit when self-evident.
**Task ID**: 2
**Status**: Complete

#### Update Step 4 TaskCreate to include description
**Task**: 1.3
**Description**: Update the TaskCreate template in Step 4 to use the task description from the stories doc as the `{Description with relevant context}` placeholder value.
**Task ID**: 3
**Status**: Complete

---

## Epic: Consumption

### Update cpm:do to read task descriptions
**Story**: 2
**Task ID**: 6
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Step 1 (Load Context) reads the `**Description**:` field from the stories doc when present
- Missing descriptions are handled gracefully — `cpm:do` continues to work with title-only tasks
- The description is used alongside (not instead of) the task title and parent story's acceptance criteria

#### Update Step 1 Load Context to read task descriptions
**Task**: 2.1
**Description**: Update cpm:do's Load Context step to read the `**Description**:` field from the stories doc when present and use it alongside the title and parent story's acceptance criteria.
**Task ID**: 4
**Status**: Complete

---
