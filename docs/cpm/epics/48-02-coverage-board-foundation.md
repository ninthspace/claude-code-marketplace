# Coverage Matrix: Board Foundation

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Epic**: docs/epics/48-02-epic-board-foundation.md  
**Date**: 2026-08-13

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR1 | "Add, list and remove round-trip through a registry file located under `$XDG_CONFIG_HOME`" | "Add, list and remove round-trip through a registry file located under `$XDG_CONFIG_HOME`" | Story 1 | `[unit]` | ✓ |
| 2 | FR1 | "A registered path that is no longer a directory is pruned on launch" | "A registered path that is no longer a directory is pruned on launch" | Story 1 | `[unit]` | ✓ |
| 3 | FR1 | "Registration works from the CLI and from inside the TUI via a directory picker." | "`board.py add <path>`, `list` and `remove <path>` reach all three operations from the CLI, and `add` refuses a path that is not a dpm project with a message naming what was missing" | Story 1 | `[integration]` | ✓ |
| 4 | FR1 (must NOT) | "must NOT write the registry anywhere outside the XDG config location" | "must NOT write the registry anywhere outside the XDG config location" | Story 1 | `[unit]` | ✓ |
| 5 | ENV1 | "`uv run --script board.py list` succeeds on a clean checkout with no prior install step" | "`uv run --script board.py list` succeeds on a clean checkout with no prior install step" | Story 2 | `[integration]` | ✓ |
| 6 | ENV3 | "The server path resolves from an installed plugin cache, from a checkout, and from an explicit override" | "The server path resolves from an installed plugin cache, from a checkout, and from an explicit override" | Story 2 | `[unit]` | ✓ |
| 7 | ENV4 | "`uv run pytest` runs the suite from the board directory" | "`uv run pytest` runs the suite from the board directory" | Story 2 | `[integration]` | ✓ |
| 8 | ENVX2 | "The board runs from a clean checkout with no npm or pip install, and dpm's `package.json` dependencies stay empty" | "The board runs from a clean checkout with no npm or pip install, and dpm's `package.json` dependencies stay empty" | Story 2 | `[unit]` | ✓ |
| 9 | ENVX4 | "The suite passes with no network available, and no socket is opened outside the stdio pipes" | "The suite passes with no network available, and no socket is opened outside the stdio pipes" | Story 2 | `[unit]` | ✓ |
| 10 | FR2 | "Every project read the board performs is observable as a `tools/call` on the spawned server" | "Every project read the board performs is observable as a `tools/call` on the spawned server" | Story 3 | `[integration]` | ✓ |
| 11 | NFR6 | "A message split across two chunk boundaries is parsed once and whole" | "A message split across two chunk boundaries is parsed once and whole" | Story 3 | `[tdd] [unit]` | ✓ |
| 12 | ENV5 | "At least one test drives the real `bin/dpm-mcp.js` over stdio against a built fixture database" | "At least one test drives the real `bin/dpm-mcp.js` over stdio against a built fixture database" | Story 3 | `[integration]` | ✓ |
| 13 | NFR6 (must NOT) | "must NOT parse anything arriving on the server's stderr as data" | "must NOT parse anything arriving on the server's stderr as data" | Story 3 | `[unit]` | ✓ |
| 14 | FR2 (must NOT) | "must NOT import `sqlite3`, or any SQLite binding, anywhere in the board's modules" | "must NOT import `sqlite3`, or any SQLite binding, anywhere in the board's modules" | Story 3 | `[unit]` | ✓ |
| 15 | FR2 (must NOT) | "must NOT open any file under a project's `docs/` or `.dpm/` from board code" | "must NOT open any file under a project's `docs/` or `.dpm/` from board code" | Story 3 | `[unit]` | ✓ |
| 16 | FR3 | "Reading a project spawns exactly one server process, reused across subsequent reads" | "Reading a project spawns exactly one server process, reused across subsequent reads" | Story 4 | `[integration]` | ✓ |
| 17 | FR3 | "Every spawned process is terminated when the board exits" | "Every spawned process is terminated when the board exits" | Story 4 | `[integration]` | ✓ |
| 18 | FR3 (added) | "A single long-lived server process per project, cwd at the project root" | "Each spawned server is launched in read-only mode with cwd at the project root" | Story 4 | `[integration]` | ✓ |
| 19 | FR3 (must NOT) | "must NOT spawn a server against a project with no `.dpm/dpm.db` — no process starts, and the project renders FR11's named missing-database state rather than nothing at all" | "must NOT spawn a server against a project with no `.dpm/dpm.db` — no process starts, and the project renders FR11's named missing-database state rather than nothing at all" | Story 4 | `[integration]` | ✓ |
| 20 | NFR5 | "Every tool name and argument the board declares resolves against the live server's `tools/list`" | "Every tool name and argument the board declares resolves against the live server's `tools/list`" | Story 5 | `[integration]` | ✓ |
| 21 | NFR5 (added) | "The board declares the tool names and arguments it depends on" | "The declared set is derived from the board's own call sites rather than transcribed into a second list, so a call the board makes and never declares fails the check" | Story 5 | `[integration]` | ✓ |
| 22 | NFR5 (must NOT) | "must NOT render an empty column when a declared tool is missing — the mismatch reports" | "must NOT render an empty column when a declared tool is missing — the mismatch reports" | Story 5 | `[integration]` | ✓ |
| 23 | NFR5 (added, must NOT) | "a dpm release that renames or rescopes one fails a test rather than quietly rendering an empty column" | "must NOT — the reconciliation passes over an empty declared set or an empty `tools/list` response" | Story 5 | `[unit]` | ✓ |
| 24 | FR1, FR3 (integration) | "Register, list and remove projects, persisted under XDG config." / "One server session per project, spawned only where a database already exists." | "`board.py list` over a registry holding two fixture projects — one with a database and one without — reports a state for both, spawns exactly one server, and exits with every spawned process reaped" | Story 6 | `[integration]` | ✓ |
| 25 | FR2 (integration) | "It contains no SQL, opens no SQLite connection, parses no markdown under `docs/`, and reads no `.dpm/dpm.sql`." | "The healthy project's reported state is built entirely from `tools/call` responses, asserted from a recorded transcript of the calls made rather than from the absence of other reads" | Story 6 | `[integration]` | ✓ |

## Notes

**Row 3 covers half of FR1's reachability.** The requirement names two affordances — the CLI and a TUI
directory picker — and the picker needs an app to open in. Its criterion is on
`docs/epics/48-04-coverage-browser-and-previews.md`; FR1 is fully covered only across the two. Row 3 is
written so that a ✓ here cannot be read as covering the picker.

**Rows 10 and 25 are the two halves of FR2, and neither substitutes for the other.** Row 10 says every
read *is* a `tools/call`; row 25 says the state a user sees was built from those calls and nothing else.
A board that made the right calls and then rendered from a stale local cache passes row 10.

**Rows 14, 15 and 25 are the positive and negative forms of one claim.** Rows 14 and 15 are static
absences — no SQLite binding imported, no project file opened — and both are satisfied by a board that
reads nothing at all. Row 25 is the paired positive: the transcript shows what *was* read. Retro 42's
observation applied one epic over from where it was written.

**Row 18 is added rather than propagated.** FR3's own criteria do not assert the launch mode or the
working directory, and both are load-bearing: `DATABASE` resolves relative to the server's cwd, so a
server spawned in the wrong directory opens the wrong database — or creates one — and read-only mode is
the whole of 48-01's protection. Asserted from the spawned process's environment and argv, not from the
board's intent.

**Rows 21 and 23 are added for the same reason, in two directions.** NFR5 says the board *declares* its
surface; a declaration transcribed into a list agrees with `tools/list` while disagreeing with the code
(row 21), and a reconciliation between two derived-but-empty sets agrees with everything (row 23). Row
23's floor is checked on planted inputs, because once Story 5 works the live surfaces cannot distinguish
a working check from a vacuous one.

**Row 19 keeps the spec's post-pivot wording.** The criterion was re-grounded on 2026-08-13 to assert a
*named state* rather than only an absent process, because spec 49 removes creation for every caller and
the earlier wording would have gone green regardless. At this epic the rendering surface is `board.py
list`; the TUI's rendering of the same state is 48-06's.

**FR3's read-only launch and 48-01's refusal are both present on purpose.** Row 19 keeps a pointless
process from starting; 48-01's row 8 is what happens when the database disappears between that check and
the open. Neither makes the other redundant, and a ✓ on one is not evidence about the other.
