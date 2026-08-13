# The Deferred Open Honours Read-Only

**Source spec**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Date**: 2026-08-13  
**Status**: Pending  
**Blocked by**: 49-01, 49-02, Epic 48-01-epic-read-only-server-mode  
**Retro applied**: 42 · Criteria gaps · Applied — the spec pairs its create absences with a decoy and leaves the restore absence unpaired; Story 2's second criterion is that missing pair, so the suppression is attributable to the mode rather than to a restore path that never worked.  
**Retro applied**: 42 · Patterns worth reusing · Applied — the two harms stay decomposed to the end: this spec stops any caller *creating*, spec 48 stops an observer *migrating*, and this epic is the one place they meet, where creating on first call would defeat the other spec's protection.  
**Retro applied**: 42 · Scope surprises · Applied — a cross-spec constraint has no field of its own, so it is written into `**Blocked by**` as a named epic and into the Notes in both directions; spec 48's AD1 carries the counterpart.

Spec 48's board launches servers read-only so that observing a project cannot migrate it. This spec
defers creation to the first tool call. Left alone, the second defeats the first: an observer's first
read would create the database it was launched specifically not to touch. FR12 is the requirement that
the deferral stops at the read-only boundary, and this epic is where the two specs meet.

## A read-only first call refuses rather than creating
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR12

**Acceptance Criteria**:

- A read-only server whose first tool call finds no database refuses with SQLite's own error rather than creating one [integration]
- After that refusal, no `.dpm/` directory, no `.gitignore` and no database file exist [integration]
- The same spawn and the same call **without** the read-only flag does create the database — the decoy that stops the three absences above passing on a server too broken to reach the filesystem at all [integration]

### The read-only branch in `open()`
**Task**: 1.1  
**Description**: The refusal comes before the mkdir, so nothing is written on the way to it — FR12 forbids the directory and the ignore file, not only the database. SQLite's own error is the refusal, not a pre-check: spec 48's FR11 reads `ERR_SQLITE_ERROR` as its named missing-database state, so producing a different error class here would break a requirement in the other spec that nothing in this one mentions.  
**Status**: Pending

### Write tests for Story 1
**Task**: 1.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The decoy runs the identical spawn and call with the mode off and asserts the database *does* appear — three absences asserted alone are all satisfied by a server that fell over before reaching the filesystem.  
**Status**: Pending

---

## No restore under read-only
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR12, AD14

**Acceptance Criteria**:

- must NOT restore from a dump under read-only: a directory holding `.dpm/dpm.sql` and no database still yields the refusal, and no database is written [integration]
- The same directory with the mode off does restore — so the suppression is attributable to the mode rather than to a broken restore path [integration]

### Suppress restore-if-missing under the mode
**Task**: 2.1  
**Description**: AD14's third case, and it is not a weaker form of the first. A restore is a write, so 49-02's automatic behaviour is out of bounds here however empty the directory is. What makes the automatic case safe is that the caller was going to use the database and nothing can be lost; an observer was not going to use it, so the same reasoning does not reach.  
**Status**: Pending

### Write tests for Story 2
**Task**: 2.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Both criteria run over the same fixture directory with the mode on and off, because "no database was written" is also true of a restore path that does not work at all.  
**Status**: Pending

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
