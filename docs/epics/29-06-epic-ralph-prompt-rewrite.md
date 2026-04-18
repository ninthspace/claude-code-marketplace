# Ralph Prompt Rewrite

**Source spec**: docs/specifications/29-spec-opus-4-7-compatibility.md
**Date**: 2026-04-18
**Status**: Complete
**Blocked by**: Epic 29-03-epic-execution-safety, Epic 29-04-epic-skill-quality-enhancements, Epic 29-05-epic-shared-conventions

## Rewrite the ralph autonomous prompt template [plan]
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R3 — Ralph prompt

**Acceptance Criteria**:

- Prompt uses only positive instructions — zero occurrences of "Do NOT", "NEVER", "Don't" [manual]
- Prompt defines "task complete" as: all tagged criteria have passing test results AND all manual criteria have self-assessment lines in the progress file [manual]
- Prompt defines "failure" for the 3-strike skip rule as: a test command exit code ≠ 0 after a code change attempt (tool errors and permission denials are not failures) [manual]
- Prompt includes a task budget advisory derived from story size [manual]
- Prompt includes a fallback for ambiguous acceptance criteria: mark story "Blocked — criteria ambiguous" and continue [manual]
- Prompt passes all five Smart Ape migration questions: explicit intent, success criteria, constraints, task budget + stop criteria, no negative-only instructions [manual]

**Retro**: [Smooth delivery] The rewritten prompt grew from ~450 to ~700 characters but each addition directly serves a spec requirement — the old 500-char guideline was a 4.6 artifact that the spec explicitly superseded.

### Draft the rewritten prompt template
**Task**: 1.1
**Description**: Replace the current prompt at ralph/SKILL.md:107 with a restructured version. Structure: positive task framing, explicit stop criteria per task, failure rules with concrete definitions, task budget advisory, ambiguity fallback. Must use vocabulary from the do/epics/spec rewrites in prior epics.
**Status**: Complete

### Validate against Smart Ape migration checklist
**Task**: 1.2
**Description**: Verify the draft prompt answers all five questions affirmatively: (1) explicit intent, (2) success criteria, (3) constraints, (4) task budget + stop criteria, (5) no negative-only instructions. Adjust if any fail.
**Status**: Complete

---

## Update ralph prompt hygiene rules and dependency documentation
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: R3 — Ralph prompt

**Acceptance Criteria**:

- Prompt hygiene rules reflect the new prompt structure (character limits, formatting constraints, completion_promise match) [manual]
- cpm2:do interaction gates table is accurate for the rewritten prompt's autonomous behaviour overrides [manual]

**Retro**: [Codebase discovery] The interaction gates table needed 3 new rows from epic 29-03's Termination sections — a direct cross-epic dependency that the blocking relationship correctly enforced.

### Update prompt hygiene rules and interaction gates table
**Task**: 2.1
**Description**: Review the prompt hygiene rules section (~line 110) and the cpm2:do interaction gates table (~line 252). Update both to reflect the new prompt structure, any changed autonomous behaviour overrides, and terminology from prior epic rewrites.
**Status**: Complete

## Lessons

### Smooth Deliveries

- Story 1: The rewritten prompt grew from ~450 to ~700 chars but each addition directly serves a spec requirement — all 5 Smart Ape questions passed on first draft.

### Codebase Discoveries

- Story 2: The interaction gates table needed 3 new rows from epic 29-03's Termination sections — a cross-epic dependency that the blocking relationship (29-06 blocked by 29-03) correctly enforced.
