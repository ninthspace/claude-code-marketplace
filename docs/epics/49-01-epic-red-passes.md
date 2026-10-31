# Red passes

**Source spec**: docs/specifications/49-spec-cheaper-red-first-evidence.md  
**Date**: 2026-10-31  
**Status**: Complete  
**Blocked by**: —  
**Lessons**: docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md → "A criterion that names a mapping with no tag to key it on" (Story 1), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 1), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 2), docs/library/01-library-lessons-learned.md → "A control mutation needs a revert that cannot take the tree with it" (Story 2), docs/library/01-library-lessons-learned.md → "A check that passes may be passing for a reason other than the one you want" (Story 2), docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md → "The revert method for a recorded red went through four rounds" (Story 2), docs/retros/11-retro-prose-rules-need-a-reader-who-is-not-the-writer.md → "The revert method for a recorded red went through four rounds" (Story 3), docs/library/04-library-model-specific-accommodations.md → "A delegated finding is spot-checked in the file before it is acted on" (Story 3)  
**Amended**: 2026-10-31 — rewritten after review 07 (docs/reviews/07-review-red-passes.md); Story 3's resume restores every directory for its own checkout, whatever its story (spec FR4 amended)

## The contract's evidence and scratch forms
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-31), 2 findings fixed  
**Blocked by**: —  
**Satisfies**: FR1, FR4, FR14

**Acceptance Criteria**:

- `cpm-next/shared/artifacts.md` shows the test-proven `Evidence` form as `{test name, file:line}{ ({command})} — red: {message} with {lines undone in {file:lines} | mutation of {file:line}: {change}}`, where `{message}` is the first line of the failure message, or for a multi-line diff the first line that names the expected and actual values; it says the command is omitted when it is the project's test command run on the named test, and `grep -c "green after restore" cpm-next/shared/artifacts.md` returns 0 `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:137` shows `{test name, file:line}{ ({command})} — red: {message} with {lines undone in {file:lines} | mutation of {file:line}: {change}}`; the paragraph at `:146` defines `{message}` and the omitted command; `grep -c "green after restore" cpm-next/shared/artifacts.md` printed 0 — red: n/a — manual
- The contract defines `red: n/a — existing (reaches {file:line})` and keys it: it fits a test-proven criterion (a tag the project's Testing Strategy maps to a suite, or untagged and proved by a test) that keeps behaviour the code already had and names no control, proved by a test whose own body is unchanged in the story's diff and that passed in the baseline, the `file:line` being a line the story changed that the test executes. A criterion names a control when it is a must-not, must-not-change or never criterion under `plan`'s rule, or its text says `control`. The `n/a` mapping lists `existing`; the sentence "A criterion a test proves takes no `n/a`" becomes one allowing `existing` and nothing else; and misuse of `existing` is a Warning, not the Critical a misfitting `n/a` reason otherwise is `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:148` defines `red: n/a — existing (reaches {file:line})`, keys it to a test-proven criterion (a tag mapped to a suite, or untagged and proved by a test) that keeps existing behaviour and names no control, whose test's own body is unchanged in the diff and passed in the baseline; it defines "names a control", replaces "takes no `n/a`" with "takes no other `n/a`", and `:146` lists `existing` among the `n/a` reasons, judges it on every criterion whatever the tag, and says its misuse is a Warning, not the Critical of a misfitting `n/a`; the template at `:139` offers `existing (reaches {file:line})` and `:146` allows it in place of a red — red: n/a — manual
- The contract holds this sentence verbatim, for `do` and the auditor to repeat: "An `existing` reason on a criterion for new behaviour, on one naming a control, on a test whose body the story changed, or naming a line the test does not execute is a finding." `[manual]`
  - Evidence: `grep -cF` for the sentence "An `existing` reason on a criterion for new behaviour, on one naming a control, on a test whose body the story changed, or naming a line the test does not execute is a finding." prints 1 for `cpm-next/shared/artifacts.md`; `do` and the auditor repeat it in 49-01 Story 2 and 49-02 Story 1 — red: n/a — manual
- The `**Scratch**` field names `{absolute git common dir}/cpm-next/scratch/{epic file stem}-{story}/` (or `quick-{nn}/`), and says it exists only while a red pass runs and that the directory also holds the pass's `manifest` and `tree` files `[manual]`
  - Evidence: `cpm-next/shared/artifacts.md:155` names `{absolute git common dir}/cpm-next/scratch/{epic file stem}-{story}/` (or `quick-{nn}/`), says the directory exists only while a red pass runs, and that it holds the `manifest` and `tree` files — red: n/a — manual

### Edit the contract
**Task**: 1.1  
**Description**: Amend the evidence block, the `n/a` mapping paragraph and the `**Scratch**` field in `cpm-next/shared/artifacts.md`.  
**Status**: Complete

---

## Red passes in do
**Story**: 2  
**Status**: Complete  
**Audit**: pass (2026-10-31), 3 findings fixed  
**Blocked by**: Story 1  
**Satisfies**: FR1, FR2, FR3  
**Effort**: high  
**Signal**: procedure-gap — project — the rewritten step 4 left three gaps a first reading met in normal use: a suite result taken before a fix, a deleted path breaking the manifest, and a mismatch restore that skipped unlisted paths (`cpm-next/skills/do/SKILL.md:51-55`, audit round 1)

**Acceptance Criteria**:

- `do` step 4 requires a red for every test-proven criterion except one recorded `existing` on the contract's terms, and holds the contract's `existing` sentence verbatim; a story with no test-proven criterion, or only `existing` ones, takes no pass `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:53` requires a red for every criterion a test proves except one recorded `red: n/a — existing (reaches {file:line})` on the contract's terms, holds the sentence "An `existing` reason on a criterion for new behaviour, on one naming a control, on a test whose body the story changed, or naming a line the test does not execute is a finding." (`grep -cF` prints 1 for `SKILL.md`) and says a story with no test-proven criterion, or only `existing` ones, takes no pass — red: n/a — manual
- Step 4 orders the work: the inputs-it-doesn't-expect probe and the read-through of docs and help text, then the full-suite run, then any fixes they need, then the red pass, which starts only when no edit to the story's files remains to be made `[manual]`
  - Evidence: `do/SKILL.md:50-53` orders step 4 as the inputs probe and read-through (`:51`), the full-suite run, run again after any fix that changes a file, until a run needs no fix (`:52`), then the red pass "once no edit to the story's files remains to be made" (`:53`) — red: n/a — manual
- Step 4 states the pass in this order: create the directory at the contract's path and write it in the story's `**Scratch**` line; write to `manifest` in it each changed or untracked, not ignored, path with its blob hash (`git diff HEAD --name-only` and `git ls-files -o --exclude-standard`, hashed with `git hash-object`, excluding the epic doc or quick record, and diffing against the empty tree when the repository has no commit), and to `tree` the output of `git rev-parse --show-toplevel`; copy each file into the directory at its repository path once, before its first mutation; for each red, undo the covered lines with the Edit tool, run only the cited test, read the failure, note it, copy the file back; then recompute the manifest and compare `[manual]`
  - Evidence: `do/SKILL.md:54` states the pass in order: new, empty pass directory at the contract's path and the `**Scratch**` line; `manifest` (`git diff HEAD --name-only`, `git ls-files -o --exclude-standard`, `git hash-object`, a path that no longer exists recorded as `deleted`, leaving out the epic doc or quick record, the empty tree when there is no commit) and `tree` (`git rev-parse --show-toplevel`); copy each file once before its first mutation; each red by undoing the covered lines with the Edit tool and running only the cited test; recompute and compare the manifest after the last red — red: n/a — manual
- Step 4 keeps today's rules: the failure must come from the cited assertion, and an error (missing class, method, route or table) doesn't count while a stub returning a wrong value does; where the undo leaves the test green or erroring, copy back and mutate a covered line instead, which may lie outside the story; never revert with `git checkout`, `git show … >`, `git stash` or `reset`; who takes the red in a single build, a one-checkout batch and worktree mode `[manual]`
  - Evidence: `do/SKILL.md:53-54` keep the failure-from-the-cited-assertion rule (an error doesn't count, a wrong-valued stub does), the fallback to a mutated covered line outside the story, the ban on `git checkout`, `git show … >`, `git stash` and `reset`, and who takes the pass in a single build, a one-checkout batch and worktree mode — red: n/a — manual
- On a matching manifest, `do` deletes the directory by its literal, quoted absolute path, never the `scratch/` folder itself or a glob, removes the `**Scratch**` line, and only then writes each red into its criterion's `Evidence` line from the noted failures; the full-suite result from before the pass stands for the audit and no test is re-run green `[manual]`
  - Evidence: `do/SKILL.md:55` — on a match delete the directory by its literal, quoted absolute path (never `scratch/` or a glob), remove the `**Scratch**` line, then append the noted reds to the `Evidence` lines; "The full-suite result from before the pass stands for the audit; re-run no test." — red: n/a — manual
- On a mismatch: a listed path whose hash differs is copied back from the directory and the manifest compared again; a path that was not listed and is now untracked is test output, named under **Found** and left alone; any other difference, or one that remains, marks the story blocked with the paths and a signal, lists it under **Needs you**, and the directory is deleted as above `[manual]`
  - Evidence: `do/SKILL.md:56` — first copy back every path that has a copy in the pass directory and differs, listed or not, and compare again; an unlisted untracked path is test output named under **Found**, and the manifest counts as matching once nothing else differs; any other difference, or one that remains, blocks the story with the contract's note, the paths and a signal, lists it under **Needs you**, and the directory and the `**Scratch**` line are removed — red: n/a — manual
- Step 5 says a fix that changes a file a red mutated, or a red's test file, retakes that red in a new pass `[manual]`
  - Evidence: `do/SKILL.md:57` (step 5) — "a fix that changes a file a red mutated, or a red's test file, retakes that red in a new pass" — red: n/a — manual
- In `cpm-next/skills/do/SKILL.md` and `cpm-next/skills/do/worktree.md`, `grep -c "red pass"` on `do/SKILL.md` returns at least 1; `grep -c "Make a directory for this red"`, `grep -c "green again"` and `grep -c "green after restore"` return 0 on each file `[manual]`
  - Evidence: `grep -c "red pass" cpm-next/skills/do/SKILL.md` printed 2; `grep -c` for "Make a directory for this red", "green again" and "green after restore" printed 0 on `SKILL.md` and on `worktree.md` — red: n/a — manual

### Rewrite steps 4 and 5
**Task**: 2.1  
**Description**: Amend `cpm-next/skills/do/SKILL.md` steps 4 and 5, and the matching terms in `worktree.md`.  
**Status**: Complete

---

## Scratch location, resume and the delegated pass
**Story**: 3  
**Status**: Complete  
**Audit**: pass (2026-10-31), 4 findings fixed  
**Blocked by**: Story 2  
**Satisfies**: FR4, FR16  
**Effort**: high  
**Signal**: procedure-gap — project — the resume restore was not first in **Before the first story**, the delegated pass left the subagent steps it must not do, and the worktree pass bullet applied where subagents write code only (`cpm-next/skills/do/SKILL.md:35-39,67`, `worktree.md:20`, audit round 1)

**Acceptance Criteria**:

- `do` **Scratch directories and isolation** names the pass directory under `{absolute git common dir}/cpm-next/scratch/`, found with `git rev-parse --path-format=absolute --git-common-dir`; builder directories are gone, auditor directories stay in the run directory under the session scratchpad, and `grep -c "builder directory"` returns 0 on `do/SKILL.md` and `worktree.md` `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:85` names the pass directory `{git common dir}/cpm-next/scratch/{epic file stem}-{story}/` (`quick-{nn}/`), found with `git rev-parse --path-format=absolute --git-common-dir`, keeps only the auditor directory in the run directory under the session scratchpad, and says a path already holding another checkout's directory blocks the pass; `grep -c "builder director"` printed 0 for `do/SKILL.md` and `worktree.md` — red: n/a — manual
- `do` **Before the first story** says that before any other work a run restores the files of every scratch directory whose `tree` file names the checkout it runs in, whatever its story or quick record, deletes the directory and removes its line; deletes, naming it under **Found**, a directory whose `tree` no longer exists; and leaves a directory whose `tree` is another existing checkout to that checkout `[manual]`
  - Evidence: `do/SKILL.md:35` — the first bullet of **Before the first story**, "before the baseline and any other work, in every run, a small change included" (`:31` says a small change reads that bullet always): restore the files (not `manifest` and `tree`) of every scratch directory whose `tree` equals `git rev-parse --show-toplevel` run now, whatever its story or quick record, delete the directory and remove its line; delete one with no `tree` file; delete, naming it under **Found**, one whose `tree` no longer exists; leave one whose `tree` is another existing checkout to that checkout — red: n/a — manual
- A `**Scratch**` line whose directory is gone and lies under the git common directory is removed (the pass was interrupted after its deletion); one naming a path outside it (a 0.10.0 session-scratchpad directory) stops the story and lists it under **Needs you**, since its files may still be mutated `[manual]`
  - Evidence: `do/SKILL.md:35` — a `**Scratch**` line whose directory is gone and lay under the common directory is removed; one naming a path outside it (a directory in a session scratchpad) stops the story and goes under **Needs you**, since its files may still be mutated — red: n/a — manual
- On resume, an evidenced story gets a red pass for each test-proven criterion that has neither a red nor an `existing` reason `[manual]`
  - Evidence: `do/SKILL.md:39` — "take a red pass (step 4) for each test-proven criterion that has neither a red nor an `existing` reason" — red: n/a — manual
- `worktree.md` says a worktree subagent's pass uses the same path in the main repository's common directory, with its worktree in `tree`, and that it commits only after its pass's directory is gone `[manual]`
  - Evidence: `cpm-next/skills/do/worktree.md:20` — when the worktree's test results count, the subagent takes the story's red pass before committing, its directory at the same path in the main repository's common directory with the worktree in `tree`, gone when the commit is made (otherwise it writes code only and the lead takes the pass after merging); `:3` names "the red pass" among the terms — red: n/a — manual
- In a one-checkout parallel batch, once the batch has finished and nothing else is running, the lead hands each story's red pass to a fresh `sonnet` subagent, one at a time, giving it the story, the cited tests, the contract's path and the absolute path of `do/SKILL.md` for the pass rules; the lead writes the `**Scratch**` line and the manifest before the hand-off, compares the manifest itself afterwards, and writes the `Evidence` lines from the subagent's reported failures after checking each against the test file. `do` says no pass runs while batch siblings run, giving the reason in one clause (a sibling's tests run mutated code), and the rule that a subagent runs only its own story's tests names this hand-off as the exception `[manual]`
  - Evidence: `do/SKILL.md:67` — once the batch has finished and nothing else is running, the lead hands each story's red pass to a fresh `sonnet` subagent, one at a time, giving it the story, the cited tests, the pass directory's absolute path, the contract's and this file's absolute paths; the lead creates the directory, `**Scratch**` line, `manifest` and `tree` first; the subagent copies files in, takes and restores each red and reports each failure with its `{file:lines}` or mutation, and does not create, compare or delete the directory or touch the epic doc; the lead then compares the manifest, deletes the directory, removes the line and writes the `Evidence` lines after checking the reported failures against the test file; no pass runs while batch siblings run, with the reason in one clause; `:65` names the hand-off as the exception to "a subagent runs only its own story's tests"; step 4 (`:53`) points at it — red: n/a — manual

### Edit do and worktree.md
**Task**: 3.1  
**Description**: Amend `do/SKILL.md` (**Before the first story**, **Scratch directories and isolation**, the parallel rules) and `worktree.md`.  
**Status**: Complete

---
