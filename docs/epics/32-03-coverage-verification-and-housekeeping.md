# Coverage Matrix: Verification & Housekeeping

**Source spec**: docs/specifications/32-spec-opus-4-8-alignment.md
**Epic**: docs/epics/32-03-epic-verification-and-housekeeping.md
**Date**: 2026-05-28

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R6 — Literalism & tool-use verification pass | "Verify the 4.7 work still holds under 4.8: 'apply to every X' instructions state scope explicitly, and the codebase-grounding sections in `spec`/`discover`/`architect` explicitly require Read/Glob/Grep before user-facing answers. Remediate only where a gap is found" | "`spec`/`discover`/`architect` codebase-grounding sections are verified to require Read/Glob/Grep before user-facing answers; gaps remediated minimally" / "'apply to every X'-style instructions across the touched skills are verified to state scope explicitly" | Story 1 | `[manual]` | |
| 2 | R6 — Literalism & tool-use verification pass | "a documented no-change outcome is acceptable" | "must NOT add new behavioural instructions — verification only; a documented no-change outcome is acceptable" | Story 1 | `[manual]` | |
| 3 | R4 — Model identity bump | "Update `.claude-plugin/plugin.json` description and any README references from 'Opus 4.7+' to reflect Opus 4.8." | "`plugin.json` description and any README references reflect Opus 4.8" | Story 2 | `[manual]` | |
| 4 | R4 — Model identity bump | "Version and keywords unchanged." | "must NOT alter `plugin.json` version or keywords; hook suite stays green" | Story 2 | `[unit]` | |
| 5 | R7 — Over-engineering & hard-coding guardrails (could-have) | "A minimal-change guardrail and a 'solve generally, don't hard-code to tests' note, in positive prose." | "`do` and `quick` carry a minimal-change guardrail and a 'solve generally, don't hard-code to tests' note, in positive prose" / "must NOT introduce ALL-CAPS/forceful language (style fidelity holds)" | Story 3 | `[manual]` | |
