# Spec: Story Intent Clarity

**Date**: 2026-02-19
**Brief**: docs/discussions/03-discussion-story-intent-clarity.md

## Problem Summary

Task descriptions in `cpm:epics` Step 3b are optional and often skipped by the producing agent, leaving a gap between story-level intent ("what are we building?") and implementation detail ("how do we build it?"). The `**Description**` field exists but guidance is vague — "This is a judgement call, not a mandatory field" — so multi-task stories frequently produce tasks with titles only. This forces the implementer (or post-compaction context) into a three-hop lookup (title → story criteria → spec) to understand what a task's slice actually covers. The discussion identified three layers of intent clarity: layer 1 (story title + criteria) is stable, layer 3 (code snippets, file paths) is immediately flaky, and layer 2 (task scope within a story) is the gap. The fix is to strengthen the description field's guidance — not add new fields or inject implementation detail.

## Functional Requirements

### Must Have
1. **Default-on descriptions for multi-task stories** — `cpm:epics` Step 3b writes a `**Description**` field for every task in stories with 2+ tasks. Single-task stories may omit the description when the title is self-evident.
2. **Criteria-anchored descriptions** — Task descriptions reference which acceptance criteria the task addresses, creating a traceable link: task → criteria → spec requirement. This reduces the three-hop lookup to a one-hop read.
3. **Constraint-style description guidance** — Step 3b guidance encourages descriptions that state scope boundaries ("handles the error path," "produces the interface for Task 2.3," "addresses the error handling path for criterion X") rather than implementation steps ("edit file.php to add a try/catch block").

### Should Have
4. **Description examples in the guidance** — Include 2-3 concrete examples of good vs. bad descriptions to make the guidance actionable for the LLM. Good descriptions anchor to criteria or state constraints; bad descriptions prescribe implementation steps or file paths.

### Won't Have (this iteration)
- New fields on tasks (e.g. `**Constraints**`, `**Scope**`) — the Description field is sufficient
- Changes to `cpm:do` — it already reads task descriptions during Step 1 (Load Context); the consumer contract doesn't change
- Changes to story-level format — stories already have acceptance criteria
- Implementation detail in descriptions — no code snippets, file paths, or step-by-step instructions

## Non-Functional Requirements

### Consistency
- Updated guidance must maintain structural consistency with existing SKILL.md patterns across CPM skills — same heading levels, same paragraph density, same instruction style.

### Maintainability
- Guidance text should be concise enough that the LLM follows it reliably without instruction bloat. Longer guidance risks being ignored during compaction or high-momentum task execution. The description field's guidance should fit in a single focused paragraph plus optional examples.

## Architecture Decisions

### Guidance Location
**Choice**: Modify the existing `**Task descriptions**` paragraph in Step 3b in-place, plus update the output template hint text.
**Rationale**: The existing paragraph is where `cpm:epics` already looks when writing tasks. Adding a separate section would increase scroll distance and risk being overlooked during compaction. The output template already includes `**Description**` on every task — only the hint comment needs updating.
**Alternatives considered**: New "Description Writing Guide" section (adds unnecessary structure for a paragraph-level change), new field alongside Description (over-engineering — the existing field is sufficient).

## Scope

### In Scope
- Rewrite the `**Task descriptions**` paragraph in `cpm/skills/epics/SKILL.md` Step 3b
- Update the output template hint text (the `{One-sentence scope...}` comment) in the same file
- Add good-vs-bad examples if the should-have is included

### Out of Scope
- Changes to `cpm:do` (it already reads descriptions — no contract change needed)
- Changes to `cpm:party`, `cpm:consult`, or any other CPM skill
- New fields on the task format
- Changes to story-level acceptance criteria format

### Deferred
- Automated validation that descriptions reference valid criteria (over-engineering for a prompt-based system)

## Testing Strategy

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion |
|---|---|
| Default-on descriptions | Step 3b guidance states descriptions are written for every task in multi-task stories |
| Default-on descriptions | Single-task stories explicitly allowed to omit descriptions |
| Criteria-anchored descriptions | Guidance instructs descriptions to reference which acceptance criteria the task addresses |
| Constraint-style guidance | Guidance encourages scope boundaries over implementation steps |
| Description examples | At least 2 good-vs-bad examples included in guidance |

All criteria verified by manual inspection of the modified SKILL.md text.

### Integration Boundaries
- **cpm:epics → cpm:do**: The `**Description**` field is the contract. `cpm:epics` produces it, `cpm:do` Step 1 reads it. This spec changes production guidance but not the field format — the integration boundary is unchanged.

### Test Infrastructure
None required. All verification is manual text inspection.

### Unit Testing
Not applicable — this spec modifies prompt guidance text, not executable code.
