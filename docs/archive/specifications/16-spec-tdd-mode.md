# Spec: CPM TDD Mode

**Date**: 2026-02-13
**Discussion**: docs/discussions/01-discussion-tdd-mode.md

## Problem Summary

The CPM execution pipeline uses post-implementation testing exclusively. `cpm:do` writes code first, then runs tests as a verification gate. A lightweight TDD convention exists — `cpm:epics` can place testing tasks before implementation tasks, and `cpm:do` respects that ordering — but there's no explicit workflow mode tag, no per-story opt-in mechanism, and no red-green-refactor discipline loop. This spec adds `[tdd]` as an optional, per-story workflow mode that switches `cpm:do` into a red-green-refactor sub-loop with targeted test execution.

## Functional Requirements

### Must Have

1. **`[tdd]` tag in spec testing strategy.** `cpm:spec` Section 6 includes `[tdd]` in the tag vocabulary as a workflow mode tag, orthogonal to test level tags (`[unit]`, `[integration]`, `[feature]`, `[manual]`). A criterion can carry both a level tag and `[tdd]` (e.g. `[tdd] [unit]`). `[tdd]` without a level tag defaults to `[tdd] [unit]`.

2. **Per-story `[tdd]` toggle in epic docs.** `cpm:epics` propagates `[tdd]` from spec to story acceptance criteria. When a story carries `[tdd]`, its testing task is placed before implementation tasks (reversing the default order). Stories without `[tdd]` retain the default order.

3. **Red-green-refactor sub-loop in `cpm:do`.** When `cpm:do` encounters a task under a `[tdd]`-tagged story, Step 4 (Do the Work) is replaced with a three-phase sub-loop:
   - **Red**: Write a failing test derived from the acceptance criteria. Run the targeted test to confirm failure.
   - **Green**: Write the minimum implementation to make the test pass. Run the targeted test to confirm it passes.
   - **Refactor**: Clean up the implementation within the scope of the current task. Run the targeted test to confirm it still passes.
   - Unexpected results (Red passes, Green still fails after implementation) trigger a stop-and-investigate prompt to the user.

4. **Targeted test execution.** During the TDD sub-loop, `cpm:do` runs only the specific test file or test case being worked on — not the full test suite. The targeted command is derived from the test file just written (e.g. `pest tests/Feature/MyTest.php`, `jest path/to/test.spec.ts`). The full test suite runs once at the story verification gate (Step 5), same as non-TDD stories.

5. **Refactor scope constraint.** The refactor step is explicitly limited to code touched by the current task. No broader codebase restructuring. Enforced by prompt instruction.

6. **Backward compatibility.** Stories without `[tdd]` continue to use the existing post-implementation workflow with zero changes. Existing epic docs and specs without `[tdd]` tags are processed normally.

### Should Have

7. **Exploratory task escape hatch.** Within a `[tdd]`-tagged story, individual tasks can carry a `**Mode**: explore` field to skip the TDD sub-loop for tasks where the interface isn't known upfront. These fall back to the standard write-then-verify workflow.

8. **`cpm:retro` TDD-aware observations.** Retro observations distinguish between TDD and post-implementation stories, enabling comparison of outcomes between modes.

### Could Have

9. **`cpm:review` TDD compliance check.** Review skill verifies that `[tdd]`-tagged stories have their testing task ordered before implementation tasks.

### Won't Have (this iteration)

- Automatic detection of which stories are TDD-suitable
- CI/CD integration for TDD workflows
- Code coverage metrics during TDD
- Changes to `cpm:discover`, `cpm:brief`, `cpm:architect`, `cpm:party`, `cpm:pivot`, `cpm:archive`, `cpm:library`, `cpm:templates`, `cpm:present`

## Non-Functional Requirements

### Backward Compatibility
Stories without `[tdd]` continue to use the existing post-implementation workflow unchanged. Existing epic docs, specs, and artifacts remain valid. `[tdd]` is additive. `cpm:do` gracefully handles mixed epics where some stories are `[tdd]` and others aren't.

### Consistency
`[tdd]` follows the same inline tag convention as `[unit]`, `[integration]`, `[feature]`, `[manual]`. Defined once in `cpm:spec` Section 6 and referenced by `cpm:epics` and `cpm:do`. The TDD sub-loop uses the same test runner discovered by `cpm:do`'s existing Test Runner Discovery step.

### Graceful Degradation
- No test runner discovered + `[tdd]` story: `cpm:do` falls back to the standard write-then-verify workflow and warns the user that TDD requires a test runner.
- `[tdd]` without a level tag: treated as `[tdd] [unit]` by default.

## Architecture Decisions

### Tag System Placement
**Choice**: `[tdd]` as an inline tag composable with existing level tags, parsed by the same tag extraction machinery.
**Rationale**: Zero new parsing infrastructure. Flows through existing propagation from spec → epics → do. Orthogonal by design — workflow mode vs test level.
**Alternatives considered**: Separate `**Mode**: tdd` field per story — rejected because it doesn't compose with the existing tag vocabulary and requires new parsing logic.

### TDD Sub-Loop Structure
**Choice**: Replace Step 4 (Do the Work) in `cpm:do` for `[tdd]` tasks with a three-phase sub-loop. Each phase runs the targeted test only (not the full suite). Red must fail, Green must pass, Refactor must still pass. The full test suite runs once at the story verification gate. Unexpected results trigger stop-and-investigate.
**Rationale**: Targeted test runs keep the TDD feedback loop fast — critical for large codebases (6000+ tests). The full suite catches regressions at the story boundary without slowing the inner loop.
**Alternatives considered**: Full suite at every phase — rejected for performance. Single test run after all three phases — rejected because it loses the red-green feedback that defines TDD.

## Scope

### In Scope
- `cpm:spec` Section 6: add `[tdd]` to tag vocabulary as workflow mode tag
- `cpm:epics`: propagate `[tdd]`, reorder testing task before implementation for `[tdd]` stories
- `cpm:do` Step 4: TDD sub-loop (red-green-refactor) with targeted test execution
- `cpm:do`: targeted test command construction (specific test file, not full suite)
- `cpm:do`: refactor scope constraint instruction
- Backward compatibility for non-`[tdd]` stories

### Out of Scope
- Changes to `cpm:discover`, `cpm:brief`, `cpm:architect`, `cpm:party`, `cpm:pivot`, `cpm:archive`, `cpm:library`, `cpm:templates`, `cpm:present`
- Automatic detection of TDD-suitable stories
- CI/CD integration for TDD workflows
- Code coverage metrics

### Deferred
- Exploratory task escape hatch (`**Mode**: explore`)
- `cpm:retro` TDD-aware observation tracking
- `cpm:review` TDD compliance checking

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:
- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag. Orthogonal — describes how to work, not what kind of test.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| 1. `[tdd]` in spec Section 6 | Section 6 presents `[tdd]` in tag vocabulary alongside existing tags | `[manual]` |
| 1. `[tdd]` in spec Section 6 | `[tdd]` described as workflow mode, orthogonal to level tags | `[manual]` |
| 1. `[tdd]` in spec Section 6 | Criteria can carry both `[tdd]` and a level tag | `[manual]` |
| 2. Per-story toggle in epics | `cpm:epics` propagates `[tdd]` from spec to story criteria | `[manual]` |
| 2. Per-story toggle in epics | `[tdd]` stories have testing task before implementation tasks | `[manual]` |
| 2. Per-story toggle in epics | Non-`[tdd]` stories retain default task order | `[manual]` |
| 3. TDD sub-loop in cpm:do | `cpm:do` detects `[tdd]` and switches to TDD sub-loop | `[manual]` |
| 3. TDD sub-loop in cpm:do | Red: writes failing test, runs targeted test, confirms failure | `[manual]` |
| 3. TDD sub-loop in cpm:do | Green: writes minimum implementation, runs targeted test, confirms pass | `[manual]` |
| 3. TDD sub-loop in cpm:do | Refactor: cleans up code, runs targeted test, confirms still passing | `[manual]` |
| 3. TDD sub-loop in cpm:do | Unexpected results trigger stop-and-investigate | `[manual]` |
| 4. Targeted test execution | Sub-loop runs specific test file, not full suite | `[manual]` |
| 4. Targeted test execution | Full suite runs at story verification gate only | `[manual]` |
| 5. Refactor scope constraint | Refactor instruction limits changes to current task scope | `[manual]` |
| 6. Backward compatibility | Non-`[tdd]` stories use existing workflow unchanged | `[manual]` |
| 6. Backward compatibility | Existing artifacts without `[tdd]` processed normally | `[manual]` |

### Integration Boundaries
- **Spec → Epics**: `[tdd]` tag in spec testing strategy parseable by `cpm:epics` and propagated to story criteria
- **Epics → Do**: `[tdd]` on story criteria triggers `cpm:do` TDD sub-loop; testing-before-implementation task order recognized during hydration
- **Do internal**: Targeted test command construction — derives test file path from the test just written

### Test Infrastructure
None required. Prompt-based plugin — verification is manual skill execution.

### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
