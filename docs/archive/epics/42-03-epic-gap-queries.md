# Gap Queries

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Date**: 2026-07-25
**Status**: Complete — delivered 2026-07-25, deleted 2026-07-26 with the join it queried. R3 and R4 are now questions the rewritten `/cpm:inspect` asks in prose rather than answers with a query; Story 2's *none found* vs *not answerable* distinction survives in that form. See the Retirement section of the source spec.
**Blocked by**: Epic 42-02-epic-intent-adapters-and-join
**Retro applied**: 20 · Testing Gaps · Applied — Story 2's suite exercises all three adapter exit codes against the answerability report, not only the two its criteria name; an erroring adapter must render as not-answerable, since retro 20 found exactly that conflation in `changeset_intent_answerable` and named R4 as the requirement it would defeat.
**Retro applied**: 20 · Testing Gaps · Applied — every absence assertion in this epic (empty orphan list, empty unbacked list, zero-adapter run) carries a positive control proving the fixture had something to report, so "none found" can never be satisfied by "nothing looked".
**Retro applied**: 20 · Criteria Gaps · Applied — Story 2's "no test naming it" admits at least three readings (header citation, filename convention, assertion text) that agree on a tidy CPM suite and diverge elsewhere; the fixture contains the case that separates them before the query is written.
**Retro applied**: 20 · Patterns Worth Reusing · Applied — each of the three story gates ends in an end-to-end read of the file it produced, with the answerability wording read hardest because R4's must-NOT is a rendering distinction that no assertion can check.

## Orphan changes
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R3
**Retro**: [Criteria gap] The story's two criteria are not equal partners, and a mutation check proved it: with the query changed to `orphan = not declared`, the assertion behind the positive criterion — "a file with a declared link is not an orphan" — still **passes**. Seven others fail. The whole discriminating power of this story sits in the must-NOT, and the only fixture file that separates the two readings is one carrying a lone derived link. Retro 20's lesson applied directly, and worth carrying: a positive criterion that names only the strongest case cannot rule out an implementation that handles only the strongest case. Separately, the gate read caught the header justifying AD3's data/labels split with a claim that does not hold — `absent` is the one label embedding no confidence judgement, so the honest argument is that the line is drawn at the stream and is worth more without a first exception.

**Acceptance Criteria**:

- A file with no adapter link appears in the orphan list; a file with a declared link does not [integration]
- must NOT list a file as an orphan when any active adapter resolves it [integration]

### Implement the orphan query
**Task**: 1.1
**Description**: Files in the change set with no link from any active adapter. Reads the join's data, not its labels — per AD3's split, the query must not depend on confidence values it cannot verify.
**Status**: Complete

### Write tests for orphan changes
**Task**: 1.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---

## Unbacked claims, with answerability
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: R4
**Decision**: "no test **naming** it" was settled at this story's gate as **any mention of the intent ID inside a test file**, matched case-insensitively, with one alternate spelling so `story 42-02.6` also matches the "Epic 42-02 Story 6" form CPM test headers use. The stricter header-only reading was rejected because it works only where that convention holds, and R9 requires this to run in repositories that have never heard of CPM. The cost is recorded and asserted: the chosen reading fails by **under-reporting**, so a passing mention in an unrelated comment backs a claim nothing tests. `test-gap-unbacked.sh` pins that case rather than leaving it as a footnote.
**Decision**: answerability rests on an **optional capability companion** to Epic 42-02's adapter contract — `<name>_link_capabilities` printing `criteria`. Absent means no capabilities, so every existing adapter keeps working and answers R4 with "not from me". This is an addition to the frozen contract, not a reopening of it: nothing an existing adapter does changes meaning.
**Retro**: [Testing gap] Retro 20's lesson paid twice here, and the second time against my own suite. Applying it produced the erroring-adapter test that no criterion asks for — mutating `exit 1` to count as an answer is caught by exactly that test and nothing else. But the must-NOT assertion itself was initially weak in the same way retro 20 describes: it compared the two empty states with *different* denominators (0 of 7 against 0 of 0), so they differed trivially and the assertion survived a mutation that collapsed the two states entirely. Holding the counts identical on both sides leaves answerability as the only thing that can make them read differently. An inequality that holds trivially is worth no more than an equality that does.

**Acceptance Criteria**:

- An intent record marked verified with no test naming it is listed as an unbacked claim [integration]
- must NOT report an empty unbacked list as "none found" when the active adapters cannot answer the query — "none found" and "not answerable" must render differently [integration]

**Note**: this story is separate from Story 1 because of the second criterion. Commit trailers and branch names record *why* a change happened; they never record *and here is the criterion it satisfies, marked verified*. R4 is therefore answerable only through an adapter carrying verification claims — in this iteration, the CPM adapter alone. If "no unbacked claims" renders identically to "I cannot answer that", the asymmetry becomes a silent lie in precisely the repositories where a reader would most trust the result.

### Implement the unbacked-claims query
**Task**: 2.1
**Description**: Intent records marked verified with no test naming them. Depends on Epic 42-02 Task 3.1, which is what makes intent records carry their criteria in the first place.
**Status**: Complete

### Implement answerability reporting
**Task**: 2.2
**Description**: Covers the must-NOT. Wording is deliberately left to execution — the criterion requires only that the two states render differently, and the decision is recorded here when made.
**Status**: Complete

### Write tests for unbacked claims
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---

## Degrade to zero adapters
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1, Story 2
**Satisfies**: R9
**Retro**: [Testing gap] The must-NOT found a real defect that every content assertion passed over. `[ -n "$x" ] && printf ...` as the last command of a `while` body makes the loop exit **1** when the list is empty — `printf '%s\n' ""` still emits a blank line, the guard fails on it, and the status propagates out through `gap_report`. So a review that correctly found nothing reported itself as having failed, which is exactly what "must NOT hard-fail when no adapter resolves anything" forbids. Every assertion about the review's *content* passed while it was broken; only the one asserting its exit code caught it. Worth carrying: in shell, "produces the right output" and "reports success" are independent claims, and a suite that only ever captures stdout will never notice the second.

**Acceptance Criteria**:

- A repository with no CPM artifacts and no trailers still produces a review, with every file reported as an orphan [integration]
- must NOT hard-fail when no adapter resolves anything [integration]

**Note**: this story doubles as the epic's cross-story verification. It exercises Stories 1 and 2 together under the zero-adapter condition, which is the only genuine cross-story interaction here — a separate integration story would restate it.

### Implement the zero-adapter degradation path
**Task**: 3.1
**Description**: Every file becomes an orphan and the run still completes. Consumes the zero-adapter configuration built in Epic 42-02 Task 1.3.
**Status**: Complete

### Write tests for degrading to zero adapters
**Task**: 3.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---
