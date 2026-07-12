# Coverage Matrix: Foundation: Contract & Python Scaffolding

**Source spec**: docs/specifications/39-spec-cross-project-cpm-board.md
**Epic**: docs/epics/39-01-epic-foundation-contract-scaffolding.md
**Date**: 2026-07-11

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | Shared status contract | a `cpm/shared/status-model.md` document authored alongside the board, defining the state vocabulary and derivation rules so the board never drifts from `/cpm:status`. | `cpm/shared/status-model.md` defines the 7 states (`no-artifacts`, `spec-ready`, `epics-ready`, `in-progress`, `blocked`, `complete`, `unknown`) and the rule mapping epic `**Status**:` + story completion counts to each state | Story 1 | `[manual]` | ✓ |
| 2 | Shared status contract | defining the state vocabulary and derivation rules so the board never drifts from `/cpm:status`. | The document specifies how the recommended next command is chosen for each state, mirroring `/cpm:status`'s decision table | Story 1 | `[manual]` | ✓ |
| 3 | Portability | Runs with `uv` and `git` on PATH. Dependency footprint managed by `uv` (single-file PEP 723 script) so "clone and run" holds. | `cpm/tools/board/board.py` is a single-file PEP 723 script declaring Textual as an inline dependency, launched via `uv run` | Story 2 | `[manual]` | ✓ |
| 4 | Test Infrastructure | **pytest** as the runner. **Fixture project trees** — small fake repos with known `docs/` + git states, to drive derivation tests deterministically. **Textual Pilot** for the `[feature]` TUI test. | pytest is configured and runnable within `cpm/tools/board/`; a fixture factory builds temporary git repos with arbitrary `docs/` trees and commits; Textual Pilot is wired up so `[feature]` TUI tests can drive the app | Story 3 | `[unit]` / `[manual]` | ✓ |
