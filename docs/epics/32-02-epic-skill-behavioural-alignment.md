# Skill Behavioural Alignment

**Source spec**: docs/specifications/32-spec-opus-4-8-alignment.md
**Date**: 2026-05-28
**Status**: Pending
**Blocked by**: Epic 32-01-epic-shared-convention-alignment

## Apply coverage-first finding framing to audit
**Story**: 1
**Status**: Pending
**Blocked by**: —
**Satisfies**: R2 — `audit` coverage-first finding framing

**Acceptance Criteria**:

- `audit`'s finding stage instructs maximise-coverage: every issue reported, each carrying severity and a confidence indicator captured within the existing Description cell (e.g. a leading `(confidence: low|med|high)` marker — no new column) [manual]
- Filtering/ranking is explicitly the Executive Summary step, not the finding stage [manual]
- must NOT add or change findings-table columns or remove the ≤10-bullet Executive Summary cap (confidence lives inside Description) [unit]

### Add coverage-first instruction to audit's finding stage
**Task**: 1.1
**Description**: Instruct report-everything with severity + in-cell confidence marker at the finding step; keep ranking/filtering at the Executive Summary. Covers R2 criteria 1–2.
**Status**: Pending

### Run the existing audit structure tests to confirm schema unchanged
**Task**: 1.2
**Description**: Run `cpm2/hooks/tests/test-audit-skill.sh`; confirm the findings-table header and Executive Summary assertions still pass after the framing edit. Reuses the existing suite (retro guidance) rather than writing new tests. Covers R2 criterion 3 [unit].
**Status**: Pending

---

## Reinforce persona voice under 4.8's flatter default
**Story**: 2
**Status**: Pending
**Blocked by**: —
**Satisfies**: R5 — Persona voice reinforcement

**Acceptance Criteria**:

- `party`, `consult`, and the Perspectives convention instruct active rendering of each agent's roster `communicationStyle` and `personality`, using identical phrasing across the three [manual]
- must NOT invent persona traits outside the roster [manual]

### Add persona-voice reinforcement to the Perspectives convention
**Task**: 2.1
**Description**: Add the canonical reinforcement text (active use of roster `communicationStyle`/`personality`) to the Perspectives section of `shared/skill-conventions.md`. This is the phrasing the skills mirror. Covers R5 criterion 1.
**Status**: Pending

### Mirror the identical phrasing into party and consult
**Task**: 2.2
**Description**: Insert the exact Task 2.1 wording into `party` and `consult`; no invented traits. Covers R5's identical-phrasing criterion (retro: batch SKILL.md consistency) and the must-NOT.
**Status**: Pending

---
