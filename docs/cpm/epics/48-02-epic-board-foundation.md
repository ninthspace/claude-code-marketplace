# Board Foundation: Registry, MCP Client, Server Pool

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Date**: 2026-08-13  
**Status**: Complete  
**Blocked by**: 48-01  
**Retro applied**: 42 · Criteria gaps · Applied — Story 5's reconciliation carries a floor, because a derived declared set and a derived `tools/list` can both come back empty and read as full agreement; the absence of a mismatch is not evidence that the surfaces match.  
**Retro applied**: 42 · Codebase discoveries · Applied — spec 47's AD1–AD11 were read as this epic's architecture; the `capabilities: { tools: { listChanged: false } }` declaration is what makes Story 5's one-shot `tools/list` reconciliation sound rather than a snapshot of a moving target.  
**Retro applied**: 42 · Scope surprises · Applied — two of FR1's and FR3's criteria name affordances that cannot exist until 48-04 and 48-06; rather than deferring the requirements whole, the CLI half is delivered here and the split is recorded in Notes in both directions.  
**Retro applied**: 47 · Testing gaps · Applied — Story 3's three must-NOTs are static sweeps by their own task description, and a token sweep cannot follow a call; each gets a behavioural companion (a recorded transcript, or the filesystem after a real run) so the sweep bounds the source and the run bounds the behaviour.  
**Retro applied**: 43 · Testing gaps · Applied — Story 5's floor is derived from a source neither the declared set nor `tools/list` passes through, because a floor built from either is satisfied by both collapsing together.  
**Retro applied**: 43 · Codebase discoveries · Applied — the MCP client reads refusals off `error.data`, never `error.message`, which `rpc.js` holds at the JSON-RPC code's standard text; Story 4's FR11 state is matched there too.  
**Retro applied**: 40 · Patterns worth reusing · Applied — Story 5's reconciliation is an `audit(declared, served) → complaints` function, so its must-NOT controls drive the deliverable on planted inputs rather than restating its rules in a second place.  
**Retro applied**: 40 · Testing gaps · Applied — every static sweep in this epic gets a planted module it must complain about, so a pattern that matches nothing anywhere cannot read as a clean tree.

The board is an MCP client and nothing else: no SQL, no SQLite connection, no markdown parsing, no
`.dpm/dpm.sql`. This epic delivers the parts that make that true and testable — where projects are
remembered, how a server is found and spoken to, how one is pooled per project, and how the board
notices when the tool surface it depends on has moved underneath it.

## The project registry
**Story**: 1  
**Status**: Complete  
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
**Status**: Complete

### Prune paths that are no longer directories
**Task**: 1.2  
**Description**: On launch, per FR1. Pruning is a write to the registry, which is one of the only two files this spec writes anywhere; it does not touch the project it forgets.  
**Status**: Complete

### The three CLI subcommands
**Task**: 1.3  
**Description**: `add`, `list`, `remove`. This is FR1's reachability half for everything except the TUI directory picker, which needs an app to live in and belongs to 48-04. `add`'s refusal names what was missing rather than reporting a generic failure, because the usual cause is a path that is a git repository but not a dpm project.  
**Status**: Complete

### Write tests for Story 1
**Task**: 1.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]` and `[integration]`. The must-NOT needs `$XDG_CONFIG_HOME` pointed at a temporary directory and an assertion that nothing appeared outside it — not merely that the expected file appeared inside it.  
**Status**: Complete

**Retro**: [Pattern worth reusing] The must-NOT asked for one absence and the fixture that answers it owns *three* roots — config, home and working directory — because "the registry appeared under `$XDG_CONFIG_HOME`" is equally true of a board that also dropped a copy in the user's home. Pointing every path-resolving variable at a directory the test owns, and then listing each one, is what turns a static claim about a module into a fact about a run; the same `sandbox` fixture is what the spawned-CLI form of the assertion runs on, so the in-process and out-of-process versions cannot disagree.  
**Retro**: [Testing gap] The first version of the atomicity test asserted through a monkeypatched `os.replace` and, against a non-atomic write, failed with "DID NOT RAISE OSError" — a true verdict about a mutation it could not describe. The property is *where the bytes go*, and asserting that the registry path is never itself written to says so directly. **When a mutation's failure text names the test's scaffolding rather than the fault, the assertion is measuring a proxy** — and this one was only findable by running the mutation and reading the message rather than the count.  
**Retro**: [Codebase discovery] Forking `cpm/tools/board/registry.py` under AD3 produced two changes that read as gratuitous and are not: `XDG_CONFIG_HOME` holding a *relative* path must fall back to the default, or it resolves against whatever directory the board was started in — which is a write into a project, forbidden by the very must-NOT this story carries — and the save has to be atomic because this file is the board's only durable state. Neither is visible from the original, which has neither property and needs neither.

---

## A runnable script and a resolvable server
**Story**: 2  
**Status**: Complete  
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
**Status**: Complete

**Retro**: The two dependency declarations have to be kept a copy of each other, not a superset — a package in `pyproject.toml` and not in `board.py`'s inline block is one the *suite* has and the shipped script does not, which is how an import that works in every test fails on the first real run. Both are empty; `textual` arrives in both at once with the TUI (48-04).

### Resolve `bin/dpm-mcp.js` three ways
**Task**: 2.2  
**Description**: Installed plugin cache, a checkout, and an explicit override for when it is neither. Ordered so the override wins — a developer with both a cache and a checkout is the common case, and the wrong one silently answering is a class of confusion that costs an afternoon.  
**Status**: Complete

**Retro**: The checkout case and the installed case turn out to be *one* rule, not two — the board ships inside the plugin, so `../../bin/dpm-mcp.js` resolves to whichever copy the running `board.py` belongs to. The cache glob is not the installed case; it is the case where `board.py` was copied out on its own, which PEP 723 single-file distribution invites.

**Retro**: A missing override is fatal rather than a fallback. Falling through to a *working* server would answer every query correctly from the wrong tree, and the reason to set the variable at all is that the order was about to pick the other one.

### Write tests for Story 2
**Task**: 2.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The no-network criterion is a socket-level assertion, not an absence of failures — a suite that never needed the network passes it vacuously.  
**Status**: Complete

**Retro**: The no-network criterion needed *two* different assertions, not one. "The network is unavailable" is an autouse guard refusing `AF_INET`/`create_connection`/`getaddrinfo` for the whole suite; "no socket is opened outside the stdio pipes" is a recording of every construction, asserted empty over the board's own surface. The guard records local families and then allows them, because `asyncio`'s event loop builds an `AF_UNIX` `socketpair` for its self-pipe and Story 3's async tests would otherwise fail for a reason unrelated to the network.

**Retro**: A spawned board is reached by `sitecustomize` on the child's `PYTHONPATH` — the only hook that runs before its script. Its control has to assert the *exception type*: an unresolvable host fails on a machine with no network whether or not the guard was ever installed, so a non-zero exit alone proves nothing.

**Retro**: `pytest.raises`'s "DID NOT RAISE" was again a true verdict that said nothing (retro 44's shape). The broken-override test is written as try/except/else so the failure names the tree the board would have silently answered from instead — which is the harm, and the reason the ordering exists.

---

## The MCP client
**Story**: 3  
**Status**: Complete  
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
**Status**: Complete

**Retro**: The carry buffer holds **bytes** and each completed line is decoded on its own, which is a third case the task description did not name: a multi-byte character split across the boundary. dpm's server is Node and `JSON.stringify` emits raw UTF-8 rather than `\uXXXX` escapes, so the fixtures had to be encoded with `ensure_ascii=False` — Python's default would have removed the hazard from the test and left it in the wire.

**Retro**: Unparseable bytes on stdout raise rather than being skipped. stdout is the protocol channel and nothing else writes to it (diagnostics go to stderr), so anything else there means this is not the server we think it is — a wrapper's banner, a misrouted Node warning — and dropping it quietly leaves the board waiting for a reply that was already ruined.

### The `initialize` handshake and the `tools/call` round trip
**Task**: 3.2  
**Description**: `initialize`, `notifications/initialized`, then `tools/call`. Every read the board performs goes through this one path, which is what makes FR2's observability criterion assertable from a single transcript rather than from a code review.  
**Status**: Complete

**Retro**: `cwd` and `env` are the caller's, not the client's. Story 4's criterion is that each server is launched read-only at a project root, and the pool can only be held to that if the client does not quietly impose it as well — confirmed by the hand-drive, which created a database exactly because nothing had asked for read-only yet.

**Retro**: Replies are matched by id and anything unmatched is kept rather than discarded. The protocol permits out-of-order answers and server-initiated notifications, and a message the board did not ask for is still evidence about what the server is doing — which is what FR2's transcript is for.

**Retro**: `PROTOCOL_VERSION` is a coupling to `src/server/mcp.js`'s `SUPPORTED_PROTOCOLS`, and a stale value fails *silently*: dpm echoes a revision it knows and answers anything else with its own newest, so drift is a downgrade rather than an error. Story 3's tests assert the string appears in that list.

### Drain stderr to a diagnostic channel
**Task**: 3.3  
**Description**: Surfaced, never parsed. Two failures are being avoided at once: treating a warning as a response, and letting a full stderr pipe block the server — a server whose stderr nobody reads stops writing to stdout too, and the board hangs with no error anywhere.  
**Status**: Complete

**Retro**: The drain starts *before* the handshake, not after it. A server that complains loudly enough during startup fills the pipe and blocks before it ever answers `initialize` — leaving the board with no error anywhere and nothing to look at but a spinner. Confirmed against a child writing 20,000 stderr lines and never answering: drained without blocking, bounded to the last 200.

**Retro**: The drain reads in chunks rather than by `readline`, and shares no code with the framer despite splitting the same delimiter. `StreamReader.readline` raises past its line limit, so one enormous stack trace would end the drain and reintroduce the blockage at the worst moment; and the day the two streams share an implementation is the day a deprecation notice becomes a malformed reply.

### Build the fixture database
**Task**: 3.4  
**Description**: A real dpm database built by dpm's own tools, per ENV5, so the integration tests drive `bin/dpm-mcp.js` rather than a stub alone. Reused by every later epic's fixtures, which is why it is a task here and not in each of them.  
**Status**: Complete

**Retro**: Built by calling the server's own `create_*` tools rather than by writing SQL. The schema is dpm's and it migrates; a fixture that inserted rows directly would be a second, silent implementation of it — correct until a migration lands, and then wrong in a way that looks like a board bug.

**Retro**: Building it found a defect in Story 2's network guard: it had replaced `socket.socket` with a *function*, and `ssl.py` runs `class SSLSocket(socket)` at import time, so any child that imports asyncio died on startup. Harmless while the board imported only the standard library's sync half, fatal from Story 6 when `board.py` reaches the MCP client. The guard is now a subclass, and the suite has a test for a child that imports asyncio.

### Write tests for Story 3
**Task**: 3.5  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`, `[unit]` and `[tdd] [unit]`. FR2's three must-NOTs are static checks over the board's own modules; write them as a sweep of every module rather than a list of the ones that exist today.  
**Status**: Complete

**Retro**: "Every read is a `tools/call`" is a claim about a transcript, so something had to write one down. A recording stand-in server answers the same handshake and appends every line it receives; the real `bin/dpm-mcp.js` proves the protocol is dpm's. Neither substitutes for the other, and putting a transcript into the shipped server to get both from one would have put test apparatus in the product.

**Retro**: The stderr must-NOT is *baited* rather than merely observed: the stand-in writes a well-formed JSON-RPC reply to stderr, first, carrying a plausible result. A client that read both streams into one framer answers from it and never knows.

**Retro**: The "no file under a project" must-NOT needed a static half and a runtime half. Statically only *which modules open files at all* is decidable — a path is built from variables and exists at runtime — so the sweep asserts the modules that talk to projects touch the filesystem not at all, and a real read against the fixture records every open and asserts none landed inside the project. A planted violation drives both sweeps, since either passes trivially when pointed at nothing.

---

## One server per project, spawned only where a database exists
**Story**: 4  
**Status**: Complete  
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
**Status**: Complete

**Retro**: The lock covers the check *and* the spawn. Two projects rendering at once is this board's ordinary case, and a check that released before spawning would let both coroutines past for one root and leave one of the two processes owned by nobody.

**Retro**: `DPM_DATABASE` is *removed* from every spawned server's environment, which is not something the criteria ask for. It is dpm's own override for where the database lives, it is plausibly set in the shell the board is started from, and inherited it points every server at one database whatever project it was launched in — so every row would render, without error and identically, the status of whichever project that variable named.

### The pre-spawn database check, yielding a named state
**Task**: 4.2  
**Description**: FR3's own guard, distinct from 48-01's refusal: the board declines to spawn, and the project acquires the named missing-database state rather than an empty row. Both exist deliberately — this one keeps a pointless process from starting, and 48-01's is what happens when a database disappears between the check and the open.  
**Status**: Complete

**Retro**: `Unreadable` carries the state's *name* and its *remedy* as separate fields rather than a sentence, because 48-06 renders them in different places in a row beside projects that are fine. `NO_DATABASE` is the first of FR11's four named states to exist.

**Retro**: The must-NOT's teeth are in the transcript, not the exception. That the board *reports* a missing database is easy; that it did so without paying for a process, a handshake and a round trip to learn what was on disk all along is the requirement — so the empty-transcript assertion runs first, and `pytest.raises` was replaced by try/except to let it.

### Teardown on exit, including on exception
**Task**: 4.3  
**Description**: Every spawned process reaped. The path that matters is the unhandled one: a board that crashes leaves a server per project holding a database open, and the user's next run spawns another.  
**Status**: Complete

**Retro**: Reached through the async context manager, so the unhandled path is the *same* path — `__aexit__` runs on the way out of an exception without anything having to remember to catch it. Asserted by signalling the pid, not by asking the client whether it closed: a `close()` that returns without doing anything passes every other form of that test.

### Write tests for Story 4
**Task**: 4.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The read-only criterion is asserted from the spawned process's own environment and argv, not from the board's intent.  
**Status**: Complete

**Retro**: Story 3's recording stand-in earned itself twice over: it now also answers with its own cwd, argv and every `DPM_` variable actually present in its environment, which is what makes "launched read-only at the project root" assertable from the process rather than from the dict the pool assembled. Five mutations confirmed the tests: no pooling, an unresolved key, a `close()` that reaps nothing, no pre-spawn check, and an inherited `DPM_DATABASE`.

---

## Pin the tool surface
**Story**: 5  
**Status**: Complete  
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
**Status**: Complete

**Retro**: The declaration *is* the call: `declare()` returns a `Call` that is then passed to `client.call()`, so the reconciled set cannot drift from the code without the code failing to run. A `Call` holds the arguments the board **passes**, not the ones the tool accepts — which is why the reconciliation is one-directional: a server growing an argument is no problem for a board that never sends it.

**Retro**: Story 6's read of a project had to arrive one story early, in `read_project()`. A declaration with no call site is exactly the central list NFR5 forbids, so there was nowhere honest to put these until something called them.

### Reconcile against `tools/list`, with a floor
**Task**: 5.2  
**Description**: Both directions — a declared tool the server does not serve, and a tool the board calls without declaring. The floor is what makes it mean anything: two empty sets agree perfectly.  
**Status**: Complete

**Retro**: The two directions are enforced by different machinery, and neither could do the other's job. A declared tool the server does not serve is a runtime comparison against `tools/list`; a tool called without being declared cannot appear in any runtime set at all — it is a bare string in the source — so that half is an AST sweep for literal tool names at `.call()`/`.read()` sites, with a planted control.

**Retro**: `reconcile()` returns complaints rather than raising, so the caller decides what a mismatch means — a test fails on it, a running board renders it — and so a release that renamed three tools says so three times instead of stopping at the first.

### Report the mismatch rather than degrading
**Task**: 5.3  
**Description**: NFR5's must-NOT. An empty column is the observable behaviour of a renamed tool, and it is indistinguishable from a project with no epics — which is why the mismatch has to surface as a mismatch.  
**Status**: Complete

**Retro**: A mismatch becomes `SURFACE_MISMATCH` — FR11's second named state, reusing `Unreadable` from Story 4 rather than inventing a parallel failure channel. The server is closed on the way out: it cannot answer what this board asks, and leaving it up holds a database open for a whole session on behalf of a project that renders an error.

### Write tests for Story 5
**Task**: 5.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]` and `[unit]`. The floor is checked by planting an empty declared set and an empty `tools/list` reply and asserting each fails — after Story 5 works, the live surfaces can no longer distinguish a working reconciliation from a vacuous one.  
**Status**: Complete

**Retro**: The stand-in's advertised list is a deliberate *copy* of dpm's shape, overridable by environment, so the mismatch cases can be staged. That it agrees with the board proves nothing on its own — the reconciliation against the real `bin/dpm-mcp.js` is what does that, and renaming a declared tool was run as a mutation to confirm it is the test a dpm release breaks.

---

## End-to-end: `list` over a mixed registry
**Story**: 6  
**Status**: Complete  
**Blocked by**: Story 1, Story 4, Story 5  
**Satisfies**: FR1, FR2, FR3 (integration)

**Acceptance Criteria**:

- `board.py list` over a registry holding two fixture projects — one with a database and one without — reports a state for both, spawns exactly one server, and exits with every spawned process reaped [integration]
- The healthy project's reported state is built entirely from `tools/call` responses, asserted from a recorded transcript of the calls made rather than from the absence of other reads [integration]

### Wire the registry, pool and client into `list`
**Task**: 6.1  
**Description**: The first path that crosses all three, and the one the TUI will replace with a view over the same seam.  
**Status**: Complete

**Retro**: Wiring it up reached a state none of the earlier stories could: a database the server *starts* against and then cannot answer for. Nothing in Stories 3–5 produced it, because their fixtures were either real databases or absent ones, and the `project()` fixture's empty file is neither. It arrives as `SERVER_FAILED` — FR11's own words — rather than as a traceback; 48-06 renders it.

**Retro**: `make_pool` is injected as a *factory*, not a pool. The pool owns processes and is entered and left inside one `asyncio.run`; a caller cannot hand in a live one built on an event loop that has already finished.

**Retro**: A `ServerNotFound` is board-level, not per-project — there is nothing to say about any project without a server — so it exits 1 with the message that names every place that was looked, rather than becoming a fourth state per row.

### Write tests for Story 6
**Task**: 6.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The transcript assertion is positive — the calls that were made — because "no file was opened" is already covered by Story 3's must-NOTs and passes on a board that reads nothing at all.  
**Status**: Complete

**Retro**: Teardown at this level needed a witness outside the pool: the stand-in now writes its own pid to a separate file as it starts, and the test asserts every one of them is gone. Asking the pool what it closed is asking the one component whose answer is wrong in exactly the case the test exists for. The pids go to their own file rather than into the transcript, which carries protocol and nothing else.

**Retro**: Story 2's socket assertion had to be restated, not weakened. From this story the board runs an asyncio event loop, and a selector loop builds an `AF_UNIX` socketpair for its self-pipe — two descriptors joined to each other inside the process. The record is now compared against `AF_UNIX`; every network family is still refused outright, which the planted control proves.

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
