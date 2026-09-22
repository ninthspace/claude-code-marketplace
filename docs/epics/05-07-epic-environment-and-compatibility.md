# Environment and compatibility

**Number**: 05-07  
**Source spec**: 05  
**Status**: complete  

## Why this epic is shaped this way

Five stories that add no behaviour. Every one of them checks that something which is true today is still true afterwards, which is why this epic waits on all five that do the work.

Most of what it asserts already holds and is already asserted elsewhere. Where that is so, the story asserts only what this change set narrows and names in the file which claims it is deliberately not restating — otherwise the next reader adds them back, and the corpus grows a second copy of a rule that can go stale separately from the first.

Two of the five carry a cost worth naming. *Nothing that closes today stops closing* is checked against the committed corpus rather than a purpose-built fixture, because a fixture written now would encode the post-change behaviour and pass against anything. And *no schema migration* is not a box to tick: a difference is a decision to raise, since a migration serves this project's own database read-only to the installed server until the plugin is reinstalled.

One story cannot be verified here at all. Whether everything works where the server is an installed plugin release rather than a working tree is a mechanical check missing only its host, so its single task records what an installed-release run would have to show. Self-assessing it from this checkout would confirm it on the one machine where it cannot fail.

## ENV5 is unverified in this environment, and this is what would close it

Story 3's criterion carries the `target` approach: the check is mechanical, only its host is missing, and a verdict from this checkout would confirm it on the one machine where it cannot fail. It is recorded unverified rather than self-assessed, and it does not block the epic.

**Half of it is already pinned here, mechanically.** "No path that exists only in this checkout" is held by two standing assertions in `baseline.test.js` — that no import in `src/` or `bin/` resolves outside `node:` builtins and this tree, and that `process.env` is read only for sanctioned names. Every module this spec added was checked against them and none resolves a path at all: `src/tools/scope.js`, `foreign-keys.js` and `prefix.js` read `PRAGMA`, `src/coverage/report.js` and `label.js` are SQL over the open connection, and `src/tools/spine/closing.js` reads rows. Nothing reaches for `import.meta.url`, `__dirname` or `process.cwd()`.

**What an installed-release run has to show, and cannot be shown from here:**

1. The plugin installed at the release carrying this change set, serving a project's own `.dpm/dpm.db` — not this repository's.
2. `check_coverage` answering for a spec and an epic in that project, with the roll-up counts it returns.
3. `create_coverage` and `update_coverage` taking `verified`, and `update_requirement` taking `coverage_claimed`, with the stamp written from the **server's** clock rather than the caller's. This is the one a run in this session could not observe at all: the MCP server here is the installed 0.7.8 release, which still takes `verified_at`.
4. `delete_dependency` and `delete_coverage_story` removing a row and refusing a second call.
5. Each of the seven write-path refusals and the four naming refusals raised against that project's rows, each message naming something from that project's own vocabulary.

Any one of those failing there and passing here would mean a dependency on this working tree that the two standing assertions do not reach. The reinstall that makes the run possible is the same one the schema-skew paragraph in CLAUDE.md describes, so the two are closed together.

## ENV3's binding quotes a clause this story made true, and that is the rule FR18 just wrote

ENV3's single binding quotes *"A suite assertion already pins this"*. That clause was **false when the binding was written** — nothing in the suite pinned this repository's hook, and story 2 found it out by going to run the assertion the requirement named. It is true now, because this story wrote the assertion.

So the binding is verified and the requirement is left unclaimed, and the reason is worth stating because epic 05-06 had just written the rule it breaks. FR18 says *a binding quotes the clause the criterion actually tests, not the nearest verbatim one*. ENV3's operative clause is the first sentence — the hook resolves to the guard in this working tree rather than to a path under the plugin cache — and that is what `tests/guard-link.test.js` measures. The fragment quotes the sentence *after* it, which is about the safeguard rather than about the guarantee. Nearest verbatim, not the clause under test.

**Nothing here rebinds it.** A binding is identity, and moving one quietly is how a coverage graph stops meaning what it says; the honest record is a verified binding, an unclaimed requirement, and a note saying which clause the work actually measured. Rebinding it is a breakdown.

ENV2 is unclaimed for the ordinary reason — two obligations, one fragment. ENV5 is unclaimed because it carries the `target` approach and is recorded unverified in this environment.

## Story 1 — Assert the development environment

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- The connection refuses to open, naming which capability is missing, where the runtime has no synchronous SQLite binding or its SQLite lacks FTS5; and the manifest declares the runtime floor that supplies both. `[integration]`
- The manifest's test script invokes the runtime's own test runner, and every test this spec adds is discovered and run by it with no other runner present. `[integration]`
- Both dependency sets in the manifest are empty after this change set, and the suite runs on a checkout with no package installation step. `[integration]`

### Task 1 — Assert the runtime floor, the runner and the empty dependency sets

**Status**: complete — Asserted only what this change set narrows, and the file **names what it is deliberately not restating** with where each already lives — the Node floor and FTS5 probe in `baseline.test.js`, the by-name refusal across all four binaries in `capability.test.js`, and the empty dependency maps plus the no-install-script check in `baseline.test.js`. Restating any of them would grow a second copy that can go stale separately from the first, which is the epic's own instruction.

What was left is the one clause none of the three reaches: ENV2's *"every test this spec adds is discovered and run by it"*. Nothing could have asserted that before the files existed.  

Most of this already holds and is asserted elsewhere. Assert only what this change set narrows, and name in the file which claims are deliberately not restated, so the next reader does not add them back.

### Task 2 — Write tests for Assert the development environment

**Status**: complete — tests/spec-environment.test.js — three tests.

**The twenty-four added suites are named, not counted.** A test asserting "twenty-four new files" passes against any twenty-four, including a set with three of these missing and three unrelated ones present. Each name is a file a story in this spec created, grouped by the epic that wrote it.

Discovery is checked by Node's own rule — a `*.test.js` under `tests/` — and then each file is required to actually **declare** a test, because a suite matching the pattern and declaring nothing is discovered, runs nothing and reports success. The second half of ENV2 is that no other runner is present, read from every script in the manifest and from the dependency maps rather than from the absence of a config file, since a runner can be run without one. ENV4's narrowing is that the new suites brought nothing with them: every import across them is a `node:` builtin or a relative path.

Three mutations. A suite renamed out of discovery → the ENV2 test fails. A suite whose `test(` calls are renamed so it declares none → the same test fails, which is the half discovery alone does not carry. A `vitest` script added beside `node --test` → the runner test fails alone.  

Covers the three criteria, including the connection refusing to open with a message naming which capability is absent.

## Story 2 — Assert the guard points at this checkout

**Status**: complete — Delivered by writing the assertion rather than running it. ENV3 claims one already exists; it does not, and the story's criterion was written on that claim. Recorded on the task and as an epic section.  
**Blocked by**: —  

### Acceptance Criteria

- The existing suite assertion that the repository's pre-commit hook resolves into this checkout rather than into the plugin cache passes after this change set. `[integration]`

### Task 1 — Run the existing hook assertion and record the result

**Status**: complete — **The assertion did not exist.** ENV3 states that "a suite assertion already pins this and is the only thing standing between a plugin reinstall and a guard gone stale", and the task was written to run it and record the result. Nothing in the suite pinned *this repository's* hook. The nearest thing — `first-run.test.js`, "must NOT — the run passes against stubs" — resolves the hook of a fixture repository it builds itself, which is a real and necessary assertion about a fresh project and says nothing about this one.

So the task became writing the assertion the requirement believed it was re-running: `tests/guard-link.test.js`, three tests. The link resolves into this checkout; it does **not** resolve into the plugin cache, named as the failure rather than only as an absence; and it is a symlink rather than a copy — the half resolution cannot see, since a copy resolves to itself and passes a path comparison while going stale the moment the guard beside the schema changes. A third test reads the guard script itself, because a correctly linked hook that invoked a cached binary would satisfy the first two and still check the database against a release.

A missing hook fails rather than skips, and the message carries the `ln -sf` command from CLAUDE.md so a red run carries its own fix.

Three mutations, each run against the real repository and restored: the hook repointed at `~/.claude/plugins/cache/.../0.7.8/hooks/pre-commit` (two tests fail, naming the resolved path); the guard script's `dpm-guard.js` renamed (the third fails alone).  

Covers the criterion. Nothing new is written unless it fails; the assertion already exists and is the only thing standing between a plugin reinstall and a guard gone stale against a schema three directories away.

### Retro

- The requirement asserted the existence of a test, the story was written to re-run it, and the test was not there. ENV3 reads "a suite assertion already pins this and is the only thing standing between a plugin reinstall and a guard gone stale" — a sentence confident enough that the breakdown produced a one-task story whose whole content was to run it and record the result. What exists is `first-run.test.js` resolving the hook of a **fixture** repository it builds itself, which is a correct and necessary assertion about a fresh project and says nothing whatever about this one. The two read almost identically in a grep and answer different questions.

The general shape is worth keeping separately from this instance: **a requirement that cites an existing safeguard is citing something nobody checked at the time of writing.** Every other clause of a requirement describes work to be done and is therefore read carefully; a clause describing work already done is read as background. This spec has now produced two of these — ENV3's phantom assertion, and FR11's claim that an observation written twice has no recovery when `update_observation` has carried one since the table was built. Both were written in good faith by someone looking at the right area, and both were wrong in the same direction: assuming the current state rather than reading it.

What made the writing straightforward once the absence was found is that the failure mode was already documented in CLAUDE.md with a date and a version. The 2026-08-16 incident — schema 24 landing beside a 0.5.0 guard that knew 23 — gave the test its three claims: the link resolves into this checkout, it does *not* resolve into the cache, and it is a link rather than a copy. That third one is the only one a path comparison cannot see, since a copy resolves to itself and passes.

Running the mutations against the real repository rather than a fixture was uncomfortable and correct. The assertion is about this working tree's `.git/hooks/pre-commit`; a fixture version of it would have been the exact mistake the requirement made.

## Story 3 — Assert the installed-plugin claim

**Status**: complete — Its single criterion carries `target` and is recorded **unverified in this environment** rather than self-assessed — a verdict from this checkout would confirm it on the one machine where it cannot fail. Epic section 2 names what an installed-release run has to show. The story is complete; the criterion is not met and is not claimed.  
**Blocked by**: —  

### Acceptance Criteria

- Every tool added here works where the server is an installed plugin release reading a project's own database, with no path that exists only in this checkout. `[target]`

### Task 1 — Record what cannot be checked here, and what would close it

**Status**: complete — Recorded as epic section 2 — five things an installed-release run has to show, and the one half that is already pinned here.

**Not self-assessed.** The criterion carries `target`, and a verdict from this checkout would confirm it on the one machine where it cannot fail.

The half that *is* mechanical was checked rather than assumed: every module this spec added was read against `baseline.test.js`'s two standing assertions — no import outside `node:` builtins and this tree, `process.env` read only for sanctioned names — and none of them resolves a path at all. No `import.meta.url`, no `__dirname`, no `process.cwd()`.

Item 3 on that list is the sharp one: this session could not observe the boolean stamp arguments at all, because the MCP server here is the installed 0.7.8 release and still takes `verified_at`. That is epic 05-03's section 2 arriving from the other side.  

The criterion is tagged for an environment nobody here has. The check is mechanical and only the host is missing, so self-assessing it from this checkout would confirm it on the one machine where it cannot fail. This task writes down what an installed-release run would have to show.

## Story 4 — Nothing that closes today stops closing

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- Every epic in the committed corpus that reaches a clean close before the change still reaches one after it, and the standing computed for each of its requirements is unchanged. `[integration]`

### Task 1 — Compare every epic's close and every requirement's standing across the change

**Status**: complete — Run against `.dpm/dpm.sql` **as it stood at c0e3814**, read out of git rather than kept as a copy beside the test — a checked-in snapshot would age separately from the history and the next reader could not tell it from something somebody refreshed. Every epic status, requirement claim and verification in that dump was written by the code as it was, which is what makes it the "before".

**No regression.** Every epic closed there still reads closed, every requirement claimed there still computes `verified`, and the report's additions all arrive under `warnings` rather than in the fields a close reads.

Two of the three findings were the test's readings rather than the corpus's, and both are recorded in the file. The first demanded every story under a closed epic be `complete` and reported `retire-coverage` and `criterion-supersession` as reopened — both closed over a `superseded` story, which is the rule `/dpm:do` Step 8 already states. The second asserted `unaccounted` was empty and it is not; what NFR2 claims is that an unaccounted criterion does not *block* a close, so the assertion is that closed epics and unaccounted criteria coexist.  

Run against the committed corpus before and after. Any difference is a regression to investigate rather than a result to record.

### Task 2 — Write tests for Nothing that closes today stops closing

**Status**: complete — tests/no-regression.test.js — four tests, none against a purpose-built fixture.

**The fourth is the control the whole story rests on**: the dump read must differ from the tree's current one, or the "before" is the "after" and every comparison is the change set against itself. Its first draft read `git show :.dpm/dpm.sql` — the *index* — which returned the committed bytes unchanged while this change set sat unstaged beside it. The control silently could not fail, and only running it showed that. It now reads the working tree's file.

Each positive test also guards against its own corpus being empty: five closed epics, five claimed requirements, and at least one retired story under a closed epic so the superseded reading is exercised rather than merely allowed for.

Two mutations. `verified` emptied in the roll-up → **the suite stayed green**, because the standing is computed by `standingOf` from counts and that line is not on its path. Recorded as a mutation that did not reach what it aimed at rather than as evidence. `standingOf` made to return `partial` always → the claimed-requirement test fails alone, which is the path.  

Covers the criterion against the committed corpus rather than a purpose-built fixture, since a fixture written now would encode the post-change behaviour.

## Story 5 — No schema migration

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- The schema version recorded by the release before this change set and by the release after it are the same number. `[integration]`

### Task 1 — Compare the schema version before and after the change set

**Status**: complete — **Measured, and they agree: 27 and 27.** `targetVersion()` reads what this tree will migrate a database to; the highest `schema_version` row in the committed dump at c0e3814 is what the previous release left behind. No decision to raise.

tests/no-migration.test.js — three tests, each a different form of the same claim, because the version numbers agreeing is the weakest of them. The migration **files** are compared by name rather than by count, since a count is satisfied by one arriving as another leaves — which is what a renumbered migration looks like. And the strongest and cheapest form: `git diff` against c0e3814 reports nothing changed under `src/schema/` at all, with a control confirming the same diff does see this change set elsewhere in `src/`, so an empty answer is about the directory rather than about a range resolving to nothing.

The version assertion carries the consequence in its own failure message — a migration serves this project read-only to the installed server until the plugin is reinstalled — so a red run states why it matters rather than only that a number moved.

Mutation: `028-planted.sql` added. The version test and the file test both fail; the diff test does not, which is right — an untracked file is not a change to the committed tree, and that is the one of the three that reads history rather than the working directory.  

Covers the criterion. A difference is not a failure to work around: it is a decision to raise, because a migration serves this project's database read-only to the installed server until the plugin is reinstalled.

### Retro

- Five stories that add no behaviour, and three of them found something — which is a better return than an epic of assertions has any right to expect. ENV3 claimed a suite assertion already pinned this repository's guard link and none did. Story 4's own control could not fail, because `git show :.dpm/dpm.sql` reads the index and this change set was unstaged, so the "before" and the "after" were the same bytes. And two of story 4's readings were wrong about the corpus rather than the corpus being wrong: a closed epic may hold a `superseded` story, and `unaccounted` is reported rather than gating.

The pattern across all three is one thing: **an assertion about the current state is the kind nobody checks when writing it.** Every other clause of a requirement describes work to be done and gets read carefully; a clause describing what is already true is read as background. This epic exists entirely to check such clauses, which is presumably why it found three.

Story 5 is the counter-example worth keeping. Its three tests say the same thing three ways — the version numbers agree, the migration files are the same by name, and `git diff` reports nothing changed under `src/schema/` — and the ordering is deliberate: the version numbers agreeing is the *weakest* of them, since two trees can target the same number with different files. The planted mutation confirmed it: adding `028-planted.sql` failed the version and file tests and left the diff test passing, because an untracked file is not a change to the committed tree. Three readings of one claim, and the mutation told them apart.

Worth recording about the `target` criterion: story 3 was the only one this run could not verify, and writing down what an installed-release run would have to show took longer than checking it would have. That is the right ratio. The alternative — self-assessing it from the one machine where it cannot fail — would have cost nothing and been worth less than nothing.

## Retro Applied

- 10 · A retro's mechanism transfers and its arithmetic does not · applied — Story 5 is the one that turns on a measurement rather than a belief: *no schema migration* is not a box to tick, because a migration serves this project's own database read-only to the installed server until the plugin is reinstalled. So the schema version is read from the release before this change set and from the tree as it stands, and compared — no figure from the spec's prose or from an earlier epic is carried in. Six epics have now each broken a different number of things than predicted; this one asks what the number actually is.
- 10 · An assertion that leaves something alone is vacuous when the fixture holds one of it · applied — This is the whole of story 4's risk and the epic already names it: *nothing that closes today stops closing* is checked against the committed corpus rather than a purpose-built fixture, because a fixture written now would encode the post-change behaviour and pass against anything. Applied as the rule for the epic — every assertion here runs against something that predates the change, and where one cannot, the story says so rather than building a fixture that agrees with it by construction.
