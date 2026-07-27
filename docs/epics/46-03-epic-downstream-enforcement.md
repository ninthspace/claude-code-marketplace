# Downstream Enforcement and the `[target]` Tag

**Source spec**: docs/specifications/46-spec-environmental-requirements.md
**Date**: 2026-07-27
**Status**: Complete
**Blocked by**: Epic 46-01-epic-constraint-traceability, Epic 46-02-epic-constraint-capture
**Retro applied**: 29 · Testing gaps · Applied — Story 3 extends the ralph prompt-clause suites, which have only ever asserted what a clause says. Its suite builds a fixture carrying a `[target]` criterion, runs the real completion script for its exit code, asserts which branch that code selects, and adds a control restoring the pre-fix wording so the assertion is shown to discriminate.
**Retro applied**: 30 · Testing gaps · Applied — Story 1's criterion 3 is the same shape that went vacuous in 46-02. The blocking-class comparison is asserted as pairwise equality with a non-empty control stated before each side, never as a `sort -u` count of distinct values.
**Retro applied**: 30 · Patterns worth reusing · Applied — Story 1's criterion 2 is a correspondence claim, so its mutation set includes one that changes the blocking class set in `cpm:epics` and `coverage-rollup.sh` *consistently* and is expected to stay green, alongside the one-sided ones expected to fire.
**Retro applied**: 28 · Testing gaps · Applied — "treats an environmental constraint as a GAP" is also satisfied by a gap check that blocks on everything. Story 1 pairs it with controls that an uncovered should-have still only warns and an uncovered must-have still blocks, so the assertion distinguishes the change wanted from the change that removes the distinction.

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

**NFR6 deltas, measured at Story 4** once all three epics of spec 46 had landed. Measured once,
against the single baseline above, rather than three times against three partial ones:

| Skill | Baseline | Delta | After |
|-------|----------|-------|-------|
| `spec` | 22,030 | +7,046 | 29,076 |
| `brief` | 13,428 | +1,173 | 14,601 |
| `epics` | 51,491 | +1,619 | 53,110 |
| `do` | 73,146 | +1,353 | 74,499 |
| `ralph` | 46,113 | +991 | 47,104 |
| **Total** | **206,208** | **+12,182** | **218,390** |

NFR6's stated failure condition is "a step that doubles the interview". `cpm:spec` — the file the
requirement singles out as already the longest in the plugin — grew 32.0%, and the five files
together 5.9%. Most of `cpm:spec`'s share is the constraint-inheritance startup check and the
environmental elicitation sub-step from epic 46-02, not the `[target]` vocabulary this epic added.

**The `After` column pins live file sizes and will go stale.** Any later change to one of these five
skills fails the assertion in `test-downstream-enforcement-integration.sh`, correctly — the stated
figure would no longer be the measured one. The remedy is to record a fresh baseline row for that
change, not to loosen the assertion. Story 4's criterion was written this way deliberately; the cost
is real and is raised as a retro observation rather than absorbed silently.

## `cpm:epics` gap-checks environmental constraints
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR7, AD3
**Retro**: [Pattern worth reusing] A correspondence oracle and an inventory assert different
things about the same claim, and this story demonstrated it rather than reasoning about it. The
mutation that added the same third blocking class to **both** `epics/SKILL.md` and
`coverage-rollup.sh` left the correspondence assertion green — correctly, the two components still
agree — while both inventory assertions fired. Correspondence cannot distinguish "both sides block
on the right classes" from "both sides drifted together"; an inventory cannot distinguish a real
agreement from two literals that happen to match. Where a criterion says two components agree *and*
names what they should agree on, that is two assertions, and the two-sided mutation is what shows
neither is redundant. Related: the non-empty control for criterion 3 was first written as
`assert_contains … "must"`, which pins a class name and would fail on precisely the consistent
rename the correspondence assertion exists to permit — a control can be too strong, not only too
weak.

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
**Status**: Complete

### Write tests for `cpm:epics` gap-checks environmental constraints
**Task**: 1.2
**Description**: Criterion 2 extracts the blocking set from `epics/SKILL.md` and from `coverage-rollup.sh` independently and asserts they agree. Criterion 3's non-empty assertions must be stated first in the file, before the comparison that depends on them.
**Status**: Complete

---

## `[target]` enters the tag vocabulary
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR10, AD6
**Retro**: [Testing gap] Retro 23's trap arrived exactly where the epic predicted it, and the
prediction still did not prevent it — because the defect was in the *slice boundary*, not in the
assertion. `[manual]` and `[target]` were confirmed to co-occur legitimately at two sites before a
line of test was written, and the must-NOT was duly scoped to the "reach for `[manual]`" routing
list rather than the file. It failed anyway: the slice ran on to the next guideline bullet, and the
paragraph distinguishing the two tags — written minutes earlier in the same task — sits between
them. The prose you have just authored does not feel like part of the neighbourhood you are
slicing, which is precisely when it is. Narrowing a must-NOT is a decision about where the slice
*ends*, and the end anchor has to be chosen against the file as it is now, not as it was when the
hazard was assessed.

**Acceptance Criteria**:

- `cpm:spec`'s Section 6a vocabulary and its output template both carry `[target]`, defined as mechanically checkable only against the real deployment target [integration]
- `cpm:epics` propagates `[target]` from spec criteria onto story criteria [integration]
- must NOT — `[target]` is treated as a synonym for `[manual]` by the propagation or selection logic [integration]

### Add `[target]` to `cpm:spec`'s Section 6a and output template
**Task**: 2.1
**Description**: Both sites — Section 6a is what the facilitation presents, the output template is what downstream skills read. A tag in one and not the other is how a vocabulary drifts. Covers criterion 1.
**Status**: Complete

### Add `[target]` to `cpm:epics`' tag propagation
**Task**: 2.2
**Description**: The propagation rules at Step 3 list the tags by name. Covers criterion 2 and the must-NOT.
**Status**: Complete

### Write tests for `[target]` enters the tag vocabulary
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Before writing the must-NOT as an `assert_not_contains`, check whether `[manual]` and `[target]` legitimately appear in the same sentence — they will, in the sentence distinguishing them. Retro 23 found this exact assertion failing for this exact reason; narrow the haystack to where the co-occurrence would be a conflation rather than a contrast.
**Status**: Complete

---

## `[target]` fails closed in autonomous execution [plan]
**Story**: 3
**Status**: Complete
**Blocked by**: Story 2
**Satisfies**: FR10, AD6
**Retro**: [Testing gap] A presence-set comparison answers "do these two statements name the same
tags?" and cannot answer "do they say the same thing about them?" — and the difference was invisible
until a mutation showed it. Deleting the verification-gate rule's substantive `[target]` sentence
left the tag named in the rule's trailing exception clause, so the two sets still matched and the
mutation passed a suite that existed to catch exactly that deletion. Retro 28's lesson in a new
place: the assertion was satisfied by the change that removed the feature. The fix is not to
abandon the set comparison — it is the right oracle for the criterion that genuinely asks *which
tags are named* — but to pair it with an assertion on the treatment wherever the claim is about
what a rule *does*. Related: deriving the tag's name from the vocabulary rather than typing it made
the suite survive a three-file consistent rename, and cost one non-obvious defect — `[target]`
interpolated into a `sed` basic regular expression is a *character class* matching one of
`t,a,r,g,e`, so the slice silently matched nothing. Only the non-empty control caught it, on
unmodified files. Derived values need escaping at the point they enter a pattern, and the control
that fires before the assertions depending on it is what makes that survivable.

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
**Status**: Complete

### Update `cpm:do`'s verification-gate rule at `do/SKILL.md:239`
**Task**: 3.2
**Description**: The parallel statement of the same partition. Leaving it means two rules in one skill disagreeing about one question — the shape retro 27 found when a script stated its exit codes in three places.
**Status**: Complete

### Add `[target]` to `cpm:ralph`'s prompt
**Task**: 3.3
**Description**: `ralph/SKILL.md:162`. Covers criterion 3. Expect the four suites that treat this sentence as an interface to need repinning; check them before the edit rather than after.
**Status**: Complete

### Write tests for `[target]` fails closed in autonomous execution
**Task**: 3.4
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Criterion 4 is the correspondence assertion across `cpm:do` and `cpm:ralph`.
**Status**: Complete

---

## Verify cross-story integration for Downstream Enforcement
**Story**: 4
**Status**: Complete
**Blocked by**: Story 1, Story 2, Story 3
**Satisfies**: NFR6
**Retro**: [Testing gap] The mechanical rule for "which lines name the automated tag set" is a trap
with an inviting exit, and the exit is worse than the problem. Four skills name that set, most of
them in several places, and a rule that collects *every* line naming level tags over-collects —
`epics/SKILL.md:464`'s worked example names `[unit]`, `[integration]` and `[manual]` together, quite
correctly, being an illustration of a result rather than a statement of the set. The obvious repair
is to keep only lines whose level-tag set has exactly three members. That repair **defines away
every line that dropped one**, so the assertion could never fail: retro 30's vacuity wearing a
filter instead of a `sort -u | grep -c .`. A filter that removes the cases an assertion exists to
catch is not a narrowing, it is a deletion, and it is hardest to see when it is written as a
tidy-up. The suite reads one designated operative site per skill instead, and says in its header
what that does not cover. Related: the four-sided consistent rename left all three correspondence
hops green and fired only the inventory — Story 1's demonstration reproducing exactly, one epic
later, at four sides instead of two.

**Acceptance Criteria**:

- Every skill that names the automated tag set names the same set, across `spec`, `epics`, `do` and `ralph` [integration]
- Each skill's stated byte delta matches its actual, measured across all five skill files spec 46 changes, against the 206,208-byte baseline recorded at breakdown [integration]
- The new elicitation sub-step converges in 1–2 `AskUserQuestion` rounds like every other section [manual] — facilitation behaviour, no automatable oracle

The third criterion is tagged below what spec 46 assigned NFR6 (`[integration]`). Convergence in
1–2 rounds is facilitation behaviour; the byte half keeps the automated tag and does the work.

### Write integration tests for Downstream Enforcement
**Task**: 4.1
**Description**: The first criterion is a four-way version of Story 1's two-way correspondence — the tag vocabulary is now stated in four places, and this is what stops them drifting. The second is deliberately the last verification in the whole change set: measured once against a single baseline rather than three times against three partial ones.
**Status**: Complete

---
