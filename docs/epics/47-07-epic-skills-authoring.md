# Skills: Authoring

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Date**: 2026-08-08  
**Status**: Pending  
**Blocked by**: Epic 47-04-epic-projection-guard-and-merge, Epic 47-05-epic-parity-and-search

Milestone M4 (AD6). Seven of FR25's twenty-two skills, one story each. These are the skills
that *produce* artefacts other than the spine's, and they are where CPM's prose markers are
densest — `**Retired**`, `**Retro waived**`, `**Superseded**`, each a separate convention
with its own parse. Every one becomes a column here.

Per the pattern set in Epic 47-06 and approved on 2026-08-08, FR25's and FR3's mechanical
checks sweep all seven files on Story 8 rather than being restated per story.

## Convert `discover`
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25

**Acceptance Criteria**:

- A discover run writes a problem brief document and its sections through create tools [feature]
- The facilitation survives: the run still explores the problem before proposing, and still refuses to produce a brief from an unexamined premise [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Rewrite the problem-brief write path as tool calls
**Task**: 1.1  
**Description**: The document and its sections. Undecomposed prose keeps a home in `document_section` rather than being over-modelled.  
**Status**: Pending

### Replace numbering, filename construction and the progress file with tool calls and a session row
**Task**: 1.2  
**Description**: The same four subtractions every skill makes. Stated once per skill because each file makes them independently.  
**Status**: Pending

### Write tests for Convert `discover`
**Task**: 1.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `brief`
**Story**: 2  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR2

**Acceptance Criteria**:

- A brief run writes a product brief whose `parent_id` names the problem brief, read through a read tool rather than resolved by slug matching [feature]
- The facilitation survives: the run still gates on scope and still separates the problem from the proposed shape [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Rewrite the product-brief write path, resolving its parent through a read tool
**Task**: 2.1  
**Description**: Parentage is `parent_id` plus a `CHECK`-pinned `parent_kind`, so naming the wrong kind of document is a write-time failure rather than a chain that resolves to the wrong node.  
**Status**: Pending

### Remove slug-matching chain discovery
**Task**: 2.2  
**Description**: A brief cannot name a problem brief that does not exist, so it never needs to guess which one it meant. Slug matching exists only because a filename is the only handle a markdown store offers.  
**Status**: Pending

### Write tests for Convert `brief`
**Task**: 2.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `architect` [plan]
**Story**: 3  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR14, AD7

**Acceptance Criteria**:

- An architect run writes `adr` rows with `decision_status`, plus `adr_option` and `adr_option_tradeoff` rows — the options and their axes are columns, not prose the skill formats [feature]
- Exactly one option per accepted ADR carries `chosen`, enforced at write time rather than by the integrity check finding it later [integration]
- An ADR is created as a child document of a spec, brief or discussion and renders inside its parent, with no number allocated and no path under `docs/architecture/` [feature]
- The facilitation survives: the run still works one phase at a time, still explores trade-offs across options before choosing, and still gates each decision before writing it [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Write `adr_option` and `adr_option_tradeoff` rows
**Task**: 3.1  
**Description**: Options and their axes stop being a prose table the skill formats and a reader compares by eye.  
**Status**: Pending

### Enforce exactly-one-`chosen` at the tool boundary
**Task**: 3.2  
**Description**: Register #8 exists because zero or two chosen options is not expressible as a row-level constraint. Refusing it at the tool boundary means this skill stops being a source of it — the register check stays, because a restore can still bring one in.  
**Status**: Pending

### Replace supersession-by-prose with a `supersedes` edge
**Task**: 3.3  
**Description**: Same reasoning as 3.2, for register #2. A superseded ADR with no outgoing edge is the state the register catches; writing the edge is what stops it being created.  
**Status**: Pending

### Create ADRs as child documents rather than root-numbered files
**Task**: 3.4  
**Description**: `adr` seeds with `dir IS NULL`, so an ADR renders inside the spec, brief or discussion that holds it and has no file of its own. This deletes the skill's number allocation and its `docs/architecture/` path construction outright — two of the five subtractions FR25 names, in one skill. It is also what closes self-hosting register entry 3: spec 47's own ten inline ADs keep `decision_status`, `adr_option` and the tradeoff axes instead of degrading to prose.  
**Status**: Pending

### Write tests for Convert `architect`
**Task**: 3.5  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `review`
**Story**: 4  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR24

**Acceptance Criteria**:

- A review run writes `review` with its `scope` and `scope_story_id`, `review_agent` rows referencing `agent` rows rather than carrying persona names as text, and `finding` rows with severity and category as taxonomy references [feature]
- A story-scoped review parents onto the epic and narrows by `scope_story_id`, rather than appending `-s2` to a filename [integration]
- The facilitation survives: agent selection still includes one reviewer challenging business value and one challenging technical approach, and the finding stage still reports comprehensively before the ranking stage curates [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Write `review`, `review_agent` and `finding` rows with domain-scoped taxonomy references
**Task**: 4.1  
**Description**: Severity and category are drawn from their own domains, so a severity cannot land in a category slot.  
**Status**: Pending

### Replace `-s2` filename scoping with `scope` and `scope_story_id`
**Task**: 4.2  
**Description**: A story-scoped review is the same kind of document with a narrower scope, which is a column pair rather than a filename suffix.  
**Status**: Pending

### Write tests for Convert `review`
**Task**: 4.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `retro` [plan]
**Story**: 5  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR10, FR24

**Acceptance Criteria**:

- A retro run gathers `observation` rows already written against stories by setting `retro_id`, leaving `story_id` intact, so an observation's origin survives promotion [feature]
- `learn` and `retire` set the retirement columns on the observation rather than editing a marker into prose; a retired observation is excluded from candidate gathering by a `WHERE` clause [integration]
- The facilitation survives: the four modes stay mutually exclusive, a `learn` still previews both the library entry and the retirement before either is written, and promotion still retires at the source in the same operation [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Gather observations by setting `retro_id` without clearing `story_id`
**Task**: 5.1  
**Description**: Inclusive parentage is what makes this possible — an exclusive constraint would make the act of gathering destroy the origin.  
**Status**: Pending

### Replace the `**Retired**` prose marker with retirement columns, and candidate filtering with a `WHERE` clause
**Task**: 5.2  
**Description**: Offer-side idempotency stops being a convention the skill remembers and becomes a predicate.  
**Status**: Pending

### Rewrite `learn` promotion to write a `library_document` and its `library_scope` rows
**Task**: 5.3  
**Description**: Provenance is a foreign key rather than a `→`-joined source line that has to be parsed to find what was promoted from where.  
**Status**: Pending

### Write tests for Convert `retro`
**Task**: 5.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `audit`
**Story**: 6  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR24

**Acceptance Criteria**:

- An audit run writes `audit_finding` rows whose dimension and severity are domain-scoped taxonomy references, rejected at write time if drawn from the wrong vocabulary [integration]
- The facilitation survives: the run still separates its complete findings from its ranked executive summary [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Write `audit_finding` rows with domain-scoped dimension and severity references
**Task**: 6.1  
**Description**: `audit_finding` and `finding` draw from different domains, and the scoping is what stops one accepting the other's rows.  
**Status**: Pending

### Replace the `**Retro waived**` marker with a column
**Task**: 6.2  
**Description**: One of three prose markers CPM maintains, each with its own parse. Making it a column is what lets `/cpm:status` stop grepping for it.  
**Status**: Pending

### Write tests for Convert `audit`
**Task**: 6.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `quick`
**Story**: 7  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, AD7

**Acceptance Criteria**:

- A quick run writes a `quick` row with its `quick_criterion` rows and its single-category retro observation, all typed [feature]
- Promotion to a completion record is a status update, not a rewrite of the file [feature]
- The facilitation survives: a fix still has its root cause investigated and its diagnosis confirmed before any change is proposed, and implementation still refuses to begin without the written change description [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Write the `quick` row, its `quick_criterion` rows and its single-category observation
**Task**: 7.1  
**Description**: The mandatory single-category observation is a row like any other, so `retro` gathers it without knowing it came from a quick record.  
**Status**: Pending

### Make promotion to a completion record a status update
**Task**: 7.2  
**Description**: The record does not change shape when it ships; its status does. Rewriting the file was the only way to express that in markdown.  
**Status**: Pending

### Write tests for Convert `quick`
**Task**: 7.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Verify cross-story integration for Skills: authoring
**Story**: 8  
**Status**: Pending  
**Blocked by**: Story 1, Story 2, Story 3, Story 4, Story 5, Story 6, Story 7  
**Satisfies**: FR25, FR3, FR24, FR10

**Acceptance Criteria**:

- None of the seven skill files contains a filename pattern under `docs/`, a glob, a number-allocation procedure, or a progress-file lifecycle [unit]
- None of the seven skill files contains a SQL keyword or a `sqlite3` invocation [unit]
- An observation written by `do`, gathered by `retro`, and promoted by `retro learn` retains its `story_id` through all three, so its origin is queryable from the library entry [feature]
- A review of an epic and an audit of the same epic write findings into two different tables with independently scoped vocabularies, and neither accepts the other's severity rows [integration]
- must NOT — a skill writes a `retired`, `waived` or `superseded` marker as prose rather than as a column [integration]

### Write integration tests for Skills: authoring
**Task**: 8.1  
**Description**: The third criterion crosses into Epic 47-06 — `do` writes the observation this epic's `retro` gathers — and is the only place the full promotion chain runs. The final criterion generalises past this epic: three separate prose-marker conventions become columns, and only a sweep over all seven files shows none survived.  
**Status**: Pending

---

## Notes

### Self-hosting register — entries in this epic's scope

The register lives in Epic 47-01's Notes.

**Entry 3** is in scope and is this epic's most direct instance: `architect` is converted
here to write `adr`, `adr_option` and `adr_option_tradeoff` rows, and spec 47 carries ten
inline ADs with exactly that structure — which degrade to `document_section` prose because
`adr` is a document kind and an AD inside a spec has no home. The skill that would have
written them correctly is built here, against a schema that cannot hold them.

**Entry 4** is in scope: `retro` is converted here, and retro 33's `**Source**` is a spec.
`document_kind_parent` seeds `retro→epic`, so the converted skill cannot write the retro
this session produced.

Neither is actionable here — both need spec changes and both carry to `/cpm:pivot`.

### Requirements only partially covered by this epic

**FR25** — seven of twenty-two skills. **FR3** — the skill-corpus half, for seven files.
**FR24** — the write-side use of domain-scoped vocabularies; the schema is Epic 47-01 and
the tools are Epic 47-05. **FR10** — one criterion, on observation origin surviving
promotion, which Epic 47-05 also asserts at the tool layer.
