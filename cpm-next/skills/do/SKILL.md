---
name: do
description: Build from CPM epic documents until every story in scope is Complete and the tests pass — one story, one epic, one spec's epics or all remaining epics unattended — or carry out a small change directly when there is no epic. Picks the next unblocked work, implements it, verifies each acceptance criterion with evidence, and keeps the epic doc as the live task list. Use whenever the user wants planned work built, continued or finished, or a small well-defined change made. Triggers on "/cpm-next:do".
model: sonnet
effort: medium
---

# Do

Build what the epics describe, and prove it. The epic doc is the task list: it's what the user reads to see where the run is, what survives context compaction, and what the next session resumes from. Keep it current as you go.

Formats, status vocabulary and the unblocked-story rule are in `shared/artifacts.md` at the plugin root, two levels above this skill's directory.

## Scope and finish line

Read `$ARGUMENTS`:

| Argument | Scope | Done when |
|---|---|---|
| epic path | that epic | all its stories are Complete |
| story or task ID (`3`, `2.1`) | that item, in the epic resolved below | that item is Complete |
| `all` | every unfinished, unretired epic, in dependency order | no unblocked story remains |
| `all {spec}` (`all 43`) | every unfinished, unretired epic whose prefix starts with that spec number, in dependency order; stop before building if there is none | no unblocked story remains in those epics |
| a description of a small change | no epic | the change works and is tested |
| nothing | the lowest-numbered In Progress epic, else the lowest-numbered epic with nothing started | that epic's stories are Complete |

`--parallel` may follow any scope but a small change, and builds in worktrees (see **Worktree mode**). `--parallel check` builds nothing and writes nothing: it reports what worktree mode would do with the scope.

In every case the full test suite must also pass at the end, or any failures that remain must have been failing before the run started. Record the baseline before changing anything.

A full-suite result already in this conversation stands for the baseline or the end-of-run check when `git status` and `git diff` show no file has changed since that run; run the suite again only when one has.

For a small change with no epic, write the `docs/quick/` record before changing any code. Read what **Before the first story** lists that bears on the change, and the code it touches, then give the record the acceptance criteria the change must meet, in the story format the contract shows. Cover everything the description asks for, each place the same fault or feature occurs, and a tagged test for each criterion that code can prove. Where the description and the code leave the extent genuinely open, so that two reasonable readings would build different things, show the user the criteria and ask which they mean, in one message, before building; otherwise don't ask. Then build it as one story, through steps 2 to 5 of **The loop**, with the `Evidence` lines in the record and the record as the story the auditor checks. Finish by adding the audit verdict to the record. A description doesn't say what complete means, and without written criteria neither the build nor the audit can tell that part of it is missing. If the criteria come to more than one story's worth of work, stop before building and suggest `/cpm-next:plan`.

## Before the first story

- Read `CLAUDE.md`, `docs/library/`, the epic, its source spec, and any ADRs it cites.
- Skim `docs/retros/` for observations that bear on this epic's area and treat them as context, skipping any marked `**Retired`.
- Find the test command from the library, `composer.json`, `package.json`, `Makefile`, `pyproject.toml` or `Cargo.toml`. Run the suite to get the baseline, unless an earlier result stands for it as above.
- Resume honestly: a story marked `In Progress` from an earlier session may be partly done. Check the code before redoing or skipping anything. If every one of its criteria already has an `Evidence` line, confirm the evidence still holds, audit it if it has no `**Audit**` line, then close it as step 6 of the loop says, before picking any other work.

## The loop

Take unblocked stories lowest number first. When two or more are unblocked at once, build them in parallel as described below. A story is unblocked only when every story in its `**Blocked by**` is `Complete` with an `**Audit**` line, not when that story's code is written. Don't start a dependent story while the one it depends on waits for its audit. Code built on an unaudited story has to be reworked when that audit's fixes change it, and then one audit covers two stories' changes. Each story goes through these steps wherever it is built:

1. Set the story (and the epic, if it was Pending) to `In Progress`. Call `mcp__cpm-next-models__set_story_effort` with the story's `**Effort**` (`medium` when it has none) and its number. The tool comes from the `cpm-next-models` mod; when it isn't available, build at the session's effort.
2. Build it, task by task. Set each task `In Progress` when you start it and `Complete` when it's done. Follow the project's existing conventions over your own preferences. In a Laravel project, run the `laravel-simplifier` agent over the story's changes if it's available, before verifying, so the evidence is gathered against the final code.
3. Verify every acceptance criterion. Run the tests its tag names, or carry out the manual check and say what you observed. Write an `Evidence` line directly under that criterion, as the contract shows, so each proof sits beside the claim it proves. A criterion without its own evidence isn't met.
4. Check the story the way the auditor will, before asking for the audit; these are the findings a first audit most often returns. Run the full suite once, and fix what it shows; in a parallel batch, the lead's run after the batch is that run. For each test the story added, confirm it fails without the change: undo the line it covers and run it, or show why it must. Feed the new code the inputs it doesn't expect: empty, missing, null, non-numeric, boundary. Read every help text, doc and `Evidence` line the story touched against the code.
5. Have the story audited before closing it (see **Audit** below). If it returns `fix needed`, set the effort for the fix with the same tool, `high`, or `xhigh` for a story already at `high`. Fix every Critical and Warning finding wherever its mistake occurs, not only at the line cited, and give each fix a test that fails without it. Treat the fix as new code and check it as step 4 says, update the `Evidence` lines the fixes affect, run the full suite once so the second audit has a result for the code as it stands, and audit once more, giving the auditor the first audit's findings. If the second audit returns a Critical, fix its findings the same way and audit a third time, given the second audit's findings; say in one line why. Otherwise, and after any third audit, that audit is the last. If it still returns `fix needed`, record each unresolved finding in a `Not met` line under the criterion it concerns, or as a `**Retro**` line when it concerns no criterion, and treat the story as blocked.
6. Close the story in the same edit that writes its `**Audit**` line: set any remaining tasks and the story's `**Status**` to `Complete`. If it was the epic's last open story, set the epic's `**Status**` to `Complete` too. Add a `**Retro**` line only for something future work genuinely needs to know.

Before starting the next story, re-read the one you just finished in the epic doc. Its `**Status**` must read `Complete` with an `**Audit**` line, or it must carry a `Not met` line and be marked blocked. An evidenced story left `In Progress` blocks every story that depends on it, because the unblocked rule reads only the status.

Stories that are unblocked together are built in parallel by default, one subagent each, when they share neither files nor runtime state. Shared runtime state includes databases, migrations, dependency installs and lock files, cache and queue state, storage directories, `.env`, and ports. Judge overlap from the files each story's tasks name and the code they touch; ask the `scout` agent where that isn't clear. Build them one at a time when they overlap, or when the user is working alongside you on a single story or task. With `--parallel`, stories that share files can also run together, each in its own worktree.

The lead agent owns everything shared, and subagents don't touch it:

- The lead runs migrations, dependency installs and the full test suite. A story that needs a schema or dependency change goes first, run by the lead, before any fan-out.
- A subagent runs only the tests for its own story, against isolated state. Use the project's parallel-testing support where it has one (for example Pest's `--parallel`, which gives each process its own test database), or an in-memory database. If that isolation isn't available, the subagent writes code only, and the lead runs its tests after it reports.
- Each subagent's prompt names the resources it must leave alone. It won't know about them otherwise.

When a subagent reports back, check its evidence against the files and test output before marking its story Complete. After a parallel batch, run the full suite once, since conflicts between stories show up only when the pieces are combined.

Start each parallel subagent on the `sonnet` model, the same model this skill builds on. A story marked `**Model**: haiku` goes to a subagent on `haiku` even when nothing runs beside it, so the lead keeps its own model and the conversation's cache. The lead makes any fixes its audit asks for.

### Worktree mode

With `--parallel`, unblocked stories are built together even when they touch the same files. Each subagent works in its own git worktree (the Agent tool's `isolation: "worktree"`), and the lead merges them. The mode covers code and tests. The running app, its domains, real databases, webhooks and third-party services stay with the lead's checkout.

These stories still run one at a time, after the batch:

- a story that depends on another story in the batch;
- one that changes a dependency lock file, `.env` or shared config;
- a migration that changes a table another story in the batch uses;
- a story whose criteria need the running app: a browser check, Dusk, a real webhook or a third-party call.

Run no more than three at once. Each worktree runs its own tests, and on one machine more of them only slow each other down.

A worktree's test results count only if the suite runs without shared services. That means a per-process or in-memory database (`phpunit.xml` with SQLite `:memory:`, or `php artisan test --parallel`), outbound HTTP faked with stray requests prevented (`Http::preventStrayRequests()`), queues and mail faked, no fixed port, and no build output the checkout lacks (in Laravel, Vite's manifest; tests can call `withoutVite()`). Check this once per run, from the test config and a few tests. Where it doesn't hold, the subagents write code only, and the lead runs each story's tests after merging it.

A worktree starts from the last commit, so commit the run's own work before each fan-out. If the tree holds changes this run didn't make, don't use worktree mode: say so, and build one at a time. Asking for `--parallel` is the user's leave to commit and merge locally on the current branch. It never covers a push.

Each subagent's prompt adds these to the usual one:

- Set up the worktree first. Install dependencies from the lock file (`composer install`, `npm ci`), and copy from the lead's checkout the gitignored files its tests need (`.env`, local settings), pointed at test resources. Don't symlink `vendor/` or `node_modules/`: Composer's autoloader resolves paths from its real location, so it would load the lead's code.
- Don't start a server, run migrations or seeders against a real database, call a real service, or edit the epic doc.
- Commit the story on the worktree's branch. Report the branch, the files changed, the tests run with their output, and what proves each criterion; the lead writes the `Evidence` lines.

The lead merges the branches in story order with `git merge --no-ff`. After resolving a conflict, run both stories' tests again. Then run the full suite once, as after any parallel batch. Audit each story with its merge commit, whose diff against its first parent is that story alone. The lead makes the fixes in its own checkout. Remove each worktree and its branch once the story is merged.

`--parallel check` reads only. It reports the unblocked stories in scope, the batches worktree mode would form and why any story stays out, whether the suite is isolated (citing the config lines that show it), and the setup each worktree would need.

A run without `--parallel` builds stories that share neither files nor runtime state in parallel in its own checkout, as above; the flag is never needed for them. For stories that rule leaves one at a time, it makes the same check as `--parallel check`, without the report. If a batch qualifies, say so in one line in the same message as the next tool call, naming the stories, what they share, and `/cpm-next:do {scope} --parallel`, then carry on one at a time, and repeat it under **Found** at the end of the run. Don't switch to worktree mode unasked, since it commits. Check the suite's isolation once per run, not at every batch.

Hand plain lookups to the `cpm-next:scout` agent: where something is defined or used, which files a change touches, what a read-only query returns. It runs on Haiku and returns only the answer, which keeps search output out of this conversation. Do the reading yourself when the answer depends on understanding the code, not finding it.

## Audit

This skill builds on Sonnet; the `auditor` agent checks each story on Opus before it closes. Start it with the Agent tool, `subagent_type` `cpm-next:auditor`, and give it the epic path and story number (or the `docs/quick/` record), the files the story changed, the test command, the result of the full-suite run made after the story's last change (counts, and any test that failed), and the resources it must leave alone. That result covers every test the `Evidence` lines cite, so don't name test files or modules it may run: it reads the tests, and runs one only to show that it can't fail. It gets none of this conversation. One auditor checks one story, with no limit on its length and nothing in its checklist narrowed; several stories to one auditor, or a word cap, leaves findings for the next round. Audit a parallel subagent's story the same way after checking its report; audits of stories that share no files or state can run in parallel.

For a later audit, give it the previous audit's findings as it wrote them, which you dismissed and why, and the files the fixes changed. Don't describe the fixes: it audits the fix code as new code, which is where later audits find most problems, and outside the fixes it reports only a Critical it missed before.

Check each finding against the code before acting on it, and drop any that don't hold up. Suggestions are not fixed in this run; record one as a `**Retro**` line only if future work needs it. When a finding contradicts the story's criterion rather than the code, it is a criterion question and goes through **When a criterion looks wrong**, not a fix.

Record the outcome on the story as `**Audit**: pass ({YYYY-MM-DD})`, adding `, {n} findings fixed` when the first audit returned `fix needed`. If the `auditor` agent isn't available, write `**Audit**: skipped — auditor unavailable` and say so under **Found** at the end of the run.

Leave commits, branches and pushes to the user unless they've said otherwise, or the run is in worktree mode.

## When to stop and when to keep going

A message without a tool call ends the turn, and the work stops until someone replies. While stories in scope remain open, don't end a turn in any of these four ways:

1. a summary of progress that announces the next step without taking it;
2. an offer to carry on unless the user would prefer otherwise;
3. a list of decisions for the user when none of them blocks the remaining work;
4. a report because a story finished or the turn has run long.

Status notes and recommendations are welcome, but put them in the same message as the next tool call, and carry on with whatever doesn't depend on an answer.

Stop and ask only when:

- a test fails for a reason you can't explain after investigating it;
- an acceptance criterion contradicts reality and resolving it would change scope (below);
- the next action is destructive or reaches outside this repository: deleting data, rewriting history, touching shared infrastructure.

For an `all` run, with or without a spec, or whenever the user has said they won't be watching, don't stop for the first two. Mark the story blocked with the reason, and move on to other unblocked work. The third always stops the run.

When the user is working alongside you (a single story or task), open with a one-line plan and let them redirect between stories if they choose. The four rules above still apply within a story.

A story isn't finished while a subagent or background command it started is still running. Wait for the output and check it.

## When a criterion looks wrong

A criterion that is hard to meet is not a criterion that is wrong. "The tests fail", "this approach didn't work" and "it's slower than the target" are reports about this implementation, and never justify changing the criterion. Leave it standing, mark the story blocked, and record what was tried in a `Not met` line under that criterion.

A criterion is wrong only when you can cite something that contradicts it: a `file:line`, a named requirement in the spec (`FR3`, `AD1`), or another criterion in the same epic that can't be satisfied at the same time.

- A wording fix with no change of scope: edit it and add an `**Inline change**` line.
- A change of scope, when the user is present: ask, showing the citation.
- A change of scope in an unattended run: amend the criterion in this epic only, with an `**Amended**` line carrying the citation, and add a `**Pivot deferred**` line for each upstream document that now disagrees. Leave the spec and every other document untouched; `plan` resolves those later with the user.

## Finishing

When the epic reaches `Complete` in the loop: if the run produced observations worth carrying forward, write a short retro to `docs/retros/` in the contract's format; otherwise add `**Retro waived**: clean run` to the epic header, so it doesn't sit waiting for a retro that has nothing to say.

End every run with three headings, in this order:

- **Needs you**: what won't happen unless the user acts, each line naming the action and what it unblocks. That is a decision only they can make, a blocked story and what would unblock it, a `**Pivot deferred**` item (to settle with `/cpm-next:plan`), a destructive step you held back from, and any step outside the repository the change depends on, such as a migration on a deployed database, a secret or environment value, or a service to restart. Leave out optional follow-ups, things worth a look, and anything already done; they belong under the other headings or nowhere. Say "Nothing" if so.
- **Changed**: stories completed, the main files touched, and the test result against the baseline.
- **Found**: anything surprising about the codebase, the plan, or the tests. Nothing here asks the user to act; an action it implies goes under **Needs you**.

Then take the **Needs you** items one at a time, the one blocking most work first. For each, say in a few lines what it is and where (`file:line`, or the epic and story), what each way of settling it leads to, and which you recommend and why. Ask with one AskUserQuestion call holding that one question, your recommendation as the first option and `Leave it for now` as the last, and act on the answer before raising the next item:

- a criterion the user changes: amend it with an `**Amended**` line citing their decision, and clear its `Not met` line;
- a destructive step they approve: carry it out;
- a step outside the repository: give the exact steps, and ask only when what you do next depends on it being done;
- a `**Pivot deferred**` item: recommend `/cpm-next:plan` and leave the upstream document to it.

An item left for now stays recorded where it is. Stories the answers unblock are built through the loop once the last item is settled, and that run ends with the three headings again.
