# Coverage Matrix: Skills — Read Surface

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Epic**: docs/epics/47-08-epic-skills-read-surface.md  
**Date**: 2026-08-08

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR25 | each rewritten against the tool surface | A status run reports across specs, epics, stories and tasks from queries, with no directory walk and no file read | Story 1 | `[feature]` | |
| 2 | FR25 | no glob | Retro-waived and archived items are excluded by `WHERE` clauses over columns, not by grepping for markers | Story 1 | `[integration]` | |
| 3 | FR25 (must NOT) | no procedure that recovers an entity by reading what an earlier skill wrote | must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool | Story 1 | `[unit]` | |
| 4 | FR13 | every list-returning tool takes a `limit` with a default | An inspect run characterises a change against the planning graph through read tools, and its every list-returning call carries the tool's default `limit` | Story 2 | `[feature]` | |
| 5 | FR25 (must NOT) | no procedure that recovers an entity by reading what an earlier skill wrote | must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool | Story 2 | `[unit]` | |
| 6 | FR2 | an artifact link cannot point at a missing document | A present run resolves its sources through the artifact join rather than by reading an index file, and a source that does not exist is a foreign-key failure rather than a broken link | Story 3 | `[feature]` | |
| 7 | FR25 (must NOT) | no procedure that recovers an entity by reading what an earlier skill wrote | must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool | Story 3 | `[unit]` | |
| 8 | AD7 | the four kinds with structure to hold | A library run reads `library_document` and `library_scope` rows, so the Library Check's scope filter is a `WHERE` clause rather than a front-matter parse | Story 4 | `[integration]` | |
| 9 | FR25 (must NOT) | no procedure that recovers an entity by reading what an earlier skill wrote | must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool | Story 4 | `[unit]` | |
| 10 | FR1 | `cpm:artifact` maintains an index file *and* backlinks inside each source document — a bidirectional link kept honest by hand, where updating one side and forgetting the other produces no diagnostic | An artifact run writes one `artifact_document` row per link; the index file and the in-document backlinks are both projections of it, so the two cannot disagree | Story 5 | `[integration]` | |
| 11 | FR25 | Each of those is a tool call. | Publishing updates the artifact row's URL in place, and a republish to the same file path resolves to the same row | Story 5 | `[feature]` | |
| 12 | FR25 (must NOT) | no procedure that recovers an entity by reading what an earlier skill wrote | must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool | Story 5 | `[unit]` | |
| 13 | FR6 | The projection is a render, not a store (AD3). | A templates run renders its previews from 47-04's projection templates, so a template and its preview cannot drift | Story 6 | `[integration]` | |
| 14 | FR25 (must NOT) | no procedure that recovers an entity by reading what an earlier skill wrote | must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool | Story 6 | `[unit]` | |
| 15 | FR9 | a search that covers only sections misses the majority of what a user would look for | A consult run retrieves prior context through the search tool rather than by reading files, and a term held only on a child row is reachable | Story 7 | `[feature]` | |
| 16 | FR25 (must NOT) | no procedure that recovers an entity by reading what an earlier skill wrote | must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool | Story 7 | `[unit]` | |
| 17 | FR25 | each rewritten against the tool surface | A party run loads its roster and reads the artifact under discussion through read tools | Story 8 | `[feature]` | |
| 18 | FR25 (must NOT) | no procedure that recovers an entity by reading what an earlier skill wrote | must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool | Story 8 | `[unit]` | |
| 19 | FR25 | no filename construction, no glob, no number allocation, no markdown parsing, no progress-file lifecycle | None of the eight skill files contains a filename pattern under `docs/`, a glob, a number-allocation procedure, or a progress-file lifecycle | Story 9 | `[unit]` | |
| 20 | FR3 | Every dpm SKILL.md contains no SQL keyword and no `sqlite3` invocation | None of the eight skill files contains a SQL keyword or a `sqlite3` invocation | Story 9 | `[unit]` | |
| 21 | FR13 | The bound is a default that costs nothing to override, not a limit. | Every list-returning call any of the eight skills makes supplies or inherits a `limit`, asserted over the call sites | Story 9 | `[unit]` | |
| 22 | FR25 (must NOT) | no markdown parsing | Deleting the entire `docs/` tree and regenerating it leaves all eight skills producing identical output, since none of them reads it | Story 9 | `[feature]` | |
| 23 | NFR7 (must NOT) | Every piece of state is reachable through a read tool without SQL | must NOT — a read skill reports an empty result where the data exists, because it queried one index or one table where the state spans two | Story 9 | `[integration]` | |

**Mapping notes.**

**Rows 3, 5, 7, 9, 12, 14, 16 and 18 are the same clause against eight files**, for the
reason given in Epics 47-06 and 47-07: FR25's recovery clause is per-file.

**Row 10 maps to FR1, and its Spec Text is drawn from the Problem Summary rather than from
FR1's own sentence.** FR1 states the rule — every artefact type is a table, not a file parsed
at read time — and the Problem Summary states the specific defect this criterion removes.
The criterion is the only one in the breakdown that closes a defect the spec opens with, so
it is bound to that sentence.

**Row 22 is a proposed criterion, not a spec line.** Its Spec Text is FR25's "no markdown
parsing", which is what it enforces; the delete-and-regenerate method was written during
breakdown and accepted by Chris on 2026-08-08. It is worth its place because it is the only
criterion here that tests the whole subtraction behaviourally rather than by grep — a skill
can pass every grep and still hold a path it constructs at runtime.

**Row 23 maps to NFR7 and is proposed.** The failure it names — a query returning nothing,
read as "nothing to report", raising no error — is the false-pass shape NFR6 forbids
generally and NFR7 forbids for read reachability specifically. It is bound to NFR7 because
the fix is that the state be reachable, not merely that the failure be loud.

**Partial coverage to flag.** FR25 is covered here for eight of twenty-two skills, FR3 for
eight of twenty-two files; both complete in Epic 47-09. FR13's rows here are the call-site
half, its tool-side half being Epic 47-03's — so FR13 also reads as partially covered in two
matrices.
