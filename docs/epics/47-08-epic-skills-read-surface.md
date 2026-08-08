# Skills: Read Surface

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Date**: 2026-08-08  
**Status**: Pending  
**Blocked by**: Epic 47-04-epic-projection-guard-and-merge, Epic 47-05-epic-parity-and-search

Milestone M4 (AD6). Eight of FR25's twenty-two skills, one story each. These consume rather
than produce, so the criteria shift: what matters is that each reads through a query instead
of a scan, and returns bounded results.

Six carry two criteria; `status` and `artifact` carry three, because each holds a specific
defect the conversion exists to remove — marker-grepping in one, the index-and-backlinks
pair that can disagree in the other. FR25's and FR3's mechanical checks sweep all eight
files on Story 9, per the pattern approved on 2026-08-08.

## Convert `status`
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR22

**Acceptance Criteria**:

- A status run reports across specs, epics, stories and tasks from queries, with no directory walk and no file read [feature]
- Retro-waived and archived items are excluded by `WHERE` clauses over columns, not by grepping for markers [integration]
- The facilitation survives: an unrecognised status is still flagged rather than guessed and still counts as not-done, and the optional artifact is still never produced unless asked for and separately confirmed [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Rewrite the roll-up as queries over specs, epics, stories and tasks
**Task**: 1.1  
**Description**: `status` is the skill that most obviously wants a database — its entire output is an aggregate that markdown forces it to assemble by walking a tree.  
**Status**: Pending

### Replace marker greps with column predicates
**Task**: 1.2  
**Description**: Waived, archived and superseded are all `WHERE` clauses. `archived_at` is separate from `status` because a document is archived *and* complete, so neither predicate hides the other.  
**Status**: Pending

### Write tests for Convert `status`
**Task**: 1.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `inspect`
**Story**: 2  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR13

**Acceptance Criteria**:

- An inspect run characterises a change against the planning graph through read tools, and its every list-returning call carries the tool's default `limit` [feature]
- The facilitation survives: the run still derives its axis before using it, still refuses to describe a suite as passing without having run it, and still reports what it did not read [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Rewrite characterisation against read tools, supplying the declared `limit` at every list call
**Task**: 2.1  
**Description**: The bound is a default that costs nothing to override, so the skill raises it where it needs more rather than working around its absence.  
**Status**: Pending

### Write tests for Convert `inspect`
**Task**: 2.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `present`
**Story**: 3  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR2

**Acceptance Criteria**:

- A present run resolves its sources through the artifact join rather than by reading an index file, and a source that does not exist is a foreign-key failure rather than a broken link [feature]
- The facilitation survives: the run still gates audience, then format, then draft in turn, and a regeneration over an existing artifact still offers update-in-place rather than silently minting a second one [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Resolve sources through the artifact join
**Task**: 3.1  
**Description**: A missing source fails at write time instead of being discovered by a reader following a dead link.  
**Status**: Pending

### Write tests for Convert `present`
**Task**: 3.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `library`
**Story**: 4  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, AD7

**Acceptance Criteria**:

- A library run reads `library_document` and `library_scope` rows, so the Library Check's scope filter is a `WHERE` clause rather than a front-matter parse [integration]
- The facilitation survives: a suggested scope is still presented for adjustment rather than applied, and the derived front-matter is still confirmed before the document is written [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Read `library_document` and `library_scope` rows
**Task**: 4.1  
**Description**: Scope is a set of rows, so a document scoped to three stages is three rows rather than a YAML array every consumer parses independently.  
**Status**: Pending

### Write tests for Convert `library`
**Task**: 4.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `artifact` [plan]
**Story**: 5  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR1

**Acceptance Criteria**:

- An artifact run writes one `artifact_document` row per link; the index file and the in-document backlinks are both projections of it, so the two cannot disagree [integration]
- Publishing updates the artifact row's URL in place, and a republish to the same file path resolves to the same row [feature]
- The facilitation survives: the run still refuses to invent any of an entry's facts, and a proposed name is still confirmed rather than assigned [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Write one `artifact_document` row per link
**Task**: 5.1  
**Description**: One relationship, one row.  
**Status**: Pending

### Make the index file and the in-document backlinks projections of that row
**Task**: 5.2  
**Description**: This closes the defect the spec's Problem Summary leads with — a bidirectional link kept honest by hand, where updating one side and forgetting the other produces no diagnostic. One join table has nowhere to hold a disagreement.  
**Status**: Pending

### Update the artifact row's URL in place on publish
**Task**: 5.3  
**Description**: A republish to the same file path resolves to the same row, which is what makes "keep the same link" a lookup rather than a convention the caller remembers.  
**Status**: Pending

### Write tests for Convert `artifact`
**Task**: 5.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `templates`
**Story**: 6  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR6

**Acceptance Criteria**:

- A templates run renders its previews from 47-04's projection templates, so a template and its preview cannot drift [integration]
- The facilitation survives: both `list` and `preview` still complete in a single response with no gate, which is the one skill here whose facilitation is the absence of one [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Render previews from the projection templates rather than from a second copy
**Task**: 6.1  
**Description**: A preview generated from its own copy of the format is the artifact-index-and-backlinks defect again, one directory over.  
**Status**: Pending

### Write tests for Convert `templates`
**Task**: 6.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `consult`
**Story**: 7  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR9

**Acceptance Criteria**:

- A consult run retrieves prior context through the search tool rather than by reading files, and a term held only on a child row is reachable [feature]
- The facilitation survives: an inferred agent is still confirmed before the consultation begins, the voice is still rendered from that agent's stored traits without inventing beyond them, and the exit is still offered rather than assumed [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Retrieve prior context through the search tool, covering both indexes
**Task**: 7.1  
**Description**: The child-row half is the one that matters here — most of what a consult would look for is a requirement's or a finding's text, not a section body.  
**Status**: Pending

### Write tests for Convert `consult`
**Task**: 7.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `party`
**Story**: 8  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR24

**Acceptance Criteria**:

- A party run loads its roster from the `agent` table and reads the artifact under discussion through read tools, with no YAML parse and no roster file on disk [feature]
- The facilitation survives: agents are still selected from the topic rather than fixed, each voice is still rendered from that agent's stored traits alone, and the run still ends in a direction of travel rather than a transcript [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Load the roster from the `agent` table and the artifact through read tools
**Task**: 8.1  
**Description**: The lightest conversion in the corpus — `party` writes nothing and its facilitation is untouched. Until the pivot of 2026-08-08 "its roster" named no table: personas lived in `agents/roster.yaml` and `review_agent.agent` was free text, so this skill would have kept a YAML parse in a corpus whose whole thesis is that nothing parses files. The roster is now an FR24 vocabulary (Epic 47-01 Story 2), which is also what makes a project-added persona reach this skill without a plugin change.  
**Status**: Pending

### Write tests for Convert `party`
**Task**: 8.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Verify cross-story integration for Skills: read surface
**Story**: 9  
**Status**: Pending  
**Blocked by**: Story 1, Story 2, Story 3, Story 4, Story 5, Story 6, Story 7, Story 8  
**Satisfies**: FR25, FR3, FR13, NFR7

**Acceptance Criteria**:

- None of the eight skill files contains a filename pattern under `docs/`, a glob, a number-allocation procedure, or a progress-file lifecycle [unit]
- None of the eight skill files contains a SQL keyword or a `sqlite3` invocation [unit]
- Every list-returning call any of the eight skills makes supplies or inherits a `limit`, asserted over the call sites [unit]
- Deleting the entire `docs/` tree and regenerating it leaves all eight skills producing identical output, since none of them reads it [feature]
- must NOT — a read skill reports an empty result where the data exists, because it queried one index or one table where the state spans two [integration]

### Write integration tests for Skills: read surface
**Task**: 9.1  
**Description**: The fourth criterion is the strongest available statement that the read surface is genuinely converted, and it is cheap to run: `docs/` is a projection, so deleting and regenerating it must be a no-op for a skill that only reads. Any skill still parsing a generated file fails it. The final clause guards the failure this epic is most exposed to — a query that returns nothing reads as "nothing to report" and raises no error.  
**Status**: Pending

---

## Notes

### Self-hosting register — entries in this epic's scope

The register lives in Epic 47-01's Notes. **Entry 5** is in scope: `present` and `artifact`
both resolve references between documents, and body-prose references — the ones FR8's merge
tool claims to rewrite — are exactly what neither can resolve, because they are text and not
rows. This epic does not close it and is not blocked by it; it is where the consequence first
becomes visible to a user.

No other entry is actionable here.

### Requirements only partially covered by this epic

**FR25** — eight of twenty-two skills. **FR3** — the skill-corpus half, for eight files.
Both complete only in Epic 47-09.

**FR13** — the call-site half. FR13's tool-side criteria, that every list tool declares a
`limit` with a raisable default, are Epic 47-03's. This epic asserts that the skills use it.
