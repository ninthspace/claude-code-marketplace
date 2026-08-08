# Parity and Search

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Date**: 2026-08-08  
**Status**: Pending  
**Blocked by**: Epic 47-01-epic-substrate, Epic 47-03-epic-server-and-spine-tools, Epic 47-04-epic-projection-guard-and-merge

Milestone M3 (AD6). Epic 47-03 gave the seven spine types their tools; this completes the
enumeration and makes the corpus searchable. The dependency on 47-04 is narrow and real —
Story 2's multi-category criterion and Story 6's parity closure both assert what the
projection renders.

## Give the remaining sixteen entity types create, read and update tools [plan]
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR10, FR1, FR27

**Acceptance Criteria**:

- All twenty-three entity types — thirteen seeded `document_kind` rows, eight child tables and two standalone tables — have a create tool, and the enumeration has no member without one [integration]
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

### Enumerate the twenty-three entity types against the registered tool list
**Task**: 1.6  
**Description**: Read the enumeration from the seeded `document_kind` rows plus a declared list of child and standalone tables, and compare against what the server registered. This is what makes the boundary with Epic 47-03 non-load-bearing — see the Notes. It reads the set from the live schema, so it caught `milestone` the moment FR27 added it, without amendment.  
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

### Write add and retire tools for taxonomy rows, test approaches and dependency kinds
**Task**: 2.1  
**Description**: Three vocabularies, one retirement semantic. Epic 47-01 Story 2 built the constraint; this makes it reachable without SQL, which is what "extensible per project" requires.  
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
**Satisfies**: FR9, FR10, FR24, NFR7

**Acceptance Criteria**:

- Creating one row of every indexed entity type through its own tool, then searching a term common to all of them, returns a hit from every one — the tools and the triggers are built by different stories and nothing else runs them together [integration]
- A create tool refuses a vocabulary row retired through Story 2's retire tool, and the refusal names the retired item [integration]
- Every one of the twenty-three entity types, created through its own tool, appears in the projection its kind renders into — or inside its parent's, for the ten that produce no file and for the ADR [integration]
- must NOT — a search returns a hit whose entity and row id do not resolve to a live row through that entity's read tool [integration]

### Write integration tests for Parity and search
**Task**: 6.1  
**Description**: The third criterion is the parity closure: FR10's enumeration (Story 1) and FR10's templates (Epic 47-04 Story 2) are the same requirement checked in two epics, and this is the only place both are true at once. The final clause guards the seam NFR7 cares about — a search index drifted from the tables returns hits nothing can open.  
**Status**: Pending

---

## Notes

### The FTS tables arrive as a migration, not in the founding DDL

Stories 3 and 4 write both virtual tables and their fifteen triggers, and Epic 47-01 Story 1
writes "the DDL". The boundary is drawn here: the FTS objects are 47-05's, delivered through
the migration runner, which makes this epic the runner's first real customer. Epic 47-01
Story 8's DDL-versus-migration parity criterion covers them once they land, so the split
costs no assertion. Approved by Chris on 2026-08-08.

### Where the twenty-three types divide between this epic and 47-03

Epic 47-03 Story 2 covers seven spine types by name; this epic covers the rest. The count
does not resolve cleanly — `coverage` is both a `document_kind` and a child table, `brief` is
two kinds, and `session state` has a table built in 47-03 Story 6 without typed tools
enumerated there. Rather than fixing a number that the spec itself qualifies at §332, Story
1's enumeration criterion reads the set from the live schema and fails on any member without
a tool. **The boundary is therefore not load-bearing**: however it is drawn, the enumeration
catches anything that falls between the two epics. This is the one place in the breakdown
where a partial split is safe, and it is safe only because the requirement was written as an
enumeration rather than a count.

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
