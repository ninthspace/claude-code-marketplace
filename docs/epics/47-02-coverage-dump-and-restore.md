# Coverage Matrix: Dump and Restore

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Epic**: docs/epics/47-02-epic-dump-and-restore.md  
**Date**: 2026-08-08

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR8 | A deterministic, sorted `.sql` dump is committed; the binary `.db` is generated and ignored. | Every `INSERT` in the dump names its columns, and every table's rows are emitted in primary-key order | Story 1 | `[unit]` | |
| 2 | FR8 | A deterministic, sorted `.sql` dump is committed | The dump contains no FTS5 shadow table and no hex blob, and restoring it yields a populated `document_fts` — the index is rebuilt by the insert trigger, not carried in the file | Story 1 | `[integration]` | |
| 3 | FR8 | Two branches that both add artefacts produce an ordinary text conflict (AD4). | Dumping the same database on two machines yields byte-identical `.sql` | Story 1 | `[integration]` | |
| 4 | NFR4 | The same database state produces the same `.sql` bytes on any machine, on any run — ordered rows, no timestamps, no locale dependence. | Dumping the same state repeatedly is byte-stable across runs and locales | Story 1 | `[integration]` | |
| 5 | NFR4 (must NOT) | ordered rows, no timestamps, no locale dependence | must NOT — the dumper delegates to `sqlite3 .dump`, which emits FTS5 shadow blobs, orders rows by insertion, and does not exist in `node:sqlite` | Story 1 | `[unit]` | |
| 6 | FR8 (must NOT) | A deterministic, sorted `.sql` dump is committed | must NOT — a table is skipped from the dump without the exclusion being declared and asserted, so a restored database is missing rows and reports success | Story 1 | `[integration]` | |
| 7 | FR14 | A verification tool reports orphans, dangling links, and each entry in the cross-row invariant register (Data Model), so a corrupted state is diagnosable without SQL. | A restore ending in `PRAGMA foreign_key_check` fails loudly on a dump carrying a dangling reference, naming the row | Story 2 | `[integration]` | |
| 8 | FR14 | each entry in the cross-row invariant register (Data Model) | A restored dump violating each register entry in turn is reported, one entry at a time, naming the rows | Story 2 | `[integration]` | |
| 9 | NFR4 | The same database state produces the same `.sql` bytes on any machine, on any run | A database dumped, restored into an empty file, and dumped again produces byte-identical output to the first dump | Story 3 | `[integration]` | |
| 10 | FR9 | Artefact bodies *and* the hand-written text on their child rows — requirements, story criteria, retro observations, review findings — are indexed with FTS5 | A restored database's `document_fts` and `entry_fts` both return the same `MATCH` results as the source database's, for a term present in a section body and a term present only in a `requirement.text` | Story 3 | `[integration]` | |
| 11 | NFR4 (must NOT) | no timestamps, no locale dependence | must NOT — a round trip loses a row, an index entry, or a trigger without failing | Story 3 | `[integration]` | |
| 12 | NFR4 | The same database state produces the same `.sql` bytes on any machine, on any run — ordered rows, no timestamps, no locale dependence. | A dump taken before and after a no-op read produces identical bytes, so reading does not perturb dump order | Story 3 | `[integration]` | |

**Mapping notes.**

Row 10 maps to **FR9**, not FR8 — the criterion is about search surviving a restore, and FR9
is the requirement that owns search. FR9's substantive coverage is Epic 47-05; this row is a
second partial, which is self-hosting register entry 1 in miniature.

**Row 12 was added on 2026-08-08**, during the pivot that closed the self-hosting register. It
was not a cascaded change: the criterion was already on Story 3 and had no row, found by a
set comparison between each epic's criteria and its matrix's `Story Criterion` column. It sits
alongside row 9 and asserts the other half of byte-stability — row 9 says a round trip is
stable, row 12 says a read is not a write.

**Row 12 named Story 4 until review 05, and this epic had three stories.** The criterion has
always sat on Story 3; both the row and the note above said Story 4, so the error corroborated
itself and reading either one confirmed the other. Both are corrected here. The correction is
worth recording rather than making silently, because this epic now *does* have a Story 4 — the
remediation story the review generated — so from this point on the stale citation would have
resolved to a real story, silently, and to the wrong one. A dangling reference that later
becomes a valid reference to something else is the failure mode `coverage.story_criterion_id`
being a foreign key is meant to make unavailable, and it is the reason the fix repoints the row
rather than leaving the numbering to absorb it.

Rows 5 and 11 map their must-NOT clauses to **NFR4** because byte-stability is the property
both defend. Neither clause is quoted from the spec — both were proposed under the skill's
must-NOT suggestion path for data-integrity stories and accepted by Chris on 2026-08-08 — so
the Spec Text column holds the requirement text they attach to rather than a verbatim
must-NOT line the spec does not contain.

**Story 4's two criteria have no rows here, and that is declared rather than missed.** It is
the "Address review findings" story, which records repairs to this breakdown rather than
obligations drawn from the spec, so its criteria have no requirement to bind to. The
both-directions set comparison should expect exactly those two as an unmatched remainder.
