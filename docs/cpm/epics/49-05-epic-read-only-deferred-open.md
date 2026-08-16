# The Deferred Open Honours Read-Only

**Source spec**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Date**: 2026-08-13  
**Status**: Complete  
**Blocked by**: 49-01, 49-02, Epic 48-01-epic-read-only-server-mode  
**Retro applied**: 42 · Criteria gaps · Applied — the spec pairs its create absences with a decoy and leaves the restore absence unpaired; Story 2's second criterion is that missing pair, so the suppression is attributable to the mode rather than to a restore path that never worked.  
**Retro applied**: 42 · Patterns worth reusing · Applied — the two harms stay decomposed to the end: this spec stops any caller *creating*, spec 48 stops an observer *migrating*, and this epic is the one place they meet, where creating on first call would defeat the other spec's protection.  
**Retro applied**: 42 · Scope surprises · Applied — a cross-spec constraint has no field of its own, so it is written into `**Blocked by**` as a named epic and into the Notes in both directions; spec 48's AD1 carries the counterpart.  
**Retro applied**: 47 · Codebase discoveries · Applied — `rpc.js` puts only `error.message` on the wire, so row 1's `ERR_SQLITE_ERROR` is asserted off the spawned server's JSON-RPC reply rather than off an in-process throw; the criterion is about what a board can distinguish, which is what crosses the boundary.  
**Retro applied**: 47 · Testing gaps · Applied — rows 2 and 4 are asserted with `readdirSync` over the directory the process ran in, never by grepping the modules on the path: both existing write sweeps are token sweeps and neither can follow a call.  
**Retro applied**: 47 · Patterns worth reusing · Applied — the epic's two decoys (rows 3 and 5) each run in the same fixture directory as the read-only arm they control, immediately after it, so the flag is the only term that differs between the two runs.  
**Retro applied**: 44 · Codebase discoveries · Applied — Task 2.1 reads where the restore actually sits in `open()`'s sequence before deciding how to suppress it, rather than assuming the read-only branch happens to precede it.  
**Retro applied**: 44 · Testing gaps · Applied — in both stories the filesystem absences are asserted before the reply is parsed, so a mutation that writes a file is reported as the write rather than caught incidentally three assertions later.

Spec 48's board launches servers read-only so that observing a project cannot migrate it. This spec
defers creation to the first tool call. Left alone, the second defeats the first: an observer's first
read would create the database it was launched specifically not to touch. FR12 is the requirement that
the deferral stops at the read-only boundary, and this epic is where the two specs meet.

## A read-only first call refuses rather than creating
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR12

**Acceptance Criteria**:

- A read-only server whose first tool call finds no database refuses with SQLite's own error rather than creating one [integration]
- After that refusal, no `.dpm/` directory, no `.gitignore` and no database file exist [integration]
- The same spawn and the same call **without** the read-only flag does create the database — the decoy that stops the three absences above passing on a server too broken to reach the filesystem at all [integration]

### The read-only branch in `open()`
**Task**: 1.1  
**Description**: The refusal comes before the mkdir, so nothing is written on the way to it — FR12 forbids the directory and the ignore file, not only the database. SQLite's own error is the refusal, not a pre-check: spec 48's FR11 reads `ERR_SQLITE_ERROR` as its named missing-database state, so producing a different error class here would break a requirement in the other spec that nothing in this one mentions.  
**Status**: Complete

### Write tests for Story 1
**Task**: 1.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The decoy runs the identical spawn and call with the mode off and asserts the database *does* appear — three absences asserted alone are all satisfied by a server that fell over before reaching the filesystem.  
**Status**: Complete

**Retro**: [Codebase discovery] Both of this story's tasks were already satisfied by code another epic had written — 48-01 put the branch above the write preamble and 49-01 made `open()` lazy — so the only thing left to build was the *reason*, and it is a reason neither of those epics could have recorded: moving the branch down would pass every criterion in spec 49 alone while reintroducing the write FR12 forbids. **Where two specs constrain one line, the constraint that is invisible from inside each of them is the one that needs writing down**, and the epic that exists at the intersection is the only place it can be written.  
**Retro**: [Testing gap] The obvious test for this story is a copy of one `read-only.test.js` already has — same fixture, same absences, same decoy — and writing it would have added a second green row and no evidence. What separates them had to be found in the criteria rather than in the code: spec 48 asks *which state* the refusal names, spec 49 asks *where* the refusal lands. Asserting the handshake and the advertised list are answered before it is the only assertion here neither the other file nor a spec-49-only reading would produce, and it is the one the eager-open mutation fails.  
**Retro**: [Pattern worth reusing] The spawn-a-session-in-a-directory shape now has 24 call sites across seven test files, each writing `runNode([BIN], wire(messages), NO_OVERRIDE, { cwd })` out by hand; this story added the 24th. It is a genuine consolidation into `tests/support/session.js` and deliberately not taken here — a helper adopted by two files out of seven is worse than none, and converting all seven is its own piece of work rather than the tail of a two-task story.

---

## No restore under read-only
**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: FR12, AD14

**Acceptance Criteria**:

- must NOT restore from a dump under read-only: a directory holding `.dpm/dpm.sql` and no database still yields the refusal, and no database is written [integration]
- The same directory with the mode off does restore — so the suppression is attributable to the mode rather than to a broken restore path [integration]

### Suppress restore-if-missing under the mode
**Task**: 2.1  
**Description**: AD14's third case, and it is not a weaker form of the first. A restore is a write, so 49-02's automatic behaviour is out of bounds here however empty the directory is. What makes the automatic case safe is that the caller was going to use the database and nothing can be lost; an observer was not going to use it, so the same reasoning does not reach.  
**Status**: Complete

### Write tests for Story 2
**Task**: 2.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Both criteria run over the same fixture directory with the mode on and off, because "no database was written" is also true of a restore path that does not work at all.  
**Status**: Complete

**Retro**: [Pattern worth reusing] The added pair earned itself on the first mutation it met. Disabling the restore outright leaves the read-only arm *passing* — the absence it asserts is exactly what a dead restore path produces — and only the control fails, on the slug that could have come from nowhere but the dump. The must-NOT and its decoy fail on disjoint faults, which is the argument for writing the pair the spec omitted rather than the reason it was omitted.  
**Retro**: [Codebase discovery] `from-dump.js`'s AD14 paragraph argues the automatic restore needs no confirmation *because restoring into nothing can lose nothing* — an argument that reads as covering a read-only server just as well, since an observer's directory is exactly the empty case. The third rule is not a further restriction on that reasoning, it is a place the reasoning does not reach, and it had to be written beside the argument it heads off rather than at the branch that enforces it. **A rule that is safe to state on its own can be unsafe to state next to the argument for its exception.**

---

## Notes

**Step 3c — integration testing story: skipped.** Two stories, both already end-to-end over a real
spawned server, both driving the same seam — `open()` under the mode. There is no cross-story data flow
to verify: Story 2 is Story 1's rule applied to one more path. The seam this epic shares with 49-01 is
covered by 49-01's Story 7, and the read-only mode itself is verified in spec 48's 48-01.

**This epic cannot be built or verified before Epic 48-01.** The mode it constrains is introduced there,
and the spec says as much: "Should the read-only mode never be built, FR12 is satisfied vacuously — which
is a reason to check it against 48's own criteria rather than to drop it." Under the agreed 49-first
landing order the practical sequence is 49-01…04, then 48-01, then this epic, then the rest of spec 48.
`**Blocked by**` names the epic directly because it exists on disk; there is no field for the cross-spec
relationship behind it, which is why the reasoning is here.

**Story 2's second criterion is the one addition, and it is the spec's own discipline applied where the
spec skipped it.** FR12's three create-side absences are paired with an explicit decoy — the spec writes
out why. Its restore-side absence has no pair, and "no database is written" is equally satisfied by a
restore path that never worked. Running the same fixture with the mode off closes it at no cost.

**The counterpart is recorded in spec 48.** AD1's second Consequence in
`docs/specifications/48-spec-dpm-board.md` states the same relationship from the other side, in both
landing orders. Two peer specs constraining one component have no representable link in CPM's vertical
chain, so the pair of prose notes is the only durable record — written deliberately in both directions
rather than only in whichever document was being edited.
