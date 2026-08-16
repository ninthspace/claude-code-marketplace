# Retro: Restore on Create

**Date**: 2026-08-14  
**Source**: docs/epics/49-02-epic-restore-on-create.md  
**Stories**: 2/2 complete

## Summary

A claim the README had been making since it was written is now true: a fresh clone's first tool call
finds no database, finds `.dpm/dpm.sql` beside it, and builds one from it — saying so in a line on
stderr, and never touching a database that is already there. Two stories, five observations, and
they share a theme that is narrower than 49-01's: **the interesting part of this epic was not the
restore, it was everything the restore had to not do.** Where it sits in `open()`'s sequence, what it
leaves behind when it fails, and how a test can tell "declined correctly" from "never worked" were
each harder than applying the dump.

## Observations

### Scope Surprises

- **The task delivered a writer the epic did not mention, and it was load-bearing.**  
  `openConnection(location)` creates the database file before the restore can fail, and `restore()`'s  
  own guarantee — a failed restore changes nothing — stops at the rollback. The empty file it leaves  
  behind is exactly what makes `restoreIfMissing` decline on the next open, so one bad dump would  
  have produced a single error and then an empty planning database, silently, for the life of the  
  checkout. The fix is four lines and it pulled in two existing sweeps (`projection.test.js`'s  
  `ALLOWED`, `baseline.test.js`'s ENVX2 `DECLARED`). The generalisable shape: **a task that creates a  
  file owns what happens when the thing it created it for fails** — and "the created file suppresses  
  the retry" is a failure mode with no error message attached to it.

### Codebase Discoveries

- **`restore()` takes a connection with no schema, and that single fact fixes the design.** The dump  
  carries its own `CREATE TABLE` statements, while `start()` is `openConnection` → `migrate` →  
  `applyVocabulary`. So the restore cannot run against the connection `start()` hands back, and it  
  cannot run after `start()` either, because `start()` creating the file is precisely what makes the  
  restore's own condition false. One place fits: `openConnection(location)` → `restore` → close,  
  *before* `start()`, which then migrates the restored schema forward the way a clone of an older  
  branch needs. None of that is visible from FR6's wording, and a breakdown written without it would  
  have described a sequence the code cannot follow.

### Testing Gaps

- **A specific assertion placed behind a generic one never runs.** The stdout must-NOT was written  
  after the assertion that reads the session's reply — and reading a reply is also a `JSON.parse`.  
  The mutation that sent the report to stdout *was* caught, but by the reply parser, with  
  `Unexpected token 'd', "[dpm] no da"... is not valid JSON`, three assertions before the one written  
  for it. Moving the purity check ahead of the reply read turned that into "the restoring session  
  wrote 0 lines to stderr". Same verdict; the difference is entirely in what the next person reads at  
  2am. **When two assertions can catch the same fault, order them so the specific one runs first** —  
  and note that this is only findable by mutation, since both orderings are green.

### Patterns Worth Reusing

- **To close a must-NOT, remove the condition and watch the same inputs produce what was refused.**  
  "X does not happen under condition C" is satisfied by a feature that never works at all. The test  
  that asserts the dump was not restored over an existing database therefore deletes the database and  
  re-runs the identical session against the untouched dump, which then restores. Without that line  
  the criterion holds for a restore path that is simply broken, and nothing else in the suite would  
  have said so.
- **A seam recorder should record the outcome, not the call.** `restore` fires on every open and  
  declines on almost all of them, so a bare `'restore'` event reads identically for the case FR6 is  
  about and the case it rules out. Recording `restore` / `restore:skipped` into the same ordered list  
  as `ignore` and `start:` makes "after the ignore, before the open, and only when the database is  
  absent" one assertion instead of three. This is retro 43's inject-both-and-record-into-one-list,  
  extended by one seam and one bit of state — and the extension is where the value was.

## Recommendations

- **At breakdown, ask what a new file's creation implies on the failure path.** This epic's only  
  unplanned work came from a file that existed for a few milliseconds and then outlived the operation  
  it was created for. The question generalises past this case: any task whose first act is to create  
  something should say what happens to it when the second act throws.
- **Order assertions specific-first, and mutation-test the order rather than the assertion.** Both  
  orderings pass, both catch the fault, and only one produces a message that locates it. The check is  
  cheap: run the mutation and read the failure text, not just the count.
- **Carry the remove-the-condition control into every must-NOT.** Retro 42 asked for decoys on  
  positive criteria; this is the same demand pointed the other way, and it is the only thing that  
  distinguishes "correctly refused" from "never worked".
- **Keep extending `recordOpen` rather than adding a second recorder.** Three seams now share one  
  event list, and every ordering claim about a first open is one `deepEqual`. A fourth seam belongs  
  there too; a parallel recorder would let two orderings be asserted independently and agree with  
  each other while both being wrong.
