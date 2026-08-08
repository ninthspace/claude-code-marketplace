# Coverage Matrix: Parity and Search

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Epic**: docs/epics/47-05-epic-parity-and-search.md  
**Date**: 2026-08-08

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR10 | Every table in `sqlite_master` has a create tool, asserted by comparing the live table list against the registered tool list — neither side is a hand-kept enumeration | Every table in `sqlite_master` has a create tool, asserted by comparing the live table list against the registered tool list — neither side is a hand-kept enumeration | Story 1 | `[integration]` | |
| 2 | FR10 | The list and every vocabulary in it are taken from a real CPM project's `docs/` tree, not from CPM's documentation — the two disagree. | An observation written against a story and later gathered into a retro retains its `story_id`, so its origin is still queryable | Story 1 | `[unit]` | |
| 3 | FR24 | seeded with defaults, extensible per project | A project-added category is usable without a schema migration | Story 2 | `[integration]` | |
| 4 | FR24 | An item may carry more than one category where the work genuinely spans two. | An observation carrying two categories round-trips, and appears under both in the projection | Story 2 | `[integration]` | |
| 5 | FR24 | retirable without invalidating rows that already use them | Retiring a test approach and a dependency kind leaves rows using them intact, as it does for a taxonomy row | Story 2 | `[unit]` | |
| 6 | FR24 (must NOT) | Observation categories, finding categories, audit dimensions, severities and test approaches are rows referenced by foreign key — seeded with defaults, extensible per project, and retirable | must NOT — any vocabulary is seeded and extensible but cannot be retired | Story 2 | `[unit]` | |
| 7 | FR9 | Artefact bodies *and* the hand-written text on their child rows — requirements, story criteria, retro observations, review findings — are indexed with FTS5 | A section written with a ULID id is retrievable by `MATCH`, and `document_fts` declares no `content=` option — the external-content form rejects a non-integer rowid at write time | Story 3 | `[unit]` | |
| 8 | FR9 | The FTS index is maintained by the three triggers above, not by a reindex step. | Updating and deleting a section both leave the index consistent with the table, asserted by comparing a `MATCH` against a `LIKE` scan | Story 3 | `[unit]` | |
| 9 | FR9 | a search that covers only sections misses the majority of what a user would look for | Every table `entry_fts` indexes has all three triggers — insert, update-of-the-indexed-column, delete — enumerated from `sqlite_schema`, with no table indexed by fewer than three | Story 4 | `[unit]` | |
| 10 | FR9 | A search index that lags a write returns a result set missing the thing just written, and reports success | Updating and deleting a row of each indexed child table leaves `entry_fts` consistent with that table, asserted by the same `MATCH`-versus-`LIKE` comparison | Story 4 | `[unit]` | |
| 11 | FR9 | are indexed with FTS5 | A search returns ranked results, and the index reflects a write made in the same session | Story 5 | `[integration]` | |
| 12 | FR9 | "which requirement mentioned the coverage helpers" returns nothing while the answer sits in `requirement.text` | A term appearing only in a `requirement.text` is found by an unscoped search, and the hit names the entity and row id | Story 5 | `[integration]` | |
| 13 | FR9 (must NOT) | Artefact bodies *and* the hand-written text on their child rows | must NOT — a search covers `document_section` only, so text held on a child row is unreachable while the tool reports success | Story 5 | `[integration]` | |
| 14 | FR9 | `entry_fts` covers those, tagged by entity, so `entity:requirement AND helpers` scopes a search and an untagged query spans everything | Creating one row of every indexed entity type through its own tool, then searching a term common to all of them, returns a hit from every one — the tools and the triggers are built by different stories and nothing else runs them together | Story 6 | `[integration]` | |
| 15 | FR24 | retirement stops rows arriving as well as preserving those that have | A create tool refuses a vocabulary row retired through Story 2's retire tool, and the refusal names the retired item | Story 6 | `[integration]` | |
| 16 | FR10 | Every artefact type CPM produces is modelled from the outset | Every table, enumerated from `sqlite_master` and populated through its own tool, appears in the projection its kind renders into — or inside its parent's, for the ten that produce no file and for the ADR | Story 6 | `[integration]` | |
| 17 | NFR7 (must NOT) | Every piece of state is reachable through a read tool without SQL | must NOT — a search returns a hit whose entity and row id do not resolve to a live row through that entity's read tool | Story 6 | `[integration]` | |
| 18 | FR24 | A persona added to a project's `agent` table is offered by `party`, `review` and `consult` with no plugin change and no file edit | A persona added to a project's `agent` table is offered by `party`, `review` and `consult` with no plugin change and no file edit | Story 2 | `[integration]` | |

**Mapping notes.**

**Row 1 is the whole of FR10's create-tool obligation, and it is checked here for the last
time.** Epic 47-03's row 5 covered the seven spine types; this row covers the enumeration in
full, so FR10's create-tool half is satisfied by this epic's matrix alone. The template half
remains Epic 47-04's. FR10 is therefore covered across three matrices and complete in none —
self-hosting register entry 1, in the requirement that gave the register its first entry.

**Rows 1 and 16 no longer carry a count, as of the pivot of 2026-08-08.** Both stated a total
that had already been recounted once — from twenty-two to twenty-three, when FR27 added
`milestone` as an eighth child table — and the total was wrong in its noun besides: twenty-three
is the number of *tables*, while FR10 enumerates twenty-two *types*, the two differing because
`brief` is two document kinds, `coverage` is both a kind and a child table, and the verification
record is deliberately no table at all. Both rows now assert against `sqlite_master` instead, so
adding a table changes no text here. Row 1's Spec Text remains identical to its criterion. Both
rows are unverified under the verification rule.

The arithmetic itself, and the phrase to quote if a count is ever needed again, live in one place:
the Data Model's *"thirteen document kinds, eight child tables and two standalone tables"*.

**Row 4's spec text is FR24's own multi-category clause, not the criterion's projection
half.** The projection is where the two categories are observed; FR24 is what requires there
to be two. The dependency this creates on Epic 47-04 is declared in the epic's `Blocked by`.

**Rows 3 and 5 are the tool-side counterparts of Epic 47-01's rows 10–12.** 47-01 proved the
constraints hold; these prove they are reachable without SQL, which is the half of FR24 that
says "extensible per project". Neither substitutes for the other.

**Row 16 is the parity closure and is deliberately duplicated in intent with row 1.** Row 1
asserts every type has a tool; row 16 asserts every type reaches a template. Together they
are FR10. Separately, each passes in a world where the other fails — which is the reason
Story 6 exists.

**Row 17 maps to NFR7, not FR9.** The clause is about reachability through read tools, which
is NFR7's subject; FR9 would be satisfied by a search that finds text and hands back an
unusable identifier.

**Story 7's two criteria have no rows here, and that is declared rather than missed.** It is
the "Address review findings" story, which records repairs to this breakdown rather than
obligations drawn from the spec, so its criteria have no requirement to bind to. The
both-directions set comparison should expect exactly those two as an unmatched remainder.

**Row 18 was added by the second pivot of 2026-08-08**, which made the agent roster an FR24
vocabulary. It is the criterion that justifies the table: CPM's `agents/roster.yaml` can only
be overridden by replacing the whole file, so a project wanting one extra persona must fork
all ten and maintain the fork — which is why the override has never been used, while
appending to the shipped roster has. FR24's seeded-extensible-retirable semantics express
append directly. The row sits here rather than in 47-08 because it asserts the *tool* half;
`party` reading the table is 47-08 row 17.
