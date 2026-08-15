# Import, Sharing the Merge's Rebuild — and Both Made Findable

**Source spec**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Date**: 2026-08-13  
**Status**: Complete  
**Blocked by**: 49-03  
**Retro applied**: 42 · Scope surprises · Applied — AD13 says the marker is written by publish *and import*, and no requirement's criteria say so for either; 49-03 added the publish half, Story 2 adds import's.  
**Retro applied**: 42 · Patterns worth reusing · Applied — AD16 is AD11's reasoning applied a second time, so the extraction comes before the new caller rather than beside it; two implementations of "rebuild the database from a dump" disagree the first time either end changes, and the disagreement is silent.  
**Retro applied**: 42 · Criteria gaps · Applied (no additions to FR8) — FR8 already carries the failed-restore must-NOT and both end-to-end journeys, which are the criteria that discriminate; what was missing was the marker write, not an assertion.  
**Retro applied**: 45 · Codebase discoveries · Applied — Story 1 extracts a rename-and-write sequence into a new module and Story 2 adds a marker write from import, so `projection.test.js`'s `ALLOWED` and `baseline.test.js`'s ENVX2 `DECLARED` are re-checked before the suite runs; the question is phrased as "does this story cause a byte to be written that was not written before", not "does it contain a `writeFileSync`", because the sweeps cannot follow a call.  
**Retro applied**: 45 · Codebase discoveries · Applied — Story 3 *is* this lesson's structural answer (FR11's shared constant), and beyond it every behaviour this epic changes gets the same question asked of `MIGRATION.md` and `hooks/pre-commit` as well as the README, none of which any test reads.  
**Retro applied**: 45 · Testing gaps · Applied — Story 1's must-NOT has two failure shapes: a restore that fails before the staging file exists and one that fails at the rename. Only the second exercises the rename-into-place the extraction exists to preserve, so the fault is injected downstream of the staging write and the mutations are judged on failure text rather than count.  
**Retro applied**: 44 · Patterns worth reusing · Applied — Story 1's must-NOT gets a control in the same test running the identical sequence against a dump that *does* survive its restore, which must replace the database; without it "the original still opens" holds for an import that never works. Story 2's guard-reports-clean assertion gets the same treatment.

`dpm-merge` exists, handles the conflicted merge correctly, and is documented nowhere — no
`.gitattributes`, no mention in the README, `MIGRATION.md` or `hooks/pre-commit`. Git never invokes it and
no user could find it. Meanwhile the clean pull, which is the common case, has no operation at all. This
epic gives the pull an import, builds it out of the merge's own tail so the two cannot drift, and makes
both findable — which FR7's reconcile verdict now depends on, because it names a tool by name.

## Extract the shared rebuild from the merge
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR8, AD16

**Acceptance Criteria**:

- A dump that does not survive its own restore is refused by the import and by the merge, with one message from one implementation [integration]
- must NOT leave the original database replaced when a restore fails — the staging file is gone and the original still opens [integration]

**Inline change**: coverage row 1's `Covered by` widened from `Story 1` to `Story 1, Story 2` — its criterion names the import, whose binary is Story 2's, so the row is marked only once both gates pass (2026-08-14)

**Retro**: [Complexity underestimate] The extraction was the easy half; the failure path was not. Moving the sequence into a module whose refusals are *returned to a caller* rather than written straight to a stream exposed a defect that had been sitting in the merge all along: the staging cleanup is `rmSync(staging, { force: true })`, and `force` covers a file that is not there and nothing else. When the staging path is unreachable — its parent turned out to be a regular file — `rmSync` throws from inside the `catch` block that was about to explain what actually went wrong, so a refusal the tool knows how to report became an uncaught `ENOTDIR`. Found by a test fixture, not by review. The generalisable shape: **a cleanup on a failure path must not be able to raise, because whatever it raises replaces the error being reported** — and `force`-style flags cover far less than their name suggests.

**Retro**: [Pattern worth reusing] Retro 44's remove-the-condition control caught the mutation that restores straight over the original — but caught it by *throwing* from the control call, four frames down, with "table schema_version already exists". True, and silent about why the test cared. Wrapping the control in `try`/`assert.fail` turned it into "a dump that does restore was refused, so the refusal asserted above is not the staging file doing its job". **A control that fails by propagating someone else's exception is half a control**: it stops the wrong implementation shipping and tells the next reader nothing.

**Retro**: [Codebase discovery] `DPM_DATABASE` had four hand-written defaults — the server, guard, publish and merge entry points — and `src/rebuild/` declining to add a fifth is what made them visible. Collected into `src/db/location.js` at the story's refactoring pass, which then failed `baseline.test.js`'s NFR2 sweep: it required *four or more* environment reads as its "the sweep is still looking" floor. The floor was calibrated to the duplication, so removing the duplication broke it. Replaced with the stronger claim the consolidation makes available — the environment is read in exactly one place, asserted by name — which a fifth hand-written default now fails and the old floor never could.

### Extract restore → rename-into-place → verify-round-trip → publish → re-guard
**Task**: 1.1  
**Description**: The tail of `merge/main.js`, lifted whole. The staging-file-and-rename detail is the part most easily omitted from a second copy, and omitting it means a restore that fails part way leaves the user with neither their database nor the import. The verify step is why the extraction includes publish: a dump that does not survive its own restore must not be committed.  
**Status**: Complete

### Point the merge at the extraction
**Task**: 1.2  
**Description**: The merge keeps its three-way merge and loses its tail. Done in the same story as the extraction, because an extraction with one caller is a refactor nobody can check — the shared-message criterion is only meaningful once both callers reach it.  
**Status**: Complete

### Write tests for Story 1
**Task**: 1.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The one-message criterion is asserted by driving both callers against the same bad dump and comparing the messages, not by asserting each against a transcribed string — two transcriptions agree until one is edited.  
**Status**: Complete

---

## The import operation
**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR8, AD13

**Acceptance Criteria**:

- `bin/dpm-import.js` rebuilds the database from `.dpm/dpm.sql` through the shared implementation, and is the command the guard's dump-moved verdict names [integration]
- After an import, the marker equals the hash of the dump on disk and the following guard run reports clean [integration]

**Inline change**: Task 2.2's description corrected — the marker write it was scoped to add already arrives through the shared rebuild's `publish` call, so the task is the assertion and the docblock note rather than a second write (2026-08-14)

**Retro**: [Scope surprise] Task 2.2 was scoped to add AD13's import-side marker write and there was nothing to add: Story 1's extraction had already carried it, because the shared rebuild publishes and publish records the sync point. The task was written when the two sides of AD13 looked symmetric — publish writes one, import writes the other — and the extraction quietly made one of them a consequence of the other. **An extraction does not only remove duplication; it moves obligations**, and the later story that was scoped against the pre-extraction shape is where that shows up. Worth checking at every AD16-style extraction: which of the *downstream* stories just had their work done for them.

**Retro**: [Testing gap] Row 4's criterion — "after an import the marker equals the hash of the dump on disk" — is not assertable at its author, and looks like it is. The rebuild publishes and then re-guards, and the guard's adopt path repairs a marker that disagrees with two artefacts that agree, which is exactly what a publish writing the wrong digest leaves behind. So the assertion is green under that mutation and only `publish.test.js` fails. The general shape: **a self-healing step downstream of the write makes every after-the-fact assertion about the write untestable**, and the mutation is what said so — nothing about reading the test suggested it. Recorded in the coverage matrix and in the test itself so the next reader does not take the line for more than it is.

**Retro**: [Codebase discovery] Two comments were rejected by the suite's own sweeps rather than by review: `import's` parsed as a bare module specifier by `plugin.test.js`'s import walker, and `src/*/main.js` inside a JSDoc block closed the comment at the `*/`. Both are prose, both broke a check about code, and both cost a full run to find. They are the price of a codebase that reasons in its comments, and the sweeps catching them is the system working — but the second one is worth knowing before writing the next docblock: **a path glob in a block comment is a syntax error waiting for the reader who writes one.**

### The import binary over the extracted sequence
**Task**: 2.1  
**Description**: Import is the merge's sequence without the three-way merge, per FR8. Scoped to a CLI binary mirroring `bin/dpm-publish.js`: the operation is triggered by the guard telling a human what to run, not by an agent mid-facilitation, and AD11's reasoning about provisional writes argues against giving it a tool.  
**Status**: Complete

### Write the marker from import
**Task**: 2.2  
**Description**: AD13's other half. 49-03 gave publish its marker write; without one on this side an import leaves the marker naming the pre-pull dump, and the next guard run reports *dump moved* against a database that has just adopted it. **Story 1's extraction already satisfies it**: the shared rebuild calls `publish`, which writes the marker from `dump(db)` — and the round-trip check immediately above has proven that equals the dump on disk. So the work here is to pin the property and say where it comes from, not to add a second write, which would be a second answer to when the sync point is recorded.  
**Status**: Complete

### Write tests for Story 2
**Task**: 2.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The command the guard names is read from the guard's own constant rather than transcribed, so a rename fails here rather than in a user's terminal.  
**Status**: Complete

---

## Make both findable
**Story**: 3  
**Status**: Complete  
**Blocked by**: Story 2  
**Satisfies**: FR11

**Acceptance Criteria**:

- The README names `dpm-merge`, says when to run it, and shares one constant with the guard's reconcile message rather than a second copy of the command string [unit]
- The README names the import command on the same terms, sharing the constant the guard's dump-moved verdict uses [unit]

**Retro**: [Criteria gap] "Shares one constant with the guard's reconcile message" is not literally achievable and the criterion is right anyway. The guard prints an *absolute* path — a fact about one machine — and no README can carry one. What the two surfaces can share is the tail, so `COMMANDS` in `src/guard/index.js` holds the repo-relative strings, the guard resolves its absolute constants from them, and the README carries them verbatim with a test asserting it. **A criterion that names an arrangement rather than a mechanism survives the discovery that the obvious mechanism does not exist** — the same criterion phrased as "the README imports the guard's constant" would have had to be rewritten.

**Retro**: [Pattern worth reusing] The strongest assertion in the story is the one nobody asked for: every `bin/dpm-*.js` string anywhere in the README must be a value of `COMMANDS`. Containment checks only prove the documented commands are documented; the sweep is what catches the *undocumented* one — a README naming `bin/dpm-restore.js` passes every "does it mention X" check while sending a reader to a file no constant defines and no test asserts the existence of. **For any "the docs name X" criterion, ask the complement: what else do the docs name, and does anything vouch for it.**

**Retro**: [Smooth delivery] Three prose surfaces were checked, not one: the README (changed), `MIGRATION.md` (nothing this epic makes false) and `hooks/pre-commit` (describes the guard's refusal generically and stays true). That check came from retro 45's consumption gate rather than from the story, and two of the three needed nothing — which is the outcome that makes the check cheap enough to keep doing.

### Document both, sourcing the command strings from the guard's constants
**Task**: 3.1  
**Description**: FR11 exists because FR7's reconcile verdict names a tool by name, and naming a tool findable only by reading the source is a worse failure than the `differs` it replaced — the user is now told to do something specific and cannot. The shared constant is the requirement's own wording and it is what keeps documentation and diagnostic from drifting.  
**Status**: Complete

### Write tests for Story 3
**Task**: 3.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`. Asserted as a shared constant reaching both the README-generation surface and the guard's message — a test comparing two literal strings passes on two copies, which is the thing FR11 forbids.  
**Status**: Complete

---

## Verify cross-story integration for import
**Story**: 4  
**Status**: Complete  
**Blocked by**: Story 1, Story 2, Story 3  
**Satisfies**: FR8

**Acceptance Criteria**:

- Clone → first open restores → publish → commit passes the guard [feature]
- Pull → guard names import → import → commit passes the guard, and the pulled rows are present [feature]

**Retro**: [Smooth delivery] Both journeys passed on their first run, which is the outcome a cross-story integration story is supposed to produce and rarely does. The reason is worth naming: every piece each journey crosses had already been driven through its own real fixture — `first-run.test.js` for the clone-to-commit shape, `guard-verdict.test.js` for the pulled state, `import.test.js` for the binary — so the journeys were composing verified behaviour rather than discovering it. **A cross-story story that finds bugs is usually reporting that the component tests were checking constructions rather than sequences.**

**Retro**: [Testing gap] Journey 2 needed a file the guard has no opinion about — `NOTES.md` — to have anything to commit at all. After a clean pull followed by an import, the tree is byte-identical to what was pulled: the rows are right, the projection is right, and there is nothing staged, so `git commit` fails at git rather than at the hook and the criterion's "commit passes the guard" is unreachable. The general shape: **an end-to-end criterion whose last step is "and the commit passes" needs the sequence to have left something to commit**, and a reconciliation operation by construction leaves nothing. Worth catching at breakdown rather than at the keyboard.

### Write integration tests for the two journeys
**Task**: 4.1  
**Description**: Both run in a real repository through 49-01's git fixture and cross four epics: the lazy open (49-01), restore-on-create (49-02), the marker and verdict (49-03), and import (49-04). The second journey's last clause is the whole point of the spec — *the pulled rows are present* — because today that sequence ends with them discarded.  
**Status**: Complete

---

## Notes

**Step 3c — integration testing story: warranted, Story 4.** FR8's two `[feature]` criteria are
end-to-end journeys that no single story owns and that span four epics. They are placed here rather than
in 49-03 because neither can complete until import exists: *pull → guard names import → import* has no
final step without it, and truncating it at the verdict is the assertion 49-03 already makes.

**Story 2's scope is a judgement call the spec leaves open.** Scope says "the new import entry points",
plural, without naming them. Scoped here to `bin/dpm-import.js`, mirroring `bin/dpm-publish.js`. The
reasoning is AD11's: a facilitation's writes are provisional until its run closes, so an operation that
overwrites the database from a committed file is one a human triggers after reading a diagnostic, not one
an agent reaches for mid-run. If that reading is wrong, the fix is one criterion on this story and a tool
registration — recorded so the decision is visible rather than inferred from what was built.

**Import's marker write is added, and it is the mirror of 49-03's addition.** AD13 says the marker is
written by both publish and import; the spec's criteria say it for neither. Without it, an import leaves
the marker naming the pre-pull dump, and the next guard run reports *dump moved* against a database that
has just adopted that dump — the same class of wrong verdict this whole line of work exists to remove,
arriving from the other direction.

**Task 1.2 belongs to Story 1, not to a later cleanup.** An extraction with a single caller is
unverifiable: FR8's one-message criterion only means something once the merge and the import both reach
the same implementation. Leaving the merge pointed at its old copy would satisfy every other criterion
here and reintroduce the drift AD16 exists to prevent.

**What this epic does not do.** Registering `dpm-merge` as a git merge driver via `.gitattributes` and
`git config` is out of scope — it needs per-clone configuration and is a separate decision. FR11 makes the
tool findable; it does not make git invoke it.
