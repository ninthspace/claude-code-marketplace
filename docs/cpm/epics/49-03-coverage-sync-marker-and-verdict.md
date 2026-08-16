# Coverage Matrix: The Sync Marker and the Guard's Directional Verdict

**Source spec**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Epic**: docs/epics/49-03-epic-sync-marker-and-verdict.md  
**Date**: 2026-08-13

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | AD13 | "`.dpm/dpm.db.synced` holds the hash of the dump text at the last sync point, written by both publish and import." | "`.dpm/dpm.db.synced` holds the hash of the dump text at the last sync point, written and read through one module" | Story 1 | `[unit]` | ✓ |
| 2 | AD13 (added) | "the filename is already covered by AD4's `dpm.db*` ignore pattern — the marker is machine-local for the same reason the database is" | "The marker is machine-local and already ignored by 49-01's `dpm.db*` pattern — asserted, not assumed" | Story 1 | `[integration]` | ✓ |
| 3 | AD13 (added) | "written by both publish and import" | "After a publish, the marker equals the hash of the dump on disk, and the immediately following guard run reports clean" | Story 2 | `[integration]` | ✓ |
| 4 | AD13 (added) | "The guard compares the marker against the hash of the dump on disk and against the hash of `dump(db)`" | "A publish that does not complete leaves the previous marker in place rather than a marker for a dump that was never written" | Story 2 | `[integration]` | ✓ |
| 5 | FR7 | "The verdict function returns database-moved / dump-moved / both-moved / adopt / unknown for the five marker states" | "The verdict function returns database-moved / dump-moved / both-moved / adopt / unknown for the five marker states" | Story 3 | `[tdd] [unit]` | ✓ |
| 6 | FR7 | "The guard distinguishes *database ahead* (publish), *dump ahead* (import) and *both moved* (reconcile deliberately), and names the fix belonging to each." | "Each verdict names its own fix in the guard's output, driven in a real repository" | Story 4 | `[integration]` | ✓ |
| 7 | FR7 | "An absent marker over a database that agrees with the dump writes the marker and reports clean" | "An absent marker over a database that agrees with the dump writes the marker and reports clean" | Story 4 | `[integration]` | ✓ |
| 8 | FR7 (must NOT) | "must NOT name publish when the dump moved" | "must NOT name publish when the dump moved" | Story 4 | `[integration]` | ✓ |
| 9 | FR7 (must NOT) | "must NOT name a single fix when the marker is absent and the two disagree — both are named, with what each would do" | "must NOT name a single fix when the marker is absent and the two disagree — both are named, with what each would do" | Story 4 | `[integration]` | ✓ |

## Notes

**Rows 3 and 4 are the epic's real addition, and they cover a subject the spec's criteria never name.**
Every one of FR7's five criteria describes the guard *reading* the marker. Nothing says publish *writes*
one. The obligation is stated only in the spec's sixth integration boundary — "Publish ↔ marker — written
by every publish, or the next guard run is wrong" — which no downstream step reads. Built without these
rows, the guard would compare against a marker no code path maintains, and every verdict after the first
would be wrong in the same direction, which is the exact failure this epic exists to close.

**Row 3's second clause is what makes it an assertion.** "The marker equals the hash of the dump" is
satisfied by a marker written with any hash the same code computed both times. Following it immediately
with a guard run that must report clean is what ties the written value to the value the guard will read.

**Row 8 is the regression test for the live defect.** Today the guard reports `differs` and names
`bin/dpm-publish.js` in every case, and publish regenerates the dump from the stale database — so the
named fix is the one that destroys the pulled rows. This row should be written to fail against the
current guard before anything is built.

**Row 9 covers the case AD13's table calls *unknown*, and it is the only verdict that refuses.** The
other four proceed with a named fix; this one names both and describes what each would do, because a
marker-less divergence carries no information about direction. It is reachable only by a database already
divergent at upgrade time — row 7 is what keeps every other existing project out of it.

**Row 5 is the only `[tdd]` row in this spec's coverage.** The verdict is a pure function over three
hashes and five states, which is the shape where writing the cases first is cheapest; the current code
produces `differs` inline where the message is written, so there is no function to test until one is
extracted.

**FR8's journeys are not in this matrix.** *Clone → first open → publish → commit* and *pull → guard names
import → import → commit* both cross this epic's boundaries and neither can complete until import exists;
both are covered at `docs/epics/49-04-coverage-import-and-discoverability.md`.
