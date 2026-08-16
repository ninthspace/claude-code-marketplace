# Coverage Matrix: Read-Only Server Mode

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Epic**: docs/epics/48-01-epic-read-only-server-mode.md  
**Date**: 2026-08-13

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | NFR1 | "Non-mutation is a property of how the server is launched and which tool set it serves" | "With `DPM_READ_ONLY=1`, the server opens the connection with `readOnly: true`, skips `migrate` and `applyVocabulary`, and serves `readOnlyTools`" | Story 1 | `[integration]` | ✓ |
| 2 | NFR1 | "Non-mutation is a property of how the server is launched and which tool set it serves" | "The equivalent CLI flag produces the same mode as the environment variable, asserted on the same three observables" | Story 1 | `[integration]` | ✓ |
| 3 | NFR1 | "With the read-only mode active, a mutating tool call is refused by the server" | "With the read-only mode active, a mutating tool call is refused by the server" | Story 1 | `[integration]` | ✓ |
| 4 | NFR1 | "With the read-only mode active, opening a database at the current schema version runs no migration and writes no row" | "With the read-only mode active, opening a database at the current schema version runs no migration and writes no row" | Story 1 | `[integration]` | ✓ |
| 5 | NFR1 (added) | "so that a call site cannot violate it by forgetting" | "Opening a database whose schema is **behind** the server read-only leaves the file byte-identical and its `schema_version` unchanged, and the same open without the mode migrates it — the pair is what separates the mode from a database that needed nothing" | Story 1 | `[integration]` | ✓ |
| 6 | NFR1 (must NOT) | "so that a call site cannot violate it by forgetting" | "must NOT — the refusal comes from a check inside a tool handler rather than from the connection and the served tool set, so an ordinary launch could forget it" | Story 1 | `[integration]` | ✓ |
| 7 | ENVX2 | "dpm ships zero dependencies and must continue to." | "The read-only mode is implemented with `node:sqlite` alone, and dpm's `package.json` dependencies stay empty" | Story 1 | `[unit]` | ✓ |
| 8 | FR3 | "A server spawned read-only against a missing database refuses with `ERR_SQLITE_ERROR` and creates no file, driven as the sequence board code would perform: spawn, then call a read tool" | "A server spawned read-only against a missing database refuses with `ERR_SQLITE_ERROR` and creates no file, driven as the sequence board code would perform: spawn, then call a read tool" | Story 2 | `[integration]` | ✓ |
| 9 | FR3 (added) | "One server session per project, spawned only where a database already exists." | "The same spawn-then-call sequence **without** the read-only mode creates the file, so the absence is attributable to the mode rather than to anything else in the tree" | Story 2 | `[integration]` | ✓ |
| 10 | FR11 | "A missing `.dpm/dpm.db`, a schema version ahead of the server, a Node below dpm's floor, and a server that fails to start each render as a distinct named per-project state carrying its remedy." | "The refusal reaches the caller as a diagnostic naming the missing database path, not as an unhandled exit of the server process" | Story 2 | `[integration]` | ✓ |
| 11 | ENVX3 (must NOT) | "Must not require write access to any registered project, including creating `.dpm/dpm.db` in a project that has none." | "must NOT — the read-only path creates `.dpm/`, `.dpm/dpm.db`, or an ignore file in a project that has none" | Story 2 | `[integration]` | ✓ |

## Notes

**Rows 1, 2 and 6 share a fragment** — NFR1's *"how the server is launched and which tool set it serves
… so that a call site cannot violate it by forgetting"*. Each forbids a different way of failing it: a
mode that is not wired to the connection at all (1), a flag path that diverges from the env path (2), and
a mode implemented as a per-handler check that a call site can bypass (6). One ✓ across the three would
stand for a rule holding in one of them.

**Rows 4 and 5 are the spec's criterion and its discriminator.** Row 4 is NFR1's own wording, kept
verbatim; it is satisfied by any database that needed no migration, which is every database at the
current schema version. Row 5 is added by this epic and is the row that fails when the mode does not
work. Both are present because dropping row 4 would edit the spec from an epic, and dropping row 5 would
leave the requirement verifiable by a no-op. Flagged to Chris at the Step 3 gate; `/cpm:pivot` is where
row 4 would be repaired if it is to be repaired.

**Row 9 is the paired positive for row 8** — retro 42's observation applied to the criterion that
observation was written about. Row 8 asserts an absence; row 9 runs the identical sequence with the mode
off and asserts the file appears, so a flag that does nothing fails row 9 rather than passing row 8.
It discriminates under both landing orders because spec 49 defers creation to the first tool call rather
than removing it, and this sequence includes a call.

**Row 10 maps to FR11, not FR3.** The criterion is about *which* named state the board can distinguish —
a missing database against a server that failed to start — which is FR11's subject. FR3 would be
satisfied by a server that refused and then exited, collapsing two of FR11's four states into one.

**ENVX3's board half is not in this matrix.** "A registered project on a read-only filesystem renders its
state without error" needs a renderer and is covered under `docs/epics/48-06-coverage-failure-surface.md`.
Row 11 is the server-side half only.

**FR11's other three states are not in this matrix.** The schema-ahead state, the Node-floor state and the
failed-to-start state are rendered by the board and are covered under 48-06. This epic delivers only the
mechanism behind the first of the four.
