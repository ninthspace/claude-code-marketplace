# Projection, Guard and Merge

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Date**: 2026-08-08  
**Status**: Pending  
**Blocked by**: Epic 47-02-epic-dump-and-restore, Epic 47-03-epic-server-and-spine-tools

Milestones M2 and M4 (AD6) — the projection and its guard are M2, the merge tool is M4. An
epic spanning two milestones is register entry 2 in the flesh, and the reason the entry
names this epic by number.

This is seam 2 of the spec's three (Testing Strategy): database state → markdown. It holds
the **merge tool**, moved here from Epic 47-02 because FR8's renumber criterion renames a
projection file and this is where projection filenames are decided.

## Render a document to markdown deterministically [plan]
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR6, FR28, AD3, AD8

**Acceptance Criteria**:

- Regenerating the projection twice from one database state yields byte-identical output [integration]
- A value written through a create tool appears in the rendered markdown for its document — determinism without this is satisfied by a renderer that emits nothing [integration]
- Two databases holding identical logical content, with child rows inserted in different orders, render byte-identical markdown [integration]
- No source file outside the projection renderer imports a markdown parser, and the renderer's only filesystem calls under `docs/` are writes — asserted over the module list, not over behaviour [integration]
- must NOT — a projected collection has no ordering column and no declared tiebreak, so its render order is whatever the query returns [unit]
- A `{{ref:<id>}}` marker in a section body and in a `requirement.text` both render as the target's current human identifier [integration]
- must NOT — a projected body contains a literal artefact number that no row produced [unit]

### Load a document and its children with an explicit `ORDER BY` on every collection
**Task**: 1.1  
**Description**: Every projected collection orders by a declared column, not by whatever the query returns. AD9's ULIDs make `ORDER BY id` a total order where no `position` exists, which is what closes the no-tiebreak clause.  
**Status**: Pending

### Render the spec kind end-to-end as the renderer's worked example
**Task**: 1.2  
**Description**: One template, not thirteen — Story 2 completes the set. This exists so the fidelity criterion has something to assert against: a determinism test passes trivially against a renderer that emits nothing.  
**Status**: Pending

### Write the fixed-format text writer — LF, trailing newline, no timestamps, no locale collation
**Task**: 1.3  
**Description**: Same discipline as Epic 47-02's dump formatter and for the same reason. Sorting anywhere in the render path uses byte order, never a locale collator.  
**Status**: Pending

### Write output with whole-file writes and keep markdown parsing out of the dependency graph
**Task**: 1.4  
**Description**: AD8's one-way rule is asserted over the module list, so the constraint is on imports as much as on behaviour. No read-modify-write under `docs/`.  
**Status**: Pending

### Resolve `{{ref:<id>}}` markers to the target's current human identifier
**Task**: 1.5  
**Description**: FR28. Markers are resolved on every prose column, not only `document_section.body` — retro 33's reference to spec 47 lives in `observation.text`, which is why a section-scoped reference table was rejected during the pivot. Resolution is total: an unresolvable marker raises, and register #13 catches the ones that reach the database anyway. The must-NOT is what makes this checkable — a projected body may contain no literal artefact number that no row produced.  
**Status**: Pending

### Write tests for Render a document to markdown deterministically
**Task**: 1.6  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Write a projection template for every document kind
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR10

**Acceptance Criteria**:

- Each of the thirteen `document_kind` rows has a projection template; the ten non-document types and the ADR render inside a parent's template and are asserted to appear in one [integration]
- The template registry is enumerated against the seeded `document_kind` rows, so a kind seeded without a template fails rather than rendering [unit]
- must NOT — a missing template falls back to a generic renderer, so an untyped dump ships in place of a failure [unit]

### Write templates for the remaining twelve document kinds
**Task**: 2.1  
**Description**: Story 1 delivered the spec template; this completes the thirteen seeded kinds.  
**Status**: Pending

### Render the ten non-document child types, and the ADR, inside their parent's template
**Task**: 2.2  
**Description**: These have no file of their own. The ADR joins them not as a child table but as a `document_kind` whose `dir IS NULL` — it keeps `decision_status`, `adr_option` and the tradeoff axes while rendering inside the spec that holds it, which is how the pivot closed register entry 3. Each must be asserted to appear in a parent's output, or the enumeration passes while the content is invisible.  
**Status**: Pending

### Build the kind→template registry and enumerate it against the seeded `document_kind` rows
**Task**: 2.3  
**Description**: Read from the live table rather than a hand-kept list, so seeding a fourteenth kind fails the test instead of silently rendering nothing. Resolution is total: an unregistered kind raises, with no generic fallback.  
**Status**: Pending

### Write tests for Write a projection template for every document kind
**Task**: 2.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Guard against hand-edits and stale generated files
**Story**: 3  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR7, AD8

**Acceptance Criteria**:

- A hand-edited generated file causes the pre-commit guard to exit non-zero, naming the file [feature]
- A write made since the last commit leaves `.dpm/dpm.sql` stale, and the guard regenerates it and fails, naming it [feature]
- must NOT — a hand-edit is silently overwritten with no diagnostic [feature]
- must NOT — a commit is accepted carrying a regenerated projection and an unregenerated dump [feature]
- must NOT — the pre-commit divergence guard compares by parsing a generated file rather than by regenerating and diffing bytes [integration]

### Regenerate the projection and the dump in the pre-commit hook and diff bytes
**Task**: 3.1  
**Description**: Regenerate-and-compare, never parse-and-compare. Parsing a generated file to check it is the failure mode AD8's clause names, and it would reintroduce the parser import Task 1.4 kept out.  
**Status**: Pending

### Report divergence by naming every differing file, and exit non-zero
**Task**: 3.2  
**Description**: Naming the file is the criterion, not just the exit code. Nothing overwrites a hand-edit: the guard refuses the commit and leaves the edit in place for the user to see.  
**Status**: Pending

### Fail on a stale `.dpm/dpm.sql`, on the same footing as a hand-edited projection
**Task**: 3.3  
**Description**: One guard, not two, because a commit carrying a fresh projection and a stale dump is the worse failure and would otherwise pass — the markdown looks current and the committed database is behind it.  
**Status**: Pending

### Write tests for Guard against hand-edits and stale generated files
**Task**: 3.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Merge two branches and renumber colliding numbers [plan]
**Story**: 4  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR8, FR28, AD4, AD9

**Acceptance Criteria**:

- Two branches each adding a spec allocate distinct ULIDs for every row, so the merged dump has no primary-key collision on any table [integration]
- Two branches each adding an epic produce a resolvable text conflict, and the merged dump restores [feature]
- When both branches allocated the same human number, the merge tool renumbers one, renames its projection file, and re-renders the artefacts that referenced it; the restored database then passes `PRAGMA foreign_key_check` and the register's checks [feature]
- Renumbering a document through the merge tool changes no stored text, and the next render resolves every marker naming it to the new number [feature]
- must NOT — a number collision is resolved by silently overwriting one side, or left for the user to find when the projection renders two artefacts with the same number [feature]

### Detect human-number collisions across the two sides of a merge
**Task**: 4.1  
**Description**: ULIDs never collide, so the merge is only ever a text conflict; human numbers do collide, because both branches allocated from their own `max + 1`. Detection is separate from repair so the no-silent-overwrite clause has something to assert against.  
**Status**: Pending

### Renumber one side — re-allocate from `number_sequence`, rename its projection file, re-render what referenced it
**Task**: 4.2  
**Description**: All three, or the projection renders two artefacts with the same number. The rename depends on Story 1's naming, which is why this epic owns the merge tool at all. The third is a re-render and not a rewrite: no reference ever stored a number, so a structural reference is a foreign key the renumber does not touch and a prose reference is a `{{ref:<id>}}` marker Task 1.5 resolves. The merge tool writes no text into any row.  
**Status**: Pending

### End the merge with a restore, `PRAGMA foreign_key_check`, and the register sweep
**Task**: 4.3  
**Description**: Reuses Epic 47-02 Story 2's restore path rather than reimplementing the checks. A merged dump that restores is the only evidence the conflict was resolved correctly.  
**Status**: Pending

### Write tests for Merge two branches and renumber colliding numbers
**Task**: 4.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Verify cross-story integration for Projection, guard and merge
**Story**: 5  
**Status**: Pending  
**Blocked by**: Story 1, Story 2, Story 3, Story 4  
**Satisfies**: FR6, FR7, FR8, NFR6

**Acceptance Criteria**:

- A database holding one document of each of the thirteen kinds regenerates byte-identically twice, so determinism is asserted across the full template set rather than the single kind Story 1 used [integration]
- The pre-commit guard runs against the real renderer and the real dumper, and a commit carrying only a database write is rejected until both generated artefacts are regenerated [feature]
- A merge that renumbers a spec yields a projection tree whose filenames and cross-references agree, and regenerating from the merged database changes no bytes [feature]
- must NOT — the guard passes because it regenerates with a renderer that silently skips a kind it has no template for [integration]

### Write integration tests for Projection, guard and merge
**Task**: 5.1  
**Description**: The final clause is what earns this story. Story 2's registry test and Story 3's guard test both pass in a world where the guard regenerates twelve of thirteen kinds and diffs clean, because neither one observes the other. Story 3 can also pass against a stubbed renderer — its own criteria are about exit codes and diagnostics, not about which renderer produced the bytes.  
**Status**: Pending

---

## Notes

### Self-hosting register — entries in this epic's scope

The register lives in Epic 47-01's Notes, where both entries this epic raised are now CLOSED
by the pivot of 2026-08-08. The rows are there and not repeated here, because a register kept
in two places is the defect this spec was written to remove.

**Entry 2 named this epic by number**: AD6's build order had no table and no column, and this
epic spans M2 and M4, so the corpus could not record where in the build order its own largest
epic sat. FR27 makes milestones spec-scoped rows and `document_milestone` a many-to-many join
— many-to-many precisely so this epic can say it spans two rather than being filed under one.
The schema is Epic 47-01; nothing in this epic implements it.

**This epic's breakdown raised entry 5** — body-prose references to another artefact, which
FR8's merge tool claimed to rewrite and dpm had no way to hold. FR28 closes it by making such
a reference a `{{ref:<id>}}` marker resolved at render time, and FR8 now says plainly that
nothing is rewritten because no reference ever stored a number. **The resolution work is this
epic's**: Task 1.5, and the merge-side criterion on Story 4.

The entry was worth its place because AD9 §202 stated the rewrite as settled — *"That is a
tool in scope, not a convention to remember"* — and AD9 §195 already knew prose references
exist, having rejected render-time numbering on the grounds that *"every cross-reference in
the projection becomes a moving target"*. The two passages together assumed a reference model
the Data Model did not provide. FR28's answer is that render-time numbering is correct after
all, and §195's objection dissolves once the marker holds a ULID rather than a number: the
target moves, the marker does not.

### Requirements only partially covered by this epic

- **FR6** — fully covered here. This epic owns the projection.
- **FR7** — fully covered here.
- **FR8** — the merge half only. The dump half is Epic 47-02.
- **FR28** — fully covered here. Marker resolution is a renderer concern (Story 1) and its  
  merge-time consequence is Story 4; nothing outside the projection reads a marker.
- **FR10** — the projection-template criterion only. The create-tool criterion is split  
  across Epics 47-03 and 47-05, so FR10 reads as partially covered in three matrices. That  
  split is the shape register entry 1 described; FR26 now gives the schema a way to tell it  
  from full coverage, which these matrices, being markdown, still cannot.

### Derived criteria

Story 2's second and third criteria are not verbatim from the spec. The enumeration
criterion is inherited from FR10's *"the enumeration has no member without one"*. The
generic-renderer clause has no spec counterpart — it was proposed during breakdown and
accepted by Chris on 2026-08-08, because a template registry is where a convenience
fallback gets added, and FR10's coverage would then pass with twelve templates and a dump.
