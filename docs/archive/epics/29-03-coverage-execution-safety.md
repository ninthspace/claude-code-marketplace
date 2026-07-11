# Coverage Matrix: Execution Safety

**Source spec**: docs/specifications/29-spec-opus-4-7-compatibility.md
**Epic**: docs/epics/29-03-epic-execution-safety.md
**Date**: 2026-04-18

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R2 — Stop criteria | Each loop has Termination section with Success/Blocker/Ambiguity | `/cpm2:do` per-task workflow loop has a Termination section with Success, Blocker, and Ambiguity exits | Story 1 | `[manual]` | ✓ |
| 2 | R2 — Stop criteria | Facilitation loops have explicit "good enough" criteria | `/cpm2:spec` facilitation loops have explicit "good enough" termination criteria that prevent 4.7 overthinking | Story 1 | `[manual]` | ✓ |
| 3 | R2 — Stop criteria | Facilitation loops have explicit "good enough" criteria | `/cpm2:epics` facilitation loops have explicit "good enough" termination criteria | Story 1 | `[manual]` | ✓ |
| 4 | R4 — Fallback rules | Every degradation scenario has explicit action + visible result | Every degradation scenario in `do/SKILL.md` specifies an explicit action sequence ending with a visible result | Story 2 | `[manual]` | ✓ |
| 5 | R4 — Fallback rules | TDD without test runner produces visible artefact | TDD-tagged story without test runner produces a visible artefact via AskUserQuestion (not silent degradation) | Story 2 | `[manual]` | ✓ |
| 6 | R4 — Fallback rules | User-affecting degradation uses AskUserQuestion | TDD-tagged story without test runner produces a visible artefact via AskUserQuestion (not silent degradation) | Story 2 | `[manual]` | ✓ |
