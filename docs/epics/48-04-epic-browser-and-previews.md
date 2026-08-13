# Three-Column Browser and Previews

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Date**: 2026-08-13  
**Status**: Pending  
**Blocked by**: 48-03  
**Retro applied**: 42 · Criteria gaps · Applied — FR4's "colour carrying state" is satisfied by a single style applied to every row; Story 1 asserts that distinct states render distinctly, from the rendered row rather than from the mapping table.  
**Retro applied**: 42 · Criteria gaps · Applied — FR7's story-scoping criterion is green on a fixture whose epic holds one story; Story 2's third criterion names the fixture where a wrong scope would be visible.  
**Retro applied**: 42 · Patterns worth reusing · Applied — NFR3's timing criteria are driven by a fixture server that delays its handshake, not by a delay or a hook inside the board's own code; a production seam added to make a test possible is a seam a call site can trip over.  
**Retro applied**: 42 · Scope surprises · Applied — FR1's directory picker arrives here rather than in 48-02, because the affordance needs an app to open in; recorded in both epics so neither reads as full coverage of FR1 alone.

The board a user actually looks at: Projects → Epics → Stories in Miller columns, a preview beneath the
column in focus, colour carrying the state 48-03 derives, and none of it waiting on a server to start.

## The three-column browser
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR4, ENV7

**Acceptance Criteria**:

- Projects, Epics and Stories columns render, and focus moves between them with ← / → [feature]
- The highlighted row's preview panel renders beneath its column [feature]
- Each derived state maps to a distinct style, asserted from the rendered row rather than from the mapping table, and no two states share one [feature]
- Feature-level tests drive the TUI through Textual's `run_test()` pilot [feature]

### The app shell and Miller-column layout
**Task**: 1.1  
**Description**: Three columns, with the preview panel beneath the Epics and Stories columns per FR4. Forked from `cpm/tools/board`'s view module per AD2 — the layout and focus helpers transfer, the content behind them does not.  
**Status**: Pending

### Focus movement and selection propagation
**Task**: 1.2  
**Description**: ← / → between columns, and a selection in one column driving the contents of the next. The case worth care is a selection that becomes invalid — an epic that vanishes from a refreshed list while its stories are on screen.  
**Status**: Pending

### State to style
**Task**: 1.3  
**Description**: One style per derived state, from 48-03's enumeration rather than a parallel list. Distinctness is the criterion: a mapping where blocked and in-progress resolve to the same colour satisfies "colour carries state" and tells the user nothing.  
**Status**: Pending

### The `run_test()` harness
**Task**: 1.4  
**Description**: ENV7's pilot harness, established once here and used by every `[feature]` criterion in this epic and in 48-05 and 48-07.  
**Status**: Pending

### Write tests for Story 1
**Task**: 1.5  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[feature]`. The style criterion is asserted from the rendered row's classes, and the distinctness half by comparing the full state-to-style map for collisions.  
**Status**: Pending

---

## Previews from rows
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR7

**Acceptance Criteria**:

- Preview text for an epic, spec or retro equals what the read tool returned for it [integration]
- A story's preview renders that story's own acceptance criteria and tasks, not the whole epic [integration]
- A story whose epic has several stories previews only the selected one, asserted against a fixture where another story's criteria would be visible if the scope were wrong [integration]
- must NOT open a projected `.md` file to build any preview [unit]

### Epic, spec and retro previews
**Task**: 2.1  
**Description**: `read_*` with `include_body`, and `preview_document_kind`. The `include_body` argument is the one to get right — a read without it returns the row and no prose, and the preview renders empty rather than failing.  
**Status**: Pending

### The story preview from its own rows
**Task**: 2.2  
**Description**: That story's acceptance criteria and tasks as rows, scoped to the story. Not the epic's body, and not the epic's whole criterion set filtered client-side — the scoping belongs in the call.  
**Status**: Pending

### Write tests for Story 2
**Task**: 2.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The fixture epic holds at least three stories with distinguishable criteria, so an unscoped preview is visibly wrong rather than coincidentally right.  
**Status**: Pending

---

## Off the UI thread
**Story**: 3  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: NFR3

**Acceptance Criteria**:

- The Projects column renders before any spawned server has completed its handshake [feature]
- Over ten registered projects the Projects column renders without waiting on server startup [feature]
- must NOT block the UI thread on a server spawn or a tool call [feature]

### Spawn and read as workers
**Task**: 3.1  
**Description**: Spawning and reading happen off the UI thread, with results applied back on it. The registry is on disk and needs no server, which is why the Projects column can render first at all.  
**Status**: Pending

### A pending state per row while a read is in flight
**Task**: 3.2  
**Description**: The visible consequence of the above, and the thing that distinguishes "not loaded yet" from "no epics". Without it, a board that is working correctly looks like a board reporting an empty project.  
**Status**: Pending

### Write tests for Story 3
**Task**: 3.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[feature]`. Driven by a fixture server that delays its handshake — a fixture the test controls, not a delay or hook added to the board's own code.  
**Status**: Pending

---

## Command palette
**Story**: 4  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR18

**Acceptance Criteria**:

- `Ctrl+P` opens the palette directly on the board's own actions [feature]
- The palette lists the board's actions and not Textual's default system commands [feature]

### The command provider
**Task**: 4.1  
**Description**: The board's own actions — register, remove, refresh, launch, attach, copy, search.  
**Status**: Pending

### Bind `Ctrl+P` to open on it directly
**Task**: 4.2  
**Description**: "Directly" is the requirement: opening the palette on Textual's default command set and making the user filter down to the board's actions is the behaviour FR18 exists to replace.  
**Status**: Pending

### Write tests for Story 4
**Task**: 4.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[feature]`. The second criterion is the one that fails on a default palette, which is what an unconfigured provider gives.  
**Status**: Pending

---

## Register a project from inside the TUI
**Story**: 5  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR1

**Acceptance Criteria**:

- A directory picker reached from the board registers a project, and the new project appears in the Projects column without a restart [feature]
- The picker refuses a directory that is not a dpm project with the same message the CLI gives [feature]

### The picker screen
**Task**: 5.1  
**Description**: FR1's second affordance. Reached from the palette and from a key binding, so the capability is discoverable rather than only bindable.  
**Status**: Pending

### Register and refresh the column in place
**Task**: 5.2  
**Description**: "Without a restart" is the criterion. A registration that lands in the file and not in the view is the failure mode, and it looks like the picker not working.  
**Status**: Pending

### Write tests for Story 5
**Task**: 5.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[feature]`. The shared refusal message is asserted against 48-02's CLI message rather than restated, so the two cannot drift into two different explanations of the same problem.  
**Status**: Pending

---

## Notes

**Step 3c — integration testing story: skipped.** The seams this epic crosses are already covered
end-to-end elsewhere: Board ↔ MCP server by 48-02's Story 6 and again by Story 2's preview criteria
against the real tools, and Contract ↔ consumers by 48-03's Stories 4 and 5. What remains here is the
view over state that already exists, and the five stories are parallel features of one app rather than
components that must interoperate. The one genuine cross-story risk — a failure in one project's read
taking the whole board down — is NFR2's, and it is verified in 48-06 where the failure states are built.

**FR1 is covered only across two epics.** The CLI affordance is 48-02 Story 1's third criterion; the
directory picker is Story 5 here. Neither epic covers the requirement alone, and both matrices say so.

**Story 1's third criterion is added.** FR4 requires "colour carrying state" and its criteria assert that
columns and previews render. A stylesheet applying one class to every row satisfies both. The added
criterion asserts distinctness from the rendered rows, and compares the whole state-to-style map for
collisions — the enumeration coming from 48-03's derived state set, so a state added later has no style
by default and fails rather than silently sharing one.

**Story 2's third criterion is added.** FR7's "not the whole epic" is unfalsifiable against an epic with
one story, which is what a minimal fixture has. Naming the fixture in the criterion is what makes the
scoping assertion mean something.

**NFR3's criteria are driven from a fixture, not a seam.** A delay or an injection point added to the
board so a test can observe pre-handshake rendering would be production code that exists for the test,
and a call site could then trip over it. The delay lives in a fixture server the test spawns instead.
