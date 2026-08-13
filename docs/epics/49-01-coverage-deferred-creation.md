# Coverage Matrix: Deferred Creation

**Source spec**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Epic**: docs/epics/49-01-epic-deferred-creation.md  
**Date**: 2026-08-13

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR2 | "Built from an in-memory template brought up by the same `start()`, and identical to the list built against a real database at the same schema version" | "The template-built tool list equals the list built against a migrated file database — full `describe()` output, not names alone" | Story 1 | `[unit]` | |
| 2 | FR2 | "The advertised tool list is complete before any database exists." | "The compared list is non-empty and its length equals the registry-derived count, never a transcribed number" | Story 1 | `[unit]` | |
| 3 | AD12 | "`methods()` splits so `tools/list` describes the template and `tools/call` resolves the live table, with the resolver defaulting to the same list so existing call sites are unchanged." | "`methods()` splits so `tools/list` describes the template and `tools/call` resolves the live table, with the resolver defaulting to the same list so every existing call site is unchanged" | Story 1 | `[unit]` | |
| 4 | FR2 (must NOT) | "must NOT pass on names alone — a template yielding correct names with empty input schemas fails" | "must NOT pass on names alone — a template yielding correct names with empty input schemas fails" | Story 1 | `[unit]` | |
| 5 | FR1 | "The server answers `initialize`, `ping` and `tools/list` and shuts down leaving no `.dpm/` directory and no file inside one." | "A spawned server in an empty temp dir, given `initialize` + `tools/list` then EOF, exits 0 and leaves no `.dpm/` entry" | Story 2 | `[integration]` | |
| 6 | FR1 | "The same spawn given one `tools/call` does leave `.dpm/dpm.db` — asserted in the same test, so a server that crashed at startup cannot satisfy the absence" | "The same spawn given one `tools/call` does leave `.dpm/dpm.db` — asserted in the same test, so a server that crashed at startup cannot satisfy the absence" | Story 2 | `[integration]` | |
| 7 | NFR1 | "a clean launch writes nothing to stderr" | "A clean spawned session writes nothing to stderr" | Story 2 | `[integration]` | |
| 8 | NFR1 | "Startup does no filesystem write, migrations run once per session" | "Launch performs no filesystem write, and migrations run once per session rather than per request — counted through an injected recorder, not a timer" | Story 2 | `[unit]` | |
| 9 | FR1 (must NOT) | "must NOT satisfy the absence by failing to serve: stdout carries a well-formed `tools/list` result whose tool count exceeds a registry-derived floor" | "must NOT satisfy the absence by failing to serve: stdout carries a well-formed `tools/list` result whose tool count exceeds a registry-derived floor" | Story 2 | `[integration]` | |
| 10 | FR3 | "Directory, ignore file, database, in that order; the triggering call returns its normal result rather than an error about a missing database." | "A first `tools/call` in a fresh directory returns its normal result, and both `.dpm/.gitignore` and `.dpm/dpm.db` exist afterwards" | Story 3 | `[integration]` | |
| 11 | FR3 | "Directory, ignore file, database, in that order" | "The ignore file is written before the database is opened, driven through an injected recorder as `openConnection`'s `probe` already is" | Story 3 | `[unit]` | |
| 12 | FR4 | "`.dpm/dpm.db` is ignored without the user doing anything." | "In a fresh repository, `git check-ignore .dpm/dpm.db` succeeds and `git status --porcelain` shows no entry for it" | Story 4 | `[integration]` | |
| 13 | FR4 | "A nested `.dpm/.gitignore` holding `dpm.db*`" | "`dpm.db-wal` and `dpm.db.synced` are ignored by the same pattern" | Story 4 | `[integration]` | |
| 14 | FR4 | "written before the database file exists and never overwritten when already present" | "An existing `.dpm/.gitignore` is left byte-identical" | Story 4 | `[integration]` | |
| 15 | FR9 | "The README stops instructing a step the server performs. The ignore line goes from setup; the pre-commit symlink stays." | "The README's setup carries no ignore-line instruction and still carries the pre-commit symlink step" | Story 4 | `[unit]` | |
| 16 | ENV3 | "git available in development, able to init a repository, commit, and produce a conflicted merge." | "The git fixture creates a repository, commits, and produces a conflicted `dpm.sql`" | Story 4 | `[integration]` | |
| 17 | FR4 (must NOT) | "must NOT over-reach: `git check-ignore .dpm/dpm.sql` fails" | "must NOT over-reach: `git check-ignore .dpm/dpm.sql` fails" | Story 4 | `[integration]` | |
| 18 | FR5 | "A database from a newer plugin serves reads and refuses writes with the existing message; the decision moves from launch to first open, because that is where `migrated.ahead` becomes knowable." | "A database whose schema version is ahead, opened lazily on first call, answers reads and refuses writes with the existing two-version message" | Story 5 | `[integration]` | |
| 19 | NFR3 | "An existing `.dpm/dpm.db` opens and serves exactly as today: no rebuild, no prompt, no migration beyond what `migrate()` already does." | "An existing database with rows hashes identically before and after a read-only lazy session, and answers the same reads" | Story 5 | `[integration]` | |
| 20 | FR5 (must NOT) | "must NOT withhold write tools from `tools/list` — they stay listed and refuse" | "must NOT withhold write tools from `tools/list` — they stay listed and refuse" | Story 5 | `[unit]` | |
| 21 | NFR2 | "No environment variable, flag or code path exists solely so a test can simulate a missing, stale or ahead database. `DPM_DATABASE` is unaffected — it is a real override with real callers." | "`process.env` is read in `src/` only for `DPM_DATABASE`, with a floor asserting the check finds the known sites" | Story 6 | `[unit]` | |
| 22 | ENV1 | "`node --test` runs the suite with no install step. `dpm/package.json` declares the runner and both dependency maps are empty" | "The suite runs from a clean checkout with no install step; both dependency maps are empty" | Story 6 | `[integration]` | |
| 23 | ENV2 | "Node 22.5.0 or later in development, with `node:sqlite` and FTS5 on the connection." | "The Node floor check and the FTS5 probe both pass in development" | Story 6 | `[unit]` | |
| 24 | ENVX1 | "Must not require any dependency outside Node's standard library. Both dependency maps stay empty." | "No import in `src/` or `bin/` resolves outside `node:` builtins and relative paths, with a floor on the number of imports examined" | Story 6 | `[unit]` | |
| 25 | ENVX2 | "Must not require the user to edit a file they own. No code path and no documented step writes outside `.dpm/` and the projection publish already owns." | "No write in `src/` targets a path outside `.dpm/` and the projection publish already owns; the README's setup step count does not grow" | Story 6 | `[unit]` | |
| 26 | ENVX3 | "Must not make git a runtime dependency of the server. The path from launch through first open and restore invokes no git subprocess." | "The static import graph from `bin/dpm-mcp.js` reaches no `node:child_process`, asserted as `server.test.js` already asserts the `node:sqlite` graph" | Story 6 | `[unit]` | |
| 27 | FR2 (added) | "required because `mcp.js` declares `listChanged: false`, so what is advertised at launch must stay true for the session" | "In one session, the tool list returned by `tools/list` before any database exists is identical to the tool table resolved for `tools/call` after the lazy open — the `listChanged: false` promise held across the seam" | Story 7 | `[integration]` | |
| 28 | AD12 (added) | "opens the real file on the first `tools/call`, rebuilding the tool table against it" | "A session that lists tools, then makes two calls, answers both from one database opened once" | Story 7 | `[integration]` | |

## Notes

**Rows 1–26 are propagated verbatim.** Nothing was strengthened, because nothing needed it: the spec
carries FR1's paired positive in the same test (rows 5 and 6), FR2's registry-derived floor (row 2) and
names-alone decoy (row 4), FR5's listed-but-refusing must-NOT (row 20), NFR1's counted-not-timed recorder
(row 8), and a floor on each of Story 6's sweeps (rows 21, 24). That is retro 42's lesson arriving in the
source rather than in the breakdown.

**Rows 27 and 28 are the gap Step 3c found.** Rows 1 and 2 compare two tool lists the *test* builds — one
from a template, one from a file database. Neither says the list the transport advertised at launch equals
the table it resolved on first call, which is exactly what `listChanged: false` promises and exactly what
AD12's `methods()` split puts at risk. A resolver wired to the wrong list passes rows 1–4 and every row in
Stories 2–5.

**Row 3 maps to AD12 rather than to a requirement,** because the `methods()` split is an architecture
decision with no `FRn`. It is asserted rather than assumed: the "resolver defaults to the same list"
clause is what makes this a compatible addition rather than a breaking change to a signature three call
sites depend on.

**Row 16 builds a fixture two epics use.** ENV3's conflicted-`dpm.sql` half is not exercised until
49-03's guard verdict; the fixture is built here because this is the first story needing a real
repository, and a second fixture built later would diverge from this one.

**Rows 21, 24, 25 and 26 guard the later epics too.** All four are static sweeps over `src/` and `bin/`,
so once written they fail for anything 49-02 through 49-05 introduces. No later matrix repeats them, and
a reader of a later epic looking for the assertion will find it here.

**Rows 15 and 25 are both about the README and cover different requirements.** Row 15 is FR9's
substantive claim — the ignore instruction gone, the symlink step kept. Row 25 is ENVX2's step-count
sweep. A ✓ on one is not evidence about the other.
