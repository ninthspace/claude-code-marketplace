# Spec: dpm — SQLite-Backed Artefact Persistence

**Date**: 2026-08-08  
**Brief**: none — authored from a facilitated design conversation, taking CPM as the reference implementation

## Problem Summary

CPM's entity model is real but implicit. A spec has requirements; an epic belongs to a spec; a coverage row joins a requirement to a story; an artifact points at the documents that produced it. None of those relationships is stored — each is spelled into markdown prose and reconstructed, on demand, by a parser.

The cost is measurable. `cpm/hooks/lib/coverage-parse.sh` (677 lines) and `coverage-rollup.sh` (802 lines) exist entirely to recover entities that were never persisted as entities: `FRn` labels lifted from prose bullets, matrix rows lifted from markdown tables, a parent spec lifted from a `**Source spec**` line. Two of those functions — `coverage_base_label()` (`coverage-parse.sh:239`) and `coverage_environmental_class()` (`:248`) — derive an entity's *type* from the spelling of its label, because there is nowhere else for a type to live.

Reconstruction fails in ways that are invisible. The parser's own header records one:

> `awk -v` applies escape processing to its value, so `\*\*` arrives collapsed to `**` and a pattern built that way silently matches nothing — a failure invisible in the pattern itself (retro 21). (`coverage-parse.sh:41–45`)

A coverage roll-up that silently matches nothing reports full coverage. The failure mode of a prose-derived entity model is not an error; it is a false pass.

The same shape recurs wherever a relationship has two ends. `cpm:artifact` maintains an index file *and* backlinks inside each source document — a bidirectional link kept honest by hand, where updating one side and forgetting the other produces no diagnostic. `cpm:archive` must preserve `docs/archive/{type}/` as a mirrored tree solely so the **Numbering** procedure's glob can still find retired numbers, making a directory layout into a load-bearing contract.

Three sections of `cpm/shared/skill-conventions.md` — **Progress File Management** (`:136`), **Stale-Progress Check** (`:167`), and **Numbering** (`:195`), 92 lines between them — specify in English what a database provides as primitives: session-scoped state with adoption on resume, staleness by age, and a monotonic sequence with retirement. `progress-classify.sh` and `cleancheck-guard.sh` (207 lines) implement the first two against the filesystem.

None of this is bad engineering. It is the necessary consequence of choosing a storage format that cannot express a foreign key. **dpm keeps CPM's pipeline and replaces its substrate.**

## Functional Requirements

### Must Have

- **FR1 — Artefacts persist as rows in SQLite.** Every CPM artefact type is a table with typed columns, not a markdown file parsed at read time. The database is the sole source of truth for artefact content and relationships.
- **FR2 — Cross-entity references are foreign keys.** An epic cannot name a spec that does not exist; a coverage row cannot cite an absent requirement; an artifact link cannot point at a missing document. `PRAGMA foreign_keys=ON` is enforced on every connection, and a violation is an error at write time rather than a discrepancy discovered later.
- **FR3 — Skills write exclusively through typed MCP tools.** dpm ships an MCP server whose tool schemas are the write contract. No skill contains SQL, and no skill constructs a query. A malformed call is rejected at the tool boundary before it reaches the database.
- **FR4 — Entity type is a column, never a spelling.** Requirement class, MoSCoW band, status, test-approach tag, and coverage verification state are typed columns constrained by `CHECK`. Nothing infers a type by parsing an identifier.
- **FR5 — Numbering is a database concern.** Human-facing artefact numbers are allocated monotonically and are never reused, including after archival. No glob, no filename parse, no archive-mirror contract.
- **FR6 — A markdown projection is generated and committed.** Every artefact renders to markdown under `docs/`, regenerated from the database and committed, so that pull requests show a readable prose diff of what changed. The projection is a render, not a store (AD3).
- **FR7 — Hand-edits to the projection are detected and refused.** Because the projection is one-way, an edit made to a generated file is lost at the next regeneration. A pre-commit guard regenerates and fails on divergence, naming the diverged file. Silent loss of a user's edit is the failure this requirement exists to prevent.
- **FR8 — The committed database representation is text.** A deterministic, sorted `.sql` dump is committed; the binary `.db` is generated and ignored. Two branches that both add artefacts produce an ordinary text conflict (AD4).
- **FR9 — Search is a query, not a grep.** Artefact bodies are indexed with FTS5 and exposed as a typed search tool returning ranked, bounded results.
- **FR10 — Full CPM artefact parity.** Every artefact type CPM produces is modelled from the outset: brief (problem and product), ADR, spec, requirement, epic, story, task, coverage, review, finding, retro, lesson, quick record, discussion, artifact, library document, audit, and session state.
- **FR11 — Session state is a row.** The progress-file subsystem — session-suffixed filenames, hook injection, adoption on `--resume`, compact-summary companions — is replaced by a session table. Adoption is an `UPDATE`; staleness is a `WHERE` clause.

### Should Have

- **FR12 — Schema migrations are versioned and forward-only.** A `schema_version` row and an ordered migration set, applied automatically on server start, so a plugin update never requires the user to intervene.
- **FR13 — Reads are bounded by default.** Query tools accept limits and return summaries rather than whole bodies unless a body is explicitly requested, so a skill reading an epic no longer pulls 20 KB into context to answer a question about its status.
- **FR14 — Referential integrity is checkable on demand.** A verification tool reports orphans, dangling links, and constraint drift across the whole database, so a corrupted state is diagnosable without SQL.
- **FR15 — Import from existing CPM artefacts.** A one-time importer reads a project's `docs/` tree and populates the database, so an existing CPM project can adopt dpm without re-authoring its history.

### Could Have

- **FR16 — Semantic diff.** A tool rendering the difference between two database states as entity-level changes rather than text.
- **FR17 — Cross-project queries.** A read path spanning several project databases, for portfolio-level status.

### Won't Have (this iteration)

- **FR18 — Round-trip import of the markdown projection.** The projection is explicitly one-way (AD3). Markdown is never a write path.
- **FR19 — Concurrent multi-writer coordination beyond SQLite's own.** WAL mode and SQLite's locking are the whole concurrency story; no external lock manager.
- **FR20 — A migration path *back* to CPM's file format.** Adoption is one-directional; dpm does not maintain an exit.

## Non-Functional Requirements

- **NFR1 — No native compilation at install time.** The plugin installs by clone or marketplace fetch with no build step, no `node-gyp`, and no per-platform binary. Satisfied by AD5's choice of `node:sqlite`.
- **NFR2 — Node floor stated and enforced.** The server refuses to start with a clear message below its minimum Node version rather than failing on a missing module. `node:sqlite` is experimental and its API may change between minors; the floor is `>=22.5.0` and CI tests against 22 and 24.
- **NFR3 — Standard output is reserved for JSON-RPC.** The MCP stdio transport owns stdout. All logging, including Node's `ExperimentalWarning` for `node:sqlite`, goes to stderr or is suppressed (`NODE_NO_WARNINGS=1`). Verified on Node v22.18.0, where `node:sqlite` loads with no flag and emits the warning on stderr only.
- **NFR4 — The dump is byte-stable.** The same database state produces the same `.sql` bytes on any machine, on any run — ordered rows, no timestamps, no locale dependence. Without this, FR8 delivers a text file that conflicts on every commit.
- **NFR5 — Tool names are discoverable.** This harness defers MCP tool schemas, listing tools by name and loading schemas on demand, so a large tool surface costs a name list rather than a wall of JSON Schema. Names must therefore be searchable words (`dpm_create_epic`, not `dpm_ce`); brevity is not a virtue here.
- **NFR6 — Failure is loud.** Any condition that could produce a false pass — a constraint violation swallowed, a projection silently stale, a search index behind the data — reports and blocks. This spec's subject applied to itself: the failure being designed against is one that looks like success.
- **NFR7 — The database is never a black box to its owner.** Every piece of state is reachable through a read tool without SQL, so a user whose server will not start is not locked out of their own planning history.

## Architecture Decisions

No ADRs exist for this project; these were facilitated from scratch during the design conversation of 2026-08-08.

### AD1 — SQLite is the source of truth, not an index over files

**Decision**: Artefact content and relationships live in SQLite. Markdown is derived.

**Rejected**: markdown as truth with SQLite as a derived cache. It preserves git behaviour perfectly and changes nothing about drift, because it keeps the parser — entities are still reconstructed from prose a model wrote, which is the defect. A derived index that disagrees with its source is an additional failure mode, not a fix.

**Consequence**: `docs/` becomes generated output. The directory tree stops being structure and becomes presentation.

### AD2 — Skills write through typed MCP tools

**Decision**: An MCP server exposes typed tools; validation happens at the tool boundary.

**Rejected**: raw `sqlite3` from Bash, which hands schema knowledge to the model in every SKILL.md and trades a prose-parsing drift problem for a SQL-generation drift problem. Also rejected as the primary surface: a CLI shelled out to from Bash — cheaper to build and genuinely adequate, but argument construction stays free-text, so violations surface at runtime rather than in a schema the model cannot malform.

**Consequence**: the tool schema *is* the contract. A model cannot create an epic without a valid `spec_id`, because the call will not typecheck.

### AD3 — The markdown projection is one-way

**Decision**: Generated markdown is committed for review, and is never an input.

**Rejected**: a lossless, reimportable projection. It is genuinely attractive — merge conflicts would resolve in readable markdown, hand-edits would become legal, and the binary database need never be committed at all. It was rejected because it constrains every column to have a stable textual form that survives `db → md → db` identity, and that constraint is paid on every schema decision forever. FR10's parity scope makes that price too high: thirteen-plus entity types is tractable precisely because they do not each need to round-trip.

**Consequence**: two obligations follow directly. The database must itself be committed (AD4), and hand-edits to generated files must be actively refused (FR7) rather than merely discouraged.

### AD4 — The committed database form is a deterministic `.sql` dump

**Decision**: Commit `.dpm/dpm.sql` — sorted, stable, text. Generate and gitignore `.dpm/dpm.db`.

**Rejected**: committing the binary. Simpler, with no sync surface and no rebuild step, but git sees `Binary files differ` — no diff, and two branches that both add an artefact produce a conflict no tool can merge, meaning one side redoes its work by hand. Since AD3 removed markdown as a merge surface, the dump is the only remaining place where branching can work.

**Consequence**: NFR4 becomes load-bearing. A dump that is not byte-stable produces a conflict on every commit and is worse than the binary it replaced.

### AD5 — Node 22+ with `node:sqlite`

**Decision**: The server is Node, using SQLite from the standard library.

**Verified rather than assumed**, on Node v22.18.0:

```
node:sqlite → OK  DatabaseSync, StatementSync, constants, backup
```

It loads with no flag and needs no native module. `better-sqlite3` was rejected for requiring compilation at install; Python was a close second — `sqlite3` and FTS5 are stdlib there too — but has no clean dependency story for the `mcp` package inside a plugin cache directory. Go and Rust were rejected for requiring a per-platform release pipeline and committed binaries.

**Consequence**: NFR2's floor and NFR3's stderr discipline both exist to contain the two known costs of this choice — API instability and the experimental warning.

### AD6 — Full parity from the outset

**Decision**: Model every CPM artefact type in the first version rather than proving the architecture on a spine first.

**Rejected**: a core-spine-only first cut (spec → requirement → epic → story → task → coverage), which would be usable sooner and would retire the coverage helpers immediately.

**Consequence**: the schema is large before anything ships. AD3 is what makes this affordable — one-way projection is the decision that removes the per-entity round-trip burden that would otherwise make parity the expensive path.

### AD7 — A `document` supertype, with per-kind detail tables

**Decision**: All numbered, file-producing artefacts share one `document` table carrying identity, numbering, status, and lineage. Kind-specific columns live in detail tables keyed to it. Sub-entities that never produce a file of their own — requirements, stories, tasks, coverage rows, findings, lessons — are ordinary child tables.

**Rejected**: one independent table per artefact type, with polymorphic joins carrying a `(kind, id)` pair. It is the obvious shape and it defeats FR2: SQLite cannot enforce a foreign key whose target table varies by row. Every polymorphic link would be an unchecked integer — which is the `**Source spec**` string again, in a column instead of a line of prose.

**Consequence**: cross-kind relationships that CPM maintains by hand become real constraints. `artifact → document`, `retro → epic`, `review → epic`, `present → sources`, and `lesson → library doc` all reference one enforceable primary key.

## Data Model

Abridged to the load-bearing definitions. Full DDL is an implementation artefact; what belongs here is the shape and the constraint behind each drift class named in the Problem Summary.

### Identity, numbering and lineage

```sql
CREATE TABLE document_kind (
  kind        TEXT PRIMARY KEY,          -- 'spec','epic','retro','review','brief_problem',…
  dir         TEXT NOT NULL,             -- projection directory under docs/
  numbered    INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE document (
  id          INTEGER PRIMARY KEY,
  kind        TEXT    NOT NULL REFERENCES document_kind(kind),
  number      INTEGER NOT NULL,
  slug        TEXT    NOT NULL,
  title       TEXT    NOT NULL,
  status      TEXT    NOT NULL DEFAULT 'draft'
                CHECK (status IN ('draft','active','delivered','archived')),
  parent_id   INTEGER REFERENCES document(id),   -- epic→spec, retro→epic, review→epic
  commit_sha  TEXT,                              -- audit and inspect pin to a commit
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL,
  UNIQUE (kind, number)
);

CREATE TABLE number_sequence (
  kind         TEXT PRIMARY KEY REFERENCES document_kind(kind),
  next_number  INTEGER NOT NULL DEFAULT 1
);
```

`number_sequence` satisfies FR5 outright. Allocation is `UPDATE number_sequence SET next_number = next_number + 1 WHERE kind = ? RETURNING next_number - 1`, which is monotonic irrespective of deletion, archival, or how many rows currently exist. The **Numbering** procedure's glob-the-active-directory, glob-the-archive-mirror, union, parse-as-integer-not-string, and its standing `99 → 100` warning all reduce to that statement — and `cpm:archive`'s obligation to preserve `docs/archive/{type}/` as a mirrored tree stops being a contract at all, because retirement is `status='archived'` on a row that never moves.

Undecomposed prose keeps a home rather than being over-modelled:

```sql
CREATE TABLE document_section (
  id           INTEGER PRIMARY KEY,
  document_id  INTEGER NOT NULL REFERENCES document(id) ON DELETE CASCADE,
  heading      TEXT    NOT NULL,
  body         TEXT    NOT NULL,
  position     INTEGER NOT NULL,
  UNIQUE (document_id, position)
);
```

### Requirements — where type stops being a spelling

```sql
CREATE TABLE requirement (
  id            INTEGER PRIMARY KEY,
  spec_id       INTEGER NOT NULL REFERENCES document(id) ON DELETE CASCADE,
  label         TEXT    NOT NULL,                  -- display only: 'FR1','NFR3','ENVX2'
  class         TEXT    NOT NULL CHECK (class IN (
                  'functional','non_functional',
                  'environmental_requirement','environmental_restriction')),
  moscow        TEXT    CHECK (moscow IN ('must','should','could','wont')),
  exclusion     TEXT    CHECK (exclusion IN ('deferred','out_of_scope')),
  parent_id     INTEGER REFERENCES requirement(id),  -- FR1a's parent is FR1
  text          TEXT    NOT NULL,
  position      INTEGER NOT NULL,
  UNIQUE (spec_id, label)
);
```

Four parsers die here, and it is worth being explicit about which:

- `coverage_environmental_class()` (`coverage-parse.sh:248`) derives requirement class from whether a label reads `ENVn` or `ENVXn`. `class` is that value, stored.
- `coverage_base_label()` (`:239`) reduces `FR1a` to `FR1` by string surgery. `parent_id` is that relationship, enforced.
- `coverage_spec_requirements()` (`:262`) reads MoSCoW from the markdown heading a bullet sits under, and carries the heading along so a Won't Have can be told from an uncovered requirement. `moscow` is a column; `wont` is a value in it.
- `coverage_spec_scope_deferrals()` (`:382`) scans `### Deferred` and `### Out of Scope` bullets for labels to exclude. `exclusion` is that fact, attached to the requirement rather than inferred from where its name was mentioned.

`label` survives as a display string only. Nothing reads it to determine meaning — which is FR4 stated as a schema property rather than a rule to remember.

### Delivery and coverage

```sql
CREATE TABLE story (
  id          INTEGER PRIMARY KEY,
  epic_id     INTEGER NOT NULL REFERENCES document(id) ON DELETE CASCADE,
  number      INTEGER NOT NULL,
  title       TEXT    NOT NULL,
  status      TEXT    NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','in_progress','done','blocked')),
  position    INTEGER NOT NULL,
  UNIQUE (epic_id, number)
);

CREATE TABLE task (
  id          INTEGER PRIMARY KEY,
  story_id    INTEGER NOT NULL REFERENCES story(id) ON DELETE CASCADE,
  number      INTEGER NOT NULL,
  title       TEXT    NOT NULL,
  status      TEXT    NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','in_progress','done','blocked')),
  position    INTEGER NOT NULL,
  UNIQUE (story_id, number)
);

CREATE TABLE acceptance_criterion (
  id              INTEGER PRIMARY KEY,
  requirement_id  INTEGER NOT NULL REFERENCES requirement(id) ON DELETE CASCADE,
  text            TEXT    NOT NULL,
  polarity        TEXT    NOT NULL DEFAULT 'must'
                    CHECK (polarity IN ('must','must_not','control')),
  position        INTEGER NOT NULL
);

CREATE TABLE test_approach (
  tag   TEXT PRIMARY KEY,                            -- unit, integration, feature, manual, target, tdd
  kind  TEXT NOT NULL CHECK (kind IN ('level','mode'))
);

CREATE TABLE criterion_approach (
  criterion_id  INTEGER NOT NULL REFERENCES acceptance_criterion(id) ON DELETE CASCADE,
  tag           TEXT    NOT NULL REFERENCES test_approach(tag),
  PRIMARY KEY (criterion_id, tag)
);

CREATE TABLE coverage (
  id              INTEGER PRIMARY KEY,
  requirement_id  INTEGER NOT NULL REFERENCES requirement(id) ON DELETE CASCADE,
  story_id        INTEGER REFERENCES story(id) ON DELETE CASCADE,
  task_id         INTEGER REFERENCES task(id)  ON DELETE CASCADE,
  state           TEXT NOT NULL DEFAULT 'planned'
                    CHECK (state IN ('planned','implemented','verified','blocked')),
  CHECK (story_id IS NOT NULL OR task_id IS NOT NULL)
);

-- NOT a composite UNIQUE: SQLite treats NULLs as distinct, so
-- UNIQUE(requirement_id, story_id, task_id) admits unlimited duplicates
-- whenever either column is NULL — which is the ordinary case. Verified
-- empirically; two identical (requirement_id, story_id) rows were accepted.
-- Duplicate coverage rows inflate the covered count, so this is an NFR6
-- false pass and must be closed at the schema.
CREATE UNIQUE INDEX coverage_req_story
  ON coverage (requirement_id, story_id) WHERE task_id IS NULL;
CREATE UNIQUE INDEX coverage_req_task
  ON coverage (requirement_id, task_id)  WHERE task_id IS NOT NULL;
```

`polarity` is the sleeper. A negative criterion is currently written `must NOT — …` and recognised by that prefix; a control case by the word `control`. Both are types carried in prose, in the one artefact whose whole purpose is deciding whether the work is done.

The coverage matrix — a markdown table, parsed row by row by `coverage_matrix_rows()` (`:585`) — becomes rows. The roll-up that `coverage-rollup.sh` performs in 802 lines becomes a join, and its `REQ = STATE ∪ EXCLUDED` partition property (spec 44 NFR4, restated as spec 46 NFR4) stops being a property to assert and becomes one that cannot fail: `exclusion IS NOT NULL` and `exclusion IS NULL` partition the table by construction.

### Review, retro, and the library

```sql
CREATE TABLE finding (
  id              INTEGER PRIMARY KEY,
  review_id       INTEGER NOT NULL REFERENCES document(id) ON DELETE CASCADE,
  agent           TEXT,
  severity        TEXT NOT NULL CHECK (severity IN ('critical','major','minor','note')),
  summary         TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'open'
                    CHECK (status IN ('open','accepted','rejected','remediated')),
  remediation_task_id INTEGER REFERENCES task(id)
);

CREATE TABLE lesson (
  id              INTEGER PRIMARY KEY,
  retro_id        INTEGER NOT NULL REFERENCES document(id) ON DELETE CASCADE,
  text            TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active','promoted','retired')),
  library_doc_id  INTEGER REFERENCES document(id)
);

CREATE TABLE audit_finding (
  id          INTEGER PRIMARY KEY,
  audit_id    INTEGER NOT NULL REFERENCES document(id) ON DELETE CASCADE,
  dimension   TEXT NOT NULL,          -- the nine dimensions of code health
  file        TEXT NOT NULL,
  line        INTEGER,
  symbol      TEXT,
  severity    TEXT NOT NULL CHECK (severity IN ('critical','major','minor','note'))
);
```

`finding.remediation_task_id` closes a loop CPM leaves open: a review finding that generated a remediation task is joined to it, so "which findings were actually acted on" is a query rather than a reading exercise. `lesson.status` makes **Retro Retirement** a transition rather than a procedure, and `library_doc_id` records where a promoted lesson landed.

### Artifacts — the bidirectional link, made unable to disagree

```sql
CREATE TABLE artifact (
  id            INTEGER PRIMARY KEY,
  url           TEXT NOT NULL UNIQUE,
  title         TEXT NOT NULL,
  description   TEXT,
  published_at  TEXT NOT NULL
);

CREATE TABLE artifact_document (
  artifact_id   INTEGER NOT NULL REFERENCES artifact(id)  ON DELETE CASCADE,
  document_id   INTEGER NOT NULL REFERENCES document(id) ON DELETE CASCADE,
  PRIMARY KEY (artifact_id, document_id)
);
```

`cpm:artifact` today maintains `docs/artifacts/index.md` **and** backlinks written into each source document — the same relationship recorded twice, in two files, by hand, with no diagnostic when one side is updated and the other is not. One join table cannot hold a disagreement, because there is only one place for the fact to live. Both the index and the in-document backlinks become projections of the same rows.

### Session state

```sql
CREATE TABLE session (
  id             TEXT PRIMARY KEY,       -- CPM_SESSION_ID
  skill          TEXT,
  phase          TEXT,
  state          TEXT,                   -- JSON blob, skill-defined
  superseded_by  TEXT REFERENCES session(id),
  created_at     TEXT NOT NULL,
  updated_at     TEXT NOT NULL
);
```

Adoption on `--resume` is `UPDATE session SET superseded_by = ?`. Classification is `updated_at < datetime('now','-3 days')`, replacing `progress-classify.sh`'s tab-delimited record emission and `cleancheck-guard.sh`'s once-per-session sentinel (207 lines together). The `.gitignore` leak — `/docs/plans/.cpm-*` swept into commits by `git add -A`, untrackable after the fact — ceases to be a category of problem, since session state is not a file.

### Search and schema management

```sql
CREATE VIRTUAL TABLE document_fts USING fts5(
  title, body, content='document_section', content_rowid='id'
);

CREATE TABLE schema_version (
  version     INTEGER NOT NULL,
  applied_at  TEXT    NOT NULL
);
```

The FTS index is maintained by triggers on `document_section`, not by a reindex step. A search index that lags a write returns a result set missing the thing just written, and reports success — an instance of NFR6's false-pass class, so it is closed at the schema rather than left to a caller to remember.

### Constraint-to-drift mapping

| Drift in CPM today | Constraint that ends it |
|---|---|
| `**Source spec**` naming a spec that may not exist | `document.parent_id` FK |
| `FR1a` reduced to `FR1` by string surgery | `requirement.parent_id` FK |
| `ENVn` vs `ENVXn` distinguished by spelling | `requirement.class` CHECK |
| MoSCoW read from the markdown heading above a bullet | `requirement.moscow` CHECK |
| Deferral inferred from a label appearing in a Scope bullet | `requirement.exclusion` CHECK |
| `must NOT —` recognised by prose prefix | `acceptance_criterion.polarity` CHECK |
| Coverage matrix parsed as a markdown table | `coverage` rows |
| `REQ = STATE ∪ EXCLUDED` asserted by test | partition holds by construction |
| Numbers recovered by globbing two directories | `number_sequence` |
| Archive mirror as a load-bearing directory contract | `document.status = 'archived'` |
| Artifact index and in-document backlinks, kept in step by hand | `artifact_document` join table |
| Progress files, session suffixes, adoption on resume | `session` rows |
| Status written as `Done` / `done` / `✅` | `CHECK` constrained enums throughout |

Fourteen rows. The four shell helpers whose work they absorb — `coverage-parse.sh`, `coverage-rollup.sh`, `progress-classify.sh`, `cleancheck-guard.sh` — are 1,686 of the 2,305 lines in `cpm/hooks/lib/`. The claim of this spec is not that the schema is clever; it is entirely ordinary. It is that ordinary constraints are unavailable in the current substrate at any price.

## Scope

### In Scope

- The SQLite schema for all CPM artefact types, with foreign keys, `CHECK`-constrained enums, and FTS5.
- The MCP server: typed create, read, update, link, and search tools; migrations; integrity verification.
- The markdown projection renderer and the pre-commit divergence guard.
- The deterministic dump-and-restore path.
- A one-time importer from an existing CPM `docs/` tree.
- dpm skill files mirroring CPM's pipeline, rewritten against the tool surface.

### Out of Scope

- Changes to CPM itself. dpm is a separate plugin; CPM is unmodified and remains installable alongside.
- A web or TUI interface. Reads go through MCP tools or the generated markdown.
- Any write path through markdown (FR18).
- Multi-project federation (FR17 is a Could Have, not committed).

### Deferred

- **FR16 semantic diff** — valuable for review, but the markdown projection already gives reviewers a readable diff, so this is an improvement rather than a gap.
- **FR17 cross-project queries** — needs a project-registry design that does not exist yet.
- **Retirement of CPM's coverage helpers.** They stay shipped and working in CPM. dpm not needing them is the win; deleting them from another plugin is not this spec's business.

## Testing Strategy

### Tag Vocabulary

- `[unit]` — Individual components in isolation.
- `[integration]` — Boundaries between components.
- `[feature]` — Complete workflows end to end.
- `[manual]` — A human judges it; no automation is possible in principle.
- `[target]` — Mechanically checkable, but only against a real deployment target. Not self-assessable in an autonomous run.
- `[tdd]` — Workflow mode, composable with any level tag.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| FR1 | Creating each artefact type produces a row readable by its typed read tool | `[integration]` |
| FR2 | Creating an epic with a non-existent `spec_id` fails, and no row is written | `[integration]` |
| FR2 | must NOT — a foreign-key violation is accepted because `foreign_keys` defaulted off on a fresh connection | `[integration]` |
| FR2 | must NOT — any reference column resolves its target table at runtime instead of declaring a foreign key (AD7) | `[integration]` |
| FR4 | Every `requirement` and `acceptance_criterion` type distinction is readable from a column with `label` and `text` withheld | `[integration]` |
| FR3 | Every dpm SKILL.md contains no SQL keyword and no `sqlite3` invocation | `[integration]` |
| FR4 | A status value outside its enum is rejected by `CHECK`, not coerced | `[unit]` |
| FR4 | must NOT — any code path derives a requirement's class by parsing its label text | `[integration]` |
| FR5 | Numbers allocated across create-archive-create never repeat, including past 99 | `[unit]` |
| FR6 | Regenerating the projection twice from one database state yields byte-identical output | `[integration]` |
| FR7 | A hand-edited generated file causes the pre-commit guard to exit non-zero, naming the file | `[feature]` |
| FR7 | must NOT — a hand-edit is silently overwritten with no diagnostic | `[feature]` |
| FR8 | Dumping the same database on two machines yields byte-identical `.sql` | `[integration]` |
| FR8 | Two branches each adding an epic produce a resolvable text conflict, and the merged dump restores | `[feature]` |
| FR9 | A search returns ranked results, and the index reflects a write made in the same session | `[integration]` |
| FR10 | Every artefact type CPM produces has a table, a create tool, and a projection template | `[integration]` |
| FR11 | A session row survives simulated resume under a new session id, and stale rows are selected by age | `[integration]` |
| FR12 | A database at schema version *n* is migrated to *n+1* on server start with no user action | `[integration]` |
| FR14 | The integrity tool reports a deliberately orphaned row | `[integration]` |
| FR15 | Importing this repository's own archived `docs/` tree populates every artefact type without loss | `[feature]` |
| NFR1 | A clean clone starts the server with no compilation step | `[target]` |
| NFR2 | The server refuses to start below the Node floor with a message naming the required version | `[integration]` |
| NFR3 | A full session's stdout parses as well-formed JSON-RPC with no stray output | `[integration]` |
| NFR4 | Dumping the same state repeatedly is byte-stable across runs and locales | `[integration]` |
| NFR6 | Each false-pass-capable condition has a test asserting it blocks rather than warns | `[integration]` |
| NFR6 | A duplicate coverage row is rejected for every combination of NULL and non-NULL in `story_id` / `task_id` | `[unit]` |
| NFR6 | must NOT — any `UNIQUE` constraint over a nullable column is relied on to reject duplicates, given SQLite's distinct-NULL semantics | `[unit]` |

FR3's criterion is a **property of the skill corpus**, checkable by grep, and is the one place where a grep proxy is the real thing rather than a stand-in: the requirement is literally that no SQL appears in a skill file.

FR8's second criterion is the only test that exercises the branching story end to end, and it is the criterion most likely to be skipped for being awkward to automate. It is the one that decides whether AD3 and AD4 together actually work.

### Integration Boundaries

Four seams:

1. **MCP tool schemas → database constraints.** A tool that accepts an argument the schema will reject has moved validation to the wrong layer. The two definitions must correspond, not merely coexist.
2. **Database state → markdown projection.** Determinism (FR6) and the divergence guard (FR7) both live here.
3. **Database state → `.sql` dump.** Byte-stability (NFR4) is the whole contract.
4. **CPM `docs/` tree → importer.** The one place dpm parses prose, by necessity — and the one component where CPM's parsing lessons, including retro 21's `awk -v` failure, apply directly.

Seam 1 is where drift would re-enter the system if it re-entered anywhere: two descriptions of the same constraint, in two languages, maintained separately. One definition, generated into both, or a test asserting correspondence.

### Test Infrastructure

New. CPM's suites are bash against fixture markdown files; dpm needs a Node test setup with an in-memory or temp-file database per test, plus a fixture corpus of artefacts. The importer (FR15) has a free real-world corpus available: this repository's own `docs/archive/`, which holds 46 specs and their epics, retros, and reviews.

### Unit Testing

Handled at the `cpm:do` task level — each story's acceptance criteria drive coverage during implementation.
