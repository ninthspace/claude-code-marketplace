# Coverage Matrix: Shared Convention Alignment

**Source spec**: docs/specifications/32-spec-opus-4-8-alignment.md
**Epic**: docs/epics/32-01-epic-shared-convention-alignment.md
**Date**: 2026-05-28

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R1 — Subagent delegation re-balanced for 4.8 | "Amend the `Subagent Delegation` section of `shared/skill-conventions.md` to state that 4.8 under-delegates by default, framing the 'Delegate (fan-out) when' cases as actively encouraged (the 'Work inline when' guidance is retained)." | "The `Subagent Delegation` section in `shared/skill-conventions.md` states that Opus 4.8 spawns fewer subagents by default, so explicit fan-out guidance is load-bearing" / "The 'Delegate (fan-out) when' cases are framed as actively encouraged under 4.8" / "The 'Work inline when…' guidance is retained — must NOT be removed" | Story 1 | `[manual]` | ✓ |
| 2 | R1 — Subagent delegation re-balanced for 4.8 | "Verify `review`'s fan-out instruction is imperative enough to fire under 4.8's reluctance." | "`review`'s fan-out instruction (3+ agents → spawn parallel subagents via the Agent tool) fires under 4.8 — verified imperative enough, tightened only if needed" | Story 1 | `[manual]` | ✓ |
| 3 | R3 — Effort Recommendations table re-validated for 4.8 | "Re-assess every medium-tier skill for 4.8 under-thinking risk, update the rationale column to reflect 4.8's strict effort adherence" | "Every medium-tier skill (`library`, `archive`, `retro`, `present`, `status`, `templates`) is assessed for 4.8 under-thinking risk; the rationale column reflects 4.8's strict effort adherence" / "must NOT downgrade `do`/`epics`/`spec`/`architect`/`ralph` below `xhigh`" | Story 2 | `[manual]` | ✓ |
| 4 | R3 — Effort Recommendations table re-validated for 4.8 | "add an advisory note (thinking off by default on 4.8; set a large ~64k output budget at `xhigh`/`max`)" | "An advisory note is added: thinking is off by default on 4.8; set a large ~64k output budget at `xhigh`/`max`" | Story 2 | `[manual]` | ✓ |
