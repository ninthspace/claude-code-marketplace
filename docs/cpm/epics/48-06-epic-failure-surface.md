# Failure Surface: Named States and Proven Non-Mutation

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Date**: 2026-08-13  
**Status**: Complete  
**Blocked by**: 48-01, 48-04  
**Retro applied**: 42 · Criteria gaps · Applied — FR11 names four states and asserts three, and nothing asserts that any two of them are distinguishable; Story 1's fifth criterion reconciles the rendered set against FR11's enumeration, because "a server that exits immediately" and "a Node below dpm's floor" are the same observable unless something separates them.  
**Retro applied**: 42 · Criteria gaps · Applied — FR10's must-NOT is a sweep over a verb set that could be empty; Story 3 derives the set from the difference between the server's full tool list and its read-only set, and fails when that difference is empty.  
**Retro applied**: 42 · Criteria gaps · Applied — FR10's non-mutation criterion names the database file, and FR10's own text says "no file under a registered project is written — `.dpm/` included"; Story 3 compares the whole tree, because a board that wrote `.dpm/dpm.sql` would pass the criterion as the spec states it.  
**Retro applied**: 42 · Patterns worth reusing · Applied — the failure states are decomposed before being rendered, exactly as the create-and-migrate seam was; three of the four have the same symptom (no data) and only a decomposition makes them separately remediable.  
**Retro applied**: 47 · Codebase discoveries · Applied — Story 1 classifies each state from what reaches the board over the transport (the spawned binary's stderr, the JSON-RPC error's message text), never from an in-process error object; Task 1.4's Node-floor refusal text is taken from dpm's own source rather than transcribed.  
**Retro applied**: 47 · Testing gaps · Applied — Story 3's non-mutation proof is a whole-tree file set and content hash across a real full board session; any source-level sweep bounds the source only and is never presented as the proof.  
**Retro applied**: 49 · Testing gaps · Applied — Task 3.3's floor is asserted on nothing-against-nothing: a planted empty difference between the server's full and read-only tool lists must fail, since once the derivation works the live surfaces cannot distinguish a real sweep from a vacuous one.  
**Retro applied**: 50 · Testing gaps · Applied — every must-NOT here is asked what would have to exist for it to fail; Story 2's containment needs each failure kind actually present beside a healthy project, and Story 3's sweep needs a non-empty verb set plus a planted call it catches.  
**Retro applied**: 48 · Patterns worth reusing · Applied — Story 3 keeps both halves, the derived verb sweep bounding what the board's code can call and the whole-tree comparison bounding what the run did, with neither offered as the whole of FR10's proof.  
**Retro applied**: 51 · Testing gaps · Applied — every planted mutation is run over the whole board suite (and `node --test` in `dpm/` when the mutation is in dpm's own code), and a surviving mutation is treated as a question about the producer before it is treated as a missing assertion.

FR10 and FR11 are the two requirements a user notices only when something is wrong: observing a project
must leave it byte-identical, and a project the board cannot read must say so, by name, with its remedy,
without taking the other projects with it. The property FR10 asserts holds from 48-02's first line of
code; what this epic delivers is the proof, and the four states that make a failure legible.

## The four named per-project states
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR11, ENV2

**Acceptance Criteria**:

- A project with no `.dpm/dpm.db` renders a named state carrying its remedy [integration]
- A database whose schema is ahead of the server renders a distinct named state [integration]
- A server that exits immediately renders a third, distinct named state [integration]
- With a Node below dpm's floor, the executable's refusal is captured and rendered per FR11 [integration]
- The four states are distinct from one another, reconciled against FR11's enumeration so a state that collapses into another fails [unit]

### Classify each failure into its named state
**Task**: 1.1  
**Description**: The classification is the story. Three of the four arrive as the same symptom — a project with no data — and the inputs that separate them are different: an absent file, a `migrated.ahead` reply, a process that exits, and a refusal on stderr naming a version. 48-01's Story 2 is what makes the first of these arrive as a diagnostic rather than as a crash, which is why that epic is a blocker.  
**Status**: Complete  
**Note**: Two new states — `schema-ahead` and `node-below-floor` — and one place that decides them: `state_of(line)` over `DIAGNOSTIC_STATES`, run by `MCPClient._diagnose` as stderr arrives, first match winning so a later warning cannot rename a cause the user is already reading. **The task's premise that the skew arrives as a `migrated.ahead` reply was wrong, and the correction is the story's real finding**: nothing about an ahead database crosses the protocol channel at all. The server serves it read-only and says so on stderr; `tools/list` is byte-identical either way, and the only tools that behave differently are the write tools FR10 forbids the board from calling. So the classification reads stderr — the one place in the board that reads it for meaning, and it still never becomes data (NFR6): a signature names a *state*, never a row, a count or a title. The pool is where both halves land: a spawn that never spoke protocol is classified after `drained()` (deterministic, because the process is gone and the drain ends at EOF), and every subsequent read checks the running server's `named_state`, because the diagnostic is written when the database is first opened — the first `tools/call`, not the handshake.  
**Gap**: nothing but stderr distinguishes a schema-ahead project. If dpm ever reports the skew over the protocol — a field in the handshake, a read tool that answers with the schema version — that is the better signal and this should move to it.

### The remedy per state
**Task**: 1.2  
**Description**: FR11 requires the state to carry its remedy, and the four remedies are unrelated: create a database, upgrade the plugin, read the server's stderr, upgrade Node. A state without its remedy is a slightly better error message.  
**Status**: Complete  
**Note**: `REMEDIES` is keyed on the state and is the only place one is written, so a state added with no remedy fails Task 1.3's reconciliation instead of rendering a row that names a problem and stops. What used to be passed to `Unreadable` as a remedy — the project's path, the tools that disagreed — is now `detail`: that is context belonging to the occurrence, and a remedy written at the raise site is a remedy *per occurrence*, which no reconciliation can hold to an enumeration. **Every remedy is short because a Miller column clips rather than wraps**; the first drafts were sentences, and the row rendered `no-database: run a dpm skill in the`, which is worse than no remedy for the user who thinks they read it. The detail rides on the CLI's full-width row (`board.py list` prints `str(state)`) and is what carries dpm's own Node refusal, both versions included. `ProjectView` gained `remedy` rather than looking it up: `board_view` derives nothing, and a lookup would make the row's text depend on a table it would have to import.

### The four-way distinctness check
**Task**: 1.3  
**Description**: Reconciled against FR11's enumeration rather than asserted pairwise, so a fifth state added later is covered without an edit. The Node-floor and failed-to-start cases are the pair most likely to collapse: below the floor, the executable refuses and exits.  
**Status**: Complete  
**Note**: Three checks, and the distinctness one is over the **rendered row** rather than over the names: two states are distinguishable only if what they put on screen differs, so `style_collisions` — 48-04's collision helper, generalised from styles to whatever a state renders as, since the rule is the same one — is driven over `{state: ProjectView(...).label}`. The enumeration is reconciled in both directions with a floor (retro 49): a state with a remedy that nothing requires fails as loudly as a required state with none, and `reconcile({}, {})` must complain, because nothing-against-nothing is the only case a set difference cannot fail on. The requirement's own side is *read from the spec*, not remembered — FR11's four phrases have to still be in its body — and a third check sweeps every `Unreadable(CONSTANT, …)` in the board's source, so a state raised on a path these tests never drive is still held to the pair.

### Write tests for Story 1
**Task**: 1.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The Node-floor case needs a `PATH` the test controls with an old-enough Node, or a stub that reproduces the executable's refusal exactly — the assertion is on the rendered state, so the second is sound only if the refusal text is taken from dpm's own source rather than transcribed.  
**Status**: Complete  
**Note**: `tests/test_states.py`, 10 tests; board suite 183 → 193, dpm's Node suite unchanged at 707. Each condition is *produced*: a directory with no database, a real fixture database with a `schema_version` row above the server's own read by the real `bin/dpm-mcp.js`, a server that exits before the handshake, and a `node` stub that calls dpm's **own** `assertNodeFloor('20.0.0')` and writes what it throws — so the refusal is dpm's sentence and not a transcription, and the floor version the assertion looks for is read out of `node-floor.js` too. A second reconciliation checks that both diagnostic signatures still appear in dpm's source, which is what makes a rewording over there fail over here rather than silently retiring a state. Five planted mutations, each failing: the Node floor mapped to `server-failed`; a running server's state never checked; the row dropping the remedy; the detail falling back to the client's symptom instead of the server's own line; and — in dpm — the read-only branch not reporting the skew.

---

## One unreadable project never takes the board down
**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: NFR2, FR11

**Acceptance Criteria**:

- With one project unreadable, every other registered project still renders its state [integration]
- must NOT let any of the three prevent the remaining projects from rendering [integration]
- Each of the four failure states is exercised in a mixed registry, not only the missing-database one [integration]

### Per-project error containment
**Task**: 2.1  
**Description**: A failure is contained to its own row, per NFR2. The containment boundary is the per-project read, and the case that escapes it is the one raised off the UI thread — a worker exception that is never awaited surfaces somewhere else entirely, or nowhere.  
**Status**: Complete  
**Note**: One catch-all arm on each of the two survey paths — `survey_project` for the browser and `_survey` for `list` — mapping anything the pool did not name to `SERVER_FAILED` with `{type}: {message}` as the detail. The named arms above them were already there; what was missing is every *other* way a read can end, and in the browser each of those is raised inside a worker, where an escape is not a traceback in a row but the whole app coming down over one project in a registry of ten. The pool now also closes a client before naming a failed spawn, so a project that renders a state for the rest of the session is not also holding a process open.  
**Gap**: the arm was first written as `except Exception` *above* an `except asyncio.CancelledError: raise`, and the re-raise was dead code — `CancelledError` has been a `BaseException` since Python 3.8, so `Exception` never caught it. Removed rather than kept as documentation; what survives is the assertion that a cancellation still propagates, which is what fails if anyone widens the arm to `BaseException`.

### Write tests for Story 2
**Task**: 2.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The registry holds a healthy project *and* each failing kind, and the assertion is that the healthy one renders its real state — not merely that the board did not crash.  
**Status**: Complete  
**Note**: `tests/test_containment.py`, 4 tests; board suite 193 → 197, dpm's Node suite unchanged at 707. **All four states are in one registry, which needed a `node` that fails differently per project**: `node` belongs to the pool and not to the project, so a registry holding a healthy project *and* one whose Node is below dpm's floor cannot be built by configuring the pool — the stub dispatches on the working directory the pool spawns in, and dpm's own refusal is still what it emits. The healthy project is registered **last**, behind all four failures, and the assertion on it is its real figure (derived from the fixture's own content) plus its own epics painted in the column beside it, reached with the keyboard past the four rows the board could not read. Story 1's producers moved to `tests/support/failures.py`, which is what both stories now build their conditions from. Four planted mutations, each failing: the browser's catch-all narrowed; it widened to `BaseException` (the cancellation test's only job); the CLI's catch-all narrowed; and a survey that reads a healthy project and reports nothing of it — caught by this story's test and by nothing else in the suite.  
**Note**: `tests/test_attach.py`'s `use()` helper was flaky at about one run in five — a fixed 0.4s sleep after `send-keys`, betting on how long a shell takes to start before tmux records the activity. Found while running a mutation over the whole suite (retro 51) and confirmed pre-existing on an otherwise untouched tree. It now retries until tmux's own `window_activity` says the session is strictly ahead of every other, and failed nothing in 8 consecutive runs.

---

## Proven non-mutation
**Story**: 3  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR10

**Acceptance Criteria**:

- After a full board session over a fixture project, the database file's hash, size and mtime are unchanged [integration]
- The project tree's whole file set and content hashes are unchanged, `.dpm/` included — not only the database [integration]
- must NOT call any tool whose name is a mutating verb, in any code path [unit]
- must NOT — the mutating-verb check passes over an empty verb set; the set is derived from the tools a read-only server refuses [unit]

### The full-session non-mutation fixture
**Task**: 3.1  
**Description**: "A full board session" is the operative phrase: browse every column, open every preview kind, run the palette, trigger a search. A session that touched three screens proves nothing about the fourth.  
**Status**: Complete  
**Note**: `tests/support/session.py` — `run(root)` snapshots the project, drives one session over it and snapshots it again. Two things make it *provably* full rather than as full as whoever wrote it remembered. The column walk is enumerated from the selection — every project, every epic under each, every story under each, with focus moved by the arrow keys so the focus actions go through it too — rather than a plausible number of `down` presses over a fixture that grows. And it runs the board's own `COMMANDS` table and reports back which actions it ran, reconciled in both directions against a `NOT_IN_A_SESSION` exclusion list carrying a reason each: `quit` ends the session the driver is inside, `register` opens a modal, `unregister` takes the row off the board. **48-07's search is therefore already in scope**: an action added to the table is exercised here or excused, and neither happening fails.  
**Gap**: the task names "trigger a search" and there is nothing to trigger yet — search arrives in 48-07. The reconciliation above is what makes that arrive covered rather than remembered.

### Whole-tree comparison
**Task**: 3.2  
**Description**: File set and content hashes across the project, not the database alone. FR10's text says "no file under a registered project is written — `.dpm/` included", and a board that regenerated `.dpm/dpm.sql` would pass the database-only assertion.  
**Status**: Complete  
**Note**: `snapshot(root)` is path → (sha256, size, mtime_ns) for every file under the project, and all three are compared because they fail differently — the mtime is the one that catches a write producing identical bytes, which is exactly what re-running a migration or regenerating a projection looks like. Appeared, vanished and changed are reported separately rather than as one dict comparison, because they are different faults. **The fixture had to be furnished first**: built through the write tools it holds `.dpm/` and nothing else, so "no file under a registered project is written, `.dpm/` included" was true of a project that had nothing else in it. It now carries `.dpm/dpm.sql`, two documents under `docs/` and a README — each a file something could plausibly rewrite — and the comparison asserts they were all there before it starts.

### The derived mutating-verb sweep, with its floor
**Task**: 3.3  
**Description**: The verb set comes from the difference between the server's full `tools/list` and its read-only set, so a mutating tool added to dpm later is swept without an edit here. The floor is what stops an empty difference reading as a clean sweep.  
**Status**: Complete  
**Note**: `surfaces(root)` returns what a read-only server advertises **and** the subset it refuses with dpm's own read-only sentence, that sentence being read out of `src/server/read-only.js` rather than transcribed. 181 advertised, 87 refused; the write verbs come out as adopt, allocate, create, delete, publish, retire, update and the read verbs as check, list, preview, read, search — so 48-07's search is on the safe side of the line by derivation rather than by anyone's say-so. The sweep has two arms over that one set: `SURFACE` (what the call sites declare) and every string literal in the board's modules, the second being the one that covers a bare tool name passed to `pool.read` on a path no test runs. The floor is bounded on both sides — non-empty, and a *proper* subset, since a signature matching any refusal at all would name every tool — and the planted control is built from the tool the derivation named, so it cannot outlive a rename.  
**Amendment (2026-08-15)**: the stated derivation is empty by construction and the story's fourth criterion is amended to the one below it. A read-only server advertises **every** tool and refuses at call time — deliberately, per `src/tools/index.js`: an absent tool answers with *Method not found*, which is what a client sees when a server is broken, and tells the user nothing about the reason that applies. Measured: 181 tools advertised either way, difference empty. The derivation is now behavioural and one layer down — the tools a read-only server refuses *with dpm's own read-only sentence* — which keeps the intent (nothing transcribed, a mutating tool added to dpm later is swept without an edit) and keeps the floor meaningful.

### Write tests for Story 3
**Task**: 3.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The floor is checked on a planted empty verb set, since once the derivation works the live surfaces cannot distinguish a working sweep from a vacuous one.  
**Status**: Complete  
**Note**: `tests/test_non_mutation.py`, 5 tests; board suite 197 → 202, dpm's Node suite unchanged at 707. Five planted mutations, each failing: a cache written into `.dpm/` (caught by the tree comparison *and* by 48-02's static opener sweep); an `os.utime` on the database, changing nothing but the mtime — **caught only by the whole-tree and database comparisons**, which is the clearest evidence the two halves of the proof do different work, since the static sweep cannot see it at all; the read-only signature no longer matching dpm's source, which empties the derivation and fails both the floor and the sweep; a `declare("update_epic", …)` in `status_model`; and a session that stops after its first action, which is the one the comparisons alone would report as a clean pass.

---

## A read-only filesystem is not a failure
**Story**: 4  
**Status**: Complete  
**Blocked by**: Story 1, Story 3  
**Satisfies**: ENVX3

**Acceptance Criteria**:

- A registered project on a read-only filesystem renders its state without error [integration]
- Its epics, stories, progress and previews render as they do for a writable project — the read-only filesystem changes nothing the user sees [integration]

### Write tests for Story 4
**Task**: 4.1  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Deliberately test-only: if this story needs production code, Story 3 or 48-01 is wrong, and finding that out is the point. The second criterion is the one that discriminates — "renders without error" is also true of a project rendered as a failure state.  
**Status**: Complete  
**Note**: `tests/test_read_only_filesystem.py`, 3 tests; board suite 202 → 205, dpm's Node suite unchanged at 707. **No production code, which was the story's own prediction.** The project is made unwritable by taking the write bits off it rather than by mounting a filesystem — a real mount needs privileges this suite does not have and a different incantation per platform — and the substitution is kept honest by a floor that asserts the *operating system* refuses a write, not that a mode bit is set, since a suite running as root would write straight through it. The discriminating criterion is an equality against a writable copy of the same built fixture: row, Epics column, Stories column, an epic's preview and a story's preview, all five. Three planted mutations, each failing: the fixture not actually made read-only (floor only); the board writing a cache into the project; and `read_only_environment` no longer setting `DPM_READ_ONLY`, which renders the project `server-failed` — the wrong answer arriving quietly, and the one this story exists to catch.

---

## Notes

**Story 1 changed dpm's server, and FR11 could not be met without it.** A board launches every
server read-only (AD1), and the read-only branch of `src/server/index.js` never reaches `migrate()`
— which is where `migrated.ahead` is computed and where the skew was reported. So the one mode the
board uses was the one mode that said nothing about a database written by a newer plugin: the
project rendered as an ordinary one holding whatever tables the older server understood, which is
the same observable as a project with less work in it. The branch now compares `currentVersion()`
against `targetVersion()` — two reads, no write, which is what makes it available in a mode whose
whole point is inertness — and logs the same sentence, extracted as `aheadMessage()` so the two
bring-ups cannot drift apart. dpm's suite is unchanged at 707.

**Step 3c — integration testing story: skipped, because Story 2 is one.** NFR2's containment is inherently
cross-cutting and Story 2 exercises every failure kind from Story 1 in a registry beside a healthy project.
A further integration story would be the same test with more projects in it. The seams this epic touches —
Board ↔ MCP server, Server ↔ SQLite read-only — are covered by 48-02's Story 6 and 48-01's Story 1
respectively; nothing here re-verifies them.

**FR11 names four states and asserts three.** Its body enumerates a missing database, a schema ahead of the
server, a Node below the floor and a server that fails to start; its criteria cover the first, second and
fourth, with the Node-floor case appearing only as ENV2's criterion. Nothing in the spec asserts that any
two are distinguishable, and the Node-floor and failed-to-start cases are the same observable — below the
floor, the executable refuses and exits. Story 1's fifth criterion is what separates them.

**FR10's criterion names the database and its requirement names the tree.** "After a full board session the
database file's hash, size and mtime are unchanged" is silent about `.dpm/dpm.sql`, about the registry's
own writes landing in the wrong place, and about a stray lock file. FR10's text is not: "no file under a
registered project is written — `.dpm/` included". The whole-tree criterion is added rather than
substituted, so the spec's row stays verifiable as written.

**The mutating-verb sweep is derived, not listed.** A transcribed list of mutating verbs is correct on the
day it is written and silently narrows every time dpm gains a tool. Deriving it from the difference between
the full and read-only tool sets makes it grow by itself — and makes the floor necessary, since an empty
difference means the two sets are identical, which is a much larger problem reported as a pass.

**Story 4 is test-only by design.** ENVX3's server half is 48-01's Story 2 must-NOT; its board half needs no
new behaviour if the board genuinely writes nothing and the registry genuinely lives under XDG. Writing it
as a test-only story makes that claim falsifiable: if production code turns out to be required, something
upstream is writing where it should not be.

**FR10's property is maintained from 48-02 onward; only its proof is here.** No story in this epic makes the
board non-mutating — 48-02's Story 3 must-NOTs and 48-01's read-only mode do that. What is delivered here is
the evidence, which is why the epic is late in the order rather than early.
