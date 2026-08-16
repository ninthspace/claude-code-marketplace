# Retro: The Sync Marker and the Guard's Directional Verdict

**Date**: 2026-08-14  
**Source**: docs/epics/49-03-epic-sync-marker-and-verdict.md  
**Stories**: 4/4 complete

## Summary

The guard used to report `differs` and name `bin/dpm-publish.js` in every case, including the one
where the dump had just arrived in a pull — where publishing regenerates it from the stale database
and the pulled rows are gone. It now reads a machine-local sync marker, decides which of the two
moved, and names the fix belonging to that answer. Four stories, seventeen mutations, seven
observations.

The theme is narrow and it is not the marker. **Every real difficulty in this epic came from a
decision table being mistaken for the thing it describes.** AD13's table has five rows; the function
has six input classes. The guard's write sweeps have a token list; the guard now writes through a
helper the list cannot see. An assertion message named the failure that was expected rather than the
one the assertion makes. In each case the artefact was right about what it was for and silent about
its own edges, and every one of them was found by mutation rather than by reading.

## Observations

### Scope Surprises

- **A decision table is a specification of the answers, not a partition of the inputs.**  
  AD13 enumerates five marker states, all of them divergences to explain, so it says nothing about a  
  *stale* marker over a dump and a database that agree byte for byte. That state is reachable the  
  moment a pull brings a dump someone else published from the state the local database is already in.  
  Read off the table literally it lands on differs-from-marker on both sides, therefore *both moved*:  
  a refused commit and an instruction to run `dpm-merge` on two identical files. The function answers  
  `adopt`, and agreement is now decided before the marker is consulted at all. Nothing in the spec,  
  the epic or the criterion pointed at this; enumerating the input classes did.
- **The dump-moved fix names a binary the next epic builds.**  
  `guard-fix.test.js` carries a must-NOT whose entire content is *the named command must exist on  
  disk* — help pointing nowhere is NFR6's failure wearing success's clothes. `IMPORT_COMMAND` cannot  
  satisfy it in this epic, and 49-04's Story 2 criterion is written the other way round: the binary  
  "is the command the guard's dump-moved verdict names", read from this constant. The split was  
  deliberate and the cost is a one-epic window where the guard names something a reader cannot run.  
  Pinned by shape here, by existence there, with both halves saying so in prose.

### Codebase Discoveries

- **Both write sweeps are token sweeps, and a write through a helper is invisible to them.**  
  `projection.test.js`'s rule and ENVX2's `auditWrites` both decide "is this a writer" by grepping the  
  module's own text for `node:fs` calls. Every writer they had ever caught made one directly, so the  
  gap never showed — until `src/sync/marker.js` existed and the guard's adopt path called  
  `writeMarker`. Closed by naming the helper in both patterns and declaring `src/guard/index.js` with  
  the root it may write under. **The general form has no sweep-sized answer**: a token list cannot  
  follow a call, and the next helper reopens it. What keeps it honest is that every declared writer  
  is also held to its root behaviourally.
- **Documentation consumes behaviour the same way a fixture does, and fails quietly.**  
  The README described `bin/dpm-publish.js` as "the command the pre-commit guard names when it  
  refuses a commit" — a sentence this epic made false, in a file no test reads. Retro 43's lesson  
  about fixtures that consume an outcome without naming it has now fired three times in fixtures and  
  once here; the difference is that a fixture breaks loudly. The only thing that catches the prose is  
  asking, of every behaviour changed, which sentences elsewhere were describing the old one.

### Testing Gaps

- **A criterion with two failure shapes gets tested against whichever one the code makes easy.**  
  Story 2's "a publish that does not complete leaves the previous marker" was tested through a  
  projection refusal — and `project()` throws at the *top* of `publish`, above the branch the marker  
  write lives in. Every position inside that branch passes that test, which is why the mutation that  
  hoisted the write to the branch's first line failed nothing. Only a run that reaches the write loop  
  and does not finish it discriminates. **Before writing a test for an ordering, find the point the  
  failure is injected at and check it is downstream of the thing being ordered.**
- **An assertion message that names the presumed cause is wrong for every other way it can fail.**  
  "A stale marker over two artefacts that agree was treated as a divergence" was accurate for the  
  mutation that returned `both-moved` and misleading for the one that returned `clean`, which is not a  
  divergence at all. Rewritten to name what should have happened. This is retro 44's "judge the  
  failure text, not the count" one level down: the count was right both times and only the sentence  
  was wrong.

### Patterns Worth Reusing

- **Give the pure function its own module and the states become assertable at zero cost.**  
  The behaviour replaced here was a single `differs` produced inline where the message is written, so  
  the only way to ask about a state was to construct a repository in it. `verdict({marker, file,  
  database})` is twelve lines, reads no file, opens no database and names no fix — and five mutations  
  against it each failed with the sentence written for that state. The rendering, which does need a  
  repository, then has four integration tests instead of nine.
- **Named parameters where two arguments of the same type mean opposite things.**  
  `verdict({marker, file, database})` rather than three positionals: swapping `file` and `database`  
  inverts the direction, which is precisely the defect the epic exists to remove, and a positional  
  call site makes that swap invisible at the point it is written.

## Recommendations

- **Enumerate the input classes separately from the decision table, at breakdown.** Every table in a  
  spec describes the cases someone thought needed answers. Listing the equality partition of the  
  actual inputs took two minutes and found a state that would have refused commits over two identical  
  files.
- **When a task adds a write site rather than a writer, re-run the sweep question anyway.** Retro 43's  
  disposition covers "this story adds a writer under `src/`". This one added a *call*, which is the  
  same authority and the sweeps could not see it. Phrase the check as "does this story cause a byte to  
  be written that was not written before", not "does it contain a `writeFileSync`".
- **Mutate the ordering, not just the logic, and read the failure text every time.** Three of this  
  epic's seventeen mutations were about *where* a line sits rather than what it does, and two of those  
  three initially survived or produced a misleading message. Neither is visible from a green suite.
- **Say in the code when a named path is landed by a later epic.** `IMPORT_COMMAND` carries the reason  
  it has no existence assertion and where the assertion lives. Without that, the missing check reads  
  as an oversight to the next reader, and the honest answer — a deliberate one-epic window — is not  
  recoverable from anywhere they will look.
