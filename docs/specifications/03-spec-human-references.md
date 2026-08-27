# Human-readable references in user-facing output

**Number**: 03  
**Status**: complete  

## Problem

A dpm skill can name a document to a person only by its ULID. A `/dpm:status` run recommended its
next step as `/dpm:do 01M0WF1KCX0PTRYNW35FJ4NAVQ`: technically runnable and practically useless. The
reader cannot tell which epic it is, cannot check it against the tree, and cannot type it from
memory.

**The cause is the tool layer, not the skills.** dpm already has a human identifier and already
knows how to build one — `identifierOf()` in `dpm/src/projection/naming.js` produces `47` for a
root-numbered document and `47-03` for a child, and both the projection filenames and the resolved
`{{ref:<id>}}` markers come from that one function so that a filename and an inbound reference
cannot disagree.

None of it reaches a skill. The `list_*` and `read_*` tools return raw table columns, and for a
child-numbered document those columns are not enough: `number` is `null`, and the identifier a human
reads needs the parent's `number`. Composing one therefore costs a second read per document that the
skill has to know to make, and would be got wrong for `coverage_matrix`, whose sequence comes from
its *epic* rather than from itself. So the id is the only complete reference a skill holds after the
call it already made, and every skill printing an id is doing the only thing available to it. Fixing
this in the skill files alone would ask twenty-three skills each to re-derive a rule that already
exists once in the source, and to make an extra call to do it.

**The seam is already there.** `defineTool` in `dpm/src/tools/convention.js` wraps every tool's
handler and post-processes its return value — that is where `withoutBody` applies the summary/body
split, and it already understands the two shapes a dpm tool returns: one row, or a page of them.

**It would not round-trip either.** Seven skills state their argument contract as *names a document
id* — architect, brief, do, epics, review, retro and spec. A skill that printed `/dpm:do 01-01`
would be recommending a command the receiving skill does not accept. Output and input have to move
together, or the recommendation is worse than the ULID: it looks readable and fails.

**Where the ULID is emitted from.** `dpm/skills/status/SKILL.md`'s *Recommended next steps* table
interpolates an id in four rows — `{epic id}` twice, `{spec id}`, `{brief id}`. That table is the
visible symptom rather than the cause; fixing only the table leaves every other skill's
conversational output naming documents by ULID.

## In scope

- `dpm/src/tools/convention.js` — `defineTool` takes a database handle and a declaration, and the
  handler wrapper attaches the reference to document rows in both shapes it already understands: a
  single row, and a `{items: [...]}` page.
- One new tool, `resolve_reference`, together with its registry entry and its conformance and parity
  registrations.
- `dpm/shared/skill-conventions.md` — a new section beside **Cross-References**, governing what a
  skill says to a person rather than what it writes to the database.
- The Input sections of the seven skills whose argument contract reads *names a document id*:
  architect, brief, do, epics, review, retro and spec.
- The *Recommended next steps* table in `dpm/skills/status/SKILL.md`, and a sweep of every skill's
  conversational output for a document named by ULID.
- Whatever test changes the NFR4 enumeration turns up.

**The registration cost is enumerated before the work is scoped, not discovered during it.** Retro 02
recorded that adding a table to this schema cost five registrations where the plan predicted one. A
new tool and a new output field touch at least: the tool registry (`dpm/src/tools/index.js`),
`dpm/tests/conformance.test.js`, `dpm/tests/parity.test.js` and its spent-checked `NO_CREATE_TOOL`
exemptions, `dpm/tests/tools.test.js`, and the fixture surface in
`dpm/tests/fixtures/tool-surface.js`. The enumeration is the first task of the work rather than a
check at the end of it.

**The forced ordering.** FR1 and FR2 gate everything: nothing in FR4 through FR7 can be written until
a skill can obtain a reference. And FR7 gates FR5 — recommending a command by reference before the
receiving skill accepts one ships precisely the failure this spec exists to avoid, where the
recommendation looks readable and does not run.

## Out of scope

- **The identifier scheme itself.** `dpm/src/projection/naming.js` is read rather than revised — the
  padding, the separator and the kind-specific step all stay as they are.
- **Any schema migration.** The reference is computed from columns that already exist, and a
  migration would serve every project read-only until its plugin was reinstalled.
- **Removing or renaming `id` on any tool output.** The reference is added beside it, never in place
  of it.
- **`search` result rows.** They are FTS hits rather than document rows.
- **CPM.** This is a change to dpm; `cpm/` is untouched, and the CPM-era corpus under `docs/cpm/` is
  not read by anything here.

Each of these is a requirement of its own — FR12, ENVX4, FR13, FR15 — carrying its `exclusion` on its
own row rather than being recorded only in this prose.

## Deferred

- **References on non-document rows** — acceptance criteria, observations, coverage rows (FR11). They
  have ids and no numbers, and the honest answer is that they are named by their parent plus a
  position. Recorded as a `could` rather than deferred outright, because the shape is settled even
  though the work is not committed to.
- **`search` hits carrying a reference** (FR15). Deferred rather than ruled out: the rows are
  `entity`, `entity_id`, an excerpt and a score, so a hit would have to be resolved to the row it
  points at before it could be named, and that is a second decision.

## Integration boundaries

Five seams follow from the decisions above. Each is where integration coverage belongs, and each is
named by its contract rather than by the files either side of it.

**1. `defineTool` and tool registration.** The wrapper acquires two things it does not take today: a
database handle, and a declaration from the tool saying its rows are document rows. The contract is
what registration passes in and what a descriptor must declare to opt in. A tool that returns
document rows and does not declare it is the failure this seam has to make visible — silently
missing the field is indistinguishable from a document that cannot be named, which is why AD4 chose
a null over an absence.

**2. The tool layer and `dpm/src/projection/naming.js`.** The contract is `identifiers(db)`: one
query, returning `Map<id, identifier>`, omitting every document whose identifier cannot be derived
rather than raising on it. That omission *is* AD4's null, so the two are one behaviour observed at
two points, and a test that checks only one of them checks half a contract.

**3. `resolve_reference` and the seven skills.** A reference and an optional kind in; one document
row, or a refusal naming what was looked for, out. The kind is what makes the identifier scheme's own
collision addressable — an epic and its coverage matrix share an identifier by construction — so the
seam's hardest case is a legitimate ambiguity rather than a malformed input.

**4. The prose write tools and the prose-column classification.** Which columns are checked comes
from `dpm/tests/support/prose-columns.js`, which already holds the judgement and is already
reconciled against the live schema in both directions. Restating the set at the tool boundary would
be a second list, and it is the copy nothing fails on when it goes stale.

**5. The skills and `dpm/shared/skill-conventions.md`.** The file is read at startup by every skill
that names it, so the new section is the contract between what the tool layer now offers and what a
skill is expected to do with it. It is the only one of the five with no runtime enforcement, which
is why FR6's check reads the skill corpus from the tree rather than trusting the convention to have
been followed.

## Functional Requirements

### FR1 (must)

Every document row returned by a `list_*` or `read_*` tool carries its human identifier as a field alongside the row's own columns, so a skill holds a readable name for a document after the call it has already made, without a second read.

- Every tool in the built registry whose name begins `list_` or `read_` and whose returned rows are `document` rows carries a `reference` field on each row. The set of such tools is enumerated from the registry itself, never from a written list of tool names. `[integration]`
- must NOT — The check must not invoke `defineTool` directly. It calls the registered handlers against a real database, so a wrapper that works in isolation but was never wired to any tool fails. `[integration]`

### FR2 (must)

The field is produced by calling `identifierOf()` in `dpm/src/projection/naming.js` rather than by re-deriving the numbering rule, so what a skill prints, what a projection filename embeds and what a `{{ref:<id>}}` marker resolves to cannot disagree.

- For every document in a fixture corpus, the `reference` a tool returns equals the identifier embedded in that document's `pathOf` filename. `[integration]`
- must NOT — The expected value must not be recomputed by calling `identifierOf` in the check. An assertion comparing the wrapper's answer against the function the wrapper calls has two outcomes that produce the same observed value, and it passes forever. `[integration]`
- control — The fixture contains a `coverage_matrix` under an epic under a spec, so a derivation taking the document's own `sequence` rather than its epic's produces a different answer and the comparison fails. Without that row the two derivations agree and the criterion above verifies nothing. `[integration]`

### FR3 (must)

A document whose identifier cannot be derived — no root-numbered ancestor, `numbering = 'none'`, or a parentage cycle — comes back with the field empty and the call still succeeds. A list never fails because one row among its rows cannot be named.

- A `numbering = 'none'` document, and a child-numbered document with no root-numbered ancestor, each come back with `reference` set to null and the call returns normally. `[integration]`
- must NOT — A list containing one unnameable document among nameable ones must not lose rows or raise. Every row comes back, and only the unnameable one carries null. `[integration]`

### FR4 (must)

`dpm/shared/skill-conventions.md` gains a convention governing what a skill says to a person: name a document by its reference and title, never by its id; ids are for tool arguments and foreign keys. It sits beside Cross-References rather than inside it, because one governs what is written to the database and the other what is said to a person.

- `dpm/shared/skill-conventions.md` carries a section governing what a skill says to a person, distinct from Cross-References, stating both the reference-and-title rule and what a skill does when the reference is null. `[integration]`

### FR5 (must)

The *Recommended next steps* table in `dpm/skills/status/SKILL.md` recommends every command by reference rather than by id — the four rows that interpolate `{epic id}`, `{spec id}` and `{brief id}`.

- No row of the status skill's *Recommended next steps* table interpolates a document id into a command. `[integration]`

### FR6 (must)

Every dpm skill that names a document in its conversational output names it by reference and title. The status table is the visible symptom; the sweep is across the whole skill corpus.

- No skill file in the tree contains a placeholder interpolating a document id into a user-facing command or sentence. The corpus is enumerated by `everySkill()` reading the tree, never by a written list, so a skill added later is covered on the day it lands. `[integration]`
- control — The pattern the check uses, run against the status skill as it stands before this work, finds its four existing occurrences. A pattern that matches nothing passes against a corpus that still leaks, and nothing in the criterion above would say so. `[integration]`

### FR7 (must)

The seven skills whose argument contract reads *names a document id* — architect, brief, do, epics, review, retro and spec — accept a human reference as well as a ULID, so a command a skill recommends is a command the receiving skill runs.

- Each of the seven skills' Input section states that a human reference is accepted alongside a ULID, and names `resolve_reference` — which the existing binding then holds to being a tool that exists. `[integration]`
- must NOT — The seven must not be swept from the tree. They are a fixed set this spec chose, so a skill added later is not silently in scope and its absence from the list is a decision rather than an oversight. `[integration]`

### FR8 (must)

A reference a user supplies resolves to exactly one document. An unresolvable reference, and one that matches more than one document, are each refused with a message naming what was looked for — never resolved to a best guess.

- `resolve_reference` given a reference matching exactly one document returns that document's row. `[integration]`
- A reference matching no document is refused, and the refusal message contains the reference that was looked for. `[integration]`
- must NOT — A reference matching both an epic and its coverage matrix, called with no `kind`, must not return either one. It is refused as ambiguous. `[integration]`
- The same reference called with `kind: 'epic'` returns the epic. `[integration]`
- control — The fixture holds a colliding pair — an epic and its coverage matrix — so the ambiguous path is reachable. Against a fixture with one epic and no matrix the ambiguity never fires and the two criteria above pass by never being exercised. `[integration]`

### FR9 (must)

Resolution costs one tool call, not a listing of every document in the project matched inside the skill's own run.

- Resolution issues a bounded number of statements against the database, and the count does not grow with the number of documents the project holds — measured against two corpora of different sizes. `[integration]`

### FR10 (should)

A refusal under FR8 names the candidates it did find, so a mistyped reference is corrected from the refusal itself rather than from a second command.

- The refusal for an unresolvable reference names the references that do exist for that kind, so a mistyped one is corrected from the message. `[integration]`

### FR11 (could)

Non-document rows — acceptance criteria, observations, coverage rows — carry a reference naming them by their parent and their position, so a skill citing one can say what it is rather than printing its id.

### FR12 (wont) — out_of_scope

The identifier scheme itself changes shape — the zero-padding, the separator, or a kind prefix inside the identifier. `identifierOf()` is the authority and this work reads it rather than revising it.

### FR13 (wont) — out_of_scope

Ids stop being returned. They remain the tool argument and the foreign key; the reference is added beside them and never in place of them, so every existing caller keeps working and the risk is what a new field costs rather than what a changed one breaks.

### FR14 (wont) — out_of_scope

A skill resolves a reference by reading the markdown projection. FR25 of the founding spec forbids parsing prose, and a resolver reading a generated filename would reintroduce exactly that.

### FR15 (wont) — deferred

`search` results carry a reference. Its rows are FTS hits — `entity`, `entity_id`, an excerpt and a score — rather than document rows, so a skill that wants to name a hit reads the row it points at. Deferred rather than ruled out.

### FR16 (must)

A prose value carrying a bare ULID that names a live `document` row is refused at the tool boundary. The refusal names the column and offers the `{{ref:<id>}}` form, so the bad prose never enters the database rather than being found in it later.

- `create_document_section` with a body containing a live document's bare ULID is refused, and the message names the column and shows the `{{ref:<id>}}` form. `[integration]`
- must NOT — The same ULID written correctly as `{{ref:<id>}}` in the same body must not be refused. A check that cannot tell the marker from the bare id refuses the only correct way to write the reference. `[integration]`
- Every prose-bearing write tool is covered, with the prose columns enumerated from the classification in `dpm/tests/support/prose-columns.js` rather than from a list of tool names — so a prose column added by a later migration is covered without an edit here. `[integration]`

### FR17 (must)

Nothing `/dpm:publish` writes into `docs/` contains a bare ULID naming a live document. This follows from FR16 rather than being enforced a second time at render, and it is stated separately because it is the outcome a reader observes.

- Publishing a fixture corpus produces no file under `docs/` containing a ULID that names a live document. `[integration]`

### FR18 (must)

The convention of FR4 covers stored prose as well as terminal output. A document named inside a body, a plan, a decision or an observation is written `{{ref:<id>}}` — never as a raw id, and never as a typed-out number, which the existing Cross-References section already forbids for its own reason.

- The convention section states the stored-prose rule — a document named inside a body is written `{{ref:<id>}}` — as well as the rule for what a skill says to a person. `[integration]`

### FR19 (must)

The refusal of FR16 exempts the columns where a ULID is the correct content: any column carrying a foreign key, and `session.state`, which is a skill-defined blob dpm does not interpret and never renders. A ULID naming something that is not a document — a session id quoted in an observation — is also left alone, because it has no marker form and refusing it would reject prose with no correct alternative.

- A foreign-key column accepts a live document's ULID: `create_dependency` with `source_document_id` set to one is not refused. `[integration]`
- `update_session` with a `state` blob containing a live document's ULID is not refused. The blob is skill-defined, dpm does not interpret it, and nothing renders it. `[integration]`
- A body containing a well-formed ULID that names no document — a session id quoted in an observation — is accepted. It has no marker form, so refusing it would reject prose with no correct alternative. `[integration]`
- control — A check without these exemptions refuses the foreign-key case — a sweep of every TEXT column against this project's own database flagged 390 of them. The three criteria above are what stop the refusal rejecting correct content, and without the control they read as defensive padding rather than as the finding they are. `[integration]`

## Non-Functional Requirements

### NFR1 (must)

Computing the reference costs a bounded number of database queries per tool call rather than one per returned row. A fifty-row list must not become fifty-one round trips to the database.

- The statement count for a fifty-row list is the same against a ten-document corpus and a two-hundred-document one. `[integration]`

### NFR2 (must)

No runtime dependency is added. `dpm/package.json` declares `"dependencies": {}` and `"devDependencies": {}`, and this work leaves both empty.

- `dpm/package.json` has empty `dependencies` and empty `devDependencies`. `[unit]`

### NFR3 (must)

A reference printed in a skill's output can be typed back verbatim as that skill's argument — no transformation, case-folding, quoting or escaping between what a person reads and what they type.

- A reference read from any tool's output is accepted verbatim by `resolve_reference` and returns the document it came from — a round trip over every document in the fixture corpus, with no transformation applied in between. `[integration]`

### NFR4 (must)

Every existing test that asserts an exact returned column set is enumerated before work starts, and each is either updated deliberately or shown not to be affected. Retro 02 recorded that adding a table to this schema cost five registrations where the plan predicted one; a field on every tool output has the same shape of hidden cost.

- Every test asserting a returned document row by deep-equality against a literal is enumerated from the suite source, and the resulting list is empty. Such an assertion breaks on any additive field, which is what makes it the shape worth finding rather than a style preference. `[unit]`

## Environmental Requirements

### ENVR1 (must)

Node.js 22.5.0 or later on the development machine. `node:sqlite` and `node:test` are both built-ins at that floor, and `REQUIRED_NODE` in `dpm/src/server/node-floor.js` already names it.

### ENVR2 (must)

The test runner is `node --test`, invoked as `npm test` from `dpm/`. No external test runner is installed or expected.

### ENVR3 (must)

A git checkout of this repository with `dpm/src` and `dpm/skills` in the working tree, and `.git/hooks/pre-commit` symlinked to `dpm/hooks/pre-commit` in that same tree rather than to a release in the plugin cache.

### ENVR4 (must)

Test data is a planning database built by the suite's own fixtures — `dpm/tests/support/planning-database.js` — rather than this project's `.dpm/dpm.db`, which must not be read or written by any test.

### ENVR5 (must)

A writable scratch directory the suite can publish a fixture corpus into, so FR17's check renders a real tree rather than inspecting the renderer's return value. Recorded here rather than at Step 6d because Step 3a is the single capture site; it was found by reconciling the tags against the constraints, which is what that step is for.

## Environmental Restrictions

### ENVX1 (must)

No npm package may need installing to run the suite. `node --test` and `node:sqlite` are the whole toolchain, and a criterion that could only be checked with an added package is one that must be re-tagged rather than one that justifies the package.

### ENVX2 (must)

No CI job may be required to verify any criterion. This repository has no `.github/workflows`, and adding one is not part of this work.

### ENVX3 (must)

The plugin cache must not need to be writable, and no criterion may be verifiable only after reinstalling the plugin.

### ENVX4 (must)

No schema migration. A migration would push a project's `.dpm/dpm.db` past the installed release's target and serve that project read-only until the plugin is reinstalled; the reference is computed from columns that already exist, so the file set under `dpm/src/schema/` is unchanged by this work.

### ENVX5 (must)

The markdown projection must not need to have been published. A reference is derived from rows, so a tool call answers correctly against a database whose `docs/` tree has never been written.

## Architecture Decisions

### 03-01 — Where a document row acquires its human reference

**Decision status**: accepted  

The reference is attached by `defineTool`'s handler wrapper in `dpm/src/tools/convention.js`, beside `withoutBody`, to any tool that declares it returns document rows — one site that a tool cannot skip, using `identifiers(db)`'s single query per call rather than a lookup per row.

#### The `defineTool` handler wrapper — chosen

One site, and one a tool cannot skip: `defineTool` already wraps every handler and post-processes its return value, which is where `withoutBody` applies the summary/body split, and it already understands both shapes a dpm tool returns — a single row and a `{items: [...]}` page. A tool that returns document rows therefore acquires the field by construction rather than by remembering to. The cost is a database handle and the identifier map reaching the wrapper, which it does not take today: registration has to hand them in.

| Axis | Assessment |
| --- | --- |
| complexity | Adds a database handle and a declaration to `defineTool`, which today takes neither — the wrapper stops being purely a function of the descriptor. |
| reach | Every registered tool, present and future, by construction — a document-returning tool cannot be built without passing through it. |
| reversibility | High — the field is additive and computed, so removing it is deleting one branch of one wrapper with no stored data left behind. |

#### In `selectPage` and each read handler

Follows the query, which is where the rows are. But `selectPage` covers the list tools only — every `read_*` would need the same code separately, and a read tool added later could simply omit it with nothing reporting the omission. The seam would be as many sites as there are read tools.

| Axis | Assessment |
| --- | --- |
| complexity | `selectPage` already holds the handle, so the list half is nearly free; the read half is the same code repeated per handler. |
| reach | Lists get it from one place; every read tool needs its own copy, and a read tool added later can silently omit it. |

#### In `documentTools` and `documentLists`

Explicit and local to the two factories that build document-kind tools. Two sites rather than one, and it scopes the answer to document *kinds* rather than to anything that returns a document row — a cross tool handing back a document would not get one.

| Axis | Assessment |
| --- | --- |
| complexity | Two sites, both already holding the handle; the simplest change to make and the easiest for a later tool to sit outside. |
| reach | Document kinds only. Anything else returning a document row — a cross tool, a future factory — is outside it. |

#### A SQL view or a generated column

Not expressible. The identifier is a recursive walk to the nearest root-numbered ancestor with a kind-specific step — a `coverage_matrix` takes its epic's sequence rather than its own — and it would also be a schema change, which ENVX4 rules out.

| Axis | Assessment |
| --- | --- |
| feasibility | Not expressible — a recursive ancestry walk with a kind-specific step, and a schema change ENVX4 forbids. |

### 03-02 — What the reference field carries, and where the kind lives

**Decision status**: accepted  

The field carries the bare identifier — `reference: "01-01"` — and the kind stays the column the row already has, so a reference can be typed back verbatim as an argument and nothing downstream has to split a composite string.

#### `reference: "01-01"`, kind stays a column — chosen

The bare identifier is what a person types back, unchanged, as a skill argument — NFR3 is satisfied by construction rather than by a rule about quoting. The kind is already on every document row, so a skill rendering "epic 01-01" composes it from two fields it holds, and a skill needing the number alone does not parse anything.

| Axis | Assessment |
| --- | --- |
| round-trip | Exact — what is printed is what is typed back, with nothing between. |
| uniqueness | Not unique on its own — an epic and its coverage matrix share an identifier by design — so the kind has to accompany it at resolution time. AD3 carries that. |

#### `reference: "epic 01-01"`

Reads better in a sentence and carries the kind that the identifier alone does not disambiguate. But it cannot be typed back as one argument, and every consumer wanting the number parses it out — which is the twenty-three-way re-derivation this spec exists to remove, arriving back at the other end of the call.

| Axis | Assessment |
| --- | --- |
| round-trip | Broken — a two-word value is not one argument, so something has to split it back apart before it can be used. |
| uniqueness | Unique — the kind is what separates an epic from its coverage matrix, and it is carried in the value. |

#### Both — `reference` and `qualified_reference`

Serves both readers and records one fact twice. The two disagree the first time either is edited, which is the rule Cross-References already states about a marker beside a foreign key.

| Axis | Assessment |
| --- | --- |
| consistency | Two spellings of one fact; they disagree the first time either is edited. |

### 03-03 — How a reference a user typed becomes a document id

**Decision status**: accepted  

A new `resolve_reference` tool takes the reference and an optional `kind` and returns the one matching document row, refusing both the unresolvable and the ambiguous by naming what was looked for — one call, and the epic/coverage-matrix collision addressable by kind rather than guessed at.

#### A `resolve_reference` tool — chosen

One call, which is FR9 directly. Not-found and ambiguous are both refusals naming what was looked for, which is the convention `readById` already sets for an absent row. The optional `kind` is what makes the identifier scheme's own collision addressable — an epic and its coverage matrix share `47-03` by design, and `/dpm:do` resolving with `kind: 'epic'` cannot be handed the matrix. Costs one tool registration and the accompanying conformance and parity entries.

| Axis | Assessment |
| --- | --- |
| ambiguity handling | Explicit — the optional `kind` narrows, and an ambiguous match with no kind is a refusal naming the candidates rather than a guess. |
| cost | One tool registration plus its conformance and parity entries — the registration cost Retro 02 recorded as being under-predicted. |

#### A `reference` filter on each `list_*`

No new tool, and the kind comes free from the tool's own name. But the reference is computed rather than stored, so the filter cannot be a `WHERE` clause: it has to run after the rows are built and before `LIMIT`, which means `selectPage` fetching unbounded rows and paging them in memory. That is a change to the file NFR1's bound lives in, made in order to add a lookup.

| Axis | Assessment |
| --- | --- |
| ambiguity handling | Implicit — the tool name supplies the kind, so a caller cannot ask the ambiguous question and cannot be told it was ambiguous. |
| cost | No new tool, and a change to `selectPage` — the one file whose whole purpose is the bound NFR1 states. |

#### The skill lists and matches in its own run

Needs no server change at all, and fails FR9 by construction — a listing per resolution. It also puts the epic/coverage-matrix collision into every skill that resolves, which is the same distributed rule the tool-layer fix exists to avoid.

| Axis | Assessment |
| --- | --- |
| ambiguity handling | Distributed — each of twenty-three skills decides for itself, so the collision is handled differently depending on which one was run. |
| cost | Nothing at the server and a listing per resolution at every call site — the cost moves rather than going away. |

### 03-04 — What the field holds for a document that cannot be named

**Decision status**: accepted  

The field is `null` and the call succeeds, so an unnameable document is distinguishable from a tool that never computed a reference, and no sentinel string can reach a person looking like an identifier.

#### `null`, and the call succeeds — chosen

The key is present on every document row, so a null says "this document cannot be named" and is distinguishable from a tool that never computed a reference at all. It matches what `identifiers(db)` already does — a document whose identifier cannot be derived is omitted from the map rather than raised on, because `numbering = 'none'` is a legitimate row. The convention then says what a skill does with it: name the document by kind and title, and say the reference is unavailable.

| Axis | Assessment |
| --- | --- |
| diagnosability | An unnameable document and an unwired tool are two different observations. |

#### The field is absent from the row

Smaller payload, and indistinguishable from a tool that does not attach references — so a skill cannot tell an unnameable document from an unwired tool, and the failure it would report is the wrong one.

| Axis | Assessment |
| --- | --- |
| diagnosability | The two collapse into one observation, and a skill reporting on it reports the wrong cause. |

#### A sentinel string

Always a string, so no consumer has to handle a null. And it gets printed: a magic value in a display field reaches a person looking like an identifier, which is a worse outcome than an absent one because it will be believed.

| Axis | Assessment |
| --- | --- |
| diagnosability | Distinguishable in principle and printed in practice — it reaches a person looking like an identifier, so it is believed rather than noticed. |

### 03-05 — Where a bare ULID in stored prose is caught

**Decision status**: accepted  

A prose value carrying a bare ULID that names a live document is refused at the tool boundary, so it never enters the database — with foreign-key columns and `session.state` exempt because a ULID is the correct content there, and a ULID naming a non-document left alone because it has no marker form.

#### Refuse at the write — chosen

The bad prose never enters the database, so there is no corpus to sweep afterwards and no window in which a reader can meet a ULID in a rendered document. It is also where FR3 already puts rejection — at the tool boundary, with a message naming what was wrong — so the refusal reads like every other refusal a caller gets rather than like a new kind of failure. The cost is a check on every prose write, and the need for the exemptions below, which are what stop it refusing correct content.

| Axis | Assessment |
| --- | --- |
| existing corpus | Unswept — a refusal at the write says nothing about prose already stored. This project's database was scanned and is clean, so nothing is owed here; another project's may not be. |
| false positives | Real and enumerated: a naive sweep flagged 390 foreign-key columns on this project's own database. The exemptions are what make the check usable, and they are found rather than assumed. |
| where the failure lands | On the author, at the moment of the mistake, with the correct form in the message. |

#### Refuse at the render

Symmetrical with what `resolve` already does for an unresolvable marker, and nothing bad reaches `docs/`. But by then the prose is stored, so the failure arrives at the person publishing rather than at the person who wrote it, and every publish is blocked until a body someone else authored is edited. A check that fires far from the mistake is one that costs the wrong person.

| Axis | Assessment |
| --- | --- |
| existing corpus | Swept by construction — every render reads every body, so nothing already stored escapes. That is also why it blocks. |
| where the failure lands | On whoever publishes, in prose someone else wrote, with the write long finished. |

#### Report only — a register entry and the pre-commit guard

The cheapest to build, and it fits beside register entry 13, which already sweeps every TEXT column for dangling markers. It refuses nothing, so the leak reaches a reader and stays there until somebody runs the check — which is the state this spec was written from.

| Axis | Assessment |
| --- | --- |
| existing corpus | Swept, and reported rather than fixed — which is what register entry 13 already does for its own invariant. |
| where the failure lands | Nowhere until someone asks — and on the reader of the published document in the meantime. |
