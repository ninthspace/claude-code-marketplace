---
name: do
description: Build from CPM epic documents until every story in scope is Complete and the tests pass — one story, one epic, or all remaining epics unattended — or carry out a small change directly when there is no epic. Picks the next unblocked work, implements it, verifies each acceptance criterion with evidence, and keeps the epic doc as the live task list. Use whenever the user wants planned work built, continued or finished, or a small well-defined change made. Triggers on "/cpm-next:do".
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

For a small change with no epic: do it, test it, and write a short `docs/quick/` record. If it turns out to need more than one story's worth of work, stop and suggest `/cpm-next:plan`.

## Before the first story

- Read `CLAUDE.md`, `docs/library/`, the epic, its source spec, and any ADRs it cites.
- Skim `docs/retros/` for observations that bear on this epic's area and treat them as context. No gate, no dispositions.
- Find the test command from the library, `composer.json`, `package.json`, `Makefile`, `pyproject.toml` or `Cargo.toml`. Run the suite to get the baseline.
- Resume honestly: a story marked `In Progress` from an earlier session may be partly done. Check the code before redoing or skipping anything.

## The loop

For each unblocked story, lowest number first:

1. Set the story (and the epic, if it was Pending) to `In Progress`.
2. Build it. Follow the project's existing conventions over your own preferences.
3. Verify every acceptance criterion. Run the tests its tag names, or carry out the manual check and say what you observed. Write an `Evidence` line directly under that criterion, as the contract shows, so each proof sits beside the claim it proves. A criterion without its own evidence isn't met.
4. Review the story's diff as a reviewer would: list only problems you'd block a merge for, and fix them. In a Laravel project, use the `laravel-simplifier` agent if it's available.
5. Mark tasks and the story `Complete`. Add a `**Retro**` line only for something future work genuinely needs to know.

Time matters in this run: avoid spending time that can be avoided, because a correct result sooner is better. Stories that are unblocked together can go to subagents in parallel, but only when they share neither files nor runtime state. Shared runtime state includes databases, migrations, dependency installs and lock files, cache and queue state, storage directories, `.env`, and ports.

The lead agent owns everything shared, and subagents don't touch it:

- The lead runs migrations, dependency installs and the full test suite. A story that needs a schema or dependency change goes first, run by the lead, before any fan-out.
- A subagent runs only the tests for its own story, against isolated state. Use the project's parallel-testing support where it has one (for example Pest's `--parallel`, which gives each process its own test database), or an in-memory database. If that isolation isn't available, the subagent writes code only, and the lead runs its tests after it reports.
- Each subagent's prompt names the resources it must leave alone. It won't know about them otherwise.

When a subagent reports back, check its evidence against the files and test output before marking its story Complete. After a parallel batch, run the full suite once, since conflicts between stories show up only when the pieces are combined. When stories share files or state, run them one at a time.

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

When an epic's last story completes, set the epic `Complete`. If the run produced observations worth carrying forward, write a short retro to `docs/retros/`; otherwise add `**Retro waived**: clean run` to the epic header, so it doesn't sit waiting for a retro that has nothing to say.

End every run with three headings, in this order:

- **Blocked on me**: decisions, blocked stories, `**Pivot deferred**` items, anything destructive you held back from. Say "Nothing" if so.
- **Changed**: stories completed, the main files touched, and the test result against the baseline.
- **Found**: anything surprising about the codebase, the plan, or the tests.
