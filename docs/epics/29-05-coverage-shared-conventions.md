# Coverage Matrix: Shared Conventions

**Source spec**: docs/specifications/29-spec-opus-4-7-compatibility.md
**Epic**: docs/epics/29-05-epic-shared-conventions.md
**Date**: 2026-04-18

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R6 — Effort calibration | Table covers all skills with level and rationale | Effort table in `cpm2/shared/skill-conventions.md` covers all CPM skills | Story 1 | `[manual]` | ✓ |
| 2 | R7 — Delegation guidance | Shared conventions includes delegation section | Shared conventions includes a "Subagent Delegation" section referencing Anthropic's guidance | Story 2 | `[manual]` | ✓ |
| 3 | R7 — Delegation guidance | At least one skill has explicit subagent fan-out | At least one skill file has an explicit subagent fan-out added where it would parallelise independent work | Story 2 | `[manual]` | ✓ |
