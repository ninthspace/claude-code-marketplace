# Intent Adapters and the Join

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Date**: 2026-07-25
**Status**: Complete — delivered 2026-07-25, deleted in full 2026-07-26. Both link adapters, the intent adapter, the link set, the join and the JSON record went with spec 42's architecture; this epic is the one whose premise failed, and the source spec's Retirement section says how.
**Blocked by**: Epic 42-01-epic-change-set-resolution
**Retro applied**: 20 · Testing Gaps · Applied — Story 1's conformance suite covers the adapter contract's whole surface rather than only the three story criteria; it ships as the harness Stories 2 and 3 run against, so a branch it omits is a branch no adapter is ever checked on.
**Retro applied**: 20 · Patterns Worth Reusing · Applied — precedence is resolved in one place both adapters feed rather than implemented per-adapter and compared, and JSON determinism comes from one canonical serialiser, so both properties are structural rather than agreements between two code paths.
**Retro applied**: 20 · Patterns Worth Reusing · Applied — each finished contract and schema is read end to end at its verification gate, Story 1's adapter contract and Story 5's JSON schema especially, since both are prose two later epics implement against and no assertion can check prose.
**Retro applied**: 19 · Testing Gaps · Applied — Story 5's byte-identical criterion compares two runs against each other rather than against a checked-in expected JSON blob, and link-set expectations are read back from the fixture recipe rather than pinned.

## Define the adapter contract [plan]
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R7, AD2
**Retro**: [Testing gap] A conformance harness is only worth having if passing it means the join will accept the adapter, and nothing asserted that: the harness filtered blank lines the join rejects, so it would have certified an adapter that fails at runtime. Found by reading the two files against each other at the gate, not by any of the ten positive controls — each proved its own check discriminates, none compared the harness's verdict to the join's.

**Acceptance Criteria**:

- Each adapter implements one contract: given a change set, return a link set [integration]
- A conformance suite exercises the contract, and any adapter must pass it [integration]
- must NOT require any adapter to be present — zero active adapters is a valid configuration [integration]

**Note**: `[plan]` because this fixes the pluggable seam AD2 depends on. The deferred issue-tracker adapters (Jira, GitHub, Linear) must be addable against this contract without reopening it, so the design needs upfront agreement rather than emerging from the first two implementations.

### Define the adapter interface
**Task**: 1.1
**Description**: The contract shape — given a change set, return a link set. Consumes the resolution interface defined in Epic 42-01 Story 3.
**Status**: Complete

### Build the adapter conformance suite
**Task**: 1.2
**Description**: The reusable harness every adapter must pass. Distinct from Task 1.4 — this ships as a testing asset that Stories 2 and 3 run their adapters against, rather than verifying this story's own criteria.
**Status**: Complete

### Implement the zero-adapter path
**Task**: 1.3
**Description**: Covers the must-NOT — no adapter present is a valid configuration, not an error. This is the mechanism R9's degradation requirement relies on in Epic 42-03.
**Status**: Complete

### Write tests for defining the adapter contract
**Task**: 1.4
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---

## Build the git-native adapter
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: R7, R2 (reverse direction), AD2
**Retro**: [Criteria gap] Story 4's criteria govern *links* — "every resolved link carries exactly one of declared / derived / absent" — and say nothing about INTENT records, but two adapters will emit an INTENT record for the same ID with different status and title (git knows neither, so it emits `unknown` and uses the ID as the title; the CPM adapter knows both). Reconciling those is a precedence question with no criterion behind it, surfaced here rather than at Story 4's gate.

**Acceptance Criteria**:

- Commit trailers (`Refs:`, `Closes:`) resolve a changed file to an intent record [integration]
- Conventional-commit subjects (`fix(scope):`) resolve a changed file to an intent record [integration]
- Branch names (`feature/AUTH-123`) resolve a changed file to an intent record [integration]
- The adapter works in any repository with no configuration [integration]

### Parse commit trailers and conventional-commit subjects
**Task**: 2.1
**Description**: `Refs:`, `Closes:`, `fix(scope):`. Runs against the conformance suite built in Task 1.2.
**Status**: Complete

### Parse branch names
**Task**: 2.2
**Description**: `feature/AUTH-123`. Separated from Task 2.1 because branch signal is lost after a squash merge and needs its own handling and its own honest limits.
**Status**: Complete

### Write tests for the git-native adapter
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---

## Build the CPM adapter
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: R7, R2 (reverse direction), AD2
**Retro**: [Pattern worth reusing] The criteria name epic docs and coverage matrices together as inputs but say nothing about how a coverage matrix that is *itself in the change set* should be labelled, and the first implementation let it fall through to co-commit — a planning artifact filed as ordinary evidence. An assertion listing the full expected set of derived links caught it, where a `grep -q` for the one file under test would have passed; enumerating the whole result is what made the extra member visible.

**Acceptance Criteria**:

- Epic docs, `**Satisfies**` fields and coverage matrices resolve to intent records carrying their criteria [integration]
- Co-commit links a changed file to an intent record when both land in one commit [integration]
- must NOT infer a link from a time window [integration]

### Parse epic docs, Satisfies fields and coverage matrices
**Task**: 3.1
**Description**: Produces intent records that carry their acceptance criteria — this is what makes R4's unbacked-claims query answerable in Epic 42-03, and why that query is CPM-adapter-only.
**Status**: Complete

### Implement co-commit linking
**Task**: 3.2
**Description**: The strongest derived signal, and the one that works because CPM updates planning documents in the same working tree as the code. Also covers the must-NOT forbidding time-window inference.
**Status**: Complete

### Write tests for the CPM adapter
**Task**: 3.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---

## Confidence labelling and precedence
**Story**: 4
**Status**: Complete
**Blocked by**: Story 2, Story 3
**Satisfies**: R7
**Retro**: [Criteria gap] "Every resolved link carries exactly one of declared / derived / absent" reads as one vocabulary over one thing, and it is not: declared and derived describe a *link*, while absent describes a *file* that has none — no adapter can even claim it, since none knows what the others found. Implementing it literally would have meant a LINK record with no intent to point at. Labels are therefore computed per file by the join, which is also the granularity R3's orphan query needs. Story 2's fixture turned out to already contain a contested pair (branch `bugfix/TICKET-7` derived against trailer `Refs: TICKET-7` declared), so precedence landing broke a green Story 2 assertion — the collapse was correct and the older expectation was stale.

**Acceptance Criteria**:

- Every resolved link carries exactly one of declared / derived / absent [unit]
- A declared marker always wins over a derived one for the same (file, intent) pair [unit]
- must NOT label a derived link as declared under any adapter combination [unit]

**Note**: there is no oracle for whether a derived link is *true* — "epic 41-03 owns this file" cannot be verified by a test. Confidence integrity is therefore a **precedence property**, not a correctness property, and these criteria assert only what is actually assertable.

### Implement label assignment
**Task**: 4.1
**Description**: declared / derived / absent, exactly one per link. Covers the first criterion.
**Status**: Complete

### Implement precedence resolution
**Task**: 4.2
**Description**: Declared beats derived for the same (file, intent) pair. Story 6 then tests this property *across* adapters; this task establishes it within one.
**Status**: Complete

### Write tests for confidence labelling and precedence
**Task**: 4.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---

## Emit the deterministic JSON record [plan]
**Story**: 5
**Status**: Complete
**Blocked by**: Story 4
**Satisfies**: R6, AD3, AD4
**Retro**: [Complexity underestimate] Running the finished record against this repository's own last three commits produced **1,405 links for 58 files** — co-commit multiplies every file in a commit by every intent in every epic doc that commit touched, and CPM commits routinely carry several epic docs. AD2 states the *granularity* consequence ("chain-level provenance there, not epic-level") but not the *volume* one, and Epic 42-05's page has to render this. Also: the end-to-end read caught the header claiming every array is sorted `LC_ALL=C` when `changeset.commits` deliberately keeps rev-list order — the prose was wrong, not the code, and no assertion covered either reading until one was added.

**Acceptance Criteria**:

- Two runs against the same repository state produce byte-identical JSON [integration]
- The emitted document is valid JSON [unit]
- The record is written to `docs/inspect/` in the repository, not to a scratch or published location [integration]

**Note**: `[plan]` because the schema is the contract Epic 42-04's review and Epic 42-05's artifact both read. Changing it later costs edits in two downstream epics.

### Define the JSON schema
**Task**: 5.1
**Description**: The contract two later epics consume. Scope is the schema; serialisation is Task 5.2.
**Status**: Complete

### Implement deterministic serialisation to docs/inspect/
**Task**: 5.2
**Description**: Byte-identical across runs is the criterion; stable key ordering and stable collection ordering are what deliver it. Determinism is what makes the record auditable and the deferred delta-between-runs feature possible.
**Status**: Complete

### Write tests for the deterministic JSON record
**Task**: 5.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---

## Verify cross-adapter integration
**Story**: 6
**Status**: Complete
**Blocked by**: Story 1, Story 2, Story 3, Story 4, Story 5
**Satisfies**: R7 (cross-adapter behaviour)
**Retro**: [Criteria gap] The third criterion — "Disabling one adapter changes which links are present but never their labels" — is unsatisfiable by any correct implementation, and Story 4 is why: if a declared marker always wins for a (file, intent) pair, then whether that pair reads declared depends on whether the adapter carrying the declaration is registered. The fixture shows it in both directions. Verified instead as the two properties it was reaching for — an adapter's own triples never depend on which peers are registered, and removing an adapter only ever removes or weakens, never strengthens or invents. Separately, the first draft's `join_with` helper registered adapters inside a command substitution, so both byte-identity tests compared two documents with an empty `adapters` array and agreed for the wrong reason; the fix was to split registration from the join, and the assertion that caught it was the one naming the expected adapters rather than either identity test.

**Acceptance Criteria**:

- With both adapters active, a file resolved by each yields one link set with precedence applied across adapters, not within one [integration]
- JSON output is byte-identical across runs with both adapters active [integration]
- Disabling one adapter changes which links are present but never their labels [integration]

**Note**: this story exists because precedence is the one property every other story can pass individually while the system still gets it wrong. Stories 2 and 3 each test their own adapter; neither reaches the case where both resolve the same file, and that handoff is where the defect would live.

### Write integration tests for cross-adapter behaviour
**Task**: 6.1
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---
