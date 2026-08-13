# Failure Surface: Named States and Proven Non-Mutation

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Date**: 2026-08-13  
**Status**: Pending  
**Blocked by**: 48-01, 48-04  
**Retro applied**: 42 · Criteria gaps · Applied — FR11 names four states and asserts three, and nothing asserts that any two of them are distinguishable; Story 1's fifth criterion reconciles the rendered set against FR11's enumeration, because "a server that exits immediately" and "a Node below dpm's floor" are the same observable unless something separates them.  
**Retro applied**: 42 · Criteria gaps · Applied — FR10's must-NOT is a sweep over a verb set that could be empty; Story 3 derives the set from the difference between the server's full tool list and its read-only set, and fails when that difference is empty.  
**Retro applied**: 42 · Criteria gaps · Applied — FR10's non-mutation criterion names the database file, and FR10's own text says "no file under a registered project is written — `.dpm/` included"; Story 3 compares the whole tree, because a board that wrote `.dpm/dpm.sql` would pass the criterion as the spec states it.  
**Retro applied**: 42 · Patterns worth reusing · Applied — the failure states are decomposed before being rendered, exactly as the create-and-migrate seam was; three of the four have the same symptom (no data) and only a decomposition makes them separately remediable.

FR10 and FR11 are the two requirements a user notices only when something is wrong: observing a project
must leave it byte-identical, and a project the board cannot read must say so, by name, with its remedy,
without taking the other projects with it. The property FR10 asserts holds from 48-02's first line of
code; what this epic delivers is the proof, and the four states that make a failure legible.

## The four named per-project states
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR11, ENV2

**Acceptance Criteria**:

- A project with no `.dpm/dpm.db` renders a named state carrying its remedy [integration]
- A database whose schema is ahead of the server renders a distinct named state [integration]
- A server that exits immediately renders a third, distinct named state [integration]
- With a Node below dpm's floor, the executable's refusal is captured and rendered per FR11 [integration]
- The four states are distinct from one another, reconciled against FR11's enumeration so a state that collapses into another fails [unit]

### Classify each failure into its named state
**Task**: 1.1  
**Description**: The classification is the story. Three of the four arrive as the same symptom — a project with no data — and the inputs that separate them are different: an absent file, a `migrated.ahead` reply, a process that exits, and a refusal on stderr naming a version. 48-01's Story 2 is what makes the first of these arrive as a diagnostic rather than as a crash, which is why that epic is a blocker.  
**Status**: Pending

### The remedy per state
**Task**: 1.2  
**Description**: FR11 requires the state to carry its remedy, and the four remedies are unrelated: create a database, upgrade the plugin, read the server's stderr, upgrade Node. A state without its remedy is a slightly better error message.  
**Status**: Pending

### The four-way distinctness check
**Task**: 1.3  
**Description**: Reconciled against FR11's enumeration rather than asserted pairwise, so a fifth state added later is covered without an edit. The Node-floor and failed-to-start cases are the pair most likely to collapse: below the floor, the executable refuses and exits.  
**Status**: Pending

### Write tests for Story 1
**Task**: 1.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The Node-floor case needs a `PATH` the test controls with an old-enough Node, or a stub that reproduces the executable's refusal exactly — the assertion is on the rendered state, so the second is sound only if the refusal text is taken from dpm's own source rather than transcribed.  
**Status**: Pending

---

## One unreadable project never takes the board down
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: NFR2, FR11

**Acceptance Criteria**:

- With one project unreadable, every other registered project still renders its state [integration]
- must NOT let any of the three prevent the remaining projects from rendering [integration]
- Each of the four failure states is exercised in a mixed registry, not only the missing-database one [integration]

### Per-project error containment
**Task**: 2.1  
**Description**: A failure is contained to its own row, per NFR2. The containment boundary is the per-project read, and the case that escapes it is the one raised off the UI thread — a worker exception that is never awaited surfaces somewhere else entirely, or nowhere.  
**Status**: Pending

### Write tests for Story 2
**Task**: 2.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The registry holds a healthy project *and* each failing kind, and the assertion is that the healthy one renders its real state — not merely that the board did not crash.  
**Status**: Pending

---

## Proven non-mutation
**Story**: 3  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR10

**Acceptance Criteria**:

- After a full board session over a fixture project, the database file's hash, size and mtime are unchanged [integration]
- The project tree's whole file set and content hashes are unchanged, `.dpm/` included — not only the database [integration]
- must NOT call any tool whose name is a mutating verb, in any code path [unit]
- must NOT — the mutating-verb check passes over an empty verb set; the set is derived from the difference between the server's full `tools/list` and its read-only set [unit]

### The full-session non-mutation fixture
**Task**: 3.1  
**Description**: "A full board session" is the operative phrase: browse every column, open every preview kind, run the palette, trigger a search. A session that touched three screens proves nothing about the fourth.  
**Status**: Pending

### Whole-tree comparison
**Task**: 3.2  
**Description**: File set and content hashes across the project, not the database alone. FR10's text says "no file under a registered project is written — `.dpm/` included", and a board that regenerated `.dpm/dpm.sql` would pass the database-only assertion.  
**Status**: Pending

### The derived mutating-verb sweep, with its floor
**Task**: 3.3  
**Description**: The verb set comes from the difference between the server's full `tools/list` and its read-only set, so a mutating tool added to dpm later is swept without an edit here. The floor is what stops an empty difference reading as a clean sweep.  
**Status**: Pending

### Write tests for Story 3
**Task**: 3.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The floor is checked on a planted empty verb set, since once the derivation works the live surfaces cannot distinguish a working sweep from a vacuous one.  
**Status**: Pending

---

## A read-only filesystem is not a failure
**Story**: 4  
**Status**: Pending  
**Blocked by**: Story 1, Story 3  
**Satisfies**: ENVX3

**Acceptance Criteria**:

- A registered project on a read-only filesystem renders its state without error [integration]
- Its epics, stories, progress and previews render as they do for a writable project — the read-only filesystem changes nothing the user sees [integration]

### Write tests for Story 4
**Task**: 4.1  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Deliberately test-only: if this story needs production code, Story 3 or 48-01 is wrong, and finding that out is the point. The second criterion is the one that discriminates — "renders without error" is also true of a project rendered as a failure state.  
**Status**: Pending

---

## Notes

**Step 3c — integration testing story: skipped, because Story 2 is one.** NFR2's containment is inherently
cross-cutting and Story 2 exercises every failure kind from Story 1 in a registry beside a healthy project.
A further integration story would be the same test with more projects in it. The seams this epic touches —
Board ↔ MCP server, Server ↔ SQLite read-only — are covered by 48-02's Story 6 and 48-01's Story 1
respectively; nothing here re-verifies them.

**FR11 names four states and asserts three.** Its body enumerates a missing database, a schema ahead of the
server, a Node below the floor and a server that fails to start; its criteria cover the first, second and
fourth, with the Node-floor case appearing only as ENV2's criterion. Nothing in the spec asserts that any
two are distinguishable, and the Node-floor and failed-to-start cases are the same observable — below the
floor, the executable refuses and exits. Story 1's fifth criterion is what separates them.

**FR10's criterion names the database and its requirement names the tree.** "After a full board session the
database file's hash, size and mtime are unchanged" is silent about `.dpm/dpm.sql`, about the registry's
own writes landing in the wrong place, and about a stray lock file. FR10's text is not: "no file under a
registered project is written — `.dpm/` included". The whole-tree criterion is added rather than
substituted, so the spec's row stays verifiable as written.

**The mutating-verb sweep is derived, not listed.** A transcribed list of mutating verbs is correct on the
day it is written and silently narrows every time dpm gains a tool. Deriving it from the difference between
the full and read-only tool sets makes it grow by itself — and makes the floor necessary, since an empty
difference means the two sets are identical, which is a much larger problem reported as a pass.

**Story 4 is test-only by design.** ENVX3's server half is 48-01's Story 2 must-NOT; its board half needs no
new behaviour if the board genuinely writes nothing and the registry genuinely lives under XDG. Writing it
as a test-only story makes that claim falsifiable: if production code turns out to be required, something
upstream is writing where it should not be.

**FR10's property is maintained from 48-02 onward; only its proof is here.** No story in this epic makes the
board non-mutating — 48-02's Story 3 must-NOTs and 48-01's read-only mode do that. What is delivered here is
the evidence, which is why the epic is late in the order rather than early.
