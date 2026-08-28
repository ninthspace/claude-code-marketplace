# Migration 025, the rebuilt schema, and the writes that reach it

**Number**: 04-01  
**Source spec**: 04  
**Status**: complete — Everything in the spec waits on this. The rebuild of coverage is what forces the order.  

## Two things the breakdown recorded rather than resolved

**NFR4 and the supersession pair name different shapes, and the decision is the later of the two.** NFR4's text offers `retired_at`/`retired_reason` as on artifact and observation, and `status`/`status_note` as on story and task. ADR 04-04 chose `superseded_at`/`superseded_reason`, following what 018 chose for `document_section` — a third pair, which is exactly what NFR4's own must-NOT is about, unless the requirement is read as naming *the shapes this schema already carries* rather than an exhaustive list of two. The breakdown reads it that way and binds the supersession criterion to "New columns follow the shapes this schema already carries" rather than to the `status_note` clause. The spec is read and never written here, so the wording stands as it is; a reader who disagrees should pivot NFR4 rather than the criterion.

**One criterion is deliberately unbound.** "A migrated schema and a freshly created one must not differ, object for object" is warranted by the Integration boundaries section's sixth seam — one set of numbered files with two entry points — and by no requirement text. No verbatim fragment of NFR1 supports it, so binding it would be a guess the integrity register would report later. It is verified like any other criterion; it simply carries no coverage row, which is the shape FR7's warrant column exists to fix and which cannot be applied here because the column arrives in epic 3.

**No cross-story integration story.** The epic's three stories meet at exactly one place — a migrated database compared against a fresh one — and that meeting is already a criterion of story 2 rather than something spanning stories. A verification story here would restate it.

## Story 1 — Rebuild coverage and extend story_criterion

**Status**: complete  
**Blocked by**: Story 4, Story 5  

### Acceptance Criteria

- The retirement columns on coverage carry the same paired CHECK that artifact and observation carry, read from the live schema rather than transcribed into the test. `[integration]`
- The supersession column on story_criterion yields an include_superseded flag and the retirement column on coverage yields an include_retired flag, both derived from the column name rather than declared. `[unit]`
- must NOT — No column this change adds introduces a third spelling of retirement or of supersession. `[integration]`
- The migration file states what the claim hash now excludes, and states that no existing claim is invalidated by it because no row is retired at migration time. `[unit]`

### Task 1 — Check the planned DDL against schema.test.js's rules

**Status**: complete — Done during the story's plan. Four rules bear on the DDL: identity survives through coverage's id primary key, so the partial index needs no IS NOT NULL partner; every column the index names is NOT NULL, so the nullable-UNIQUE rule is not engaged; warrant_adr_id references adr(document_id) rather than document(id, kind), so kind-pinning does not apply; and five new columns need prose-columns classifications, of which coverage.retired_reason is the only one that holds prose.  

Reads the schema suite's rules and the prose-columns classification requirement against the DDL about to be written, before the migration file exists rather than after. Addresses the shape of the new columns, not their behaviour.

### Task 2 — Rebuild coverage in migration 025

**Status**: complete  

The retirement pair with its paired CHECK, the UNIQUE table constraint replaced by a partial unique index over live rows, coverage_story rescued and restored around the rebuild, and the three coverage_unverify_* and three requirement_unclaim_* triggers dropped and recreated. The file's note states what the claim hash now excludes and that no existing claim is invalidated, because no row is retired at migration time. Respects the boundary that no tool arm is written here.

### Task 3 — Add the supersession pair and warrant_adr_id to story_criterion

**Status**: complete  

Columns only, following document_section's superseded_at and superseded_reason. The update_story_criterion arms that write them belong to epic 3.

### Task 4 — Mirror the rebuild into the create path

**Status**: complete — No production code, and the reason rather than the fact: src/schema/index.js is a thin name over migrate(), and a fresh database is one at version 0, so the numbered files are already both paths. The work was the assertion — integration.test.js compares a migrated schema against a freshly created one object for object and passes across the rebuild, with its pinned target version moved from 24 to 25.  

One set of numbered files with two entry points. Addresses the migration-path and create-path boundary, which every earlier migration relied on and this one is the first to rebuild a table across.

### Task 5 — Declare coverage's liveness column and story_criterion's supersession in list.js

**Status**: complete  

The live entry for coverage, and what the derived include flags read on both tables. Addresses the column-name-and-derived-flag boundary: the declaration and the derivation read different things on purpose.

### Task 6 — Write tests for Rebuild coverage and extend story_criterion

**Status**: complete  

Covers the criteria tagged unit and integration, reading the paired CHECK from the live schema rather than transcribing it.

### Retro

- A column and the tool that writes it cannot land in different epics. Three derived sweeps — sparse.test.js's every-declared-state check, parity-integration.test.js's indexed-type round trip, and entry-index.test.js's scan — all require that every state the schema admits be reachable from the corpus, and the corpus is built by driving the registered tools. So a schema-only story leaves its own epic's suite red for a reason no amount of work inside the story can fix: coverage.retired_at and story_criterion.superseded_at were declared here and writable only from epic 04-02 and 04-03. The run pivoted rather than continued, and the two write-arm stories moved into this epic as stories 4 and 5. Worth generalising: a breakdown that splits schema from surface has to check the derived sweeps before it splits, because the sweeps are what make the split unbuildable rather than merely awkward.

## Story 2 — Migrate an existing database untouched

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- A database at the previous schema version, holding coverage rows and story criteria, migrates with every one of them live: retired_at and superseded_at are null throughout. `[integration]`
- The claim hash over a requirement with no retired bindings returns the same digest before and after the migration, so every standing claim survives it. `[integration]`
- must NOT — Migrating must not drop a coverage_story row, an index or a trigger. `[integration]`
- must NOT — A migrated schema and a freshly created one must not differ, object for object. `[integration]`
- control — A coverage_story row present before the rebuild is present after it, carrying the same pair, so the rescue put back what it took aside. `[integration]`

### Task 1 — Build a previous-version fixture with coverage rows, coverage_story rows and a standing claim

**Status**: complete  

This repository's own database is clean, so the state the migration has to preserve is constructed rather than found. Scoped to the fixture, not to the assertions over it.

### Task 2 — Write tests for Migrate an existing database untouched

**Status**: complete  

Covers all five criteria, including the object-for-object comparison of a migrated schema against a fresh one and the coverage_story rescue control.

### Retro

- The corpus fixture found a real defect in migration 025 that the schema assertions could not. `-- dpm:rebuild` turns foreign-key enforcement off for the duration of the migration, and a cascade IS enforcement — so `DROP TABLE coverage` left every `coverage_story` row exactly where it was, and the rescue's restore inserted a second copy of rows that never left. `UNIQUE (coverage_id, story_id)` refused it and rolled the whole migration back. Story 1's suite was green throughout, because a database built from DDL alone holds no rows and "nothing was lost" is satisfied by a migration that dropped everything. The fix is a `DELETE FROM coverage_story` between the copy-aside and the restore, which makes the outcome the rescue's contents whichever way enforcement behaved. Generalisable: the rescue-aside pattern in `017-observation-quick.sql` reads as insurance against the cascade, but under `dpm:rebuild` the cascade never fires, so the restore is always a duplicate insert and always needs clearing first. A second finding worth keeping: a row's verification and a requirement's completeness claim decay on different inputs — rewording a criterion clears the row's ✓ but leaves the claim current, because `claimHash` is over fragment and criterion id rather than criterion text. The intuitive reading is that both move together, and a later change making them do so would look like a fix.

## Story 3 — The environment the suite and the migration need

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- The suite runs to completion on Node 22.5.0 or later using node --test, with DatabaseSync imported from node:sqlite. `[integration]`
- A test creates a database at the previous schema version and migrates it in-process, without opening the project's own planning database. `[integration]`
- A project database at the previous schema version reaches the new one on first start, in a single transaction, with no SQLite beyond the one built into Node. `[target]`
- must NOT — The suite runs with no dependencies and no devDependencies installed, and the manifest declares none. `[integration]`
- must NOT — No test in the suite opens the project's own planning database for writing. `[integration]`
- must NOT — Migrating must not require a project to run a command, edit a file or repair a row by hand. `[target]`

### Task 1 — Write tests for The environment the suite and the migration need

**Status**: complete  

Covers ENV1, ENV2, ENVX1 and ENVX2. The two target criteria are out of its reach by construction and are not self-assessed here.

### Task 2 — Record ENV4 and ENVX3 as target-only

**Status**: complete — Both recorded as unverified in this environment, with their coverage rows left unmarked. ENV4 — a project database at the previous schema version reaching the new one on first start, in a single transaction — is closed by a real project host starting the installed plugin against its own .dpm/dpm.db; this repository's own database is one such host and reaching the new version costs the plugin reinstall CLAUDE.md describes, which is epic 04-06's business. ENVX3 — that migrating requires no command, no hand-edit and no repaired row — is closed by the same first start producing no prompt and no manual step. Neither is self-assessed here: both are mechanical checks whose whole content is about a host this run does not have, and a verdict from this machine would read afterwards as a deliberate verification while being the opposite of one.  

Names what would close each: a project host reaching the new version on first start. Neither is verified from this machine and neither blocks completion.

### Retro

- An environment story two specs apart from another one is mostly a duplicate, and the useful part is deciding which half not to write. Four of this story's six criteria are already held by `reference-environment.test.js` over the same sources — the Node floor, `node --test`, the empty manifest, and the `.dpm/` anchoring sweep with its planted control. Copying those assertions would have produced two places to edit and no second check. What earned a new file was the part spec 04 narrows: `node:sqlite` exercised rather than named, because the rebuild depends on three specific behaviours of it (multi-statement `exec`, `PRAGMA foreign_keys` as per-connection state, and `PRAGMA foreign_key_check` returning rows rather than throwing) and the second of those is exactly what the `coverage_story` defect in story 2 turned on; and an import sweep scoped to the files this epic added, because the whole-suite version of that claim belongs in one place while a new file importing something installable would slip past it. Two criteria are `target` and stayed unmarked: their content is about a project host on first start, and this machine has no verdict to give. Worth generalising: when a spec restates an environmental requirement another spec already carries, the reusable answer is to assert only the narrowing and cite the existing file for the rest — and to say in the new file which claims it is deliberately not restating, or the next reader adds them back.

## Story 4 — The retire_coverage tool

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- retire_coverage sets retired_at and retired_reason together on a live binding, and read_coverage on that id returns both. `[integration]`
- list_coverage omits a retired binding by default and returns it when include_retired is passed. `[integration]`
- must NOT — update_coverage does not set retired_at or retired_reason. Retirement is its own tool, as it is for every other retirable thing in the surface. `[unit]`
- must NOT — No tool in the registered surface deletes a coverage row. `[unit]`
- control — update_coverage still sets position and verified_at on the same row, so the refusal above is specific to the retirement columns rather than a tool that updates nothing. `[unit]`

### Task 1 — Register retire_coverage and write its handler

**Status**: complete  

Sets the retirement pair together on a live binding. Addresses the schema-and-tool boundary: the tool must not refuse what the schema permits, so a sound binding retires as readily as a broken one.

### Task 2 — Hold update_coverage to position and verified_at

**Status**: complete  

The refusal is the tool's declared arguments rather than a guard inside the handler. Addresses the rejected path, not the happy path.

### Task 3 — Write tests for The retire_coverage tool

**Status**: complete  

Covers the criteria tagged unit and integration, including the control that update_coverage still updates what it is meant to.

### Retro

- A column and the tool that writes it cannot land in separate epics, and the reason is a fixture rather than a feature. Three derived sweeps — sparse.test.js's declared-state walk, entry-index.test.js's scan, parity-integration.test.js's round trip over every indexed type — read a corpus built by driving the registered tools, and each asks whether every state the schema admits is reachable. Story 1 added coverage.retired_at and coverage.retired_reason with no verb to set them, so all three went red the moment the migration landed and stayed red for two stories. That is what the pivot into this epic corrected, and it generalises: any migration adding a state has to arrive with the write path that reaches it, or the suite reports a gap the schema opened and no story owns.

The corollary is that a shared corpus is version-agnostic and has to stay that way. fullCorpus is filled on a pre-025 database by plugin-stamp.test.js, so that "no other table's contents changed" compares rows rather than empty tables — and the new retire_coverage call broke it, reporting "already retired at undefined" because the row it read had no such column. The guard is columnNames(db, 'coverage'), the schema's own answer, rather than a version number written into the fixture.

Retiring a binding does not invalidate the requirement's completeness claim, and the two decay on genuinely different inputs: claimHash is over (spec_fragment, story_criterion_id) pairs, while bindingHash is over fragment ‖ criterion text. So editing a criterion's text clears that row's ✓ and leaves the claim standing, and the four requirement_unclaim_* triggers fire on coverage insert, coverage delete, fragment edit and requirement text edit — none on an update of retired_at. Migration 025's own prose asserted the opposite; the sentence was corrected in place, and the suite now asserts the distinction so a later change that conflates them reads as a regression rather than a tidy-up.

## Story 5 — Superseding a criterion

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- update_story_criterion sets superseded_at and superseded_reason together, and the criterion's own text is unchanged by that call. `[integration]`
- list_story_criterion omits a superseded criterion by default and returns it when include_superseded is passed. `[integration]`
- must NOT — A row must not exist with superseded_at set and superseded_reason null. `[integration]`
- must NOT — Superseding a criterion must not clear the verification of bindings on other criteria of the same story. `[integration]`
- control — The same call passing the criterion's text back byte-identical leaves its bindings' verification standing, so a cleared mark is the supersession rather than a trigger firing on any write. `[integration]`

### Task 1 — Add the supersession arm to update_story_criterion

**Status**: complete  

Sets the pair together and leaves the criterion's own text alone, which is the whole point of the requirement: the epic goes on recording what it delivered rather than being rewritten to match an amended requirement.

### Task 2 — Write tests for Superseding a criterion

**Status**: complete  

Covers all five criteria. The byte-identical control is the one the existing decay suite already uses, and it is what separates a trigger that fired from a trigger that fires on every write.

### Retro

- The create/update split for an ending column had no seam in criterionTools, and adding one made the asymmetry between the two criterion tables legible rather than incidental. `extra` fed both create and update, which is right for `warrant_adr_id` — a breakdown knows a criterion's warrant as it writes it — and wrong for supersession, because a criterion born superseded is not a state anybody decided. The new `endings` option reaches the update tool alone. `entityTools` already draws that line as `mutable`, and the sweep written for criterion 5 found the consequence of it not being drawn there: `create_document_section` offers `superseded_at`, not as a decision but because that factory offers every field at create. It is carried in the assertion as a named exception rather than excluded from it, since a sweep that quietly skipped it would read as "no factory anywhere does this".

Two of the five criteria are satisfied by triggers that must not fire, and neither is shown by nothing happening — a database where no write can ever clear a mark passes both. The control that makes them mean something is the trigger doing its job on the next line: supersede a criterion and both bindings keep their marks; then edit the same criterion's text, and its own mark clears while the other criterion's stands. `coverage_unverify_on_criterion_edit` is `AFTER UPDATE OF text ... WHEN OLD.text <> NEW.text`, so the supersession write names no watched column and the byte-identical write fails the `WHEN`.

Two mechanical facts about the surface that cost a red run each. `read_story_criterion` withholds `text` without `include_body` while `update_story_criterion` returns it, so comparing the two without asking compares a string against undefined — and that comparison passes on a call that blanked the column, which is the exact defect the assertion was written to catch. And the pairing guarantee is the column's `CHECK`, not the boundary's: asserting it through the tool alone would have been satisfied by a handler guard that every other writer routes around, so it is asserted twice, once through the tool and once by direct UPDATE.

## Dependencies

- blocks → 04-02
- blocks → 04-03

## Retro Applied

- 02 · Codebase Discoveries · applied — Story 2's migration criteria are judged against the dump and the schema objects, never the database file's bytes — the file is rewritten on every start and the byte claim was only ever true of the committed projection. Where the concern is that a write happens at all, the criterion names the write rather than its downstream trace.
- 05 · Complexity Underestimates · applied — Each derived sweep's own reading is checked before its cost is estimated. A rebuilt table, three new columns and two new tools are three differently-shaped changes, and the five-registration figure was measured on a table — carrying it over unread would be a precedent standing in for a reading.
- 02 · Complexity Underestimates · applied — The five-registration cost of a new table is budgeted into story 1: coverage is rebuilt and story_criterion gains three columns, so prose-columns classification and schema.test.js's rules are checked against the DDL before it is written rather than after the suite fails.
- 01 · Scope Surprises · applied — Step 1 reads the existing migration corpus, the schema modules and the test support before each task is planned, on the expectation that some of what the spec states is already true — and that the genuinely unmet criterion will be attached to whatever looks most finished.
- 05 · Testing Gaps · applied — Before a fixture is built for the partial unique index or the claim over a retired set, the schema is checked for whether it can hold the mixture the criterion is about — live and retired bindings carrying the same fragment on one requirement. A fixture that cannot hold the mixture satisfies the criterion's words and tests nothing.
- 02 · Testing Gaps · applied — Every must_not in this epic gets one control arm per place the rejected behaviour could live — the trigger, the partial index, the tool handler, the migration — listed before the control is run, and the red is read for the harm it names rather than for being red.
