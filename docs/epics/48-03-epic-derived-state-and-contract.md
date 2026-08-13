# Row-Derived State and the Status-Model Contract

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Date**: 2026-08-13  
**Status**: Pending  
**Blocked by**: 48-02  
**Retro applied**: 42 · Criteria gaps · Applied — FR5's *in progress* criterion is green on a derivation that answers "in progress" for every epic, so Story 1 carries the two decoy cases (all complete, none complete) that make the same derivation discriminate.  
**Retro applied**: 42 · Criteria gaps · Applied — FR9's ordering criterion is green on a comparator that never sorts, if the fixture holds one kind of candidate; Story 3's must-NOT names that fixture explicitly rather than trusting the happy-path one to contain all three.  
**Retro applied**: 42 · Patterns worth reusing · Applied — the contract's two consumers are reconciled separately (Story 4 for the board, Story 5 for `dpm:status`), because a single "they agree" check would be satisfied by two consumers that are both wrong in the same way.  
**Retro applied**: 42 · Codebase discoveries · Applied — the readiness rule is dpm's own `readyClause` over `dependency` filtered by `gates_work`, read from the schema rather than restated; a rule transcribed into the contract from memory is a third implementation, not a source of truth.

dpm holds the answers CPM's board infers. A blocked epic names its blocker from a row rather than
having one guessed from a `**Blocked by**` line. This epic is where that becomes true — the derivation
itself, and the written contract that keeps the board and `/dpm:status` from drifting into two answers
about what a project's state is.

## Derive readiness and blocking from rows
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR5

**Acceptance Criteria**:

- An epic held by an incomplete blocker renders blocked and names that blocker [tdd] [integration]
- An epic with some stories complete and some pending renders in progress, though no row carries that value [tdd] [unit]
- An epic with every story complete does not render in progress, and neither does one with no story complete — the three cases are distinguished by the same derivation [tdd] [unit]
- Readiness comes from `list_epic` and `list_story` with `ready`, and blockers from `list_dependency` filtered by `gates_work` — asserted from the calls made, not from an equivalent locally computed answer [integration]
- must NOT treat a `superseded` or `withdrawn` blocker as satisfying the edge it holds [tdd] [unit]

### Readiness from the `ready` filter
**Task**: 1.1  
**Description**: `list_epic` and `list_story` with `ready`, which applies dpm's own `readyClause`. The board asks the question rather than answering it — a locally recomputed readiness is a second implementation of a rule that already exists, and it drifts silently the first time `readyClause` changes.  
**Status**: Pending

### Name the blocker from `list_dependency`
**Task**: 1.2  
**Description**: Filtered by `gates_work`. This is the whole difference from CPM's board, which infers a blocker from prose: here the edge is a row and the blocker has a name because it has an id.  
**Status**: Pending

### Derive *in progress*
**Task**: 1.3  
**Description**: `[tdd]` per the spec's tag. dpm's status enum has no such value, so the derivation is the board's — some stories complete, some pending. The failing test written first is the three-case one: all complete, none complete, and mixed, all through the same function.  
**Status**: Pending

### The retired-blocker rule
**Task**: 1.4  
**Description**: `superseded` and `withdrawn` retire an epic without satisfying anything that waits on it. A dependent left waiting on a withdrawn blocker is stuck and should read as stuck; treating retirement as completion is what would silently release it.  
**Status**: Pending

### Write tests for Story 1
**Task**: 1.5  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[tdd] [integration]`, `[tdd] [unit]`, `[integration]` and `[unit]`. The call-provenance criterion is asserted from a transcript — the `ready` filter appearing in the request — because a board that computed the same answer locally produces identical output.  
**Status**: Pending

---

## Story progress counts
**Story**: 2  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR6

**Acceptance Criteria**:

- Per-project and per-epic done-over-total counts equal the story rows the tools return [tdd] [unit]
- An epic with no stories reports no progress rather than 0/0 rendered as complete [unit]

### Per-epic done over total
**Task**: 2.1  
**Description**: Counted from story rows, per FR6. `[tdd]` per the spec's tag on this criterion.  
**Status**: Pending

### Per-project roll-up
**Task**: 2.2  
**Description**: Across the project's epics. Separate from 2.1 because the roll-up's edge cases are its own — an epic with no stories, and a project with no epics, both of which have a plausible-looking wrong answer.  
**Status**: Pending

### Write tests for Story 2
**Task**: 2.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[tdd] [unit]` and `[unit]`. The empty case is the one worth writing first: 0/0 is arithmetically complete and is the answer a naive implementation gives.  
**Status**: Pending

---

## Candidate next actions, ordered
**Story**: 3  
**Status**: Pending  
**Blocked by**: Story 1, Story 2  
**Satisfies**: FR9

**Acceptance Criteria**:

- Candidates order as ready epics, then specs with no epics, then complete epics with no retro [tdd] [unit]
- must NOT offer a retro candidate for an epic carrying a recorded retro waiver [unit]
- must NOT — the ordering is asserted over a fixture containing only one of the three kinds, so a comparator that never sorts reads as correct [unit]

### The three candidate kinds
**Task**: 3.1  
**Description**: Ready epics, specs with no epics, complete epics with neither a retro nor a waiver. Each is a query over rows; the ordering between them is FR9's requirement and the part a fixture can accidentally not test.  
**Status**: Pending

### Exclude waived epics from retro candidates
**Task**: 3.2  
**Description**: A recorded waiver is a decision already taken. Offering the epic again is how a board trains its user to ignore it.  
**Status**: Pending

### Write tests for Story 3
**Task**: 3.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[tdd] [unit]` and `[unit]`. The fixture holds all three kinds, and holds more than one of each — an ordering over three singletons is satisfied by six comparators of which one is correct.  
**Status**: Pending

---

## The derivation contract at `dpm/shared/status-model.md`
**Story**: 4  
**Status**: Pending  
**Blocked by**: Story 1, Story 2, Story 3  
**Satisfies**: AD5

**Acceptance Criteria**:

- The contract states each derivation rule in rows and tool calls: readiness, blocking, the retired-blocker rule, *in progress*, progress counts, and candidate ordering [unit]
- Every rule the board implements appears in the contract and every rule the contract states is implemented, reconciled by name so a rule present in one and absent from the other fails [unit]
- must NOT — the reconciliation passes over an empty rule set on either side [unit]

### Write the contract
**Task**: 4.1  
**Description**: Expressed in rows and tool calls, per AD5 — not in narrative. `cpm/shared/status-model.md` is the shape; the content is dpm's, and where a rule already exists in the schema (`readyClause`, the status enum) the contract points at it rather than restating it.  
**Status**: Pending

### Make the board's rules enumerable
**Task**: 4.2  
**Description**: Named derivation functions collected into a set, so Task 4.3 reconciles a derived enumeration rather than a transcribed one. A hand-maintained list of rules would agree with the contract while disagreeing with the code — the same failure NFR5 guards against one layer down.  
**Status**: Pending

### Reconcile both directions, with a floor
**Task**: 4.3  
**Description**: A rule in the code and not the contract, and a rule in the contract and not the code, each fail. The floor is what stops two empty sets agreeing perfectly.  
**Status**: Pending

### Write tests for Story 4
**Task**: 4.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`. The floor is checked on planted inputs — once the reconciliation passes, the live sets can no longer distinguish a working check from a vacuous one.  
**Status**: Pending

---

## Reconcile `dpm:status` against the contract
**Story**: 5  
**Status**: Pending  
**Blocked by**: Story 4  
**Satisfies**: AD5

**Acceptance Criteria**:

- Every contract rule carries a disposition in the reconciliation record — conformed, amended in the skill, or deliberately left alone with its reason — and a rule with no disposition fails [unit]
- Each `dpm:status` passage amended is amended only where it contradicts the contract, and the record names the contradiction [unit]

### Read `dpm:status` against each rule
**Task**: 5.1  
**Description**: Rule by rule, not passage by passage. Walking the skill and looking for disagreements finds the ones written down; walking the contract finds the ones the skill is silent about, which is the more common kind of divergence.  
**Status**: Pending

### Amend the contradictions
**Task**: 5.2  
**Description**: Bounded per the spec's Scope: only where the skill contradicts the contract. Rewriting `dpm:status`'s narrative, artifact or coverage-rollup behaviour is out of scope and stays out.  
**Status**: Pending

### Record every disposition, including the deliberate omissions
**Task**: 5.3  
**Description**: What was left alone, and why, is the half that would otherwise be lost — an unamended passage and an unexamined one look identical afterwards.  
**Status**: Pending

### Write tests for Story 5
**Task**: 5.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`. The disposition check reads the contract's rule set and the record together, so a rule added to the contract later fails until it is dispositioned.  
**Status**: Pending

---

## Notes

**Why the contract lands at Story 4 rather than first.** AD5 makes the contract the source of truth,
which reads like an argument for writing it before any derivation exists. Its rules are dpm's own —
`readyClause` over `dependency` filtered by `gates_work`, the status enum's values, the two derived
values the enum does not carry — so writing it after Stories 1–3 is transcription of facts that already
hold rather than invention. What prevents the drift AD5 exists to prevent is the two-way reconciliation
in Story 4 and the dispositions in Story 5, and neither depends on write order. A contract written first
and never reconciled would drift on the first change to `readyClause`.

**Story 4's second criterion is not a test that transcribes its source.** The obvious way to verify a
written contract is to assert that a document says what it says, which tests the transcription. The
criterion here reconciles two independently derived enumerations — the board's named derivation
functions and the contract's stated rules — so it fails when either side moves without the other. The
floor in the third criterion is what keeps that from degenerating into two empty sets agreeing.

**Step 3c — integration testing story: skipped, because Stories 4 and 5 are it.** The spec names
*Contract ↔ its two consumers* as an integration boundary and says "the reconciliation pass is where a
disagreement surfaces". That pass is Story 5, and it is the cross-consumer story a separate integration
story would otherwise be. The other seam this epic touches — Board ↔ MCP server — is covered by 48-02's
Story 6; Story 1's provenance criterion drives the real tools over it again for the derivation
specifically, which is where a locally recomputed answer would hide.

**Story 1's third criterion is added.** FR5's *in progress* criterion is satisfied by a derivation that
answers "in progress" unconditionally, because the requirement names only the mixed case. The two decoy
cases are what force the same derivation to distinguish all three, and they cost nothing to assert
alongside the one the spec names.

**FR9's third criterion is added for the same class of reason.** An ordering assertion over a fixture
holding one candidate of each kind is satisfied by several wrong comparators, and one holding a single
kind is satisfied by a comparator that does not sort at all. The must-NOT names the fixture rather than
the code, because that is where this particular false pass comes from.
