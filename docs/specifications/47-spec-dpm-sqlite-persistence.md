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
- **FR10 — Full CPM artefact parity, derived from real output.** Every artefact type CPM produces is modelled from the outset: brief (problem and product), ADR, spec, requirement, epic, story, task, story criterion, coverage, review, finding, retro, lesson, quick record, discussion, artifact, library document, audit, runbook, verification record, and session state. The list and every vocabulary in it are taken from a real CPM project's `docs/` tree, not from CPM's documentation — the two disagree.
- **FR11 — Session state is a row.** The progress-file subsystem — session-suffixed filenames, hook injection, adoption on `--resume`, compact-summary companions — is replaced by a session table. Adoption is an `UPDATE`; staleness is a `WHERE` clause.
- **FR21 — Verification is bound to the text it verified, and decays when that text changes.** A coverage row records what it was verified against; editing either the requirement fragment or the story criterion resets it to unverified automatically. Every coverage matrix CPM writes states this rule in prose and relies on an agent to honour it; here the database enforces it.
- **FR22 — Relationships between artefacts are typed edges, not status values.** Blocking, spec-to-spec lineage, and ADR constraint are rows in one edge table with a kind, so "which epics are ready" is a query, a blocker's completion is visible to everything downstream, and a new relationship kind is data rather than a migration. Source and target may each be a document or a story.
- **FR24 — Every controlled vocabulary is a table, and projects may edit it.** Observation categories, finding categories, audit dimensions, severities and test approaches are rows referenced by foreign key — seeded with defaults, extensible per project, and retirable without invalidating rows that already use them. An item may carry more than one category where the work genuinely spans two.
- **FR23 — Two-level numbering.** Root-numbered kinds (a spec) and child-numbered kinds (an epic, numbered within its spec and restarting at 1 per parent) are both allocated monotonically and never reused.

### Should Have

- **FR12 — Schema migrations are versioned and forward-only.** A `schema_version` row and an ordered migration set, applied automatically on server start, so a plugin update never requires the user to intervene.
- **FR13 — Reads are bounded by default.** Query tools accept limits and return summaries rather than whole bodies unless a body is explicitly requested, so a skill reading an epic no longer pulls 20 KB into context to answer a question about its status.
- **FR14 — Referential integrity is checkable on demand.** A verification tool reports orphans, dangling links, and constraint drift across the whole database, so a corrupted state is diagnosable without SQL.

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

### AD8 — Every project starts with an empty database

**Decision**: dpm never reads a CPM `docs/` tree. New and existing projects alike begin with a blank database; there is no importer and no migration path from CPM's markdown artefacts.

**Rejected**: a one-time importer, so an existing CPM project could adopt dpm carrying its history. Attractive on its face, and it was in an earlier draft of this spec as FR15 — added on the author's initiative rather than requested. It was cut because it buys continuity at the price of making CPM's entire historical output a compatibility surface.

**Consequence**: this is the decision that makes the rest of the schema free, and three things follow from it directly.

- **dpm parses no prose anywhere.** Markdown is strictly write-only output with no reader in the system. The one component that would have had to re-solve CPM's parsing problems — and inherit its parsing failures — does not exist.
- **CPM's vocabularies are not binding.** Status words, severity scales, retro categories and audit dimensions are dpm's to choose. What dpm must still *express* is whatever its own pipeline needs; what it calls things is unconstrained, because no artefact crosses between the systems.
- **Constraints can be strict.** With the only write path a typed MCP tool, an unrecognised value cannot arrive, so `CHECK` constraints reject rather than lint. CPM must accept-and-flag a malformed status because it reads human-edited files; dpm reads none, so the conservative behaviour is unnecessary here.

The two systems coexist by not touching. A project runs CPM or dpm, and the choice is made once at the start.

## Data Model

Abridged to the load-bearing definitions. Full DDL is an implementation artefact; what belongs here is the shape and the constraint behind each drift class named in the Problem Summary.

### Identity, numbering and lineage

```sql
CREATE TABLE document_kind (
  kind        TEXT PRIMARY KEY,          -- 'spec','epic','retro','review','runbook',…
  dir         TEXT NOT NULL,             -- projection directory under docs/
  numbering   TEXT NOT NULL DEFAULT 'root'
                CHECK (numbering IN ('root','child','none'))
);

CREATE TABLE document (
  id          INTEGER PRIMARY KEY,
  kind        TEXT    NOT NULL REFERENCES document_kind(kind),
  number      INTEGER,          -- root-numbered kinds: spec 47. NULL for child-numbered
  sequence    INTEGER,          -- child-numbered kinds: epic 03 within spec 101
  slug        TEXT    NOT NULL,
  title       TEXT    NOT NULL,
  status      TEXT    NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','complete')),
  status_note TEXT,             -- the free-text qualifier real epics append to a status
  parent_id   INTEGER REFERENCES document(id),   -- epic→spec, retro→epic, review→epic
  archived_at TEXT,             -- orthogonal to status; NULL means live
  commit_sha  TEXT,             -- audit and inspect pin to a commit
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL,
  CHECK ((number IS NULL) <> (sequence IS NULL)),
  CHECK (sequence IS NULL OR parent_id IS NOT NULL)
);

CREATE UNIQUE INDEX document_root_number
  ON document (kind, number)              WHERE number IS NOT NULL;
CREATE UNIQUE INDEX document_child_number
  ON document (kind, parent_id, sequence) WHERE sequence IS NOT NULL;

CREATE TABLE number_sequence (
  kind        TEXT    NOT NULL REFERENCES document_kind(kind),
  parent_id   INTEGER REFERENCES document(id) ON DELETE CASCADE,  -- NULL for root-numbered
  next_value  INTEGER NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX number_sequence_root
  ON number_sequence (kind)            WHERE parent_id IS NULL;
CREATE UNIQUE INDEX number_sequence_child
  ON number_sequence (kind, parent_id) WHERE parent_id IS NOT NULL;
```

**Numbering is two-level, because real projects number two ways.** A spec is numbered globally (`47-spec-…`); an epic is numbered *within* its spec (`101-03-epic-cpm-markers.md` is sequence 3 under spec 101, and every spec restarts at 1). A single `number` column with `UNIQUE (kind, number)` cannot hold the second, so `number` and `sequence` are exclusive alternatives enforced by `CHECK`, and a child sequence requires a parent to be counted within.

`number_sequence` satisfies FR5 for both levels — one row per root kind, one row per (child kind, parent). Allocation is `UPDATE number_sequence SET next_value = next_value + 1 WHERE … RETURNING next_value - 1`, monotonic irrespective of deletion or archival. The **Numbering** procedure's glob-the-active-directory, glob-the-archive-mirror, union, parse-as-integer-not-string, and its standing `99 → 100` warning all reduce to that statement — and `cpm:archive`'s obligation to preserve `docs/archive/{type}/` as a mirrored tree stops being a contract at all, because retirement sets `archived_at` on a row that never moves.

**Status carries a note, and archival is not a status.** A status frequently needs a qualifier — *complete, but folded into another story*; *pending, but waiting on a third party*. In a markdown store that qualifier has nowhere to go but the same line as the status word, which is why CPM parses a lead token and preserves the tail. dpm has a typed write path and no such constraint, so the qualifier is simply its own column: `status` is always exactly one enum value, and `status_note` carries the rest.

`archived_at` is separate from `status` because the two are orthogonal — a document is archived *and* complete. Collapsing them into one enum forces a false choice and loses the completion state on archival.

**Vocabularies here are dpm's own** (AD8). Studying a real 393-artefact CPM project was useful evidence about what planning data actually contains — statuses need qualifiers, blocking is a graph, coverage binds to text fragments — but dpm is not bound to CPM's spellings, because nothing ever crosses between the two.

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
                CHECK (status IN ('pending','complete')),
  status_note TEXT,
  position    INTEGER NOT NULL,
  UNIQUE (epic_id, number)
);

CREATE TABLE task (
  id          INTEGER PRIMARY KEY,
  story_id    INTEGER NOT NULL REFERENCES story(id) ON DELETE CASCADE,
  number      INTEGER NOT NULL,
  title       TEXT    NOT NULL,
  description TEXT,
  status      TEXT    NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending','complete')),
  status_note TEXT,
  position    INTEGER NOT NULL,
  UNIQUE (story_id, number)
);

CREATE TABLE test_approach (
  tag   TEXT PRIMARY KEY,                            -- unit, integration, feature, manual, target, tdd
  kind  TEXT NOT NULL CHECK (kind IN ('level','mode'))
);

-- Spec-side criteria: the spec's own Testing Strategy table,
-- `| Requirement | Acceptance Criterion | Test Approach |`.
CREATE TABLE acceptance_criterion (
  id              INTEGER PRIMARY KEY,
  requirement_id  INTEGER NOT NULL REFERENCES requirement(id) ON DELETE CASCADE,
  text            TEXT    NOT NULL,
  polarity        TEXT    NOT NULL DEFAULT 'must'
                    CHECK (polarity IN ('must','must_not','control')),
  position        INTEGER NOT NULL,
  UNIQUE (requirement_id, position)
);

CREATE TABLE criterion_approach (
  criterion_id  INTEGER NOT NULL REFERENCES acceptance_criterion(id) ON DELETE CASCADE,
  tag           TEXT    NOT NULL REFERENCES test_approach(tag),
  PRIMARY KEY (criterion_id, tag)
);

-- Story-side criteria: the epic's `**Acceptance Criteria**:` bullets,
-- a DIFFERENT set from the spec's. The coverage matrix joins the two.
CREATE TABLE story_criterion (
  id          INTEGER PRIMARY KEY,
  story_id    INTEGER NOT NULL REFERENCES story(id) ON DELETE CASCADE,
  text        TEXT    NOT NULL,
  polarity    TEXT    NOT NULL DEFAULT 'must'
                CHECK (polarity IN ('must','must_not','control')),
  position    INTEGER NOT NULL,
  UNIQUE (story_id, position)
);

CREATE TABLE story_criterion_approach (
  story_criterion_id INTEGER NOT NULL REFERENCES story_criterion(id) ON DELETE CASCADE,
  tag                TEXT    NOT NULL REFERENCES test_approach(tag),
  PRIMARY KEY (story_criterion_id, tag)
);

-- One row per matrix row: a VERBATIM FRAGMENT of a requirement bound to one
-- story criterion. A single requirement yields several rows — FR4 of spec 101
-- produces three, each independently verified.
CREATE TABLE coverage (
  id                 INTEGER PRIMARY KEY,
  requirement_id     INTEGER NOT NULL REFERENCES requirement(id) ON DELETE CASCADE,
  spec_fragment      TEXT    NOT NULL,
  story_criterion_id INTEGER NOT NULL REFERENCES story_criterion(id) ON DELETE CASCADE,
  position           INTEGER NOT NULL,
  verified_at        TEXT,            -- NULL = unverified; the ✓ column
  binding_hash       TEXT,            -- hash of (spec_fragment ‖ criterion text) at verification
  UNIQUE (requirement_id, story_criterion_id, position),
  CHECK ((verified_at IS NULL) = (binding_hash IS NULL))
);

-- "Covered by: Story 2, Story 4" — a criterion may be delivered by more than
-- the story that declares it. Rare (3 rows in a 393-artefact corpus) but real.
CREATE TABLE coverage_story (
  coverage_id  INTEGER NOT NULL REFERENCES coverage(id) ON DELETE CASCADE,
  story_id     INTEGER NOT NULL REFERENCES story(id)    ON DELETE CASCADE,
  PRIMARY KEY (coverage_id, story_id)
);

-- Verification is bound to text, and text changes silently. These triggers are
-- the schema-level statement of the rule every coverage matrix carries in prose.
CREATE TRIGGER coverage_unverify_on_criterion_edit
AFTER UPDATE OF text ON story_criterion
WHEN OLD.text <> NEW.text
BEGIN
  UPDATE coverage SET verified_at = NULL, binding_hash = NULL
   WHERE story_criterion_id = NEW.id;
END;

CREATE TRIGGER coverage_unverify_on_requirement_edit
AFTER UPDATE OF text ON requirement
WHEN OLD.text <> NEW.text
BEGIN
  UPDATE coverage SET verified_at = NULL, binding_hash = NULL
   WHERE requirement_id = NEW.id;
END;
```

`polarity` is the sleeper. A negative criterion is currently written `must NOT — …` and recognised by that prefix; a control case by the word `control`. Both are types carried in prose, in the one artefact whose whole purpose is deciding whether the work is done.

The coverage matrix — a markdown table, parsed row by row by `coverage_matrix_rows()` (`:585`) — becomes rows. The roll-up that `coverage-rollup.sh` performs in 802 lines becomes a join, and its `REQ = STATE ∪ EXCLUDED` partition property (spec 44 NFR4, restated as spec 46 NFR4) stops being a property to assert and becomes one that cannot fail: `exclusion IS NOT NULL` and `exclusion IS NULL` partition the table by construction.

**Two criterion sets, not one.** A spec states its criteria in `## Testing Strategy`; an epic states different ones per story. The matrix's job is joining them, and its columns say so — `Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified`. Modelling only the spec side leaves the join with nothing on its right-hand side, which is what an earlier draft of this section did.

**The grain is a fragment, not a requirement.** Rows 1–3 of a real matrix all cite `FR4`, each binding a different verbatim slice of FR4's text to a different story criterion, each carrying its own ✓. A `coverage(requirement_id, story_id)` row cannot represent three independent verification states for one requirement, so `spec_fragment` is stored per row and the requirement is referenced, not consumed.

**Verification decays, and the schema has to know.** Every matrix carries this rule in prose:

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

A plain `state` column cannot honour it: edit a criterion and the ✓ survives, now attesting to text that no longer exists. That is a false pass inside the coverage subsystem — the precise failure class this spec exists to eliminate, reproduced by this spec's own first draft. `binding_hash` records what was verified, the `CHECK` keeps it in lockstep with `verified_at`, and the two triggers make the reset automatic rather than remembered.

### Dependencies and retro feed-forward

```sql
-- Edge kinds are rows, so a new relationship is data rather than a migration.
-- `blocks` gates readiness; `builds_on` and `constrains` are lineage only.
CREATE TABLE dependency_kind (
  kind         TEXT PRIMARY KEY,      -- 'blocks','builds_on','constrains'
  gates_work   INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE dependency (
  id                  INTEGER PRIMARY KEY,
  kind                TEXT NOT NULL REFERENCES dependency_kind(kind),
  source_document_id  INTEGER REFERENCES document(id) ON DELETE CASCADE,
  source_story_id     INTEGER REFERENCES story(id)    ON DELETE CASCADE,
  target_document_id  INTEGER REFERENCES document(id) ON DELETE CASCADE,
  target_story_id     INTEGER REFERENCES story(id)    ON DELETE CASCADE,
  CHECK ((source_document_id IS NULL) <> (source_story_id IS NULL)),
  CHECK ((target_document_id IS NULL) <> (target_story_id IS NULL)),
  CHECK (source_document_id IS NULL OR target_document_id IS NULL
         OR source_document_id <> target_document_id),
  CHECK (source_story_id IS NULL OR target_story_id IS NULL
         OR source_story_id <> target_story_id)
);

-- One expression index rather than four partial ones: coalesce removes the
-- NULLs that would otherwise make every edge distinct from every other.
CREATE UNIQUE INDEX dependency_edge ON dependency (
  kind,
  coalesce(source_document_id, -1), coalesce(source_story_id, -1),
  coalesce(target_document_id, -1), coalesce(target_story_id, -1)
);

-- `**Retro applied**: 12 · Codebase discovery · Applied — <text>`
-- Four fields in one prose line, on 29 epics.
CREATE TABLE retro_application (
  id            INTEGER PRIMARY KEY,
  retro_id      INTEGER NOT NULL REFERENCES document(id) ON DELETE CASCADE,
  applied_to_id INTEGER NOT NULL REFERENCES document(id) ON DELETE CASCADE,
  theme         TEXT NOT NULL DEFAULT '',
  disposition   TEXT NOT NULL
                  CHECK (disposition IN ('applied','not_applicable','deferred')),
  note          TEXT NOT NULL DEFAULT '',
  UNIQUE (retro_id, applied_to_id, theme, note)
);
```

Blocking is a **relationship**, and an earlier draft of this spec made it a `status` value — the same category error the Problem Summary accuses CPM of committing with `**Source spec**`. A status cannot say *what* blocks you, cannot be traversed to find a ready epic, and cannot be invalidated when the blocker completes.

**Edges are typed, and their kinds are rows, because more relationships exist than any one skill defines.** Three are already in evidence:

- **`blocks`** — an epic blocked by epics, or a story blocked by another story. Both directions occur in real epics, which is why source and target may each be either a document or a story.
- **`builds_on`** — spec-to-spec lineage. CPM has no field for this, yet three real specifications carry a hand-written `**Builds on**:` header. A field invented independently in three documents is a missing feature, not a stylistic flourish.
- **`constrains`** — ADR-to-ADR, which CPM *does* define ("Depends on ADR {nn}" / "Constrains ADR {nn}") and which is directional and distinct from blocking.

`gates_work` separates the edge that stops work from the edges that merely record lineage, so readiness is a query over one flag rather than a hardcoded list of kinds.

`theme` and `note` are `NOT NULL DEFAULT ''` rather than nullable, so the `UNIQUE` actually constrains. Nullable columns in a `UNIQUE` are the trap already documented against `coverage`, and the fix is cheaper here than a second pair of partial indexes.

### Review, retro, and the library

```sql
-- Every controlled vocabulary is a table, seeded but project-editable.
-- `retired_at` lets a project stop offering a category without deleting the
-- rows that already use it.
CREATE TABLE taxonomy (
  id          INTEGER PRIMARY KEY,
  domain      TEXT    NOT NULL,   -- 'observation','finding','audit_dimension','severity'
  name        TEXT    NOT NULL,   -- canonical form, e.g. 'Patterns Worth Reusing'
  singular    TEXT,               -- per-item display form, e.g. 'Pattern worth reusing'
  position    INTEGER NOT NULL,
  retired_at  TEXT,
  UNIQUE (domain, name)
);

CREATE TABLE finding (
  id              INTEGER PRIMARY KEY,
  review_id       INTEGER NOT NULL REFERENCES document(id) ON DELETE CASCADE,
  agent           TEXT,
  category_id     INTEGER NOT NULL REFERENCES taxonomy(id),
  severity_id     INTEGER NOT NULL REFERENCES taxonomy(id),
  summary         TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'open'
                    CHECK (status IN ('open','accepted','rejected','remediated')),
  remediation_task_id INTEGER REFERENCES task(id)
);

-- A retro observation. Also the story-level `**Retro**:` field, which is the
-- same thing recorded earlier — hence the exclusive parentage.
CREATE TABLE observation (
  id              INTEGER PRIMARY KEY,
  retro_id        INTEGER REFERENCES document(id) ON DELETE CASCADE,
  story_id        INTEGER REFERENCES story(id)    ON DELETE CASCADE,
  text            TEXT NOT NULL,
  synthesis       TEXT,            -- written when grouped into a retro
  note            TEXT,            -- escape hatch: qualifiers, caveats, scope
  library_doc_id  INTEGER REFERENCES document(id),   -- set on promotion
  retired_at      TEXT,
  retired_reason  TEXT,
  CHECK ((retro_id IS NULL) <> (story_id IS NULL)),
  CHECK ((retired_at IS NULL) = (retired_reason IS NULL))
);

-- Many-to-many: an observation genuinely spans categories.
CREATE TABLE observation_category (
  observation_id INTEGER NOT NULL REFERENCES observation(id) ON DELETE CASCADE,
  taxonomy_id    INTEGER NOT NULL REFERENCES taxonomy(id),
  PRIMARY KEY (observation_id, taxonomy_id)
);

CREATE TABLE audit_finding (
  id           INTEGER PRIMARY KEY,
  audit_id     INTEGER NOT NULL REFERENCES document(id) ON DELETE CASCADE,
  dimension_id INTEGER NOT NULL REFERENCES taxonomy(id),
  file         TEXT NOT NULL,
  line         INTEGER,
  symbol       TEXT,
  severity_id  INTEGER NOT NULL REFERENCES taxonomy(id)
);
```

`finding.remediation_task_id` closes a loop CPM leaves open: a review finding that generated a remediation task is joined to it, so "which findings were actually acted on" is a query rather than a reading exercise.

**Why every taxonomy is a table.** This is the design decision in this spec with the strongest empirical backing, and the evidence is worth stating exactly.

CPM fixes seven retro observation categories, named in a prose sentence inside a shared procedure. Across 22 real retro files in one project they appear as **eleven distinct headings**:

| Intended category | What was actually written |
|---|---|
| smooth deliveries | `Smooth Deliveries` (7), `What Went Smoothly` (5), `Smooth Delivery` (5) |
| codebase discoveries | `Codebase Discoveries` (15), `Codebase Discovery` (2) |
| testing gaps | `Testing Gaps` (11), `Testing Gap` (1), `Testing Notes` (1) |
| scope surprises | `Scope Surprises` (1), `Scope Surprise` (1) |
| criteria gaps | `Criteria Gaps` (2) |
| patterns worth reusing | `Patterns Worth Reusing` (18) |
| complexity underestimates | *never used, in any file* |

`What Went Smoothly` is a paraphrase, `Testing Notes` an invention, and the canonical `Smooth Deliveries` is the minority spelling of its own category.

The control case is in the same project, by the same author, in the same period: **review finding categories held almost perfectly** — all ten canonical categories used, roughly seven strays across a hundred headings. The difference is not discipline, it is form. Review categories appear as **literal headings in the skill's output template** and get copied; retro categories appear as **prose inside a shared procedure** and get restated in the author's own words.

Three consequences are built into the schema above:

- **`taxonomy` rows, referenced by FK.** Eleven spellings of seven categories cannot occur when the category is an id.
- **`observation_category` is many-to-many.** Real observations were forced into invented compounds — `Testing gap → guard friction`, `Testing gap / pattern`, `Pattern reuse + testing` — because the format allowed one category and the work spanned two.
- **`taxonomy.retired_at`, not deletion.** One of the seven categories was never used once. A project should be able to stop offering a category without invalidating rows that already reference it, which means the vocabulary is data and not an enum.

`taxonomy.singular` exists because the canonical list is plural (it names categories) while a field carrying one observation wants the singular — `Pattern worth reusing` outnumbers `Patterns worth reusing` 31 to 4. Nobody specified which to use, so both were guessed. Storing both forms makes it a projection concern rather than an authoring decision.

**Retirement keeps its date and reason and stays reversible.** `observation.retired_at` / `retired_reason` mirror CPM's in-place `**Retired {date}**: {reason}` marker rather than collapsing it to a status value. CPM's design note gives the reason — the marker "preserves category context and leaves a visible, greppable, reversible record" — and un-retiring is setting both columns back to NULL. `library_doc_id` records where an observation went when promoted, which is also what a promotion sets as its retirement reason.

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
| ✓ surviving an edit to the criterion it verified | `binding_hash` + unverify triggers |
| One requirement's several obligations collapsed to one row | `coverage.spec_fragment`, one row each |
| Story criteria readable only as epic prose | `story_criterion` rows |
| `**Blocked by**` as a prose list of epic filenames | `dependency` edges |
| Seven retro categories written as eleven headings | `taxonomy` rows, referenced by FK |
| An observation forced into one category when it spans two | `observation_category` many-to-many |
| `**Builds on**` hand-invented in three specs, unspecified | `dependency_kind = 'builds_on'` |
| Retirement collapsing date and reason into a state | `retired_at` + `retired_reason`, reversible |
| A test-approach tag appearing in a retro category slot | FK to `taxonomy`, domain-scoped |
| `**Retro applied**: 12 · theme · Applied — …` in one line | `retro_application` columns |
| Status carrying an unparseable free-text qualifier | `status` + `status_note` |
| Numbers recovered by globbing two directories | `number_sequence`, root and child |
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
- dpm skill files mirroring CPM's pipeline, rewritten against the tool surface.

### Out of Scope

- **Any importer from CPM's markdown artefacts** (AD8). Every project starts with an empty database. This was briefly FR15 in an earlier draft; it was never requested and is now an explicit non-goal.
- **Compatibility with CPM's existing output.** dpm does not read, parse, or reproduce historic artefacts, and therefore does not inherit their conventions — legacy filename shapes, read-only status synonyms, or free-text status tails are CPM's concerns, not dpm's.
- **Reproducing CPM's vocabularies.** dpm defines its own enums (AD8). CPM's are useful prior art and no more.
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
| FR21 | Editing a story criterion's text clears `verified_at` and `binding_hash` on every coverage row bound to it | `[unit]` |
| FR21 | Editing a requirement's text clears verification on its coverage rows | `[unit]` |
| FR21 | must NOT — a coverage row holds `verified_at` while `binding_hash` is NULL, or the reverse | `[unit]` |
| FR21 | control — an edit that leaves the text byte-identical does not clear verification | `[unit]` |
| FR22 | An epic blocked by two epics yields two `dependency` rows, and completing both makes it selectable as ready | `[integration]` |
| FR22 | A story-to-story `blocks` edge and a spec-to-spec `builds_on` edge both round-trip through one table | `[unit]` |
| FR22 | A `builds_on` edge does not gate readiness; a `blocks` edge does | `[unit]` |
| FR22 | must NOT — a document or story depends on itself | `[unit]` |
| FR22 | must NOT — the same edge is storable twice, for any combination of NULL source/target columns | `[unit]` |
| FR24 | An observation carrying two categories round-trips, and appears under both in the projection | `[integration]` |
| FR24 | Retiring a taxonomy row leaves rows referencing it intact and readable | `[unit]` |
| FR24 | A project-added category is usable without a schema migration | `[integration]` |
| FR24 | must NOT — any category, severity, dimension or approach is stored as free text rather than a foreign key | `[integration]` |
| FR23 | Two epics under different specs may both hold sequence 1; two under the same spec may not | `[unit]` |
| FR23 | Child sequences restart at 1 per parent and never reuse a value after deletion | `[unit]` |
| FR23 | must NOT — a row carries both `number` and `sequence`, or neither | `[unit]` |
| FR12 | A database at schema version *n* is migrated to *n+1* on server start with no user action | `[integration]` |
| FR14 | The integrity tool reports a deliberately orphaned row | `[integration]` |
| AD8 | must NOT — any component reads, globs, or parses a markdown file under `docs/` | `[integration]` |
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
There is deliberately **no fourth seam**. An earlier draft listed "CPM `docs/` tree → importer" as the one place dpm parses prose by necessity. AD8 removes it: nothing in dpm reads markdown, so the component that would have inherited CPM's parsing failures — retro 21's `awk -v` collapse among them — has no counterpart here.

Seam 1 is where drift would re-enter the system if it re-entered anywhere: two descriptions of the same constraint, in two languages, maintained separately. One definition, generated into both, or a test asserting correspondence.

### Test Infrastructure

New. CPM's suites are bash against fixture markdown files; dpm needs a Node test setup with an in-memory or temp-file database per test, plus a fixture corpus of artefacts.

Fixtures are written against the tool surface, not parsed from markdown — AD8 means there is no import path to exercise. Each test creates entities through the MCP tools, so the fixtures and the production write path are the same code.

A real 393-artefact CPM project remains valuable as **design evidence** rather than as a test input: it shows what planning data accumulates in practice once a pipeline has been run in anger, including structure the skills never specified. Every vocabulary in this schema was corrected against it, and the schema before that check contained eight defects — one of them a false pass in the coverage subsystem (FR21).

### Unit Testing

Handled at the `cpm:do` task level — each story's acceptance criteria drive coverage during implementation.
