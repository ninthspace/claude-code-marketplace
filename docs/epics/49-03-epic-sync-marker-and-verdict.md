# The Sync Marker and the Guard's Directional Verdict

**Source spec**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Date**: 2026-08-13  
**Status**: Pending  
**Blocked by**: 49-01  
**Retro applied**: 42 · Scope surprises · Applied — the spec's sixth integration boundary names an obligation no requirement carries ("Publish ↔ marker — written by every publish, or the next guard run is wrong"); Story 2 exists because a boundary with no criterion is built by inference or not at all.  
**Retro applied**: 42 · Criteria gaps · Applied (no additions to FR7) — FR7 already carries both must-NOTs and the adopt-path criterion, which are the discriminating cases; the addition here is a missing subject, not a weak assertion.  
**Retro applied**: 42 · Patterns worth reusing · Applied — the verdict is decomposed into five named states before any output is written, which is what lets Story 3 be a pure `[tdd]` function and Story 4 a rendering of it; the current code collapses all of them into `differs`.

A clean pull rewrites `.dpm/dpm.sql` and touches nothing else, so the local database is silently stale.
The guard then compares `dump(db)` against the file, reports `differs`, and names `bin/dpm-publish.js` —
which regenerates the dump from the stale database and discards the pulled rows. The guard is right that
something is wrong and wrong about which direction, and there is no information in the two files alone to
tell it: after both a pull and local work, the worktree matches `HEAD`.

## The sync marker
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: AD13

**Acceptance Criteria**:

- `.dpm/dpm.db.synced` holds the hash of the dump text at the last sync point, written and read through one module [unit]
- The marker is machine-local and already ignored by 49-01's `dpm.db*` pattern — asserted, not assumed [integration]

### The marker module
**Task**: 1.1  
**Description**: One module, read and write. AD13 chose a file over a `sync_state` table because the dump is generated from the database, so a stored hash would end up inside the file it hashes — and excluding a table from the dump to escape that would put a special case against spec 47's NFR4, which makes byte-stability load-bearing.  
**Status**: Pending

### Write tests for Story 1
**Task**: 1.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]` and `[integration]`. The ignore assertion is here rather than assumed from 49-01: the pattern was written for the database and its WAL sibling, and the marker's coverage by it is a consequence worth pinning where the marker is introduced.  
**Status**: Pending

---

## Every publish writes the marker
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: AD13

**Acceptance Criteria**:

- After a publish, the marker equals the hash of the dump on disk, and the immediately following guard run reports clean [integration]
- A publish that does not complete leaves the previous marker in place rather than a marker for a dump that was never written [integration]

### Write the marker from publish
**Task**: 2.1  
**Description**: Every publish, all three callers — the `publish` MCP tool, `bin/dpm-publish.js`, and `/dpm:publish` — because they share one implementation at `publish/index.js`. Written after the dump lands, so a failure between the two leaves a stale marker rather than a marker for a file that does not exist; the first is diagnosable and the second is a verdict built on a lie.  
**Status**: Pending

### Write tests for Story 2
**Task**: 2.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The guard-reports-clean half is what makes this a real assertion — a marker written with the wrong hash satisfies "a marker exists" and produces a wrong verdict on the next run.  
**Status**: Pending

---

## The five-state verdict function
**Story**: 3  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR7

**Acceptance Criteria**:

- The verdict function returns database-moved / dump-moved / both-moved / adopt / unknown for the five marker states [tdd] [unit]

### Write tests for the verdict function
**Task**: 3.1  
**Description**: `[tdd]`, so this comes first. Five states from two comparisons — marker against the dump on disk, marker against `dump(db)` — plus the two absent-marker cases. The pair that must not collapse is *both moved* and *unknown*: both are ambiguous, and only one of them has a marker to reason from.  
**Status**: Pending

### The verdict function
**Task**: 3.2  
**Description**: A pure function over three hashes, separate from anything that renders it. That separation is what makes the five states assertable at all — today they are one `differs` produced inline where the message is written.  
**Status**: Pending

---

## The guard names the fix belonging to each verdict
**Story**: 4  
**Status**: Pending  
**Blocked by**: Story 2, Story 3  
**Satisfies**: FR7

**Acceptance Criteria**:

- Each verdict names its own fix in the guard's output, driven in a real repository [integration]
- An absent marker over a database that agrees with the dump writes the marker and reports clean [integration]
- must NOT name publish when the dump moved [integration]
- must NOT name a single fix when the marker is absent and the two disagree — both are named, with what each would do [integration]

### Replace `differs` with the five verdicts and their fixes
**Task**: 4.1  
**Description**: Database moved names publish, dump moved names import, both moved names `dpm-merge`. The current behaviour — `differs`, naming publish in every case — is not a missing feature but an active data-loss path, because the fix it names is the one that destroys the pulled rows.  
**Status**: Pending

### The adopt-on-agreement upgrade path
**Task**: 4.2  
**Description**: Every database that exists today lacks a marker, so without this every existing project sees a verdict on its next commit. One that already agrees with its dump is not ambiguous at all: adopt silently, write the marker, report clean. Only a database already divergent at upgrade time reaches *unknown*.  
**Status**: Pending

### Write tests for Story 4
**Task**: 4.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`, driven in a real repository through 49-01's git fixture. The dump-moved must-NOT is the regression test for the defect this epic exists to close, and it should be written to fail against today's guard.  
**Status**: Pending

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
