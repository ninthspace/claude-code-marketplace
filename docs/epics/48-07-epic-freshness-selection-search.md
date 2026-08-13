# Freshness, Ralph Multi-Select and Cross-Project Search

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Date**: 2026-08-13  
**Status**: Pending  
**Blocked by**: 48-04, 48-05  
**Retro applied**: 42 · Criteria gaps · Applied — a cache is a write, and FR10's proof in 48-06 runs over a session that may never have triggered one; Story 1's must-NOT pins the cache outside every registered project rather than leaving it to the earlier epic's fixture to notice.  
**Retro applied**: 42 · Criteria gaps · Applied — FR14's retargeting criterion says nothing about the empty selection, so a board that always builds a `/dpm:ralph` command passes it; Story 2's third criterion asserts the empty case against 48-05's own targets.  
**Retro applied**: 42 · Patterns worth reusing · Applied — NFR2's containment is re-asserted for search rather than assumed from 48-06, because search is the one path that fans out across every registered project in a single action.  
**Retro applied**: 42 · Codebase discoveries · Applied — AD6's stamp is the database file's own mtime and size because dpm's state is the database, not files under version control; ENVX6 is asserted here rather than left implicit, since a git-derived stamp is the natural thing to reach for and CPM's board does exactly that.

The spec's Should-haves, and the three that fall out of what the earlier epics built: a cache so a cold
board does not re-query everything, a multi-select that turns several ready epics into one `/dpm:ralph`
command, and a search that crosses projects.

## Freshness cache
**Story**: 1  
**Status**: Pending  
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
**Status**: Pending

### The schema-version stamp
**Task**: 1.2  
**Description**: An entry written under an earlier schema is invalid even when the file has not changed, because the derivation that produced it may no longer be the derivation in force. Without it the first plugin upgrade serves stale answers from a file whose mtime is genuinely unchanged.  
**Status**: Pending

### Force-refresh and clear
**Task**: 1.3  
**Description**: Both reachable — bound and present in the palette. A cache with no way to bypass it is the one a user cannot debug, and mtime-and-size does have a blind spot: a write that preserves both.  
**Status**: Pending

### Write tests for Story 1
**Task**: 1.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[feature]` and `[integration]`. The must-NOT is asserted by hashing the fixture project's tree across a session that definitely writes a cache entry — the case 48-06's non-mutation fixture might not reach.  
**Status**: Pending

---

## Ralph multi-select
**Story**: 2  
**Status**: Pending  
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
**Status**: Pending

### The eligibility rule
**Task**: 2.2  
**Description**: Runnable epics only. The three excluded kinds are excluded for different reasons — a blocked epic cannot run, a retro candidate is not an epic to run, and a spec with no epics has nothing to run — and the rule reads off 48-03's candidate kinds rather than re-deriving them.  
**Status**: Pending

### Retarget the launch keys
**Task**: 2.3  
**Description**: One `/dpm:ralph <epics…>` command instead of a single-epic `/dpm:do`. Built through 48-05's argv path, so NFR4's no-shell-string rule covers it without a second implementation.  
**Status**: Pending

### Write tests for Story 2
**Task**: 2.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]` and `[feature]`. The empty-selection criterion is asserted against 48-05's targets directly rather than restated, so the two cannot drift.  
**Status**: Pending

---

## Cross-project search
**Story**: 3  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR15

**Acceptance Criteria**:

- A search runs across registered projects and each result navigates back to its project and epic [integration]
- Results come from the `search` tool, asserted from the calls made [integration]
- A project whose server cannot start contributes no results and does not stop the other projects' results appearing [integration]

### Fan the search across pooled servers
**Task**: 3.1  
**Description**: One `search` call per project, over 48-02's pool and off the UI thread per NFR3. This is the one action that touches every registered project at once, which is why containment is a criterion here as well as in 48-06.  
**Status**: Pending

### Result rows carrying their project and epic
**Task**: 3.2  
**Description**: A result with no project is unnavigable, and results from several projects are indistinguishable without it.  
**Status**: Pending

### Navigate back on selection
**Task**: 3.3  
**Description**: Selecting a result moves the three columns to that project and epic. This is FR15's second half and the part that makes the first half useful.  
**Status**: Pending

### Write tests for Story 3
**Task**: 3.4  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. The containment case uses a registry holding one healthy project and one whose server exits, and asserts the healthy project's results appear — not merely that the search returned.  
**Status**: Pending

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
