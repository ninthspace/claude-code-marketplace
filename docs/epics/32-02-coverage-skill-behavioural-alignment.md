# Coverage Matrix: Skill Behavioural Alignment

**Source spec**: docs/specifications/32-spec-opus-4-8-alignment.md
**Epic**: docs/epics/32-02-epic-skill-behavioural-alignment.md
**Date**: 2026-05-28

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R2 — `audit` coverage-first finding framing | "Reframe `audit` so the finding stage maximises coverage (every issue reported, each tagged with severity **and** confidence) and filtering/ranking happens only at the Executive Summary step." | "`audit`'s finding stage instructs maximise-coverage: every issue reported, each carrying severity and a confidence indicator captured within the existing Description cell (e.g. a leading `(confidence: low\|med\|high)` marker — no new column)" / "Filtering/ranking is explicitly the Executive Summary step, not the finding stage" | Story 1 | `[manual]` | ✓ |
| 2 | R2 — `audit` coverage-first finding framing | "Document schema (findings-table columns, ≤10-bullet Exec Summary cap) is unchanged." | "must NOT add or change findings-table columns or remove the ≤10-bullet Executive Summary cap (confidence lives inside Description)" | Story 1 | `[unit]` | ✓ |
| 3 | R5 — Persona voice reinforcement | "Reinforce `party`, `consult`, and the Perspectives convention to actively render each agent's roster `communicationStyle`/`personality`, so multi-persona output stays differentiated under 4.8's flatter default. Identical phrasing across the three." | "`party`, `consult`, and the Perspectives convention instruct active rendering of each agent's roster `communicationStyle` and `personality`, using identical phrasing across the three" | Story 2 | `[manual]` | ✓ |
| 4 | R5 — Persona voice reinforcement | "must NOT invent persona traits outside the roster" | "must NOT invent persona traits outside the roster" | Story 2 | `[manual]` | ✓ |
