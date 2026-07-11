# Spec: Prompt Engineering Alignment for Claude 4.6

**Date**: 2026-03-15
**Brief**: docs/discussions/11-discussion-prompt-engineering-best-practices.md

## Problem Summary

CPM skill prompts were authored for earlier Claude models (3.5/Opus 4) where undertriggering was common, using aggressive language (ALL CAPS, "HARD RULE", shouting blockquotes) to ensure compliance. Claude 4.6's improved instruction following means this language now causes overtriggering. Anthropic's latest prompt engineering best practices recommend semantic XML blocks for behavioural directives, motivation-based instructions ("do X so that Y"), positive framing over negatives, and explicit subagent orchestration guidance — none of which CPM currently uses. This spec covers 7 amendments across 13 stateful skill files to align with these best practices.

## Functional Requirements

### Must Have

1. **Replace aggressive progress file language with `<progress_file_discipline>` XML block** — In `cpm:do` (Step 6 Part C), `cpm:quick` (process-level hard rule), and `cpm:party` (state management). Replace ALL CAPS blockquotes and "YOU ARE ABOUT TO SKIP THIS" with a calm XML block explaining *why* the write matters (compaction resilience, session recovery). Identical block text across all three skills.

2. **Add `<investigate_before_answering>` XML block to `cpm:discover` and `cpm:spec`** — Insert inline at the start of codebase exploration phases. Instructs Claude to read relevant files before answering questions about the codebase during facilitation, preventing speculation during requirements conversations.

3. **Add `<subagent_guidance>` XML block to `cpm:do`** — Insert inline before the work loop. Guides Claude on when to delegate to subagents (parallel independent tasks, isolated context) vs. work directly (sequential operations, single-file edits, maintaining context across steps).

### Should Have

4. **Add `<default_to_action>` XML block to `cpm:do`** — Insert inline before task execution (Step 4). Instructs Claude to implement changes rather than asking permission when the task's intent is clear from acceptance criteria and description.

5. **Add motivation/context to key instructions across all 13 stateful skills** — Audit instructions that state rules without explaining why, add "so that..." clauses. Priority targets: state management update instructions, library check skip conditions, format tolerance notes. Apply consistently across all skills per retro guidance.

6. **Reframe "Do NOT" patterns as positive instructions across all 13 stateful skills** — Audit and flip negative instructions where positive framing is clearer. E.g. "Do not create tasks for work already done" → "Skip task creation for work that already exists in the task list."

7. **Add context-awareness line to state management boilerplate across all 13 stateful skills** — Add one line: "Context compaction will fire automatically — your progress file ensures seamless continuation. Work persistently without concern about context limits." Identical text across all 13 skills.

### Won't Have (this iteration)

- Structured JSON state for progress files
- Reducing prescriptive step-by-step instructions in `cpm:do`
- Structural XML wrapping (`<instructions>`, `<context>`)
- Changes to `cpm:templates` (stateless)
- Changes to hook scripts, hooks.json, or roster.yaml
- Extending to other plugins (noteplan, php-lsp, js-simplifier)

## Non-Functional Requirements

### Consistency

All XML blocks of the same type must use identical content across skills. The context-awareness line must be word-for-word identical across all 13 skills. This follows the parallel sessions retro finding that consistent SKILL.md structure enables efficient batch updates.

### Backward Compatibility

Changes are tone/framing only. No skill behaviour, output format, progress file format, or hook interface changes. A session started before these changes should continue working after them.

## Architecture Decisions

### XML Block Placement
**Choice**: All inline at the most relevant point in the procedural flow
**Rationale**: Keeps directives close to where they apply. The progress file discipline block in particular must stay at the point of action — the documented failure mode is that the instruction gets forgotten when it's distant from the write step.
**Alternatives considered**: All in Guidelines section (clean separation but risk of distance from action), hybrid (progress inline, others in Guidelines)

## Scope

### In Scope

- All 13 stateful SKILL.md files for changes 5, 6, 7
- 5 specific skills for XML block additions: `cpm:do`, `cpm:quick`, `cpm:party`, `cpm:discover`, `cpm:spec`
- SKILL.md files only

### Out of Scope

- `cpm:templates` (stateless)
- Hook scripts, hooks.json, roster.yaml
- Output templates and artifact formats
- Any behavioural changes to skill execution flow

### Deferred

- Structured JSON state for progress files
- Prescriptive step reduction in `cpm:do`
- Extending XML blocks to other plugins
- Auditing remaining skills for additional XML block opportunities

## Testing Strategy

### Tag Vocabulary

Test approach tags used in this spec:
- `[manual]` — Manual inspection, observation, or user confirmation

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| 1. progress_file_discipline | Aggressive blockquotes and ALL CAPS removed from cpm:do Step 6 Part C | `[manual]` |
| 1. progress_file_discipline | Same `<progress_file_discipline>` block present in cpm:do, cpm:quick, cpm:party | `[manual]` |
| 1. progress_file_discipline | Block explains *why* (compaction resilience) not just *what* | `[manual]` |
| 2. investigate_before_answering | `<investigate_before_answering>` block present in cpm:discover and cpm:spec | `[manual]` |
| 2. investigate_before_answering | Block instructs to read files before answering codebase questions | `[manual]` |
| 3. subagent_guidance | `<subagent_guidance>` block present in cpm:do | `[manual]` |
| 3. subagent_guidance | Block distinguishes parallel/isolated (delegate) from sequential/contextual (direct) | `[manual]` |
| 4. default_to_action | `<default_to_action>` block present in cpm:do | `[manual]` |
| 5. motivation/context | Key instructions across 13 skills include "so that..." or equivalent motivation | `[manual]` |
| 6. reframe negatives | No "Do NOT" patterns remain where a positive reframe is clearer | `[manual]` |
| 7. context-awareness | Identical context-awareness line present in state management of all 13 skills | `[manual]` |

### Integration Boundaries

None — isolated text edits with no runtime interfaces.

### Test Infrastructure

None required.

### Unit Testing

Not applicable — changes are natural language prompt edits, not executable code.
