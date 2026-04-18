# Coverage Matrix: Shared-Convention Consolidation

**Source spec**: docs/specifications/30-spec-cpm2-post-switch-refinements.md
**Epic**: docs/epics/30-01-epic-shared-convention-consolidation.md
**Date**: 2026-04-18

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R1 — Library Check consolidation | All 8 target skills contain exactly one `Follow the shared **Library Check** procedure` line and zero inline Library Check procedure bodies (grep) | Each of `cpm2/skills/{do,quick,epics,retro,review,party,present,consult}/SKILL.md` contains exactly one line matching `Follow the shared **Library Check** procedure with scope keyword` and zero inline procedure bodies (numbered steps starting with `Glob \`docs/library/*.md\``) | Story 1 | `[manual]` | ✓ |
| 2 | R1 — Library Check consolidation | Each reference line names a scope keyword matching the skill name | Each reference names a scope keyword matching the skill name (e.g. `do` in the `cpm2:do` reference, `quick` in the `cpm2:quick` reference) | Story 1 | `[manual]` | ✓ |
| 3 | R1 — Library Check consolidation | `cpm2:library` still contains the expanded Library Check logic | `cpm2/skills/library/SKILL.md` retains its expanded Library Check logic and is unchanged by this story | Story 1 | `[manual]` | ✓ |
| 4 | R2 — Roster Loading consolidation | All 3 target skills contain exactly one `Follow the shared **Roster Loading** procedure` line and zero inline Roster Loading procedure bodies (grep) | Each of `cpm2/skills/{review,party,consult}/SKILL.md` contains exactly one line matching `Follow the shared **Roster Loading** procedure` and zero inline procedure bodies (numbered steps starting with `Project override`) | Story 2 | `[manual]` | ✓ |
| 5 | Non-functional — Token Efficiency | Total bytes across `cpm2/skills/*/SKILL.md` decrease versus Spec-29 baseline | Total bytes across `cpm2/skills/*/SKILL.md` decrease versus the Spec-29 baseline (commit 513656c `Complete Opus 4.7 compatibility pass for cpm2 plugin`) | Story 3 | `[manual]` | ✓ |
| 6 | Non-functional — Behavioural Preservation | Library Check still fires at the same point in each skill's flow (section header position preserved) | Section header position in each skill's flow is preserved — Library Check still fires at the same point relative to surrounding startup steps | Story 1 | `[manual]` | ✓ |
