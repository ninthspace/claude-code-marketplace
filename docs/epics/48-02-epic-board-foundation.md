# Board Foundation: Registry, MCP Client, Server Pool

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Date**: 2026-08-13  
**Status**: Pending  
**Blocked by**: 48-01  
**Retro applied**: 42 · Criteria gaps · Applied — Story 5's reconciliation carries a floor, because a derived declared set and a derived `tools/list` can both come back empty and read as full agreement; the absence of a mismatch is not evidence that the surfaces match.  
**Retro applied**: 42 · Codebase discoveries · Applied — spec 47's AD1–AD11 were read as this epic's architecture; the `capabilities: { tools: { listChanged: false } }` declaration is what makes Story 5's one-shot `tools/list` reconciliation sound rather than a snapshot of a moving target.  
**Retro applied**: 42 · Scope surprises · Applied — two of FR1's and FR3's criteria name affordances that cannot exist until 48-04 and 48-06; rather than deferring the requirements whole, the CLI half is delivered here and the split is recorded in Notes in both directions.

The board is an MCP client and nothing else: no SQL, no SQLite connection, no markdown parsing, no
`.dpm/dpm.sql`. This epic delivers the parts that make that true and testable — where projects are
remembered, how a server is found and spoken to, how one is pooled per project, and how the board
notices when the tool surface it depends on has moved underneath it.

## The project registry
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR1

**Acceptance Criteria**:

- Add, list and remove round-trip through a registry file located under `$XDG_CONFIG_HOME` [unit]
- A registered path that is no longer a directory is pruned on launch [unit]
- `board.py add <path>`, `list` and `remove <path>` reach all three operations from the CLI, and `add` refuses a path that is not a dpm project with a message naming what was missing [integration]
- must NOT write the registry anywhere outside the XDG config location [unit]

### The registry file and its XDG resolution
**Task**: 1.1  
**Description**: `$XDG_CONFIG_HOME` when set, its documented default when not. Written atomically — a truncated registry is a board that has forgotten every project, and the write happens on a path the user is not watching.  
**Status**: Pending

### Prune paths that are no longer directories
**Task**: 1.2  
**Description**: On launch, per FR1. Pruning is a write to the registry, which is one of the only two files this spec writes anywhere; it does not touch the project it forgets.  
**Status**: Pending

### The three CLI subcommands
**Task**: 1.3  
**Description**: `add`, `list`, `remove`. This is FR1's reachability half for everything except the TUI directory picker, which needs an app to live in and belongs to 48-04. `add`'s refusal names what was missing rather than reporting a generic failure, because the usual cause is a path that is a git repository but not a dpm project.  
**Status**: Pending

### Write tests for Story 1
**Task**: 1.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]` and `[integration]`. The must-NOT needs `$XDG_CONFIG_HOME` pointed at a temporary directory and an assertion that nothing appeared outside it — not merely that the expected file appeared inside it.  
**Status**: Pending

---

## A runnable script and a resolvable server
**Story**: 2  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: ENV1, ENV3, ENV4, ENVX2, ENVX4

**Acceptance Criteria**:

- `uv run --script board.py list` succeeds on a clean checkout with no prior install step [integration]
- The server path resolves from an installed plugin cache, from a checkout, and from an explicit override [unit]
- `uv run pytest` runs the suite from the board directory [integration]
- The board runs from a clean checkout with no npm or pip install, and dpm's `package.json` dependencies stay empty [unit]
- The suite passes with no network available, and no socket is opened outside the stdio pipes [unit]

### PEP 723 header, and a `pyproject.toml` for the harness only
**Task**: 2.1  
**Description**: Per AD2 and the arrangement `cpm/tools/board` already uses: dependencies declared inline for `uv run --script`, with the `pyproject.toml` existing for pytest and nothing else. ENVX2 holds because the board's dependencies are uv-managed and its own.  
**Status**: Pending

### Resolve `bin/dpm-mcp.js` three ways
**Task**: 2.2  
**Description**: Installed plugin cache, a checkout, and an explicit override for when it is neither. Ordered so the override wins — a developer with both a cache and a checkout is the common case, and the wrong one silently answering is a class of confusion that costs an afternoon.  
**Status**: Pending

### Write tests for Story 2
**Task**: 2.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The no-network criterion is a socket-level assertion, not an absence of failures — a suite that never needed the network passes it vacuously.  
**Status**: Pending

---

## The MCP client
**Story**: 3  
**Status**: Pending  
**Blocked by**: Story 2  
**Satisfies**: FR2, NFR6, ENV5

**Acceptance Criteria**:

- Every project read the board performs is observable as a `tools/call` on the spawned server [integration]
- A message split across two chunk boundaries is parsed once and whole [tdd] [unit]
- At least one test drives the real `bin/dpm-mcp.js` over stdio against a built fixture database [integration]
- must NOT parse anything arriving on the server's stderr as data [unit]
- must NOT import `sqlite3`, or any SQLite binding, anywhere in the board's modules [unit]
- must NOT open any file under a project's `docs/` or `.dpm/` from board code [unit]

### Newline framing with a carry buffer
**Task**: 3.1  
**Description**: `[tdd]`, per the spec's tag on NFR6's criterion. The failing test comes first and it is the split one: a message delivered as two chunks, and a second message whose leading bytes arrive in the same chunk as the first message's tail. A framer that passes the first and fails the second is the shape this task exists to reject.  
**Status**: Pending

### The `initialize` handshake and the `tools/call` round trip
**Task**: 3.2  
**Description**: `initialize`, `notifications/initialized`, then `tools/call`. Every read the board performs goes through this one path, which is what makes FR2's observability criterion assertable from a single transcript rather than from a code review.  
**Status**: Pending

### Drain stderr to a diagnostic channel
**Task**: 3.3  
**Description**: Surfaced, never parsed. Two failures are being avoided at once: treating a warning as a response, and letting a full stderr pipe block the server — a server whose stderr nobody reads stops writing to stdout too, and the board hangs with no error anywhere.  
**Status**: Pending

### Build the fixture database
**Task**: 3.4  
**Description**: A real dpm database built by dpm's own tools, per ENV5, so the integration tests drive `bin/dpm-mcp.js` rather than a stub alone. Reused by every later epic's fixtures, which is why it is a task here and not in each of them.  
**Status**: Pending

### Write tests for Story 3
**Task**: 3.5  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`, `[unit]` and `[tdd] [unit]`. FR2's three must-NOTs are static checks over the board's own modules; write them as a sweep of every module rather than a list of the ones that exist today.  
**Status**: Pending

---

## One server per project, spawned only where a database exists
**Story**: 4  
**Status**: Pending  
**Blocked by**: Story 3  
**Satisfies**: FR3

**Acceptance Criteria**:

- Reading a project spawns exactly one server process, reused across subsequent reads [integration]
- Every spawned process is terminated when the board exits [integration]
- Each spawned server is launched in read-only mode with cwd at the project root [integration]
- must NOT spawn a server against a project with no `.dpm/dpm.db` — no process starts, and the project renders FR11's named missing-database state rather than nothing at all [integration]

### Lazy spawn, pooled on project root
**Task**: 4.1  
**Description**: Spawn on first read, keep for the board's lifetime, per AD4. Keyed on the resolved project root so two registry entries pointing at the same tree share one process.  
**Status**: Pending

### The pre-spawn database check, yielding a named state
**Task**: 4.2  
**Description**: FR3's own guard, distinct from 48-01's refusal: the board declines to spawn, and the project acquires the named missing-database state rather than an empty row. Both exist deliberately — this one keeps a pointless process from starting, and 48-01's is what happens when a database disappears between the check and the open.  
**Status**: Pending

### Teardown on exit, including on exception
**Task**: 4.3  
**Description**: Every spawned process reaped. The path that matters is the unhandled one: a board that crashes leaves a server per project holding a database open, and the user's next run spawns another.  
**Status**: Pending

### Write tests for Story 4
**Task**: 4.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The read-only criterion is asserted from the spawned process's own environment and argv, not from the board's intent.  
**Status**: Pending

---

## Pin the tool surface
**Story**: 5  
**Status**: Pending  
**Blocked by**: Story 3  
**Satisfies**: NFR5

**Acceptance Criteria**:

- Every tool name and argument the board declares resolves against the live server's `tools/list` [integration]
- The declared set is derived from the board's own call sites rather than transcribed into a second list, so a call the board makes and never declares fails the check [integration]
- must NOT render an empty column when a declared tool is missing — the mismatch reports [integration]
- must NOT — the reconciliation passes over an empty declared set or an empty `tools/list` response [unit]

### Declare the surface at the call sites
**Task**: 5.1  
**Description**: The declaration lives where the call is made, and the set is collected from those sites. A separate hand-maintained list is the failure mode NFR5 exists to prevent, one level up: it agrees with `tools/list` and disagrees with the code.  
**Status**: Pending

### Reconcile against `tools/list`, with a floor
**Task**: 5.2  
**Description**: Both directions — a declared tool the server does not serve, and a tool the board calls without declaring. The floor is what makes it mean anything: two empty sets agree perfectly.  
**Status**: Pending

### Report the mismatch rather than degrading
**Task**: 5.3  
**Description**: NFR5's must-NOT. An empty column is the observable behaviour of a renamed tool, and it is indistinguishable from a project with no epics — which is why the mismatch has to surface as a mismatch.  
**Status**: Pending

### Write tests for Story 5
**Task**: 5.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The floor is checked by planting an empty declared set and an empty `tools/list` reply and asserting each fails — after Story 5 works, the live surfaces can no longer distinguish a working reconciliation from a vacuous one.  
**Status**: Pending

---

## End-to-end: `list` over a mixed registry
**Story**: 6  
**Status**: Pending  
**Blocked by**: Story 1, Story 4, Story 5  
**Satisfies**: FR1, FR2, FR3 (integration)

**Acceptance Criteria**:

- `board.py list` over a registry holding two fixture projects — one with a database and one without — reports a state for both, spawns exactly one server, and exits with every spawned process reaped [integration]
- The healthy project's reported state is built entirely from `tools/call` responses, asserted from a recorded transcript of the calls made rather than from the absence of other reads [integration]

### Wire the registry, pool and client into `list`
**Task**: 6.1  
**Description**: The first path that crosses all three, and the one the TUI will replace with a view over the same seam.  
**Status**: Pending

### Write tests for Story 6
**Task**: 6.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The transcript assertion is positive — the calls that were made — because "no file was opened" is already covered by Story 3's must-NOTs and passes on a board that reads nothing at all.  
**Status**: Pending

---

## Notes

**Step 3c — integration testing story: warranted, Story 6.** The spec names *Board ↔ MCP server* as the
seam most likely to break on a dpm release and the one FR2 makes load-bearing. Stories 3, 4 and 5 each
exercise it alone; none of them crosses the registry, the pool and the client in the sequence a user's
first command actually takes, and the mixed registry — one healthy project beside one with no database —
is the case where a containment failure in the pool would show up as a board that reports nothing for
either. That is the state NFR2 forbids and 48-06 verifies for the TUI; Story 6 is its CLI-level
counterpart, and it exists at this epic rather than later because the pool is delivered here.

**FR3's must-NOT renders against the CLI at this stage.** The criterion is kept whole — "the project
renders FR11's named missing-database state rather than nothing at all" — and the only rendering surface
that exists in this epic is `board.py list`. The TUI's version of the same state is 48-06's, over the
same named state this epic's pool produces. Retro 42's fix to this criterion is what makes it discriminate
at either surface: it asserts a named state, not merely an absent process.

**FR1's TUI directory picker is in 48-04.** FR1 requires registration "from the CLI and from inside the
TUI via a directory picker"; the picker needs an app to open in. The CLI affordance is Story 1's third
criterion, the picker is a criterion on 48-04, and FR1 is covered only when both are done. Recorded in
both epics so neither reads as complete coverage of the requirement on its own.

**ENVX2 is split with 48-01.** This epic carries the spec's verbatim criterion, including the clean-checkout
half; 48-01 carries the claim that the read-only mode itself introduced no dependency. The shared clause —
dpm's `package.json` dependencies staying empty — is asserted in both, because the two epics are the two
ways it could stop being true.

**Why Story 5's `tools/list` reconciliation is sound as a one-shot check.** dpm declares
`capabilities: { tools: { listChanged: false } }`, so the list advertised at handshake holds for the
session. A reconciliation performed once per spawn is therefore checking a fixed surface rather than
sampling a moving one. If that capability ever changes, this story's premise changes with it.
