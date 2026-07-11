# Foundation: Contract & Python Scaffolding

**Source spec**: docs/specifications/39-spec-cross-project-cpm-board.md
**Date**: 2026-07-11
**Status**: Complete
**Blocked by**: —
**Retro applied**: 05 · Testing gap · Applied — board tests assert on structural state (state enum, row identity) not brittle rendered substrings.
**Retro applied**: 06 · Testing gap · Not relevant here — board resolves paths via `__file__`/`uv run`, not the `${CLAUDE_PLUGIN_ROOT}` Bash token, so the unverified-plugin-root caveat doesn't bind it.

## Author the shared status-model contract [plan]
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Shared status contract

**Acceptance Criteria**:

- `cpm/shared/status-model.md` defines the 7 states (`no-artifacts`, `spec-ready`, `epics-ready`, `in-progress`, `blocked`, `complete`, `unknown`) and the rule mapping epic `**Status**:` + story completion counts to each state [manual] — documentation content review, no code oracle
- The document specifies how the recommended next command is chosen for each state, mirroring `/cpm:status`'s decision table [manual] — documentation content review, no code oracle

### Write state vocabulary and status→state mapping
**Task**: 1.1
**Description**: Covers the first criterion — enumerate the 7 states and the rule that maps an epic's `**Status**:` field plus story completion counts onto a state.
**Status**: Complete

### Write the recommended-next-command decision table
**Task**: 1.2
**Description**: Covers the second criterion — the per-state next-command logic, kept in lockstep with `/cpm:status` so the board and skill cannot diverge.
**Status**: Complete

**Retro**: [Criteria gap] The single "recommended next command" criterion missed that a repo can have multiple actionable next steps at once; the contract was extended mid-story to derive an ordered candidate list (primary + rest), which ripples into the 39-04/39-05 criteria.

---

## Scaffold the uv single-file Textual app
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: Runtime & UI framework (4.1), Portability

**Acceptance Criteria**:

- `cpm/tools/board/board.py` is a single-file PEP 723 script declaring Textual as an inline dependency, launched via `uv run` [manual] — verifies uv env provisioning in a real environment; no test harness for uv bootstrap yet
- The scaffold boots a minimal Textual app that quits on `q` [feature]

### Create the PEP 723 script with inline dependency metadata
**Task**: 2.1
**Description**: Establishes the `uv`-runnable single-file entry point with Textual pinned in inline metadata — the runtime foundation all later code builds on.
**Status**: Complete

### Build the minimal Textual App shell
**Task**: 2.2
**Description**: A do-nothing Textual `App` that mounts, renders an empty screen, and binds `q` to quit — the skeleton the TUI epics extend.
**Status**: Complete

### Write tests for the scaffold
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged [feature] — boot the shell under Textual Pilot and assert it quits on `q`.
**Status**: Complete

**Retro**: [Smooth delivery] The PEP 723 single-file + separate dev `pyproject.toml` split delivered a clean `uv run` app and `uv run pytest` harness first try; the scaffold feature test asserts on widget identity + return code per the retro-05 marker lesson.

---

## Set up pytest and fixture-repo infrastructure
**Story**: 3
**Status**: Complete
**Blocked by**: Story 2
**Satisfies**: Test Infrastructure

**Acceptance Criteria**:

- pytest is configured and runnable within `cpm/tools/board/` [manual] — verifies the runner boots in a real env
- A fixture factory builds temporary git repos with arbitrary `docs/` trees and commits, for deterministic derivation tests [unit]
- Textual Pilot is wired up so `[feature]` TUI tests can drive the app [manual] — verifies the Pilot harness in a real env

### Configure pytest for the tool
**Task**: 3.1
**Description**: Covers the first criterion — pytest config/layout so tests run from the tool directory.
**Status**: Complete

### Build the fixture-repo factory helper
**Task**: 3.2
**Description**: Covers the second criterion — a helper that materialises a temp git repo with a caller-specified `docs/` tree and commit state, the backbone of derivation tests.
**Status**: Complete

### Write tests for the fixture factory
**Task**: 3.3
**Description**: Write automated tests covering the story's acceptance criteria tagged [unit] — assert the factory produces repos with the requested docs/git state.
**Status**: Complete

**Retro**: [Smooth delivery] Fixture factory landed as a `make_project` factory fixture in conftest.py; 4 unit tests cover docs-tree writing, resolvable HEAD, commit-skip, and per-call isolation.

---
