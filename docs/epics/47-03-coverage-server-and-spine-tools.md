# Coverage Matrix: Server and Spine Tools

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Epic**: docs/epics/47-03-epic-server-and-spine-tools.md  
**Date**: 2026-08-08

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | NFR1 | The plugin installs by clone or marketplace fetch with no build step, no `node-gyp`, and no per-platform binary. | A clean clone starts the server with no compilation step | Story 1 | `[target]` | |
| 2 | NFR2 | The server refuses to start with a clear message below its minimum Node version rather than failing on a missing module. | The server refuses to start below the Node floor with a message naming the required version | Story 1 | `[integration]` | |
| 3 | NFR3 | The MCP stdio transport owns stdout. All logging, including Node's `ExperimentalWarning` for `node:sqlite`, goes to stderr or is suppressed (`NODE_NO_WARNINGS=1`). | A full session's stdout parses as well-formed JSON-RPC with no stray output | Story 1 | `[integration]` | |
| 4 | FR1 | Every CPM artefact type is a table with typed columns, not a markdown file parsed at read time. | Creating each artefact type produces a row readable by its typed read tool | Story 2 | `[integration]` | |
| 5 | FR10 | All twenty-three entity types — thirteen seeded `document_kind` rows, eight child tables and two standalone tables — have a create tool, and the enumeration has no member without one | The seven spine entity types — spec, requirement, story criterion, epic, story, task, coverage — each have create, read and update tools | Story 2 | `[integration]` | |
| 6 | FR4 (must NOT) | Nothing infers a type by parsing an identifier. | must NOT — the `requirement` create tool accepts a class inferred from `label`, rather than requiring `class` as an argument | Story 2 | `[unit]` | |
| 7 | FR4 | Requirement class, MoSCoW band, status, test-approach tag, and coverage verification state are typed columns constrained by `CHECK`. | Every `requirement` and `acceptance_criterion` type distinction is readable from a column with `label` and `text` withheld | Story 2 | `[integration]` | |
| 8 | FR5 (must NOT) | Human-facing artefact numbers are allocated monotonically and are never reused, including after archival. | Allocating a number through its tool returns the value and never a success without one | Story 3 | `[unit]` | |
| 9 | FR22 | so "which epics are ready" is a query, a blocker's completion is visible to everything downstream | The link tool refuses an edge that would close a cycle over a `gates_work` kind, naming both ends | Story 3 | `[integration]` | |
| 10 | FR14 | A verification tool reports orphans, dangling links, and each entry in the cross-row invariant register (Data Model), so a corrupted state is diagnosable without SQL. | The integrity tool is callable and reports every register entry it checks | Story 3 | `[integration]` | |
| 11 | FR13 | Query tools return summaries rather than whole bodies unless a body is explicitly requested | For the same artefact, a read without an explicit body request returns strictly fewer bytes than one with it — asserted as a comparison between two responses, not against a fixed number | Story 4 | `[integration]` | |
| 12 | FR13 | every list-returning tool takes a `limit` with a default | Every list-returning tool declares a `limit` with a default, and a caller that raises it receives the larger result | Story 4 | `[unit]` | |
| 13 | FR13 (must NOT) | The bound is a default that costs nothing to override, not a limit. | must NOT — a query tool returns an unbounded row set when no limit is supplied, or refuses a limit the caller raised | Story 4 | `[unit]` | |
| 14 | NFR5 | Names must therefore be searchable words (`dpm_create_epic`, not `dpm_ce`); brevity is not a virtue here. | Every exported tool name matches `dpm_[a-z_]{6,}`, and every part after the verb is a table name, a column name, or a seeded `document_kind.kind` value — checked against the live schema, not against a hand-kept word list | Story 5 | `[unit]` | |
| 15 | NFR7 | Every piece of state is reachable through a read tool without SQL | Every table in `sqlite_master` is reachable through at least one read tool, asserted by comparing the table list against the tools' declared coverage | Story 5 | `[integration]` | |
| 16 | NFR7 | so a user whose server will not start is not locked out of their own planning history | A database whose schema version is ahead of the server still answers read tools rather than refusing to start | Story 5 | `[integration]` | |
| 17 | FR11 | The progress-file subsystem — session-suffixed filenames, hook injection, adoption on `--resume`, compact-summary companions — is replaced by a session table. Adoption is an `UPDATE`; staleness is a `WHERE` clause. | A session row survives simulated resume under a new session id, and stale rows are selected by age | Story 6 | `[integration]` | |
| 18 | AD10 | Every tool argument that names a column exists on that table, with a compatible type | Every enum a tool declares is equal to the `CHECK` set on its column, in both directions, read from the live schema | Story 7 | `[unit]` | |
| 19 | AD10 | Every `NOT NULL` column without a default is a required argument on its create tool. | Every `NOT NULL` column without a default is a required argument on its create tool, and every foreign key on the table has a corresponding argument | Story 7 | `[unit]` | |
| 20 | AD10 (must NOT) | a test asserts their correspondence against the live database | must NOT — the conformance test compares tool schemas against a second copy of the DDL rather than against `PRAGMA` output | Story 7 | `[unit]` | |
| 21 | FR3 | dpm ships an MCP server whose tool schemas are the write contract. A malformed call is rejected at the tool boundary before it reaches the database. | A create call whose enum value the column's `CHECK` rejects fails at the tool boundary, and no row is written | Story 8 | `[integration]` | |
| 22 | FR3 (must NOT) | A malformed call is rejected at the tool boundary before it reaches the database. | must NOT — a tool accepts an argument the schema rejects, so validation happens at neither layer | Story 8 | `[integration]` | |
| 23 | AD10 | It runs in the suite, not at build time. | The conformance test passes against the running server's actual registered tool list, not a fixture of it | Story 8 | `[integration]` | |
| 24 | FR3 | dpm ships an MCP server whose tool schemas are the write contract. | A spec created through its tool, then an epic under it, then a story, then a coverage row binding a requirement fragment to a story criterion, all succeed in sequence and read back consistently through their read tools | Story 8 | `[integration]` | |
| 25 | FR11 | The progress-file subsystem — session-suffixed filenames, hook injection, adoption on `--resume`, compact-summary companions — is replaced by a session table. Adoption is an `UPDATE`; staleness is a `WHERE` clause. | A session created, resumed under a new id, and read back returns the state written before the resume | Story 8 | `[integration]` | |
| 26 | AD10 | It runs in the suite, not at build time. | Every tool the server registers appears in the reachability assertion, and every table appears in exactly one tool's declared coverage | Story 8 | `[integration]` | |

**Partial coverage to flag.**

**FR3 is half covered here.** Rows 21–22 cover the tool boundary rejecting malformed calls.
FR3's other clause — "No skill contains SQL, and no skill constructs a query", whose spec
criterion is "Every dpm SKILL.md contains no SQL keyword and no `sqlite3` invocation" — is a
property of the skill corpus and belongs to Epics 47-06 through 47-09.

**FR10's create-tool criterion (row 5) covers the seven spine types only.** The remaining
sixteen entity types are Epic 47-05 — sixteen rather than fifteen since the pivot of
2026-08-08 added `milestone` (FR27). FR10 therefore has partial coverage across three epics,
making it the clearest live instance of self-hosting register entry 1 in this breakdown.

**Rows 24–26 were added on 2026-08-08**, during the pivot that closed the self-hosting
register. They were not cascaded changes: all three criteria were already on Story 8 and had
no row, found by a set comparison between each epic's criteria and its matrix's `Story
Criterion` column. Row 26 is the pair to row 23 and neither substitutes for it — row 23 says
the conformance test reads the live registration, row 26 says the registration is complete in
both directions.

**Row 25 is FR11's only appearance in this matrix.** The session *table* is Story 6's; the
skills that stop writing progress files are Epics 47-06 through 47-09. FR11 is therefore
partially covered here and completed in 47-09.

**FR4, FR5, FR14 and FR22** each appear here in their tool-boundary half only; the schema
half is Epic 47-01's matrix.
