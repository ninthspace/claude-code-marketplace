# Discussion: The cost of red-first evidence, and corrections

**Date**: 2026-10-31  
**Participants**: the user, Claude  
**Status**: Concluded

## Context

cpm-next 0.9.0 (spec 47) made every test-proven criterion record a red: the builder undoes the covered lines, runs the cited test, reads the failure, restores the files and runs it green (`cpm-next/skills/do/SKILL.md:49-52`). It also added `[user]` and `[browser]` tags, per-run scratch directories and isolation rules. A review of the release against 0.8.7 found the development benefit real (it targets the failure seen in 25+ ice-analytics retros and five other repositories) and these costs:

1. **Time per story.** Each red takes about 10 tool calls (directory, `**Scratch**` line, copy, undo, run, copy back, run green, delete directory, delete line, append evidence), for every test-proven criterion, including tests that existed and passed before the story. Audit fixes need reds too.
2. **Less parallel work.** In a one-checkout batch only the lead takes reds, after the batch (`:49`); no red is taken while any auditor runs (`:85`); with an unisolated suite subagents write code only and the lead runs their tests (`:62`).
3. **Working-tree risk.** Red copies live in the session scratchpad under `/private/tmp`, which may be gone when an interrupted run resumes (`:38`). A run stopped mid-red leaves a mutated source file, and `/commitp` (`git add -A`) would commit it. The revert wording needed four audit rounds (`docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md`).
4. **A weaker auditor in unisolated suites.** The auditor no longer breaks lines itself; in an unisolated suite it runs no tests (`:96`) and works only from the builder's recorded red.
5. **Stories waiting on the user shown as work.** Such stories count as done for `do`, but `whats-next` offers them as next and `cpm-next-progress` shows them in progress (README, "Upgrading to 0.9.0"). A `[browser]` criterion `do` falls back to treating as `[user]` keeps its tag, so no mod can tell.
6. **Browser checks fall back late.** `do` probes for a browser tool and a connected browser at run start (`:37`) but reports what is missing only at the end, by which time an unattended run has turned every browser check into a user item.
7. **The user-checks epic.** Exists only for specs with `[user]` criteria (`cpm-next/skills/plan/SKILL.md:47`); keeps user waits off the build's path.
8. **Smaller costs.** Long `Evidence` lines; no back-fill of epics planned before 0.9.0; 0.9.0 itself was size-neutral (SKILL.md words fell 9,182 to 8,346).

## Decisions

- **Reds only for new or changed tests** — a red is required for a test the story added or changed. A cited test that existed and passed before the story records `red: n/a — existing`, and the auditor confirms it existed before the story (from the diff). The retros' failures were new tests that could not fail; re-proving passing tests is the largest single cost. (cost 1)
- **One scratch copy per story** — one directory and one `**Scratch**` line per story, each file copied once before its first mutation; each red is then undo, run, copy back. About 10 calls per red become about 4. (cost 1)
- **The full suite confirms the restore** — step 4 takes the reds first and then runs the full suite once, which shows every file was put back; the per-test green re-run goes. The audit still gets a full-suite result for the final code. (cost 1)
- **Subagents take their own reds** — in a one-checkout batch, a subagent takes its reds when the suite is isolated and every line it mutates is in its own story's files; otherwise the lead takes them after the batch, as now. (cost 2)
- **Reds during other audits** — a red may run while an audit is in progress if it mutates no file in the audited story's diff; today any running audit blocks every red. (cost 2)
- **Red copies under `.git/cpm-next/`** — copies go to `$(git rev-parse --git-common-dir)/cpm-next/scratch/{epic}-{story}/`: they survive sessions, need no `.gitignore` entry and cannot be committed. Auditor directories stay in the session scratchpad. (cost 3)
- **Block commits mid-red** — a mod hook refuses a `git commit` made through Claude while a `**Scratch**` line remains in `docs/epics/` or `docs/quick/`, naming the story and saying to resume `do` or restore the files. Commits from the user's own terminal are not covered. (cost 3)
- **The auditor checks the failure text fits** — it confirms each recorded failure is what the cited assertion would print for the recorded change; a mismatch is a Warning, as a missing red is now. (cost 4)
- **The auditor runs tests when alone** — in an unisolated suite the lead tells the auditor whether nothing else is using the suite (no other audit, red or suite run); only then may it run tests, and the lead holds reds and suite runs until it reports. (cost 4)
- **cpm-next-progress shows "Waiting on input"** — a story waiting on a user check gets that existing tracker status, by the same rule `status` uses, and counts in the overview's waiting figure. (cost 5)
- **whats-next skips and lists** — it never offers a story waiting on a user check as next, and lists those stories in a "Waiting on you" group with each check's steps. (cost 5)
- **A marker for fallback criteria** — when `do` treats a criterion not tagged `[user]` as `[user]` (a browser check with no server or browser, a deploy), it writes an indented `- Waiting on user: {steps}` line under it; `status` and the mods read that line instead of inferring it. (cost 5)
- **Say what's missing at the start** — when the scope holds `[browser]` criteria the run can't check (no app answering at `APP_URL`, no connected browser, no login session), its first message says what is missing and how to fix it, then carries on; in an attended run that is one question before building. (cost 6)
- **Group and retry browser checks at the end** — in the **Needs you** walk-through, browser checks that fell back are one question: fix the environment and let `do` run them, or report the results. If fixed, `do` checks them through claude-in-chrome and records them `browser-observed`. (cost 6)
- **Shorter Evidence lines** — `red: {assertion message line} with {change}`; the command is omitted when it is the project's test command run on the named test, and `green after restore` goes with the per-test green run. (cost 8)

## Open Questions

- Which mod owns the commit hook: `cpm-next-models` (already loaded wherever cpm-next runs, but about models) or `cpm-next-progress` (already parses epic docs)?
- How the auditor establishes that an `existing` test predates the story when the story's changes are uncommitted: the test file's absence from `git diff` and `git status`, or its presence at `HEAD`.
- The auditor's current rule makes a missing `green after restore` a Warning (`cpm-next/agents/auditor.md`); it has to change with the shorter form, and the `n/a` reason table in `cpm-next/shared/artifacts.md` needs `existing`.
- Whether the `- Waiting on user:` line can be confused with `- Not met:` by the mods' and `status`'s parsers, which key on indented lines under criteria.
- A worktree subagent's reds: its copies would go under the main repository's common `.git` directory; confirm the path is unique per worktree story.

## Positions Not Taken

- **Offer suite isolation once** — raising a one-off Needs you item with the change that would isolate the suite; not chosen for now.
- **Nudge when only the user-checks epic is left** — `status` leading with it and the overview marking the spec "waiting on your checks"; the epic and the walk-through already raise it.
- **Back-fill older epics with reds** — expensive, touches finished work, and with reds limited to new or changed tests older epics matter less.
- **Leaving any cost as it is** — rejected for costs 1–6 and 8.

## Recommended Next Step

`/cpm-next:plan docs/discussions/23-discussion-cost-of-red-first-evidence.md` to write spec 49 and its epics; the changes touch `cpm-next` (do, auditor, contract, plan), `cpm-next-progress`, `whats-next` and one mod hook.
