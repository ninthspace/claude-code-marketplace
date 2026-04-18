# Coverage Matrix: Skill Quality Enhancements

**Source spec**: docs/specifications/29-spec-opus-4-7-compatibility.md
**Epic**: docs/epics/29-04-epic-skill-quality-enhancements.md
**Date**: 2026-04-18

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R5 — Must-NOT clauses | cpm2:spec Section 6b prompts for "must NOT" lines | `cpm2:spec` Section 6b asks "Are there behaviours this criterion explicitly allows that you would reject?" and captures responses as `must NOT` lines paired with positive criteria | Story 1 | `[manual]` | ✓ |
| 2 | R5 — Must-NOT clauses | cpm2:epics Step 3 surfaces/proposes "must NOT" clauses | `cpm2:epics` Step 3 propagates `must NOT` clauses from spec when present | Story 1 | `[manual]` | ✓ |
| 3 | R5 — Must-NOT clauses | cpm2:epics Step 3 surfaces/proposes "must NOT" clauses | `cpm2:epics` Step 3 proposes `must NOT` clauses when absent on stories touching security, data integrity, or external systems | Story 1 | `[manual]` | ✓ |
| 4 | R8 — Codebase grounding | spec, discover, architect have grounding instructions | `cpm2:spec` has an explicit grounding instruction requiring codebase exploration before user-facing responses | Story 2 | `[manual]` | ✓ |
| 5 | R8 — Codebase grounding | spec, discover, architect have grounding instructions | `cpm2:discover` has an explicit grounding instruction requiring codebase exploration before user-facing responses | Story 2 | `[manual]` | ✓ |
| 6 | R8 — Codebase grounding | spec, discover, architect have grounding instructions | `cpm2:architect` has an explicit grounding instruction requiring codebase exploration before user-facing responses | Story 2 | `[manual]` | ✓ |
