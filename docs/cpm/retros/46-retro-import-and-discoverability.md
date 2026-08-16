# Retro: Import, the Shared Rebuild, and Making Both Findable

**Date**: 2026-08-14  
**Source**: docs/epics/49-04-epic-import-and-discoverability.md  
**Stories**: 4/4 complete

## Summary

The clean pull had no operation at all: `.dpm/dpm.sql` arrived rewritten, the local database was
silently behind it, and the only tool that rebuilt a database from a dump was reachable only from
inside a conflicted merge — a tool that was itself documented nowhere. This epic extracted the
merge's tail into `src/rebuild/`, built `bin/dpm-import.js` on top of it, and put both commands in
the README behind one constant the guard resolves. Four stories, twenty mutations, eleven
observations, seven tests, `689 → 696` passing.

The theme is **what an extraction does to the stories downstream of it**. Story 1 moved a sequence
into a module; that quietly satisfied Story 2's marker task, exposed a latent defect in the failure
path the merge had carried since epic 47-04, and made visible four hand-written copies of
`DPM_DATABASE` that a fifth was about to join. None of the three was in the epic. An extraction is
usually described as removing duplication, and every difficulty here came from the other half of
what it does: it *moves obligations*, and the artefacts written against the pre-extraction shape are
where that shows up.

## Observations

### Complexity Underestimates

- **The extraction was the easy half; the failure path was not.**  
  Moving the sequence into a module whose refusals are *returned to a caller* rather than written  
  straight to a stream exposed a defect sitting in the merge all along. The staging cleanup is  
  `rmSync(staging, { force: true })`, and `force` covers a file that is not there and nothing else:  
  when the staging path is unreachable — its parent turned out to be a regular file — `rmSync` throws  
  from inside the `catch` block that was about to explain what actually went wrong, so a refusal the  
  tool knows how to report became an uncaught `ENOTDIR`. **A cleanup on a failure path must not be  
  able to raise, because whatever it raises replaces the error being reported**, and `force`-style  
  flags cover far less than their name suggests. Found by a test fixture, not by review.

### Scope Surprises

- **Story 1's extraction did Story 2's work, and nothing said so.**  
  Task 2.2 was scoped to add AD13's import-side marker write and there was nothing to add: the shared  
  rebuild publishes, and publish records the sync point. The task was written when AD13's two halves  
  looked symmetric — publish writes one, import writes the other — and the extraction made one a  
  consequence of the other. Worth asking at every AD16-style extraction: **which of the downstream  
  stories just had their work done for them.** Surfaced through the Change Type gate rather than  
  resolved silently; the task now records where the obligation is met so nobody adds a second write.
- **`src/rebuild/` declining a default is what made four copies of one visible.**  
  `DPM_DATABASE` had four hand-written defaults — the server, guard, publish and merge entry points —  
  and they had not drifted, so nothing was wrong in the ordinary sense. What made it a problem is that  
  the *fifth* would be written by hand too, and a fifth spelling the default without reading the  
  variable would be correct everywhere except the setups that override it. Collected into  
  `src/db/location.js` at Story 1's refactoring pass.

### Codebase Discoveries

- **A test floor calibrated to a duplication breaks when the duplication goes.**  
  `baseline.test.js`'s NFR2 sweep required *four or more* environment reads as its "the sweep is still  
  looking" floor, with a comment saying `DPM_DATABASE` has four call sites. Consolidating them failed  
  it. Lowering the floor was available and wrong; the consolidation makes a strictly stronger claim  
  reachable — the environment is read in exactly one place, asserted by name — which a fifth  
  hand-written default fails and the old floor never could. **A floor that counts instances of a  
  pattern is a floor that argues against removing them.**
- **Two prose comments were rejected by the suite's own sweeps rather than by review.**  
  `import's` parsed as a bare module specifier by `plugin.test.js`'s import walker, and `src/*/main.js`  
  inside a JSDoc block closed the comment at the `*/`. Both are the price of a codebase that reasons  
  in its comments, and both cost a full run to find. The second is worth knowing in advance: **a path  
  glob in a block comment is a syntax error waiting for the reader who writes one.**
- **Three enumerations of the binary set, and only two of them knew they were enumerations.**  
  Adding a fifth binary failed `publish-cli.test.js` twice, by design — its directory `deepEqual` was  
  written to catch exactly this. `capability.test.js`'s FTS5 sweep, titled "all four binaries", did  
  not: it is a hand-written list of per-binary invocations and there is no deriving it, because each  
  needs its own arguments and environment. Closed by asserting the list against the directory listing.

### Testing Gaps

- **A self-healing step downstream of a write makes every after-the-fact assertion about that write  
  untestable.**  
  Coverage row 4 says the marker equals the hash of the dump on disk after an import, and after an  
  import it does — but no assertion taken *after* an import can say which write put it there. The  
  rebuild publishes and then re-guards, and the guard's adopt path repairs a marker that disagrees  
  with two artefacts that agree, which is precisely the state a publish recording the wrong digest  
  would leave. Driven to confirm: hashing the wrong text leaves the row's assertion green and fails  
  `publish.test.js`, where 49-03 bound the attribution. Nothing about reading the test suggested it.
- **Retro 44's control caught its mutation and said nothing about why.**  
  The remove-the-condition control for Story 1's must-NOT caught the rebuild that restores straight  
  over the original — by *throwing*, four frames down, with "table schema_version already exists".  
  True, and silent. Wrapped in `try`/`assert.fail` it became "a dump that does restore was refused, so  
  the refusal asserted above is not the staging file doing its job". **A control that fails by  
  propagating someone else's exception is half a control.**
- **An end-to-end criterion ending in "and the commit passes" needs the sequence to leave something to  
  commit.**  
  After a clean pull followed by an import, the tree is byte-identical to what was pulled: rows right,  
  projection right, nothing staged — so `git commit` fails at git rather than at the hook and the  
  criterion is unreachable. Journey 2 commits a file dpm does not generate alongside. A reconciliation  
  operation leaves nothing to commit by construction, and that is worth catching at breakdown.

### Patterns Worth Reusing

- **For any "the docs name X" criterion, ask the complement.**  
  The strongest assertion in Story 3 is the one no criterion asked for: every `bin/dpm-*.js` string  
  anywhere in the README must be a value of `COMMANDS`. Containment checks only prove the documented  
  commands are documented; the sweep is what catches the *undocumented* one — a README naming  
  `bin/dpm-restore.js` passes every "does it mention X" check while sending a reader to a file no  
  constant defines and nothing asserts the existence of.
- **A criterion that names an arrangement survives the discovery that the obvious mechanism does not  
  exist.**  
  "Shares one constant with the guard's reconcile message" is not literally achievable — the guard  
  prints an absolute path, a fact about one machine, and no README can carry one. What the surfaces  
  share is the tail: `COMMANDS` holds repo-relative strings, the guard resolves its constants from  
  them, the README carries them verbatim, a test binds the two. Phrased as "the README imports the  
  guard's constant", the criterion would have had to be rewritten.

### Smooth Deliveries

- **Both end-to-end journeys passed on their first run.**  
  Every piece each journey crosses had already been driven through its own real fixture —  
  `first-run.test.js` for the clone-to-commit shape, `guard-verdict.test.js` for the pulled state,  
  `import.test.js` for the binary — so the journeys composed verified behaviour rather than  
  discovering it. **A cross-story story that finds bugs is usually reporting that the component tests  
  were checking constructions rather than sequences.**
- **Three prose surfaces were checked and two needed nothing.**  
  The README changed; `MIGRATION.md` says nothing this epic makes false, and `hooks/pre-commit`  
  describes the guard's refusal generically and stays true. The check came from retro 45's consumption  
  gate rather than from any story, and the fact that two of three were already right is what makes it  
  cheap enough to keep doing.

## Recommendations

- **At every extraction, re-read the stories downstream of it before starting them.** Ask which of  
  their tasks the extraction has already satisfied, and which of their premises it has made false.  
  Both happened here, one epic apart, and neither was visible from the extraction's own story.
- **Grep the suite for floors calibrated to the thing you are about to remove.** A `>= N` assertion  
  whose comment explains where N came from is an assertion that will break on the cleanup, and the  
  reflex — lower the floor — throws away the stronger claim the cleanup just made available.
- **Every failure path gets a mutation that makes its cleanup fail.** The `discard` defect is  
  reachable only by breaking the recovery, not the operation, and it had shipped for two epics. The  
  question is "what does this `catch` block do when the thing inside it also throws".
- **When a criterion's subject is repaired downstream, say so where the criterion is recorded.** Row  
  4's assertion looks like it proves more than it does. The note in the coverage matrix and in the test  
  is what stops the next reader taking it for the attribution it cannot be.
