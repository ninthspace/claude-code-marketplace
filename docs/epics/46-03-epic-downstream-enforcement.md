# Downstream Enforcement and the `[target]` Tag

**Source spec**: docs/specifications/46-spec-environmental-requirements.md
**Date**: 2026-07-27
**Status**: Pending
**Blocked by**: Epic 46-01-epic-constraint-traceability, Epic 46-02-epic-constraint-capture

The enforcement half: `cpm:epics` gap-checks the new class, and `[target]` reaches every skill that
reads a test approach tag.

**Scope widened at breakdown, with Chris's approval.** Spec 46's In Scope list names `spec`,
`brief`, `epics`, `do`, `coverage-rollup.sh` and tests. It does not name `cpm:ralph`, and `[target]`
fails open without it:

- `do/SKILL.md:281` reads "**`[manual]` or no tag**: Self-assess by inspecting the codebase." An  
  unrecognised tag falls into "no tag" and self-assesses — the exact false pass AD6 exists to stop,  
  and worse than no tag at all because it reads as a deliberate verification choice.
- `ralph/SKILL.md:162` encodes the partition literally in the autonomous prompt: "all tagged  
  criteria ([unit]/[integration]/[feature]) have passing test results, and all [manual] criteria  
  have self-assessment lines". A `[target]` criterion is in neither list.

This is retro 23's scope surprise arriving on schedule: a rule stated per-X where X has always had
exactly one Y. "Automated tags are these three, everything else self-assesses" was written when
`[manual]` was the only other tag.

**NFR6 baseline recorded at breakdown**: 206,208 bytes across the five skill files spec 46 touches
— `spec` 22,030 · `brief` 13,428 · `epics` 51,491 · `do` 73,146 · `ralph` 46,113.

## `cpm:epics` gap-checks environmental constraints
**Story**: 1
**Status**: Pending
**Blocked by**: —
**Satisfies**: FR7, AD3

**Acceptance Criteria**:

- The cross-epic gap check treats an uncovered environmental constraint as a GAP, like a must-have, not a warning like a should-have [integration]
- The requirement classes `cpm:epics`' gap check treats as blocking are the same set `coverage-rollup.sh` treats as blocking [integration]
- Both extractions in that comparison are non-empty before they are compared [integration]

The second criterion is Margot's single-definition constraint made checkable, and retro 25's pattern
— derive the two sides from opposite ends and assert them equal, rather than pinning both to a
literal. The third is what stops it going vacuous: two empty extractions compare equal.

### Extend the cross-epic gap check
**Task**: 1.1
**Description**: `epics/SKILL.md:308` compares the union of covered requirements against the spec's Must Have list only. AD3 adds the environmental class as a peer of Must Have, not as a should-have warning. Covers criterion 1.
**Status**: Pending

### Write tests for `cpm:epics` gap-checks environmental constraints
**Task**: 1.2
**Description**: Criterion 2 extracts the blocking set from `epics/SKILL.md` and from `coverage-rollup.sh` independently and asserts they agree. Criterion 3's non-empty assertions must be stated first in the file, before the comparison that depends on them.
**Status**: Pending

---

## `[target]` enters the tag vocabulary
**Story**: 2
**Status**: Pending
**Blocked by**: —
**Satisfies**: FR10, AD6

**Acceptance Criteria**:

- `cpm:spec`'s Section 6a vocabulary and its output template both carry `[target]`, defined as mechanically checkable only against the real deployment target [integration]
- `cpm:epics` propagates `[target]` from spec criteria onto story criteria [integration]
- must NOT — `[target]` is treated as a synonym for `[manual]` by the propagation or selection logic [integration]

### Add `[target]` to `cpm:spec`'s Section 6a and output template
**Task**: 2.1
**Description**: Both sites — Section 6a is what the facilitation presents, the output template is what downstream skills read. A tag in one and not the other is how a vocabulary drifts. Covers criterion 1.
**Status**: Pending

### Add `[target]` to `cpm:epics`' tag propagation
**Task**: 2.2
**Description**: The propagation rules at Step 3 list the tags by name. Covers criterion 2 and the must-NOT.
**Status**: Pending

### Write tests for `[target]` enters the tag vocabulary
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Before writing the must-NOT as an `assert_not_contains`, check whether `[manual]` and `[target]` legitimately appear in the same sentence — they will, in the sentence distinguishing them. Retro 23 found this exact assertion failing for this exact reason; narrow the haystack to where the co-occurrence would be a conflation rather than a contrast.
**Status**: Pending

---

## `[target]` fails closed in autonomous execution [plan]
**Story**: 3
**Status**: Pending
**Blocked by**: Story 2
**Satisfies**: FR10, AD6

**Acceptance Criteria**:

- `cpm:do`'s verification selection reports a `[target]` criterion as unverifiable in this environment, rather than self-assessing it [integration]
- must NOT — an unrecognised tag falls through to the "no tag" self-assessment path at `do/SKILL.md:281` [integration]
- `cpm:ralph`'s prompt states what a `[target]` criterion means for task completion [integration]
- The tag lists in `cpm:do`'s verification selection and `cpm:ralph`'s prompt name the same tags [integration]

`[plan]` because it edits `ralph/SKILL.md:162`, a single sentence that four suites treat as an
interface (retro 27) — the blast radius is known and worth agreeing before the edit, not after.

The second criterion is the one that matters most in this epic. Without it, `[target]` is worse than
no tag at all: it reads as a deliberate verification choice while silently self-assessing.

### Change `do/SKILL.md:281`'s fall-through from open to closed
**Task**: 3.1
**Description**: Today "`[manual]` or no tag: Self-assess" swallows any unrecognised tag. Name `[target]` explicitly, and make an unknown tag report rather than self-assess. Covers criteria 1 and 2.
**Status**: Pending

### Update `cpm:do`'s verification-gate rule at `do/SKILL.md:239`
**Task**: 3.2
**Description**: The parallel statement of the same partition. Leaving it means two rules in one skill disagreeing about one question — the shape retro 27 found when a script stated its exit codes in three places.
**Status**: Pending

### Add `[target]` to `cpm:ralph`'s prompt
**Task**: 3.3
**Description**: `ralph/SKILL.md:162`. Covers criterion 3. Expect the four suites that treat this sentence as an interface to need repinning; check them before the edit rather than after.
**Status**: Pending

### Write tests for `[target]` fails closed in autonomous execution
**Task**: 3.4
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Criterion 4 is the correspondence assertion across `cpm:do` and `cpm:ralph`.
**Status**: Pending

---

## Verify cross-story integration for Downstream Enforcement
**Story**: 4
**Status**: Pending
**Blocked by**: Story 1, Story 2, Story 3
**Satisfies**: NFR6

**Acceptance Criteria**:

- Every skill that names the automated tag set names the same set, across `spec`, `epics`, `do` and `ralph` [integration]
- Each skill's stated byte delta matches its actual, measured across all five skill files spec 46 changes, against the 206,208-byte baseline recorded at breakdown [integration]
- The new elicitation sub-step converges in 1–2 `AskUserQuestion` rounds like every other section [manual] — facilitation behaviour, no automatable oracle

The third criterion is tagged below what spec 46 assigned NFR6 (`[integration]`). Convergence in
1–2 rounds is facilitation behaviour; the byte half keeps the automated tag and does the work.

### Write integration tests for Downstream Enforcement
**Task**: 4.1
**Description**: The first criterion is a four-way version of Story 1's two-way correspondence — the tag vocabulary is now stated in four places, and this is what stops them drifting. The second is deliberately the last verification in the whole change set: measured once against a single baseline rather than three times against three partial ones.
**Status**: Pending

---
