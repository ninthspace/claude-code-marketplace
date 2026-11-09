# Test runs

How `do` chooses, records and reuses the test runs of a story. `do` and the `auditor` read this file; the `**Test run**` field it fills is defined in `artifacts.md`.

A run is **full** (every test of every runner the baseline used) or **targeted** (the set below). The baseline is always one full run per `do` run. A story takes a targeted run unless this file makes it full.

## The targeted set

- the tests its `Evidence` lines cite;
- the test files the story added or changed;
- for each changed code file (any file that is not exempt, below), the tests that run it: tests that call it, or reach it through one caller, directly or by the name the framework resolves it by (a route's URL or name, a view name, a component tag, a command signature, an event it handles), and tests that iterate its directory, namespace or registry (architecture tests, snapshot and route-list sweeps).

A test that fakes or mocks the file does not run it. Tests are selected by file path, never by a name filter, which can match extra tests or none. A test file the story adds is in the set; it is not wide reach.

## When the run is full

A story's run is full when any of these holds:

- a changed file has wide reach (below);
- a changed code file has no test that runs it, or is deleted or renamed;
- the story closes its epic: at its step 4 run, every other story in the epic is Complete or has only `[user]` criteria (or criteria treated as `[user]`) left;
- the work is a small change (`docs/quick/`);
- a sibling in the same parallel batch forced a full run, or a merge conflict was resolved.

A failing targeted run adds a full run as **A failing targeted run** says, below.

A story whose diff holds no non-exempt file takes no run and records `none`. When it closes its epic, it takes one full run (`closes epic`) unless a full run's recorded snapshot, the baseline's included, matches a fresh snapshot: the code is then the code that run covered. Every rerun after a fix for a story that is full for one of the reasons in the list above, or after an order-dependent failure, is full; any other story's fix rerun is its targeted set, the fix's tests, the tests that run any newly changed code file and every test that failed in the previous run, and is full when the fix itself has wide reach.

## Wide reach

- a migration or schema;
- a dependency manifest or lock file;
- config, environment and test-runner config (`phpunit.xml`, `.env.testing`, the jest or vitest config);
- shared test setup (the base test case, `Pest.php`, `conftest.py`), fixtures, factories and seeders;
- boot-time registration and route files, console routes included (service providers, container bindings, `bootstrap/`);
- anything the framework wires by convention or by a string rather than an import: event listeners, observers, policies and gates, middleware, layouts and view components, translations, scheduled and console commands, model events and global scopes;
- a change to what callers can observe (signature, return value, side effects, thrown exceptions) of an existing symbol that more than one non-test file uses, found by a grep for its qualified use (`Class::method`, `->method(` on that type), not the bare method name.

A symbol added that nothing uses yet is not wide reach.

## Exempt files and the snapshot

Exempt files, by kind, are the epic doc, the `docs/quick/` record, and prose (Markdown and plain text) that no code, test, test config or build config reads. Every code, config, fixture, test, view, template, translation or asset file is a code file and makes a run stale.

After each run `do` takes a snapshot, whose first line is `git rev-parse HEAD` (`no commit` when there is none) and whose other lines are every changed and untracked, not ignored, non-exempt path (from `git diff HEAD --name-only` and `git ls-files -o --exclude-standard`, against the empty tree when there is no commit) as a `{path} {blob hash}` line (`git hash-object`; `deleted` for a path that no longer exists), the lines sorted and hashed together with `git hash-object --stdin` to one `{hash}`. A file a run writes that git does not ignore is part of the snapshot but is test output, not story work: it is neither a changed code file for the targeted set and the `untested` trigger nor a reason a story is not `none`, and one that a red pass rewrites makes the result stale, so a project ignores it. The baseline's snapshot is noted when the baseline is taken and kept for the run. A result stands while a fresh snapshot hashes the same; a second edit to a file already changed at the previous run changes it. A snapshot that was not recorded, or no longer matches, never stands.

## A failing targeted run

A targeted run that fails or errors in a test the story did not add or change, and that passed at the baseline, is followed by a full run before any fix. A test that failed at the baseline is left out of this.

- The full run fails too: fix it, and every rerun includes each test that failed in the previous run.
- The full run passes: run the targeted set once more. A pass names the test under **Found** as flaky. A second failure names it as order-dependent under **Found**, and the story's runs are full until it closes (`order-dependent: {test}`).

A failure in a test the story added or changed is fixed without a full run.

## Reasons a full run records

`closes epic`, `small change`, `wide reach: {file} ({entry})`, `untested: {file}`, `deleted: {file}`, `renamed: {file}`, `targeted failure: {test}`, `order-dependent: {test}`, `sibling Story {n}`, `merge conflict`, `audit: run too narrow`.

For a targeted run the line records each changed code file and the tests that run it (directories or globs allowed for a long set), and the auditor checks that mapping against the test tree.
