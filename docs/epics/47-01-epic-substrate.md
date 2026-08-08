# Substrate

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Date**: 2026-08-08  
**Status**: Pending  
**Blocked by**: —

Milestone M1 (AD6). Nothing here is user-facing: the plugin skeleton and test harness, the
schema, its seeded vocabularies, number allocation, the edge table, migrations, and the
integrity check that reports the invariants SQLite cannot hold.

**Story 0 runs first, and its number is not its position in the build order.** Every other
story in this epic writes DDL or a test, and both need somewhere to live and something to run
them. Stories 1–9 keep the numbers Chris approved because renumbering them churns roughly 79
`Covered by` cells in the coverage matrix — the churn Task 9.4 decided against, and the cause
of three of review 05's findings. The `Blocked by` graph is what orders execution; the number
is identity only.

## Stand up the plugin skeleton and the test harness
**Story**: 0  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: NFR1, and the spec's **Test Infrastructure** section

**Acceptance Criteria**:

- A test creates its own database, exercises it, and leaves nothing behind; two tests running in one process do not share state [unit]
- The whole suite runs from one command that needs no install step and no compiled dependency [integration]
- must NOT — a fixture is a markdown file parsed at load, rather than built by calling create tools [integration]
- `dpm/` is installable from the marketplace manifest as a plugin alongside `cpm/`, with no build step [target]
- must NOT — a dependency is added whose install requires compilation [unit]

### Create the `dpm/` plugin directory, its manifest and its marketplace entry
**Task**: 0.1  
**Description**: `dpm/` sits beside `cpm/` in the same marketplace repository, which is not an incidental layout: the spec's **Testing Strategy** requires the suite to read CPM's `skills/` directory as a name oracle for FR25's twenty-two, and states that being a sibling in the same commit is what removes the version pin. Covers the marketplace-installability criterion, which is `[target]` for the same reason Epic 47-03's NFR1 criterion is — it needs a real install to assess.  
**Status**: Pending

### Stand up the test harness on `node --test` with a per-test database lifecycle
**Task**: 0.2  
**Description**: `node --test` is the runner, and the reason is AD5's reason one layer over: the spec asks for "a Node test setup", NFR1 bans any dependency requiring compilation at install, and every third-party runner is an `npm install` this plugin has no way to perform from a plugin cache directory. Node's built-in runner is already present wherever the Node floor is met, so the suite inherits the floor rather than adding a precondition. Covers the isolation and one-command criteria. Each test takes its own database — in-memory by default, temp-file where a test must reopen a connection, since `PRAGMA foreign_keys` is per-connection and Story 1's fresh-connection criterion cannot be asserted against a single shared handle.  
**Status**: Pending

### Build fixtures through the tool surface, not from markdown
**Task**: 0.3  
**Description**: Covers the must-NOT. AD8 means no import path exists to exercise, so a fixture parsed from a file would be testing a code path dpm does not have. Until Epic 47-03 ships the MCP tools, the builder calls the same statements those tools will wrap and exposes one seam — a single module the tools replace — so the substitution is one edit rather than a rewrite of every fixture. Name that seam explicitly; a fixture layer that reaches into the schema directly is the thing this task exists to prevent.  
**Status**: Pending

### Write tests for Stand up the plugin skeleton and the test harness
**Task**: 0.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`. The isolation criterion needs two tests observed in one process — a single test that cleans up after itself asserts nothing about leakage between them.  
**Status**: Pending

---

## Create the core schema with kind-pinned references [plan]
**Story**: 1  
**Status**: Pending  
**Blocked by**: Story 0  
**Satisfies**: FR1, FR2, FR27, AD7, AD9, NFR6

**Acceptance Criteria**:

- Every column named `*_id` on every table appears in that table's `PRAGMA foreign_key_list`, with no exceptions list (AD7) [unit]
- Every foreign key whose target is `document` names `(id, kind)`, except the three the Data Model names as legitimately kind-agnostic — and that exceptions list is the one in the Data Model, not one the test may extend [unit]
- must NOT — a `story` is accepted under a spec, a `requirement` under an epic, or a detail row on a document of another kind [unit]
- Creating an epic with a non-existent `spec_id` fails, and no row is written [integration]
- must NOT — a foreign-key violation is accepted because `foreign_keys` defaulted off on a fresh connection [integration]
- Every primary key in `sqlite_schema` is declared `TEXT`, excluding the FTS5 shadow tables, which SQLite creates with `INTEGER PRIMARY KEY` and dpm does not author [unit]
- Ten thousand ids generated in one process are unique and sort in generation order [unit]
- `document_kind.dir` is nullable, and a kind declaring `dir IS NULL` accepts documents that render inside a parent rather than into a file of their own [unit]
- Two specs may each hold a milestone labelled `M1`; one spec may not hold two, and positions are unique within a spec [unit]
- must NOT — an artefact's milestone is a column, so an epic spanning two must be filed under one [unit]
- An epic whose `parent_id` names a review is rejected, and one naming a spec is accepted [unit]
- A review parents onto either a spec or an epic, both being allow-listed, and onto a runbook not at all [unit]
- must NOT — `observation.library_doc_id` accepts a document that is not of kind `library` [unit]
- must NOT — a document's `parent_kind` can misdescribe the kind of the parent it points at [unit]
- Binding the same `(requirement_id, spec_fragment, story_criterion_id)` twice is rejected, and two different fragments against one criterion are both accepted [unit]
- must NOT — any `UNIQUE` constraint over a nullable column is relied on to reject duplicates, given SQLite's distinct-NULL semantics [unit]
- must NOT — `coverage` identity depends on `position`, so that display order can admit or reject a binding [unit]

### Write `document`, `document_kind` and `document_kind_parent`
**Task**: 1.1  
**Description**: Establishes the composite `(id, kind)` parent key that every other table joins to. Covers the parentage criteria; the allow-list table is what makes an illegal pairing unsatisfiable rather than merely unwritten.  
**Status**: Pending

### Write the nine per-kind detail tables and fourteen child tables with kind-pinned composite FKs
**Task**: 1.2  
**Description**: Covers the story-under-a-spec and requirement-under-an-epic rejections. Every reference whose target kind is fixed carries a `CHECK`-pinned kind column; the three deliberately unpinned ones are named in the Data Model and stay unpinned. The fourteenth child table is `milestone` (FR27), which brings `document_milestone` with it.  
**Status**: Pending

### Implement ULID generation and apply TEXT keys throughout
**Task**: 1.3  
**Description**: Covers both AD9 criteria. The generator is the only source of ids in the system — nothing else may mint one.  
**Status**: Pending

### Enforce `PRAGMA foreign_keys=ON` on every connection the server opens
**Task**: 1.4  
**Description**: Addresses the criterion that a fresh connection defaults it off. Scoped to connection setup, not to the tool layer.  
**Status**: Pending

### Write tests for Create the core schema with kind-pinned references
**Task**: 1.5  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Seed and constrain every vocabulary [plan]
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR4, FR10, FR24

**Acceptance Criteria**:

- A status value outside its enum is rejected by `CHECK`, not coerced [unit]
- must NOT — any category, severity, dimension or approach is stored as free text rather than a foreign key [integration]
- A severity row is rejected in a category slot, and an audit dimension in a severity slot, on `finding` and `audit_finding` alike [unit]
- Retiring a taxonomy row leaves rows referencing it intact and readable [unit]
- must NOT — a new row is accepted referencing a taxonomy row, test approach or dependency kind already retired, so that retirement stops rows arriving as well as preserving those that have [unit]
- `review_agent.agent` and `finding.agent` both reject a persona name no `agent` row carries, so the roster is a vocabulary rather than free text [unit]
- must NOT — a `document_kind` row exists that the parity enumeration does not name, or the reverse [unit]
- An `adr` parents onto a spec, a brief or a discussion, and onto an epic not at all [unit]
- A `retro` parents onto an epic, a spec or a quick record — the three sources `cpm:retro` actually accepts [unit]
- Loading a corpus whose labels are all replaced with opaque identifiers leaves every class, MoSCoW band and exclusion value unchanged [integration]

### Seed the thirteen `document_kind` rows and their `document_kind_parent` allow-list
**Task**: 2.1  
**Description**: Covers the parity-enumeration criterion in both directions, and the two parentage criteria. `adr` seeds with `dir IS NULL` and `numbering = 'child'`, so an AD written inside a spec keeps its `decision_status` and tradeoff axes instead of degrading to prose. The allow-list is what makes an unlisted pairing unwritable, so each criterion needs its accepted control as well as its refusal.  
**Status**: Pending

### Write the taxonomy tables with domain-scoped composite FKs
**Task**: 2.2  
**Description**: Covers the severity-in-a-category-slot rejections on `finding` and `audit_finding` alike. A plain `REFERENCES taxonomy(id)` would relocate the drift rather than remove it.  
**Status**: Pending

### Write and seed the `agent` table, and point `review_agent` and `finding` at it
**Task**: 2.3  
**Description**: The roster becomes a vocabulary under FR24 — its own table rather than a `taxonomy` domain, for the reason `test_approach` is one: it carries four columns no other vocabulary needs. Seed from CPM's `agents/roster.yaml`. Both referencing columns are declared several hundred lines before `agent` in the Data Model's DDL order; SQLite resolves a foreign key at write time rather than at `CREATE`, so the forward reference holds — asserted by the story's rejection criterion rather than assumed.  
**Status**: Pending

### Implement retirement so it stops new rows arriving as well as preserving those that have
**Task**: 2.4  
**Description**: Covers cross-row register #10 — the half of the retirement promise that was previously enforced by nothing.  
**Status**: Pending

### Write tests for Seed and constrain every vocabulary
**Task**: 2.5  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Allocate numbers two-level and never reuse them
**Story**: 3  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR5, FR23

**Acceptance Criteria**:

- Numbers allocated across create-archive-create never repeat, including past 99 [unit]
- The first allocation for a kind with no `number_sequence` row returns 1, and the first child allocation under a new parent does the same [unit]
- Two epics under different specs may both hold sequence 1; two under the same spec may not [unit]
- must NOT — a row carries both `number` and `sequence`, or neither, unless its kind is declared `numbering = 'none'` [unit]
- must NOT — an allocation returns no row, or returns success without a number [unit]
- Child sequences restart at 1 per parent and never reuse a value after deletion [unit]
- A kind declared `numbering = 'none'` accepts a document carrying neither `number` nor `sequence` [unit]
- must NOT — a kind declared `numbering = 'root'` accepts a row carrying `sequence`, or the reverse [unit]

### Write `number_sequence` with partial unique indexes for root and child allocation
**Task**: 3.1  
**Description**: The two schemes are exclusive alternatives, so they are two partial indexes rather than one nullable column.  
**Status**: Pending

### Implement the upsert allocation that holds register #5 by construction
**Task**: 3.2  
**Description**: Scoped to the allocation statement only — the MCP tool wrapping it belongs to Epic 47-03.  
**Status**: Pending

### Write tests for Allocate numbers two-level and never reuse them
**Task**: 3.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Model relationships as typed edges
**Story**: 4  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR22, FR27

**Acceptance Criteria**:

- A story-to-story `blocks` edge and a spec-to-spec `builds_on` edge both round-trip through one table [unit]
- A `builds_on` edge does not gate readiness; a `blocks` edge does [unit]
- must NOT — a document or story depends on itself [unit]
- must NOT — the same edge is storable twice, for any combination of NULL source/target columns [unit]
- An epic blocked by two epics yields two `dependency` rows, and completing both makes it selectable as ready [integration]
- A `builds_on` cycle is accepted, since no readiness query traverses it [unit]
- An epic joined to two milestones is returned by a readiness query for either, and reports both [integration]

### Write `dependency` and `dependency_kind` with the coalesce dedup index
**Task**: 4.1  
**Description**: Covers the duplicate-edge rejection across every NULL combination. One expression index rather than four partial ones.  
**Status**: Pending

### Implement readiness traversal so only `gates_work` kinds gate
**Task**: 4.2  
**Description**: Covers the `builds_on`-does-not-gate pair and the two-blockers case. A `builds_on` cycle is legal precisely because no readiness query traverses it.  
**Status**: Pending

### Project `document_milestone` into the readiness result
**Task**: 4.3  
**Description**: FR27's query half — "which epics are in M2" is answered here, and an epic joined to two milestones reports both rather than being filed under one. The join is many-to-many for exactly that case; a readiness result that returns a single milestone re-imposes the column FR27 removed.  
**Status**: Pending

### Write tests for Model relationships as typed edges
**Task**: 4.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Version the schema and migrate forward-only
**Story**: 5  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR12, FR24

**Acceptance Criteria**:

- A database at schema version *n* is migrated to *n+1* on server start with no user action [integration]
- A vocabulary default the plugin adds after a database was created appears in it on the next server start, and a term the project added under the same name is not overwritten [integration]
- A vocabulary default the plugin retires is retired in an existing database, and rows already referencing it stay readable [integration]
- must NOT — an upgrade resurrects a term the project retired, because the seed comparison was made against live terms rather than against every row present [integration]
- must NOT — a migration rewrites the `name` or `display_name` of a vocabulary row that existing rows reference, silently changing what those rows are recorded as meaning [unit]

### Write `schema_version` and the ordered migration runner applied on server start
**Task**: 5.1  
**Description**: Forward-only, no user intervention. The runner is a second path to the same schema as the DDL, which is what Story 8's first criterion exists to catch.  
**Status**: Pending

### Restrict vocabulary migrations to insert-if-absent and retire-if-live
**Task**: 5.2  
**Description**: FR24's evolution clause. A plugin-side vocabulary change is a migration, never a re-seed, and only two operations are legal: `INSERT` guarded on absence **by primary key**, and `UPDATE … SET retired_at WHERE retired_at IS NULL`. Guarding on the key rather than on live terms is what stops the resurrection case — retirement sets a column, so a retired row is still present. Rewriting a vocabulary row's text is not an operation, and that ban is what makes both permitted ones idempotent without the schema recording which rows a project has touched: no provenance column, no content hash, no reconcile.  
**Status**: Pending

### Write tests for Version the schema and migrate forward-only
**Task**: 5.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`. The four vocabulary-evolution criteria each need a database created *before* the change and migrated into it — a test that seeds the new state directly asserts nothing about the upgrade path.  
**Status**: Pending

---

## Check the invariants SQLite cannot hold
**Story**: 6  
**Status**: Pending  
**Blocked by**: Story 1, Story 2, Story 3, Story 4  
**Satisfies**: FR14, NFR6

**Acceptance Criteria**:

- Every numbered entry in the cross-row invariant register has a check in the integrity tool, and the tool has no *register-derived* check absent from the register [integration]
- Each of the thirteen register entries is reported in turn, naming the rows [unit]
- The integrity tool reports a deliberately orphaned row [integration]
- Every condition in the false-pass register has a test asserting it blocks rather than warns, and the register has no unregistered entries [integration]
- must NOT — the integrity tool reports a violation it cannot locate, or passes a database holding one [integration]

### Implement the thirteen cross-row register checks
**Task**: 6.1  
**Description**: One check per numbered entry, each naming the offending rows. Entry #3 matters most — it is the only one whose violation renders plausibly.  
**Status**: Pending

### Implement orphan and dangling-reference detection
**Task**: 6.2  
**Description**: Covers the deliberately-orphaned-row criterion, and the restore path's `PRAGMA foreign_key_check` consumes the same detection.  
**Status**: Pending

### Assert register-to-check parity in both directions
**Task**: 6.3  
**Description**: An entry with no check, and a register-derived check with no entry, both fail. Scoped to register-derived checks — the tool may hold others.  
**Status**: Pending

### Write tests for Check the invariants SQLite cannot hold
**Task**: 6.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Decay verification and completeness when the text they were bound to changes
**Story**: 7  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR21, FR26, NFR6

**Acceptance Criteria**:

- Editing a story criterion's text clears `verified_at` and `binding_hash` on every coverage row bound to it [unit]
- Editing a requirement's text clears verification on its coverage rows [unit]
- Editing `coverage.spec_fragment` clears `verified_at` and `binding_hash` on that row [unit]
- control — an edit that leaves the text byte-identical does not clear verification, on all three watched columns [unit]
- must NOT — a coverage row holds `verified_at` while `binding_hash` is NULL, or the reverse [unit]
- must NOT — any column the binding is computed from can be edited without clearing verification [unit]
- Claiming completeness on a requirement, then inserting a coverage row for it, leaves the claim cleared [unit]
- Deleting a coverage row, and editing a bound fragment, each clear the claim on that row's requirement [unit]
- Editing a requirement's text clears its own completeness claim, not only its coverage rows' verification [unit]
- control — an edit leaving the requirement's text byte-identical does not clear the claim, and neither does an update to an unrelated column [unit]
- A requirement with fragments bound and no claim is distinguishable by query from one with the same fragments and a current claim [integration]
- must NOT — `coverage_claimed_at` is set while `coverage_claim_hash` is NULL, or the reverse [unit]
- must NOT — completeness is derived from fragment offsets rather than claimed, so connective prose must be bound to satisfy it [unit]

### Write the three `AFTER UPDATE OF` triggers, one per column the binding is computed from
**Task**: 7.1  
**Description**: Three, not two. The binding is computed from two texts held in three places — `requirement.text`, `acceptance_criterion.text` and `coverage.spec_fragment` — and a draft carrying only the first two left the fragment editable with the ✓ intact, verified by execution.  
**Status**: Pending

### Constrain `verified_at` and `binding_hash` to be set and cleared together
**Task**: 7.2  
**Description**: A row holding one without the other is a verification state nothing can re-derive. The `CHECK` makes the pair atomic rather than leaving it to whichever trigger fired.  
**Status**: Pending

### Enumerate the watched columns and assert a trigger exists for each
**Task**: 7.3  
**Description**: Closes the final clause. The set of columns the binding hashes is declared and compared against `sqlite_schema`, so adding a fourth input to the hash fails until it has a trigger — the same shape as Story 6's register-to-check parity.  
**Status**: Pending

### Write the four unclaim triggers on `requirement.coverage_claimed_at`
**Task**: 7.4  
**Description**: FR26. Four events change the set a claim was made against — a coverage row arrives, one leaves, a fragment is rewritten, and the text being accounted for is edited — so four triggers. `requirement_unclaim_on_text_edit` updates the table it fires on; that was verified safe with `recursive_triggers` both off and on, because it watches `text` and writes only the two claim columns.  
**Status**: Pending

### Write the claim tool and the `CHECK` binding the claim pair together
**Task**: 7.5  
**Description**: Claiming is a deliberate act with no derived alternative — the Data Model records why a computed version was rejected. The `CHECK` keeps `coverage_claimed_at` and `coverage_claim_hash` set and cleared together, as `verified_at`/`binding_hash` are one level down.  
**Status**: Pending

### Write tests for Decay verification and completeness when the text they were bound to changes
**Task**: 7.6  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`. Both byte-identical controls matter as much as the decay cases — a trigger that clears on every write passes every decay criterion and makes the claim worthless. That is false-pass register entry #18.  
**Status**: Pending

---

## Verify cross-story integration for Substrate
**Story**: 8  
**Status**: Pending  
**Blocked by**: Story 1, Story 2, Story 3, Story 4, Story 5, Story 6, Story 7  
**Satisfies**: FR12, FR14

**Acceptance Criteria**:

- A database built by running the migration set from empty has a `sqlite_schema` identical to one built by executing the DDL directly — every table, index, trigger and constraint [integration]
- Seeding, retiring a vocabulary row, then applying a migration leaves the retirement in force and the rows referencing it readable [integration]
- The integrity tool passes on a freshly migrated and seeded database, and fails on each of the thirteen register violations injected into it in turn [integration]
- A number allocated before a migration is not reissued after it [integration]
- A coverage row verified before a migration is still verified after it, and a text edit made after the migration still clears it — a migration that recreates a table drops its triggers, and nothing in Story 5 or Story 7 alone observes that [integration]
- A completeness claim made before a migration survives it, and a coverage row inserted after the migration still clears the claim — the same trigger-loss failure one level up, on the four FR26 triggers rather than the three FR21 ones [integration]
- A document assigned to two milestones keeps both across a migration, and the spec-scoping pair check still refuses a cross-spec assignment afterwards [integration]
- must NOT — the migration runner and the DDL produce schemas differing in any constraint, index or trigger [integration]

### Write integration tests for Substrate
**Task**: 8.1  
**Description**: Covers the cross-story criteria above. The first criterion is the one that earns this story — Stories 1–5 produce two independent paths to the same schema and no per-story criterion compares them.  
**Status**: Pending

---

## Address review findings
**Story**: 9  
**Status**: Complete — applied by `/cpm:pivot` on 2026-08-08 from review 05  
**Blocked by**: —

**Acceptance Criteria**:

- Each critical and warning finding from review 05 scoped to this epic has been addressed
- Existing acceptance criteria on other stories continue to pass

### Fix: FR26's must-NOT criterion is carried by no story in any epic
**Task**: 9.1  
**Description**: [critical] Spec:1311 — *"must NOT — completeness is derived from fragment offsets rather than claimed, so connective prose must be bound to satisfy it"* — is carried by no story in any of the nine epics, and no matrix row cites it; `offset` and `connective` appear nowhere in `docs/epics/`. This epic's Story 7 owns FR26, and this matrix's note asserts "FR26 is complete here", so the gap and the false claim are both here. Add the criterion to Story 7 and a row to the coverage matrix, then correct the note. Without it an implementer can derive completeness from fragment offsets, pass the other six FR26 criteria and both controls, and reintroduce the alternative the Data Model rejects under **"Completeness is a claim and not a computation, and the alternative is worth stating because it looks better than it is"**.  
**Status**: Complete — criterion added to Story 7, matrix row 80 added, completeness note corrected

### Fix: Task 5.1 cites Story 7's first criterion, which is Story 8's
**Task**: 9.2  
**Description**: [warning] Task 5.1's description says the migration runner "is a second path to the same schema as the DDL, which is what Story 7's first criterion exists to catch". Story 7's first criterion is about a story criterion's text edit clearing verification; the DDL-versus-migration parity criterion is **Story 8's**. The note is right about the risk and wrong about where it closes.  
**Status**: Complete — Task 5.1 now cites Story 8

### Fix: `§1234` in the coverage matrix resolves to the wrong passage
**Task**: 9.3  
**Description**: [warning] The matrix's mapping notes cite `§1234` for the spec's record that the real corpus exposed eight schema defects. Spec line 1234 is `### Deferred`; the passage is at line 1440. One of five stale spec line-references across the breakdown — see Epic 47-04 and 47-05 for the others. Prefer a quoted phrase or a section heading over a line number, since a line number into an amendable document is the failure FR28 exists to prevent.  
**Status**: Complete — repointed to the spec's **Test Infrastructure** heading

### Decision: Story 1 stays whole, and the reason is recorded rather than the split deferred
**Task**: 9.4  
**Description**: [warning] Review 05 observed that Story 1 carries 17 acceptance criteria against FR1, FR2, FR27, AD7, AD9 and NFR6 — the whole 38-table schema — in four implementation tasks, blocks six of this epic's seven other stories, and gates four further epics transitively. Nothing partial can land. **Chris decided on 2026-08-08 to leave it whole**, and the trade is worth stating because the observation is correct and was not rejected. Splitting means either renumbering Stories 1–9, which churns roughly 79 `Covered by` cells in the coverage matrix, or appending new stories out of build order. Both are large edits to citation-bearing text, and three of the same review's findings — a row bound to a story that did not exist, five stale spec line-references, a task pointing at the wrong story — were caused by exactly that kind of churn. The sizing risk is a scheduling cost, paid once and visibly; the citation risk is a correctness cost that hides. Tasks 1.1–1.5 already decompose the work, so the story is large to *track* rather than large to *do*. Revisit if Story 1 stalls in execution: at that point the matrix is being edited anyway.  
**Status**: Complete — decision recorded; no split performed

---

## Notes

### Self-hosting register

Chris's standing check for this build: **dpm must be able to represent spec 47's own
planning corpus** — this spec, review 04, retro 33, these nine epics and their coverage
matrices. Each entry below is something that corpus requires and the schema as specified
could not do when the breakdown was written. All five needed a **spec** change, so none was
fixable during the breakdown; all five were carried to `/cpm:pivot` and closed there on
2026-08-08.

Later epics add to this register as they surface more. Epic 47-09's terminal story is where
it must be empty or every remaining entry explicitly waived.

| # | What the corpus requires | Status | Closed by |
|---|---|---|---|
| 1 | A requirement covered partially across several epics, distinguishable from one fully covered. Fragment rows are stored, but nothing tells "some fragments bound" from "accounted for", so a requirement with one of five obligations bound rolls up as covered | CLOSED | FR26 — `requirement.coverage_claimed_at`/`coverage_claim_hash`, a deliberate claim decayed by four triggers. Story 7 |
| 2 | AD6's four-milestone build order, and an epic spanning two of them — 47-04 spans M2 and M4. There is no `milestone` table and no build-order column on `document` or `story` | CLOSED | FR27 — `milestone` (spec-scoped, ordered by `position`) and the `document_milestone` join, which is many-to-many precisely so 47-04 can span two. Story 1 |
| 3 | Spec 47's ten inline ADs, carrying Decision / Rejected / Consequence and their rejected alternatives. `adr` is a *document kind*, so an AD inside a spec degrades to `document_section` prose and loses `decision_status`, `adr_option` and the tradeoff axes | CLOSED | `document_kind.dir` made nullable — NULL means the kind produces no file of its own and renders inside its parent, so `adr` stays a document kind with all its child tables while living inside a spec. Stories 1 and 2 |
| 4 | Retro 33, whose `**Source**` is a spec. `document_kind_parent` seeds `retro→epic`, not `retro→spec` — the retro written during this session is unstorable | CLOSED | Seeding widened to `retro→epic, spec or quick` and `adr→spec, brief or discussion`. Story 2 |
| 5 | A reference from one artefact to another written *in body prose* — this corpus has "The merge half is Epic 47-04" inside 47-02's Notes. FR8's merge tool "rewrites the references that named it", but every reference dpm models is a foreign key to a ULID and renumbering changes no ULID, so under FR2 there is nothing to rewrite. The references that do go stale are opaque text no tool can find. The clause is either vacuous or unimplementable, and the spec does not say which | CLOSED | FR28 — a prose reference is a `{{ref:<ULID>}}` marker the renderer resolves at projection time, so it never stored a number and nothing is rewritten. FR8 amended to say so. Renderer work is Epic 47-04 |

Entry 1 is the one that mattered most, on the spec's own terms: it was a false pass in the
subsystem built to remove false passes. The Problem Summary's "a coverage roll-up that
silently matches nothing reports full coverage" had a sibling the schema did not close —
a roll-up that matches *something* also reports full coverage. FR26's answer is that
completeness is asserted, not derived, and decays when the text it was asserted over moves.

Entry 5's mechanism changed during the pivot. A `document_reference` table was designed and
rejected on execution: the corpus's hardest case is retro 33's reference to spec 47, which
lives in `observation.text` — a child row, not a section — so a section-scoped reference
table cannot reach it. Markers can live in any text column.

**Two register entries in the Data Model were found by executing the amended schema, not by
reading it**: #12 (a document and its milestone must belong to the same spec) and #13 (every
`{{ref:}}` marker resolves to a live artefact). Both are cross-row invariants SQLite cannot
express, and both are now in Story 6's thirteen.

### Requirements only partially covered by this epic

FR10's seeding half is covered (Story 2's parity-enumeration criterion). Its other
obligation — every table having a create tool — belongs to Epics 47-03 and
47-05, so FR10 reads as fully covered only in the cross-epic union, not in this epic's
coverage matrix. This is register entry 1 in miniature, and is the reason it was noticed.
