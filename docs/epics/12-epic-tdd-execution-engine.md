# TDD Execution Engine

**Source spec**: docs/specifications/16-spec-tdd-mode.md
**Date**: 2026-02-13
**Status**: Complete
**Blocked by**: Epic 11-epic-tdd-tag-pipeline

## Implement TDD sub-loop in cpm:do Step 4
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Req 3 — Red-green-refactor sub-loop, Req 4 — Targeted test execution, Req 5 — Refactor scope constraint

**Acceptance Criteria**:
- `cpm:do` detects `[tdd]` on story acceptance criteria and switches to TDD sub-loop for implementation tasks [manual]
- Red phase: writes a failing test, runs targeted test (specific file, not full suite), confirms failure [manual]
- Green phase: writes minimum implementation, runs targeted test, confirms pass [manual]
- Refactor phase: cleans up code within current task scope, runs targeted test, confirms still passing [manual]
- Targeted test command derived from the test file just written (not the cached full-suite command) [manual]
- Refactor instruction explicitly limits changes to code touched by current task [manual]
- Unexpected results (Red passes, Green fails) trigger stop-and-investigate prompt [manual]

### Add [tdd] detection to Step 1 (Load Context)
**Task**: 1.1
**Description**: When loading story context, check acceptance criteria for `[tdd]` tag and record the workflow mode for use in Step 4
**Status**: Complete

### Implement red-green-refactor sub-loop in Step 4
**Task**: 1.2
**Description**: Add conditional branch for `[tdd]` tasks that replaces standard "Do the Work" with three-phase loop (Red → Green → Refactor), each with a targeted test run
**Status**: Complete

### Add targeted test command construction
**Task**: 1.3
**Description**: Derive the test file path from the test just written and construct a targeted run command distinct from the cached full-suite command
**Status**: Complete

### Add refactor scope constraint instruction
**Task**: 1.4
**Description**: Explicit instruction limiting the refactor phase to code touched by the current task only — no broader restructuring
**Status**: Complete

### Add unexpected result handling
**Task**: 1.5
**Description**: Stop-and-investigate prompt when Red passes unexpectedly or Green still fails after implementation
**Status**: Complete

---

## Ensure backward compatibility for non-TDD stories
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Req 6 — Backward compatibility

**Acceptance Criteria**:
- Stories without `[tdd]` use existing post-implementation workflow unchanged [manual]
- Existing epic docs without `[tdd]` tags are processed normally [manual]
- Mixed epics with both `[tdd]` and non-`[tdd]` stories work correctly [manual]
- No test runner discovered + `[tdd]` story falls back to standard workflow with warning [manual]

### Add graceful degradation for no-runner + [tdd]
**Task**: 2.1
**Description**: When no test command is cached and a `[tdd]` story is encountered, fall back to standard workflow with a warning that TDD requires a test runner
**Status**: Complete

### Update Guidelines section
**Task**: 2.2
**Description**: Replace the lightweight "Task ordering enables TDD" guideline with documentation of the full TDD sub-loop behavior
**Status**: Complete

---
