# No bare ULID in stored prose

**Number**: 03-04  
**Source spec**: 03  
**Status**: complete  

## Story 1 — Refuse a bare ULID at the write

**Status**: complete  
**Blocked by**: Story 2  

### Acceptance Criteria

- `create_document_section` with a body containing a live document's bare ULID is refused, and the message names the column and shows the `{{ref:<id>}}` form. `[integration]`
- must NOT — The same ULID written correctly as `{{ref:<id>}}` in the same body must not be refused. A check that cannot tell the marker from the bare id refuses the only correct way to write the reference. `[integration]`
- Every prose-bearing write tool is covered, with the prose columns enumerated from the classification in `dpm/tests/support/prose-columns.js` rather than from a list of tool names — so a prose column added by a later migration is covered without an edit here. `[integration]`
- A foreign-key column accepts a live document's ULID: `create_dependency` with `source_document_id` set to one is not refused. `[integration]`
- `update_session` with a `state` blob containing a live document's ULID is not refused. The blob is skill-defined, dpm does not interpret it, and nothing renders it. `[integration]`
- A body containing a well-formed ULID that names no document — a session id quoted in an observation — is accepted. It has no marker form, so refusing it would reject prose with no correct alternative. `[integration]`
- control — A check without these exemptions refuses the foreign-key case — a sweep of every TEXT column against this project's own database flagged 390 of them. The three criteria above are what stop the refusal rejecting correct content, and without the control they read as defensive padding rather than as the finding they are. `[integration]`

### Task 1 — Write the bare-ULID predicate

**Status**: complete  

Distinguishes a bare ULID from one already inside a `{{ref:<id>}}` marker, and resolves the candidate against live `document` rows so a ULID naming something that is not a document is not a hit. Detection only; wiring is task 3.

### Task 2 — Derive the columns the check applies to

**Status**: complete  

Prose columns in; foreign-key columns and `session.state` out. Where the runtime column set is derived from — as against the test's enumeration, which the criterion pins to `dpm/tests/support/prose-columns.js` — is the open question this story's planning settles before the task starts.

### Task 3 — Wire the refusal into the write boundary

**Status**: complete  

The refusal names the column and shows the `{{ref:<id>}}` form, so the writer is told what to do rather than only what failed. The bad prose never enters the database, which is what makes a register entry unnecessary.

### Task 4 — Build the exemption control

**Status**: complete  

A variant of the check with the exemptions removed, so the foreign-key case is observed being refused without them. Addresses the control criterion, and is what makes the three exemptions read as a finding rather than as defensive padding.

### Task 5 — Write tests for Refuse a bare ULID at the write

**Status**: complete  

Covers the story's seven `integration` criteria: the refusal and its message, the marker that must not be refused, coverage across every prose-bearing write tool, the three exemptions, and the control.

### Retro

- The obvious seam for a write-boundary check — `defineTool` in `src/tools/convention.js` — cannot hold one, because only three of the ~40 tool definitions pass `db` and the check needs a connection to resolve a candidate id against. The usable seam was one level down: `INSERT INTO` and `UPDATE … SET` appear in `src/tools/crud.js` and nowhere else under `src/tools/`, so `insert` and `updateByKey` are two call sites that already hold `db`, the table, the values and the tool name, and cover every write tool by construction rather than by a list. The suite now asserts that structurally, and finding it needed one grep over the tool tree rather than a design decision.

Two smaller things the run turned up. First, that structural assertion failed on its first run against `session.js`, which *describes* its adoption statement as `UPDATE session SET superseded_by = ?` in a doc comment — this repository explains its SQL in prose everywhere, so any scan for write sites has to strip comments or it will find one wherever somebody was being helpful. Second, the exemptions are derived from `PRAGMA foreign_key_list` and `PRAGMA table_info` rather than from column names, and the control for that plants the two columns the wrong way round in a scratch table — a foreign key named `owner`, a plain TEXT column named `body_id` — which is the only arrangement that can tell a role-keyed exemption from a name-keyed one.

## Story 2 — Nothing published carries a bare ULID

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- Publishing a fixture corpus produces no file under `docs/` containing a ULID that names a live document. `[integration]`

### Task 1 — Write tests for Nothing published carries a bare ULID

**Status**: complete  

Publishes a fixture corpus into a writable scratch tree per ENVR5 and scans every rendered file, rather than inspecting the renderer's return value. The outcome a reader observes, which is why it is stated separately from the refusal that produces it.

### Retro

- The fixture this story needed already existed and had been written for it by name: `publishedTree` in `tests/support/published.js` says in its own note that it exists so a check over what the renderer wrote is not put behind a git repository and a database on disk, and gives FR17's claim — "that no rendered file carries a bare ULID" — as its example. The first draft hand-rolled the same seven steps from `publish-tool.test.js`'s `repository()`; the refactoring pass replaced it, along with the tree walk, which `filesUnder` in `tests/support/sources.js` already does with dot-directories skipped. Two helpers, both found by reading `tests/support/` rather than by the failure that would eventually have made someone look. Worth doing before writing a fixture, not after.

The substantive finding is where the corpus names other documents. The vacuity guard — that the scan ran over prose that *could* have failed — was first written against `document_section.body` and found nothing, because `fullCorpus` puts its three `{{ref:}}` markers on a criterion, a coverage-matrix note and an ADR consequence instead. Sweeping every column in `proseColumns()` fixed it and made the guard agree with Story 1's coverage check by construction. A vacuity guard aimed at one column is a guard that reports on that column's emptiness rather than on the corpus's.

## Retro Applied

- 05 · codebase-discoveries · applied — Read what each sweep reads before budgeting. A refusal at the write seam touches prose-columns.js, conformance.js and the tool-surface fixtures, and epic 03-03 found the budget has to include the sweeps over the test tree — fixtures.test.js refused a markdown capture that no reading of src/ would have predicted.
- 02 · complexity-underestimates · applied — A cost carried from a differently-shaped change is a guess. This one is a refusal at the write seam rather than a field on a read, so the registrations are counted by reading each sweep against this change before the plan is presented, not by carrying 03-01's one or retro 02's five forward.
- 04 · criteria-gaps · applied — A criterion can read as the natural test of a rule and have no purchase on it. Story 2's "nothing published carries a bare ULID" follows from Story 1 rather than being enforced again at render, so its test has to publish a real tree from a corpus that would leak — a check over the renderer's return value would assert nothing.
- 05 · patterns-worth-reusing · applied — A first run reporting offenders is usually the reading, not the corpus — and this epic's own control criterion says so in advance: a check without the exemptions flagged 390 TEXT columns in this project's database. The refusal is narrowed by what a column is for rather than by an allow-list of columns.
- 05 · patterns-worth-reusing · applied — Assemble the forbidden string rather than writing it. This suite's ULIDs come off fixture rows rather than being typed, and where a literal is genuinely needed for a control it is built from parts so no sweep over the test tree reports its own control as a finding.
- 02 · testing-gaps · applied — One control arm per path the rejected behaviour could reach. A marker wrongly refused could come from the ULID pattern matching inside the braces, from the exemption keying off the column name rather than its role, or from the marker being stripped before the scan; each is planted and removed in turn.
- 04 · testing-gaps · applied — Read the criterion for the failure it protects against. The must-NOT here is that the marker form is not refused; the failure is a check that cannot tell `{{ref:<id>}}` from a bare id, which would reject the only correct way to write the reference and be silenced by exempting the column.
