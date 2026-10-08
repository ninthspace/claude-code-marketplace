---
name: do
description: Build from CPM epic documents until every story in scope is Complete and the tests pass — one story, one epic, or all remaining epics unattended — or carry out a small change directly when there is no epic. Picks the next unblocked work, implements it, verifies each acceptance criterion with evidence, and keeps the epic doc as the live task list. Use whenever the user wants planned work built, continued or finished, or a small well-defined change made. Triggers on "/cpm-next:do".
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
| a description of a small change | no epic | the change works and is tested |
| nothing | the lowest-numbered In Progress epic, else the lowest-numbered epic with nothing started | that epic's stories are Complete |

In every case the full test suite must also pass at the end, or any failures that remain must have been failing before the run started. Record the baseline before changing anything.

For a small change with no epic: do it, test it, have it audited as below, and write a short `docs/quick/` record that includes the audit verdict. If it turns out to need more than one story's worth of work, stop and suggest `/cpm-next:plan`.

## Before the first story

- Read `CLAUDE.md`, `docs/library/`, the epic, its source spec, and any ADRs it cites.
- Skim `docs/retros/` for observations that bear on this epic's area and treat them as context, skipping any marked `**Retired`.
- Find the test command from the library, `composer.json`, `package.json`, `Makefile`, `pyproject.toml` or `Cargo.toml`. Run the suite to get the baseline.
- Resume honestly: a story marked `In Progress` from an earlier session may be partly done. Check the code before redoing or skipping anything. If every one of its criteria already has an `Evidence` line, confirm the evidence still holds, audit it if it has no `**Audit**` line, then close it as step 5 of the loop says, before picking any other work.

## The loop

Take unblocked stories lowest number first. When two or more are unblocked at once, build them in parallel as described below. Each story goes through these steps wherever it is built:

1. Set the story (and the epic, if it was Pending) to `In Progress`. Call `mcp__cpm-next-models__set_story_effort` with the story's `**Effort**` (`medium` when it has none) and its number. The tool comes from the `cpm-next-models` mod; when it isn't available, build at the session's effort.
2. Build it, task by task. Set each task `In Progress` when you start it and `Complete` when it's done. Follow the project's existing conventions over your own preferences. In a Laravel project, run the `laravel-simplifier` agent over the story's changes if it's available, before verifying, so the evidence is gathered against the final code.
3. Verify every acceptance criterion. Run the tests its tag names, or carry out the manual check and say what you observed. Write an `Evidence` line directly under that criterion, as the contract shows, so each proof sits beside the claim it proves. A criterion without its own evidence isn't met.
4. Have the story audited before closing it (see **Audit** below). If it returns `fix needed`, set the effort for the fix with the same tool, `high`, or `xhigh` for a story already at `high`, then fix every Critical and Warning finding, update the `Evidence` lines the fixes affect, and audit once more. If the second audit still returns `fix needed`, record each unresolved finding in a `Not met` line under the criterion it concerns, or as a `**Retro**` line when it concerns no criterion, and treat the story as blocked.
5. Close the story in the same edit that writes its `**Audit**` line: set any remaining tasks and the story's `**Status**` to `Complete`. If it was the epic's last open story, set the epic's `**Status**` to `Complete` too. Add a `**Retro**` line only for something future work genuinely needs to know.

Before starting the next story, re-read the one you just finished in the epic doc. Its `**Status**` must read `Complete` with an `**Audit**` line, or it must carry a `Not met` line and be marked blocked. An evidenced story left `In Progress` blocks every story that depends on it, because the unblocked rule reads only the status.

Stories that are unblocked together are built in parallel by default, one subagent each, when they share neither files nor runtime state. Shared runtime state includes databases, migrations, dependency installs and lock files, cache and queue state, storage directories, `.env`, and ports. Judge overlap from the files each story's tasks name and the code they touch; ask the `scout` agent where that isn't clear. Build them one at a time when they overlap, or when the user is working alongside you on a single story or task.

The lead agent owns everything shared, and subagents don't touch it:

- The lead runs migrations, dependency installs and the full test suite. A story that needs a schema or dependency change goes first, run by the lead, before any fan-out.
- A subagent runs only the tests for its own story, against isolated state. Use the project's parallel-testing support where it has one (for example Pest's `--parallel`, which gives each process its own test database), or an in-memory database. If that isolation isn't available, the subagent writes code only, and the lead runs its tests after it reports.
- Each subagent's prompt names the resources it must leave alone. It won't know about them otherwise.

When a subagent reports back, check its evidence against the files and test output before marking its story Complete. After a parallel batch, run the full suite once, since conflicts between stories show up only when the pieces are combined. When stories share files or state, run them one at a time.

Start each parallel subagent on the `sonnet` model, the same model this skill builds on. A story marked `**Model**: haiku` goes to a subagent on `haiku` even when nothing runs beside it, so the lead keeps its own model and the conversation's cache. The lead makes any fixes its audit asks for.

Hand plain lookups to the `cpm-next:scout` agent: where something is defined or used, which files a change touches, what a read-only query returns. It runs on Haiku and returns only the answer, which keeps search output out of this conversation. Do the reading yourself when the answer depends on understanding the code, not finding it.

## Audit

This skill builds on Sonnet; the `auditor` agent checks each story on Opus before it closes. Start it with the Agent tool, `subagent_type` `cpm-next:auditor`, and give it the epic path and story number (or the change description), the files the story changed, the test command, and the resources it must leave alone. It gets none of this conversation. Audit a parallel subagent's story the same way after checking its report; audits of stories that share no files or state can run in parallel.

Check each finding against the code before acting on it, and drop any that don't hold up. Suggestions are not fixed in this run; record one as a `**Retro**` line only if future work needs it. When a finding contradicts the story's criterion rather than the code, it is a criterion question and goes through **When a criterion looks wrong**, not a fix.

Record the outcome on the story as `**Audit**: pass ({YYYY-MM-DD})`, adding `, {n} findings fixed` when the first audit returned `fix needed`. If the `auditor` agent isn't available, write `**Audit**: skipped — auditor unavailable` and say so under **Found** at the end of the run.

Leave commits, branches and pushes to the user unless they've said otherwise.

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

For an `all` run, or whenever the user has said they won't be watching, don't stop for the first two. Mark the story blocked with the reason, and move on to other unblocked work. The third always stops the run.

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

- **Blocked on me**: decisions, blocked stories, `**Pivot deferred**` items, anything destructive you held back from. Say "Nothing" if so.
- **Changed**: stories completed, the main files touched, and the test result against the baseline.
- **Found**: anything surprising about the codebase, the plan, or the tests.
