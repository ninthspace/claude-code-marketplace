# Ralph Skill Core

**Source spec**: docs/specifications/26-spec-cpm-ralph-integration.md
**Date**: 2026-04-01
**Status**: Complete
**Blocked by**: —

## Create skill scaffold and pre-flight validation
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: 1. New skill `cpm:ralph`, 7. Pre-flight validation

**Acceptance Criteria**:
- SKILL.md exists at `cpm/skills/ralph/SKILL.md` with valid frontmatter (name, description, trigger) `[manual]`
- Skill appears in Claude Code's skill list when plugin is installed `[manual]`
- Skill fails fast if no incomplete epics found `[feature]`
- Skill warns if Ralph Wiggum plugin not detected `[feature]`
- Skill discovers and reports test runner `[feature]`

### Create SKILL.md with frontmatter and basic structure
**Task**: 1.1
**Description**: Create the skill file at `cpm/skills/ralph/SKILL.md` with valid frontmatter (name, description, trigger) and the overall document structure (sections for input, process, prompt template, state management, guidelines). Covers the "SKILL.md exists with valid frontmatter" and "appears in skill list" criteria.
**Status**: Complete

### Implement pre-flight validation logic
**Task**: 1.2
**Description**: Add pre-flight validation: check that target epics exist and have pending work, detect whether the Ralph Wiggum plugin is installed, and discover the project's test runner. Covers the three `[feature]` pre-flight criteria.
**Status**: Complete
**Retro**: [Scope surprise] Pre-flight validation (Task 1.2) was already fully covered by the document structure created in Task 1.1 — the two tasks could have been a single task for a SKILL.md deliverable.

---

## Epic discovery, selection, and story filtering
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: 2. Epic selection, 13. Selective story execution

**Acceptance Criteria**:
- Accepts explicit epic doc paths as arguments `[feature]`
- Auto-discovers incomplete epics when no args provided `[feature]`
- Handles range-style epic references `[feature]`
- Accepts story filters and includes them in generated prompt `[feature]`

### Implement epic discovery and argument parsing
**Task**: 2.1
**Description**: Parse skill arguments for explicit epic doc paths, range-style references (e.g. `46-epic-*.md through 50-epic-*.md`), and auto-discover incomplete epics via glob when no args provided. Covers the first three acceptance criteria.
**Status**: Complete

### Implement story filtering
**Task**: 2.2
**Description**: Parse include/exclude story filter syntax from arguments and embed filters in the generated prompt. Covers the story filter criterion.
**Status**: Complete
**Retro**: [Scope surprise] Like Story 1, both tasks were already covered by the initial SKILL.md creation — argument parsing and story filtering were part of the Input section written in Task 1.1.

---

## Prompt template with autonomous behaviour
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1, Story 2
**Satisfies**: 3. Prompt generation, 4. Autonomous decision-making, 5. Multi-epic transitions, 6. Completion detection, 9. Stuck detection, 10. Execution log, 14. Notification on completion

**Acceptance Criteria**:
- Generated prompt calls `/cpm:do` with the correct epic list `[manual]`
- Generated prompt includes autonomous behaviour instructions `[manual]`
- Generated prompt includes completion promise wrapper `[manual]`
- Generated prompt instructs Claude not to use AskUserQuestion `[manual]`
- Generated prompt specifies fallback behaviour for each gate type (test failures, unmet criteria, stuck tasks) `[manual]`
- Generated prompt instructs auto-continue to next epic `[manual]`
- Generated command includes `--completion-promise` flag `[manual]`
- Generated prompt includes `<promise>` output at correct point `[manual]`
- Generated prompt includes stuck threshold and skip logic `[manual]`
- Generated prompt specifies log file path and append-only format `[manual]`
- Generated prompt includes completion sentinel/output `[manual]`

### Write core prompt template structure
**Task**: 3.1
**Description**: Write the fixed prompt template with variable slots (`{epic_list}`, `{max_iterations}`, `{completion_promise}`, etc.). The template calls `/cpm:do` with the interpolated epic list and wraps the completion promise. Covers prompt generation and completion detection criteria.
**Status**: Complete

### Add autonomous decision-making overrides
**Task**: 3.2
**Description**: Add the autonomous behaviour section to the prompt template: instruct Claude not to use AskUserQuestion, specify fallback behaviour for each known gate type (test failures → fix and retry, unmet criteria → re-attempt, formal plan mode → use inline planning). Covers autonomous decision criteria.
**Status**: Complete

### Add multi-epic, stuck detection, execution log, and notification instructions
**Task**: 3.3
**Description**: Complete the prompt template with: auto-continue to next epic on completion, stuck detection threshold and skip logic, execution log file path and append-only format, and completion sentinel/notification output. Covers remaining prompt content criteria.
**Status**: Complete
**Retro**: [Pattern worth reusing] For SKILL.md deliverables, the entire file is often written in the first task. Decomposing into per-section tasks creates busywork when the sections are tightly coupled. Consider single-story single-task for SKILL.md epics.

---

## Two-phase launch, max iterations, and dry-run
**Story**: 4
**Status**: Complete
**Blocked by**: Story 3
**Satisfies**: 11. Dry-run mode, 12. Configurable max iterations

**Acceptance Criteria**:
- Skill presents generated command without executing `[feature]`
- Output is copy-pasteable as a valid `/ralph-loop` command `[manual]`
- Accepts `--max-iterations` argument `[feature]`
- Default max iterations is applied when not specified `[feature]`

### Implement two-phase launch flow
**Task**: 4.1
**Description**: Implement the present → confirm → execute flow: assemble the `/ralph-loop` command with generated prompt, present it to the user for review (dry-run as default first step), then execute on confirmation. Covers dry-run and launch criteria.
**Status**: Complete

### Implement max-iterations argument parsing
**Task**: 4.2
**Description**: Parse `--max-iterations` from skill arguments with a sensible default (e.g. 50). Interpolate the value into the generated `/ralph-loop` command. Covers max iterations criteria.
**Status**: Complete
**Retro**: [Smooth delivery] Two-phase launch and max-iterations were straightforward sections already present from the initial SKILL.md creation.

---

## Resume capability and progress persistence
**Story**: 5
**Status**: Complete
**Blocked by**: Story 3
**Satisfies**: 8. Progress persistence, 15. Resume capability

**Acceptance Criteria**:
- Generated prompt instructs execution log maintenance `[manual]`
- Epic doc status fields update correctly across Ralph iterations `[feature]`
- Detects existing execution log and epic statuses from previous run `[feature]`
- Adjusts generated prompt to continue from previous run's state `[feature]`

### Implement resume detection
**Task**: 5.1
**Description**: Check for existing execution log file and read epic doc status fields to determine if a previous Ralph run was interrupted. Covers resume detection criteria.
**Status**: Complete

### Implement prompt adjustment for resume
**Task**: 5.2
**Description**: When a previous run is detected, adjust the generated prompt to continue from where it left off (skip completed epics/stories, reference existing execution log). Add execution log maintenance instructions to the prompt template. Covers resume adjustment and progress persistence criteria.
**Status**: Complete
**Retro**: [Smooth delivery] Resume detection and prompt adjustment were already part of the initial SKILL.md structure.

---

## Maintenance coupling notice
**Story**: 6
**Status**: Complete
**Blocked by**: Story 3
**Satisfies**: 16. Maintenance coupling notice

**Acceptance Criteria**:
- SKILL.md includes prominent maintenance coupling section `[manual]`
- Notice lists specific `cpm:do` AskUserQuestion locations overridden by prompt template `[manual]`

### Add maintenance coupling section to SKILL.md
**Task**: 6.1
**Description**: Add a prominent "Maintenance Coupling" section to the SKILL.md that documents the dependency on `cpm:do`'s interaction gates, listing each specific AskUserQuestion location in `cpm:do` that the prompt template overrides with autonomous behaviour. Covers both coupling notice criteria.
**Status**: Complete
**Retro**: [Smooth delivery] Maintenance coupling section with full gate table was already written in the initial SKILL.md creation.

## Lessons

### Scope Surprises
- Story 1: Pre-flight validation (Task 1.2) was already fully covered by the document structure created in Task 1.1 — the two tasks could have been a single task for a SKILL.md deliverable.
- Story 2: Like Story 1, both tasks were already covered by the initial SKILL.md creation — argument parsing and story filtering were part of the Input section written in Task 1.1.

### Patterns Worth Reusing
- Story 3: For SKILL.md deliverables, the entire file is often written in the first task. Decomposing into per-section tasks creates busywork when the sections are tightly coupled. Consider single-story single-task for SKILL.md epics.

### Smooth Deliveries
- Story 4: Two-phase launch and max-iterations were straightforward sections already present from the initial SKILL.md creation.
- Story 5: Resume detection and prompt adjustment were already part of the initial SKILL.md structure.
- Story 6: Maintenance coupling section with full gate table was already written in the initial SKILL.md creation.
