# Freshness, Ralph Multi-Select and Cross-Project Search

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Date**: 2026-08-13  
**Status**: Complete  
**Blocked by**: 48-04, 48-05  
**Retro applied**: 42 · Criteria gaps · Applied — a cache is a write, and FR10's proof in 48-06 runs over a session that may never have triggered one; Story 1's must-NOT pins the cache outside every registered project rather than leaving it to the earlier epic's fixture to notice.  
**Retro applied**: 42 · Criteria gaps · Applied — FR14's retargeting criterion says nothing about the empty selection, so a board that always builds a `/dpm:ralph` command passes it; Story 2's third criterion asserts the empty case against 48-05's own targets.  
**Retro applied**: 42 · Patterns worth reusing · Applied — NFR2's containment is re-asserted for search rather than assumed from 48-06, because search is the one path that fans out across every registered project in a single action.  
**Retro applied**: 42 · Codebase discoveries · Applied — AD6's stamp is the database file's own mtime and size because dpm's state is the database, not files under version control; ENVX6 is asserted here rather than left implicit, since a git-derived stamp is the natural thing to reach for and CPM's board does exactly that.  
**Retro applied**: 52 · Testing gaps · Applied — Story 3 adds its search action to `COMMANDS` and drives it in `tests/support/session.py`'s `run()`, so 48-06's FR10 proof covers the search path; anything excused goes in `NOT_IN_A_SESSION` with a reason.  
**Retro applied**: 52 · Testing gaps · Applied — Story 1's must-NOT hashes the project tree with mtime and size across a session that definitely writes a cache entry, reusing 48-06's `snapshot()` rather than a second comparison; the stamp's own blind spot — a write preserving both — is what Task 1.3's force-refresh answers.  
**Retro applied**: 52 · Patterns worth reusing · Applied — Story 2's empty-selection criterion is an equality against 48-05's own `launch_target()` answers for the same rows rather than a restatement of them, and Story 1's cache criterion compares a cached read against an uncached one over the same project.  
**Retro applied**: 52 · Codebase discoveries · Applied — Story 2's selection marker and Story 3's result rows are sized for the column they land in and asserted from the painted row, because a marker the board holds and clips off the end is a selection the user cannot see.  
**Retro applied**: 51 · Patterns worth reusing · Applied — Story 2's eligibility rule reads off 48-03's candidate kinds rather than re-deriving which epics are runnable, so the rows the board offers to select and the rows it offers a `/dpm:do` for cannot disagree.  
**Retro applied**: 51 · Testing gaps · Applied — every planted mutation runs over the whole board suite (and `node --test` in `dpm/` when it touches dpm), and a surviving mutation is treated as a question about the producer before it is treated as a missing assertion.

The spec's Should-haves, and the three that fall out of what the earlier epics built: a cache so a cold
board does not re-query everything, a multi-select that turns several ready epics into one `/dpm:ralph`
command, and a search that crosses projects.

## Freshness cache
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR13, ENVX6, AD6

**Acceptance Criteria**:

- A second read within the freshness window is served from cache; a touched database invalidates it [unit]
- The cache stamp is the database file's mtime and size, and a schema-version stamp invalidates entries written under an earlier schema [unit]
- A force-refresh bypasses the cache and a clear removes it, both reachable from the board [feature]
- A registered project that is not a git repository renders normally [integration]
- must NOT write the cache anywhere inside a registered project — it lives beside the registry under XDG [unit]

### Stamp and lookup
**Task**: 1.1  
**Description**: mtime and size, per AD6. The database is the state, which is why neither git `HEAD` nor a `docs/` mtime appears here — CPM's board stamps on both because its state is files under version control, and dpm's is not.  
**Status**: Complete

**Notes**: `dpm/tools/board/cache.py` — `Stamp`, `stamp_of()`, `entry_key()` and `Cache`, with the lookup
wired into `ServerPool.read()` **before** `self.client(root)`. That order is the whole payoff: a hit answers
without spawning a process. The database file is `stat`-ed and never opened, which is what keeps AD6's stamp
inside FR2's must-NOT — and is why AD6 names those two attributes rather than a digest.

The cache is written once, by `ServerPool.close()`, rather than flushed per read: a board over a dozen
projects makes seven calls each at startup, and a flush per call rewrites the whole file eighty-four times
for something nobody reads until the next session.

### The schema-version stamp
**Task**: 1.2  
**Description**: An entry written under an earlier schema is invalid even when the file has not changed, because the derivation that produced it may no longer be the derivation in force. Without it the first plugin upgrade serves stale answers from a file whose mtime is genuinely unchanged.  
**Status**: Complete

**Notes**: **The schema version had nowhere to come from, and this task added it to dpm.** The board can
reach a project's schema only through the `initialize` handshake — the connection is not open when
`initialize` is answered (AD12 defers it) and no read tool reports the version — so `serverInfo` was the only
surface available. `src/server/mcp.js`'s `methods(tools, resolve, serverInfo)` now takes the block as a
parameter instead of closing over the module constant, and `serve()` in `src/server/index.js` defaults it to
`{ ...SERVER_INFO, schemaVersion: targetVersion() }`. `mcp.js` itself still knows nothing about schemas,
which is the point of passing it in.

**A consequence worth stating**: the schema is unknown until the first handshake of a session comes back, so
the first read always goes out — as does every read that started before that. An entry is never served
against an unknown schema, because a guessed version is a cache that serves the wrong derivation silently.
What the cache buys is the rest of the session.

### Force-refresh and clear
**Task**: 1.3  
**Description**: Both reachable — bound and present in the palette. A cache with no way to bypass it is the one a user cannot debug, and mtime-and-size does have a blind spot: a write that preserves both.  
**Status**: Complete

**Notes**: Two actions rather than one with a flag. `R` / "Force refresh" re-reads every project with the
cache bypassed and the answers written back; `ctrl+k` / "Clear the cache" forgets everything and does **not**
re-read, because clearing is what a user does to establish that the cache is not the cause of what they are
looking at, and a clear that repopulated immediately would answer a different question.

`fresh` is threaded from the action down through `start_survey` → `survey_project` → `read_view` →
`status_model.rows` → `pool.read`, and is all-or-nothing across `read_view`'s seven reads: a project's figures
are derived from all of them together, so refreshing some would render one project out of two moments.

`R` rather than `r` — an unshifted key that re-reads every project would spawn a server per project on a typo.

### Write tests for Story 1
**Task**: 1.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[feature]` and `[integration]`. The must-NOT is asserted by hashing the fixture project's tree across a session that definitely writes a cache entry — the case 48-06's non-mutation fixture might not reach.  
**Status**: Complete

**Notes**: `dpm/tools/board/tests/test_cache.py`, eight tests. Board suite **213 passing** (205 at this
story's start); `node --test` in `dpm/` **707 passing**. Every claim about "served from cache" is read off the
stand-in's transcript — calls that did not happen — rather than off the cache's own account of itself. The
stand-in gained `RECORDING_SCHEMA` so a session's reported schema can be varied; unset by default, which
makes it the older dpm and leaves every other test running against a pool that never serves an entry.

**Two findings from planting six mutations over the whole suite** (retro 51):

- **The upgrade test proved nothing as first written.** The cache is consulted before the server is spawned,  
  so the *first* read of any session misses whatever the schema — the second pool's single call was that,  
  not the schema check. Rewritten as three sessions with a warm-up read each, the middle one on the *same*  
  schema as the control that makes the third mean something.
- **The must-NOT's tree hash missed a cache redirected into the project**, because the same session runs the  
  clear and the misplaced file was gone before the second snapshot. The test now also asserts where the cache  
  is still pointing when the session ends.

The mutations killed: the stamp comparison dropped from `Cache.get`; `fresh` ignored in `ServerPool.read`;
`action_clear_cache` made a no-op; the arguments dropped from `entry_key`; the cache path redirected into the
project; and `schemaVersion` removed from dpm's handshake — the last one caught by both suites.

---

## Ralph multi-select
**Story**: 2  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR14

**Acceptance Criteria**:

- A non-empty ralph selection retargets the launch keys to one `/dpm:ralph <epics…>` command [unit]
- `space` selects a runnable epic and deselects it, and the selection is visible in the row [feature]
- With an empty selection the launch keys behave exactly as 48-05 specifies, asserted against the same targets [unit]
- must NOT allow selection of a blocked, retro or needs-epics row [unit]

### Selection state and the `space` binding
**Task**: 2.1  
**Description**: Toggle, and visible in the row. A selection the user cannot see is a launch command they did not expect.  
**Status**: Complete

**Notes**: `space` → `BoardApp.action_toggle_ralph`, over `self._ralph: set[str]`. **Ids rather than
rows**, because every survey replaces the row objects and a held row would be one no longer in the
column — and a refresh landing is exactly when a user is about to launch what they selected before it.

One flat set for the whole board rather than one per project, because `ralph_selection()` reads it
*through* the epics on screen: a selection made in one project contributes nothing to another's launch
and comes back intact on returning. That is asserted rather than assumed.

The marker is `board_view.ralph_label()` — `▸` in front, a blank in its place on every other row so a
selection never shifts the column sideways. **Leading rather than trailing**: a row is as wide as its
title and its figure, and a marker on the end is the first thing a narrow column clips. `▸` and not the
live pill's `●`, which is on the same board and means a session running *now*.

A key and no palette entry, unlike everything else bound here: the palette acts on the board and this
acts on the row under the cursor, so an entry would run against whichever row the palette left
highlighted.

### The eligibility rule
**Task**: 2.2  
**Description**: Runnable epics only. The three excluded kinds are excluded for different reasons — a blocked epic cannot run, a retro candidate is not an epic to run, and a spec with no epics has nothing to run — and the rule reads off 48-03's candidate kinds rather than re-deriving them.  
**Status**: Complete

**Notes**: `launcher.selectable(candidate)` — **a kind is selectable exactly when it launches
`/dpm:do` singly**, read off `CANDIDATE_COMMANDS`. `/dpm:ralph <epics…>` is the multi-epic form of
`/dpm:do <epic>`, so that is not a proxy for the rule; it is the rule. Each of FR14's three exclusions
then falls out of the existing table rather than being remembered: a blocked epic has no candidate at
all, `spec_without_epics` launches `/dpm:epics`, `retro_missing` launches `/dpm:retro`.

`DO` is now a named constant because three things depend on it being one string — the Projects
column's bare target, the `epic_ready` mapping, and this rule. A literal in any of the three would
break the derivation silently.

A refused row is *said out loud*. A key that quietly did nothing over an excluded row is
indistinguishable from a selection that is broken, and the user's next move would be to press it again.

### Retarget the launch keys
**Task**: 2.3  
**Description**: One `/dpm:ralph <epics…>` command instead of a single-epic `/dpm:do`. Built through 48-05's argv path, so NFR4's no-shell-string rule covers it without a second implementation.  
**Status**: Complete

**Notes**: `launch_target(column, candidate, selected)` — a third parameter on 48-05's own resolver
rather than a second resolver, so the ids reach tmux through the one quoting rule the module already
has. `ralph_target()` returns an argv list like every other target; nothing joins the ids into a
command line on the way.

**A non-empty selection answers before the column does, for every column.** The selection is what the
user built deliberately, one keypress per epic; the highlighted row is wherever the cursor was left. A
board that let the cursor win would launch a single epic while two rows were still marked on screen.

The ids come out in column order, not the order they were pressed: a ralph run works them in the order
it is given them, and the column's order is the project's own — reproducible, and the same twice.

### Write tests for Story 2
**Task**: 2.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]` and `[feature]`. The empty-selection criterion is asserted against 48-05's targets directly rather than restated, so the two cannot drift.  
**Status**: Complete

**Notes**: `dpm/tools/board/tests/test_ralph_selection.py`, seven tests. Board suite **220 passing**
(213 at this story's start).

**The empty-selection test's expected value is `launch_target()` called the way 48-05 calls it** — two
arguments, no selection — and that is the whole of its discriminating power. Comparing the board's
answer against the board's own three-argument call would agree with a board that always built a ralph
command, which is exactly the failure this criterion exists for. The planted version of that mutation
failed seven tests, three of them 48-05's own.

The eligibility test asserts a floor *and* a ceiling: something must be selectable (a rule admitting
nothing passes every must-NOT while making the feature unreachable), and the admitted set must be a
**proper** subset of the model's kinds (a rule admitting everything is the must-NOT itself). The
selection marker is read off the painted rows, never off the set the app holds — a selection the board
knows about and does not draw is what makes a user launch two epics expecting one.

Five mutations planted over the whole suite, all killed: eligibility widened to any candidate; the
marker held but not painted; a ralph command built for an empty selection; the selection read straight
out of the set instead of through the epics on screen; and the toggle not repainting.

---

## Cross-project search
**Story**: 3  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR15

**Acceptance Criteria**:

- A search runs across registered projects and each result navigates back to its project and epic [integration]
- Results come from the `search` tool, asserted from the calls made [integration]
- A project whose server cannot start contributes no results and does not stop the other projects' results appearing [integration]

### Fan the search across pooled servers
**Task**: 3.1  
**Description**: One `search` call per project, over 48-02's pool and off the UI thread per NFR3. This is the one action that touches every registered project at once, which is why containment is a criterion here as well as in 48-06.  
**Status**: Complete

**Notes**: `board.search_projects()` gathers `search_project()` over every registry row, concurrently
for the reason the survey is: a project's server is a process, and twelve asked in turn make the last
wait on the eleven in front. The results come back in **registry order** — a list that reordered
itself by whichever server was quickest would put the same hit somewhere different each run.

`status_model.hits()` is **the one read in that module that does not follow `more`**, and the
exception is stated where it is made: every other read is counted, and a page boundary would take
stories out of a denominator. A search is not counted — dpm ranks it, and the rows past the bound are
by construction the ones it ranked worst. `SEARCH_LIMIT` is per project, because the fan-out has no
way to rank across servers: each answers with its own bm25 scores over its own corpus.

Containment is `Exception`, not `BaseException`, with a cancellation test that holds the *width*. The
mutation survived until that test existed — the search worker is cancelled when the screen closes, and
the wide arm would answer with an empty list, so the project would appear to have matched nothing in a
list the user is still reading.

**The declared surface is what caught the missing tool**: adding `declare("search", …)` failed every
stand-in test as a reconciliation mismatch until the stand-in advertised it. That is NFR5 working.

### Result rows carrying their project and epic
**Task**: 3.2  
**Description**: A result with no project is unnavigable, and results from several projects are indistinguishable without it.  
**Status**: Complete

**Notes**: `board_view.Result` carries the project path and name, the `(entity, entity_id)` pair dpm
returns unchanged, the excerpt, and the document selecting it lands on.

**`document` is `None` for a hit the board holds no row for, and that is a finding rather than a
shortcut.** `search` answers over **fifteen** indexed entities — requirement, finding, observation,
milestone, agent and the rest — and none of them carries an ancestor column in common; the browser's
three columns hold documents and stories. Resolving a requirement to its epic would mean the board
walking dpm's parent columns table by table, which is a second implementation of ancestry the server
owns (AD5) and would go quietly wrong the day a sixteenth entity is indexed. So three routes are
taken, each reading an id off a row: the hit *is* a document on the board, the hit is a story and its
epic is on the board, or the hit is a section and its own row carries the `document_id`. That last is
the only extra read the search makes and it covers every document's prose, which is the bulk of what
matches.

Those results still appear, named by their project. **Hiding them would be the false negative dpm's
own search tool spends three paragraphs warning about** — an empty answer a user reads as an absence.

A second guard sits behind the resolution: a named document that is not a row in the Epics column
resolves to `None`. A spec's section carries a perfectly good `document_id`, and the column holds
epics — carrying it would move the cursor to a row that is not there, which reads as a selection that
did nothing. The mutation that dropped this guard survived the whole suite until a test using the
fixture's *spec* section existed; `IN_A_SECTION` sits under an epic and cannot reach it.

### Navigate back on selection
**Task**: 3.3  
**Description**: Selecting a result moves the three columns to that project and epic. This is FR15's second half and the part that makes the first half useful.  
**Status**: Complete

**Notes**: `SearchScreen` — a modal like the picker, because the thing being done is a question with
an answer and the columns behind it are what the answer is *about*. The query runs in a worker and the
screen stays up while it does (NFR3): twelve servers is twelve processes, and a modal that blocked
until the slowest answered would be a board that stops repainting on a keypress.

`BoardApp.found()` moves the cursor **by id, not by index**. The result was built from the rows as
they stood when the search ran, and a survey can land while the screen is open — an index would point
at whatever had moved into that position. A row that has genuinely gone leaves the cursor on the
project, which cannot go stale while it is registered.

Three strings where a board might use one: `READY`, `RUNNING` and `NOTHING`. An unrun search and an
empty answer reported identically leave the user with two different next moves and no way to tell
which they are in.

Bound to `ctrl+f` **and** in the palette — the entry that 48-04's `COMMANDS` table deliberately left
out until this story existed, with a comment saying why. That comment is now gone, which is the shape
this table is meant to have.

### Write tests for Story 3
**Task**: 3.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The containment case uses a registry holding one healthy project and one whose server exits, and asserts the healthy project's results appear — not merely that the search returned.  
**Status**: Complete

**Notes**: `dpm/tools/board/tests/test_search.py`, nine tests. Board suite **229 passing** (220 at this
story's start); `node --test` in `dpm/` **707 passing**.

**Two copies of the same fixture are registered, deliberately.** Identical corpora make the projects
indistinguishable by their hits, so the only thing that can tell the results apart is the field naming
where each came from — which is the property being asserted. Two different projects would let a result
be attributed correctly by accident, from its text.

The containment case puts the **dead project first**, so a fan-out that stopped at the first failure
returns nothing at all, and asserts the healthy project's own hits rather than the call completing: a
fan-out that swallowed every project returns an empty list without raising and would pass the weaker
claim while failing the requirement entirely.

Provenance is read off the transcript, with the query asserted **verbatim** — a board that helpfully
added an `entity:` scope would return a narrower corpus than the user asked for and report it as the
whole answer.

Retro 52's disposition is discharged: `search` is in `COMMANDS` and `tests/support/session.py`'s
`run()` *drives* it — opens the screen, types a query, waits for the results — rather than dispatching
the action, which would open and close a modal and reach neither the `search` call nor the section
read behind it.

Five mutations planted over the whole suite. Three were killed outright: the query narrowed with an
`entity:` scope, the navigation moving to the project but not the epic, and the fan-out reading only
the first project (four tests, including the provenance one). **Two survived and each named a missing
test rather than a missing assertion** (retro 51's rule) — the containment arm widened to
`BaseException`, and the guard that keeps a resolved document inside the Epics column. Both tests were
written and both mutations then failed.

---

## Notes

**Step 3c — integration testing story: skipped.** The three stories are independent features over
foundations already delivered and verified: the pool and client by 48-02's Story 6, the view by 48-04, the
launch path by 48-05. They share no seam with each other — a cache failure cannot affect a selection, and
neither can affect a search. Story 3's third criterion is the one cross-cutting property, and it is
NFR2's, asserted where the fan-out happens rather than as a story of its own.

**The cache is a write, and that has consequences outside this epic.** `Board ↔ XDG registry and cache
files` is the spec's fourth integration boundary and its own words are "the only files the board itself
writes, and the only writes anywhere in this spec". 48-06 proves FR10 over a full board session, but a
session that never triggered a cache write proves nothing about the cache. Story 1's must-NOT closes that
by hashing the project tree across a session that definitely writes one.

**Story 2's third criterion is added.** FR14 says a non-empty selection retargets the launch keys and says
nothing about an empty one, so a board that always builds a `/dpm:ralph` command — with one epic in it —
satisfies the requirement as written and breaks 48-05's FR8 targets. The criterion asserts the empty case
against those targets directly.

**ENVX6 is asserted rather than assumed.** A git-derived freshness stamp is the natural thing to reach for
and CPM's board does exactly that, so the restriction is not hypothetical: it names the mistake the
adjacent codebase already makes for good reasons of its own. AD6 is why dpm's answer is different, and the
non-git-project criterion is what would fail if the reasoning were ever reverted.

**Nothing here is a blocker for anything.** All three are Should-haves. If the spec is cut for time, this
epic is the cut — with the exception of Story 1's must-NOT, which belongs to FR10 rather than to FR13 and
should move to 48-06 if the cache is dropped.
