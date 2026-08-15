# Deferred Creation: Template Tool List, Lazy Open, Automatic Ignore

**Source spec**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Date**: 2026-08-13  
**Status**: Complete  
**Blocked by**: —  
**Retro applied**: 42 · Criteria gaps · Applied (no additions needed) — the spec was written after retro 42 and already carries what the lesson asks for: FR1's paired positive in the same test, FR2's registry-derived floor, FR2's names-alone decoy, FR5's listed-but-refusing must-NOT. Every criterion here is propagated verbatim.  
**Retro applied**: 42 · Codebase discoveries · Applied — AD12 rests on the finding that every build-time database read in the tool layer reads schema or seeded vocabulary and never a user row; that finding is what makes Story 1 sound, and Story 7 is what checks it held across the live seam rather than only in a comparison.  
**Retro applied**: 42 · Patterns worth reusing · Applied — the seam's two harms stay named separately: this spec stops any caller *creating* a database, spec 48 stops an observer *migrating* one, and no story here claims the other's half.  
**Retro applied**: 42 · Codebase discoveries · Applied — spec 47's AD1–AD11 and this spec's AD12–AD16 are read as the architecture for the epic; the ADR glob over `docs/architecture/` returns nothing meaningful here, and new code cites its AD by name as `dpm/src/` already does.  
**Retro applied**: 40 · Testing gaps · Applied — every sweep floor and every must-NOT decoy gets a planted input that must fail; test output is written to a file and read whole rather than piped through `head`/`tail`, so a truncated run cannot report a pass it never computed.  
**Retro applied**: 40 · Patterns worth reusing · Applied — Story 6's four sweeps are written as `audit(inputs) → complaints` functions so the tests drive the real sweep on planted sources instead of restating its rules; the Story 1 tool-list comparison takes the same shape.  
**Retro applied**: 41 · Testing gaps · Applied — where a criterion can only pass once the fix has landed everywhere, the discriminating case is a planted source or fixture the check must complain about, not a comment asserting it would.

`main()` does two things nobody asked for: it creates `.dpm/dpm.db` in whatever directory the session
started in, and it migrates and re-seeds whatever it finds there. This epic removes the first for every
caller. The obstacle is that `spineTools(db)` reads `document_kind` at build time, so the advertised
tool list currently depends on a migrated database existing — AD12's template is what removes that
dependency without changing what is advertised.

## Build the tool list from an in-memory template [plan]
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR2, AD12

**Acceptance Criteria**:

- The template-built tool list equals the list built against a migrated file database — full `describe()` output, not names alone [unit]
- The compared list is non-empty and its length equals the registry-derived count, never a transcribed number [unit]
- `methods()` splits so `tools/list` describes the template and `tools/call` resolves the live table, with the resolver defaulting to the same list so every existing call site is unchanged [unit]
- must NOT pass on names alone — a template yielding correct names with empty input schemas fails [unit]

**Retro**: [Testing gaps] "The registry-derived count" reads as an independent floor and is not one: the template list, the file-database list and the count are all built by `spineTools`, so a registry that collapsed collapsed all three by the same amount and the equality went green over three short lists. Found by planting a two-tool return rather than by reading the criterion, and closed with a second floor taken off the seeded `document_kind` rows — four tools per kind — which `spineTools` does not mediate.

### Bring up the `:memory:` template through the existing `start()`
**Task**: 1.1  
**Description**: The same `start()` — `openConnection` → `migrate` → `applyVocabulary` — against `:memory:`, purely to build the tool table. `cross/template.js` already does exactly this inside a handler, so the pattern is established rather than invented. Going through `start()` is also what keeps the Node-floor import-graph guard in `server.test.js` intact.  
**Status**: Complete

### Split `methods()` with a defaulted resolver
**Task**: 1.2  
**Description**: `tools/list` describes the template, `tools/call` resolves the live table. The resolver defaults to the same list, which is what leaves every existing `methods(tools)` call site unchanged — the reason this is a signature addition rather than a breaking change. `[plan]` sits on this story for this task: three modules destructure `const { db } = context` at build time, and a design that resolves eagerly would defeat the whole epic silently.  
**Status**: Complete

### Write tests for Story 1
**Task**: 1.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`. The comparison is over full `describe()` output; the floor is the registry-derived count, because a template that produced two tools would otherwise compare equal to a broken real build.  
**Status**: Complete

---

## A session that never calls a tool creates nothing
**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR1, NFR1

**Acceptance Criteria**:

- A spawned server in an empty temp dir, given `initialize` + `tools/list` then EOF, exits 0 and leaves no `.dpm/` entry [integration]
- The same spawn given one `tools/call` does leave `.dpm/dpm.db` — asserted in the same test, so a server that crashed at startup cannot satisfy the absence [integration]
- A clean spawned session writes nothing to stderr [integration]
- Launch performs no filesystem write, and migrations run once per session rather than per request — counted through an injected recorder, not a timer [unit]
- must NOT satisfy the absence by failing to serve: stdout carries a well-formed `tools/list` result whose tool count exceeds a registry-derived floor [integration]

**Retro**: [Scope surprise] The `migrated.ahead` gate had to move in this story, not in Story 5 where the epic put it: once the eager `start()` goes, `migrated.ahead` is not knowable at launch, so the decision has nowhere to stand and the server would silently lose NFR7's read-only serving. A task that *removes* a call site owns every decision that call site was making, and the breakdown split them across three stories.

**Retro**: [Codebase discovery] Three `spine-integration.test.js` tests used launch-time creation as a fixture — spawn a session with a `ping`, then open the database the server had created — and broke with `no such table: document_kind`, a message naming neither creation, nor the fixture, nor this epic. Removing a behaviour breaks whoever was quietly relying on it, and the failure surfaces in the file least likely to mention it.

### Remove the unconditional create from `main()`
**Task**: 2.1  
**Description**: The `mkdirSync(dirname(location), { recursive: true })` and the `start(location)` that follows it. This is the defect, and it is two lines; everything else in this epic exists to make removing them safe.  
**Status**: Complete

### The migration-count recorder
**Task**: 2.2  
**Description**: Counted, not timed. NFR1's criterion names the recorder because a timing assertion is flaky and answers a different question — "was it fast" rather than "did it run once".  
**Status**: Complete

### Write tests for Story 2
**Task**: 2.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The absence and its paired positive go in one test, per FR1's own criterion — separated, a server that dies at startup passes the first and the second never runs.  
**Status**: Complete

---

## The first tool call brings the database into existence
**Story**: 3  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR3  
**Retro**: [Codebase discovery] `projection.test.js`'s "nothing outside the projection writes under docs/" sweep names every writer outside `src/projection/` in an `ALLOWED` set and asserts the allowance is *spent*, so any new writer anywhere under `src/` breaks it — the second existing sweep this epic has tripped, after the launch-time-creation assumption in `spine-integration.test.js`. Accounted for rather than exempted: `src/server/ignore.js` joins the set with a behavioural guard that runs it against a test-owned directory and checks what appeared there, because a text sweep for `docs` would pass on a module that composed the path from fragments.

**Acceptance Criteria**:

- A first `tools/call` in a fresh directory returns its normal result, and both `.dpm/.gitignore` and `.dpm/dpm.db` exist afterwards [integration]
- The ignore file is written before the database is opened, driven through an injected recorder as `openConnection`'s `probe` already is [unit]

### The lazy `open()`
**Task**: 3.1  
**Description**: Directory, ignore file, database, in that order — FR3's order, and AD15's reason for it: the database never exists unignored, even briefly. The triggering call returns its normal result rather than an error, which is what makes this deferral invisible to a caller.  
**Status**: Complete

### Rebuild the tool table against the live database
**Task**: 3.2  
**Description**: On first call, per AD12. Story 1's template is what `tools/list` described; this is the table `tools/call` resolves, and Story 7 is what checks the two agree.  
**Status**: Complete

### Write tests for Story 3
**Task**: 3.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The ordering criterion uses an injected recorder on the same pattern `openConnection`'s `probe` already establishes — an existing seam with real callers, not a new one added for the test.  
**Status**: Complete

---

## `.dpm/dpm.db` is ignored without the user doing anything
**Story**: 4  
**Status**: Complete  
**Blocked by**: Story 3  
**Satisfies**: FR4, FR9, ENV3  
**Retro**: [Scope surprise] Two of this story's four tasks needed no code. 4.1's writer landed in Task 3.1, because Story 3's own criteria name `.dpm/.gitignore` and its position in the open order — the ignore file is not separable from the order it is written in. 4.2's fixture (`tests/support/git.js`) has existed since Epic 47-04 with a dozen consumers. The epic split FR4 across two stories as *write it* and *prove git honours it*, but the write could not be deferred past the story whose criteria mention it. Third instance in this epic of a task's code arriving one story early, after 5.1 in Story 2 and 3.2 in Story 2.  
**Retro**: [Pattern worth reusing] `git check-ignore -v` returns the verdict *and* names the file and pattern that produced it. Reading that provenance back is what stops a machine-level `core.excludesFile` from passing an ignore assertion for the wrong reason — the same class of false green as a test whose two sides both move together, which is why the pattern's *value* is never compared against the constant that writes it.

**Acceptance Criteria**:

- In a fresh repository, `git check-ignore .dpm/dpm.db` succeeds and `git status --porcelain` shows no entry for it [integration]
- `dpm.db-wal` and `dpm.db.synced` are ignored by the same pattern [integration]
- An existing `.dpm/.gitignore` is left byte-identical [integration]
- The README's setup carries no ignore-line instruction and still carries the pre-commit symlink step [unit]
- The git fixture creates a repository, commits, and produces a conflicted `dpm.sql` [integration]
- must NOT over-reach: `git check-ignore .dpm/dpm.sql` fails [integration]

### Write `.dpm/.gitignore` holding `dpm.db*`
**Task**: 4.1  
**Description**: Only when absent, before the database file is created. The star is load-bearing: it covers the WAL and journal siblings — `merge/main.js` already checks for `.dpm/dpm.db-wal` — and the sync marker 49-03 introduces. This implements AD4's second clause, which has had no implementation since it was written.  
**Status**: Complete

### The git fixture
**Task**: 4.2  
**Description**: ENV3. Repository, commit, and a conflicted `dpm.sql`. The conflict half is not used until 49-03; it is built here because this is the story that first needs a real repository, and building it twice is how the two versions diverge.  
**Status**: Complete

### Cut the README's ignore step, and the two tests that perform it by hand
**Task**: 4.3  
**Description**: FR9. `tests/support/git.js:56` and `first-run.test.js:62` write `.gitignore` by hand "performed exactly as it is written there" — so the step and its tests come out together. `first-run.test.js:106` asserts *set equality* on tracked files, so `.dpm/.gitignore` joins that list as a constant beside `DUMP_PATH`; missing that line is a failing suite with a misleading message.  
**Status**: Complete

### Write tests for Story 4
**Task**: 4.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The over-reach must-NOT is the one that matters most: `dpm.sql` is the committed artefact, and a pattern that swallowed it would break every clone while every other criterion here passed.  
**Status**: Complete

---

## The version-ahead gate, decided at first open
**Story**: 5  
**Status**: Complete  
**Blocked by**: Story 3  
**Satisfies**: FR5, NFR3  
**Retro**: [Criteria gaps] NFR3's criterion asked that an existing database "hashes identically" across a read-only session, and no database in this codebase can satisfy it: `migrate()` calls `createRetirementGuards()` on every open, which drops and recreates twenty-four triggers by design — measured, two consecutive opens of an untouched file give three different digests. The criterion's proxy was stricter than the requirement it maps to, whose own words are "no migration beyond what `migrate()` already does". Amended, on Chris's decision, to hash the `dump()` text and to assert `migrated.applied` empty and `vocabulary.inserted` all zero — the second pair added because a content hash alone would hold if the writes happened to be idempotent, which is not what NFR3 asks. Coverage row 19 rebound to the amended text.  
**Retro**: [Codebase discovery] `rpc.js` deliberately keeps `error.message` as the JSON-RPC code's standard text and puts the actionable detail in `error.data`. A wire-level test matching the two-version refusal on `message` asserts against the string "Invalid params" and passes for any refusal at all — the in-process tests in `naming.test.js` read the `ToolError` directly and never meet this.

**Acceptance Criteria**:

- A database whose schema version is ahead, opened lazily on first call, answers reads and refuses writes with the existing two-version message [integration]
- An existing database with rows has an identical *content* hash — the `dump()` text — before and after a read-only lazy session, applies no migration, re-seeds no vocabulary, and answers the same reads [integration]
- must NOT withhold write tools from `tools/list` — they stay listed and refuse [unit]

### Move the `migrated.ahead` decision into `open()`
**Task**: 5.1  
**Description**: It is taken at launch today and cannot be: `migrated.ahead` only becomes knowable once the file is opened, and the file is no longer opened at launch. The message is the existing one — this story moves a decision, it does not change a behaviour.  
**Status**: Complete

### Write tests for Story 5
**Task**: 5.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The must-NOT is what keeps `listChanged: false` true for an ahead database: withholding the write tools would make the advertised list wrong for the session, which is the failure Story 1 exists to prevent arriving by another route.  
**Status**: Complete

---

## The baseline sweeps
**Story**: 6  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: NFR2, ENV1, ENV2, ENVX1, ENVX2, ENVX3  
**Retro**: [Codebase discovery] Every entry point under `bin/` reaches its logic through `await import()`, so *every* `bin/` static graph is the same three files — including `bin/dpm-merge.js`, which runs `git` on every invocation. The first control written for ENVX3's walker was taken from there and passed for the wrong reason: it found no `node:child_process` because the walker cannot see past a dynamic import, not because the merge tool does not use git. The control had to move to `src/merge/main.js`, and what the check actually defends is the *hoisting* order the Node floor depends on rather than dpm's use of git as a whole. A static-graph guard's control has to be a module in the static graph.  
**Retro**: [Testing gaps] The comment stripper the three source sweeps rest on has its own test, written first, because a stripper that ate a regular-expression literal would delete code the sweeps then report clean — and every one of them would stay green. Confirmed by mutating `/\*…\*/` to `/…/`: four tests failed, and three of them were sweeps whose subject was untouched.

**Acceptance Criteria**:

- `process.env` is read in `src/` only for `DPM_DATABASE`, with a floor asserting the check finds the known sites [unit]
- The suite runs from a clean checkout with no install step; both dependency maps are empty [integration]
- The Node floor check and the FTS5 probe both pass in development [unit]
- No import in `src/` or `bin/` resolves outside `node:` builtins and relative paths, with a floor on the number of imports examined [unit]
- No write in `src/` targets a path outside `.dpm/` and the projection publish already owns; the README's setup step count does not grow [unit]
- The static import graph from `bin/dpm-mcp.js` reaches no `node:child_process`, asserted as `server.test.js` already asserts the `node:sqlite` graph [unit]

### The four static sweeps, each with its floor
**Task**: 6.1  
**Description**: `process.env` reads, imports, writes, and the `bin/dpm-mcp.js` import graph. Every one is a search that returns nothing when it is broken, which is why each carries a floor — a sweep that examined zero files reports perfect compliance.  
**Status**: Complete

### Write tests for Story 6
**Task**: 6.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]` and `[integration]`. The floors are checked on planted inputs where possible; where they cannot be, the floor is a minimum count asserted against the known sites.  
**Status**: Complete

---

## Verify cross-story integration for deferred creation
**Story**: 7  
**Status**: Complete  
**Blocked by**: Story 1, Story 2, Story 3, Story 5  
**Satisfies**: FR2, AD12  
**Retro**: [Patterns worth reusing] The seam is asserted by calling *every advertised tool* in one session and filtering the replies on `Method not found` rather than on success. Most of those calls are made with no arguments and are refused as `Invalid params` — which is a tool that *was* resolved and then declined, and is exactly the signal to ignore. Filtering on the error code rather than on the outcome is what lets a single session exercise the whole 181-tool surface, and the mutation that renamed one resolved tool was caught by name.  
**Retro**: [Codebase discovery] Calling the whole surface with empty arguments reaches `publish`, which regenerates `.dpm/dpm.sql` and the markdown projection — so a sweep session leaves more in `.dpm/` than a first run does, and the set-equality assertion written for it had to become containment plus "exactly one `dpm.db`". A test that exercises every tool is also running every tool's side effects.

**Acceptance Criteria**:

- In one session, the tool list returned by `tools/list` before any database exists is identical to the tool table resolved for `tools/call` after the lazy open — the `listChanged: false` promise held across the seam [integration]
- A session that lists tools, then makes two calls, answers both from one database opened once [integration]

### Write integration tests for deferred creation
**Task**: 7.1  
**Description**: Driven over the real `bin/dpm-mcp.js` across a whole session, because the seam only exists at runtime. FR2's own criteria compare two lists built out of band; this compares what the transport actually advertised against what it actually resolved.  
**Status**: Complete

---

## Notes

**Nothing in Stories 1–6 is added beyond the spec.** Every criterion is propagated verbatim, including
the decoys and floors: FR1's paired positive in the same test, FR2's registry-derived count and its
names-alone decoy, FR5's listed-but-refusing must-NOT, NFR1's counted-not-timed recorder, and the floors
on all four of Story 6's sweeps. The spec was written after retro 42 and carries the lesson already,
which is the difference between this epic and spec 48's, where twenty criteria had to be added.

**Step 3c — integration testing story: warranted, Story 7.** Two of the spec's six integration boundaries
are this epic's — *Transport ↔ tool table* and *`open()` ↔ filesystem* — and the first has a gap no story
covers. FR2's criteria compare a template-built list against a file-database-built list, both constructed
out of band by the test. Neither says the list the transport *advertised* at launch equals the table it
*resolved* on first call, which is precisely what `listChanged: false` promises and precisely what the
`methods()` split puts at risk. A resolver wired to the wrong list passes every criterion in Stories 1–5.

**Story 6 guards the later epics as well as this one.** NFR2's no-production-seam sweep and ENVX1's
import sweep are static checks over all of `src/`, so once written they fail for anything 49-02 through
49-05 introduces. Recorded here because a reader of a later epic will look for the assertion and not find
one — it is in this file, by design, and asserting it again there would be a second implementation of the
same check.

**ENVX2 and FR9 are split across Stories 4 and 6,** and both are about the README. FR9's substantive claim
— the ignore instruction is gone, the symlink step remains — sits with the work that makes it true in
Story 4. ENVX2's step-count assertion is a sweep and sits with the other sweeps in Story 6. Neither covers
the other.

**Task 4.3 carries a failure that looks like an unrelated break.** `first-run.test.js:106` asserts set
equality over tracked files, so adding `.dpm/.gitignore` to the tree without adding it to that constant
fails a test that mentions neither ignore files nor this epic. Named in the task because the connection is
not findable from the error.
