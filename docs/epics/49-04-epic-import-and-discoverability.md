# Import, Sharing the Merge's Rebuild — and Both Made Findable

**Source spec**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Date**: 2026-08-13  
**Status**: Pending  
**Blocked by**: 49-03  
**Retro applied**: 42 · Scope surprises · Applied — AD13 says the marker is written by publish *and import*, and no requirement's criteria say so for either; 49-03 added the publish half, Story 2 adds import's.  
**Retro applied**: 42 · Patterns worth reusing · Applied — AD16 is AD11's reasoning applied a second time, so the extraction comes before the new caller rather than beside it; two implementations of "rebuild the database from a dump" disagree the first time either end changes, and the disagreement is silent.  
**Retro applied**: 42 · Criteria gaps · Applied (no additions to FR8) — FR8 already carries the failed-restore must-NOT and both end-to-end journeys, which are the criteria that discriminate; what was missing was the marker write, not an assertion.

`dpm-merge` exists, handles the conflicted merge correctly, and is documented nowhere — no
`.gitattributes`, no mention in the README, `MIGRATION.md` or `hooks/pre-commit`. Git never invokes it and
no user could find it. Meanwhile the clean pull, which is the common case, has no operation at all. This
epic gives the pull an import, builds it out of the merge's own tail so the two cannot drift, and makes
both findable — which FR7's reconcile verdict now depends on, because it names a tool by name.

## Extract the shared rebuild from the merge
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR8, AD16

**Acceptance Criteria**:

- A dump that does not survive its own restore is refused by the import and by the merge, with one message from one implementation [integration]
- must NOT leave the original database replaced when a restore fails — the staging file is gone and the original still opens [integration]

### Extract restore → rename-into-place → verify-round-trip → publish → re-guard
**Task**: 1.1  
**Description**: The tail of `merge/main.js`, lifted whole. The staging-file-and-rename detail is the part most easily omitted from a second copy, and omitting it means a restore that fails part way leaves the user with neither their database nor the import. The verify step is why the extraction includes publish: a dump that does not survive its own restore must not be committed.  
**Status**: Pending

### Point the merge at the extraction
**Task**: 1.2  
**Description**: The merge keeps its three-way merge and loses its tail. Done in the same story as the extraction, because an extraction with one caller is a refactor nobody can check — the shared-message criterion is only meaningful once both callers reach it.  
**Status**: Pending

### Write tests for Story 1
**Task**: 1.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The one-message criterion is asserted by driving both callers against the same bad dump and comparing the messages, not by asserting each against a transcribed string — two transcriptions agree until one is edited.  
**Status**: Pending

---

## The import operation
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR8, AD13

**Acceptance Criteria**:

- `bin/dpm-import.js` rebuilds the database from `.dpm/dpm.sql` through the shared implementation, and is the command the guard's dump-moved verdict names [integration]
- After an import, the marker equals the hash of the dump on disk and the following guard run reports clean [integration]

### The import binary over the extracted sequence
**Task**: 2.1  
**Description**: Import is the merge's sequence without the three-way merge, per FR8. Scoped to a CLI binary mirroring `bin/dpm-publish.js`: the operation is triggered by the guard telling a human what to run, not by an agent mid-facilitation, and AD11's reasoning about provisional writes argues against giving it a tool.  
**Status**: Pending

### Write the marker from import
**Task**: 2.2  
**Description**: AD13's other half. 49-03 gave publish its marker write; without this one an import leaves the marker naming the pre-pull dump, and the next guard run reports *dump moved* against a database that has just adopted it.  
**Status**: Pending

### Write tests for Story 2
**Task**: 2.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The command the guard names is read from the guard's own constant rather than transcribed, so a rename fails here rather than in a user's terminal.  
**Status**: Pending

---

## Make both findable
**Story**: 3  
**Status**: Pending  
**Blocked by**: Story 2  
**Satisfies**: FR11

**Acceptance Criteria**:

- The README names `dpm-merge`, says when to run it, and shares one constant with the guard's reconcile message rather than a second copy of the command string [unit]
- The README names the import command on the same terms, sharing the constant the guard's dump-moved verdict uses [unit]

### Document both, sourcing the command strings from the guard's constants
**Task**: 3.1  
**Description**: FR11 exists because FR7's reconcile verdict names a tool by name, and naming a tool findable only by reading the source is a worse failure than the `differs` it replaced — the user is now told to do something specific and cannot. The shared constant is the requirement's own wording and it is what keeps documentation and diagnostic from drifting.  
**Status**: Pending

### Write tests for Story 3
**Task**: 3.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`. Asserted as a shared constant reaching both the README-generation surface and the guard's message — a test comparing two literal strings passes on two copies, which is the thing FR11 forbids.  
**Status**: Pending

---

## Verify cross-story integration for import
**Story**: 4  
**Status**: Pending  
**Blocked by**: Story 1, Story 2, Story 3  
**Satisfies**: FR8

**Acceptance Criteria**:

- Clone → first open restores → publish → commit passes the guard [feature]
- Pull → guard names import → import → commit passes the guard, and the pulled rows are present [feature]

### Write integration tests for the two journeys
**Task**: 4.1  
**Description**: Both run in a real repository through 49-01's git fixture and cross four epics: the lazy open (49-01), restore-on-create (49-02), the marker and verdict (49-03), and import (49-04). The second journey's last clause is the whole point of the spec — *the pulled rows are present* — because today that sequence ends with them discarded.  
**Status**: Pending

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
