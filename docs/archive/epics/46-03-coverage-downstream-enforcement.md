# Coverage Matrix: Downstream Enforcement and the `[target]` Tag

**Source spec**: docs/specifications/46-spec-environmental-requirements.md
**Epic**: docs/epics/46-03-epic-downstream-enforcement.md
**Date**: 2026-07-27

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR7 | `cpm:epics` gap-checks environmental constraints. *(Hazard B.)* | The cross-epic gap check treats an uncovered environmental constraint as a GAP, like a must-have, not a warning like a should-have | Story 1 | `[integration]` | ✓ |
| 2 | FR7 | *(as row 1)* | The requirement classes `cpm:epics`' gap check treats as blocking are the same set `coverage-rollup.sh` treats as blocking | Story 1 | `[integration]` | ✓ |
| 3 | FR7 | *(as row 1)* | Both extractions in that comparison are non-empty before they are compared | Story 1 | `[integration]` | ✓ |
| 4 | AD3 | an uncovered environmental constraint is a blocker like a must-have, not a warning like a should-have … a design that cannot deploy is not a partial delivery. | The cross-epic gap check treats an uncovered environmental constraint as a GAP, like a must-have, not a warning like a should-have | Story 1 | *(architecture decision — no row in the spec's table)* | ✓ |
| 5 | FR10 | Verification approach is stated for target-only constraints. Most environmental constraints can be checked only against the real target, not the dev sandbox. The tag vocabulary says what that means. | `cpm:spec`'s Section 6a vocabulary and its output template both carry `[target]`, defined as mechanically checkable only against the real deployment target | Story 2 | `[integration]` | ✓ |
| 6 | AD6 | `cpm:epics` propagation and `cpm:do` verification-approach selection both learn a sixth tag. | `cpm:epics` propagates `[target]` from spec criteria onto story criteria | Story 2 | *(architecture decision — no row in the spec's table)* | ✓ |
| 7 | FR10 | *(as row 5)* | must NOT — `[target]` is treated as a synonym for `[manual]` by the propagation or selection logic | Story 2 | `[integration]` | ✓ |
| 8 | FR10 | *(as row 5)* | `cpm:do`'s verification selection reports a `[target]` criterion as unverifiable in this environment, rather than self-assessing it | Story 3 | `[integration]` | ✓ |
| 9 | AD6 | Collapsing them into `[manual]` means an autonomous run treats them as self-assessment, and self-assessing "runs on PHP 8.2" from a sandbox where it does is exactly the false pass this spec exists to stop. | must NOT — an unrecognised tag falls through to the "no tag" self-assessment path at `do/SKILL.md:281` | Story 3 | *(architecture decision — no row in the spec's table)* | ✓ |
| 10 | FR10 | *(as row 5)* | `cpm:ralph`'s prompt states what a `[target]` criterion means for task completion | Story 3 | `[integration]` | ✓ |
| 11 | AD6 | *(as row 9)* | The tag lists in `cpm:do`'s verification selection and `cpm:ralph`'s prompt name the same tags | Story 3 | *(architecture decision — no row in the spec's table)* | ✓ |
| 12 | NFR6 | Bounded facilitation and bounded prose … the bytes added to each skill file are stated and asserted. | Each skill's stated byte delta matches its actual, measured across all five skill files spec 46 changes, against the 206,208-byte baseline recorded at breakdown | Story 4 | `[integration]` | ✓ |
| 13 | NFR6 | The new step converges in 1–2 `AskUserQuestion` rounds like every other section | The new elicitation sub-step converges in 1–2 `AskUserQuestion` rounds like every other section | Story 4 | `[integration]` → tagged `[manual]` on the story | ✓ |
| 14 | AD6 | *(as row 9)* | Every skill that names the automated tag set names the same set, across `spec`, `epics`, `do` and `ralph` | Story 4 | *(architecture decision — no row in the spec's table)* | ✓ |

## Notes

**Row 13 is the only downgrade in the change set.** Spec 46 tags NFR6 `[integration]` as a whole.
Convergence in 1–2 `AskUserQuestion` rounds is facilitation behaviour with no automatable oracle, so
the story tags that half `[manual]`. Recorded explicitly because a downgrade is where coverage
quietly weakens; the byte half (row 12) keeps the automated tag and carries the requirement.

**Rows 6, 9, 11 and 14 exist because the scope widened.** Spec 46's In Scope list does not name
`cpm:ralph`, and its Acceptance Criteria Coverage table has no rows for the fall-through at
`do/SKILL.md:281`, because the spec did not know about it. Chris approved the widening at breakdown;
the spec's In Scope list is corrected to match.

**Row 13's self-assessment, recorded here because the progress file does not survive the epic.**
`spec/SKILL.md:168` closes Step 3a with "Converge in 1-2 `AskUserQuestion` rounds, as every other
section does" — pointing at the skill's shared **Facilitation depth** rule at `:59` rather than
restating a bound of its own, which is what "like every other section" asks for. The one clause
that could plausibly authorise more rounds does the opposite: the refusal of an unfalsifiable entry
at `:154` is framed explicitly as "a refinement round, not a rejection", so it sits *inside* the
bound, and the **Fail closed** rule at `:157` blocks the step rather than looping on it. What cannot
be assessed without running a real facilitation is whether it converges in practice; what is
assessed is that the instruction is present, matches the shared rule, and contains no escape from
it. That gap is why the story tags this `[manual]` rather than claiming an oracle it does not have.

**Row 12's baseline is recorded, not derived at verification time.** 206,208 bytes across the five
skill files, measured before any story ran. A delta measured against a baseline taken afterwards
compares the change to itself.
