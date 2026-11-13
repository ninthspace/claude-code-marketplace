---
name: do
description: Build from CPM epic documents until every story in scope is Complete and the tests pass — one story, one epic, one spec's epics or all remaining epics unattended — or carry out a small change directly when there is no epic. Picks the next unblocked work, implements it, verifies each acceptance criterion with evidence, and keeps the epic doc as the live task list. Use whenever the user wants planned work built, continued or finished, or a small well-defined change made. Triggers on "/cpm-next:do".
model: opus
effort: medium
---

# Do

Build what the epics describe, and prove it. The epic doc is the task list and the run's only state, read by the user, a compacted context and the next session, so keep it current as you go. Formats, status vocabulary and the unblocked-story rule are in `shared/artifacts.md`, two levels above this skill's directory; read it before the first story.

## Scope and finish line

Read `$ARGUMENTS`:

| Argument | Scope | Done when |
|---|---|---|
| epic path | that epic | all its stories are Complete |
| story or task ID (`3`, `2.1`) | that item, in the epic the last row picks | that item is Complete |
| `all` | every unfinished, unretired epic, in dependency order | no unblocked story remains |
| `all {spec}` (`all 43`) | the same, limited to epics whose prefix starts with that spec number; stop before building if there is none | no unblocked story remains in those epics |
| a description of a small change | no epic | the change works and is tested |
| nothing | the lowest-numbered In Progress epic with an open story that is unblocked, isn't marked blocked and isn't waiting on the user; else the lowest-numbered epic with nothing started whose `**Blocked by**` epics are all Complete and that has such a story; stop before building if there is none | that epic's stories are Complete |

Unblocked, marked blocked and waiting on the user are the contract's terms (**Status vocabulary**, **Evidence against each criterion**), step 3 saying which criteria are treated as `[user]`; a story waiting on the user counts as done for the finish lines above.

`--parallel` and `--parallel check` may follow any scope but a small change (see **Worktree mode**); `--parallel check` builds nothing and writes nothing.

The baseline is one full run of the project's suite before anything changes. Each story's runs after it are decided by `shared/test-runs.md` (beside the contract) and recorded in its `**Test run**` line, and that file says when a result stands. The run is done when every story it closed closed on a passing run of its kind and every epic it closed closed on a passing full run; a failure left in the suite must have been failing at the baseline, or be one `test-runs.md` (**An open story's independent tests**) leaves to its story. A run that closes no epic takes a full run only where `test-runs.md` calls for one.

For a small change, write the `docs/quick/` record before any code: without written criteria, neither the build nor the audit can tell that part of the change is missing.

- Read what **Before the first story** lists that bears on the change (its first bullet always), and the code it touches, then give the record acceptance criteria in the contract's story format for everything the description asks, at each place the same fault or feature occurs, with a tagged test for each criterion code can prove.
- Write must-not, must-not-change and never criteria as the **Epics** section of `skills/plan/SKILL.md` (beside this skill's directory) says, reflect bearing lessons as its **Lessons** section says, and tag and route each criterion as step 3 does.
- Where two reasonable readings of the description and code would build different things, show the user the criteria and ask which they mean, in one message, before building; otherwise don't ask.
- If the criteria exceed one story's work, stop before building and suggest `/cpm-next:plan`; otherwise build it as one story through the steps of **The loop**, its `Evidence`, `**Test run**` and `**Audit**` lines in the record in the contract's forms, which the auditor checks as the story.
- A record carrying either `**Audit**` form is resumed as a story is.

## Before the first story

- Restore what a stopped red pass left, before the baseline and any other work, in every run, a small change included. For every directory under `{git common dir}/cpm-next/scratch/` (found as **Scratch directories and isolation** says):
  - one whose `tree` file equals the output of `git rev-parse --show-toplevel` run now, whatever its story or quick record: copy its files back to their repository paths (not its `manifest` and `tree` files), delete the directory by its literal, quoted absolute path and remove its `**Scratch**` line;
  - delete a directory with no `tree` file (its pass stopped before copying anything), and one whose `tree` no longer exists, naming the latter under **Found**;
  - leave one whose `tree` is another existing checkout to that checkout.
  - Remove a `**Scratch**` line whose directory is gone and lay under the common directory (the pass was interrupted after its deletion); a line that names a path outside it (a directory in a session scratchpad) stops the story and goes under **Needs you**, since its files may still be mutated.
- Clear stale round records: a story's record directory (**Audit rounds**) whose `tree` is this checkout and whose story is `Complete`, no longer exists, or lies in a `Withdrawn` or `Superseded` epic is deleted as **Audit rounds** says, and named under **Found**; one whose `tree` is another existing checkout is left to it, and one whose `tree` no longer exists, or that has no `tree` file and so no record, is deleted.
- Read `CLAUDE.md`, `docs/library/`, the epic, its source spec and the ADRs it cites; read the library lessons, the signals that recur (the contract's **Signals**) and the unretired legacy retro observations (bullets under a retro's `## Observations` with no `**Retired` marker) that bear on the epic's area.
- Find the test command (library, `composer.json`, `package.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`) and run the full suite for the baseline, noting its snapshot, unless an earlier full result stands.
- A failing test at the baseline that a story with a `full run due` or `fix due` `**Audit**` line explains is that story's regression (`test-runs.md`, **The deferred full run**). A failing test at the baseline that a story closed on a targeted run in an In Progress epic explains is not accepted as pre-existing: it is fixed in the next story this run builds in that epic, named in that story's audit prompt with the failing test, or, when this run builds none there, listed under **Needs you** with the test and the story, with a signal. A baseline failure no such story explains is pre-existing, unless `test-runs.md` (**An open story's independent tests**) gives it to an open story.
- If the scope holds a `[browser]` criterion (for a small change, once its record is written), `browser.md` says whether to take its browser probe before building (`browser.md` in this skill's directory, read when the scope holds a `[browser]` criterion, an `**Amended**` line's included; read it again if it is not in context).
- Resume honestly: a story `In Progress` from an earlier session may be partly done, so check the code before redoing or skipping anything.
  - A story marked blocked is not resumed until the user settles the blocker: list it under **Needs you** with its reason.
  - If every criterion has an `Evidence` line, confirm the evidence holds, take a red pass (step 4) for each test-proven criterion that has neither a red nor an `existing` reason, take its step 4 run first unless its own `**Test run**` line still stands (`test-runs.md`, **Exempt files and the snapshot**), audit the story if it has no `**Audit**` line, its count continued as **Audit rounds** says, and close it as step 6 says, before other work.
  - A story whose `**Audit**` line carries `full run due` takes its deferred full run as `test-runs.md` (**The deferred full run**) says.
  - A `fix due` story finishes its fix, takes the fix rerun and retakes in a red pass every red of the story taken in one and the fix's red (which files the fix touched cannot be known from the record, so a recorded `— deferred full run, before the fix` red is retaken too), then is audited as a whole story, the prompt naming as **Audit**'s fixes outside the story, as candidates, every file outside the story's files that no other open story's `**Test run**` mapping lists and that is changed or was changed by a commit made on or after the `**Audit**` line's date (from 00:00 that day), with the failing tests the `**Audit**` line names and the fix's red when it belongs to no criterion, that audit standing as its scoped round, before its deferred full run.

## The loop

Take unblocked stories, as the contract defines them, lowest number first. A story `do` closes is `Complete` only in the edit that writes its `**Audit**` line (step 6), so the fixes from its audit, which would rework code built on top of it, are made before its dependents start. Each story goes through these steps, wherever it is built:

1. Set the story, and the epic if it was Pending, to `In Progress`. Call `mcp__cpm-next-models__set_story_effort` with the story's number and `**Effort**` (`medium` when it has none); without that tool, build at the session's effort. A story whose `**Independent tests**` line reads `due` then takes **Independent tests** (`independent-tests.md` in this skill's directory, read when a story in scope has an `**Independent tests**` line other than `skipped`; read it again if it is not in context) before any of its code is written.
2. Build it task by task, setting each task `In Progress` as you start it and `Complete` when done; in a worktree build, whose subagent leaves the epic doc alone, the lead sets the tasks `Complete` in the closing edit (step 6), none passing through `In Progress`. Follow the project's existing conventions over your own preferences. In a Laravel project, run the `laravel-simplifier` agent over the story's changes, if available, before verifying.
3. Verify every acceptance criterion with the tests its tag names, or with the manual check and what you observed, in an `Evidence` line as the contract shows. A criterion without its own evidence isn't met.
   - `[browser]`: checked as `browser.md` says (`browser.md` in this skill's directory, read when the scope holds a `[browser]` criterion, an `**Amended**` line's included; read it again if it is not in context).
   - A criterion an independent test proves cites it as **Independent tests** says (`independent-tests.md` in this skill's directory, read when a story in scope has an `**Independent tests**` line other than `skipped`; read it again if it is not in context), and a red held from the pre-build run is written into its `Evidence` line here.
   - `[user]`, and any criterion you can't carry out in the session whatever its tag (a deploy, a production run, a sign-off), is treated as `[user]`: never claim it as met, list it under **Needs you**, and write its `Evidence` line only from the user's own answer, never in a run with no user present. Give it the contract's `- Waiting on user: {steps}` line where the contract calls for one.
4. Check the story as the auditor will, before the audit, in this order:
   - Feed the new code inputs it doesn't expect (empty, missing, null, non-numeric, boundary, records that collide on an attribute that is not their key, the same identity twice in one delivery), and read every help text, doc and `Evidence` line the story touched against the code. Fix what either shows.
   - Read `shared/test-runs.md` and decide the story's run by it, run it, write the `**Test run**` line and fix what it shows, rewriting the line and running again after any change to a non-exempt file until a run needs no fix. That file also says when a story closes its epic, what a story whose diff holds no non-exempt file takes, and what a failing targeted run leads to, in this step and step 5.
   - Take the reds, in one red pass, once no edit to the story's files remains to be made, after the simplifier pass and against the code being closed. A red is required for every test-proven criterion (the contract's term), except one recorded `existing` on the contract's terms. An independent test whose held `before the build` red stands takes none either (**Independent tests** says when one is dropped: `independent-tests.md` in this skill's directory, read when a story in scope has an `**Independent tests**` line other than `skipped`; read it again if it is not in context). The builder takes the pass in a single build; in a one-checkout parallel batch, the lead's subagent after the batch, as the parallel rules say; in worktree mode, whoever `worktree.md` says.
   - The red pass: create the pass directory, new and empty, at the path the contract's `**Scratch**` field gives, and write its path in a `**Scratch**` line under the story (a worktree subagent skips the line). Write a `manifest` in it, each changed or untracked, not ignored, path with its blob hash (from `git diff HEAD --name-only` and `git ls-files -o --exclude-standard`, hashed with `git hash-object`, a path that no longer exists recorded as `deleted` and not hashed, leaving out the epic doc or `docs/quick/` record, which the pass edits, and diffing against the empty tree when the repository has no commit), and a `tree` file holding the output of `git rev-parse --show-toplevel`.
   - Copy each file the pass will change into the directory at its repository path, once, before its first mutation.
   - Take each red by undoing the lines the cited test covers with the Edit tool and running only that test. Where that leaves it green (a refactor, a characterisation test, code the story didn't change) or makes it error, copy the file back and mutate a covered line instead, which may lie outside the story. The failure must come from the cited assertion: an error (missing class, method, route or table) doesn't count, and a stub that returns a wrong value does.
   - Note the failure text and the undone `{file:lines}` or the mutation, then copy each file back from the pass directory. Never revert with `git checkout`, `git show … >`, `git stash` or `reset`, which take uncommitted work with them.
   - When the last red is taken, recompute the manifest and compare it with the first.
   - On a match, delete the pass directory by its literal, quoted absolute path (never the `scratch/` folder itself, and never a glob) and remove the `**Scratch**` line; only then write each noted red into its criterion's `Evidence` line as the contract shows (a retaken red replaces the earlier one), and a criterion no test proves, or that takes `existing`, records `red: n/a` with its reason. The result from before the pass stands for the audit; re-run no test.
   - On a mismatch, first copy back every path that has a copy in the pass directory (not `manifest` and `tree`) and differs from it, listed or not, and compare again. A path that was not listed and is now untracked is test output: name it under **Found** and leave it, and count the manifest as matching once nothing else differs. Any other difference, or one that remains (a listed path with no copy, such as a tracked file the test run rewrote), marks the story blocked (the contract's note with the paths, and a signal) and lists it under **Needs you**; the pass directory and the `**Scratch**` line are then removed as above.
5. Have the story audited (see **Audit**).
   - On `fix needed`, set the fix's effort with the same tool (`high`, or `xhigh` for a story already at `high`), fix every Critical and Warning finding wherever its mistake occurs, not only where cited (**Independent tests** says which findings on an independent test are disputes, which no fix answers: `independent-tests.md` in this skill's directory, read when a story in scope has an `**Independent tests**` line other than `skipped`; read it again if it is not in context), and give each fix a test, its red recorded in the `Evidence` line of the criterion the finding concerns or, for a finding with no criterion, in the findings list handed to the next audit.
   - Update the `Evidence` lines the fix affects, and check the fix as new code as step 4 says, so the next audit has the run for the code as it stands (a fix rerun is the one `test-runs.md` gives); a fix that changes a file a red mutated, or a red's test file, retakes that red in a new pass.
   - A Warning that the run was missing or too narrow is settled by making the run, which needs no test and no red and, when full, records the reason `test-runs.md` (**Reasons a full run records**) gives: when it passes, that finding is fixed and needs no further round of its own, and only a failure it shows is fixed through this step.
   - A Warning that the prompt named no deferred full run for a story that needs one (`test-runs.md`) is settled by writing the `full run due` suffix on its `**Audit**` line, with no fix round.
   - Then audit again. The rounds go on as **Audit rounds** (below) allows; when the last of this step's rounds still returns `fix needed`, record each unresolved finding in a `Not met` line under the criterion it concerns, or as a signal when it concerns none, and treat the story as blocked (see **Signals**).
   - When the last audit passes for a story that needs a deferred full run, write its `**Audit**` line with the contract's `full run due` suffix and take the deferred full run, and act on a failing one, as `test-runs.md` (**The deferred full run**) says.
6. Close the story in the same edit that writes its `**Audit**` line: set any remaining tasks and the story's `**Status**` to `Complete`, and the epic's too if it was the last open story. A story with a deferred full run due closes only on that run's pass as `test-runs.md` defines it, in the edit that rewrites its `**Audit**` line without the suffix (a scoped round counted in `n findings fixed`).

Before the next story, re-read the one just finished in the epic doc: it must be `Complete` with an `**Audit**` line, be marked blocked as the contract says, with a `Not met` line under any unmet criterion, wait on the user, or carry a `full run due` or `fix due` `**Audit**` line while it waits for its batch's shared deferred full run or its scoped round, since an evidenced story left `In Progress` blocks its dependents.

Stories unblocked together are built in parallel, one subagent each, when they share neither files nor runtime state (databases, migrations, dependency installs and lock files, cache and queue state, storage directories, `.env`, ports), judged from the files their tasks name and the code they touch; otherwise, or when the user is working alongside you on a single story or task, one at a time. The lead owns everything shared:

- It runs migrations, dependency installs and every test run after a batch: the union of the stories' targeted sets, and the batch's shared deferred full run (`test-runs.md`'s **A batch** gives the rules, and its **When the run is full** says when a story closes its epic). A story that needs a schema or dependency change goes first, run by the lead, before any fan-out.
- In a one-checkout batch, a subagent writes code only and runs no tests, whatever the suite's isolation, since its siblings are writing code in the same checkout (a worktree subagent's runs are `worktree.md`'s). A red pass handed to it, below, is the one exception.
- A subagent leaves `[browser]` criteria to the lead, who checks them after the batch.
- Once the batch has finished and nothing else is running, the lead hands each story's red pass (step 4) to a fresh `opus` subagent, one at a time:
  - giving it the story, the cited tests, the pass directory's absolute path, the absolute path of the contract and the absolute path of this file for step 4's rules on taking each red;
  - the lead creates the pass directory, the `**Scratch**` line, the `manifest` and the `tree` file before the hand-off;
  - the subagent copies files into the directory, takes and restores each red, and reports each failure with its `{file:lines}` or mutation, and does not create, compare or delete the directory or touch the epic doc;
  - the lead then compares the manifest itself, deletes the directory, removes the line, and writes the `Evidence` lines from the reported failures after checking each against the test file.
  - No pass runs while batch siblings run, since the pass's tests would run a sibling's half-written code and a sibling could read or edit a file the pass has mutated.
- A subagent has none of this conversation, so its prompt names the resources it must leave alone.
- A subagent building a story with independent tests, in either build mode, is given **Independent tests**' builder's limits and dispute route (`independent-tests.md` in this skill's directory, read when a story in scope has an `**Independent tests**` line other than `skipped`; read it again if it is not in context) in its prompt, with the files on the story's line; it carries a dispute to the lead in its report, and the lead writes the story's held reds into their `Evidence` lines when it checks that report.
- The lead checks each report against the files and test output before the story goes to audit, and makes every audit fix, in its own checkout.

Start each parallel subagent on `opus`, and a `**Model**: haiku` story on a `haiku` subagent even when nothing runs beside it.

Hand plain lookups (where something is defined or used, which files a change touches, what a read-only query returns) to the `cpm-next:scout` agent, which keeps search output out of this conversation; read the code yourself when the answer depends on understanding it.

Leave commits, branches and pushes to the user unless they've said otherwise. Asking for `--parallel` is their leave to commit and merge locally on the current branch, never to push.

### Independent tests

This section is `independent-tests.md`, in this skill's directory: read it when a story in scope has an `**Independent tests**` line other than `skipped`, and read it again if it is not in context.

### Audit rounds

How many audits step 5 makes, when they stop, and the record that counts them.

- **The cap.** At the end of each audit, the run is unattended when **When to stop and when to keep going** says so; an audit made during **Finishing** is attended. In an attended run a second audit that returns a Critical gets a third, saying in one line why; otherwise the second is the last, and a third, or any audit after it, always is. In an unattended run a story is audited up to five times, and the fifth is the last. An audit whose findings all fail the lead's check is a pass. Each audit after the second says in one line its number and, in an unattended run, the stop tests' results.
- **A whole-story audit after a pass.** A story that passed and must be audited again as a whole story (a snapshot mismatch before the deferred run, `test-runs.md` **The deferred full run**; a worktree sibling's fix, **A batch**) is always audited, and that audit counts. Its `fix needed` is fixed and audited again while the count is under the run's cap (five unattended, three attended), whatever **The cap** says of a second or third audit; at or past the cap that audit is the last. A resumed `fix due` story's whole-story audit is not one of these: it is its scoped round, and its `fix needed` blocks the story (**Before the first story**).
- **The stops.** In an unattended run, from the third audit on, the rounds end with that audit as the last when either test holds, both read over findings that held after the lead's check:
  - **Repeat**: a finding that held and was fixed in two earlier rounds holds again, at the same file and symbol or criterion; a new place the earlier finding covered is not a repeat, nor is a dismissed finding raised again.
  - **Rising count**: the audit's held Critical and Warning findings outnumber the previous audit's, both audits scoped to the findings before them, so a whole-story audit is compared with neither neighbour.
  - Neither test counts a `missed earlier` Critical, a Warning settled by making a run or writing the `full run due` suffix, a finding routed through **When a criterion looks wrong**, or a disputed independent test the writer kept.
  - A stop's name is appended to the story's signal of the tripping finding's class, since **Signals** writes one per class per story.
- **The record.** After each audit these rounds count, the lead writes `{git common dir}/cpm-next/rounds/{epic file stem}-{story}/r{n}` (`quick-{nn}/` for a small change; the common directory as **Scratch directories and isolation** finds it), `{n}` the audit's number: the findings as the auditor wrote them, the lead's verdict on each (held, or dismissed with the reason) and the stop tests' results.
  - The story's count is the number of records. The scoped round of a failing deferred full run, and a resumed `fix due` story's scoped audit, write none and are not counted. A resumed story, a whole-story audit and a story settled at **Finishing** continue the count from the records.
  - The directory also holds a `tree` file with the output of `git rev-parse --show-toplevel`, written before its first record, since every checkout of the repository shares the folder.
  - After the closing edit or the blocked note the lead appends the story's epic, number and count to a `rounds` tally in the run directory; after the closing edit it then deletes the record directory by its literal, quoted absolute path (never the folder that holds every story's records, and never a glob), and a blocked story keeps it.

### Worktree mode

With `--parallel` or `--parallel check`, read `worktree.md` in this skill's directory before building, and follow it: it says which stories a worktree batch may hold, when a worktree's test results count, what each subagent's prompt adds, how the lead merges, and what `--parallel check` reports.

Without `--parallel`, stories that share neither files nor runtime state are still built in parallel; the flag is never needed for them. When unblocked stories that rule keeps apart are waiting, read `worktree.md` and check them as `--parallel check` would, without the report. If a batch qualifies, say so in one line with the next tool call, naming the stories, what they share and `/cpm-next:do {scope} --parallel`, carry on one at a time, and repeat the line under **Found**. Don't switch to worktree mode unasked, since it commits.

### Scratch directories and isolation

At the start of a run, make a run directory under the session's scratchpad, or with `mktemp -d` when there is none. Inside it the lead creates, and passes by absolute path, a fresh auditor directory per audit round (`audit-{epic}-{story}-r{n}`, or `audit-quick-{nn}-r{n}`, `{n}` the audit's number in **Audit rounds**; a scoped round's is `audit-{epic}-{story}-s{n}`, or `audit-quick-{nn}-s{n}`, `{n}` counting the story's scoped rounds), and a fresh writer directory per test-writer it starts (`writer-{epic}-{story}-{n}`). No two agents share one. A red pass's directory is not there: it is the one the contract's `**Scratch**` field names, the common directory found with `git rev-parse --path-format=absolute --git-common-dir`, so it outlives the session and every worktree of the repository shares it. If that path already holds a directory whose `tree` is another checkout (an abandoned worktree's), the pass does not run: mark the story blocked with the reason and a signal.

A suite is isolated when every test process, including a single run without a parallel flag, gets its own database and its own copy of every file tests write (fake disks, SQLite database files, file caches, compiled views, result caches), and no test binds a fixed port. Check this once per run, before the first fan-out or audit, from the test config and a few tests, whatever the build mode.

A red pass may run while an audit runs only when it mutates no file the audited story changed and that auditor was told to run no tests and no probes, scope being judged from the file list the auditor was given. Audits that run tests may run together in an isolated suite, since no code changes while they run: no code is written in the checkout (an audit fix, a story's build, a test-writer's files) while a test-running audit runs. Apart from those audits, two test runs, full or targeted, never overlap in one checkout, and a red pass never runs beside any test run.

## Audit

Start the `auditor` agent with the Agent tool, `subagent_type` `cpm-next:auditor`. One auditor checks one story, with no limit on its length and nothing in its checklist narrowed, since a shared or capped audit leaves findings for the next round. It has none of this conversation, so give it:

- the epic path and story number, or the `docs/quick/` record;
- the files the story changed, or a worktree story's merge commit;
- the files on the story's `**Independent tests**` line, in every build mode;
- the baseline result of each test an `existing` reason cites, when the run holds it, or that it holds none;
- the test command, the story's `**Test run**` line, the path of `shared/test-runs.md` and the result of the run made after the story's last change (counts, and any failing test). A targeted run's tests are listed as the run's coverage, not for the auditor to run; the result covers every test it lists, which the `Evidence` lines cite, so the auditor reads the tests and their recorded red results and runs none to reproduce a red. For a story that needs a deferred full run, that the full run follows the audit, or that a full run before it stands for it, with its reasons;
- the fixes made outside the story's files to answer a failure a run or the baseline showed, each with the test whose failure it answers;
- when the story took a red pass, that the pass ended with a matching manifest;
- the absolute path of the contract (`shared/artifacts.md`, resolved from this skill's directory);
- its auditor directory, for probe scripts, test output and `TMPDIR`;
- whether the suite is isolated or free; in a suite that is neither, the auditor runs no tests and no probes and works from the tests and the run result it was given. The lead may say an unisolated suite is free only when it will wait for that audit in the foreground and make no test-running call, start no red pass and start no other test-running audit until it reports;
- the resources it must leave alone.

Audits of stories that share no files may run in parallel, isolated suite or not; those that run tests do so as **Scratch directories and isolation** says. A later audit also gets the previous audit's findings as it wrote them, which you dismissed and why, every finding dismissed in a round before that with its reason (from **Audit rounds**' record), and the files the latest fix changed, but no description of the fixes: it audits the fix code as new code. A whole-story audit gets the dismissed findings only, as ones not to raise again, so its scope stays the whole story; so does a resumed story with round records, given every recorded dismissal, since no record holds a fix's files. A scoped round gets the prompt `test-runs.md` sets out in place of findings, except a resumed `fix due` story's, which is a whole-story audit given every recorded dismissal.

Check each finding against the code before acting on it, and drop any that don't hold up; **Independent tests** says which findings on an independent test are disputes (`independent-tests.md` in this skill's directory, read when a story in scope has an `**Independent tests**` line other than `skipped`; read it again if it is not in context). Suggestions are neither fixed nor recorded. A finding that contradicts the criterion rather than the code goes through **When a criterion looks wrong**.

Record the outcome as `**Audit**: pass ({YYYY-MM-DD})`, adding `, {n} findings fixed` when the first audit returned `fix needed` (a scoped round counts too), and for a story that needs a deferred full run the contract's `full run due` suffix. If the `auditor` agent isn't available, write `**Audit**: skipped — auditor unavailable` and say so under **Found**.

## Signals

Write a `**Signal**` on the story, or in the `docs/quick/` record (form, slug rule and version in the contract's **Signals**), when an audit finding holds, when you mark a story blocked (step 5, **When to stop**), and when you write an `**Amended**`, `**Inline change**` or `**Pivot deferred**` line (**When a criterion looks wrong**): one per class per story. Before choosing a slug, grep the `**Signal**:` lines in `docs/epics/`, `docs/archive/epics/` and `docs/quick/`, the library's `**Class**` lines and the contract's seed slugs for one to reuse.

After writing each signal, separately, check whether it recurs. Look in this order: a library lesson with that `**Class**` (or, for a lesson with none, one that describes the failure); a signal with that slug in a different epic or quick record, `docs/archive/` included; an unretired legacy retro observation (read them once per run or, with more than 20 retro files, have `scout` list those matching the signal's terms). Read both to confirm they describe the same failure, and on a match append ` — recurs: {reference} ({why it matches, one clause})`. A match within the same epic is not a recurrence. A rejected `**Class**` or signal match gives the signal a different slug, matched once more under it; after a rejected description match, carry on down the order.

Route a recurrence by its kind:

- A `project` signal that recurs with no library lesson, none of whose matches carries a ` — declined` or ` — promoted` mark, goes under **Needs you** with the matching signals and the constraint proposed (the rule, how a criterion or check shows it holds, and the owning layer), and is marked ` — raised {YYYY-MM-DD}`.
- A signal matching a declined one is marked as the contract's **Signals** says, and not raised.
- A `process` signal, and a signal that recurs against a library lesson, go under **Found** only.
- A signal that matches a candidate still waiting for its answer, or any signal listed with or joined to it, whatever its epic, joins that candidate instead of becoming another, and is marked ` — raised` too.
- One that matches an answered candidate takes its answer: declined after a no, whatever the epic, and after a yes a recurrence against the new lesson, under **Found**.

## When to stop and when to keep going

A message without a tool call ends the turn, and the work stops until someone replies. While stories in scope remain open, don't end a turn on a progress summary announcing a next step you haven't taken, an offer to carry on, a list of decisions none of which blocks the remaining work, or a report because a story finished or the turn ran long. Put status notes and recommendations in the message with the next tool call, and carry on with whatever doesn't depend on an answer.

Stop and ask only when:

- a test fails for a reason you can't explain after investigating it;
- a criterion contradicts reality and resolving it would change scope (below);
- the next action is destructive or reaches outside this repository: deleting data, rewriting history, touching shared infrastructure.

In an `all` run, with or without a spec, or whenever the user has said they won't be watching, don't stop for the first two: mark the story blocked with the reason (and a signal), and move on to other unblocked work. The third always stops the run.

A story isn't finished while a subagent or background command it started is still running: wait for its output and check it.

## When a criterion looks wrong

A criterion that is hard to meet is not wrong. "The tests fail", "this approach didn't work" and "it's slower than the target" are reports about this implementation, and never justify changing the criterion: leave it standing, mark the story blocked, and record what was tried in a `Not met` line under it, with a signal.

A criterion is wrong only when you can cite what contradicts it: a `file:line`, a named spec requirement (`FR3`, `AD1`), or another criterion in the same epic that can't be satisfied at the same time.

- A wording fix with no change of scope: edit it and add an `**Inline change**` line, with a signal.
- A change of scope, with the user present: ask, showing the citation.
- A change of scope in an unattended run: amend the criterion in this epic only, with an `**Amended**` line carrying the citation, and add a `**Pivot deferred**` line for each upstream document that still disagrees with the amended criterion. Leave the spec and every other document untouched; `plan` resolves those later with the user.

## Finishing

End every run with three headings, in this order:

- **Needs you**: only what won't happen unless the user acts, each line naming the action and what it unblocks: a decision only they can make, a blocked story and what would unblock it, a `**Pivot deferred**` item (with `/cpm-next:plan {path of the upstream document}`), a promotion candidate, a `[user]` criterion of a story waiting on the user, with its steps, a destructive step you held back from, and any step outside the repository the change depends on (a migration on a deployed database, a secret or environment value, a service to restart). Leave out optional follow-ups, things worth a look and anything already done; say "Nothing" if so.
- **Changed**: stories completed, the main files touched, how many full and targeted runs the run made (the baseline and each story's `**Test run**` counts, a shared deferred run counted once), each story's last result, each story's audit count from the run directory's `rounds` tally (**Audit rounds**), and any failure left with whether it failed at the baseline.
- **Found**: anything surprising about the codebase, the plan or the tests, and each story that passed at its fourth or fifth audit or was stopped by a stop test. Nothing here asks the user to act; an action it implies goes under **Needs you**.

When the run leaves a spec finished (every one of its epics `Complete`, or open only for stories waiting on the user), add one line after the headings suggesting `/cpm-next:library sweep`, which looks across repositories for failures a cpm-next rule could have prevented; when `~/.claude/cpm-next/repos.txt` does not list this repository, suggest `/cpm-next:library sweep add {its path}` first. It is a suggestion, not a **Needs you** item.

Then take the **Needs you** items one at a time, the one blocking most work first. For each, say in a few lines what it is and where (`file:line`, or the epic and story), what each way of settling it leads to, and which you recommend and why. Ask with one AskUserQuestion call holding that one question, your recommendation as the first option and `Leave it for now` as the last, and act on the answer before raising the next item:

- a criterion the user changes: amend it with an `**Amended**` line citing their decision, and clear its `Not met` line, and the story's blocked note once the contract says it comes off;
- a destructive step they approve: carry it out;
- a step outside the repository: give the exact steps, and ask only when what you do next depends on it being done;
- a `**Pivot deferred**` item: recommend `/cpm-next:plan`, and leave the upstream document to it;
- a promotion candidate: on a yes, write the lesson as an entry in the library's `lessons-learned.md` (an existing file ending in `lessons-learned.md` counts) in the contract's form, unless the library already holds it (a match as the contract's **Library document** says); create the file with its front-matter when missing, and update the front-matter as the contract's **Library document** says, leaving an existing file's header alone when it has no front-matter; then mark the candidate, each signal it matched and each signal that joined it ` — promoted {YYYY-MM-DD}`. On a no, mark them ` — declined {YYYY-MM-DD}`. Write no amendment to any other library document: `library learn` does that;
- the `[browser]` criteria that fell back to the user (step 3): as `browser.md` says (`browser.md` in this skill's directory, read when the scope holds a `[browser]` criterion, an `**Amended**` line's included; read it again if it is not in context);
- a `[user]` criterion: ask for the result of its steps. On success, write its `Evidence` line in the contract's `[user]` form, and once no criterion in the story lacks `Evidence`, take step 4 for the story, audit it, take its deferred full run if it needs one, and close it as step 6 says; on failure, write a `Not met` line and mark the story blocked with the contract's note;
- a blocked story: once the user settles the blocker (a decision, a fix, or an amended criterion), clear its `Not met` lines for what is settled, and its note as the contract says, then resume the story through the loop.

An item left for now stays recorded where it is. Once the last item is settled, build the stories the answers unblocked through the loop, and end that run with the three headings again.
