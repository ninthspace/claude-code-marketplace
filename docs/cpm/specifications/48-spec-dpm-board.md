# Spec: dpm board — a cross-project TUI over the planning database

**Date**: 2026-08-13  
**Brief**: none — direct input

## Problem Summary

dpm has reached parity with CPM's skill surface but has no cross-project view. There is no way to
see, across every project that uses it, which epics can be picked up now, which are waiting and on
what, and to launch the right `/dpm:*` session for one without leaving the terminal. CPM answers
that question with `cpm/tools/board`, a Textual TUI that parses `docs/` markdown and derives state
from it. dpm holds the same answers as rows, reachable through typed MCP tools — which makes them
exact rather than inferred: a blocked epic names its blocker instead of having one guessed from a
`**Blocked by**` line. This spec covers a companion board for dpm, and the one amendment to dpm's
server that makes observing a project genuinely inert.

## Functional Requirements

### Must Have

- **FR1 — Project registry.** Register, list and remove projects, persisted under XDG config.  
  Registration works from the CLI and from inside the TUI via a directory picker. A registered path  
  that is no longer a directory is pruned on launch.
- **FR2 — Every read goes through dpm's typed MCP tools.** The board is an MCP client speaking  
  newline-framed JSON-RPC over stdio to `bin/dpm-mcp.js`: `initialize`, then `tools/call` against  
  `list_*`, `read_*`, `search` and `preview_document_kind`. It contains no SQL, opens no SQLite  
  connection, parses no markdown under `docs/`, and reads no `.dpm/dpm.sql`.
- **FR3 — One server session per project, spawned only where a database already exists.** A single  
  long-lived server process per project, cwd at the project root, reused across reads and torn down  
  when the board exits. The board confirms `.dpm/dpm.db` is present before spawning.
- **FR4 — Three-column browser.** Projects → Epics → Stories in Miller columns, with a preview panel  
  beneath the Epics and Stories columns and colour carrying state.
- **FR5 — State derived from rows, never from prose.** Readiness comes from `list_epic` and  
  `list_story` with `ready`, which applies dpm's own `readyClause` over `dependency` filtered by  
  `gates_work`. A blocked row names its blocker from `list_dependency` rather than inferring one.  
  *In progress* is derived — some stories complete, some pending — because dpm's status enum has no  
  such value. `superseded` and `withdrawn` retire an epic without satisfying anything that waits on  
  it.
- **FR6 — Story progress.** Stories done over stories total, per project and per epic, counted from  
  story rows.
- **FR7 — Previews rendered from the database.** The epic, spec and retro preview renders what  
  `read_*` (with `include_body`) and `preview_document_kind` return; the story preview renders that  
  story's own acceptance criteria and tasks as rows. No projected `.md` file is opened.
- **FR8 — Launch the right `/dpm:*` session.** Launch as a tmux session (`l`), open a plain Claude  
  at the project (`o`), attach this terminal to a running session (`t`), or copy the command (`c`).  
  The target follows the focused column: a bare `/dpm:do` from the Projects column, and the  
  highlighted candidate's own command — `/dpm:do <epic>`, `/dpm:epics <spec>`, `/dpm:retro <epic>` —  
  from the Epics or Stories column.
- **FR9 — Candidate next actions, ordered.** Ready epics first, then specs with no epics, then  
  complete epics with neither a retro nor a recorded waiver.
- **FR10 — The board never mutates a project.** No mutating tool is called, nothing is staged, and  
  no file under a registered project is written — `.dpm/` included. Observing a project leaves it  
  byte-identical.
- **FR11 — A project the board cannot read is a state, not a crash.** A missing `.dpm/dpm.db`, a  
  schema version ahead of the server, a Node below dpm's floor, and a server that fails to start  
  each render as a distinct named per-project state carrying its remedy. Every other project  
  continues to render.
- **FR18 — Command palette.** `Ctrl+P` opens straight to the board's own actions.

### Should Have

- **FR12 — Live session pills.** A project with a running board-launched session shows a `● live`  
  pill, carrying a count when several are running, dropped when a session ends.
- **FR13 — Freshness cache.** Derived per-project status is cached and invalidated by the database  
  file's own mtime and size, with a force-refresh and a clear.
- **FR14 — Ralph multi-select.** `space` selects runnable epics; while the selection is non-empty  
  the launch keys build one `/dpm:ralph <epics…>` command instead of a single-epic `/dpm:do`.
- **FR15 — Cross-project search.** The `search` tool, run across registered projects, with results  
  navigable back to their project and epic.

### Could Have

- **FR16 — Coverage gaps view.** Requirements with no coverage row, from `list_coverage` — a  
  question CPM's board could not ask of a markdown corpus.
- **FR17 — Integrity badge.** `check_integrity` per project, surfaced as a per-project badge.

### Won't Have (this iteration)

- Any write path from the board — no status editing, no publish trigger, no `create_*` or `update_*`  
  call under any circumstance.
- Reading a CPM markdown corpus, importing a CPM project, or merging the two boards into one binary.
- Rewriting `dpm:status`'s narrative, artifact or coverage-rollup behaviour beyond the reconciliation  
  named in scope.
- Remote or multi-user operation; the board is local and single-user.
- Publishing to PyPI or shipping a compiled binary — the board runs from the repository, as  
  `cpm/tools/board` does.

## Non-Functional Requirements

- **NFR1 — Read-only by construction, not by discipline.** Non-mutation is a property of how the  
  server is launched and which tool set it serves, so that a call site cannot violate it by  
  forgetting.
- **NFR2 — One unreadable project never takes the board down.** A failure is contained to its own  
  row.
- **NFR3 — Responsive at a working registry size.** Over ten registered projects the Projects column  
  renders without waiting on server startup; spawning and reading happen off the UI thread.
- **NFR4 — Shell-safe launch.** Every `tmux` invocation is an argv list; the project path and command  
  are quoted into the single `cd … && claude …` string tmux runs. No shell at any layer of the  
  board's own code.
- **NFR5 — The tool surface is pinned, not assumed.** The board declares the tool names and arguments  
  it depends on, and a dpm release that renames or rescopes one fails a test rather than quietly  
  rendering an empty column.
- **NFR6 — Protocol hygiene.** The server's stdout carries protocol and nothing else; its stderr is  
  surfaced as a diagnostic and never parsed as data. A message split across chunk boundaries is  
  buffered and parsed once, whole.
- **ENV1 — uv and Python 3.11+.** `uv` on the machine running the board, with a Python 3.11 or later  
  interpreter it can provision.
- **ENV2 — Node 22.5.0 or later on `PATH`.** The board spawns `bin/dpm-mcp.js`; below the floor that  
  executable refuses with a message naming the version, and the board renders the refusal per FR11.
- **ENV3 — `bin/dpm-mcp.js` resolvable.** Locatable on disk — installed plugin cache or a checkout —  
  and configurable when it is neither.
- **ENV4 — pytest and pytest-asyncio in development,** runnable as `uv run pytest` from the board  
  directory.
- **ENV5 — A real dpm database fixture buildable in development,** so tests drive the actual  
  `bin/dpm-mcp.js` over stdio rather than a stub alone.
- **ENV6 — tmux available in development,** so the launch, attach and live-pill paths are exercised  
  rather than assumed.
- **ENV7 — Textual 0.80 or later,** provisioned inline by uv under PEP 723, with its `run_test()`  
  pilot harness available in development for feature-level tests.
- **ENVX1 — Must not require tmux to view the board.** Without tmux the board renders and the launch  
  keys degrade to copy.
- **ENVX2 — Must not require an npm install, a build step, or a new runtime dependency on dpm.** dpm  
  ships zero dependencies and must continue to.
- **ENVX3 — Must not require write access to any registered project,** including creating  
  `.dpm/dpm.db` in a project that has none.
- **ENVX4 — Must not require network access.**
- **ENVX5 — Must not require a running Claude Code session or the `claude` CLI to view the board.**  
  Only launching needs `claude`.
- **ENVX6 — Must not require git, or a committed database.** Freshness is the database file's own  
  mtime and size.

## Architecture Decisions

### AD1 — dpm gains a read-only server mode, and the board launches nothing else

**Choice**: `DPM_READ_ONLY=1` (with an equivalent flag) opens the connection with `readOnly: true`,
skips `migrate` and `applyVocabulary`, and serves `readOnlyTools`. SQLite's own refusal on a missing
file supplies FR11's missing-database state.

**Rationale**: `bin/dpm-mcp.js` calls `start()`, which migrates the database and re-seeds vocabulary
before a single tool is called. So merely opening the board after a plugin update would migrate every
registered project's database, leaving each one diverged from its committed `.dpm/dpm.sql` — and the
pre-commit guard would then refuse the user's next commit in a repository they had not touched. The
failure is silent, delayed, and impossible to attribute. A read-only connection closes it at the only
layer that can.

**The migration is the whole of the rationale, and the create-on-open hazard is no longer part of it.**
An earlier draft of this decision also cited `main()` creating `.dpm/` and the database file on the way
in, and credited the read-only flag with closing that as a side effect. Spec 49 closes it at the
source for every caller, not only for a board-launched one, so read-only mode is not what protects a
registered project from acquiring a database. What the flag still does — and what FR11 depends on — is
supply the *named state*: SQLite refuses to open a missing file read-only (`ERR_SQLITE_ERROR`,
confirmed on Node 24.19), which is how the board learns a project has no database rather than
inferring it. That is an obligation on this spec whether or not 49 has landed.

**Alternatives considered**: an existence check plus call-site discipline (leaves the migration
intact); copying the database to a temporary file and serving from the copy (racy, and stale by
construction); accepting the migration as harmless (it is not — it breaks the user's next commit).

**Consequence**: this spec spans two components. The board depends on the server amendment, so the
amendment is built first.

**Consequence — the relationship to spec 49, in both landing orders.** Spec 49 (*DPM Database
Lifecycle*) defers creation for every caller and adds FR12, which requires the deferred open to honour
this mode: refuse a missing database rather than create it, write no directory and no ignore file, and
perform no restore. The two specs are complementary — 49 covers create universally and leaves
migrate-on-first-use alone, this one covers migrate for observers and needs the refusal for FR11 — so
neither replaces the other, and the order they land in changes only how much each carries.

- **49 first**: this amendment reduces to the read-only connection, the skipped migration and seeding,  
  and the refusal that FR11 reads. Nothing here has to prevent a file being created, because nothing  
  creates one.
- **This one first**: the amendment is built as specified, and 49's FR12 is then the requirement that  
  its lazy open does not reintroduce the create on the read-only path.

### AD2 — Python 3.11 and Textual, forked from cpm board's module split

**Choice**: `board.py`, `status_model.py`, `board_view.py`, `launcher.py`, `registry.py`, `cache.py`,
plus a new `mcp_client.py`. Distributed as a PEP 723 single-file script provisioned by uv, with a
`pyproject.toml` for the test harness only — the same arrangement `cpm/tools/board` uses.

**Rationale**: the launcher, registry, cache and view helpers transfer nearly intact along with their
tests; derivation is the part that gets rewritten, from a markdown parser into an MCP client. Because
MCP is protocol-level, the implementation language buys nothing on the read side, so reuse decides
it. ENVX2 holds: the board's dependencies are uv-managed and its own, and dpm gains none.

**Alternatives considered**: Node with Ink — matches dpm's runtime and could import dpm's modules
directly, but that is precisely what FR2 rules out, and it adds npm dependencies while
re-implementing everything reusable. Go or Rust — a single distributable binary, but a third
toolchain and nothing to reuse.

### AD3 — A sibling tool at `dpm/tools/board/`, sharing no runtime code with `cpm/tools/board/`

**Choice**: a self-contained tool alongside the CPM board, not an extension of it and not a shared
package.

**Rationale**: a project is a CPM project or a dpm project, never both, and the two derivation models
differ at the root — one parses files and infers blocking, the other queries rows and reads it. The
boards then version independently.

**Alternatives considered**: extracting a shared Python package (couples two plugins' release cycles
for the sake of launcher and registry code that rarely changes); one board with two backends (a mode
switch spanning two different state models).

**Accepted cost**: roughly a thousand lines of launcher, registry and cache duplicated between the two
trees.

### AD4 — One long-lived server per project, lazily spawned and pooled

**Choice**: spawn on first read of a project, keep the process for the board's lifetime, reap on exit.

**Rationale**: startup includes a connection open and a handshake; paying that per query would put it
on the interaction path.

**Alternatives considered**: spawn-per-read (simplest lifecycle, worst latency); one server for every
project (unavailable — a server serves one database).

### AD5 — A derivation contract at `dpm/shared/status-model.md`

**Choice**: a single written source of truth for how state, progress and next actions are derived,
conformed to by the board (in code) and `/dpm:status` (in prose), expressed in rows and tool calls.

**Rationale**: `cpm/shared/status-model.md` is why CPM's two consumers have never disagreed about what
a project's state is, and dpm now has the same two consumers.

**Alternatives considered**: no contract, with the board deriving alone (guarantees the two answers
drift, and gives neither a place to record why).

### AD6 — Freshness keyed on the database file's mtime and size

**Choice**: the cache stamp is the database file's mtime and size, plus a schema-version stamp that
invalidates old entries.

**Rationale**: the database is the state. CPM's board stamps on git `HEAD` and `docs/` mtimes because
its state is files under version control; dpm's is not, and ENVX6 says git need not be present at all.

**Alternatives considered**: no cache (a query is milliseconds, but a cold board still spawns N
servers); git `HEAD` (wrong input, and unavailable in a non-git project).

### AD7 — The launcher reused in shape, with dpm's own session names

**Choice**: tmux sessions named `dpm-<project>-<id>`, a `Ctrl-b o` return binding guarded on a
`@dpm_launched` session option, and argv-list invocation throughout.

**Rationale**: the reasoning behind CPM's launcher — why the return key is a prefix binding, why every
tmux call is an argv list — applies unchanged. Distinct session names and a distinct guard option keep
the two boards' sessions from claiming each other's.

## Scope

### In Scope

- dpm's read-only server mode: connection flag, skipped migration and seeding, read-only tool set,  
  refusal on a missing database (AD1).
- `dpm/tools/board/` — registry, three-column browser, MCP client, row-derived state, previews from  
  rows, tmux launcher, command palette (FR1–FR11, FR18).
- The should-haves where they fall out of the above: live pills, freshness cache, ralph multi-select,  
  cross-project search (FR12–FR15).
- `dpm/shared/status-model.md`, and a bounded reconciliation pass against `dpm:status` that amends the  
  skill only where it contradicts the contract and lists what it deliberately left alone.
- The pytest suite, driving the real `bin/dpm-mcp.js` over stdio against a built fixture database.

### Out of Scope

- Any write path from the board.
- Reading a CPM markdown corpus, importing a CPM project, or merging the two boards.
- `dpm:status` behaviour beyond the contract reconciliation.
- Remote or multi-user operation.
- Packaging beyond running from the repository.

### Deferred

- FR16 (coverage gaps view) and FR17 (integrity badge) — both cheap over the tool surface, neither  
  needed for the board to earn its place.
- Milestone and communication views.
- Sharing code between the two boards, should the duplication start to hurt.

## Testing Strategy

### Tag Vocabulary

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[target]` — Mechanical check runnable only against the real deployment target; not a human  
  judgement, and not a development-environment claim
- `[tdd]` — Workflow mode: red-green-refactor. Composable with any level tag.

No criterion in this spec carries `[manual]` or `[target]`. Everything here is mechanically checkable,
and the board's runtime environment is a developer workstation — the same class of machine the work
happens on — so every environmental entry is a development claim and takes an automated tag.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| FR1 | Add, list and remove round-trip through a registry file located under `$XDG_CONFIG_HOME` | `[unit]` |
| FR1 | A registered path that is no longer a directory is pruned on launch | `[unit]` |
| FR1 | must NOT write the registry anywhere outside the XDG config location | `[unit]` |
| FR2 | Every project read the board performs is observable as a `tools/call` on the spawned server | `[integration]` |
| FR2 | must NOT import `sqlite3`, or any SQLite binding, anywhere in the board's modules | `[unit]` |
| FR2 | must NOT open any file under a project's `docs/` or `.dpm/` from board code | `[unit]` |
| FR3 | Reading a project spawns exactly one server process, reused across subsequent reads | `[integration]` |
| FR3 | Every spawned process is terminated when the board exits | `[integration]` |
| FR3 | must NOT spawn a server against a project with no `.dpm/dpm.db` — no process starts, and the project renders FR11's named missing-database state rather than nothing at all | `[integration]` |
| FR3 | A server spawned read-only against a missing database refuses with `ERR_SQLITE_ERROR` and creates no file, driven as the sequence board code would perform: spawn, then call a read tool | `[integration]` |
| FR4 | Projects, Epics and Stories columns render, and focus moves between them with ← / → | `[feature]` |
| FR4 | The highlighted row's preview panel renders beneath its column | `[feature]` |
| FR5 | An epic held by an incomplete blocker renders blocked and names that blocker | `[tdd] [integration]` |
| FR5 | An epic with some stories complete and some pending renders in progress, though no row carries that value | `[tdd] [unit]` |
| FR5 | must NOT treat a `superseded` or `withdrawn` blocker as satisfying the edge it holds | `[tdd] [unit]` |
| FR6 | Per-project and per-epic done-over-total counts equal the story rows the tools return | `[tdd] [unit]` |
| FR7 | Preview text for an epic, spec or retro equals what the read tool returned for it | `[integration]` |
| FR7 | A story's preview renders that story's own criteria and tasks, not the whole epic | `[integration]` |
| FR7 | must NOT open a projected `.md` file to build any preview | `[unit]` |
| FR8 | Each focused column produces its documented launch target as an argv list | `[tdd] [unit]` |
| FR8 | A launch creates a tmux session named `dpm-<project>-<id>` running in the project directory | `[integration]` |
| FR8 | `t` attaches to the most recently used live session for the selected project | `[integration]` |
| FR9 | Candidates order as ready epics, then specs with no epics, then complete epics with no retro | `[tdd] [unit]` |
| FR9 | must NOT offer a retro candidate for an epic carrying a recorded retro waiver | `[unit]` |
| FR10 | After a full board session over a fixture project, the database file's hash, size and mtime are unchanged | `[integration]` |
| FR10 | must NOT call any tool whose name is a mutating verb, in any code path | `[unit]` |
| FR11 | A project with no `.dpm/dpm.db` renders a named state carrying its remedy | `[integration]` |
| FR11 | A database whose schema is ahead of the server renders a distinct named state | `[integration]` |
| FR11 | A server that exits immediately renders a third, distinct named state | `[integration]` |
| FR11 | must NOT let any of the three prevent the remaining projects from rendering | `[integration]` |
| FR18 | `Ctrl+P` opens the palette directly on the board's own actions | `[feature]` |
| FR12 | A project with a running launched session shows a `● live` pill, carrying a count when several run | `[integration]` |
| FR12 | The pill is dropped when the session ends or its window id changes | `[integration]` |
| FR13 | A second read within the freshness window is served from cache; a touched database invalidates it | `[unit]` |
| FR14 | A non-empty ralph selection retargets the launch keys to one `/dpm:ralph <epics…>` command | `[unit]` |
| FR14 | must NOT allow selection of a blocked, retro or needs-epics row | `[unit]` |
| FR15 | A search runs across registered projects and each result navigates back to its project and epic | `[integration]` |
| NFR1 | With the read-only mode active, a mutating tool call is refused by the server | `[integration]` |
| NFR1 | With the read-only mode active, opening a database at the current schema version runs no migration and writes no row | `[integration]` |
| NFR2 | With one project unreadable, every other registered project still renders its state | `[integration]` |
| NFR3 | The Projects column renders before any spawned server has completed its handshake | `[feature]` |
| NFR3 | must NOT block the UI thread on a server spawn or a tool call | `[feature]` |
| NFR4 | A project path containing spaces, quotes and a semicolon produces a correct argv and executes nothing extra | `[unit]` |
| NFR4 | must NOT construct any tmux invocation as a shell string | `[unit]` |
| NFR5 | Every tool name and argument the board declares resolves against the live server's `tools/list` | `[integration]` |
| NFR5 | must NOT render an empty column when a declared tool is missing — the mismatch reports | `[integration]` |
| NFR6 | A message split across two chunk boundaries is parsed once and whole | `[tdd] [unit]` |
| NFR6 | must NOT parse anything arriving on the server's stderr as data | `[unit]` |
| ENV1 | `uv run --script board.py list` succeeds on a clean checkout with no prior install step | `[integration]` |
| ENV2 | With a Node below dpm's floor, the executable's refusal is captured and rendered per FR11 | `[integration]` |
| ENV3 | The server path resolves from an installed plugin cache, from a checkout, and from an explicit override | `[unit]` |
| ENV4 | `uv run pytest` runs the suite from the board directory | `[integration]` |
| ENV5 | At least one test drives the real `bin/dpm-mcp.js` over stdio against a built fixture database | `[integration]` |
| ENV6 | The launch and attach paths create and tear down a real tmux session during the suite | `[integration]` |
| ENV7 | Feature-level tests drive the TUI through Textual's `run_test()` pilot | `[feature]` |
| ENVX1 | With tmux absent from `PATH`, the board renders and the launch keys degrade to copy | `[integration]` |
| ENVX2 | The board runs from a clean checkout with no npm or pip install, and dpm's `package.json` dependencies stay empty | `[unit]` |
| ENVX3 | A registered project on a read-only filesystem renders its state without error | `[integration]` |
| ENVX4 | The suite passes with no network available, and no socket is opened outside the stdio pipes | `[unit]` |
| ENVX5 | With `claude` absent from `PATH`, the board renders and the launch keys report the absence | `[integration]` |
| ENVX6 | A registered project that is not a git repository renders normally | `[integration]` |

### Integration Boundaries

- **Board ↔ MCP server** — newline-framed JSON-RPC over stdio: the `initialize` handshake, `tools/call`  
  request and reply shapes, and the tool names and arguments NFR5 pins. The seam most likely to break  
  on a dpm release, and the one FR2 makes load-bearing.
- **Server ↔ SQLite, in read-only mode** — AD1's new seam. The boundary test is negative: opening runs  
  no migration and writes no row.
- **Board ↔ tmux** — argv construction, session naming, the `@dpm_launched` guard, and attach  
  behaviour when several sessions are live.
- **Board ↔ XDG registry and cache files** — the only files the board itself writes, and the only  
  writes anywhere in this spec.
- **Contract ↔ its two consumers** — `dpm/shared/status-model.md` against the board's derivation and  
  against `dpm:status`; the reconciliation pass is where a disagreement surfaces.

### Unit Testing

Unit testing of individual components is handled at the `dpm:do` task level — each story's acceptance
criteria drive test coverage during implementation.
