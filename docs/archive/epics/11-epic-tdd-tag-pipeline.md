# TDD Tag Pipeline

**Source spec**: docs/specifications/16-spec-tdd-mode.md
**Date**: 2026-02-13
**Status**: Complete
**Blocked by**: —

## Add [tdd] to cpm:spec tag vocabulary
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Req 1 — `[tdd]` tag in spec testing strategy

**Acceptance Criteria**:
- Section 6a presents `[tdd]` alongside existing tags with description as workflow mode tag [manual]
- `[tdd]` described as orthogonal to level tags — composes with any level tag (e.g. `[tdd] [unit]`) [manual]
- `[tdd]` without a level tag defaults to `[tdd] [unit]` [manual]
- Spec output template includes `[tdd]` in the Tag Vocabulary section [manual]

### Add [tdd] to Step 6a tag vocabulary list
**Task**: 1.1
**Description**: Add the `[tdd]` entry with workflow mode description to the tag list in Step 6a of cpm:spec SKILL.md
**Status**: Complete

### Update spec output template
**Task**: 1.2
**Description**: Add `[tdd]` to the Tag Vocabulary section in the spec output format template
**Status**: Complete

---

## Propagate [tdd] and reorder tasks in cpm:epics
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Req 2 — Per-story `[tdd]` toggle in epic docs

**Acceptance Criteria**:
- `cpm:epics` Step 3 propagates `[tdd]` from spec criteria to story acceptance criteria [manual]
- When a story carries `[tdd]`, the auto-generated testing task is placed before implementation tasks (reversing the default order) [manual]
- Stories without `[tdd]` retain the default task order — testing task after implementation [manual]
- Non-`[tdd]` stories in the same epic are unaffected by the presence of `[tdd]` stories [manual]

### Add [tdd] awareness to Step 3 tag propagation
**Task**: 2.1
**Description**: Ensure `[tdd]` is recognized and propagated alongside level tags when writing story acceptance criteria in cpm:epics SKILL.md
**Status**: Complete

### Add conditional task reordering in Step 3b
**Task**: 2.2
**Description**: When a story carries `[tdd]`, place the auto-generated testing task before implementation tasks instead of after
**Status**: Complete

### Update Guidelines section
**Task**: 2.3
**Description**: Note the `[tdd]` reordering behavior alongside existing testing task documentation in the Guidelines
**Status**: Complete

---
