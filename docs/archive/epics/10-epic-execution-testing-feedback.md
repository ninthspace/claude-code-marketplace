# Execution Testing & Feedback

**Source spec**: docs/specifications/15-spec-cpm-testing-activities.md
**Date**: 2026-02-12
**Status**: Complete
**Blocked by**: Epic 09-epic-epic-testing-annotations

## Add test runner discovery to cpm:do
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Requirement 7 (test runner discovery)

**Acceptance Criteria**:
- At work loop startup (after library check, before first task), `cpm:do` discovers the test command [manual]
- Discovery priority: (1) library documents scoped to `do` with testing instructions, (2) project config files (`composer.json`, `package.json`, `Makefile`, `pyproject.toml`), (3) ask the user [manual]
- The discovered test command is cached in the progress file and reused across all verification gates [manual]
- If no test runner is discoverable and the user chooses not to provide one, verification gates fall back to self-assessment [manual]

### Add test runner discovery step to SKILL.md
**Task**: 1.1
**Description**: Insert a new startup step between the library check and task selection that discovers the test runner using the priority chain: library docs, config files, user prompt
**Status**: Complete

### Update progress file format
**Task**: 1.2
**Description**: Add a `**Test command**:` field to the progress file template for caching the discovered command
**Status**: Complete

---

## Enhance verification gates to execute tests
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Requirement 3 (execute tests in verification gates), Requirement 4 (write tests as implementation), Requirement 5 (pipeline thread — do stage)

**Acceptance Criteria**:
- Verification gates read test approach tags from the story's acceptance criteria [manual]
- When criteria are tagged `[unit]`, `[integration]`, or `[feature]`, the verification gate runs the cached test command and reports pass/fail [manual]
- When all criteria are `[manual]`, the verification gate performs the existing self-assessment approach [manual]
- When the test command fails, `cpm:do` reports the failure and asks the user how to proceed (not blocking) [manual]
- Testing tasks ("Write tests for {story}") are treated as standard implementation work — no special handling needed beyond what the existing implementation step provides [manual]

### Amend Step 4 (Do the Work)
**Task**: 2.1
**Description**: Update verification gate logic to read tags from criteria and run the cached test command when automated tags are present
**Status**: Complete

### Amend Step 5 (Verify Acceptance Criteria)
**Task**: 2.2
**Description**: Enhance the verification step to use test results (pass/fail) rather than purely self-assessment when automated tags are present
**Status**: Complete

### Add graceful degradation for test failures
**Task**: 2.3
**Description**: Ensure failed test commands result in a user prompt rather than blocking the work loop
**Status**: Complete

---

## Add testing dimensions to cpm:review and cpm:retro
**Story**: 3
**Status**: Complete
**Blocked by**: —
**Satisfies**: Requirement 8 (review test coverage dimension), Requirement 10 (retro testing gap category)

**Acceptance Criteria**:
- `cpm:review` includes "Missing test coverage" as a concern type — flags stories without test approach tags or missing testing tasks when `[unit]`/`[integration]`/`[feature]` criteria warrant them [manual]
- QA and Developer agents in `cpm:review` include test coverage in their review focus areas [manual]
- `cpm:retro` includes "Testing gap" as an observation category for when tests revealed issues criteria didn't anticipate [manual]

### Add "Missing test coverage" concern type to cpm:review
**Task**: 3.1
**Description**: Update the review dimensions list and agent focus areas in SKILL.md to include test coverage checking
**Status**: Complete

### Add "Testing gap" observation category to cpm:retro
**Task**: 3.2
**Description**: Update the observation categories in SKILL.md to include "Testing gap" for when tests reveal issues criteria didn't anticipate
**Status**: Complete

---

## TDD workflow support
**Story**: 4
**Status**: Complete
**Blocked by**: Story 2
**Satisfies**: Requirement 11 (TDD workflow — could-have)

**Acceptance Criteria**:
- When a story's testing task precedes implementation tasks in the epic doc ordering, `cpm:do` respects that sequence [manual]
- No special logic needed — `cpm:do` already processes tasks in order; this story confirms the mechanism works and documents the TDD convention [manual]

### Document TDD convention in cpm:do guidelines
**Task**: 4.1
**Description**: Add a guideline noting that task ordering in the epic doc is respected, enabling TDD when testing tasks are placed before implementation tasks
**Status**: Complete

---
