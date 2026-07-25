# Change-Set Review

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Date**: 2026-07-25
**Status**: Complete — delivered 2026-07-25, deleted 2026-07-26. R5's findings half was withdrawn as `/cpm:audit`'s question asked over a narrower range. Story 2's disclosure discipline is the part that survives, carried into the rewritten skill as *Say what you did not read*. See the Retirement section of the source spec.
**Blocked by**: Epic 42-01-epic-change-set-resolution
**Retro applied**: 17 · Testing Gaps · Applied — every criterion here is structural, and none can tell whether a finding is any good; the suite header names what it does not test, so a green run cannot be mistaken for a verified review. The coverage matrix already records the same gap at row level.
**Retro applied**: 19 · Testing Gaps · Applied — Story 2's ordering and unexamined-file expectations are derived from the fixture at run time (the unexamined list asserted as the set complement of the examined one) rather than pinned as literals, which would be a snapshot wearing an invariant's clothes.
**Retro applied**: 20 · Criteria Gaps · Applied — Story 2's third criterion has two branches by construction, so both are run against the *same* fixture and the two orderings are asserted to differ; a fallback that quietly ignored the gap queries would otherwise pass both. "Overflows one pass" is an injectable budget rather than a hidden constant.
**Retro applied**: 17 · Patterns Worth Reusing · Applied — each story gate ends in an end-to-end read, AD3's boundary especially, since it is a prose rule no assertion can fully check. Retro 17's recommendation to fold this into `cpm:do`'s Step 4 rather than dispose of it per run is now outstanding across seven epics.

**Note on dependencies**: this epic is deliberately **not** blocked by Epic 42-02 or 42-03. R9 guarantees the review runs with zero adapters resolving anything, so it needs only the change-set structure from 42-01. Epics 42-02/03 and this epic are genuinely parallel. Story 2's third criterion specifies the fallback that makes this true in practice rather than only in principle.

## Produce findings over the change set
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R5, AD3
**Decision**: AD3 is enforced **by construction at the payload boundary**, not by a rule the review is asked to follow. `review_payload` rebuilds each link from fields 2 and 3 rather than reprinting the record, so a LINK gaining a fifth field later cannot carry anything through a path nobody re-read. The forbidden vocabulary lives in one variable, `REVIEW_FORBIDDEN_LABELS`, that both the builder and the test that polices it read — so they cannot drift by someone editing one list.
**Decision**: a criterion's `verified` state is **kept**, and is not a confidence label. AD3 excludes declared / derived / absent — the join's assessment of how well it knows something. `verified` is a claim the plan makes about itself, which is data about the work under review and the thing R4's whole query rests on. The two are easy to conflate and stripping the second would take away exactly what the review needs.
**Retro**: [Testing gap] Naming the untested surface in the suite header changed what got built, not just what got documented. Writing "a green run means the review was well *formed*, never that it was any good" made it obvious that the structural assertions were the whole deliverable, which is what pushed the validator toward asserting each *diagnostic* rather than merely that something was rejected — a validator that rejected everything passes a suite checking only exit codes. Separately, the `NF != 4` branch had no test, because no criterion mentions arity: a finding whose text contained a tab would have validated with the text silently truncated at the tab, leaving a citation attached to half a sentence.

**Acceptance Criteria**:

- Findings carry `file:line` citations [integration]
- The review consumes the join's data, never its confidence labels [integration]

### Implement the review pass over the change set
**Task**: 1.1
**Description**: Produces findings against the change-set structure from Epic 42-01, not against a path scope. This is the distinction from `/cpm:audit`, which orients on whole-codebase signals.
**Status**: Complete

### Enforce the data-not-labels boundary
**Task**: 1.2
**Description**: AD3's hard split. Verified here because this is the only place in the system where confidence labels could be consumed — the join produces them and nothing else reads them.
**Status**: Complete

### Write tests for producing findings
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---

## Disclose what was not examined
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: R5, NFR Behaviour at Scale
**Decision**: gap-query availability is **detected via `declare -f gap_orphans`**, not configured. A flag would be something a test sets and nothing else ever does; the function's presence is the same condition a real caller creates by sourcing — or not sourcing — `gap-queries.sh`, which is exactly the parallelism this epic's dependency note claims. The budget is likewise a parameter, never a constant: what fits in one pass depends on the model and the files, and a compiled-in number would be untestable besides, since a suite cannot construct a change set that overflows a limit it cannot name.
**Retro**: [Pattern worth reusing] Running both branches of the third criterion against the *same* fixture with the *same* budget is what made the criterion testable rather than merely visited, and a mutation confirmed it: a branch that reports `orphans-first` while resolving an empty orphan list produces the fallback order and is caught by four assertions, the decisive one being the direct comparison of the two orders. Tested in separate fixtures it would have passed both. The fixture detail that carries this is small and easy to lose — the orphans are the two files that sort *last*, so orphan priority and change-set order cannot coincide; had they sorted first, every comparison would have been vacuously green.

**Acceptance Criteria**:

- When the change set overflows one pass, the files not examined are listed explicitly [integration]
- must NOT present a partial review as complete [integration]
- When the gap queries are available, unexamined-file selection prioritises orphans first; when they are not, it falls back to a deterministic file order [integration]

**Note**: the third criterion is what lets this epic be built and verified end-to-end before Epic 42-03 exists. Without a specified fallback, "prioritised by provenance signal, orphans first" would make this story silently depend on the gap queries, and the parallelism claimed in the epic header would be false.

### Implement overflow detection and disclosure
**Task**: 2.1
**Description**: Covers the must-NOT. A review that silently samples reads as "clean" when it means "unexamined", which is worse than refusing — the disclosure is the whole point of the criterion.
**Status**: Complete

### Implement provenance-signal prioritisation with deterministic fallback
**Task**: 2.2
**Description**: The soft coupling to Epic 42-03, made explicit and testable. Orphans first when the gap queries are available; a deterministic file order when they are not.
**Status**: Complete

### Write tests for disclosure and prioritisation
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---
