# Coverage Matrix: Row-Derived State and the Status-Model Contract

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Epic**: docs/epics/48-03-epic-derived-state-and-contract.md  
**Date**: 2026-08-13

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR5 | "An epic held by an incomplete blocker renders blocked and names that blocker" | "An epic held by an incomplete blocker renders blocked and names that blocker" | Story 1 | `[tdd] [integration]` | |
| 2 | FR5 | "An epic with some stories complete and some pending renders in progress, though no row carries that value" | "An epic with some stories complete and some pending renders in progress, though no row carries that value" | Story 1 | `[tdd] [unit]` | |
| 3 | FR5 (added) | "*In progress* is derived — some stories complete, some pending — because dpm's status enum has no such value." | "An epic with every story complete does not render in progress, and neither does one with no story complete — the three cases are distinguished by the same derivation" | Story 1 | `[tdd] [unit]` | |
| 4 | FR5 (added) | "Readiness comes from `list_epic` and `list_story` with `ready`, which applies dpm's own `readyClause` over `dependency` filtered by `gates_work`." | "Readiness comes from `list_epic` and `list_story` with `ready`, and blockers from `list_dependency` filtered by `gates_work` — asserted from the calls made, not from an equivalent locally computed answer" | Story 1 | `[integration]` | |
| 5 | FR5 (must NOT) | "must NOT treat a `superseded` or `withdrawn` blocker as satisfying the edge it holds" | "must NOT treat a `superseded` or `withdrawn` blocker as satisfying the edge it holds" | Story 1 | `[tdd] [unit]` | |
| 6 | FR6 | "Per-project and per-epic done-over-total counts equal the story rows the tools return" | "Per-project and per-epic done-over-total counts equal the story rows the tools return" | Story 2 | `[tdd] [unit]` | |
| 7 | FR6 (added) | "Stories done over stories total, per project and per epic, counted from story rows." | "An epic with no stories reports no progress rather than 0/0 rendered as complete" | Story 2 | `[unit]` | |
| 8 | FR9 | "Candidates order as ready epics, then specs with no epics, then complete epics with no retro" | "Candidates order as ready epics, then specs with no epics, then complete epics with no retro" | Story 3 | `[tdd] [unit]` | |
| 9 | FR9 (must NOT) | "must NOT offer a retro candidate for an epic carrying a recorded retro waiver" | "must NOT offer a retro candidate for an epic carrying a recorded retro waiver" | Story 3 | `[unit]` | |
| 10 | FR9 (added, must NOT) | "Ready epics first, then specs with no epics, then complete epics with neither a retro nor a recorded waiver." | "must NOT — the ordering is asserted over a fixture containing only one of the three kinds, so a comparator that never sorts reads as correct" | Story 3 | `[unit]` | |
| 11 | AD5 | "a single written source of truth for how state, progress and next actions are derived, conformed to by the board (in code) and `/dpm:status` (in prose), expressed in rows and tool calls" | "The contract states each derivation rule in rows and tool calls: readiness, blocking, the retired-blocker rule, *in progress*, progress counts, and candidate ordering" | Story 4 | `[unit]` | |
| 12 | AD5 | "`cpm/shared/status-model.md` is why CPM's two consumers have never disagreed about what a project's state is, and dpm now has the same two consumers." | "Every rule the board implements appears in the contract and every rule the contract states is implemented, reconciled by name so a rule present in one and absent from the other fails" | Story 4 | `[unit]` | |
| 13 | AD5 (added, must NOT) | "no contract, with the board deriving alone (guarantees the two answers drift, and gives neither a place to record why)" | "must NOT — the reconciliation passes over an empty rule set on either side" | Story 4 | `[unit]` | |
| 14 | Scope (in scope) | "a bounded reconciliation pass against `dpm:status` that amends the skill only where it contradicts the contract and lists what it deliberately left alone" | "Every contract rule carries a disposition in the reconciliation record — conformed, amended in the skill, or deliberately left alone with its reason — and a rule with no disposition fails" | Story 5 | `[unit]` | |
| 15 | Scope (in scope) | "amends the skill only where it contradicts the contract" | "Each `dpm:status` passage amended is amended only where it contradicts the contract, and the record names the contradiction" | Story 5 | `[unit]` | |

## Notes

**Rows 2 and 3 are the requirement and its discriminator.** Row 2 is FR5's own wording and names only
the mixed case, so it is satisfied by a derivation that answers "in progress" unconditionally. Row 3
adds the two decoys — all complete, none complete — through the same derivation. Both are present
because dropping row 2 would edit the spec from an epic and dropping row 3 would leave the requirement
verifiable by a constant.

**Rows 8 and 10 are the same pair for FR9.** Row 8 asserts the ordering; row 10 forbids the fixture that
makes a non-sorting comparator pass it. The must-NOT is written against the fixture rather than the code
because that is where this false pass originates — the implementation can be correct and the assertion
still worthless.

**Row 4 is added, and it is the row that distinguishes this board from CPM's.** FR5 states that readiness
comes from dpm's `ready` filter and blockers from `list_dependency`, but its criteria assert only the
*answers*. A board that recomputed readiness locally produces identical output and identical passes, and
would then drift the first time `readyClause` changes — which is precisely the failure FR5's prose is
about. Asserted from the request transcript.

**Row 7 covers the case where the arithmetic is right and the answer is wrong.** 0/0 is complete by any
reading, and it is what a naive roll-up returns for an epic with no stories. FR6's own criterion is
satisfied by it, because zero rows equal zero rows.

**Rows 11–13 verify a written document without transcribing it.** Row 11 asserts the contract's coverage
of the six rules; row 12 reconciles two independently derived enumerations — the board's named derivation
functions against the contract's stated rules — so either side moving alone fails; row 13 is the floor
that keeps two empty sets from agreeing. A test asserting only that the document contains certain
sentences would test the transcription and nothing else.

**Rows 14 and 15 map to Scope rather than to a requirement,** because the reconciliation pass is scoped
there and has no `FRn` of its own. Row 14 is the one that makes an omission visible: an unamended passage
and an unexamined one are indistinguishable afterwards unless every rule carries a disposition.

**AD5's contract is verified here; its second consumer is verified here too.** There is no later epic that
re-checks `dpm:status` against the contract, so a change to either after this epic closes is caught by row
12's reconciliation for the board and row 14's dispositions for the skill — both of which run in the suite
rather than at review time.
