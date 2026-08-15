# Retro: Spec 49 — the database lifecycle, end to end

**Date**: 2026-08-15  
**Source**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Epics**: 5/5 complete — 49-01 … 49-05  
**Stories**: 19/19 complete  
**Synthesised from**: docs/retros/43–46, 49-05's story-level observations, and the five epic docs
and coverage matrices. Retro 42 covers the pivot that reconciled this spec with spec 48, written
before either was built; this is the delivery retro that had no counterpart.

## Summary

Three problems met at one seam — the moment `.dpm/dpm.db` comes into existence — and all three are
closed. A session that answers `initialize`, `ping` and `tools/list` now leaves nothing on disk; the
first tool call creates the directory, writes `.dpm/.gitignore`, restores from a committed dump if
there is one and no database, and opens. The guard reads a machine-local sync marker and names the
fix belonging to whichever side moved, instead of naming publish for a pull it would destroy.
`bin/dpm-import.js` exists, shares one implementation with the merge, and both are in the README.
And a read-only server creates none of it. `dpm`'s suite ran `689 → 696` across 49-04 and stands at
**707** with 49-05 and spec 48's first epic in.

**The through-line is that removing a behaviour costs more than the removal.** 49-01 named it and
the following four epics kept finding new places it was true: two test suites that encoded
launch-time creation without mentioning creation, a README sentence made false in a file no test
reads, a test floor calibrated to the duplication being deleted, and a downstream story whose task
an upstream extraction had already done. Fixtures break loudly. Prose, floors and obligations do
not.

**The second thread is that a document describing the answers is not a partition of the inputs.**
AD13's table has five rows and the function has six input classes; NFR3's criterion picked a proxy
stricter than the requirement it mapped to and was unsatisfiable by any database in the codebase; a
coverage row claimed an attribution no assertion taken after the operation could make. Each artefact
was right about what it was for and silent about its own edges, and every one was found by
enumerating or mutating rather than by reading.

## Observations

### Smooth Deliveries

- **The five epics ran strictly sequentially with one genuine cross-spec blocker and no re-planning.**  
  49-05's `**Blocked by**` names an epic in *another* spec, which is the only representation  
  available for a peer-spec constraint, and it held. Nothing was re-scoped mid-chain.
- **Both end-to-end journeys passed on their first run.** Clone → first open restores → publish →  
  commit, and pull → guard names import → import → commit. Every component each journey crosses had  
  already been driven through its own real fixture, so the journeys composed verified behaviour  
  rather than discovering it. A cross-story story that finds bugs is usually reporting that the  
  component tests were checking constructions rather than sequences.
- **Three prose surfaces were checked at 49-04's gate and two needed nothing.** `MIGRATION.md` says  
  nothing this spec made false and `hooks/pre-commit` describes the guard's refusal generically. The  
  check came from a retro consumption gate rather than from any story, and two-of-three-already-right  
  is what makes it cheap enough to keep doing.

### Scope Surprises

- **A task that removes a call site owns every decision that call site was making.** Three of  
  49-01's tasks were already done when their story came up: the `migrated.ahead` gate had to move in  
  Story 2 because once the eager `start()` goes the decision is not knowable at launch; the ignore  
  writer landed in Story 3 because Story 3's criteria name the file *and its position in the open  
  order*, and the file is not separable from the order. A breakdown that spreads a removed line's  
  decisions across later stories is describing a sequence the code cannot follow.
- **An extraction moves obligations, and that is the half nobody plans for.** 49-04's Story 1 moved  
  the merge's tail into `src/rebuild/` and thereby did Story 2's marker work (the shared rebuild  
  publishes, and publish records the sync point), exposed a failure-path defect the merge had carried  
  since epic 47-04, and made visible four hand-written copies of `DPM_DATABASE` that a fifth was  
  about to join. None of the three was in the epic.
- **A task that creates a file owns what happens when the thing it created it for fails.**  
  `openConnection` creates the database before a restore can fail, and the empty file it leaves is  
  exactly what makes `restoreIfMissing` decline on the *next* open. One bad dump would have produced  
  a single error and then an empty planning database, silently, for the life of the checkout.
- **The guard named a binary for one epic before that binary existed.** Deliberate and split across  
  the two epics with both halves saying so in prose — pinned by shape in 49-03, by existence in  
  49-04 — but it is a one-epic window in which the help pointed nowhere.
- **49-05's two tasks were already satisfied by code two other epics had written.** 48-01 put the  
  read-only branch above the write preamble and 49-01 made `open()` lazy, so the only thing left to  
  build was the *reason* — and it is a reason neither of those epics could have recorded, because  
  moving the branch down passes every criterion in spec 49 alone while reintroducing the write FR12  
  forbids. Where two specs constrain one line, the constraint invisible from inside each of them is  
  the one that needs writing down, and the epic at the intersection is the only place it can go.

### Criteria Gaps

- **A criterion whose proxy is stricter than the requirement it maps to can be unsatisfiable on the  
  day it is drafted.** NFR3 asked that an existing database "hashes identically" across a read-only  
  lazy session; `migrate()` drops and recreates twenty-four retirement guards on every open, so two  
  consecutive opens of an untouched file give three different digests. The requirement's own words  
  are "no migration beyond what `migrate()` already does". Amended to hash the `dump()` text with  
  `migrated.applied` empty and `vocabulary.inserted` all zero beside it — a content hash alone would  
  hold if the writes merely happened to be idempotent.
- **The spec paired its creation absences with decoys and left the restore absence unpaired.** 49-05  
  wrote the missing pair, and it earned itself on the first mutation it met: disabling the restore  
  outright leaves the read-only arm *passing*, because the absence it asserts is exactly what a dead  
  restore path produces. Only the control fails. The must-NOT and its decoy fail on disjoint faults,  
  which is the argument for writing the pair rather than the reason it was omitted.
- **A coverage row can claim an attribution no assertion taken after the operation could make.** Row  
  4 says the marker equals the hash of the dump on disk after an import — true, and no post-import  
  assertion can say which write put it there, because the rebuild publishes and then re-guards and  
  the adopt path repairs exactly the state a wrong digest would leave. The row and the test now say  
  so, so the next reader cannot take it for the attribution it is not.

### Complexity Underestimates

- **The extraction was the easy half; the failure path was not.** Returning refusals to a caller  
  rather than writing them to a stream exposed a `rmSync(staging, { force: true })` in a `catch`  
  block: `force` covers a file that is not there and nothing else, so an unreachable staging path  
  threw `ENOTDIR` from inside the handler that was about to explain what actually went wrong. **A  
  cleanup on a failure path must not be able to raise, because whatever it raises replaces the error  
  being reported.** It had shipped for two epics and was found by a fixture, not by review.
- **Everything the restore had to *not* do was harder than applying the dump.** Where it sits in  
  `open()`'s sequence is forced: `restore()` takes a connection with no schema, so it cannot run  
  against what `start()` hands back, and it cannot run after `start()` because `start()` creating the  
  file is precisely what makes the restore's own condition false. One position fits, and none of it  
  is visible from FR6's wording.

### Codebase Discoveries

- **Both write sweeps are token sweeps, and a write through a helper is invisible to them.**  
  `projection.test.js` and ENVX2's `auditWrites` decide "is this a writer" by grepping a module's own  
  text for `node:fs` calls; every writer they had caught made one directly, until `src/sync/marker.js`  
  existed and the guard's adopt path called `writeMarker`. There is no sweep-sized answer — a token  
  list cannot follow a call — so what keeps it honest is that every declared writer is also held to  
  its root behaviourally.
- **Two existing suites encoded launch-time creation as an unstated assumption.** Three  
  `spine-integration.test.js` tests broke with `no such table: document_kind`, a message naming  
  neither creation, nor the fixture, nor the epic. The failure surfaces in the file least likely to  
  mention it.
- **`rpc.js` keeps `error.message` as the JSON-RPC code's standard text and puts the actionable  
  detail in `error.data`.** A wire-level test matching a refusal on `message` asserts against  
  "Invalid params" and passes for any refusal at all. In-process tests never meet this, because they  
  read the `ToolError` directly.
- **Every entry point under `bin/` reaches its logic through `await import()`**, so every `bin/`  
  static graph is the same three files. A static-graph guard's control has to be a module that is  
  actually in the static graph, or it passes for the wrong reason.
- **Calling the whole tool surface with empty arguments reaches `publish`.** A test that exercises  
  every tool is also running every tool's side effects.
- **A rule that is safe to state on its own can be unsafe to state next to the argument for its  
  exception.** `from-dump.js` argues the automatic restore needs no confirmation *because restoring  
  into nothing can lose nothing* — which reads as covering a read-only server, since an observer's  
  directory is exactly the empty case. The read-only rule is not a further restriction on that  
  reasoning; it is a place the reasoning does not reach, and it had to be written beside the argument  
  it heads off rather than at the branch that enforces it.
- **A path glob inside a JSDoc block is a syntax error waiting to happen**, and `import's` parses as  
  a bare module specifier to the suite's import walker. Both are the price of a codebase that reasons  
  in its comments, and both cost a full run to find.

### Testing Gaps

- **A floor that is not independent of the thing it bounds is not a floor.** The "registry-derived  
  count" read as one and was not — template list, file-database list and count are all built by  
  `spineTools`, so a collapsed registry collapsed all three equally and the equality went green over  
  three short lists. Closed with a second floor taken off the seeded `document_kind` rows, which  
  `spineTools` does not mediate. Ask what a floor is derived from, not whether one exists.
- **A floor that counts instances of a pattern is a floor that argues against removing them.**  
  `baseline.test.js` required four or more environment reads because `DPM_DATABASE` had four call  
  sites; consolidating them failed it. Lowering the floor was available and wrong — the consolidation  
  makes a strictly stronger claim reachable, that the environment is read in exactly one place,  
  asserted by name.
- **A specific assertion placed behind a generic one never runs.** The stdout must-NOT sat after the  
  assertion that reads the session's reply, and reading a reply is also a `JSON.parse` — so the  
  mutation was caught three assertions early by a parser error quoting the diagnostic. Same verdict;  
  the whole difference is what the next person reads at 2am, and it is only findable by mutation  
  because both orderings are green.
- **A criterion with two failure shapes gets tested against whichever one the code makes easy.**  
  "A publish that does not complete leaves the previous marker" was tested through a projection  
  refusal that throws *above* the branch the marker write lives in, so every position inside that  
  branch passed. Before testing an ordering, find the point the failure is injected at and check it  
  is downstream of the thing being ordered.
- **An assertion message that names the presumed cause is wrong for every other way it can fail**,  
  and **a control that fails by propagating someone else's exception is half a control** — the  
  remove-the-condition control caught its mutation by throwing "table schema_version already exists"  
  four frames down. True, and silent.
- **An end-to-end criterion ending in "and the commit passes" needs the sequence to leave something  
  to commit.** After a clean pull and an import the tree is byte-identical to what was pulled, so  
  `git commit` fails at git rather than at the hook. A reconciliation operation leaves nothing to  
  commit by construction, and that is worth catching at breakdown.
- **A shared helper under a set of sweeps needs its own test, written first.** The comment stripper  
  three source sweeps rest on would, if it ate a regular-expression literal, delete code the sweeps  
  then report clean — every one staying green.

### Patterns Worth Reusing

- **When two seams must happen in an order, inject both and record into one event list — and record  
  the outcome, not the call.** `open()` takes `start`, `writeIgnore`, `restore` and `connect` so the  
  order is observable, and `restore` / `restore:skipped` go into the same ordered list, which turns  
  "after the ignore, before the open, and only when the database is absent" into one assertion  
  instead of three. Three epics extended one recorder rather than adding a second; a parallel  
  recorder would let two orderings be asserted independently and agree with each other while both  
  being wrong.
- **To close a must-NOT, remove the condition and watch the same inputs produce what was refused.**  
  "X does not happen under condition C" is satisfied by a feature that never works at all.
- **Give the pure function its own module and the states become assertable at zero cost.**  
  `verdict({marker, file, database})` is twelve lines, reads no file, opens no database and names no  
  fix; five mutations against it each failed with the sentence written for that state, and the  
  rendering — which does need a repository — has four integration tests instead of nine. The named  
  parameters are load-bearing too: swapping `file` and `database` inverts the direction, which is  
  precisely the defect the epic exists to remove.
- **Filter a whole-surface sweep on the error code, not on success.** Calling all 181 advertised  
  tools in one session and looking only for `Method not found` is what makes the sweep possible;  
  most calls are refused as `Invalid params`, which is a tool that *was* resolved.
- **`git check-ignore -v` returns the verdict and names the file and pattern that produced it.**  
  Reading that provenance back is what stops a machine-level `core.excludesFile` passing an ignore  
  assertion for the wrong reason.
- **For any "the docs name X" criterion, ask the complement.** The strongest assertion in 49-04's  
  Story 3 is the one no criterion asked for: every `bin/dpm-*.js` string anywhere in the README must  
  be a value of `COMMANDS`. Containment only proves the documented commands are documented; the sweep  
  catches the *undocumented* one.
- **A criterion that names an arrangement survives the discovery that the obvious mechanism does not  
  exist.** "Shares one constant with the guard's reconcile message" is not literally achievable — the  
  guard prints an absolute path — but what the surfaces share is the tail, and the criterion held.  
  Phrased as "the README imports the guard's constant" it would have had to be rewritten.
- **Say in the code when a named path is landed by a later epic.** `IMPORT_COMMAND` carries the  
  reason it has no existence assertion and where the assertion lives; without it the missing check  
  reads as an oversight and the honest answer is unrecoverable.

## Recommendations

- **At breakdown, ask three questions this spec paid for one at a time.** For every removal task,  
  what did the removed line decide? For every new file, what happens to it when the operation it was  
  created for throws? For every extraction, which downstream tasks has it just done, and which of  
  their premises has it made false? Each was learned in a different epic and all three generalise.
- **Phrase the write-sweep question as "does this story cause a byte to be written that was not  
  written before", not "does it add a `writeFileSync`".** 49-03 added a *call*, which is the same  
  authority, and both token sweeps were blind to it.
- **Grep the suite for floors calibrated to the thing you are about to remove, and for prose  
  describing the behaviour you are about to change.** A `>= N` whose comment explains where N came  
  from will break on the cleanup, and the reflex — lower the floor — discards the stronger claim the  
  cleanup just made available. The README sentence made false by 49-03 was in a file no test reads.
- **Mutate the ordering, not only the logic, and read the failure text every time.** Three of  
  49-03's seventeen mutations were about where a line sits rather than what it does, and two of those  
  three either survived or produced a misleading message. Neither is visible from a green suite.
- **The 24-call-site session helper is a real consolidation, deliberately not taken.**  
  `runNode([BIN], wire(messages), NO_OVERRIDE, { cwd })` is written out by hand at 24 sites across  
  seven test files. Converting two of seven would be worse than none; it is its own piece of work and  
  it is recorded here so it stays a decision rather than becoming an oversight.
- **Retro 42's open recommendation is still open.** Two peer specs bearing on one line have no  
  representable relationship — 49-05 used `**Blocked by**` and prose in both directions, which  
  worked, and FR12's reason now lives in a code comment because there is nowhere else durable to put  
  it. Spec 48's own criteria gaps are the next pass over that pair.
