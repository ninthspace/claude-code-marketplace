# Parity and Search

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Date**: 2026-08-08  
**Status**: Pending  
**Blocked by**: Epic 47-01-epic-substrate, Epic 47-03-epic-server-and-spine-tools, Epic 47-04-epic-projection-guard-and-merge

Milestone M3 (AD6). Epic 47-03 gave the seven spine types their tools; this completes the
enumeration and makes the corpus searchable. The dependency on 47-04 is narrow and real —
Story 2's multi-category criterion and Story 6's parity closure both assert what the
projection renders.

**The `Blocked by` field above over-constrains this epic, and the excess is a milestone
inversion.** What this epic actually waits on is 47-04's **projection**, which is Stories 1
and 2 and is M2 work. It does **not** wait on 47-04 Story 4, the merge tool, which is M4 —
later in AD6's build order than this entire epic. Read literally, the field holds M3 behind
M4 for a third of the build. The field stays as it is because `Blocked by` is declared per
epic and 47-04 is the epic that spans two milestones (self-hosting register entry 2), so
there is nowhere in this format to say "Stories 1–2 of 47-04, not Story 4". Anyone sequencing
from the field should read this paragraph with it. FR22 is what removes the limitation once
dpm holds this corpus: a `dependency` edge's source and target may each be a document **or a
story**, so the narrow dependency becomes expressible and the inversion stops being something
a note has to carry.

## Give the remaining sixteen entity types create, read and update tools [plan]
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR10, FR1, FR27

**Acceptance Criteria**:

- Every table in `sqlite_master` has a create tool, asserted by comparing the live table list against the registered tool list — neither side is a hand-kept enumeration [integration]
- An observation written against a story and later gathered into a retro retains its `story_id`, so its origin is still queryable [unit]

### Write create, read and update tools for the ten remaining document kinds
**Task**: 1.1  
**Description**: Problem brief, product brief, ADR, review, retro, quick record, discussion, audit, runbook, library document. All are rows in `document`, so the tools differ by their `kind` pin and their detail table, not by their storage.  
**Status**: Pending

### Write tools for the nine detail tables behind ADR, review, quick and library document
**Task**: 1.2  
**Description**: `adr` + `adr_option` + `adr_option_tradeoff`, `review` + `review_agent`, `quick` + `quick_criterion`, `library_document` + `library_scope`. AD7 gives these structure to hold; without tools that structure is write-only.  
**Status**: Pending

### Write tools for `finding` and `observation`
**Task**: 1.3  
**Description**: `observation` is the one with inclusive parentage — `story_id` is the origin and survives promotion into a retro, `retro_id` is the grouping. The update tool must not clear one to set the other.  
**Status**: Pending

### Write tools for `artifact` and its document join
**Task**: 1.4  
**Description**: One join table replaces CPM's index-plus-backlinks pair. The tools write the row; the index file and the in-document backlinks are both 47-04 projections of it.  
**Status**: Pending

### Write tools for `milestone` and `document_milestone`
**Task**: 1.5  
**Description**: FR27's tool half — create a milestone scoped to a spec at a given position, and join an artefact to one. The join tool is where register #12 is enforced: the document and the milestone must belong to the same spec, which no foreign key can express because it needs `document.parent_id` walked to the root.  
**Status**: Pending

### Enumerate the live table list against the registered tool list
**Task**: 1.6  
**Description**: Read the table list from `sqlite_master` and compare against what the server registered, in both directions — neither side is a hand-kept enumeration. This is what makes the boundary with Epic 47-03 non-load-bearing — see the Notes. It reads the set from the live schema, so it caught `milestone` the moment FR27 added it, without amendment.  
**Status**: Pending

### Write tests for Give the remaining sixteen entity types create, read and update tools
**Task**: 1.7  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Make every vocabulary extensible and retirable through tools
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR24

**Acceptance Criteria**:

- A project-added category is usable without a schema migration [integration]
- An observation carrying two categories round-trips, and appears under both in the projection [integration]
- Retiring a test approach and a dependency kind leaves rows using them intact, as it does for a taxonomy row [unit]
- must NOT — any vocabulary is seeded and extensible but cannot be retired [unit]
- A persona added to a project's `agent` table is offered by `party`, `review` and `consult` with no plugin change and no file edit [integration]

### Write add and retire tools for taxonomy rows, test approaches, dependency kinds and agents
**Task**: 2.1  
**Description**: Four vocabularies, one retirement semantic. Epic 47-01 Story 2 built the constraint; this makes it reachable without SQL, which is what "extensible per project" requires. The `agent` roster is the case that motivated FR24's evolution clause: CPM's `agents/roster.yaml` can only be overridden by replacing the whole file, so adding one persona means forking all ten and maintaining the fork. Append is the operation projects actually perform, and it is the one the file cannot express.  
**Status**: Pending

### Attach more than one category to an item through the join, and project both
**Task**: 2.2  
**Description**: An item may genuinely span two categories. The projection half is why this story depends on Epic 47-04.  
**Status**: Pending

### Write tests for Make every vocabulary extensible and retirable through tools
**Task**: 2.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Index section bodies and maintain the index by trigger [plan]
**Story**: 3  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR9, AD9

**Acceptance Criteria**:

- A section written with a ULID id is retrievable by `MATCH`, and `document_fts` declares no `content=` option — the external-content form rejects a non-integer rowid at write time [unit]
- Updating and deleting a section both leave the index consistent with the table, asserted by comparing a `MATCH` against a `LIKE` scan [unit]

### Write `document_fts` as a standalone FTS5 table carrying `section_id UNINDEXED`
**Task**: 3.1  
**Description**: Standalone, not external-content: `content_rowid` must be an integer and AD9 made every id a ULID, so the external form fails with `datatype mismatch` on the first section written. The criterion asserts the absence of `content=`, not just that search works.  
**Status**: Pending

### Write the insert, update-of-indexed-column and delete triggers
**Task**: 3.2  
**Description**: The triggers are the whole maintenance story — the table owns its content, so there is no `rebuild` to run and none to test.  
**Status**: Pending

### Write tests for Index section bodies and maintain the index by trigger
**Task**: 3.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`. The `MATCH`-versus-`LIKE` comparison is the assertion shape: it fails on a stale index where a bare `MATCH` would pass.  
**Status**: Pending

---

## Index the prose held on child rows
**Story**: 4  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR9

**Acceptance Criteria**:

- Every table `entry_fts` indexes has all three triggers — insert, update-of-the-indexed-column, delete — enumerated from `sqlite_schema`, with no table indexed by fewer than three [unit]
- Updating and deleting a row of each indexed child table leaves `entry_fts` consistent with that table, asserted by the same `MATCH`-versus-`LIKE` comparison [unit]

### Write `entry_fts` with an `entity` tag column and `entity_id UNINDEXED`
**Task**: 4.1  
**Description**: The tag is what makes `entity:requirement AND term` scope a search while an untagged query spans everything.  
**Status**: Pending

### Write three triggers for each indexed table — `requirement`, `acceptance_criterion`, `observation`, `finding`
**Task**: 4.2  
**Description**: Twelve triggers. A column earns its place by holding prose a person wrote that no other column can find the row by; labels, statuses and enums stay out, being `WHERE` clauses and not search terms.  
**Status**: Pending

### Enumerate the indexed tables from `sqlite_schema` and assert three triggers each
**Task**: 4.3  
**Description**: A missing update trigger leaves the index behind the data while every search still returns something, so it is asserted structurally rather than behaviourally.  
**Status**: Pending

### Write tests for Index the prose held on child rows
**Task**: 4.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Search across both indexes through one tool
**Story**: 5  
**Status**: Pending  
**Blocked by**: Story 3, Story 4  
**Satisfies**: FR9

**Acceptance Criteria**:

- A search returns ranked results, and the index reflects a write made in the same session [integration]
- A term appearing only in a `requirement.text` is found by an unscoped search, and the hit names the entity and row id [integration]
- must NOT — a search covers `document_section` only, so text held on a child row is unreachable while the tool reports success [integration]

### Query both indexes from one tool and merge ranked results
**Task**: 5.1  
**Description**: One tool, two indexes. A tool reading only `document_section` returns success while missing most of the searchable prose, which is the story's final clause.  
**Status**: Pending

### Name the entity and row id on every hit, and accept a column-scoped `entity:` term
**Task**: 5.2  
**Description**: A hit that cannot be resolved back to a row is not a result. Scoping is what makes the tagged index usable rather than merely tagged.  
**Status**: Pending

### Write tests for Search across both indexes through one tool
**Task**: 5.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`, including same-session write visibility.  
**Status**: Pending

---

## Verify cross-story integration for Parity and search
**Story**: 6  
**Status**: Pending  
**Blocked by**: Story 1, Story 2, Story 3, Story 4, Story 5  
**Satisfies**: FR9, FR10, FR24, NFR7, NFR6

**Acceptance Criteria**:

- Creating one row of every indexed entity type through its own tool, then searching a term common to all of them, returns a hit from every one — the tools and the triggers are built by different stories and nothing else runs them together [integration]
- A create tool refuses a vocabulary row retired through Story 2's retire tool, and the refusal names the retired item [integration]
- Every table, enumerated from `sqlite_master` and populated through its own tool, appears in the projection its kind renders into — or inside its parent's, for the ten that produce no file and for the ADR [integration]
- must NOT — a search returns a hit whose entity and row id do not resolve to a live row through that entity's read tool [integration]
- Every condition in the false-pass register has a test asserting it blocks rather than warns — including the six Epic 47-01 deferred, whose closing epics are all complete by the time this story runs [integration]
- A restored database's `document_fts` and `entry_fts` both return the same `MATCH` results as the source database's, for a term present in a section body and a term present only in a `requirement.text` [integration]

### Write integration tests for Parity and search
**Task**: 6.1  
**Description**: The third criterion is the parity closure: FR10's enumeration (Story 1) and FR10's templates (Epic 47-04 Story 2) are the same requirement checked in two epics, and this is the only place both are true at once. The final clause guards the seam NFR7 cares about — a search index drifted from the tables returns hits nothing can open.  
**Status**: Pending

### Close the false-pass register
**Task**: 6.2  
**Description**: Epic 47-01 built the register as executable data in `dpm/tests/false-pass.test.js` and gave each of the twenty conditions exactly one disposition: a test that closes it, or the epic that will. Six carry the second kind — #9 to the dump path (47-02), #10 to the tool boundary (47-03), #4 to the projection guard (47-04), and #3, #15 and #16 to the search index built by this epic's Stories 3–5. This story is the first point in the build order where all four of those epics are complete, which is why the whole-register claim is declared here rather than at its author. Convert each of the six from a `closedIn` deferral to a `test` citation naming a test that exists, and the existing assertion that every deferral names where it closes then passes over an empty set — the register goes from complete and honest to satisfied. A condition converted without a test behind it is register entry #18's own shape applied to the register, so each conversion is mutation-checked the way 47-01 checked the other fourteen.  
**Status**: Pending

---

## Address review findings
**Story**: 7  
**Status**: Complete — applied by `/cpm:pivot` on 2026-08-08 from review 05  
**Blocked by**: —

**Acceptance Criteria**:

- Each critical and warning finding from review 05 scoped to this epic has been addressed
- Existing acceptance criteria on other stories continue to pass

### Fix: the epic-level blocker inverts the milestone order
**Task**: 7.1  
**Description**: [warning] This epic is M3 and declares `**Blocked by**: … Epic 47-04-epic-projection-guard-and-merge`. Epic 47-04 spans **M2 and M4** — its merge tool is M4 work — so followed literally, M3 cannot start until M4's merge tool is complete, reversing AD6's build order for a third of the build. This epic's header note says the real dependency is narrow (Story 2's projection assertion and Story 6's parity closure, both against 47-04's M2 half), but nothing machine-readable records that and `cpm:do`'s readiness pass reads the field, not the note. Narrow the declaration to the stories it actually depends on, or record the milestone-half distinction where a reader of the field will find it. FR22 exists to make blocking a typed edge whose source and target "may each be a document or a story", and this is the case that needs it.  
**Status**: Complete — the inversion is now stated in the header beside the field, since the format cannot express the narrow edge

### Fix: `§332` resolves to the wrong passage
**Task**: 7.2  
**Description**: [warning] This epic's Notes say "Rather than fixing a number that the spec itself qualifies at §332". Spec line 332 is blank; the passage that qualifies the arithmetic — *"The arithmetic does not reduce to a subtraction…"* — is at line 345. One of five stale spec line-references across the breakdown; Epics 47-01 and 47-04 carry the others. Prefer a quoted phrase or a section heading to a line number.  
**Status**: Complete — repointed to the Data Model's parity-contract heading and its quoted sentence

---

## Notes

### The FTS tables arrive as a migration, not in the founding DDL

Stories 3 and 4 write both virtual tables and their fifteen triggers, and Epic 47-01 Story 1
writes "the DDL". The boundary is drawn here: the FTS objects are 47-05's, delivered through
the migration runner, which makes this epic the runner's first real customer. Epic 47-01
Story 8's DDL-versus-migration parity criterion covers them once they land, so the split
costs no assertion. Approved by Chris on 2026-08-08.

### Where the tables divide between this epic and 47-03

Epic 47-03 Story 2 covers seven spine types by name; this epic covers the rest. The count
does not resolve cleanly — `coverage` is both a `document_kind` and a child table, `brief` is
two kinds, and `session state` has a table built in 47-03 Story 6 without typed tools
enumerated there. Rather than fixing a number that the spec itself qualifies under **"The
kinds are seeded data, and the list is the parity contract"** in the Data Model — the
paragraph beginning *"The arithmetic does not reduce to a subtraction"* — Story
1's enumeration criterion reads the set from the live schema and fails on any member without
a tool. **The boundary is therefore not load-bearing**: however it is drawn, the enumeration
catches anything that falls between the two epics. This is the one place in the breakdown
where a partial split is safe, and it is safe only because the requirement was written as an
enumeration rather than a count.

Epic 47-03 said "the remaining fifteen" against this epic's "sixteen" until review 05. Both
are now sixteen — the Data Model's
*thirteen document kinds, eight child tables and two standalone tables*, less the spine's
seven — with the `session` qualification stated in 47-03 where the number appears, rather
than left to a reader to reconcile from a third note.

The pivot of 2026-08-08 removed the count from Story 1's criterion altogether: it now reads
the table list from `sqlite_master` and compares it against the registered tools, so no
number in this epic is load-bearing. Story 1's heading still says "sixteen" because it names
a scope split rather than an assertion, and the split is the thing this note declares safe.

### Self-hosting register — entries in this epic's scope

The register lives in Epic 47-01's Notes. **Entry 1** is in scope here in its most direct
form: FR10 is now claimed across three epics — 47-03 (spine tools), 47-04 (templates) and
47-05 (the remaining types) — and no single coverage matrix shows it satisfied. Story 6's
third criterion is the nearest thing to a fix available without a schema change, since it
asserts the enumeration and the templates together. It closes the *test* gap, not the
*storage* gap: dpm still cannot record that FR10 is covered in three places.

No other entry is actionable here.

### Requirements only partially covered by this epic

- **FR9** — fully covered here. This epic owns search.
- **FR10** — the create-tool half. Templates are 47-04; the spine tools are 47-03.
- **FR24** — the tool and extensibility half. The schema and retirement constraints are  
  Epic 47-01 Story 2.
