# Autonomous Epic Generation

**Source spec**: docs/specifications/45-spec-delivery-autonomy.md
**Date**: 2026-07-26
**Status**: Pending
**Blocked by**: —

## Add the autonomous branch for the five proposal gates
**Story**: 1
**Status**: Pending
**Blocked by**: —
**Satisfies**: FR4

**Acceptance Criteria**:

- The branch is defined in `cpm:epics`; `cpm:ralph`'s prompt references it rather than restating it [integration]
- Each of `:81`, `:178`, `:214`, `:231`, `:282` has a stated autonomous disposition [integration]

### Add the autonomous branch section covering the five approve-your-own-proposal gates
**Task**: 1.1
**Description**: Covers the second criterion. Scoped to the five gates where a proposal is already rendered and "approve your own proposal" is a defensible default — epic grouping, stories, tasks, the integration-testing story, and final confirmation. The must-NOT gate at `:155` is Story 2's and is deliberately not touched here.
**Status**: Pending

### Reference the branch from `cpm:ralph`'s prompt without restating it
**Task**: 1.2
**Description**: Covers the first criterion. `cpm:do`'s retro-gate overrides already take this shape — the prompt names the branch and `cpm:do` defines it — so the constraint is that the prompt gains a reference, not a second copy of the rules. Retro 21's "only the template is operative" is why the reference has to be in the template rather than the override table.
**Status**: Pending

### Write tests for Add the autonomous branch for the five proposal gates
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Pending

---

## Add the must-NOT gate rule
**Story**: 2
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: FR5

**Acceptance Criteria**:

- Spec-originated must-NOT clauses are propagated; others are recorded as proposed-unreviewed rather than attached [integration]
- must NOT attach a must-NOT clause that cannot be traced to a line in the source spec [integration]

### Add the `:155` rule per AD5
**Task**: 2.1
**Description**: Covers both criteria. The distinction the rule turns on is transcription versus judgement: a must-NOT the spec's own Section 6b probed for is citable, one invented for a domain the spec never mentioned is not. Record what would have been proposed rather than dropping it silently.
**Status**: Pending

### Write tests for Add the must-NOT gate rule
**Task**: 2.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Retro 21's hazard is the negative control worth building: an invented must-NOT can be unsatisfiable as written, which is what makes auto-accepting one dangerous rather than merely over-cautious.
**Status**: Pending

---

## Bound the write surface and record the audit trail
**Story**: 3
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: NFR3, NFR4

**Acceptance Criteria**:

- An autonomous run writes nothing under `docs/specifications/` [integration]
- must NOT write to `docs/specifications/` during an autonomous run [integration]
- Each autonomous gate decision leaves a breadcrumb naming the gate and the choice [integration]

### Add the write-surface boundary and the breadcrumb format
**Task**: 3.1
**Description**: Covers all three criteria. The boundary is stated at the branch rather than as a general guideline, because that is where a reader looks for what the autonomous path may do. The must-NOT names the **path**, not the word "spec" — retro 21 found a must-NOT phrased against a token constrains the prose as well as the behaviour, and "spec" appears throughout the explanatory text here.
**Status**: Pending

### Write tests for Bound the write surface and record the audit trail
**Task**: 3.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Pending

---

## Verify cross-story integration for Autonomous Epic Generation
**Story**: 4
**Status**: Pending
**Blocked by**: Story 1, Story 2, Story 3
**Satisfies**: FR4

**Acceptance Criteria**:

- Every one of the six gate sites has a stated autonomous disposition [integration]
- must NOT leave any gate site without a stated autonomous disposition [integration]

### Write integration tests for Autonomous Epic Generation
**Task**: 4.1
**Description**: The six-site assertion lives here rather than in Story 1 because five sites are Story 1's and the sixth is Story 2's — "all six" is only true once both land. Take the inventory of gate sites first and assert each by name, which turns the must-NOT into arithmetic rather than judgement (retro 22).
**Status**: Pending

---

## Notes

**Why the six-site criterion is on the integration story.** Splitting it across Stories 1 and 2 would let each pass while the set stayed incomplete. Retro 22's finding — *"a rule inventory taken before the first edit turns a must-NOT into arithmetic"* — is the shape: enumerate the six sites up front, assert each carries a disposition, and a seventh gate added later fails the count until someone classifies it.

**`cpm:epics` has no autonomous handling today.** `grep -ic autonomous cpm/skills/epics/SKILL.md` returns **0**, against **17** in `cpm:do`. This epic builds the branch from scratch against 43-02's pattern rather than extending an existing one, which is why Story 1 comes before everything else in the epic.

**The Stale-Progress Check is not a seventh gate.** Its guard prints `SUPPRESS` when `.claude/ralph-loop.local.md` exists, so it is already autonomous-safe. The consequence — a cross-session relaunch never being told about a leftover progress file — is epic 45-04's Story 2, not this epic's.
