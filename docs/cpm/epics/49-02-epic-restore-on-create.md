# Restore on Create, and the One-Line Report

**Source spec**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Date**: 2026-08-13  
**Status**: Complete  
**Blocked by**: 49-01  
**Retro applied**: 42 · Criteria gaps · Applied (no additions needed) — FR6 already carries its own decoy, and the spec names it as one: "the decoy that stops *answers from the dump* passing by returning anything at all". FR10's stdout must-NOT is likewise already present.  
**Retro applied**: 42 · Patterns worth reusing · Applied — AD14's two directions are named separately (creating from the dump is safe automatically, overwriting is not), and the restore path here is deliberately *not* the import sequence 49-04 extracts; conflating them would apply the overwrite protections to a case that has nothing to protect.  
**Retro applied**: 43 · Codebase discoveries · Applied — Story 1 changes `open()` a third time, so before running the suite the fixtures that consume a first open's *outcome* without naming it are checked: `spine-integration.test.js`, `first-run.test.js`, `deferred-integration.test.js` and `ignore.test.js` all spawn sessions whose database appears at first call, and a restore firing when it should not would change what they read back rather than fail loudly. `projection.test.js`'s writer sweep and `baseline.test.js`'s ENVX2 declaration are re-checked if the restore adds a writer.  
**Retro applied**: 43 · Patterns worth reusing · Applied — `restore` joins `start` and `writeIgnore` as an injected seam on `open()`, and `recordOpen()` records all three into one event list, because Story 1's must-NOT is an ordering-and-condition claim: a test reading the rows afterwards would pass whether the restore ran in the right place or not at all against the right dump.  
**Retro applied**: 43 · Testing gaps · Applied — "answers from the dump's rows" is grounded on a row traceable to the dump and nothing else (a spec with a slug nothing else creates), because a seeded vocabulary row or a tool-synthesised default satisfies a bare non-empty check. Criterion 2's empty-directory decoy is the independent side.  
**Retro applied**: 42 · Criteria gaps · Applied — Story 2's "an ordinary create writes none" would hold if the reporting code never ran at all, since 49-01's NFR1 test already asserts stderr silence. Both halves go in one test over one mechanism: the same binary, two directories differing only in whether `.dpm/dpm.sql` is present. Criterion 5's stdout must-NOT is asserted on the restoring session, where a line exists that could have gone to the wrong stream.

The README has said since it was written that `.dpm/dpm.sql` "is what a checkout restores from", and no
code path performs it — `restore()` is reached only from the conflicted-merge path. A fresh clone starts
with an empty database beside a dump full of rows. Now that the database is created lazily, the create is
the natural place to close that.

## Restore from the dump when no database exists
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR6, AD14

**Acceptance Criteria**:

- A directory holding `.dpm/dpm.sql` and no database answers a read tool from the dump's rows [integration]
- The same call with no dump present returns an empty result rather than an error — the decoy that stops "answers from the dump" passing by returning anything at all [integration]
- must NOT restore over an existing database: a database holding a distinguishable row keeps it when the dump lacks it [integration]

**Retro**: [Codebase discovery] `restore()` takes a connection with **no schema** — the dump carries its own `CREATE TABLE` statements — while `start()` is `openConnection` → `migrate` → `applyVocabulary`. So the restore cannot run against the connection `start()` returns, and it cannot run after `start()` either, because `start()` creating the file is exactly what makes the restore's own condition false. There is one place it fits: `openConnection(location)` → `restore` → close, *before* `start()`, which then migrates the restored schema forward the way a clone of an older branch needs. The constraint is the design, and it is not visible from FR6's wording.

**Retro**: [Scope surprise] The task delivered a writer the epic did not mention. `openConnection(location)` creates the file before the restore can fail, and `restore()`'s own guarantee — a failed restore changes nothing — stops at the rollback: the empty file it leaves behind is precisely what makes `restoreIfMissing` decline next time. One bad dump would have produced a single error and then an empty planning database, silently, for the life of the checkout. The fix is four lines (`db.close()`, `rmSync`, rethrow) and it pulled in two sweeps — `projection.test.js`'s `ALLOWED` and `baseline.test.js`'s ENVX2 `DECLARED`. The generalisable shape: **a task that creates a file owns what happens when the thing it created it for fails**, and "the created file suppresses the retry" is a failure mode with no error message attached.

**Retro**: [Patterns worth reusing] A must-NOT of the form "X does not happen under condition C" is satisfied by a feature that never works at all. The control that closes it is to *remove* the condition and watch the same inputs produce X: the test deletes the database and re-runs the identical session against the untouched dump, which then restores. Without that line the criterion holds for a restore path that is simply broken, and nothing else in the suite would have said so.

### Restore-if-missing inside `open()`
**Task**: 1.1  
**Description**: A first open finding no database and a dump beside it restores from that dump; a first open finding a database never touches it, whatever the dump says. This is `restore()` alone, deliberately **not** the staging-file-and-rename sequence 49-04 extracts — AD14's whole argument for making this case automatic is that restoring into nothing can lose nothing, so there is no existing database to protect. Reusing the import sequence here would be harmless and misleading, and the next reader would take the protections as evidence something was at risk.  
**Status**: Complete

### Write tests for Story 1
**Task**: 1.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The decoy is the load-bearing one: a read tool returning rows proves nothing unless the same call over an empty directory returns *empty* rather than the same rows from somewhere else.  
**Status**: Complete

---

## Report the unusual first open in one line on stderr
**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR10

**Acceptance Criteria**:

- A first open that restored from a dump writes exactly one line to stderr naming the restore; an ordinary create writes none [integration]
- must NOT write any of it to stdout [integration]

**Retro**: [Testing gaps] The stdout must-NOT was written *after* the assertion that reads the session's reply, and reading a reply is also a `JSON.parse`. The mutation that sent the report to stdout was caught — but by the reply parser, with `Unexpected token 'd', "[dpm] no da"... is not valid JSON`, three assertions before the one written for it. Moving the purity check ahead of the reply read turned that into "the restoring session wrote 0 lines to stderr". Same verdict, and the difference is entirely in what the next person reads at 2am. **When two assertions can catch the same fault, order them so the specific one runs first** — a check that never executes because a generic one threw is a check whose message was never tested.

**Retro**: [Patterns worth reusing] The seam recorder records the *outcome*, not the call: `restore` fires on every open and declines on almost all of them, so a bare `'restore'` event would read identically for the case FR6 is about and the case it rules out. `restore` / `restore:skipped` in the same ordered list as `ignore` and `start:` is what makes "after the ignore, before the open, and only when the database is absent" one assertion instead of three. This is retro 43's inject-both-and-record-into-one-list, extended by one seam and one bit of state.

### The one-line report
**Task**: 2.1  
**Description**: The unusual cases only — a restore, or a database served read-only. An ordinary create is silent, per the spec's Deferred list, and NFR1's stderr-silence criterion in 49-01 depends on that staying true.  
**Status**: Complete

### Write tests for Story 2
**Task**: 2.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Both halves of the first criterion go in one test — a restore that reports and an ordinary create that does not — because "writes one line" is satisfiable by a server that writes one line every time.  
**Status**: Complete

---

## Notes

**Nothing added beyond the spec.** FR6 carries its own decoy and the spec labels it as one; FR10 carries
the stdout must-NOT. Both are the shape retro 42 asks for, already in the source.

**Step 3c — integration testing story: skipped.** Two stories, sequentially dependent, both already
driven end-to-end over a real server. The epic's boundary — *Server ↔ dump*, "the one place the server
reads a committed artefact" — is Story 1's entire subject and is exercised there rather than by a
cross-story story. The seam this epic shares with 49-01, the lazy `open()` itself, is covered by 49-01's
Story 7.

**Why this is a separate epic from 49-01 despite its size.** It is the only place the server reads a
committed artefact, and it is the requirement that makes the README's long-standing claim true. Folding
it into the deferred-creation epic would put a behaviour change inside an epic whose subject is a
behaviour *removal*, and the two land differently: 49-01 can ship without this and be correct, while this
cannot ship without 49-01 at all.

**FR10's second unusual case is 49-01's.** "A database served read-only" is FR5's version-ahead path,
delivered in 49-01 Story 5. FR10's own criterion names only the restore case, so that is what this epic's
criteria assert; the read-only line is wired here and exercised where the version-ahead gate is.
