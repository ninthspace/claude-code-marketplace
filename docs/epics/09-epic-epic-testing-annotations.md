# Epic Testing Annotations

**Source spec**: docs/specifications/15-spec-cpm-testing-activities.md
**Date**: 2026-02-12
**Status**: Complete
**Blocked by**: Epic 08-epic-spec-testing-strategy

## Propagate test approach tags to story acceptance criteria
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Requirement 2 (testing annotations on stories), Requirement 5 (pipeline thread — epics stage)

**Acceptance Criteria**:
- When the input spec has a Testing Strategy with tagged criteria, Step 3 reads those tags and applies matching tags inline on story acceptance criteria [manual]
- Tags follow the `[tag]` format on the acceptance criteria line, consistent with how the spec defines them [manual]
- When the spec has no testing strategy or no tags, Step 3 behaviour is unchanged (backward compatible) [manual]
- The progress file captures which tags were propagated for compaction resilience [manual]

### Amend Step 3 in SKILL.md to read spec testing strategy and propagate tags
**Task**: 1.1
**Description**: Add logic to extract tag assignments from the spec's testing strategy section and apply matching tags when writing story acceptance criteria
**Status**: Complete

---

## Auto-generate testing tasks and integration testing stories
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Requirement 2 (testing annotations), Requirement 5 (pipeline thread), Requirement 9 (integration testing stories)

**Acceptance Criteria**:
- Stories with `[unit]`, `[integration]`, or `[feature]` criteria get a "Write tests for {story title}" task auto-generated in Step 3b [manual]
- The testing task is placed after implementation tasks by default [manual]
- Stories with only `[manual]` criteria do not get testing tasks [manual]
- For integration-heavy epics, a dedicated integration testing story is generated after all implementation stories, blocked by the stories it validates [manual]
- The integration testing story has its own acceptance criteria about cross-story behaviour [manual]

### Amend Step 3b to auto-generate testing tasks
**Task**: 2.1
**Description**: Add logic to check for automated test tags on criteria and generate a "Write tests" task when present
**Status**: Complete

### Add integration testing story generation
**Task**: 2.2
**Description**: After all stories are defined, assess whether the epic warrants a dedicated integration testing story and generate it with appropriate blocking dependencies
**Status**: Complete

### Update epic output template guidance
**Task**: 2.3
**Description**: Ensure the guidelines and output format sections reference testing tasks and integration testing stories
**Status**: Complete

---
