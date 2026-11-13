# Test runs

How `do` chooses, records and reuses the test runs of a story. `do` and the `auditor` read this file; the `**Test run**` and `**Audit**` fields it fills are defined in `artifacts.md`.

A run is **full** (every test of every runner the baseline used) or **targeted** (the set below). The baseline is always one full run per `do` run. A story's runs before its audit are targeted, except the full run a failing targeted run adds (**A failing targeted run**) and the runs of an order-dependent story (**A failing targeted run**) or of a story with no targeted set (**The targeted set**), which are full. A story that needs a deferred full run (**When the run is full**) also takes one full run after its last passing audit, unless a full run before the audit stands for it: **The deferred full run**, below.

## The targeted set

- the tests its `Evidence` lines cite;
- the test files the story added or changed;
- the files on the story's `**Independent tests**` line, in either build mode;
- for each changed code file (any file that is not exempt, below), the tests that run it: tests that call it, or reach it through one caller, directly or by the name the framework resolves it by (a route's URL or name, a view name, a component tag, a command signature, an event it handles), and tests that iterate its directory, namespace or registry (architecture tests, snapshot and route-list sweeps).

A test that fakes or mocks the file does not run it. Tests are selected by file path, never by a name filter, which can match extra tests or none. A test file the story adds is in the set; it is not wide reach.

For a story that needs a deferred full run, a changed file of wide reach, and an untested, deleted or renamed code file, contribute no tests to the set; the `**Test run**` line maps each `{file} → deferred full run`. A wide-reach file's own tests are not listed for that file. The set is otherwise as above. A story whose every changed file maps `→ deferred full run` has no targeted set: its run before the audit is full, with its reasons, and stands for the deferred run while its snapshot matches (**A pass**).

## When the run is full

A story needs a deferred full run when any of these holds:

- a changed file has wide reach (below);
- a changed code file has no test that runs it, or is deleted or renamed;
- the story closes its epic: at its step 4 run, every other story in the epic is Complete, has only `[user]` criteria (or criteria treated as `[user]`) left, or is in its batch;
- the work is a small change (`docs/quick/`);
- a merge conflict was resolved.

A story whose diff holds no non-exempt file takes no run before its audit and records `none`. When it closes its epic, it takes a deferred full run (`closes epic`) unless a recorded passing full run stands for it (**A pass**): the code is then the code that run covered.

A fix rerun is the story's targeted set, the fix's tests, the tests that run any newly changed code file and every test that failed in the previous run; a story with no targeted set reruns full. A fix with wide reach makes the story one that needs a deferred full run.

## Wide reach

- a migration or schema;
- a dependency manifest or lock file;
- config, environment and test-runner config (`phpunit.xml`, `.env.testing`, the jest or vitest config);
- shared test setup (the base test case, `Pest.php`, `conftest.py`), fixtures, factories and seeders; a fixture or factory file a story's test-writer or builder added that only that story's tests read is not wide reach, the writer's files committed before fan-out included;
- boot-time registration and route files, console routes included (service providers, container bindings, `bootstrap/`);
- anything the framework wires by convention or by a string rather than an import: event listeners, observers, policies and gates, middleware, layouts and view components, translations, scheduled and console commands, model events and global scopes;
- a change to what callers can observe (signature, return value, side effects, thrown exceptions) of an existing symbol that more than one non-test file uses, found by a grep for its qualified use (`Class::method`, `->method(` on that type), not the bare method name.

A symbol added that nothing uses yet is not wide reach.

## Exempt files and the snapshot

Exempt files, by kind, are the epic doc, the `docs/quick/` record, and prose (Markdown and plain text) that no code, test, test config or build config reads, prose that only skills read among it. A skill or agent file is not exempt, since the harness loads it. Every code, config, fixture, test, view, template, translation or asset file, and every skill or agent file, is a code file and makes a run stale.

After each run `do` takes a snapshot:

- **Its lines.** The first is `git rev-parse HEAD` (`no commit` when there is none); the others are every changed and untracked, not ignored, non-exempt path (from `git diff HEAD --name-only` and `git ls-files -o --exclude-standard`, against the empty tree when there is no commit) as a `{path} {blob hash}` line (`git hash-object`; `deleted` for a path that no longer exists), the lines sorted and hashed together with `git hash-object --stdin` to one `{hash}`.
- **Test output.** A file a run writes that git does not ignore is part of the snapshot but is test output, not story work: it is neither a changed code file for the targeted set and the `untested` trigger nor a reason a story is not `none`, and one that a red pass rewrites makes the result stale, so a project ignores it.
- **The baseline's.** It is noted when the baseline is taken and kept for the run.
- **Standing.** A result stands while a fresh snapshot hashes the same; a second edit to a file already changed at the previous run changes it. A snapshot that was not recorded, or no longer matches, never stands.

The **story snapshot** covers only the story's own paths: each changed code file and each test file the story added or changed, which its `**Test run**` mapping lists as left-hand sides, as `{path} {blob hash}` lines (`git hash-object`; `deleted` for a path that no longer exists), sorted and hashed with `git hash-object --stdin`, with no `HEAD` line. It holds across a commit. The deferred run's `**Test run**` line keeps that mapping after its reasons, so a resumed run recomputes the snapshot from the line and compares it with the one in the `**Audit**` line.

## An open story's independent tests

A failing test in a file on the `**Independent tests**` line of a story not yet Complete belongs to that story, and every rule in this file and in `do` that reads a failure sorts it by this one first. In a run that covers that story (its own targeted or deferred run, or a batch's shared deferred run, which holds only the batch stories it closes) it is a failure of the run, fixed in that story. In any other run it is set aside: it is not pre-existing at a baseline, not a regression another story must fix, and not a failure that keeps that run from passing, and it takes no run alone by path and no flaky or order-dependent check. That story closes only when its own independent tests pass.

## A failing targeted run

A targeted run that fails or errors in a test the story did not add or change, and that passed at the baseline, is followed by a full run before any fix. A test that failed at the baseline is left out of this.

This holds for a story with a deferred run due: the full run comes before any fix and before the audit, and the reruns after it are fix reruns (**When the run is full**).

- The full run fails too: fix it, each rerun a fix rerun.
- The full run passes: run the targeted set once more. A pass names the test under **Found** as flaky. A second failure names it as order-dependent under **Found**. Once a test is named order-dependent, here or by the deferred run (**A failure**, below), the story's runs are full until it closes (`order-dependent: {test}`).

A failure in a test the story added or changed, or in a test on its own `**Independent tests**` line, is fixed without a full run.

## The deferred full run

A story that needs a deferred full run takes it once its last audit has passed, at once, against the code being closed, and closes only when it passes.

- **Timing.** In a single build no other story's work starts between that audit and the run. No edit to the story's own paths (as the story snapshot defines them) is made from that audit until the run has finished, except by a fix below; in a batch, siblings' audit fixes to their own paths go on, and nothing else runs in the checkout while the run does.
- **The line.** The run rewrites the `**Test run**` line as a `full` run with every reason that made the story full, and the counts include it.
- **The snapshot comparison.** Before the run, the story snapshot is compared with the one in the `**Audit**` line: when they differ, a file of the story changed after its audit (outside a fix below), and the story is audited again as a whole story, as `do`'s **Audit rounds** (**A whole-story audit after a pass**) says, before the run is taken.
- **A pass.** The run passes when it shows no failure the baseline did not have and its passed count, per test runner, is at least the baseline's less the test cases the stories it covers removed; a run below that floor, or with a failure the baseline did not have, is not a pass. On a resumed run, baseline failures that a `full run due` or `fix due` story explains are left out of the baseline for this comparison. A pass closes the story with no further audit when the snapshot compared before the run equalled the one recorded in its `**Audit**` line, or when the whole-story audit a mismatch gives has passed. A recorded passing full run whose snapshot matches a fresh one, the baseline's included, stands for the deferred run.
- **A failure.** A test that failed at the baseline is pre-existing. Any other failing test is run alone by path: a failure there is a regression; a pass is followed by one more full run, whose pass names the test under **Found** as flaky and is the deferred run's pass, and whose failure names it as order-dependent, a regression too.
- **Every regression** is fixed, wherever its cause lies (the story, an earlier story, a batch sibling, or several together), in the open story whose change explains it or, when none does, in the story that took the run (the lowest-numbered open story of a batch).
  - The story's `**Audit**` line reads `fix due` from the failure, before the fix is made.
  - The fix's red is the failing test with its failure text from the deferred run, recorded `red: {failure text} — deferred full run, before the fix`; a red-pass red whose file the fix changed, or whose test file it changed, is retaken before the audit below, and the fix's red only when the fix changed its test file.
  - The fix rerun is the one **When the run is full** gives; its `**Test run**` line keeps the deferred run's reasons, which the audit's prompt and the `full run due` line need.
  - The fix is audited once, in a **scoped round** outside the rounds `do`'s **Audit rounds** counts, whose prompt holds the failing tests, their failure text and the fix's files, the files being in scope wherever they lie. Every scoped round writes a `missed-regression` signal (`project`) on the story it is made in and counts in that story's `n findings fixed`.
  - A resumed `fix due` story, whose earlier session held the scoped round's inputs, retakes the reds and is audited as a whole story, which stands as its scoped round, as `do`'s resume bullet says.
  - When the scoped round passes, the `**Audit**` line is rewritten as `full run due` with a story snapshot taken after the fix, and the deferred run is taken again.
- **A second failure.** A second failing deferred run, or a scoped round that returns `fix needed`, marks the story blocked as `do` step 5's last audit does.
- **A batch** in which any story needs a deferred full run takes one shared deferred run, once each story's audit has passed, it is blocked, or it waits on the user (that story takes its own deferred run when it later closes). Every story of the batch waits for it, so none closes before it. A regression a blocked batch story explains blocks the batch's other stories too, listed under **Needs you** with it. In a worktree batch whose stories share files, a sibling's fix to a shared file gives the other story a whole-story audit.

## Reasons a full run records

`closes epic`, `small change`, `wide reach: {file} ({entry})`, `untested: {file}`, `deleted: {file}`, `renamed: {file}`, `targeted failure: {test}`, `order-dependent: {test}`, `merge conflict`, `audit: run too narrow`. A full run that settles an audit's Warning that the run was missing or too narrow records `audit: run too narrow`.

For a targeted run the line records each changed code file and each test file the story added or changed, with the tests that run it (directories or globs allowed for a long set), or `{file} → deferred full run` for a file that contributes no tests, and the auditor checks that mapping against the test tree.
