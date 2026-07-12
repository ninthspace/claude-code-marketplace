# Status Derivation Engine

**Source spec**: docs/specifications/39-spec-cross-project-cpm-board.md
**Date**: 2026-07-11
**Status**: Complete
**Blocked by**: Epic 39-01-epic-foundation-contract-scaffolding
**Retro applied**: 07 · Pattern worth reusing · Applied — derivation tests use the `make_project` fixture factory for deterministic docs/git substrates.
**Retro applied**: 07 · Criteria gap · Applied — the engine computes the ordered multi-action candidate list (not a single command), per the pivoted contract.
**Retro applied**: 05 · Testing gap · Applied — tests assert on the state enum + structured `NextAction` fields, not rendered strings.

## Derive project state from docs and git
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Independent status derivation, Read-only guarantee

**Acceptance Criteria**:

- Given a project's `docs/` tree + git state, produces the correct state and story counts per `status-model.md` [unit]
- Board and `/cpm:status` agree on state for the same project (contract conformance) [integration]
- A full sweep performs no writes or git mutations in any tracked repo [integration]
- must NOT perform any write or git-mutating command against a tracked repo [integration]

### Parse epic docs for status and story counts
**Task**: 1.1
**Description**: Covers the derivation input — read a project's `docs/epics/` (and related artifacts) to extract each epic's `**Status**:` and story completion counts, read-only.
**Status**: Complete

### Map parsed artifacts to a state per the contract
**Task**: 1.2
**Description**: Applies the `status-model.md` mapping to produce the project's overall state — the conformance criterion's core logic.
**Status**: Complete

### Read git HEAD read-only
**Task**: 1.3
**Description**: Addresses the read-only guarantee and must-NOT clause — obtain `git rev-parse HEAD` and any needed git facts using inspection commands only, never mutating the repo.
**Status**: Complete

### Write tests for derivation and read-only guarantee
**Task**: 1.4
**Description**: Write automated tests covering the story's acceptance criteria tagged [unit] and [integration] — derivation correctness against fixtures, `/cpm:status` conformance, and assertion that a sweep mutates nothing.
**Status**: Complete

**Retro**: [Pattern worth reusing] Contract conformance was tested as a table-driven parametrized case (scenario→expected State) and read-only was proven by snapshotting HEAD + asserting `git status --porcelain` empty — both reusable across the remaining board epics.

---

## Compute the recommended next command
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Recommended next action

**Acceptance Criteria**:

- Emits the correct next command for each state (spec-ready→epics, epics-ready→do, in-progress→do that epic, etc.) [unit]

### Implement the next-command decision table
**Task**: 2.1
**Description**: Codifies the `status-model.md` recommended-next-command logic into the engine, producing the command string the launcher will use.
**Status**: Complete

### Write tests for the next-command logic
**Task**: 2.2
**Description**: Write automated tests covering the story's acceptance criteria tagged [unit] — assert the correct command for every state.
**Status**: Complete

**Retro**: [Pattern worth reusing] Per-epic classification reuses the project-level precedence (`_epic_state` mirrors `derive_state`), so the primary candidate can never contradict the overall RAG state — one precedence definition, two call sites.

---

## Graceful degradation of derivation
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Graceful degradation

**Acceptance Criteria**:

- Unreachable registry path → "unreachable" row; malformed/half-written artifact → `?` state [unit]
- must NOT abort the whole sweep because one project is bad [unit]

### Isolate per-project derivation
**Task**: 3.1
**Description**: Wrap each project's derivation so a failure is contained to that project — the must-NOT-abort guarantee.
**Status**: Complete

### Map failure modes to states
**Task**: 3.2
**Description**: Translate an unreachable path into "unreachable" and unparseable/half-written front-matter into `?`, rather than raising.
**Status**: Complete

### Write tests for degradation
**Task**: 3.3
**Description**: Write automated tests covering the story's acceptance criteria tagged [unit] — feed unreachable paths and malformed fixtures, assert states and that the sweep completes.
**Status**: Complete

---
