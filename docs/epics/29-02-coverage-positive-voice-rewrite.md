# Coverage Matrix: Positive Voice Rewrite

**Source spec**: docs/specifications/29-spec-opus-4-7-compatibility.md
**Epic**: docs/epics/29-02-epic-positive-voice-rewrite.md
**Date**: 2026-04-18

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R1 — Negative→positive rewrite | Every negative triaged: rewritten or preserved with inline rationale | Every negative instruction in do, epics, ralph, and spec triaged as behaviour-shaping, hard constraint, or hint and either rewritten to positive form or preserved with inline rationale | Story 1 | `[manual]` | ✓ |
| 2 | R1 — Negative→positive rewrite | Every negative triaged: rewritten or preserved with inline rationale | Every negative instruction in all 14 standalone skill files triaged and either rewritten or preserved with inline rationale | Story 2 | `[manual]` | ✓ |
| 3 | R1 — Negative→positive rewrite | No net-new negative instructions introduced (grep) | No net-new negative instructions introduced in any file | Story 2 | `[manual]` | ✓ |
| 4 | R1 — Negative→positive rewrite | No net-new negative instructions introduced (grep) | No net-new negative instructions introduced during the rewrite (diff comparison) | Story 3 | `[manual]` | ✓ |
| 5 | R1 — Negative→positive rewrite | Preserved negatives annotated with load-bearing rationale | Grep for `Don't\|Do not\|Never\|Avoid` across all `cpm2/skills/*/SKILL.md` returns only entries with inline load-bearing rationale | Story 3 | `[manual]` | ✓ |
