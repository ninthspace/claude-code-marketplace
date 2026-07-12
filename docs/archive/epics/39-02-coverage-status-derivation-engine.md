# Coverage Matrix: Status Derivation Engine

**Source spec**: docs/specifications/39-spec-cross-project-cpm-board.md
**Epic**: docs/epics/39-02-epic-status-derivation-engine.md
**Date**: 2026-07-11

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | Independent status derivation | read each project's `docs/` + git directly to compute state per the shared status contract; zero Claude/skill invocation. | Given a project's `docs/` tree + git state, produces the correct state and story counts per `status-model.md` | Story 1 | `[unit]` | ✓ |
| 2 | Independent status derivation (contract conformance) | so the board never drifts from `/cpm:status`. | Board and `/cpm:status` agree on state for the same project (contract conformance) | Story 1 | `[integration]` | ✓ |
| 3 | Reliability / Correctness | Strictly read-only against every tracked repo: no writes, no git mutations, no lock contention with an active session running in that repo. | A full sweep performs no writes or git mutations in any tracked repo; must NOT perform any write or git-mutating command against a tracked repo | Story 1 | `[integration]` | ✓ |
| 4 | Recommended next action (roll-up) | one row per project: name, overall state, story progress (e.g. 4/7), recommended next action. | Emits the correct next command for each state (spec-ready→epics, epics-ready→do, in-progress→do that epic, etc.) | Story 2 | `[unit]` | ✓ |
| 5 | Graceful degradation | unreachable registry path → "unreachable" row; unparseable/half-written artifact → `?` state. One bad project never aborts the sweep. | Unreachable registry path → "unreachable" row; malformed/half-written artifact → `?` state; must NOT abort the whole sweep because one project is bad | Story 3 | `[unit]` | ✓ |
