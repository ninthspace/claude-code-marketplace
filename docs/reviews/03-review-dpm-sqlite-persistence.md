# Review: Spec 47 — dpm SQLite-Backed Artefact Persistence

**Date**: 2026-08-08  
**Source**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Scope**: Spec (no epic exists — reviewed against the spec directly)  
**Agents**: Jordan, Margot, Bella, Casey  
**Findings**: 15 (4 critical, 11 warnings, 0 suggestions)

## Summary

The argument is sound and the evidence behind it — particularly the eleven-spellings-of-seven-categories finding — is the strongest thing in the document. The schema is not yet sound. Every `sql` block was extracted and executed against SQLite for this review, and six defects were confirmed by execution rather than inference: FTS5 cannot be built at all, `coverage` admits duplicate bindings while rejecting legitimate ones, and the domain-scoping the spec claims for `taxonomy` does not exist in any constraint. Three of those are in exactly the subsystems the spec was written to fix, which makes them the findings that matter most.

The spec is not ready to feed `cpm:epics`. The four critical findings are all narrow schema corrections, not redesigns, and the two decisions that would need real thought — AD7's absent detail tables and the sizing of a full-parity first release — are the ones a review cannot settle.

## Findings

### Unclear Requirements

- **[warning]** 📋 **Jordan**: The spec's headline quantified benefit is a benefit dpm does not deliver.  
  → Problem Summary / Deferred: The number the document leads and closes with is "1,686 of the 2,305 lines in `cpm/hooks/lib/`" — the shell dpm makes unnecessary. But Deferred states plainly that those helpers "stay shipped and working in CPM" and that deleting them "is not this spec's business." Nothing in scope removes a line of that 1,686. Set against AD8, which severs every tie between the systems, the effect is that the cost being measured belongs to a product that is not changing. There is no statement anywhere of who runs dpm, what they cannot do today, or what improves for them — the entire case is made in implementation-cost terms for a codebase this work leaves untouched.

- **[warning]** 💻 **Bella**: The constraint-to-drift table is out of step with the schema it summarises, in two independent ways.  
  → Data Model, line 603 and line 608: The table says archival is handled by `document.status = 'archived'`. The DDL constrains `status` to `CHECK (status IN ('pending','complete'))`, and the prose at line 207 argues at length that "`archived_at` is separate from `status` because the two are orthogonal." An implementer working from the summary table writes a value the schema rejects. Separately, line 608 opens "Fourteen rows" — the table has 24. Both errors are stale text left behind by a revision that changed the thing being described, in a document whose thesis is that hand-maintained facts drift out of step with what they describe.

### Missing Acceptance Criteria

- **[warning]** 🧪 **Casey**: Three stated requirements have no acceptance criterion.  
  → Testing Strategy: Cross-referencing the criteria table against every requirement label leaves **FR13** (bounded reads), **NFR5** (discoverable tool names) and **NFR7** (never a black box to its owner) with nothing. FR16–FR20 are correctly absent, being Could Have and Won't Have. NFR7 is the one to worry about: it is the user-facing safety property — a user whose server will not start is not locked out of their planning history — and it is the kind of requirement that is quietly not built when nothing checks it. FR13 is the requirement that keeps a status query from pulling 20 KB into context, which is a stated motivation for the whole design.

### Hidden Complexity

- **[warning]** 📋 **Jordan**: AD6 commits to full parity in the first version and the spec contains no sizing of any kind.  
  → AD6 / In Scope: The first release is 27 tables, an MCP server with typed create/read/update/link/search tools, a migration system, an integrity checker, a projection renderer, a pre-commit guard, a deterministic dump-and-restore path, and roughly twenty rewritten skill files. AD6 dismisses the core-spine alternative in two sentences and asserts that AD3 "is what makes this affordable" without quantifying either side. There is no milestone, no sequencing, and nothing that could be delivered and used before all of it is done. `cpm:epics` will have to invent the decomposition, and the decision about whether parity-first is worth its delay will get made there by default rather than here on the evidence.

### Architectural Risks

- **[critical]** 🏗️ **Margot**: The FTS5 table cannot be built — FR9 is unimplementable as specified. Verified by execution.  
  → Data Model, `document_fts`: The table is declared `fts5(title, body, content='document_section', content_rowid='id')`. An external-content FTS5 table reads its indexed columns from the content table by name, and `document_section` has no `title` column — it has `heading` and `body`. Running the spec's own DDL and then `INSERT INTO document_fts(document_fts) VALUES('rebuild')` fails with `no such column: T.title`. Any query against the index fails the same way. There is a second problem behind the first: a document's title lives on `document`, not on `document_section`, so title search cannot be satisfied by an external-content table over sections at all. FR9 needs either `heading` in place of `title`, or a contentless index populated by the triggers the spec mentions but does not define.

- **[critical]** 🏗️ **Margot**: `coverage`'s uniqueness key is wrong in both directions — it admits duplicate bindings and rejects legitimate ones. Verified by execution.  
  → Data Model, `coverage`: The key is `UNIQUE (requirement_id, story_criterion_id, position)`. Inserting the same requirement, the *same* `spec_fragment` and the same criterion twice at positions 1 and 2 is accepted — two identical coverage rows, each independently verifiable, each counting toward a roll-up. Inserting two *different* fragments against one criterion at the same position is rejected. The discriminator that makes a coverage row what it is — `spec_fragment`, the whole point of the "grain is a fragment, not a requirement" argument at line 369 — is absent from the key, and display order stands in for it. This is the second time this table's `UNIQUE` has been wrong, and a duplicated verified row inflating a coverage roll-up is precisely the false pass NFR6 exists to block.

- **[critical]** 🏗️ **Margot**: `taxonomy` is not domain-scoped by any constraint, and the spec claims it is. Verified by execution.  
  → Data Model, `taxonomy` / `finding` / `audit_finding` / `observation_category`: `finding.category_id` and `finding.severity_id` both reference `taxonomy(id)` with nothing restricting which `domain` the target row belongs to. A `finding` row was created with a `severity` row in the category slot and an `audit_dimension` row in the severity slot; both were accepted. The drift-mapping table asserts the opposite — "A test-approach tag appearing in a retro category slot | FK to `taxonomy`, **domain-scoped**" — and FR24's must-NOT criterion is satisfied by any FK at all, so the test would pass while the named drift remains fully available. Enforcing this needs `UNIQUE (id, domain)` on `taxonomy` and a composite FK against a `CHECK`-pinned domain column on each referencing table.

- **[warning]** 🏗️ **Margot**: Nothing prevents a `blocks` cycle, and a cycle is silent. Verified by execution.  
  → Data Model, `dependency`: The `CHECK` constraints rule out self-edges only. `A blocks B` and `B blocks A` were both inserted without complaint. With `gates_work = 1`, the readiness query over that pair returns nothing ready — which is indistinguishable from "all work is done" and reports no error. FR22 makes "which epics are ready" the query that drives execution, so the failure lands on the primary read path in the shape NFR6 names: a condition that looks like success. Detection is not a schema constraint here; it belongs in the link tool or the FR14 integrity check, and neither is specified to do it.

- **[warning]** 💻 **Bella**: Number allocation silently no-ops when its sequence row does not exist. Verified by execution.  
  → Data Model, `number_sequence` (line 203): Allocation is stated as `UPDATE number_sequence SET next_value = next_value + 1 WHERE … RETURNING next_value - 1`. Run against a database with no seed row for that kind, it returns zero rows and reports success. Nothing in the spec says who inserts the seed row, or when — and for child-numbered kinds a row is needed per parent, so a new spec needs one created at the moment its first epic is written. The table also has no primary key, only two partial unique indexes. FR5's promise that numbers never repeat rests entirely on this statement, and as written the first allocation for any kind returns nothing.

- **[warning]** 🏗️ **Margot**: AD7 decides per-kind detail tables and the data model contains none.  
  → AD7 / Data Model: AD7 states that "kind-specific columns live in detail tables keyed to it," and the consequence paragraph builds on that. Not one detail table appears in the DDL — every kind-specific field is either absent or pushed into `document_section` as undecomposed prose. The Data Model's "abridged to the load-bearing definitions" covers omitting examples of a pattern, not omitting a pattern that has no instance anywhere. An implementer has no way to tell which kinds need a detail table, what belongs in one, or what belongs in a section instead, and FR10's parity claim depends entirely on that answer.

- **[warning]** 💻 **Bella**: FR24 promises retirability for five vocabularies; two of them cannot be retired.  
  → FR24 / `test_approach` / `dependency_kind`: FR24 states that the vocabularies are "seeded with defaults, extensible per project, and retirable without invalidating rows that already use them," and names test approaches among them. `test_approach` and `dependency_kind` are separate tables from `taxonomy` and neither has a `retired_at` column, so neither is retirable. FR24's must-NOT criterion only checks that approaches are a foreign key rather than free text, which both satisfy — so the criterion passes and two-fifths of the requirement is unmet. Each table carries one column `taxonomy` lacks (`kind`, `gates_work`), which is why they were split out; that is a reason to reconcile the two mechanisms deliberately, not to leave the requirement overstating what the schema does.

- **[warning]** 💻 **Bella**: An observation promoted from a story into a retro loses its provenance.  
  → Data Model, `observation`: `CHECK ((retro_id IS NULL) <> (story_id IS NULL))` makes parentage exclusive, and the comment says the story-level `**Retro**:` field is "the same thing recorded earlier." When that observation is later gathered into a retro, satisfying the `CHECK` means clearing `story_id` — so the record of which story produced it is destroyed by the act of promoting it. `retro_application` records where a retro's lesson was later applied, but nothing records where an observation came from. The spec never describes the promotion path, so this only surfaces when someone implements it.

### Testability Concerns

- **[critical]** 🧪 **Casey**: An acceptance criterion references two columns that do not exist on the table it tests.  
  → Testing Strategy, NFR6 (line 692): "A duplicate coverage row is rejected for every combination of NULL and non-NULL in `story_id` / `task_id`." `coverage` has neither column — it has `requirement_id`, `spec_fragment`, `story_criterion_id`, `position`, `verified_at`, `binding_hash`, and the first four are all `NOT NULL`. The criterion is left over from a superseded draft of the table and cannot be written as a test. It also masks a live problem: because those columns are gone, the NULL-semantics hazard no longer applies to `coverage` at all, while the key that replaced it is wrong for an unrelated reason (see Margot's `coverage` finding above). The general-case criterion on line 693 is the one still doing work.

- **[warning]** 🧪 **Casey**: FR10's parity criterion has no list to check against, so it cannot fail.  
  → Testing Strategy, FR10: The criterion is "Every artefact type CPM produces has a table, a create tool, and a projection template." FR10 names twenty-one types in prose, and the mechanism that would enumerate them — the `document_kind` seed rows — has no seed list anywhere in the spec. Two of the twenty-one have no visible home: "verification record" maps to nothing beyond `coverage.verified_at`, and "quick record" is presumably a `document_kind` but is never confirmed. A parity test with no enumeration passes by construction, and parity is what AD6 spends the entire first release buying.

- **[warning]** 🧪 **Casey**: Four criteria are stated as universal negatives over unspecified code and cannot be falsified.  
  → Testing Strategy, FR4 (line 658), AD8 (line 686), FR2 (line 654), NFR6 (line 691): "must NOT — **any code path** derives a requirement's class by parsing its label text" and "must NOT — **any component** reads, globs, or parses a markdown file under `docs/`" have no bounded thing to check; a passing run means nobody found one, not that none exists. AD8's is also imprecise in a way that will bite — the projection renderer necessarily touches `docs/`, and a renderer that checks whether a file exists before writing globs it, so the criterion as worded flags a component the design requires. NFR6's "Each false-pass-capable condition has a test asserting it blocks rather than warns" is a criterion about the test suite with no enumeration of the conditions it ranges over. All four are tagged `[integration]`; what they actually describe is a static property of the corpus, which is the shape FR3 gets right by naming the exact thing to grep for.

## Remediation

**Path**: Standalone tasks (no epic doc exists for this spec)  
**Tasks created**: 15

| # | Finding | Severity | Task |
|---|---------|----------|------|
| 1 | FTS5 external-content table cannot be built | critical | Fix: FTS5 external-content table cannot be built (FR9) |
| 2 | `coverage` key admits duplicates, rejects valid rows | critical | Fix: coverage uniqueness key admits duplicates and rejects valid rows |
| 3 | `taxonomy` references not domain-scoped | critical | Fix: taxonomy references are not domain-scoped |
| 4 | NFR6 criterion names nonexistent columns | critical | Fix: NFR6 acceptance criterion names columns that do not exist |
| 5 | `blocks` cycles accepted and silent | warning | Add cycle detection for gating dependency edges |
| 6 | Number allocation silently no-ops | warning | Specify number_sequence seeding and fix silent no-op allocation |
| 7 | AD7's detail tables declared, none defined | warning | Decide and specify AD7's per-kind detail tables |
| 8 | FR24 retirability unmet by two vocabularies | warning | Reconcile test_approach and dependency_kind with FR24's retirability promise |
| 9 | Promotion destroys an observation's story link | warning | Preserve story provenance when an observation is promoted to a retro |
| 10 | FR13, NFR5, NFR7 have no criteria | warning | Add acceptance criteria for FR13, NFR5 and NFR7 |
| 11 | FR10 parity criterion has no enumeration | warning | Make FR10's parity criterion checkable by enumerating the artefact kinds |
| 12 | Four unfalsifiable universal-negative criteria | warning | Rewrite four unfalsifiable "must NOT — any code path" criteria |
| 13 | Headline benefit is out of scope | warning | State dpm's user-facing value, separately from CPM's shell line count |
| 14 | Drift table contradicts the schema; count stale | warning | Correct the constraint-to-drift table: archived-as-status and the row count |
| 15 | Full parity committed with no sizing | warning | Size and sequence the full-parity first release (AD6) |

**Sequencing**: task 4 is blocked by task 2 (the replacement criterion tests the corrected key); task 8 is blocked by task 3 (folding the vocabularies into `taxonomy` would change the composite-FK design); task 7 is blocked by task 11 (detail tables need the kind enumeration first).

**Method note**: every schema finding above was confirmed by extracting the spec's `sql` blocks, executing them against SQLite, and probing with a deliberate violation. The four criticals and findings 5, 6 are verified failures rather than inferred risks.
