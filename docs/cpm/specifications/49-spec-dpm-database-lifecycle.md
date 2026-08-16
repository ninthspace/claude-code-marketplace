# Spec: DPM Database Lifecycle — Deferred Creation, Automatic Ignore, and Dump/Database Direction

**Date**: 2026-08-13  
**Brief**: docs/discussions/32-discussion-dpm-database-creation-deferral.md

## Problem Summary

Three problems meet at one seam — the moment the DPM database comes into existence. The MCP server
creates `.dpm/dpm.db` unconditionally at launch, so every Claude session in every directory acquires
a migrated, seeded planning database whether or not the project uses DPM. The database is only
gitignored if the user followed a manual README step, leaving AD4's second clause unimplemented. And
nothing imports `.dpm/dpm.sql`: a clean pull rewrites the dump and leaves the local database behind,
after which the guard refuses the next commit as `differs` and names `bin/dpm-publish.js` — which
regenerates the dump from the stale database and discards the pulled rows. A fresh clone separately
starts with an empty database beside a full dump, contradicting the README's own claim that the dump
is what a checkout restores from.

## Functional Requirements

### Must Have

- **FR1 — A session that never calls a tool creates nothing.** The server answers `initialize`, `ping` and `tools/list` and shuts down leaving no `.dpm/` directory and no file inside one.
- **FR2 — The advertised tool list is complete before any database exists.** Built from an in-memory template brought up by the same `start()`, and identical to the list built against a real database at the same schema version — required because `mcp.js` declares `listChanged: false`, so what is advertised at launch must stay true for the session.
- **FR3 — The first tool call brings the database into existence and then succeeds.** Directory, ignore file, database, in that order; the triggering call returns its normal result rather than an error about a missing database.
- **FR4 — `.dpm/dpm.db` is ignored without the user doing anything.** A nested `.dpm/.gitignore` holding `dpm.db*`, written before the database file exists and never overwritten when already present. This implements AD4's second clause, which has had no implementation.
- **FR5 — The version-ahead gate still applies, decided at first open.** A database from a newer plugin serves reads and refuses writes with the existing message; the decision moves from launch to first open, because that is where `migrated.ahead` becomes knowable.
- **FR6 — A missing database beside a committed dump is built from it.** Restore, not migrate-empty — the behaviour the README already claims.
- **FR7 — A database that disagrees with the dump is diagnosed by direction.** The guard distinguishes *database ahead* (publish), *dump ahead* (import) and *both moved* (reconcile deliberately), and names the fix belonging to each. Today it reports `differs` and names publish in every case, which silently discards a pull.
- **FR8 — An explicit import operation exists, sharing one implementation with the merge.** Import is the merge's restore → rename-into-place → verify-round-trip → publish → re-guard sequence without the three-way merge.
- **FR10 — A first open that did something unusual reports it in one line on stderr.** A restore from the dump, or a database served read-only, is named. An ordinary create is not.
- **FR12 — The deferred open honours a read-only server mode.** Where the server is running read-only, the first tool call refuses a missing database rather than creating one, writes no `.dpm/` directory and no ignore file, and performs no restore. The mode is introduced by spec 48's AD1 (`DPM_READ_ONLY=1`), which needs SQLite's refusal on a missing file to supply its own FR11 state; this requirement is that FR1–FR6 do not defeat it by creating on first call instead. The two specs are complementary — 48 stops an observer *migrating* a project, this one stops any caller *creating* one — and either may land first.

### Should Have

- **FR9 — The README stops instructing a step the server performs.** The ignore line goes from setup; the pre-commit symlink stays.
- **FR11 — `dpm-merge` becomes discoverable.** It is documented nowhere today, so FR7's reconcile diagnostic would otherwise name a tool findable only by reading the source.

### Could Have

None. FR10 and FR11 were promoted during facilitation; the labels stay stable rather than being
resequenced by heading.

### Won't Have (this iteration)

- Registering `dpm-merge` as a git merge driver via `.gitattributes` and `git config`. It needs per-clone configuration and is a separate decision from making the tool findable.
- A write-only creation gate. First-call-of-any-kind is the chosen behaviour; the narrower gate remains available later without redoing FR1–FR3.
- An importer from CPM's markdown. AD8 stands and is untouched.
- Any change to the dump format, the projection format, or the schema. This spec adds no migration.

## Non-Functional Requirements

- **NFR1 — Launch cost and stderr silence hold.** Startup does no filesystem write, migrations run once per session, and a clean launch writes nothing to stderr.
- **NFR2 — No production seam exists for testing.** No environment variable, flag or code path exists solely so a test can simulate a missing, stale or ahead database. `DPM_DATABASE` is unaffected — it is a real override with real callers.
- **NFR3 — Existing projects are unaffected.** An existing `.dpm/dpm.db` opens and serves exactly as today: no rebuild, no prompt, no migration beyond what `migrate()` already does.
- **ENV1 — `node --test` runs the suite with no install step.** `dpm/package.json` declares the runner and both dependency maps are empty; a clean checkout runs the suite immediately.
- **ENV2 — Node 22.5.0 or later in development, with `node:sqlite` and FTS5 on the connection.**
- **ENV3 — git available in development, able to init a repository, commit, and produce a conflicted merge.** FR4 and FR7 are checkable only against a real repository.
- **ENVX1 — Must not require any dependency outside Node's standard library.** Both dependency maps stay empty.
- **ENVX2 — Must not require the user to edit a file they own.** No code path and no documented step writes outside `.dpm/` and the projection publish already owns.
- **ENVX3 — Must not make git a runtime dependency of the server.** The path from launch through first open and restore invokes no git subprocess.

**No production environmental entries.** Stated rather than omitted: the runtime floor is spec 47's
NFR2 and this spec does not move it, and nothing here asks the host for anything new. This spec
therefore has no `[target]` criteria — every entry above is a claim about the development machine.

## Architecture Decisions

These continue spec 47's sequence as AD12–AD16 rather than restarting at AD1, because `dpm/src/`
carries comments citing AD4, AD5, AD10 and AD11 and a second AD4 would be unresolvable.

### AD12 — The tool list is built from an in-memory template; the live database is opened on first call

**Choice**: `main()` brings up a `:memory:` database through the existing `start()` purely to build the tool table it advertises, and opens the real file on the first `tools/call`, rebuilding the tool table against it. `methods()` splits so `tools/list` describes the template and `tools/call` resolves the live table, with the resolver defaulting to the same list so existing call sites are unchanged.

**Rationale**: every build-time database read in the tool layer reads schema or seeded vocabulary, never a user row — the document-kind query in the registry, the `sqlite_schema` read behind search's entity vocabulary, the kind/numbering and `PRAGMA table_info` reads in the list layer, and the per-kind reads in the document and milestone factories. A template at the same schema version therefore produces an identical list, which is what `listChanged: false` requires. `cross/template.js` already builds a whole tool set off `start(':memory:')`.

**Alternatives considered**: a lazy getter or proxy on `context.db` — rejected because three modules destructure `const { db } = context` at build time, so a getter would be resolved eagerly and silently. Classifying every `db` use in the tool layer into schema-reads and row-reads — rejected as a large audit with an invisible failure mode, to save milliseconds on one call.

### AD13 — Direction is decided by a machine-local sync marker

**Choice**: `.dpm/dpm.db.synced` holds the hash of the dump text at the last sync point, written by both publish and import. The guard compares the marker against the hash of the dump on disk and against the hash of `dump(db)`:

| Marker vs. file | Marker vs. `dump(db)` | Verdict | Fix named |
|---|---|---|---|
| same | differs | database moved | publish |
| differs | same | dump moved | import |
| differs | differs | both moved | reconcile deliberately (`dpm-merge`) |
| absent, and the two agree | — | adopt | write the marker, report clean |
| absent, and the two differ | — | unknown | refuse; name both fixes and what each would do |

**Rationale**: one hash answers the question unambiguously, needs no migration, and the filename is already covered by AD4's `dpm.db*` ignore pattern — the marker is machine-local for the same reason the database is. The absent-marker rows are the upgrade path: every database that exists today lacks a marker, and one that already agrees with its dump is not ambiguous at all, so it adopts silently and only a database already divergent at upgrade time sees the unknown verdict.

**Alternatives considered**: a `sync_state` table — rejected because the dump is generated from the database, so a stored hash would end up inside the file it hashes, and excluding one table from the dump to escape that is a special case that outlives whoever understood it; spec 47's NFR4 makes byte-stability load-bearing. Row-set diff alone, restoring the disk dump into a scratch database and comparing — rejected as the verdict because a local deletion and a remote addition produce the same signature, though it is retained as the source of diagnostic detail (deferred). Asking git — rejected because after both a pull and local database work the worktree matches `HEAD`, so the two cases are indistinguishable from history.

### AD14 — Creating from the dump is automatic; overwriting from it is explicit

**Choice**: a first open that finds no database and a committed dump beside it restores from that dump. A first open that finds a database never touches it, whatever the dump says.

**Rationale**: the two directions have different stakes. Restoring into nothing writes a generated, gitignored file from its committed source and can lose nothing. Overwriting an existing database can destroy rows created and never published — the class of thing AD11 already rejected the server doing on its own initiative, on the grounds that a facilitation's writes are provisional until its run closes.

**Alternatives considered**: reimporting automatically whenever the dump is ahead — rejected as AD11's mistake with data loss in place of an inconvenient rewrite. Never restoring and leaving the clone case manual — rejected because the README already promises otherwise and an empty database beside a full dump is a state nobody wants.

**There is a third case, and it is not a weaker form of the first: under a read-only server, create
never.** A restore is a write, so FR6 is out of bounds there however empty the directory is — a
read-only observer that restored a project from its dump would be writing into a repository it was
launched specifically not to touch. The distinction that makes the automatic case safe is that nothing
can be lost, and it holds only because the caller was going to use the database; an observer was not.
Read-only refuses instead, and the refusal is what spec 48's FR11 reads as a named state (FR12).

### AD15 — The ignore file is nested in `.dpm/`, not appended to the root `.gitignore`

**Choice**: write `.dpm/.gitignore` containing `dpm.db*`, only when absent, before the database file is created.

**Rationale**: git honours a `.gitignore` in any directory, so it does the same job without editing a file the user owns (ENVX2), and committed beside `.dpm/dpm.sql` it reaches every clone once. Writing it first means the database never exists unignored, even briefly. The star covers the WAL and journal siblings and the sync marker.

**Alternatives considered**: appending to the root `.gitignore` — rejected on ENVX2 and the idempotency it would need. A global gitignore — rejected as not shared with collaborators, which is the point.

### AD16 — Import shares one implementation with the merge

**Choice**: the restore → rename-into-place → verify-the-dump-round-trips → publish → re-guard sequence in the merge is extracted and called by both the merge and the new import.

**Rationale**: AD11's reasoning applied a second time. Two implementations of "rebuild the database from a dump and bring the tree into agreement" disagree the first time either end changes, and the disagreement is silent. The staging-file-and-rename detail is easy to omit in a second copy, and a restore straight over `.dpm/dpm.db` that fails part way leaves the user with neither their database nor the import.

**Alternatives considered**: a fresh import path — rejected above. Reusing `restore()` alone without the verify and the publish — rejected because a dump that does not survive its own restore would then be committed.

## Scope

### In Scope

- FR1–FR8, FR10 and FR12; FR9 and FR11.
- `src/server/index.js` — `main()` becomes a template build plus a lazy `open()` carrying the mkdir, the ignore file, restore-if-missing, and the version-ahead gate.

**Landing order against spec 48.** Spec 48 (*dpm board*) introduces the read-only server mode its AD1
specifies, and this spec's FR12 is the requirement that the deferred open does not defeat it. Either
may land first and the split of work differs:

- **This spec first**: 48's server amendment reduces to the read-only connection, the skipped migration  
  and seeding, and the refusal its FR11 reads. Nothing there has to prevent a file being created.
- **48 first**: its amendment is built as specified, and FR12 is then a constraint on the lazy open  
  rather than a description of behaviour that already holds.

FR12 is a must-have in both orders. Should the read-only mode never be built, FR12 is satisfied
vacuously — which is a reason to check it against 48's own criteria rather than to drop it.

- `src/server/mcp.js` — `methods()` splits `tools/list` from `tools/call` with a defaulted resolver.
- A sync-marker module, written by publish and import, read by the guard.
- `src/guard/` — the three-way verdict, the named fix per case, and the adopt-on-agreement upgrade path.
- Extraction of the rebuild tail from `src/merge/main.js`, and the new import entry points.
- README: the ignore step goes; `dpm-merge` and the new import are documented.
- Test changes across `server.test.js`, `capability.test.js`, `first-run.test.js`, `guard.test.js`, `tests/support/git.js`, and the merge suites the extraction moves code out of.

### Out of Scope

- Registering `dpm-merge` as a git merge driver.
- A write-only creation gate.
- Any importer from CPM markdown.
- Any change to the dump format, the projection format, or the schema.

### Deferred

- Row-level detail in the guard's diagnostic — which rows moved on which side, from the scratch-restore diff. The verdict and the named fix ship now.
- A stderr line on ordinary creation. FR10 covers the unusual cases only.

## Testing Strategy

### Tag Vocabulary

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[tdd]` — Workflow mode: red-green-refactor, composable with a level tag

`[manual]` and `[target]` are unused. Nothing here resists automation, and Step 3a recorded no
production entries, so no criterion needs the real host.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| FR1 | A spawned server in an empty temp dir, given `initialize` + `tools/list` then EOF, exits 0 and leaves no `.dpm/` entry | `[integration]` |
| FR1 | The same spawn given one `tools/call` does leave `.dpm/dpm.db` — asserted in the same test, so a server that crashed at startup cannot satisfy the absence | `[integration]` |
| FR1 | must NOT satisfy the absence by failing to serve: stdout carries a well-formed `tools/list` result whose tool count exceeds a registry-derived floor | `[integration]` |
| FR2 | The template-built tool list equals the list built against a migrated file database — full `describe()` output, not names alone | `[unit]` |
| FR2 | The compared list is non-empty and its length equals the registry-derived count, never a transcribed number | `[unit]` |
| FR2 | must NOT pass on names alone — a template yielding correct names with empty input schemas fails | `[unit]` |
| FR3 | A first `tools/call` in a fresh directory returns its normal result, and both `.dpm/.gitignore` and `.dpm/dpm.db` exist afterwards | `[integration]` |
| FR3 | The ignore file is written before the database is opened, driven through an injected recorder as `openConnection`'s `probe` already is | `[unit]` |
| FR4 | In a fresh repository, `git check-ignore .dpm/dpm.db` succeeds and `git status --porcelain` shows no entry for it | `[integration]` |
| FR4 | `dpm.db-wal` and `dpm.db.synced` are ignored by the same pattern | `[integration]` |
| FR4 | must NOT over-reach: `git check-ignore .dpm/dpm.sql` fails | `[integration]` |
| FR4 | An existing `.dpm/.gitignore` is left byte-identical | `[integration]` |
| FR5 | A database whose schema version is ahead, opened lazily on first call, answers reads and refuses writes with the existing two-version message | `[integration]` |
| FR5 | must NOT withhold write tools from `tools/list` — they stay listed and refuse | `[unit]` |
| FR6 | A directory holding `.dpm/dpm.sql` and no database answers a read tool from the dump's rows | `[integration]` |
| FR6 | The same call with no dump present returns an empty result rather than an error — the decoy that stops "answers from the dump" passing by returning anything at all | `[integration]` |
| FR6 | must NOT restore over an existing database: a database holding a distinguishable row keeps it when the dump lacks it | `[integration]` |
| FR7 | The verdict function returns database-moved / dump-moved / both-moved / adopt / unknown for the five marker states | `[tdd] [unit]` |
| FR7 | Each verdict names its own fix in the guard's output, driven in a real repository | `[integration]` |
| FR7 | must NOT name publish when the dump moved | `[integration]` |
| FR7 | An absent marker over a database that agrees with the dump writes the marker and reports clean | `[integration]` |
| FR7 | must NOT name a single fix when the marker is absent and the two disagree — both are named, with what each would do | `[integration]` |
| FR8 | A dump that does not survive its own restore is refused by the import and by the merge, with one message from one implementation | `[integration]` |
| FR8 | must NOT leave the original database replaced when a restore fails — the staging file is gone and the original still opens | `[integration]` |
| FR8 | Clone → first open restores → publish → commit passes the guard | `[feature]` |
| FR8 | Pull → guard names import → import → commit passes the guard, and the pulled rows are present | `[feature]` |
| FR10 | A first open that restored from a dump writes exactly one line to stderr naming the restore; an ordinary create writes none | `[integration]` |
| FR10 | must NOT write any of it to stdout | `[integration]` |
| FR12 | A read-only server whose first tool call finds no database refuses with SQLite's own error rather than creating one | `[integration]` |
| FR12 | After that refusal, no `.dpm/` directory, no `.gitignore` and no database file exist | `[integration]` |
| FR12 | must NOT restore from a dump under read-only: a directory holding `.dpm/dpm.sql` and no database still yields the refusal, and no database is written | `[integration]` |
| FR12 | The same spawn and the same call **without** the read-only flag does create the database — the decoy that stops the three absences above passing on a server too broken to reach the filesystem at all | `[integration]` |
| FR9 | The README's setup carries no ignore-line instruction and still carries the pre-commit symlink step | `[unit]` |
| FR11 | The README names `dpm-merge`, says when to run it, and shares one constant with the guard's reconcile message rather than a second copy of the command string | `[unit]` |
| NFR1 | A clean spawned session writes nothing to stderr | `[integration]` |
| NFR1 | Launch performs no filesystem write, and migrations run once per session rather than per request — counted through an injected recorder, not a timer | `[unit]` |
| NFR2 | `process.env` is read in `src/` only for `DPM_DATABASE`, with a floor asserting the check finds the known sites | `[unit]` |
| NFR3 | An existing database with rows hashes identically before and after a read-only lazy session, and answers the same reads | `[integration]` |
| ENV1 | The suite runs from a clean checkout with no install step; both dependency maps are empty | `[integration]` |
| ENV2 | The Node floor check and the FTS5 probe both pass in development | `[unit]` |
| ENV3 | The git fixture creates a repository, commits, and produces a conflicted `dpm.sql` | `[integration]` |
| ENVX1 | No import in `src/` or `bin/` resolves outside `node:` builtins and relative paths, with a floor on the number of imports examined | `[unit]` |
| ENVX2 | No write in `src/` targets a path outside `.dpm/` and the projection publish already owns; the README's setup step count does not grow | `[unit]` |
| ENVX3 | The static import graph from `bin/dpm-mcp.js` reaches no `node:child_process`, asserted as `server.test.js` already asserts the `node:sqlite` graph | `[unit]` |

### Integration Boundaries

1. **Transport ↔ tool table** — the resolver seam in `methods()`, where `tools/list` and `tools/call` stop sharing a list.
2. **`open()` ↔ filesystem** — directory, ignore file, marker, database, in that order.
3. **Server ↔ dump** — restore-on-create, the one place the server reads a committed artefact.
4. **Guard ↔ marker ↔ dump ↔ database** — the three-hash comparison, and the only place a verdict is decided.
5. **Import / merge ↔ shared rebuild ↔ publish** — the extracted tail, exercised from both callers.
6. **Publish ↔ marker** — written by every publish, or the next guard run is wrong.

### Unit Testing

Unit testing of individual components is handled at the `cpm:do` task level — each story's
acceptance criteria drive test coverage during implementation.
