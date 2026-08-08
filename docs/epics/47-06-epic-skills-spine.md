# Skills: Spine

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Date**: 2026-08-08  
**Status**: Pending  
**Blocked by**: Epic 47-03-epic-server-and-spine-tools, Epic 47-04-epic-projection-guard-and-merge, Epic 47-05-epic-parity-and-search

Milestone M4 (AD6). Three of FR25's twenty-two skills, one story each. These three are the
pipeline CPM's handoff problem lives in — each recovers the previous stage's work by parsing
what it wrote — so they convert first and their sequence is what the integration story runs.

The mechanical checks FR25 and FR3 impose on every file — no glob, no filename pattern under
`docs/`, no number-allocation procedure, no progress-file lifecycle, no SQL keyword — sweep
all three files in one test and therefore sit on Story 4. What stays per-skill is what that
skill writes, and the recovery clause, because what a skill would wrongly read back differs
by skill.

## Convert `spec` [plan]
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR5, FR11

**Acceptance Criteria**:

- A spec run writes the document, its requirements with `class` and MoSCoW band, and its acceptance-criteria coverage rows, all through create tools [feature]
- The facilitation survives: the run still gates on scope, still produces a testing strategy, and still refuses an untestable criterion [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Rewrite the spec write path as tool calls — document, requirements, criteria, coverage
**Task**: 1.1  
**Description**: Everything the skill currently composes into markdown becomes typed arguments. `class` and MoSCoW band stop being label prefixes the skill formats and become columns it passes.  
**Status**: Pending

### Replace numbering, filename construction and the progress file with tool calls and a session row
**Task**: 1.2  
**Description**: Four of FR25's six subtractions land in this one task. The number comes from the allocation tool, the filename does not exist, and the progress file becomes an `UPDATE`.  
**Status**: Pending

### Write tests for Convert `spec`
**Task**: 1.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `epics` [plan]
**Story**: 2  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR23, FR21

**Acceptance Criteria**:

- An epics run allocates every epic number through the allocation tool, and writes stories, tasks, criteria and coverage rows through create tools [feature]
- The coverage matrix is a projection of `coverage` rows, not a file the skill writes — the skill emits no markdown table [integration]
- The facilitation survives: the run still gates on the epic grouping before writing any story, still carries every must-NOT the source spec states into a story criterion, and still refuses to attach a criterion it cannot trace to spec text [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Rewrite epic, story, task, criterion and coverage writes as tool calls
**Task**: 2.1  
**Description**: Every epic number and child sequence comes from the allocation tool, so the two-level numbering the skill implements today by globbing both `docs/epics/` and `docs/archive/epics/` disappears entirely.  
**Status**: Pending

### Remove the coverage-matrix writer
**Task**: 2.2  
**Description**: The matrix is a projection of `coverage` rows. The skill writes rows and stops emitting a markdown table, which is also what makes its verification marks decay under FR21 instead of persisting as text.  
**Status**: Pending

### Replace the progress file with a session row
**Task**: 2.3  
**Description**: Including the session-suffixed filename and the compaction-recovery read. Adoption on resume is an `UPDATE`.  
**Status**: Pending

### Write tests for Convert `epics`
**Task**: 2.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `do`
**Story**: 3  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR22, FR21, FR11

**Acceptance Criteria**:

- A do run updates story and task status through update tools, and records verification by writing `coverage.verified_at`, so FR21's triggers govern it rather than the skill's own prose rule [feature]
- Story readiness comes from the dependency query, not from reading `**Blocked by**` lines [integration]
- The facilitation survives: the retro-consumption gate still requires a disposition per observation rather than one blanket acknowledgement, and a story's verification gate still fires only once every implementation task under it is complete [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Rewrite status and verification updates as tool calls
**Task**: 3.1  
**Description**: `status` and `status_note` are separate columns, so the lead-token-plus-tail parse the skill performs today has nothing left to parse. Verification is `coverage.verified_at`, written not asserted.  
**Status**: Pending

### Replace `**Blocked by**` parsing with the readiness query
**Task**: 3.2  
**Description**: Readiness becomes a query over `dependency` — the FR22 capability the schema was built for, and the one place `do` currently derives a graph from prose.  
**Status**: Pending

### Replace the progress file and its compact-summary companion with a session row
**Task**: 3.3  
**Description**: The companion file exists only because a markdown store cannot hold state that survives compaction; a row can.  
**Status**: Pending

### Write tests for Convert `do`
**Task**: 3.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Verify cross-story integration for Skills: spine
**Story**: 4  
**Status**: Pending  
**Blocked by**: Story 1, Story 2, Story 3  
**Satisfies**: FR25, FR3, FR11

**Acceptance Criteria**:

- None of the three skill files contains a filename pattern under `docs/`, a glob, a number-allocation procedure, or a progress-file lifecycle [unit]
- None of the three skill files contains a SQL keyword or a `sqlite3` invocation [unit]
- A spec written by `spec`, broken down by `epics`, and executed by `do` produces one connected graph — requirements to criteria to coverage to stories — with no step reading what the previous one wrote from disk [feature]
- must NOT — a skill's progress state is a file rather than a `session` row [integration]

### Write integration tests for Skills: spine
**Task**: 4.1  
**Description**: The third criterion is what earns this story. Converting each skill individually proves each writes through tools; only running them in sequence proves none still reads back. The grep criteria are cheap and belong here rather than restated on each story — one sweep covers the epic's whole corpus.  
**Status**: Pending

---

## Notes

### Self-hosting register — entries in this epic's scope

The register lives in Epic 47-01's Notes. **Entry 3** is in scope: `spec` is converted here,
and spec 47 itself carries ten inline ADs with Decision / Rejected / Consequence structure
that degrade to `document_section` prose because `adr` is a document kind. A converted
`spec` skill therefore cannot write the spec it was converted from without loss. Not
actionable here — it needs a schema change.

**Entry 1** is also visible: the converted `epics` skill writes `coverage` rows and nothing
else, so the partial-coverage state this very breakdown produced for FR10 would be
unrepresentable in the tool the breakdown was made with.

### Requirements only partially covered by this epic

**FR25** — three of twenty-two skills. The remaining nineteen are Epics 47-07, 47-08 and
47-09; FR25's corpus-wide criteria — that all twenty-two exist, that none exists which FR25
does not name, and that every reachable pipeline stage has one — can only be asserted once
the last skill lands, and are Epic 47-09's.

**FR3** — the skill-corpus half, for three files. The tool-boundary half is Epic 47-03.
