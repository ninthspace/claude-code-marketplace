---
name: do
description: Build from CPM epic documents until every story in scope is Complete and the tests pass — one story, one epic, one spec's epics or all remaining epics unattended — or carry out a small change directly when there is no epic. Picks the next unblocked work, implements it, verifies each acceptance criterion with evidence, and keeps the epic doc as the live task list. Use whenever the user wants planned work built, continued or finished, or a small well-defined change made. Triggers on "/cpm-next:do".
model: sonnet
effort: medium
---

# Do

Build what the epics describe, and prove it. The epic doc is the task list and the run's only state, read by the user, a compacted context and the next session, so keep it current as you go. Formats, status vocabulary and the unblocked-story rule are in `shared/artifacts.md`, two levels above this skill's directory.

## Scope and finish line

Read `$ARGUMENTS`:

| Argument | Scope | Done when |
|---|---|---|
| epic path | that epic | all its stories are Complete |
| story or task ID (`3`, `2.1`) | that item, in the epic the last row picks | that item is Complete |
| `all` | every unfinished, unretired epic, in dependency order | no unblocked story remains |
| `all {spec}` (`all 43`) | the same, limited to epics whose prefix starts with that spec number; stop before building if there is none | no unblocked story remains in those epics |
| a description of a small change | no epic | the change works and is tested |
| nothing | the lowest-numbered In Progress epic with an open story that is unblocked, isn't marked blocked (no `Not met` line or ` — blocked:` note) and isn't waiting on the user; else the lowest-numbered epic with nothing started whose `**Blocked by**` epics are all Complete and that has such a story; stop before building if there is none | that epic's stories are Complete |

A story is waiting on the user when it is unblocked, isn't marked blocked, at least one criterion lacks `Evidence`, and every such criterion is `[user]` or treated as `[user]` (step 3). It is skipped when picking work, and counts as done for the finish lines above.

`--parallel` and `--parallel check` may follow any scope but a small change (see **Worktree mode**); `--parallel check` builds nothing and writes nothing.

The full suite must also pass at the end, or every failure left must have been failing before the run, so record the baseline before changing anything. A full-suite result already in this conversation stands for the baseline or the end-of-run check while `git status` and `git diff` show no file changed since.

For a small change, write the `docs/quick/` record before any code (signals found while building it go there too): without written criteria, neither the build nor the audit can tell that part of the change is missing. Read what **Before the first story** lists that bears on the change (its first bullet always), and the code it touches, then give the record acceptance criteria in the contract's story format for everything the description asks, at each place the same fault or feature occurs, with a tagged test for each criterion code can prove. Write must-not, must-not-change and never criteria as the **Epics** paragraph of `skills/plan/SKILL.md` (beside this skill's directory) says, reflect bearing lessons as its **Lessons** paragraph says, and tag and route each criterion as step 3 does. Where two reasonable readings of the description and code would build different things, show the user the criteria and ask which they mean, in one message, before building; otherwise don't ask. If the criteria exceed one story's work, stop before building and suggest `/cpm-next:plan`; otherwise build it as one story through steps 2 to 5 of **The loop**, with the `Evidence` lines and the audit verdict in the record, which the auditor checks as the story.

## Before the first story

- Restore what a stopped red pass left, before the baseline and any other work, in every run, a small change included. For every directory under `{git common dir}/cpm-next/scratch/` (found as **Scratch directories and isolation** says) whose `tree` file equals the output of `git rev-parse --show-toplevel` run now, whatever its story or quick record: copy its files back to their repository paths (not its `manifest` and `tree` files), delete the directory by its literal, quoted absolute path and remove its `**Scratch**` line. Delete a directory with no `tree` file (its pass stopped before copying anything), and one whose `tree` no longer exists, naming the latter under **Found**; leave one whose `tree` is another existing checkout to that checkout. Remove a `**Scratch**` line whose directory is gone and lay under the common directory (the pass was interrupted after its deletion); a line that names a path outside it (a directory in a session scratchpad) stops the story and goes under **Needs you**, since its files may still be mutated.
- Read `CLAUDE.md`, `docs/library/`, the epic, its source spec and the ADRs it cites; read the library lessons, the signals that recur (a `**Signal**` with a ` — recurs:` suffix) and the unretired legacy retro observations (bullets under a retro's `## Observations` with no `**Retired` marker) that bear on the epic's area.
- Find the test command (library, `composer.json`, `package.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`) and run the suite for the baseline, unless an earlier result stands.
- If the scope holds a `[browser]` criterion (for a small change, once its record is written) and the repo has no browser test tool that runs in the session (step 3), load the claude-in-chrome tools with ToolSearch and list the connected browsers, once per run, and probe the app as step 3 does (and again when the user says they have fixed it): `APP_URL`'s host must be `localhost`, `127.0.0.1` or a `.test` host, and one HTTP request must show the app answering there. With a browser connected and the app answering, open the page the criterion needs (or `APP_URL`) in that browser and note whether it lands on a login page; enter no credentials. Tools not found, or no browser listed, count as not connected. When the run then cannot check it (no connected browser, no app answering at a local `APP_URL`, or no login session where one is needed), say what is missing and how to fix it in the first message after the probe and carry on; with the user present, ask once, before building, whether to fix it first.
- Resume honestly: a story `In Progress` from an earlier session may be partly done, so check the code before redoing or skipping anything. A story marked blocked (a `Not met` line or a ` — blocked:` note) is not resumed until the user settles the blocker: list it under **Needs you** with its reason. If every criterion has an `Evidence` line, confirm the evidence holds, take a red pass (step 4) for each test-proven criterion that has neither a red nor an `existing` reason, audit the story if it has no `**Audit**` line, and close it as step 6 says, before other work.

## The loop

Take unblocked stories lowest number first. A story is unblocked only when every story in its `**Blocked by**` is `Complete` with an `**Audit**` line, since fixes from that story's audit would rework code built on top of it, and every epic its epic's `**Blocked by**` names is `Complete`. Each story goes through these steps, wherever it is built:

1. Set the story, and the epic if it was Pending, to `In Progress`. Call `mcp__cpm-next-models__set_story_effort` with the story's number and `**Effort**` (`medium` when it has none); without that tool, build at the session's effort.
2. Build it task by task, setting each task `In Progress` as you start it and `Complete` when done. Follow the project's existing conventions over your own preferences. In a Laravel project, run the `laravel-simplifier` agent over the story's changes, if available, before verifying.
3. Verify every acceptance criterion with the tests its tag names, or with the manual check and what you observed, in an `Evidence` line directly under it, as the contract shows. A criterion without its own evidence isn't met.
   - `[browser]`: use the repo's own browser test tool when its manifest declares one (`laravel/dusk`, `pestphp/pest-plugin-browser`, `@playwright/test`) and it runs in the session. It gets a red like any test and may start its own server; if it runs outside the project's test command, run it yourself and give its result to the auditor with the full-suite result. Otherwise the lead, never a subagent, uses claude-in-chrome: take the URL from the project's `APP_URL` when its host is `localhost`, `127.0.0.1` or a `.test` host, confirm with one HTTP request that the app answers there, and record the URL, the steps and a short excerpt of the page text (`red: n/a — browser-observed`). Start no server, enter no credentials, create no users; behind a login, use the browser's existing session. Any other case (another host, no answering server, no connected browser, a login with no session, a browser that disconnects later) goes to **Needs you** and is then treated as `[user]`, with an indented `- Waiting on user: {steps}` line under the criterion.
   - `[user]`, and any criterion you can't carry out in the session whatever its tag (a deploy, a production run, a sign-off), is treated as `[user]`: never claim it as met, list it under **Needs you**, and write its `Evidence` line only from the user's own answer, never in a run with no user present. A criterion not tagged `[user]` gets the same `- Waiting on user: {steps}` line, which you remove when you write its `Evidence` line.
4. Check the story as the auditor will, before the audit, in this order:
   - Feed the new code inputs it doesn't expect (empty, missing, null, non-numeric, boundary), and read every help text, doc and `Evidence` line the story touched against the code. Fix what either shows.
   - Run the full suite and fix what it shows, running it again after any fix that changes a file, until a run needs no fix (in a parallel batch, the lead's run after the batch is that run).
   - Take the reds, in one red pass, once no edit to the story's files remains to be made, after the simplifier pass and against the code being closed. A red is required for every criterion a test proves (any tag the project's Testing Strategy maps to a suite, and any untagged criterion a test proves), except one recorded `red: n/a — existing (reaches {file:line})` on the contract's terms. The auditor reports a misused `existing` as a Warning. An `existing` reason on a criterion for new behaviour, on one naming a control, on a test whose body the story changed, or naming a line the test does not execute is a finding. A story with no test-proven criterion, or only `existing` ones, takes no pass. The builder takes the pass in a single build; in a one-checkout parallel batch, the lead's subagent after the batch, as the parallel rules say, never while siblings run; in worktree mode, the subagent in its own worktree, or the lead after merging where subagents write code only.
   - The red pass: create the pass directory, new and empty, at the path the contract's `**Scratch**` field gives, and write its path in a `**Scratch**` line under the story (a worktree subagent skips the line). Write a `manifest` in it, each changed or untracked, not ignored, path with its blob hash (from `git diff HEAD --name-only` and `git ls-files -o --exclude-standard`, hashed with `git hash-object`, a path that no longer exists recorded as `deleted` and not hashed, leaving out the epic doc or `docs/quick/` record, which the pass edits, and diffing against the empty tree when the repository has no commit), and a `tree` file holding the output of `git rev-parse --show-toplevel`. Copy each file the pass will change into the directory at its repository path, once, before its first mutation. Take each red by undoing the lines the cited test covers with the Edit tool and running only that test. Where that leaves it green (a refactor, a characterisation test, code the story didn't change) or makes it error, copy the file back and mutate a covered line instead, which may lie outside the story. The failure must come from the cited assertion: an error (missing class, method, route or table) doesn't count, and a stub that returns a wrong value does. Note the failure text and the undone `{file:lines}` or the mutation, then copy each file back from the pass directory. Never revert with `git checkout`, `git show … >`, `git stash` or `reset`, which take uncommitted work with them. When the last red is taken, recompute the manifest and compare it with the first.
   - On a match, delete the pass directory by its literal, quoted absolute path (never the `scratch/` folder itself, and never a glob) and remove the `**Scratch**` line; only then write each noted red into its criterion's `Evidence` line as the contract shows (a retaken red replaces the earlier one), and a criterion no test proves, or that takes `existing`, records `red: n/a` with its reason. A fix's test for a finding with no criterion takes its red in a pass too, and the red goes in the findings list handed to the next audit. The full-suite result from before the pass stands for the audit; re-run no test.
   - On a mismatch, first copy back every path that has a copy in the pass directory (not `manifest` and `tree`) and differs from it, listed or not, and compare again. A path that was not listed and is now untracked is test output: name it under **Found** and leave it, and count the manifest as matching once nothing else differs. Any other difference, or one that remains (a listed path with no copy, such as a tracked file the test run rewrote), marks the story blocked (the contract's note with the paths, and a signal) and lists it under **Needs you**; the pass directory and the `**Scratch**` line are then removed as above.
5. Have the story audited (see **Audit**). On `fix needed`, set the fix's effort with the same tool (`high`, or `xhigh` for a story already at `high`), fix every Critical and Warning finding wherever its mistake occurs, not only where cited, and give each fix a test, its red recorded in the `Evidence` line of the criterion the finding concerns or, for a finding with no criterion, in the findings list handed to the next audit. Update the `Evidence` lines the fix affects, and check the fix as new code as step 4 says, so the next audit has a full-suite result for the code as it stands; a fix that changes a file a red mutated, or a red's test file, retakes that red in a new pass. Then audit again. If the second audit returns a Critical, fix its findings the same way and audit a third time, saying in one line why. Otherwise, and after any third audit, that audit is the last: if it still returns `fix needed`, record each unresolved finding in a `Not met` line under the criterion it concerns, or as a signal when it concerns none, and treat the story as blocked (see **Signals**).
6. Close the story in the same edit that writes its `**Audit**` line: set any remaining tasks and the story's `**Status**` to `Complete`, and the epic's too if it was the last open story.

Before the next story, re-read the one just finished in the epic doc: it must be `Complete` with an `**Audit**` line, be marked blocked (its status kept, with the contract's ` — blocked: {reason}` note, and a `Not met` line under any unmet criterion), or wait on the user, since an evidenced story left `In Progress` blocks its dependents.

Stories unblocked together are built in parallel, one subagent each, when they share neither files nor runtime state (databases, migrations, dependency installs and lock files, cache and queue state, storage directories, `.env`, ports), judged from the files their tasks name and the code they touch; otherwise, or when the user is working alongside you on a single story or task, one at a time. The lead owns everything shared:

- It runs migrations, dependency installs and the full suite. A story that needs a schema or dependency change goes first, run by the lead, before any fan-out.
- A subagent runs only its own story's tests, and only when the suite is isolated (see **Scratch directories and isolation**); otherwise it writes code only, and the lead runs its tests after it reports. A red pass handed to it, below, is the one exception.
- A subagent leaves `[browser]` criteria to the lead, who checks them after the batch.
- Once the batch has finished and nothing else is running, the lead hands each story's red pass (step 4) to a fresh `sonnet` subagent, one at a time, giving it the story, the cited tests, the pass directory's absolute path, the absolute path of the contract and the absolute path of this file for step 4's rules on taking each red. The lead creates the pass directory, the `**Scratch**` line, the `manifest` and the `tree` file before the hand-off; the subagent copies files into the directory, takes and restores each red, and reports each failure with its `{file:lines}` or mutation, and does not create, compare or delete the directory or touch the epic doc. The lead then compares the manifest itself, deletes the directory, removes the line, and writes the `Evidence` lines from the reported failures after checking each against the test file. No pass runs while batch siblings run, since a sibling's tests would run the code a red has mutated.
- A subagent has none of this conversation, so its prompt names the resources it must leave alone.
- The lead checks each report against the files and test output before the story goes to audit, and makes every audit fix, in its own checkout.

Start each parallel subagent on `sonnet`, and a `**Model**: haiku` story on a `haiku` subagent even when nothing runs beside it.

Hand plain lookups (where something is defined or used, which files a change touches, what a read-only query returns) to the `cpm-next:scout` agent, which keeps search output out of this conversation; read the code yourself when the answer depends on understanding it.

Leave commits, branches and pushes to the user unless they've said otherwise. Asking for `--parallel` is their leave to commit and merge locally on the current branch, never to push.

### Worktree mode

With `--parallel` or `--parallel check`, read `worktree.md` in this skill's directory before building, and follow it: it says which stories a worktree batch may hold, when a worktree's test results count, what each subagent's prompt adds, how the lead merges, and what `--parallel check` reports.

Without `--parallel`, stories that share neither files nor runtime state are still built in parallel; the flag is never needed for them. When unblocked stories that rule keeps apart are waiting, read `worktree.md` and check them as `--parallel check` would, without the report. If a batch qualifies, say so in one line with the next tool call, naming the stories, what they share and `/cpm-next:do {scope} --parallel`, carry on one at a time, and repeat the line under **Found**. Don't switch to worktree mode unasked, since it commits.

### Scratch directories and isolation

At the start of a run, make a run directory under the session's scratchpad, or with `mktemp -d` when there is none. Inside it the lead creates, and passes by absolute path, a fresh auditor directory per audit round (`audit-{epic}-{story}-r{n}`, or `audit-quick-{nn}-r{n}`). No two auditors share one. A red pass's directory is not there: it is `{git common dir}/cpm-next/scratch/{epic file stem}-{story}/` (`quick-{nn}/` for a small change), the common directory found with `git rev-parse --path-format=absolute --git-common-dir`, so it outlives the session and every worktree of the repository shares it. If that path already holds a directory whose `tree` is another checkout (an abandoned worktree's), the pass does not run: mark the story blocked with the reason and a signal.

A suite is isolated when every test process, including a single run without a parallel flag, gets its own database and its own copy of every file tests write (fake disks, SQLite database files, file caches, compiled views, result caches), and no test binds a fixed port. Check this once per run, before the first audit, from the test config and a few tests, whatever the build mode.

A red pass may run while an audit runs only when it mutates no file the audited story changed and that auditor was told to run no tests and no probes, scope being judged from the file list the auditor was given; two full-suite runs, or a full-suite run and a red pass, never overlap in one checkout.

## Audit

Start the `auditor` agent with the Agent tool, `subagent_type` `cpm-next:auditor`. One auditor checks one story, with no limit on its length and nothing in its checklist narrowed, since a shared or capped audit leaves findings for the next round. It has none of this conversation, so give it:

- the epic path and story number, or the `docs/quick/` record;
- the files the story changed, or a worktree story's merge commit;
- the test command and the result of the full-suite run made after the story's last change (counts, and any failing test). That result covers every test the `Evidence` lines cite, so name no test files or modules for it to run: it reads the tests and their recorded red results, and runs none to reproduce a red;
- when the story took a red pass, that the pass ended with a matching manifest;
- the absolute path of the contract (`shared/artifacts.md`, resolved from this skill's directory);
- its auditor directory, for probe scripts, test output and `TMPDIR`;
- whether the suite is isolated or free; in a suite that is neither, the auditor runs no tests and no probes and works from the tests and the full-suite result it was given. The lead may say an unisolated suite is free only when it will wait for that audit in the foreground and make no test-running call, start no red pass and start no other test-running audit until it reports;
- the resources it must leave alone.

Audits of stories that share no files may run in parallel, isolated suite or not. A later audit also gets the previous audit's findings as it wrote them, which you dismissed and why, and the files the fixes changed, but no description of the fixes: it audits the fix code as new code.

Check each finding against the code before acting on it, and drop any that don't hold up. Suggestions are neither fixed nor recorded. A finding that contradicts the criterion rather than the code goes through **When a criterion looks wrong**.

Record the outcome as `**Audit**: pass ({YYYY-MM-DD})`, adding `, {n} findings fixed` when the first audit returned `fix needed`. If the `auditor` agent isn't available, write `**Audit**: skipped — auditor unavailable` and say so under **Found**.

## Signals

Write a `**Signal**` on the story, or in the `docs/quick/` record (form and slug rule in the contract), when an audit finding holds, when you mark a story blocked (step 5, **When to stop**), and when you write an `**Amended**`, `**Inline change**` or `**Pivot deferred**` line (**When a criterion looks wrong**): one per class per story. An unresolved finding that concerns no criterion is a signal too. A `process` signal names the cpm-next file and step involved. Before choosing a slug, grep the `**Signal**:` lines in `docs/epics/`, `docs/archive/epics/` and `docs/quick/`, the library's `**Class**` lines and the contract's seed slugs, and reuse one that fits.

After writing each signal, separately, check whether it recurs. Look in this order: a library lesson with that `**Class**` (or, for a lesson with none, one that describes the failure); a signal with that slug in a different epic or quick record, `docs/archive/` included; an unretired legacy retro observation (read them once per run or, with more than 20 retro files, have `scout` list those matching the signal's terms). Read both to confirm they describe the same failure, and on a match append ` — recurs: {reference} ({why it matches, one clause})`. A match within the same epic is not a recurrence. A rejected `**Class**` or signal match gives the signal a different slug, matched once more under it; after a rejected description match, carry on down the order.

Route a recurrence by its kind. A `project` signal that recurs with no library lesson, none of whose matches carries a ` — declined` or ` — promoted` mark, goes under **Needs you** with the matching signals and the constraint proposed (the rule, how a criterion or check shows it holds, and the owning layer), and is marked ` — raised {YYYY-MM-DD}`. A signal matching a declined one is marked ` — declined` too and not raised. A `process` signal, and a signal that recurs against a library lesson, go under **Found** only. A signal that matches a candidate still waiting for its answer, or any signal listed with or joined to it, whatever its epic, joins that candidate instead of becoming another, and is marked ` — raised` too. One that matches an answered candidate takes its answer: declined after a no, whatever the epic, and after a yes a recurrence against the new lesson, under **Found**. A signal that never recurs is never reported.

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
- A change of scope in an unattended run: amend the criterion in this epic only, with an `**Amended**` line carrying the citation, and add a `**Pivot deferred**` line for each upstream document that now disagrees. Leave the spec and every other document untouched; `plan` resolves those later with the user.

## Finishing

End every run with three headings, in this order:

- **Needs you**: only what won't happen unless the user acts, each line naming the action and what it unblocks: a decision only they can make, a blocked story and what would unblock it, a `**Pivot deferred**` item (with `/cpm-next:plan {path of the upstream document}`), a promotion candidate, a `[user]` criterion of a story waiting on the user, with its steps, a destructive step you held back from, and any step outside the repository the change depends on (a migration on a deployed database, a secret or environment value, a service to restart). Leave out optional follow-ups, things worth a look and anything already done; say "Nothing" if so.
- **Changed**: stories completed, the main files touched, and the test result against the baseline.
- **Found**: anything surprising about the codebase, the plan or the tests. Nothing here asks the user to act; an action it implies goes under **Needs you**.

When the run leaves a spec finished (every one of its epics `Complete`, or open only for stories waiting on the user), add one line after the headings suggesting `/cpm-next:library sweep`, which looks across repositories for failures a cpm-next rule could have prevented; when `~/.claude/cpm-next/repos.txt` does not list this repository, suggest `/cpm-next:library sweep add {its path}` first. It is a suggestion, not a **Needs you** item.

Then take the **Needs you** items one at a time, the one blocking most work first. For each, say in a few lines what it is and where (`file:line`, or the epic and story), what each way of settling it leads to, and which you recommend and why. Ask with one AskUserQuestion call holding that one question, your recommendation as the first option and `Leave it for now` as the last, and act on the answer before raising the next item:

- a criterion the user changes: amend it with an `**Amended**` line citing their decision, and clear its `Not met` line, and the story's ` — blocked:` note once no other `Not met` line or unresolved finding remains;
- a destructive step they approve: carry it out;
- a step outside the repository: give the exact steps, and ask only when what you do next depends on it being done;
- a `**Pivot deferred**` item: recommend `/cpm-next:plan`, and leave the upstream document to it;
- a promotion candidate: on a yes, write the lesson as an entry in the library's `lessons-learned.md` (an existing file ending in `lessons-learned.md` counts) in the contract's form, unless the library already holds a lesson with that `**Class**` or one describing the rule; create the file with its front-matter when missing, add the entry's scope values to the file's `scope` and set `last-reviewed` to today, leaving an existing file's header alone when it has no front-matter; then mark the candidate, each signal it matched and each signal that joined it ` — promoted {YYYY-MM-DD}`. On a no, mark them ` — declined {YYYY-MM-DD}`. Write no amendment to any other library document: `library learn` does that;
- the `[browser]` criteria that fell back to the user (step 3): ask once for all of them, whether the user will fix the environment (an app answering at the local `APP_URL`, a connected browser, a login session) so that you run them all, or report the results themselves. Once it is fixed, check each through claude-in-chrome as step 3 says, record it `browser-observed` and remove its `- Waiting on user:` line, and for each story whose criteria then all have `Evidence`, take step 4, audit it and close it as step 6 says; a check that fails gets a `Not met` line in place of its `- Waiting on user:` line and the contract's blocked note on its story; a reported result is written as the next item describes;
- a `[user]` criterion: ask for the result of its steps. On success, write `Evidence (user, {YYYY-MM-DD}): {what they reported} — red: n/a — user` under it, and once no criterion in the story lacks `Evidence`, take step 4 for the story, audit it and close it as step 6 says; on failure, write a `Not met` line and mark the story blocked with the contract's note;
- a blocked story: once the user settles the blocker (a decision, a fix, or an amended criterion), clear its `Not met` lines for what is settled and, when nothing else blocks it, its note, then resume the story through the loop.

An item left for now stays recorded where it is. Once the last item is settled, build the stories the answers unblocked through the loop, and end that run with the three headings again.
