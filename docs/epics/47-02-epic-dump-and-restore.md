# Dump and Restore

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Date**: 2026-08-08  
**Status**: Pending  
**Blocked by**: Epic 47-01-epic-substrate

Milestone M1 (AD6). The committed form of the database is text, and this epic produces the
bytes and reads them back. The **merge tool** is deliberately *not* here: FR8's merge
criterion requires renaming a projection file, so the whole of it lives in Epic 47-04 where
the renderer exists. Splitting that criterion across two epics would have manufactured the
partial-coverage state recorded as self-hosting register entry 1.

## Write the deterministic dumper [plan]
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR8, NFR4, AD4

**Acceptance Criteria**:

- The dump contains no FTS5 shadow table and no hex blob, and restoring it yields a populated `document_fts` — the index is rebuilt by the insert trigger, not carried in the file [integration]
- Every `INSERT` in the dump names its columns, and every table's rows are emitted in primary-key order [unit]
- Dumping the same database on two machines yields byte-identical `.sql` [integration]
- Dumping the same state repeatedly is byte-stable across runs and locales [integration]
- must NOT — the dumper delegates to `sqlite3 .dump`, which emits FTS5 shadow blobs, orders rows by insertion, and does not exist in `node:sqlite` [unit]
- must NOT — a table is skipped from the dump without the exclusion being declared and asserted, so a restored database is missing rows and reports success [integration]

### Enumerate dumpable objects from `sqlite_schema`, excluding `sqlite_%` and the FTS5 shadow tables
**Task**: 1.1  
**Description**: The exclusion is declared and asserted rather than implicit — that is what the no-silent-omission clause requires. The `CREATE VIRTUAL TABLE` statements are kept; their five shadow tables each are not.  
**Status**: Pending

### Emit schema first, with triggers created before any data
**Task**: 1.2  
**Description**: This is what makes the index reproducible without dumping it — restoring `document_section` fires `document_fts_insert` row by row. Covers the no-shadow-table criterion's second half.  
**Status**: Pending

### Emit rows as one column-named INSERT per row, ordered by primary key
**Task**: 1.3  
**Description**: AD9 is what makes "order by primary key" a total order on every table, including the association tables whose key is composite. Naming columns keeps historic dumps valid across a migration that adds one.  
**Status**: Pending

### Write the fixed literal formatter and the LF / trailing-newline discipline
**Task**: 1.4  
**Description**: Covers byte-stability across machines and locales — no locale collation anywhere in the pipeline, no float shortening, integers in base ten.  
**Status**: Pending

### Write tests for Write the deterministic dumper
**Task**: 1.5  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Restore a dump and prove it intact
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR14

**Acceptance Criteria**:

- A restore ending in `PRAGMA foreign_key_check` fails loudly on a dump carrying a dangling reference, naming the row [integration]
- A restored dump violating each register entry in turn is reported, one entry at a time, naming the rows [integration]

### Apply the dump in a transaction and let the triggers rebuild both FTS indexes
**Task**: 2.1  
**Description**: No reindex step — the index arrives as a consequence of the data. Scoped to applying the file; the checks that follow are Task 2.2.  
**Status**: Pending

### End the restore with `PRAGMA foreign_key_check` and the register sweep
**Task**: 2.2  
**Description**: Restore is the one connection where FR2 cannot hold, because a sorted dump is not in topological order and `document.parent_id` is self-referential. Neither check is optional and neither is the caller's to remember.  
**Status**: Pending

### Write tests for Restore a dump and prove it intact
**Task**: 2.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Verify cross-story integration for Dump and restore
**Story**: 3  
**Status**: Pending  
**Blocked by**: Story 1, Story 2  
**Satisfies**: NFR4, FR9

**Acceptance Criteria**:

- A database dumped, restored into an empty file, and dumped again produces byte-identical output to the first dump [integration]
- A restored database's `document_fts` and `entry_fts` both return the same `MATCH` results as the source database's, for a term present in a section body and a term present only in a `requirement.text` [integration]
- A dump taken before and after a no-op read produces identical bytes, so reading does not perturb dump order [integration]
- must NOT — a round trip loses a row, an index entry, or a trigger without failing [integration]

### Write integration tests for Dump and restore
**Task**: 3.1  
**Description**: The round-trip criterion is what earns this story. Stories 1 and 2 each satisfy their own criteria without ever being compared to one another — the same gap shape as Epic 47-01's DDL-versus-migration-runner divergence.  
**Status**: Pending

---

## Address review findings
**Story**: 4  
**Status**: Complete — applied by `/cpm:pivot` on 2026-08-08 from review 05  
**Blocked by**: —

**Acceptance Criteria**:

- Each critical and warning finding from review 05 scoped to this epic has been addressed
- Existing acceptance criteria on other stories continue to pass

### Fix: coverage matrix row 12 is bound to a story that does not exist
**Task**: 4.1  
**Description**: [critical] Row 12 of `47-02-coverage-dump-and-restore.md` names **Story 4** under `Covered by`. This epic had three stories when the review ran; the criterion — "A dump taken before and after a no-op read produces identical bytes, so reading does not perturb dump order" — sits on **Story 3**. The matrix's own mapping note repeats the error ("the criterion was already on Story 4"), so it is recorded twice and self-corroborating. Correct both the row and the note. A coverage row that cannot resolve to a story is retro 34's "green mark with nothing behind it" one column over: a roll-up either breaks on it or silently drops it, and a dropped row lowers the denominator rather than raising an error. Note that this remediation story is itself numbered 4 — the fix is to repoint row 12 at Story 3, not to let the new numbering make the stale citation accidentally resolve.  
**Status**: Complete — row 12 repointed to Story 3, mapping note corrected and the near-miss recorded

---

## Notes

### Self-hosting register — entries in this epic's scope

The register lives in Epic 47-01's Notes. No entry falls in this epic's scope; all four are
schema or seeding concerns owned by 47-01 and closable only by a spec change.

**One entry was reinforced by this epic's breakdown rather than added.** Entry 1 (partial
coverage indistinguishable from full) is what decided the merge tool's placement: keeping
FR8's merge criterion whole in 47-04 was preferred over splitting it across two epics,
precisely because the split would have produced a requirement that reads as covered in two
matrices while no single story delivers it.

### Requirements only partially covered by this epic

- **FR8** — the dump half only. The merge half is Epic 47-04.
- **FR9** — one row (coverage matrix row 10), asserting search survives a restore. FR9's  
  substantive coverage is Epic 47-05.
- **FR14** — the restore-path checks only. The integrity tool itself is Epic 47-01 Story 6.
