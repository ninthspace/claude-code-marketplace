# Read-Only Server Mode

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Date**: 2026-08-13  
**Status**: Complete  
**Blocked by**: —  
**Retro applied**: 42 · Criteria gaps · Applied — NFR1's "opening a database at the current schema version runs no migration and writes no row" is green before the work starts, because a database already at the current version is migrated by nothing; Story 1 carries a paired criterion over a database *behind* the server, where the mode and its absence differ.  
**Retro applied**: 42 · Criteria gaps · Applied — Story 2's absence criterion is paired with the same sequence run without the mode, so "no file is created" is attributable to the read-only connection rather than to spec 49, a crashed process, or anything else in the tree.  
**Retro applied**: 42 · Patterns worth reusing · Applied — the seam's two harms stay named separately throughout: this epic stops the migration, spec 49 stops the creation, and no criterion here claims the other's half.  
**Retro applied**: 42 · Scope surprises · Applied — the peer-spec relationship has no field to live in, so the landing-order dependency on spec 49 is written into this epic's Notes rather than left to `**Blocked by**`, which can only name a sibling epic.  
**Retro applied**: 42 · Codebase discoveries · Applied — spec 47's AD1–AD11 were read as this epic's architecture; AD5's Node floor and AD11's explicit-regeneration rule both bear on what a read-only launch may and may not do.  
**Retro applied**: 43 · Codebase discoveries · Applied — before changing what a launch does, grep the suites for fixtures that *consume* migrate-at-launch and seed-at-launch rather than for tests that name them; `spine-integration.test.js` and anything opening a server-migrated database are the first places to look. Informs Task 1.2's exploration.  
**Retro applied**: 43 · Codebase discoveries · Applied — Story 2's "diagnostic naming the missing database path" is asserted against `error.data`, never `error.message`, which `rpc.js` holds at the JSON-RPC code's standard text and which would pass for any refusal at all.  
**Retro applied**: 43 · Testing gaps · Applied — Story 1's "serves `readOnlyTools`" is asserted against something `readOnlyTools` does not itself mediate: the mutating tool names absent *by name* and the read tools present *by name*, not "the two lists differ" or "the count is lower".  
**Retro applied**: 44 · Patterns worth reusing · Applied — both must-NOTs get a remove-the-condition control. Story 2's is already in the criteria as the paired positive; Story 1's must-NOT gets one built the same way rather than left as a code inspection.  
**Retro applied**: 45 · Codebase discoveries · Applied — the two write sweeps are token sweeps and cannot see a write through a helper, so they cannot prove the read-only path writes nothing; Story 2's must-NOT is asserted behaviourally against the filesystem after the sequence, not by grepping the modules on that path.

`bin/dpm-mcp.js` calls `start()`, which migrates the database and re-seeds vocabulary before a single
tool is called. Opening the board after a plugin update would therefore migrate every registered
project's database, leaving each diverged from its committed `.dpm/dpm.sql` — and the pre-commit guard
would refuse the user's next commit in a repository they had not touched. This epic closes that at the
connection, and produces the refusal FR11 reads to learn that a project has no database at all.

## Launch dpm's server in read-only mode
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: NFR1, ENVX2

**Acceptance Criteria**:

- With `DPM_READ_ONLY=1`, the server opens the connection with `readOnly: true`, skips `migrate` and `applyVocabulary`, and serves `readOnlyTools` [integration]
- The equivalent CLI flag produces the same mode as the environment variable, asserted on the same three observables [integration]
- With the read-only mode active, a mutating tool call is refused by the server [integration]
- With the read-only mode active, opening a database at the current schema version runs no migration and writes no row [integration]
- Opening a database whose schema is **behind** the server read-only leaves the file byte-identical and its `schema_version` unchanged, and the same open without the mode migrates it — the pair is what separates the mode from a database that needed nothing [integration]
- must NOT — the refusal comes from a check inside a tool handler rather than from the connection and the served tool set, so an ordinary launch could forget it [integration]
- The read-only mode is implemented with `node:sqlite` alone, and dpm's `package.json` dependencies stay empty [unit]

### Resolve the mode once at launch
**Task**: 1.1  
**Description**: `DPM_READ_ONLY` and the equivalent CLI flag resolved to a single boolean in `main()`, before the connection is opened. One resolution point is what makes the flag-equals-env criterion a fact about the code rather than two parallel paths that happen to agree today.  
**Status**: Complete

### Open read-only, and skip migrate and seed
**Task**: 1.2  
**Description**: `openConnection(location, { readOnly: true })`, with `migrate` and `applyVocabulary` not called rather than called and short-circuited. `start()` is the composition of the three, so this is a branch at `start()`'s level, not inside it — a skipped-but-invoked migration is the shape that reintroduces a write on some future edit.  
**Status**: Complete

### Serve `readOnlyTools` for the session's lifetime
**Task**: 1.3  
**Description**: The mutating tools are absent from the served set, not present-and-guarded. `readOnlyTools` already exists for the version-ahead path, so this is a second entry point to it. NFR1's must-NOT is the whole point of this task: a handler-level check is a discipline, a missing tool is a property.  
**Status**: Complete

### Write tests for Story 1
**Task**: 1.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The migration-skip pair needs a fixture database deliberately behind the current schema version — build it by migrating to version *n−1* rather than by editing a committed file, so it stays behind as migrations are added.  
**Status**: Complete

**Retro**: [Codebase discovery] `baseline.test.js`'s NFR2 sweep pinned the environment reader list to exactly `['src/db/location.js']` with `examined === 1`, so the second sanctioned variable failed it on the first task — and the repair that widens the allowed list is the weak one: a module taking `env = process.env` and indexing it by an exported constant appears in the file list, contributes nothing to the count, and reads the environment in a shape the sweep cannot attribute to any name, so the variable is read by name statically and the list and the count are now asserted equal.  
**Retro**: [Pattern worth reusing] NFR1's own criterion — no migration and no row written at the current schema version — is satisfied by any database that needed nothing, and what rescues it is a fact about `migrate()` rather than anything in this epic: it drops and recreates the retirement guards on *every* open, so an ordinary open of the same untouched file is **not** byte-identical and the read-only one is. The discriminator for a vacuous criterion was already in the tree, and finding it took reading what the unmodified path does rather than adding a fixture.  
**Retro**: [Codebase discovery] `capability.js` claims its FTS5 probe answers on a read-only connection because it builds in `temp.`, and the first reach at it appeared to disprove that — `vtable constructor failed` — which turned out to be a probe naming its table and its column the same thing, a failure a writable connection gives identically. The claim is true, verified against a real database on Node 22.18. **A capability probe written for a test is a probe that can be wrong in ways the thing under test is not**, and the control that settles it is running the same statement against the connection the claim is not about.

---

## A missing database refuses, and the refusal is legible
**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR3, FR11, ENVX3

**Acceptance Criteria**:

- A server spawned read-only against a missing database refuses with `ERR_SQLITE_ERROR` and creates no file, driven as the sequence board code would perform: spawn, then call a read tool [integration]
- The same spawn-then-call sequence **without** the read-only mode creates the file, so the absence is attributable to the mode rather than to anything else in the tree [integration]
- The refusal reaches the caller as a diagnostic naming the missing database path, not as an unhandled exit of the server process [integration]
- must NOT — the read-only path creates `.dpm/`, `.dpm/dpm.db`, or an ignore file in a project that has none [integration]

### Let SQLite's refusal be the answer
**Task**: 2.1  
**Description**: No existence pre-check on the server side. AD1 makes SQLite's own refusal on a missing file the mechanism that supplies FR11's state; a pre-check would produce a different error class, and the board would then be reading dpm's opinion rather than the file system's. FR3's "the board confirms `.dpm/dpm.db` is present before spawning" is the board's own guard and belongs to 48-02.  
**Status**: Complete

### Surface the refusal as a named diagnostic carrying the path
**Task**: 2.2  
**Description**: The error reaches the client as a response, with the attempted path in it. A server that exits on the exception is FR11's *third* state — "a server that fails to start" — and would collapse two distinct states the board is required to tell apart.  
**Status**: Complete

### Write tests for Story 2
**Task**: 2.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The paired positive is the load-bearing one: run the identical spawn-then-call sequence with the mode off and assert the file *does* appear.  
**Status**: Complete

**Retro**: [Codebase discovery] `rpc.js` puts only `error.message` on the wire, so a classification kept on the error object as `code` reaches no client at all — which makes FR11's "distinct named state" a property of the *message text* rather than of the error. The state was correct in process and absent over the transport, and the only thing that found it was driving the real binary rather than `main`. **An error's shape in process is not its shape to a caller**, and any criterion about what a client can tell apart has to be asserted on what crosses the boundary.  
**Retro**: [Testing gap] The must-NOT — "creates `.dpm/`, `.dpm/dpm.db`, or an ignore file" — reads like something the two existing write sweeps would catch, and neither can: both are token sweeps over module source and neither follows a call. Asserting it against `readdirSync` after the sequence is what makes it a fact about the run. The mutation that proves the difference is moving the read-only branch below the mkdir preamble: the sweeps stay green, the directory listing does not.  
**Retro**: [Pattern worth reusing] Story 2's paired positive runs in the *same directory* as the arm it controls, one after the other, so the only difference between the two is the variable — not the fixture, not the working directory, not the ordering of anything else. A control built in its own directory would have been a second experiment; built in the same one it is the same experiment with one term removed.

---

## Notes

**Sized for the 49-first landing order.** AD1's second Consequence gives two orders. Under 49-first —
the order agreed on 2026-08-13 — this amendment reduces to the read-only connection, the skipped
migration and seeding, and the refusal FR11 reads; nothing here has to prevent a file being created,
because nothing creates one. Under the other order the same two stories stand and 49's FR12 becomes the
requirement that its lazy open does not reintroduce the create on this path. Either way the criteria are
unchanged; only the ambient risk differs. There is no field for a cross-spec dependency, which is why
this is prose — `**Blocked by**` can only name a sibling epic.

**Why Story 2's paired positive still discriminates under 49-first.** Spec 49 defers creation to the
first tool call rather than removing it, so a spawn-then-*call* sequence with the mode off does create
the file. That is exactly why the spec's FR3 criterion names the sequence — a spawn alone would create
nothing under either mode and the assertion would pass on a broken flag.

**One criteria gap left in the spec deliberately.** NFR1's "opening a database at the current schema
version runs no migration and writes no row" is satisfied by any database that needed no migration,
which is every database at the current version. It stays as written in the spec and in this epic's
criteria, with the discriminating pair added beside it rather than replacing it. Flagged to Chris at the
Step 3 gate; the remedy, if wanted, is `/cpm:pivot` over spec 48 rather than an edit from here.

**Step 3c — integration testing story: skipped.** The spec names *Server ↔ SQLite, in read-only mode* as
an integration boundary and states its boundary test is negative — opening runs no migration and writes
no row. That test is Story 1's fourth and fifth criteria, driven against the real `bin/dpm-mcp.js`. The
two stories are sequential rather than components that must interoperate, and there is no third party
here for a cross-story story to exercise: the board is the consumer and it does not exist yet. Its side
of this seam is covered by 48-02's spawn criteria and 48-06's rendering of all three failure states.

**ENVX3 is split across two epics on purpose.** Its server half — no write to a project that has none —
is Story 2's must-NOT. Its board half, "a registered project on a read-only filesystem renders its state
without error", needs a renderer and lives in 48-06.
