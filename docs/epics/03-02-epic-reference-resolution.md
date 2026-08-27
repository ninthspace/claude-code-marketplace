# Resolving a reference back to a document

**Number**: 03-02  
**Source spec**: 03  
**Status**: complete  

## The tool name and the naming sweep

`resolve_reference` collides with `dpm/tests/naming.test.js` as that file stood before this epic, and the collision was found by reading the sweeps before writing the tool rather than by running the suite afterwards.

**What the collision is.** The sweep builds a vocabulary from the live schema — table names, every column of every table, and every seeded `document_kind` — and requires that any tool whose declared `table` is a live table have its name's subject in that set. `resolve_reference` declares `table: 'document'`, which is live, and `reference` is in no part of the vocabulary: epic 03-01 added the reference as a *returned field* and deliberately added no column for it (ENVX4, and the tests that hold it). The check was run directly against a fresh in-memory schema to confirm it rather than inferred from reading the code.

**Why the rule and not the name.** NFR5 is in the CPM-era corpus at `docs/cpm/specifications/47-spec-dpm-sqlite-persistence.md`, which DPM cannot see and which this project keeps as read-only history, so there is no artefact for `/dpm:pivot` to operate on. More to the point, the requirement's own text is narrower than the test: *"The rule is that every underscore-separated part is a whole word, which a test can check without maintaining a list of permitted abbreviations."* `reference` is a whole word, and `resolve_reference` satisfies NFR5 as written. The schema-vocabulary lookup is `naming.test.js`'s own stricter implementation of that rule, and it rests on an assumption that held until epic 03-01 and does not hold now: that every field a tool returns is a column of some table. `reference` is on every document row a caller sees and is exactly the kind of searchable word NFR5 exists to require — it is simply not in `PRAGMA table_info`.

So the vocabulary is under-reading, and widening it repairs a check that has gone stale against its own purpose. The two alternatives were considered and rejected. Renaming to `resolve_document` would have touched twelve rows across spec 03, its ADR, two of its sections and epic 03-03, to work around a rule the tool already satisfies. Adding a fourth entry to the sweep's schema-spanning exemption — beside `check_integrity`, `publish` and `search` — would have been the wrong reason recorded permanently: those three are exempt because they are named for no table, and this one declares the table it reads.

**What changes.** `naming.test.js`'s vocabulary admits the fields document-row tools return alongside the columns they read. The change is to a test and to nothing else; no requirement moves, and no other document is edited.

The decision was put to the user as a gate with all three options and the reasoning above, and the answer was to widen the vocabulary. The pivot the answer named turned out to have no target, which is recorded here rather than resolved silently.

## Story 1 — `resolve_reference` returns the one document

**Status**: complete  
**Blocked by**: Story 2  

### Acceptance Criteria

- `resolve_reference` given a reference matching exactly one document returns that document's row. `[integration]`
- A reference matching both an epic and its coverage matrix, called with `kind: 'epic'`, returns the epic. `[integration]`
- Resolution issues a bounded number of statements against the database, and the count does not grow with the number of documents the project holds — measured against two corpora of different sizes. `[integration]`
- A reference read from any tool's output is accepted verbatim by `resolve_reference` and returns the document it came from — a round trip over every document in the fixture corpus, with no transformation applied in between. `[integration]`

### Task 1 — Define the `resolve_reference` tool contract

**Status**: complete  

Inputs are a reference and an optional `kind`; the return is a document row of the same shape every other read tool returns. Scope is the contract and its registration surface, not the lookup logic — that is task 2.

### Task 2 — Build the reverse lookup from `identifiers(db)`

**Status**: complete  

Reference to document ids, grouped so a collision is visible to the caller rather than silently collapsed to one. Reads the same map the reference field is computed from, which is what keeps the statement count bounded and independent of corpus size.

### Task 3 — Narrow a grouped match by `kind`

**Status**: complete  

Addresses the epic-and-coverage-matrix pair, which is the case `kind` exists for. Narrowing to one candidate only; what happens when it narrows to none or to several is Story 2.

### Task 4 — Write tests for `resolve_reference` returns the one document

**Status**: complete  

Covers the story's four criteria, all tagged `integration`: the single match, the `kind`-narrowed match, the bounded statement count across two corpus sizes, and the verbatim round trip over every document in the fixture corpus.

### Retro

- The registration cost of a new tool came to one sweep, and reading the five before writing anything is what found it — three days after retro 05 recorded that the same reading for an *output field* came to zero. `parity` checks that a declared table exists (`document` does), `parity-integration` and `conformance` both skip anything not named `create_`, and `prose-columns` classifies columns (none added). The one that bit was `naming.test.js`: NFR5's check builds a vocabulary from `PRAGMA table_info` and requires a tool named for a live table to have its subject in it, and `reference` is a field 03-01 derived rather than a column it stored. Running the sweep's own vocabulary builder against a fresh schema confirmed it before a line of the tool existed.

**The rule was right and its reading was one epic out of date, and telling those two apart is the whole finding.** NFR5's text is "every underscore-separated part is a whole word, which a test can check without maintaining a list of permitted abbreviations" — `reference` is a whole word, and `resolve_reference` satisfies the requirement as written. The schema-vocabulary lookup is the test's own stricter implementation, resting on an assumption that held until 03-01: that every field a tool returns is a column of something. Renaming the tool to `resolve_document` would have touched twelve rows across the spec, its ADR, two sections and epic 03-03 to work around a rule the tool already met; a fourth entry in the schema-spanning exemption would have recorded the wrong reason permanently, since the other three are exempt for being named after no table and this one declares the table it reads. Widening the vocabulary — from `REFERENCE_FIELD`, exported where the field is produced — was the only option that repaired something.

The approved resolution named `/dpm:pivot`, and the pivot had no target: NFR5 lives in `docs/cpm/specifications/47-spec-dpm-sqlite-persistence.md`, the parked CPM corpus DPM cannot see. Worth recording as a shape rather than an incident — **a rule this project still enforces can have its source outside anything DPM can edit**, so "pivot the document that is wrong" has a null case, and the honest answer is to change the code and write down why rather than to look for a document to amend.

Two controls, both run by removing the implementation. Emptying the vocabulary widening failed the naming sweep naming exactly `resolve_reference`. On the resolver, collapsing the grouped map (`found.length = 1`) failed three of four criteria and left the bound green — correctly, since the bound test resolves references nothing collides with — and returning an empty map failed all four. The first is the more informative of the two: it says the grouping is load-bearing for the *resolving* criteria and not merely for Story 2's refusals, which is not what the task descriptions suggest.

## Story 2 — Refusing rather than guessing

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- A reference matching no document is refused, and the refusal message contains the reference that was looked for. `[integration]`
- must NOT — A reference matching both an epic and its coverage matrix, called with no `kind`, must not return either one. It is refused as ambiguous. `[integration]`
- control — The fixture holds a colliding pair — an epic and its coverage matrix — so the ambiguous path is reachable. Against a fixture with one epic and no matrix the ambiguity never fires and the two criteria above pass by never being exercised. `[integration]`
- The refusal for an unresolvable reference names the references that do exist for that kind, so a mistyped one is corrected from the message. `[integration]`

### Task 1 — Refuse an unresolvable reference, naming what was looked for

**Status**: complete  

The error path only; the resolving path is Story 1's. The message carries the reference that was supplied, so a reader knows which one failed.

### Task 2 — Refuse an ambiguous match rather than returning either candidate

**Status**: complete  

Addresses the must-not: neither candidate is returned and no preference between them is encoded. Returning the first, the newest or the epic over its matrix all satisfy a naive reading and all guess.

### Task 3 — Name the candidates that do exist for that kind in the refusal

**Status**: complete  

FR10, the one should-have in this epic. The refusal from task 1 is correct without it and useful with it, so it is separable if the epic runs long.

### Task 4 — Write tests for Refusing rather than guessing

**Status**: complete  

Covers the story's four criteria, all tagged `integration`, including the control that the fixture holds a colliding pair — without which the ambiguity never fires and the refusal tests pass by never being exercised.

### Retro

- The must-NOT control was run once per place a guess could live, and all three arms were caught by the same single test — which is the finding, because it is not what the retro lesson predicted. Arm 1 put a `[0]` on the candidate list by disabling the ambiguity refusal; arm 2 added a `localeCompare` tie-break by kind ahead of it; arm 3 collapsed the collision inside `documentsByIdentifier` so the resolver never saw two candidates at all. Each was planted and removed in turn from a scratchpad copy, never `git checkout`. All three failed the same assertion, and the reason they converge is structural rather than lucky: the refusal is the only place a second candidate can go, so every guess has to route through disabling it.

The fixture control earned its place separately and in the opposite direction. Under arm 3 the collision test still passed — correctly, because it reads both references from `read_epic` and `read_coverage_matrix` rather than from the map, and the pair really did still share `47-03`. Had the control been written against the map it would have gone green alongside the bug it exists to catch.

The refusal-lists-candidates work turned up a fixture constraint worth knowing: `KIND_PARENTS` gives a spec exactly two child-numbered kinds, `epic` and `adr`. `review` and `retro` are root-numbered even though a spec parents them, so a test needing a second document at `47-02` has to use the ADR. Two FOREIGN KEY failures found this before the seed file did.

## Dependencies

- blocks → 03-03

## Retro Applied

- 05 · codebase-discoveries · applied — Step 1 of Story 1 reads what each derived sweep actually reads before estimating — `parity`, `parity-integration`, `conformance`, `prose-columns`, `tool-surface` — rather than carrying 03-01's answer of "none" across. 03-01 added a returned field and touched no sweep; a tool is a different shape and the reading is short.
- 02 · complexity-underestimates · applied — This epic adds a *tool*, which is the case the five-registrations finding was actually about — `parity.test.js` and `parity-integration.test.js` both enumerate the tool surface, and `conformance` reads every tool's declarations. Unlike 03-01's output field, a new tool is visible to all of them. The registration cost is budgeted into Story 1's plan and checked before the tool is written, not after the suite reports it.
- 04 · criteria-gaps · applied — Story 1's criterion 3 bounds the statement count and says "measured against two corpora of different sizes" — which already avoids the shape this observation warns about, but only if the second corpus is built by the test rather than taken from the shared fixture. Epic 03-01's bound test built a 200-document corpus against a 10-document one for exactly this reason; the same construction is reused here rather than quantifying over whatever `fullCorpus` happens to hold.
- 05 · patterns-worth-reusing · applied — Story 1's criterion 4 — a reference from any tool's output round-trips through `resolve_reference` — is enumerated from the built registry by what the tools *return* (`documentRows`, which 03-01 declared), while `resolve_reference` itself is keyed off something else. The two must not read the same column, or a tool omitted from one is omitted from its own check. This is the same "declare one, check by another" rule, and 03-01 left the declaration in place ready for it.
- 05 · patterns-worth-reusing · applied — Story 2's criterion 3 is itself a `control` polarity row demanding the fixture hold a colliding epic/matrix pair. 03-01 Story 1 already built `matrixUnderEpic()`, which creates exactly that pair — an epic at sequence 3 with a coverage matrix beneath it, both deriving `47-03`. The mixture the criterion needs already exists and is checked before the ambiguity test is written, not assumed.
- 04 · testing-gaps · applied — Every control in this epic is run by removing the implementation and watching the test fail, never by reasoning about it — the file copied to the scratchpad first and copied back, never `git checkout`. Story 2's criterion 2 (ambiguity must not resolve to either candidate) is the one at risk: a resolver that simply never matched two rows would satisfy it while doing nothing, so the control has to make the ambiguous pair actually collide.
- 02 · testing-gaps · applied — Story 2's must-NOT — an ambiguous reference resolves to neither candidate — gets one control arm per place a guess could be written, not one per criterion. The rejected behaviour has at least three homes here: a `LIMIT 1` on the query, a `[0]` on the result array, and a tie-break by kind order or by `position`. The control has to reach each, so each is planted and removed in turn rather than argued away.
