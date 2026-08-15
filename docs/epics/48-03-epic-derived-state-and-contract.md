# Row-Derived State and the Status-Model Contract

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Date**: 2026-08-13  
**Status**: Complete  
**Blocked by**: 48-02  
**Retro applied**: 42 · Criteria gaps · Applied — FR5's *in progress* criterion is green on a derivation that answers "in progress" for every epic, so Story 1 carries the two decoy cases (all complete, none complete) that make the same derivation discriminate.  
**Retro applied**: 42 · Criteria gaps · Applied — FR9's ordering criterion is green on a comparator that never sorts, if the fixture holds one kind of candidate; Story 3's must-NOT names that fixture explicitly rather than trusting the happy-path one to contain all three.  
**Retro applied**: 42 · Patterns worth reusing · Applied — the contract's two consumers are reconciled separately (Story 4 for the board, Story 5 for `dpm:status`), because a single "they agree" check would be satisfied by two consumers that are both wrong in the same way.  
**Retro applied**: 42 · Codebase discoveries · Applied — the readiness rule is dpm's own `readyClause` over `dependency` filtered by `gates_work`, read from the schema rather than restated; a rule transcribed into the contract from memory is a third implementation, not a source of truth.  
**Retro applied**: 48 · Patterns worth reusing · Applied — Story 1's provenance criterion is asserted from the recording stand-in's transcript, the `ready` filter and `gates_work` appearing in the recorded `tools/call` arguments, because a board that recomputed readiness locally produces identical output.  
**Retro applied**: 48 · Patterns worth reusing · Applied — the new fixtures this epic needs (a `gates_work` edge, a retired blocker, an epic with no stories, a recorded waiver) are built by calling the server's own create/link tools in `tests/support/fixture_database.py`, never by writing SQL against dpm's schema.  
**Retro applied**: 40 · Patterns worth reusing · Applied — Story 4's two-way reconciliation returns a complaint list, the shape `reconcile()` already has in `mcp_client.py`, so Task 4.4's floor and must-NOT drive the real reconciliation on planted rule sets rather than restating its rules in the test.  
**Retro applied**: 40 · Testing gaps · Applied — the contract's rule set is parsed out of `dpm/shared/status-model.md` and a parse matching nothing passes every per-rule check, so each extraction carries a planted control that must complain and the parsed count is asserted against the code's enumerated count.  
**Retro applied**: 39 · Codebase discoveries · Applied — Task 4.2's enumeration is derived from the board's named derivation functions at runtime rather than hand-kept, and Story 5's dispositions reconcile against the contract's parsed rules rather than a copy pasted into the record.  
**Retro applied**: 39 · Testing gaps · Applied — each test in Stories 1–3 names its wrong answer first (an unconditional *in progress*, a comparator that never sorts, 0/0 read as complete, a retired blocker treated as satisfied) and the fixture is built so each returns something visibly different.

dpm holds the answers CPM's board infers. A blocked epic names its blocker from a row rather than
having one guessed from a `**Blocked by**` line. This epic is where that becomes true — the derivation
itself, and the written contract that keeps the board and `/dpm:status` from drifting into two answers
about what a project's state is.

## Derive readiness and blocking from rows
**Story**: 1  
**Status**: Complete  
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
**Status**: Complete  
**Retro**: New `status_model.py` (AD2's module list). The declared read surface moved here from `board.py` and is now declared once per tool name — `SURFACE` is keyed on the name, so two `declare("list_epic", …)` calls in two modules leave whichever imported last, and the reconciliation would then check a set that depends on import order.

### Name the blocker from `list_dependency`
**Task**: 1.2  
**Description**: Filtered by `gates_work`. This is the whole difference from CPM's board, which infers a blocker from prose: here the edge is a row and the blocker has a name because it has an id.  
**Status**: Complete  
**Retro**: `list_dependency_kind` hides retired kinds unless asked, and `readyClause` mentions `retired_at` nowhere — a retired edge kind still gates, because retirement stops new edges arriving rather than releasing the work existing ones hold. So the board passes `include_retired`, which is the one place this read departs from a tool's default; without it the board would find an edge whose kind it had never heard of and call an epic workable that dpm says is blocked.

### Derive *in progress*
**Task**: 1.3  
**Description**: `[tdd]` per the spec's tag. dpm's status enum has no such value, so the derivation is the board's — some stories complete, some pending. The failing test written first is the three-case one: all complete, none complete, and mixed, all through the same function.  
**Status**: Complete  
**Retro**: Written red first, and the shape the three cases force is two counts (`0 < done < len`) rather than a check for one completed story. `epic_state` carries the precedence that makes the answer single-valued — complete, retired keeping its own word, blocked, in progress, then dpm's readiness — with blocked above in progress because the question a state answers is "can this be picked up".

### The retired-blocker rule
**Task**: 1.4  
**Description**: `superseded` and `withdrawn` retire an epic without satisfying anything that waits on it. A dependent left waiting on a withdrawn blocker is stuck and should read as stuck; treating retirement as completion is what would silently release it.  
**Status**: Complete  
**Retro**: The rule is `still_gates(status)` — dpm's `blocker.status <> 'complete'` in one named function rather than a condition inside the loop, so the contract has something to point at and the must-NOT has one thing to mutate. Its mirror image (a *retired row* is not offered as workable either) belongs to `readyClause` and is taken from the `ready` filter, never restated.

### Write tests for Story 1
**Task**: 1.5  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[tdd] [integration]`, `[tdd] [unit]`, `[integration]` and `[unit]`. The call-provenance criterion is asserted from a transcript — the `ready` filter appearing in the request — because a board that computed the same answer locally produces identical output.  
**Status**: Complete  
**Retro**: `tests/test_status_model.py`, 10 tests, suite 79. The fixture gained a third epic, a `blocks` edge and — the part that earns its keep — a `builds_on` edge from an *incomplete* epic into the one that must stay ready, so a board filtering edges by anything other than `gates_work` reports this project's only workable epic as blocked. Two existing assertions that had transcribed the fixture's shape (`"2 epics, 2 stories, 2 tasks"`, a literal list of epic titles) now read it from `CONTENT`, which is data for exactly this reason. Four mutations, all caught and each naming the harm: readiness recomputed locally, gating kinds hardcoded to `{"blocks"}`, `include_retired` dropped, and the kind filter dropped from `blockers()`.

---

## Story progress counts
**Story**: 2  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR6

**Acceptance Criteria**:

- Per-project and per-epic done-over-total counts equal the story rows the tools return [tdd] [unit]
- An epic with no stories reports no progress rather than 0/0 rendered as complete [unit]

### Per-epic done over total
**Task**: 2.1  
**Description**: Counted from story rows, per FR6. `[tdd]` per the spec's tag on this criterion.  
**Status**: Complete  
**Retro**: `progress()` returns `None` rather than `Progress(0, 0)` for an epic with no stories, which is what keeps the empty case from being rendered by arithmetic that is correct: `done == total` holds of 0/0, "every story is done" is vacuously true of it, and the caller is now forced to say what it shows instead.

### Per-project roll-up
**Task**: 2.2  
**Description**: Across the project's epics. Separate from 2.1 because the roll-up's edge cases are its own — an epic with no stories, and a project with no epics, both of which have a plausible-looking wrong answer.  
**Status**: Complete  
**Retro**: The roll-up is the same function over the project's story rows rather than a sum of per-epic figures, and both edge cases then fall out of one rule. The reading that does not survive is averaging epic completion: it gives an epic with no stories a 100% of its own, so a project with one untouched epic and one empty one reads as half done. `by_epic()` groups on the `epic_id` every story row already carries, so one unscoped `list_story` answers for every epic — the per-epic scoped call would be a round trip to learn what the first answer already said.

### Write tests for Story 2
**Task**: 2.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[tdd] [unit]` and `[unit]`. The empty case is the one worth writing first: 0/0 is arithmetically complete and is the answer a naive implementation gives.  
**Status**: Complete  
**Retro**: `tests/test_progress.py`, 8 tests, suite 87. Three mutations: the empty case returning 0/0 was caught by two tests; `complete` rewritten as `total - done <= 0` is equivalent given the constructor and no case can distinguish it; and counting "not pending" as done **survived**, which was a missing corpus case rather than a missing assertion. The test written for it was framed as "a status the schema does not yet allow" — **and that framing was wrong**: `020-status-lifecycle.sql` widened `story` and `task` alongside `document`, so `story.status` already carries four values and a `withdrawn` story is a row that really occurs. Story 5 found it while reading the contract, corrected the test's premise, and the rule it pins (a retired story leaves the count) turned out to be a live defect in the board rather than a future one — suite now 11.

---

## Candidate next actions, ordered
**Story**: 3  
**Status**: Complete  
**Blocked by**: Story 1, Story 2  
**Satisfies**: FR9

**Acceptance Criteria**:

- Candidates order as ready epics, then specs with no epics, then complete epics with no retro [tdd] [unit]
- must NOT offer a retro candidate for an epic carrying a recorded retro waiver [unit]
- must NOT — the ordering is asserted over a fixture containing only one of the three kinds, so a comparator that never sorts reads as correct [unit]

### The three candidate kinds
**Task**: 3.1  
**Description**: Ready epics, specs with no epics, complete epics with neither a retro nor a waiver. Each is a query over rows; the ordering between them is FR9's requirement and the part a fixture can accidentally not test.  
**Status**: Complete  
**Retro**: The ordering lives in one tuple, `CANDIDATE_KINDS`, and `Candidate.rank` reads its index — but that was not enough on its own. The first version appended one kind at a time, which produced FR9's order *with the sort removed*: the mutation that deleted `sorted()` passed every test. Candidates are now emitted in row order, both epic kinds in one pass, so the sort is the only thing that orders anything and the assertion can see it. `numbering_of()` reads `number` or `sequence` because specs are root-numbered and epics child-numbered; reading one column orders one kind and piles the other at zero, where the id tiebreak makes it stable, plausible and wrong.

### Exclude waived epics from retro candidates
**Task**: 3.2  
**Description**: A recorded waiver is a decision already taken. Offering the epic again is how a board trains its user to ignore it.  
**Status**: Complete  
**Retro**: `waived()` tests `retro_waived_at` alone, though the schema pairs it with a reason — `015-retro-waiver.sql`'s CHECK makes both present or neither, so a second condition could never independently be false. The fixture's seventh epic (complete, no retro, waived) is the only row that distinguishes "has a retro" from "needs no retro", and it went red before the rule existed.

### Write tests for Story 3
**Task**: 3.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[tdd] [unit]` and `[unit]`. The fixture holds all three kinds, and holds more than one of each — an ordering over three singletons is satisfied by six comparators of which one is correct.  
**Status**: Complete  
**Retro**: `tests/test_candidates.py`, 4 tests, suite 91. The fixture grew to seven epics and three specs: two of each candidate kind, and a decoy for each — a spec that *has* epics, a complete epic that already has a retro, a complete epic whose retro was waived. The count assertion (`>= 2` per kind) is the must-NOT stated about the fixture rather than the code, so a later story narrowing the fixture fails here rather than quietly weakening the ordering test. Five mutations: four caught; the fifth — deleting `sorted()` — **survived** and was the criterion's own false pass reaching the code, fixed by making the emission order interleave the kinds.

---

## The derivation contract at `dpm/shared/status-model.md`
**Story**: 4  
**Status**: Complete  
**Blocked by**: Story 1, Story 2, Story 3  
**Satisfies**: AD5

**Acceptance Criteria**:

- The contract states each derivation rule in rows and tool calls: readiness, blocking, the retired-blocker rule, *in progress*, progress counts, and candidate ordering [unit]
- Every rule the board implements appears in the contract and every rule the contract states is implemented, reconciled by name so a rule present in one and absent from the other fails [unit]
- must NOT — the reconciliation passes over an empty rule set on either side [unit]

### Write the contract
**Task**: 4.1  
**Description**: Expressed in rows and tool calls, per AD5 — not in narrative. `cpm/shared/status-model.md` is the shape; the content is dpm's, and where a rule already exists in the schema (`readyClause`, the status enum) the contract points at it rather than restating it.  
**Status**: Complete  
**Retro**: `dpm/shared/status-model.md`. Two of CPM's sections have no dpm counterpart and their absence is the interesting part: there is no lead-token status parsing and no vocabulary linting, because `document.status` is a CHECK-constrained enum and a status outside it cannot be written. Where CPM's model *defines* readiness, this one points at `readyClause` and says why it is not restated.

### Make the board's rules enumerable
**Task**: 4.2  
**Description**: Named derivation functions collected into a set, so Task 4.3 reconciles a derived enumeration rather than a transcribed one. A hand-maintained list of rules would agree with the contract while disagreeing with the code — the same failure NFR5 guards against one layer down.  
**Status**: Complete  
**Retro**: A `@derivation("rule")` decorator filling `DERIVATIONS` at import — the same shape as `declare()` one layer down, and for the same reason. A rule maps to *several* functions (readiness is asked twice, once per gated table), so the registry is name → list rather than name → function; that also makes "registered with no function behind it" a state the reconciliation can complain about.

### Reconcile both directions, with a floor
**Task**: 4.3  
**Description**: A rule in the code and not the contract, and a rule in the contract and not the code, each fail. The floor is what stops two empty sets agreeing perfectly.  
**Status**: Complete  
**Retro**: `tests/support/contract.py` — test support rather than a board module, because nothing at runtime reads the contract and a board module that opened a file would widen the surface FR2's sweeps bound. `reconcile_rules()` returns complaints, so the must-NOTs drive the real reconciliation on planted inputs. The parse is scoped to the *Derivation rules* section: an unscoped `###` sweep would read *Graceful degradation*'s three state names as rules nothing implements.

### Write tests for Story 4
**Task**: 4.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`. The floor is checked on planted inputs — once the reconciliation passes, the live sets can no longer distinguish a working check from a vacuous one.  
**Status**: Complete  
**Retro**: `tests/test_contract.py`, 10 tests, suite 101. Four mutations, all caught, and the floor one taught the lesson: with the *other* side populated, the per-rule loops complain anyway, so the two one-sided floor tests passed with the floor deleted. Only `reconcile_rules({}, [])` — nothing against nothing — is the case a set-difference cannot fail on, and it is now asserted in its bare form.

---

## Reconcile `dpm:status` against the contract
**Story**: 5  
**Status**: Complete  
**Blocked by**: Story 4  
**Satisfies**: AD5

**Acceptance Criteria**:

- Every contract rule carries a disposition in the reconciliation record — conformed, amended in the skill, or deliberately left alone with its reason — and a rule with no disposition fails [unit]
- Each `dpm:status` passage amended is amended only where it contradicts the contract, and the record names the contradiction [unit]

### Read `dpm:status` against each rule
**Task**: 5.1  
**Description**: Rule by rule, not passage by passage. Walking the skill and looking for disagreements finds the ones written down; walking the contract finds the ones the skill is silent about, which is the more common kind of divergence.  
**Status**: Complete  
**Retro**: Reading the contract at the skill found four contradictions, and **three of them were the board's, not the skill's** — the skill was right about retired stories leaving the count, right that a truncated read is a wrong count, and the board did neither. AD5's premise is that either consumer can be the one that drifted; walking passage-by-passage from the skill would have found only the fourth. The one genuinely skill-side pair was its recommendation ordering and its offering `/dpm:do` on an epic dpm does not report ready.

### Amend the contradictions
**Task**: 5.2  
**Description**: Bounded per the spec's Scope: only where the skill contradicts the contract. Rewriting `dpm:status`'s narrative, artifact or coverage-rollup behaviour is out of scope and stays out.  
**Status**: Complete  
**Retro**: Amendments landed in four places, only two of them the skill: the board gained `more`-paging and retired-story exclusion, the contract gained the four-value enum and the truncated-read paragraph, `test_progress.py` lost a test whose premise was factually wrong, and the skill gained a reordered recommendation table and a readiness paragraph. The skill edit then failed `reachability.test.js` — a bare `list_epic` in a table cell is not the name the harness dispatches. A corpus sweep already guarded the thing the amendment broke, which is the argument for running dpm's own suite after editing a skill, not only the board's.

### Record every disposition, including the deliberate omissions
**Task**: 5.3  
**Description**: What was left alone, and why, is the half that would otherwise be lost — an unamended passage and an unexamined one look identical afterwards.  
**Status**: Complete  
**Retro**: A new section in `docs/maintenance/README.md`, per CLAUDE.md's rule that maintenance records have one home and nothing runtime-facing names that path — dpm already keeps three records there. A disposition table with the contract's rule names as its first column, so the machine-checkable part is the *keys*; the prose in the cells is for the reader. The dispositions that carry the most are the ones that are not "amended in the skill": *blocking* records a bounded omission (`gates_work` is not read, so the skill can name an edge that holds nothing) and *retired blockers* records conformance the skill achieves by delegating to `readyClause` — real, invisible, and exactly the passage a later maintainer would "fix" by hand.

### Write tests for Story 5
**Task**: 5.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`. The disposition check reads the contract's rule set and the record together, so a rule added to the contract later fails until it is dispositioned.  
**Status**: Complete  
**Retro**: `tests/test_reconciliation.py`, 10 tests, suite 113. Five mutations; the ordering one survived and taught the lesson. The criterion-2 test searched the whole skill for `/dpm:do`, `/dpm:epics`, `/dpm:retro` — and the paragraph *above* the table names all three in the contract's order while explaining that the order is the contract's, so `find()` measured the sentence about the table and passed with the rows reversed. Fixed by parsing the table's rows. **A passage that states a rule sits next to the passage that obeys it, and a text search cannot tell them apart** — the same confusion, one layer up, that makes the skill's half of AD5 unmechanisable in the first place.

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
