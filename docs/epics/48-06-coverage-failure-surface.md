# Coverage Matrix: Failure Surface

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Epic**: docs/epics/48-06-epic-failure-surface.md  
**Date**: 2026-08-13

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR11 | "A project with no `.dpm/dpm.db` renders a named state carrying its remedy" | "A project with no `.dpm/dpm.db` renders a named state carrying its remedy" | Story 1 | `[integration]` | |
| 2 | FR11 | "A database whose schema is ahead of the server renders a distinct named state" | "A database whose schema is ahead of the server renders a distinct named state" | Story 1 | `[integration]` | |
| 3 | FR11 | "A server that exits immediately renders a third, distinct named state" | "A server that exits immediately renders a third, distinct named state" | Story 1 | `[integration]` | |
| 4 | ENV2 | "With a Node below dpm's floor, the executable's refusal is captured and rendered per FR11" | "With a Node below dpm's floor, the executable's refusal is captured and rendered per FR11" | Story 1 | `[integration]` | |
| 5 | FR11 (added) | "A missing `.dpm/dpm.db`, a schema version ahead of the server, a Node below dpm's floor, and a server that fails to start each render as a distinct named per-project state carrying its remedy." | "The four states are distinct from one another, reconciled against FR11's enumeration so a state that collapses into another fails" | Story 1 | `[unit]` | |
| 6 | NFR2 | "With one project unreadable, every other registered project still renders its state" | "With one project unreadable, every other registered project still renders its state" | Story 2 | `[integration]` | |
| 7 | FR11 (must NOT) | "must NOT let any of the three prevent the remaining projects from rendering" | "must NOT let any of the three prevent the remaining projects from rendering" | Story 2 | `[integration]` | |
| 8 | NFR2 (added) | "One unreadable project never takes the board down. A failure is contained to its own row." | "Each of the four failure states is exercised in a mixed registry, not only the missing-database one" | Story 2 | `[integration]` | |
| 9 | FR10 | "After a full board session over a fixture project, the database file's hash, size and mtime are unchanged" | "After a full board session over a fixture project, the database file's hash, size and mtime are unchanged" | Story 3 | `[integration]` | |
| 10 | FR10 (added) | "No mutating tool is called, nothing is staged, and no file under a registered project is written — `.dpm/` included. Observing a project leaves it byte-identical." | "The project tree's whole file set and content hashes are unchanged, `.dpm/` included — not only the database" | Story 3 | `[integration]` | |
| 11 | FR10 (must NOT) | "must NOT call any tool whose name is a mutating verb, in any code path" | "must NOT call any tool whose name is a mutating verb, in any code path" | Story 3 | `[unit]` | |
| 12 | FR10 (added, must NOT) | "No mutating tool is called" | "must NOT — the mutating-verb check passes over an empty verb set; the set is derived from the difference between the server's full `tools/list` and its read-only set" | Story 3 | `[unit]` | |
| 13 | ENVX3 | "A registered project on a read-only filesystem renders its state without error" | "A registered project on a read-only filesystem renders its state without error" | Story 4 | `[integration]` | |
| 14 | ENVX3 (added) | "Must not require write access to any registered project, including creating `.dpm/dpm.db` in a project that has none." | "Its epics, stories, progress and previews render as they do for a writable project — the read-only filesystem changes nothing the user sees" | Story 4 | `[integration]` | |

## Notes

**Row 5 exists because FR11's four states are asserted separately and never against each other.** Rows 1–4
each check that some named state renders; none checks that any two of them differ. The Node-floor and
failed-to-start cases are the same observable — below the floor, the executable refuses and exits — so a
board that collapsed them would pass rows 3 and 4 and fail the requirement's word *distinct*. Reconciled
against FR11's enumeration rather than pairwise, so a fifth state added later is covered without an edit.

**Row 10 is the difference between FR10's criterion and FR10's requirement.** Row 9 names the database file
only; the requirement says no file under a registered project is written, `.dpm/` included. A board that
regenerated `.dpm/dpm.sql`, or left a lock file, or wrote its own cache into the project, passes row 9. Row
10 is added rather than substituted, so row 9 stays verifiable as the spec states it.

**Rows 11 and 12 are a derived sweep and its floor.** A transcribed list of mutating verbs is correct on the
day it is written and narrows silently every time dpm gains a tool; the set is derived from the difference
between the full `tools/list` and the read-only set instead. That derivation makes row 12 necessary — an
empty difference means the two sets are identical, which is a much larger problem than a failed sweep and
would otherwise report as a pass.

**Rows 9–12 prove a property this epic does not deliver.** The board is non-mutating because of 48-02's
Story 3 must-NOTs and 48-01's read-only mode. These rows are the evidence, which is why they sit late in the
order. A ✓ here is not a claim that this epic made the board read-only.

**Row 8 is the coverage NFR2's own criterion does not compel.** Row 6 is satisfied by a mixed registry
containing one unreadable project of the easiest kind. The containment path differs by failure kind — an
absent file is caught synchronously, a server that exits mid-read is not — so the criterion names all four.

**Row 14 discriminates where row 13 does not.** "Renders its state without error" is also true of a project
rendered as one of Story 1's failure states, which is the wrong answer arriving quietly. Row 14 asserts the
project renders as a healthy one.

**ENVX3's server half is not in this matrix.** "The read-only path creates `.dpm/`, `.dpm/dpm.db`, or an
ignore file in a project that has none" is covered at
`docs/epics/48-01-coverage-read-only-server-mode.md` row 11. Rows 13 and 14 are the board half only, and
ENVX3 is covered across the two.
