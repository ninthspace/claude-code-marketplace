# Coverage Matrix: The Deferred Open Honours Read-Only

**Source spec**: docs/specifications/49-spec-dpm-database-lifecycle.md  
**Epic**: docs/epics/49-05-epic-read-only-deferred-open.md  
**Date**: 2026-08-13

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR12 | "Where the server is running read-only, the first tool call refuses a missing database rather than creating one" | "A read-only server whose first tool call finds no database refuses with SQLite's own error rather than creating one" | Story 1 | `[integration]` | |
| 2 | FR12 | "writes no `.dpm/` directory and no ignore file, and performs no restore" | "After that refusal, no `.dpm/` directory, no `.gitignore` and no database file exist" | Story 1 | `[integration]` | |
| 3 | FR12 | "The same spawn and the same call **without** the read-only flag does create the database — the decoy that stops the three absences above passing on a server too broken to reach the filesystem at all" | "The same spawn and the same call **without** the read-only flag does create the database — the decoy that stops the three absences above passing on a server too broken to reach the filesystem at all" | Story 1 | `[integration]` | |
| 4 | FR12 (must NOT) | "must NOT restore from a dump under read-only: a directory holding `.dpm/dpm.sql` and no database still yields the refusal, and no database is written" | "must NOT restore from a dump under read-only: a directory holding `.dpm/dpm.sql` and no database still yields the refusal, and no database is written" | Story 2 | `[integration]` | |
| 5 | AD14 (added) | "There is a third case, and it is not a weaker form of the first: under a read-only server, create never. A restore is a write, so FR6 is out of bounds there however empty the directory is" | "The same directory with the mode off does restore — so the suppression is attributable to the mode rather than to a broken restore path" | Story 2 | `[integration]` | |

## Notes

**Row 5 is the pair row 4 does not have.** FR12's three create-side absences (rows 1 and 2) come with an
explicit decoy in row 3, and the spec writes out the reasoning for it. The restore-side absence in row 4
has no such pair, and "no database is written" is equally satisfied by a restore path that never worked —
which is exactly the failure the spec's own row 3 exists to prevent one requirement earlier. Row 5 runs
the same fixture with the mode off.

**Row 1 asserts *which* error, not merely that one occurred.** SQLite's own `ERR_SQLITE_ERROR` is what
spec 48's FR11 reads as its named missing-database state. A pre-check producing a different error class
would satisfy every absence in this matrix and break a requirement in the other spec that nothing in this
one mentions — the counterpart row is
`docs/epics/48-01-coverage-read-only-server-mode.md` row 8.

**Every row here depends on a mode this spec does not build.** The read-only flag is spec 48's AD1,
delivered by Epic 48-01. Until that lands, FR12 is satisfiable vacuously, which the spec identifies as a
reason to check it against 48's criteria rather than to drop it. That is why this epic's `**Blocked by**`
names an epic from the other parent.

**Rows 4 and 5 constrain a behaviour delivered in 49-02.** Restore-on-create is covered at
`docs/epics/49-02-coverage-restore-on-create.md`; these rows say when it must not fire. Neither matrix's
✓ is evidence about the other's — 49-02 verifies the restore happens, this verifies it stops.
