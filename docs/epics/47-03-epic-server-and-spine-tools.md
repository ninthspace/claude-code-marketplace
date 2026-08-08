# Server and Spine Tools

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Date**: 2026-08-08  
**Status**: Pending  
**Blocked by**: Epic 47-01-epic-substrate

Milestone M2 (AD6), tool half. The MCP server, the typed tools for the seven spine entity
types, the tool-surface properties (bounded reads, discoverable names, reachability), session
state, and the AD10 conformance test that keeps the tool schemas and the DDL in step.

The projection — M2's other half — is Epic 47-04.

## Start the server on a stated Node floor with clean stdout
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: NFR1, NFR2, NFR3, AD5

**Acceptance Criteria**:

- A clean clone starts the server with no compilation step [target]
- The server refuses to start below the Node floor with a message naming the required version [integration]
- A full session's stdout parses as well-formed JSON-RPC with no stray output [integration]

### Write the MCP stdio server entry point with logging on stderr
**Task**: 1.1  
**Description**: Covers the JSON-RPC criterion — stdout belongs to the transport, so `NODE_NO_WARNINGS=1` and every log line goes to stderr. `node:sqlite`'s ExperimentalWarning is the specific case that motivated it.  
**Status**: Pending

### Enforce the >=22.5.0 Node floor with a message naming the required version
**Task**: 1.2  
**Description**: Refuse to start rather than fail on a missing module. Scoped to the floor check; the API-instability risk it contains is AD5's rationale, not this task's work.  
**Status**: Pending

### Write tests for Start the server on a stated Node floor with clean stdout
**Task**: 1.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. NFR1's criterion is `[target]` and is not self-assessable here — it needs a clean clone on a real host.  
**Status**: Pending

---

## Expose typed create, read and update tools for the spine [plan]
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR1, FR4, FR10

**Acceptance Criteria**:

- Creating each artefact type produces a row readable by its typed read tool [integration]
- The seven spine entity types — spec, requirement, story criterion, epic, story, task, coverage — each have create, read and update tools [integration]
- Every `requirement` and `acceptance_criterion` type distinction is readable from a column with `label` and `text` withheld [integration]
- must NOT — the `requirement` create tool accepts a class inferred from `label`, rather than requiring `class` as an argument [unit]

### Define the tool-schema conventions every entity tool follows
**Task**: 2.1  
**Description**: Argument shape, error envelope, and the rule that a column's `CHECK` set is the tool's enum. Produces the contract Stories 3–7 all assert against — deliberately first and separate, because AD10 exists precisely because this convention is maintained by hand.  
**Status**: Pending

### Implement create, read and update for spec, requirement and story criterion
**Task**: 2.2  
**Description**: The requirement tool takes `class` as a required argument and never infers one from `label` — covers the must-NOT and the label-withheld criterion.  
**Status**: Pending

### Implement create, read and update for epic, story, task and coverage
**Task**: 2.3  
**Description**: The coverage tool binds `(requirement_id, spec_fragment, story_criterion_id)`, which is the natural key — `position` is display order and no part of identity.  
**Status**: Pending

### Write tests for Expose typed create, read and update tools for the spine
**Task**: 2.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Expose the cross-cutting tools [plan]
**Story**: 3  
**Status**: Pending  
**Blocked by**: Story 2  
**Satisfies**: FR5, FR14, FR22

**Acceptance Criteria**:

- Allocating a number through its tool returns the value and never a success without one [unit]
- The link tool refuses an edge that would close a cycle over a `gates_work` kind, naming both ends [integration]
- The integrity tool is callable and reports every register entry it checks [integration]

### Wrap the number allocation from Epic 47-01 Story 3 as a tool
**Task**: 3.1  
**Description**: The allocation statement already exists and holds register #5 by construction; this task is only its tool boundary.  
**Status**: Pending

### Implement the link tool with the gates_work cycle refusal
**Task**: 3.2  
**Description**: Names both ends of the edge it rejects. Cycle detection is reachability, which is why register #1 exists rather than a constraint.  
**Status**: Pending

### Wrap the integrity check from Epic 47-01 Story 6 as a tool
**Task**: 3.3  
**Description**: The checks exist; this exposes them so a corrupted state is diagnosable without SQL, which is the whole of FR14's "without SQL" clause.  
**Status**: Pending

### Write tests for Expose the cross-cutting tools
**Task**: 3.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Bound reads by default and let callers raise the bound
**Story**: 4  
**Status**: Pending  
**Blocked by**: Story 2  
**Satisfies**: FR13

**Acceptance Criteria**:

- For the same artefact, a read without an explicit body request returns strictly fewer bytes than one with it — asserted as a comparison between two responses, not against a fixed number [integration]
- Every list-returning tool declares a `limit` with a default, and a caller that raises it receives the larger result [unit]
- must NOT — a query tool returns an unbounded row set when no limit is supplied, or refuses a limit the caller raised [unit]

### Add summary and body read modes to every read tool
**Task**: 4.1  
**Description**: The summary is the default; the body is requested explicitly. There is deliberately no byte ceiling — a cap the caller cannot lift is a boundary on what dpm can be asked for.  
**Status**: Pending

### Add a defaulted, raisable limit to every list-returning tool
**Task**: 4.2  
**Description**: Covers both the default and the raise. A refused raise fails the must-NOT as squarely as an unbounded default does.  
**Status**: Pending

### Write tests for Bound reads by default and let callers raise the bound
**Task**: 4.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Name tools discoverably and keep every table reachable
**Story**: 5  
**Status**: Pending  
**Blocked by**: Story 2, Story 3  
**Satisfies**: NFR5, NFR7

**Acceptance Criteria**:

- Every exported tool name matches `dpm_[a-z_]{6,}`, and every part after the verb is a table name, a column name, or a seeded `document_kind.kind` value — checked against the live schema, not against a hand-kept word list [unit]
- Every table in `sqlite_master` is reachable through at least one read tool, asserted by comparing the table list against the tools' declared coverage [integration]
- A database whose schema version is ahead of the server still answers read tools rather than refusing to start [integration]

### Assert every tool name against the live schema's tables, columns and seeded kinds
**Task**: 5.1  
**Description**: No hand-kept word list — a list of permitted abbreviations would be one more hand-maintained vocabulary of exactly the kind this spec removes.  
**Status**: Pending

### Assert every table in sqlite_master is reachable through a read tool
**Task**: 5.2  
**Description**: Compares the table list against the tools' declared coverage. This is the assertion that makes NFR7's promise checkable rather than aspirational.  
**Status**: Pending

### Answer read tools when the database schema version is ahead of the server
**Task**: 5.3  
**Description**: NFR7's lockout case — degrade to reads rather than refusing to start, so a user is never shut out of their own planning history by a version skew.  
**Status**: Pending

### Write tests for Name tools discoverably and keep every table reachable
**Task**: 5.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Replace the progress-file subsystem with a session row
**Story**: 6  
**Status**: Pending  
**Blocked by**: Story 2  
**Satisfies**: FR11

**Acceptance Criteria**:

- A session row survives simulated resume under a new session id, and stale rows are selected by age [integration]

### Implement session create, adopt-on-resume and staleness-by-age
**Task**: 6.1  
**Description**: Adoption is an `UPDATE SET superseded_by`; staleness is a `WHERE updated_at < …` clause. Replaces session-suffixed filenames, hook injection and compact-summary companions outright.  
**Status**: Pending

### Write tests for Replace the progress-file subsystem with a session row
**Task**: 6.2  
**Description**: Write automated tests covering the story's acceptance criterion tagged `[integration]`.  
**Status**: Pending

---

## Assert tool schemas conform to the live schema
**Story**: 7  
**Status**: Pending  
**Blocked by**: Story 2, Story 3, Story 4, Story 6  
**Satisfies**: AD10

**Acceptance Criteria**:

- Every enum a tool declares is equal to the `CHECK` set on its column, in both directions, read from the live schema [unit]
- Every `NOT NULL` column without a default is a required argument on its create tool, and every foreign key on the table has a corresponding argument [unit]
- must NOT — the conformance test compares tool schemas against a second copy of the DDL rather than against `PRAGMA` output [unit]

### Read the correspondence out of PRAGMA table_info and PRAGMA foreign_key_list
**Task**: 7.1  
**Description**: Never from a second copy of the DDL — a copy is the drift this seam exists to catch, relocated into the test.  
**Status**: Pending

### Assert enum equality in both directions, and required-argument parity
**Task**: 7.2  
**Description**: A tool offering a value the `CHECK` rejects is validation in the wrong layer; a `CHECK` admitting a value no tool offers is a column the pipeline cannot reach. Both fail.  
**Status**: Pending

### Write tests for Assert tool schemas conform to the live schema
**Task**: 7.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`.  
**Status**: Pending

---

## Verify cross-story integration for Server and spine tools
**Story**: 8  
**Status**: Pending  
**Blocked by**: Story 1, Story 2, Story 3, Story 4, Story 5, Story 6, Story 7  
**Satisfies**: FR3, AD10

**Acceptance Criteria**:

- A spec created through its tool, then an epic under it, then a story, then a coverage row binding a requirement fragment to a story criterion, all succeed in sequence and read back consistently through their read tools [integration]
- A create call whose enum value the column's `CHECK` rejects fails at the tool boundary, and no row is written [integration]
- The conformance test passes against the running server's actual registered tool list, not a fixture of it [integration]
- A session created, resumed under a new id, and read back returns the state written before the resume [integration]
- Every tool the server registers appears in the reachability assertion, and every table appears in at least one tool's declared coverage [integration]
- must NOT — a tool accepts an argument the schema rejects, so validation happens at neither layer [integration]

### Write integration tests for Server and spine tools
**Task**: 8.1  
**Description**: Drives the full spine chain through the tool surface rather than the database, which is the only way the tool boundary is exercised at all. The third criterion is the load-bearing one — AD10's test could pass against a fixture tool list and prove nothing about what the server exposes.  
**Status**: Pending

---

## Address review findings
**Story**: 9  
**Status**: Complete — applied by `/cpm:pivot` on 2026-08-08 from review 05  
**Blocked by**: —

**Acceptance Criteria**:

- Each critical and warning finding from review 05 scoped to this epic has been addressed
- Existing acceptance criteria on other stories continue to pass

### Fix: Story 5 and Story 8 state reachability requirements that cannot both pass
**Task**: 9.1  
**Description**: [critical] Story 5 requires that "every table in `sqlite_master` is reachable through **at least one** read tool"; Story 8 requires that "every table appears in **exactly one** tool's declared coverage". `document` is read by the read tool of every one of the thirteen kinds, and `taxonomy` by `finding`, `observation` and `audit_finding` — so exactly-one is not merely stricter, it is unsatisfiable against this schema. NFR7 (spec:1383) says at-least-one, so Story 8 also invents an obligation the spec does not carry. Reconcile Story 8's clause to the spec's wording, and update the matching coverage row. Neither criterion is wrong read alone, which is the reading retro 33 recorded as the one that cannot find this.  
**Status**: Complete — Story 8 and matrix row 26 now read "at least one", matching NFR7

### Fix: this epic says "the remaining fifteen"; Epic 47-05 says "sixteen"
**Task**: 9.2  
**Description**: [warning] This epic states "47-05 the remaining fifteen types" and "The remaining fifteen are Epic 47-05", both unqualified. Epic 47-05 titles its Story 1 "Give the remaining **sixteen** entity types create, read and update tools". The two reconcile only via this epic's own FR11 placement note — `session` has its tool here but is counted in 47-05's accounting — which is a derivation held in a third location and stated in neither. 47-05 already routes around the count by reading the enumeration from the live schema; either adopt that qualification here or state the derivation where the number appears. Retro 33's "count in code, quote in prose", returning for a third session.  
**Status**: Complete — both statements now read "sixteen", with the `session` derivation stated inline

---

## Notes

### Self-hosting register — entries in this epic's scope

The register lives in Epic 47-01's Notes. No entry is closable here; all four need spec
changes. Entry 1 is however **most visible in this epic**: FR10 now has partial coverage in
three separate epics (47-01 seeding, 47-03 spine create tools, 47-05 the remaining sixteen
types), and nothing in dpm as specified could distinguish that from FR10 being fully covered.
It is the clearest live instance of the entry in the whole breakdown.

### Placement decisions worth recording

**NFR1 is tagged `[target]`, not `[manual]`.** "A clean clone starts the server with no
compilation step" is mechanically checkable, but only against a real clone on a real host — a
verdict from a machine that already has the dependencies is worth nothing. Story 1 therefore
cannot be fully closed by an autonomous run, which is a property of the requirement rather
than a gap in the story.

**FR11 sits here rather than in Epic 47-05.** `session` is one of the parity enumeration's
two standalone tables, so on AD6's accounting it is M3 work. But session lifecycle is a
server concern that every skill needs from the first conversion, so the tool lives here.
47-05 retains it in the parity enumeration's accounting only.

### Requirements only partially covered by this epic

- **FR3** — the tool-boundary half (rows 21–22). Its other clause, "No skill contains SQL,  
  and no skill constructs a query", is a property of the skill corpus and belongs to Epics  
  47-06 through 47-09.
- **FR10** — the seven spine entity types only. The remaining **sixteen** are Epic 47-05's —  
  the Data Model's *thirteen document kinds, eight child tables and two standalone tables*,  
  less this epic's seven. One of the sixteen, `session`, has its table  
  and its tool built *here* under FR11 and is counted there only for the enumeration's  
  arithmetic, so 47-05 writes fifteen tools against sixteen accounted types. The derivation  
  is stated here because the number alone cannot be reconciled from either epic on its own:  
  until review 05 this note said "fifteen" while 47-05 said "sixteen", and the note that made  
  them consistent lived in a third place. Prefer 47-05 Story 1's enumeration over either  
  number — it reads the set from the live schema and fails on any member without a tool.
- **FR4**, **FR5**, **FR14**, **FR22** — the tool-boundary half of each; the schema half is  
  Epic 47-01.
