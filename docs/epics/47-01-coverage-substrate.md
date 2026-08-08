# Coverage Matrix: Substrate

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Epic**: docs/epics/47-01-epic-substrate.md  
**Date**: 2026-08-08

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR1 | Every CPM artefact type is a table with typed columns, not a markdown file parsed at read time. | Every column named `*_id` on every table appears in that table's `PRAGMA foreign_key_list`, with no exceptions list (AD7) | Story 1 | `[unit]` | |
| 2 | FR2 | `PRAGMA foreign_keys=ON` is enforced on every connection, and a violation is an error at write time rather than a discrepancy discovered later. | Creating an epic with a non-existent `spec_id` fails, and no row is written | Story 1 | `[integration]` | |
| 3 | FR2 (must NOT) | `PRAGMA foreign_keys=ON` is enforced on every connection | must NOT — a foreign-key violation is accepted because `foreign_keys` defaulted off on a fresh connection | Story 1 | `[integration]` | |
| 4 | FR2 | An epic cannot name a spec that does not exist; a coverage row cannot cite an absent requirement | Every foreign key whose target is `document` names `(id, kind)`, except the three the Data Model names as legitimately kind-agnostic — and that exceptions list is the one in the Data Model, not one the test may extend | Story 1 | `[unit]` | |
| 5 | FR2 (must NOT) | An epic cannot name a spec that does not exist | must NOT — a `story` is accepted under a spec, a `requirement` under an epic, or a detail row on a document of another kind | Story 1 | `[unit]` | |
| 6 | AD9 | every surrogate primary key in the schema is a ULID stored as `TEXT` | Every primary key in `sqlite_schema` is declared `TEXT`, excluding the FTS5 shadow tables, which SQLite creates with `INTEGER PRIMARY KEY` and dpm does not author | Story 1 | `[unit]` | |
| 7 | AD9 | Ids sort by creation time and carry no meaning. | Ten thousand ids generated in one process are unique and sort in generation order | Story 1 | `[unit]` | |
| 8 | FR4 | Requirement class, MoSCoW band, status, test-approach tag, and coverage verification state are typed columns constrained by `CHECK`. | A status value outside its enum is rejected by `CHECK`, not coerced | Story 2 | `[unit]` | |
| 9 | FR24 | Observation categories, finding categories, audit dimensions, severities and test approaches are rows referenced by foreign key | must NOT — any category, severity, dimension or approach is stored as free text rather than a foreign key | Story 2 | `[integration]` | |
| 10 | FR24 | seeded with defaults, extensible per project, and retirable without invalidating rows that already use them | A severity row is rejected in a category slot, and an audit dimension in a severity slot, on `finding` and `audit_finding` alike | Story 2 | `[unit]` | |
| 11 | FR24 | retirable without invalidating rows that already use them | Retiring a taxonomy row leaves rows referencing it intact and readable | Story 2 | `[unit]` | |
| 12 | FR24 (must NOT) | retirable without invalidating rows that already use them | must NOT — a new row is accepted referencing a taxonomy row, test approach or dependency kind already retired, so that retirement stops rows arriving as well as preserving those that have | Story 2 | `[unit]` | |
| 13 | FR10 | Every artefact type CPM produces is modelled from the outset | must NOT — a `document_kind` row exists that the parity enumeration does not name, or the reverse | Story 2 | `[unit]` | |
| 14 | FR5 | Human-facing artefact numbers are allocated monotonically and are never reused, including after archival. | Numbers allocated across create-archive-create never repeat, including past 99 | Story 3 | `[unit]` | |
| 15 | FR5 | No glob, no filename parse, no archive-mirror contract. | The first allocation for a kind with no `number_sequence` row returns 1, and the first child allocation under a new parent does the same | Story 3 | `[unit]` | |
| 16 | FR5 (must NOT) | Human-facing artefact numbers are allocated monotonically | must NOT — an allocation returns no row, or returns success without a number | Story 3 | `[unit]` | |
| 17 | FR23 | Root-numbered kinds (a spec) and child-numbered kinds (an epic, numbered within its spec and restarting at 1 per parent) are both allocated monotonically and never reused. | Two epics under different specs may both hold sequence 1; two under the same spec may not | Story 3 | `[unit]` | |
| 18 | FR23 (must NOT) | Root-numbered kinds (a spec) and child-numbered kinds (an epic, numbered within its spec and restarting at 1 per parent) | must NOT — a row carries both `number` and `sequence`, or neither, unless its kind is declared `numbering = 'none'` | Story 3 | `[unit]` | |
| 19 | FR22 | Blocking, spec-to-spec lineage, and ADR constraint are rows in one edge table with a kind | A story-to-story `blocks` edge and a spec-to-spec `builds_on` edge both round-trip through one table | Story 4 | `[unit]` | |
| 20 | FR22 | so "which epics are ready" is a query, a blocker's completion is visible to everything downstream | A `builds_on` edge does not gate readiness; a `blocks` edge does | Story 4 | `[unit]` | |
| 21 | FR22 (must NOT) | Source and target may each be a document or a story. | must NOT — a document or story depends on itself | Story 4 | `[unit]` | |
| 22 | FR22 (must NOT) | rows in one edge table with a kind | must NOT — the same edge is storable twice, for any combination of NULL source/target columns | Story 4 | `[unit]` | |
| 23 | FR12 | A `schema_version` row and an ordered migration set, applied automatically on server start, so a plugin update never requires the user to intervene. | A database at schema version *n* is migrated to *n+1* on server start with no user action | Story 5 | `[integration]` | |
| 24 | FR14 | A verification tool reports orphans, dangling links, and each entry in the cross-row invariant register (Data Model), so a corrupted state is diagnosable without SQL. | Every numbered entry in the cross-row invariant register has a check in the integrity tool, and the tool has no *register-derived* check absent from the register | Story 6 | `[integration]` | |
| 25 | FR14 | reports orphans, dangling links | The integrity tool reports a deliberately orphaned row | Story 6 | `[integration]` | |
| 26 | FR14 (must NOT) | so a corrupted state is diagnosable without SQL | must NOT — the integrity tool reports a violation it cannot locate, or passes a database holding one | Story 6 | `[integration]` | |
| 27 | NFR6 | Any condition that could produce a false pass — a constraint violation swallowed, a projection silently stale, a search index behind the data — reports and blocks. | Every condition in the false-pass register has a test asserting it blocks rather than warns, and the register has no unregistered entries | Story 6 | `[integration]` | |
| 28 | FR12 | applied automatically on server start | A database built by running the migration set from empty has a `sqlite_schema` identical to one built by executing the DDL directly — every table, index, trigger and constraint | Story 8 | `[integration]` | |
| 29 | FR14 | each entry in the cross-row invariant register (Data Model) | The integrity tool passes on a freshly migrated and seeded database, and fails on each of the thirteen register violations injected into it in turn | Story 8 | `[integration]` | |
| 30 | FR2 | An epic cannot name a spec that does not exist | An epic whose `parent_id` names a review is rejected, and one naming a spec is accepted | Story 1 | `[unit]` | |
| 31 | FR2 | an artifact link cannot point at a missing document | A review parents onto either a spec or an epic, both being allow-listed, and onto a runbook not at all | Story 1 | `[unit]` | |
| 32 | FR2 (must NOT) | a coverage row cannot cite an absent requirement | must NOT — `observation.library_doc_id` accepts a document that is not of kind `library` | Story 1 | `[unit]` | |
| 33 | FR2 (must NOT) | a violation is an error at write time rather than a discrepancy discovered later | must NOT — a document's `parent_kind` can misdescribe the kind of the parent it points at | Story 1 | `[unit]` | |
| 34 | NFR6 | a constraint violation swallowed | Binding the same `(requirement_id, spec_fragment, story_criterion_id)` twice is rejected, and two different fragments against one criterion are both accepted | Story 1 | `[unit]` | |
| 35 | NFR6 (must NOT) | Any condition that could produce a false pass | must NOT — any `UNIQUE` constraint over a nullable column is relied on to reject duplicates, given SQLite's distinct-NULL semantics | Story 1 | `[unit]` | |
| 36 | NFR6 (must NOT) | the failure being designed against is one that looks like success | must NOT — `coverage` identity depends on `position`, so that display order can admit or reject a binding | Story 1 | `[unit]` | |
| 37 | FR4 | Nothing infers a type by parsing an identifier. | Loading a corpus whose labels are all replaced with opaque identifiers leaves every class, MoSCoW band and exclusion value unchanged | Story 2 | `[integration]` | |
| 38 | FR23 | restarting at 1 per parent | Child sequences restart at 1 per parent and never reuse a value after deletion | Story 3 | `[unit]` | |
| 39 | FR23 | both allocated monotonically and never reused | A kind declared `numbering = 'none'` accepts a document carrying neither `number` nor `sequence` | Story 3 | `[unit]` | |
| 40 | FR23 (must NOT) | Root-numbered kinds (a spec) and child-numbered kinds | must NOT — a kind declared `numbering = 'root'` accepts a row carrying `sequence`, or the reverse | Story 3 | `[unit]` | |
| 41 | FR22 | so "which epics are ready" is a query | An epic blocked by two epics yields two `dependency` rows, and completing both makes it selectable as ready | Story 4 | `[integration]` | |
| 42 | FR22 | Lineage kinds are left alone — a `builds_on` cycle is meaningless but harmless, because nothing waits on it. | A `builds_on` cycle is accepted, since no readiness query traverses it | Story 4 | `[unit]` | |
| 43 | FR14 | each entry in the cross-row invariant register (Data Model) | The integrity tool reports a `gates_work` cycle introduced by restoring a dump (register #1) | Story 6 | `[integration]` | |
| 44 | FR14 | each entry in the cross-row invariant register (Data Model) | An ADR at `decision_status = 'superseded'` with no outgoing `supersedes` edge is reported (register #2) | Story 6 | `[unit]` | |
| 45 | FR14 | each entry in the cross-row invariant register (Data Model) | A coverage row joining one spec's requirement to another spec's story criterion is reported (register #3) | Story 6 | `[unit]` | |
| 46 | FR14 | each entry in the cross-row invariant register (Data Model) | A `coverage_story` row naming a story outside the coverage row's epic is reported (register #4) | Story 6 | `[unit]` | |
| 47 | FR14 | each entry in the cross-row invariant register (Data Model) | A `number_sequence` row behind the highest number already allocated for its kind is reported and repairable (register #5) | Story 6 | `[unit]` | |
| 48 | FR14 | each entry in the cross-row invariant register (Data Model) | A `builds_on` edge between two epics is reported (register #6) | Story 6 | `[unit]` | |
| 49 | FR14 | each entry in the cross-row invariant register (Data Model) | A review scoped to a story outside the epic it reviews is reported (register #7) | Story 6 | `[unit]` | |
| 50 | FR14 | each entry in the cross-row invariant register (Data Model) | An accepted ADR carrying zero or two `chosen` options is reported (register #8) | Story 6 | `[unit]` | |
| 51 | FR14 | each entry in the cross-row invariant register (Data Model) | A `spec_fragment` that is not a substring of its requirement's text is reported (register #9) | Story 6 | `[unit]` | |
| 52 | FR14 | each entry in the cross-row invariant register (Data Model) | A row referencing a vocabulary item retired before that row was written is reported (register #10) | Story 6 | `[unit]` | |
| 53 | FR14 | each entry in the cross-row invariant register (Data Model) | A `session.superseded_by` cycle is reported (register #11) | Story 6 | `[unit]` | |
| 54 | FR21 | editing either the requirement fragment or the story criterion resets it to unverified automatically | Editing a story criterion's text clears `verified_at` and `binding_hash` on every coverage row bound to it | Story 7 | `[unit]` | |
| 55 | FR21 | editing either the requirement fragment or the story criterion resets it to unverified automatically | Editing a requirement's text clears verification on its coverage rows | Story 7 | `[unit]` | |
| 56 | FR21 | the fragment is not `requirement.text` — it is `coverage.spec_fragment`, a stored verbatim slice, which is also half of what `binding_hash` hashes | Editing `coverage.spec_fragment` clears `verified_at` and `binding_hash` on that row | Story 7 | `[unit]` | |
| 57 | FR21 | A coverage row records what it was verified against | control — an edit that leaves the text byte-identical does not clear verification, on all three watched columns | Story 7 | `[unit]` | |
| 58 | FR21 (must NOT) | Every coverage matrix CPM writes states this rule in prose and relies on an agent to honour it; here the database enforces it. | must NOT — a coverage row holds `verified_at` while `binding_hash` is NULL, or the reverse | Story 7 | `[unit]` | |
| 59 | FR21 (must NOT) | a trigger must watch every column the binding is computed from, and the binding is computed from two texts held in three places | must NOT — any column the binding is computed from can be edited without clearing verification | Story 7 | `[unit]` | |
| 60 | FR21 | and decays when that text changes | A coverage row verified before a migration is still verified after it, and a text edit made after the migration still clears it — a migration that recreates a table drops its triggers, and nothing in Story 5 or Story 7 alone observes that | Story 8 | `[integration]` | |
| 61 | FR10 | Every artefact type CPM produces is modelled from the outset | `document_kind.dir` is nullable, and a kind declaring `dir IS NULL` accepts documents that render inside a parent rather than into a file of their own | Story 1 | `[unit]` | |
| 62 | FR27 | A specification's milestones are rows scoped to it, ordered, and joined to the artefacts that deliver them | Two specs may each hold a milestone labelled `M1`; one spec may not hold two, and positions are unique within a spec | Story 1 | `[unit]` | |
| 63 | FR27 (must NOT) | an epic that spans two milestones says so rather than being filed under one | must NOT — an artefact's milestone is a column, so an epic spanning two must be filed under one | Story 1 | `[unit]` | |
| 64 | FR2 | An epic cannot name a spec that does not exist | An `adr` parents onto a spec, a brief or a discussion, and onto an epic not at all | Story 2 | `[unit]` | |
| 65 | FR2 | An epic cannot name a spec that does not exist | A `retro` parents onto an epic, a spec or a quick record — the three sources `cpm:retro` actually accepts | Story 2 | `[unit]` | |
| 66 | FR27 | so "which epics are in M2" is a query | An epic joined to two milestones is returned by a readiness query for either, and reports both | Story 4 | `[integration]` | |
| 67 | FR14 | each entry in the cross-row invariant register (Data Model) | A `document_milestone` row whose document and milestone belong to different specs is reported (register #12) | Story 6 | `[unit]` | |
| 68 | FR14 | each entry in the cross-row invariant register (Data Model) | A `{{ref:}}` marker naming a deleted document is reported, naming the column and row it sits in, and a marker naming a live document is not (register #13) | Story 6 | `[unit]` | |
| 69 | FR26 | Completeness is therefore a separate, deliberate claim on the requirement, cleared automatically whenever a coverage row for it is added or removed | Claiming completeness on a requirement, then inserting a coverage row for it, leaves the claim cleared | Story 7 | `[unit]` | |
| 70 | FR26 | cleared automatically whenever a coverage row for it is added or removed, its fragment is edited | Deleting a coverage row, and editing a bound fragment, each clear the claim on that row's requirement | Story 7 | `[unit]` | |
| 71 | FR26 | or the requirement's own text changes | Editing a requirement's text clears its own completeness claim, not only its coverage rows' verification | Story 7 | `[unit]` | |
| 72 | FR26 | Whether a requirement's bindings *account for* it is recorded, and decays like a verification. | control — an edit leaving the requirement's text byte-identical does not clear the claim, and neither does an update to an unrelated column | Story 7 | `[unit]` | |
| 73 | FR26 | a requirement with one of five obligations bound reads exactly like one fully covered — a roll-up that matches something reports full coverage | A requirement with fragments bound and no claim is distinguishable by query from one with the same fragments and a current claim | Story 7 | `[integration]` | |
| 74 | FR26 (must NOT) | Completeness is therefore a separate, deliberate claim on the requirement | must NOT — `coverage_claimed_at` is set while `coverage_claim_hash` is NULL, or the reverse | Story 7 | `[unit]` | |
| 75 | FR12 | A `schema_version` row and an ordered migration set, applied automatically on server start | Seeding, retiring a vocabulary row, then applying a migration leaves the retirement in force and the rows referencing it readable | Story 8 | `[integration]` | |
| 76 | FR5 | Human-facing artefact numbers are allocated monotonically and are never reused, including after archival. | A number allocated before a migration is not reissued after it | Story 8 | `[integration]` | |
| 77 | FR26 | and decays like a verification | A completeness claim made before a migration survives it, and a coverage row inserted after the migration still clears the claim — the same trigger-loss failure one level up, on the four FR26 triggers rather than the three FR21 ones | Story 8 | `[integration]` | |
| 78 | FR27 | joined to the artefacts that deliver them | A document assigned to two milestones keeps both across a migration, and the spec-scoping pair check still refuses a cross-spec assignment afterwards | Story 8 | `[integration]` | |
| 79 | FR12 (must NOT) | applied automatically on server start, so a plugin update never requires the user to intervene | must NOT — the migration runner and the DDL produce schemas differing in any constraint, index or trigger | Story 8 | `[integration]` | |

**Rows 30–60 were added on 2026-08-08**, when the cross-epic union check ran early against
the spec's 113 tagged criteria and found FR21 uncovered in every epic. They are appended
rather than interleaved so that rows 1–29, which Chris approved, keep their numbers — the
`Covered by` column carries the grouping, not the row order. The two changes to rows 1–29
are Story 7 → Story 8 on rows 28 and 29, following the insertion of the decay-trigger story.

**Rows 61–79 were added on 2026-08-08 by the pivot that closed the self-hosting register** —
FR26's six decay criteria, FR27's milestone criteria, the two parentage criteria that let
`adr` and `retro` reach their real parents, the nullable `dir`, and register entries #12 and
#13. Row 29's count moved from eleven to thirteen for the same reason.

**Rows 30–42 asserted coverage by criteria no story carried, until this pivot.** They were
appended with rows 43–60 during the FR21 gap fix; the six FR21 criteria went into both the
epic and the matrix, and these thirteen went into the matrix alone. A matrix row citing a
criterion that does not exist is a coverage claim with nothing behind it — self-hosting
register entry 1's failure mode, in the document that records entry 1, for the second time.
All thirteen are now criteria on Stories 1–4. The check that found it is a set comparison
between the epic's criteria and the matrix's `Story Criterion` column, run in both
directions; nothing in the breakdown ran it until the pivot.

**Why FR21 was missed, since the omission is the interesting part.** Story 1 writes the DDL,
and the DDL contains the three triggers — so the work was in scope and only its *verification*
was absent. A criterion asserting the schema is created does not assert a trigger fires, and
FR21 is the one requirement in this spec whose entire content is that something fires. §1234
records that the real corpus exposed eight schema defects, one of them a false pass in this
exact subsystem; the breakdown had reproduced the same blind spot one layer up.

**Rows 43–53, 67 and 68 expand a roll-up, and are the one declared exception to the rule that
every matrix row cites a criterion the epic carries.** They specialise Story 6's "Each of the
thirteen register entries is reported in turn, naming the rows", which genuinely asserts all
thirteen — so this is a traceability change and not new work. Row 29 is Story 8's migrated
counterpart of the same roll-up. It is worth making explicit because a matrix in which one
row stands for thirteen spec criteria is self-hosting register entry 1's exact shape,
appearing in the document that records entry 1. The set comparison run at the end of the
pivot expects exactly these thirteen and nothing else.

**Partial coverage note**: FR10 is covered here only in its seeding half (rows 13 and 61).
Its other obligation — all twenty-three entity types having a create tool — belongs to Epics
47-03 and 47-05. FR26 is complete here; FR27's projection half belongs to Epic 47-04. Since
this pivot, the schema *can* distinguish partial coverage from full: FR26 makes completeness
a claim rather than a roll-up, which is what register entry 1 asked for.
