# Spec: CPM Ralph Integration — Autonomous Multi-Epic Execution

**Date**: 2026-04-01

## Problem Summary

CPM's `cpm:do` skill executes epic tasks in a supervised loop with user interaction gates (AskUserQuestion). The Ralph Wiggum plugin (by Anthropic) enables autonomous, iterative execution via a stop hook that re-feeds prompts — files persist between iterations, allowing Claude to read its own previous work. Currently, users manually craft Ralph prompts that wrap `/cpm:do` with natural-language overrides to achieve autonomous multi-epic execution. This spec defines a new `cpm:ralph` skill that automates this pattern: discovering epics, generating Ralph-compatible prompts, validating prerequisites, and launching the loop — with structured guardrails for stuck detection, execution logging, and resume capability.

## Functional Requirements

### Must Have

1. **New skill `cpm:ralph`** — a dedicated CPM skill at `cpm/skills/ralph/SKILL.md` for autonomous multi-epic execution via the Ralph Wiggum plugin
2. **Epic selection** — accept epic doc paths/ranges as input arguments, or auto-discover all incomplete epics via glob (`docs/epics/*-epic-*.md`)
3. **Prompt generation** — generate a self-contained Ralph-compatible prompt from epic docs that calls `/cpm:do` with autonomous behaviour instructions, completion conditions, stuck detection rules, and execution log maintenance instructions
4. **Autonomous decision-making** — the generated prompt replaces all `AskUserQuestion` interaction gates with autonomous fallback behaviour: fix test failures, retry unmet criteria, use inline planning, and skip tasks after stuck threshold
5. **Multi-epic transitions** — the generated prompt instructs auto-continue to the next epic when one completes
6. **Completion detection** — the generated `/ralph-loop` command includes a `--completion-promise` that fires when all specified epics are done
7. **Pre-flight validation** — before generating the prompt, verify: epics exist and have pending work, test runner is discoverable, Ralph Wiggum plugin is installed
8. **Progress persistence** — three-layer state: epic doc status fields (primary), CPM progress file (intra-iteration compaction resilience), append-only execution log (cross-iteration history)
9. **Stuck detection** — the generated prompt includes stuck detection logic: if the same task fails verification N times consecutively, skip it and move on (configurable threshold)
10. **Execution log** — the generated prompt instructs Claude to maintain an append-only markdown log file capturing: tasks attempted, verification results, skipped tasks, epic transitions, errors
11. **Dry-run mode** — the skill's default first step is presenting the generated `/ralph-loop` command for user review before execution
12. **Configurable max iterations** — accept `--max-iterations` as a skill argument with a sensible default (e.g. 50)
13. **Selective story execution** — accept story filters (include/exclude) and embed them in the generated prompt
14. **Notification on completion** — the generated prompt includes a distinctive completion output/sentinel when the loop finishes
15. **Resume capability** — detect existing execution log and epic doc statuses from a previous run, and adjust the generated prompt to continue from where it left off
16. **Maintenance coupling notice** — the SKILL.md includes a prominent section documenting that changes to `cpm:do`'s interaction gates (AskUserQuestion usage) may require updates to the prompt template's autonomous behaviour overrides, listing the specific gates that are overridden
17. **Help page updates** — update `cpm/README.md` (skill listing), `/cpm:templates` SKILL.md (interactive skill discovery), and `docs/communications/03-onboarding-guide-cpm-technical.md` (technical onboarding guide) to include `cpm:ralph` with description, usage, and relationship to `cpm:do`

### Won't Have (this iteration)

- **Parallel epic execution** — running multiple epics simultaneously in separate Ralph loops
- **Custom autonomous decision policies** — user-configurable rules for how to handle each type of interaction gate
- **Cross-project execution** — running epics from different project directories

## Non-Functional Requirements

### Reliability
- Generated prompts are deterministic — same epics and configuration produce the same prompt
- Progress persistence survives Ralph's stop-hook cycle (file written before Claude exits, readable on re-entry)
- Stuck detection does not false-positive on tasks that legitimately take multiple iterations

### Usability
- Dry-run output is copy-pasteable as a valid `/ralph-loop` command
- Execution log is human-readable markdown without tooling
- Skill invocation is as simple as `/cpm:ralph` with sensible auto-discovery defaults

### Error Handling / Data Integrity
- Epic doc modifications (status updates, retro observations) are atomic per-story — no partial updates on interruption
- Execution log is append-only — entries are never lost
- Pre-flight fails fast and clearly if Ralph Wiggum plugin is not installed

## Architecture Decisions

### Composition over Reimplementation
**Choice**: Pure prompt composition — `cpm:ralph` generates a Ralph prompt that calls `/cpm:do` with natural-language overrides for autonomous behaviour
**Rationale**: `cpm:do` already implements story hydration, epic doc parsing, test runner discovery, progress files, and verification gates. Reimplementing this would be pure duplication. The autonomous behaviour is a prompt-level overlay, not a different engine.
**Alternatives considered**: Modal composition (add `autonomous: true` flag to `cpm:do` — deferred as fragility mitigation if needed later), new execution engine (purpose-built autonomous logic — rejected due to duplication)

### Two-Phase Launch
**Choice**: Generate the `/ralph-loop` command and present it for review, then auto-execute on user confirmation
**Rationale**: Combines dry-run safety with low-friction execution. The user always sees what will run before it runs. Dry-run mode is the natural default first step.
**Alternatives considered**: Generate-only (always requires manual copy-paste — too much friction), auto-execute (no chance to inspect — too risky for long-running autonomous loops)

### Three-Layer State Persistence
**Choice**: Epic doc status fields (primary "where am I"), CPM progress file (intra-iteration compaction resilience), append-only execution log (cross-iteration history)
**Rationale**: Epic doc status fields already survive between Ralph iterations (they're files). The progress file handles within-iteration compaction. The execution log is a new artifact that provides cross-iteration audit trail — needed because the progress file is replaced each iteration.
**Alternatives considered**: Single state file (insufficient — can't serve both compaction resilience and cross-iteration history), git-only state (unreliable — requires clean commits between iterations)

### Template with Interpolation
**Choice**: Fixed prompt template embedded in SKILL.md with variable slots (`{epic_list}`, `{max_iterations}`, `{completion_promise}`, etc.)
**Rationale**: Predictable, debuggable, and the generated output is easy for users to understand in dry-run mode. The core prompt structure is stable since it wraps `/cpm:do`.
**Alternatives considered**: Dynamic assembly from epic content (richer but less predictable, harder to debug)

### Standard Skill Structure
**Choice**: Single SKILL.md in `cpm/skills/ralph/`, consistent with all other CPM skills
**Rationale**: No external template files needed — the prompt template lives in the SKILL.md itself. Maintains structural consistency across the plugin.
**Alternatives considered**: None — this was uncontroversial

## Scope

### In Scope
- New `cpm:ralph` skill (`cpm/skills/ralph/SKILL.md`)
- Pre-flight validation (epics, Ralph plugin, test runner)
- Epic discovery and selection (glob, path args, ranges, auto-discover)
- Selective story filtering (include/exclude)
- Prompt template with interpolation (epic list, max iterations, completion promise, autonomous rules, stuck detection, execution log, commit instructions)
- Two-phase launch flow (present → confirm → execute)
- Dry-run mode (present only)
- Execution log format definition (markdown, append-only)
- Resume detection (existing log + epic statuses)
- Notification/sentinel on completion
- State management (progress file for pre-flight phase)
- Maintenance coupling notice in SKILL.md
- Help page updates (README, templates skill, onboarding guide)

### Out of Scope
- Changes to `cpm:do` SKILL.md
- Changes to the Ralph Wiggum plugin
- Parallel epic execution
- Custom per-gate decision policies
- Cross-project execution
- New hooks or hook modifications

### Deferred
- `cpm:do` autonomous mode flag — revisit if prompt composition proves fragile
- Prompt refinement based on execution history — learn from past runs to improve prompts
- Integration with `cpm:retro` — auto-run retro after Ralph loop completes

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:
- `[manual]` — Manual inspection, observation, or user confirmation
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| 1. New skill | SKILL.md exists at `cpm/skills/ralph/SKILL.md` with valid frontmatter | `[manual]` |
| 1. New skill | Skill appears in Claude Code's skill list when plugin is installed | `[manual]` |
| 2. Epic selection | Accepts explicit epic doc paths as arguments | `[feature]` |
| 2. Epic selection | Auto-discovers incomplete epics when no args provided | `[feature]` |
| 2. Epic selection | Handles range-style epic references | `[feature]` |
| 3. Prompt generation | Generated prompt calls `/cpm:do` with the correct epic list | `[manual]` |
| 3. Prompt generation | Generated prompt includes autonomous behaviour instructions | `[manual]` |
| 3. Prompt generation | Generated prompt includes completion promise wrapper | `[manual]` |
| 4. Autonomous decisions | Generated prompt instructs Claude not to use AskUserQuestion | `[manual]` |
| 4. Autonomous decisions | Generated prompt specifies fallback behaviour for each gate type | `[manual]` |
| 5. Multi-epic transitions | Generated prompt instructs auto-continue to next epic | `[manual]` |
| 5. Multi-epic transitions | A Ralph loop completes multiple epics sequentially | `[feature]` |
| 6. Completion detection | Generated command includes `--completion-promise` flag | `[manual]` |
| 6. Completion detection | Generated prompt includes `<promise>` output at correct point | `[manual]` |
| 7. Pre-flight validation | Skill fails fast if no incomplete epics found | `[feature]` |
| 7. Pre-flight validation | Skill warns if Ralph Wiggum plugin not detected | `[feature]` |
| 7. Pre-flight validation | Skill discovers and reports test runner | `[feature]` |
| 8. Progress persistence | Generated prompt instructs execution log maintenance | `[manual]` |
| 8. Progress persistence | Epic doc status fields update correctly across Ralph iterations | `[feature]` |
| 9. Stuck detection | Generated prompt includes stuck threshold and skip logic | `[manual]` |
| 9. Stuck detection | A stuck task is eventually skipped in a real Ralph loop | `[feature]` |
| 10. Execution log | Generated prompt specifies log file path and append-only format | `[manual]` |
| 10. Execution log | Log file is human-readable markdown after a real run | `[feature]` |
| 11. Dry-run mode | Skill presents generated command without executing | `[feature]` |
| 11. Dry-run mode | Output is copy-pasteable as a valid `/ralph-loop` command | `[manual]` |
| 12. Max iterations | Accepts `--max-iterations` argument | `[feature]` |
| 12. Max iterations | Default is applied when not specified | `[feature]` |
| 13. Story filtering | Accepts story filters and includes them in generated prompt | `[feature]` |
| 14. Notification | Generated prompt includes completion sentinel/output | `[manual]` |
| 15. Resume | Detects existing execution log and epic statuses from previous run | `[feature]` |
| 15. Resume | Adjusts generated prompt to continue from previous run's state | `[feature]` |
| 16. Coupling notice | SKILL.md includes prominent maintenance coupling section | `[manual]` |
| 16. Coupling notice | Notice lists specific `cpm:do` AskUserQuestion locations overridden by prompt template | `[manual]` |
| 17. Help updates | `cpm/README.md` includes `cpm:ralph` in skill listing | `[manual]` |
| 17. Help updates | `/cpm:templates` SKILL.md includes `cpm:ralph` in discovery table | `[manual]` |
| 17. Help updates | Onboarding guide includes `cpm:ralph` in pipeline/skill guide | `[manual]` |

### Integration Boundaries
1. **`cpm:ralph` → Ralph Wiggum plugin** — CLI interface: prompt text, `--completion-promise`, `--max-iterations`
2. **Generated prompt → `cpm:do`** — skill invocation with natural-language behaviour overrides
3. **`cpm:ralph` → Epic docs** — file format with `**Status**:` fields
4. **Execution log → Human reviewer** — append-only markdown file

### Test Infrastructure
None required. The deliverable is a SKILL.md file. Testing is primarily manual inspection of generated prompts and end-to-end Ralph loop runs against real epics.

### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
