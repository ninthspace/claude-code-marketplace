# The Sync Marker and the Guard's Directional Verdict

**Source spec**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Date**: 2026-08-13  
**Status**: Complete  
**Blocked by**: 49-01  
**Retro applied**: 42 · Scope surprises · Applied — the spec's sixth integration boundary names an obligation no requirement carries ("Publish ↔ marker — written by every publish, or the next guard run is wrong"); Story 2 exists because a boundary with no criterion is built by inference or not at all.  
**Retro applied**: 42 · Criteria gaps · Applied (no additions to FR7) — FR7 already carries both must-NOTs and the adopt-path criterion, which are the discriminating cases; the addition here is a missing subject, not a weak assertion.  
**Retro applied**: 42 · Patterns worth reusing · Applied — the verdict is decomposed into five named states before any output is written, which is what lets Story 3 be a pure `[tdd]` function and Story 4 a rendering of it; the current code collapses all of them into `differs`.  
**Retro applied**: 43 · Codebase discoveries · Applied — Story 2 adds a writer under `src/`, so before the suite runs, `projection.test.js`'s `ALLOWED` set and `baseline.test.js`'s ENVX2 `DECLARED` map are re-checked, along with the fixtures that consume a publish's *outcome* without naming it — `guard.test.js`, `publish.test.js` and `parity-integration.test.js` all drive a publish and read what appeared, and a marker written at the wrong moment changes what they read back rather than failing loudly.  
**Retro applied**: 43 · Testing gaps · Applied — Story 2's "the marker equals the hash of the dump on disk" has both sides computable by one function, and the equality would hold however wrong the hash is. It is grounded on the dump text read back off disk independently of the writer, and on the guard's own clean verdict, which does not route through the marker writer at all.  
**Retro applied**: 43 · Patterns worth reusing · Applied — Story 1's ignore criterion is asserted through real `git check-ignore -v` in a test-owned repository, reading the provenance back, so a machine-level `core.excludesFile` cannot pass it for the wrong reason; the pattern's value is never compared against the constant that writes it. `tests/ignore.test.js` already holds the shape.  
**Retro applied**: 44 · Testing gaps · Applied — Story 4's four criteria all assert on one guard invocation's output and a wrong verdict fails several at once, so each test asserts the criterion it exists for *first*, and the mutation checks are judged on the failure text rather than the failure count.  
**Retro applied**: 44 · Patterns worth reusing · Applied — Story 4's two must-NOTs each get a control in the same test that flips the condition and shows the guard *does* name publish, or *does* name a single fix, when it should; without them both hold for a guard that names nothing at all.

A clean pull rewrites `.dpm/dpm.sql` and touches nothing else, so the local database is silently stale.
The guard then compares `dump(db)` against the file, reports `differs`, and names `bin/dpm-publish.js` —
which regenerates the dump from the stale database and discards the pulled rows. The guard is right that
something is wrong and wrong about which direction, and there is no information in the two files alone to
tell it: after both a pull and local work, the worktree matches `HEAD`.

## The sync marker
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: AD13

**Acceptance Criteria**:

- `.dpm/dpm.db.synced` holds the hash of the dump text at the last sync point, written and read through one module [unit]
- The marker is machine-local and already ignored by 49-01's `dpm.db*` pattern — asserted, not assumed [integration]

**Retro**: [Pattern worth reusing] The story's three tests were the *fourth* copy of a temp-directory helper and the *third* of "bring up an in-memory planning database and dump it", so the refactoring pass collected both into `tests/support/scratch.js` and `tests/support/dumps.js`, and lifted `ignore.test.js`'s `git check-ignore -v` wrapper into `tests/support/git.js` as `ignoreCheck(root)`. The duplication is not what makes this worth recording — a dump is an *input* to almost everything under test in spec 49, and three private builders is three chances for one to drift into producing something the release would never write.

### The marker module
**Task**: 1.1  
**Description**: One module, read and write. AD13 chose a file over a `sync_state` table because the dump is generated from the database, so a stored hash would end up inside the file it hashes — and excluding a table from the dump to escape that would put a special case against spec 47's NFR4, which makes byte-stability load-bearing.  
**Status**: Complete

### Write tests for Story 1
**Task**: 1.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]` and `[integration]`. The ignore assertion is here rather than assumed from 49-01: the pattern was written for the database and its WAL sibling, and the marker's coverage by it is a consequence worth pinning where the marker is introduced.  
**Status**: Complete

---

## Every publish writes the marker
**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: AD13

**Acceptance Criteria**:

- After a publish, the marker equals the hash of the dump on disk, and the immediately following guard run reports clean [integration]
- A publish that does not complete leaves the previous marker in place rather than a marker for a dump that was never written [integration]

**Retro**: [Testing gap] "A publish that does not complete" has two failure shapes and only one of them can see the ordering the task is about. `project()` throws at the *top* of `publish`, before the branch the marker write lives in — so a projection refusal leaves the previous marker whatever position the write is in, and the mutation that hoisted it to the first line of that branch passed the refusal test outright. Only a run that reached the write loop and did not finish it discriminates, and that needs the dangling-symlink fault the dump-ordering criterion already uses. The generalisable form: **before writing a test for an ordering, find the point the failure is injected at and check it is downstream of the thing being ordered.**

**Retro**: [Codebase discovery] The whole-surface sweep in `deferred-integration.test.js` broke on the new writer, exactly as retro 43 predicted — it listed `.dpm/` and filtered on a `dpm.db` prefix, so `dpm.db.synced` read as a second database. That is now the third fixture in two epics to consume a first run's or a publish's *outcome* without naming it. Closed by replacing the filter with exact set equality over the four files that directory holds, each named, which is stronger than what it replaced and fails loudly the next time something appears there.

### Write the marker from publish
**Task**: 2.1  
**Description**: Every publish, all three callers — the `publish` MCP tool, `bin/dpm-publish.js`, and `/dpm:publish` — because they share one implementation at `publish/index.js`. Written after the dump lands, so a failure between the two leaves a stale marker rather than a marker for a file that does not exist; the first is diagnosable and the second is a verdict built on a lie.  
**Status**: Complete

### Write tests for Story 2
**Task**: 2.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The guard-reports-clean half is what makes this a real assertion — a marker written with the wrong hash satisfies "a marker exists" and produces a wrong verdict on the next run.  
**Status**: Complete

---

## The five-state verdict function
**Story**: 3  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR7

**Acceptance Criteria**:

- The verdict function returns database-moved / dump-moved / both-moved / adopt / unknown for the five marker states [tdd] [unit]

**Retro**: [Scope surprise] AD13's table has five rows and the function's input space has six equivalence classes. The sixth — a *stale* marker over a dump and a database that agree byte for byte — is not in the table because the table enumerates the states that need a verdict, not the states that are reachable, and it is reachable the moment a pull brings a dump someone else published from the state this database is already in. Read off the table literally it lands on differs-from-marker on both sides, therefore *both moved*: a refused commit and an instruction to reconcile two identical files. The function answers `adopt`, and agreement is now decided before the marker is consulted at all. The generalisable form: **a decision table is a specification of the answers, not a partition of the inputs** — enumerate the input classes separately and check each one lands somewhere deliberate.

**Retro**: [Testing gap] A mutation collapsing `adopt` into `clean` failed the right assertion with the wrong sentence: the message read "was treated as a divergence" while the actual verdict was `clean`, which is not a divergence. The message had been written for the failure that was expected rather than for the assertion that was made, so it was accurate for one of the two ways that line can fail and misleading for the other. Rewritten to name what should have happened instead of the presumed cause. This is retro 44's "judge the failure text, not the count" arriving one level down — the count was right both times and only the text was wrong.

### Write tests for the verdict function
**Task**: 3.1  
**Description**: `[tdd]`, so this comes first. Five states from two comparisons — marker against the dump on disk, marker against `dump(db)` — plus the two absent-marker cases. The pair that must not collapse is *both moved* and *unknown*: both are ambiguous, and only one of them has a marker to reason from.  
**Status**: Complete

### The verdict function
**Task**: 3.2  
**Description**: A pure function over three hashes, separate from anything that renders it. That separation is what makes the five states assertable at all — today they are one `differs` produced inline where the message is written.  
**Status**: Complete

---

## The guard names the fix belonging to each verdict
**Story**: 4  
**Status**: Complete  
**Blocked by**: Story 2, Story 3  
**Satisfies**: FR7

**Acceptance Criteria**:

- Each verdict names its own fix in the guard's output, driven in a real repository [integration]
- An absent marker over a database that agrees with the dump writes the marker and reports clean [integration]
- must NOT name publish when the dump moved [integration]
- must NOT name a single fix when the marker is absent and the two disagree — both are named, with what each would do [integration]

**Retro**: [Codebase discovery] Both write sweeps — `projection.test.js`'s and ENVX2's `auditWrites` — detect a writer by grepping for `node:fs` calls in the module's own text, and every writer they had ever caught made one. The moment `src/sync/marker.js` existed, any module could touch a user's disk by calling `writeMarker` and stay invisible to both, which is exactly what the guard's adopt path does. Closed by naming the helper in both patterns and declaring `src/guard/index.js` with the root it may write under; mutation-verified by removing the token and watching ENVX2 complain that the declaration backs nothing. **The general form has no sweep-sized answer** — a token list cannot follow a call — and what keeps it honest is that each declared writer is also held to its root behaviourally.

**Retro**: [Scope surprise] The dump-moved fix names `bin/dpm-import.js`, which epic 49-04 builds. This codebase already has a rule about that: `guard-fix.test.js` carries a must-NOT whose whole content is *the named command must exist on disk*, on the grounds that help pointing nowhere is NFR6's failure looking like success. `IMPORT_COMMAND` cannot satisfy it here, and 49-04's own Story 2 criterion is written the other way round — the binary "is the command the guard's dump-moved verdict names", read from this constant. So the split was deliberate, and the cost is a one-epic window in which the guard names something a reader cannot run. Pinned by shape here, by existence there, with both halves saying so.

**Retro**: [Codebase discovery] The README described `bin/dpm-publish.js` as "the command the pre-commit guard names when it refuses a commit" — a sentence made false by this story, in a file no test reads. This is retro 43's "consumes an outcome without naming it" arriving in prose rather than in a fixture: the difference is that a fixture breaks loudly and documentation does not, so the only thing that catches it is asking, of every behaviour changed, which sentences elsewhere were describing the old one.

### Replace `differs` with the five verdicts and their fixes
**Task**: 4.1  
**Description**: Database moved names publish, dump moved names import, both moved names `dpm-merge`. The current behaviour — `differs`, naming publish in every case — is not a missing feature but an active data-loss path, because the fix it names is the one that destroys the pulled rows.  
**Status**: Complete

### The adopt-on-agreement upgrade path
**Task**: 4.2  
**Description**: Every database that exists today lacks a marker, so without this every existing project sees a verdict on its next commit. One that already agrees with its dump is not ambiguous at all: adopt silently, write the marker, report clean. Only a database already divergent at upgrade time reaches *unknown*.  
**Status**: Complete

### Write tests for Story 4
**Task**: 4.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`, driven in a real repository through 49-01's git fixture. The dump-moved must-NOT is the regression test for the defect this epic exists to close, and it should be written to fail against today's guard.  
**Status**: Complete

---

## Notes

**Story 2 is the one addition, and it is a missing subject rather than a weak assertion.** FR7's five
criteria all describe the guard *reading* the marker; nothing in the spec's Acceptance Criteria Coverage
says publish ever *writes* one. The spec knows the obligation exists — its sixth integration boundary is
"Publish ↔ marker — written by every publish, or the next guard run is wrong" — but a boundary is not a
requirement, and nothing downstream reads the boundary list. Without this story the guard would be built
against a marker that no code path maintains, and every verdict after the first would be wrong in the
same direction.

**Step 3c — integration testing story: skipped, deliberately, and the reason names another epic.** The
two journeys that cross this epic's boundaries end-to-end are *clone → first open → publish → commit →
guard clean* and *pull → guard names import → import → commit → guard clean, with the pulled rows
present*. Both are FR8's `[feature]` criteria and both are covered in
`docs/epics/49-04-epic-import-and-discoverability.md`, because neither can complete until import exists.
Writing a cross-story story here would produce the same journeys truncated at the point where they matter.

**AD13's rejected alternatives are worth keeping in view during Story 3.** A `sync_state` table puts the
hash inside the file it hashes. A row-set diff cannot decide direction, because a local deletion and a
remote addition have the same signature — it is retained as a source of diagnostic detail and deferred,
not as the verdict. Asking git cannot decide it either: after both a pull and local database work the
worktree matches `HEAD`. Each of these looks reasonable until the case that defeats it is named, which is
why they are recorded rather than left to be re-proposed.

**The marker's ignore coverage is asserted here and delivered in 49-01.** `dpm.db*` was written for the
database and its WAL sibling; that it also covers `dpm.db.synced` is a consequence, and Story 1's second
criterion pins it where the marker is introduced. 49-01's row 13 asserts the same pattern from the other
side.
