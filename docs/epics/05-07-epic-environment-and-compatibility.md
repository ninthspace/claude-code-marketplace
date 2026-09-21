# Environment and compatibility

**Number**: 05-07  
**Source spec**: 05  
**Status**: pending  

## Why this epic is shaped this way

Five stories that add no behaviour. Every one of them checks that something which is true today is still true afterwards, which is why this epic waits on all five that do the work.

Most of what it asserts already holds and is already asserted elsewhere. Where that is so, the story asserts only what this change set narrows and names in the file which claims it is deliberately not restating — otherwise the next reader adds them back, and the corpus grows a second copy of a rule that can go stale separately from the first.

Two of the five carry a cost worth naming. *Nothing that closes today stops closing* is checked against the committed corpus rather than a purpose-built fixture, because a fixture written now would encode the post-change behaviour and pass against anything. And *no schema migration* is not a box to tick: a difference is a decision to raise, since a migration serves this project's own database read-only to the installed server until the plugin is reinstalled.

One story cannot be verified here at all. Whether everything works where the server is an installed plugin release rather than a working tree is a mechanical check missing only its host, so its single task records what an installed-release run would have to show. Self-assessing it from this checkout would confirm it on the one machine where it cannot fail.

## Story 1 — Assert the development environment

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- The connection refuses to open, naming which capability is missing, where the runtime has no synchronous SQLite binding or its SQLite lacks FTS5; and the manifest declares the runtime floor that supplies both. `[integration]`
- The manifest's test script invokes the runtime's own test runner, and every test this spec adds is discovered and run by it with no other runner present. `[integration]`
- Both dependency sets in the manifest are empty after this change set, and the suite runs on a checkout with no package installation step. `[integration]`

### Task 1 — Assert the runtime floor, the runner and the empty dependency sets

**Status**: pending  

Most of this already holds and is asserted elsewhere. Assert only what this change set narrows, and name in the file which claims are deliberately not restated, so the next reader does not add them back.

### Task 2 — Write tests for Assert the development environment

**Status**: pending  

Covers the three criteria, including the connection refusing to open with a message naming which capability is absent.

## Story 2 — Assert the guard points at this checkout

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- The existing suite assertion that the repository's pre-commit hook resolves into this checkout rather than into the plugin cache passes after this change set. `[integration]`

### Task 1 — Run the existing hook assertion and record the result

**Status**: pending  

Covers the criterion. Nothing new is written unless it fails; the assertion already exists and is the only thing standing between a plugin reinstall and a guard gone stale against a schema three directories away.

## Story 3 — Assert the installed-plugin claim

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- Every tool added here works where the server is an installed plugin release reading a project's own database, with no path that exists only in this checkout. `[target]`

### Task 1 — Record what cannot be checked here, and what would close it

**Status**: pending  

The criterion is tagged for an environment nobody here has. The check is mechanical and only the host is missing, so self-assessing it from this checkout would confirm it on the one machine where it cannot fail. This task writes down what an installed-release run would have to show.

## Story 4 — Nothing that closes today stops closing

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- Every epic in the committed corpus that reaches a clean close before the change still reaches one after it, and the standing computed for each of its requirements is unchanged. `[integration]`

### Task 1 — Compare every epic's close and every requirement's standing across the change

**Status**: pending  

Run against the committed corpus before and after. Any difference is a regression to investigate rather than a result to record.

### Task 2 — Write tests for Nothing that closes today stops closing

**Status**: pending  

Covers the criterion against the committed corpus rather than a purpose-built fixture, since a fixture written now would encode the post-change behaviour.

## Story 5 — No schema migration

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- The schema version recorded by the release before this change set and by the release after it are the same number. `[integration]`

### Task 1 — Compare the schema version before and after the change set

**Status**: pending  

Covers the criterion. A difference is not a failure to work around: it is a decision to raise, because a migration serves this project's database read-only to the installed server until the plugin is reinstalled.
