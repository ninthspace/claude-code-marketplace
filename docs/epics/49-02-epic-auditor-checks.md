# Auditor checks for red passes

**Source spec**: docs/specifications/49-spec-cheaper-red-first-evidence.md  
**Date**: 2026-10-31  
**Status**: Complete  
**Blocked by**: Epic 49-01-epic-red-passes  
**Lessons**: docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 1)  
**Amended**: 2026-10-31 — the `existing` sentence check, the manifest wording and FR6 moved here after review 07 (docs/reviews/07-review-red-passes.md)

## Check 5 reads the new evidence
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-31), 3 findings fixed
**Blocked by**: —  
**Satisfies**: FR1, FR3, FR7, FR14  
**Amended**: criterion 4 ties the manifest statement to a story that took a red pass (a story whose criteria all take `existing` takes none) and drops "the full-suite result predates it", which cannot be said after a conflicted worktree merge re-runs the suite; a matching manifest already shows the pass left the tree as it was (2026-10-31) — cited: `cpm-next/skills/do/SKILL.md` step 4 ("A story with no test-proven criterion, or only `existing` ones, takes no pass") and `cpm-next/skills/do/worktree.md:23` (the lead runs the full suite after a conflicted merge)
**Pivot deferred**: FR7's "The audit prompt says the red pass ended with a matching manifest and that the full-suite result predates it; a story with test-proven criteria and no such statement is a Warning" → docs/specifications/49-spec-cheaper-red-first-evidence.md (Story 1, 2026-10-31) — cited: `cpm-next/skills/do/SKILL.md` step 4 (a story with no test-proven criterion, or only `existing` ones, takes no pass) and `cpm-next/skills/do/worktree.md` (the lead re-runs the suite after a conflicted merge)  
**Signal**: spec-drift — project — FR7 required the manifest statement of every story with test-proven criteria, though stories whose criteria all take `existing` take no pass (`cpm-next/agents/auditor.md:24`, audit round 1)

**Acceptance Criteria**:

- Auditor check 5 reads the contract's new `Evidence` form and no longer requires `green after restore` `[manual]`
  - Evidence: `cpm-next/agents/auditor.md:24` (check 5) reads each test-proven criterion's red result in its `Evidence` line and no longer lists `green after restore` (`grep -c "green after restore" cpm-next/agents/auditor.md` printed 0) — red: n/a — manual
- Check 5 holds the contract's `existing` sentence verbatim and reports such a finding as a Warning; control: `grep -rlF` for the full sentence ("An `existing` reason on a criterion for new behaviour, on one naming a control, on a test whose body the story changed, or naming a line the test does not execute is a finding.") lists exactly `cpm-next/shared/artifacts.md`, `cpm-next/skills/do/SKILL.md` and `cpm-next/agents/auditor.md` `[manual]`
  - Evidence: `grep -rlF` for the sentence "An `existing` reason on a criterion for new behaviour, on one naming a control, on a test whose body the story changed, or naming a line the test does not execute is a finding." over `cpm-next/shared/artifacts.md`, `cpm-next/skills/do/SKILL.md` and `cpm-next/agents/auditor.md` lists exactly those three files (`grep -cF` prints 1 in each); check 5 reports it as a Warning "whatever the tag" (`auditor.md:24`) — red: n/a — manual
- Check 5 reports as a Warning a recorded failure text that is not what the cited assertion would print for the recorded change `[manual]`
  - Evidence: `cpm-next/agents/auditor.md:24` lists "has failure text that is not what the cited assertion would print for the recorded change" among the Warnings of check 5 — red: n/a — manual
- Check 5 reports as a Warning a story that took a red pass whose audit prompt does not say the pass ended with a matching manifest; `do` **Audit** lists that statement among what the prompt gives `[manual]`
  - Evidence: `auditor.md:24` — "for a story that took a red pass, check the prompt says the pass ended with a matching manifest", a story that took a pass whose prompt lacks it being a Warning, and a missing red a Warning only "on a criterion with no `existing` reason"; `cpm-next/skills/do/SKILL.md:98` lists "when the story took a red pass, that the pass ended with a matching manifest" among what the audit prompt gives — red: n/a — manual

### Edit the auditor and do's Audit list
**Task**: 1.1  
**Description**: Amend `cpm-next/agents/auditor.md` check 5 and the list in `do/SKILL.md` **Audit**.  
**Status**: Complete

---

## The suite-free handshake
**Story**: 2  
**Status**: Complete  
**Audit**: pass (2026-10-31)  
**Blocked by**: Story 1  
**Satisfies**: FR6, FR8

**Acceptance Criteria**:

- `do` **Scratch directories and isolation** says a red may run while an audit runs only when it mutates no file the audited story changed and that auditor was told the suite is not free, so runs no tests and no probes, and judges scope from the file list it is given; a full-suite run never overlaps another or a red in the same checkout; the sentence "No red is taken (no source file mutated) in the checkout while any auditor is running" is gone `[manual]`
  - Evidence: `cpm-next/skills/do/SKILL.md:89` (**Scratch directories and isolation**) says a red pass may run while an audit runs only when it mutates no file the audited story changed and that auditor was told to run no tests and no probes, scope being judged from the file list the auditor was given, and that two full-suite runs, or a full-suite run and a red pass, never overlap in one checkout; `grep -c "No red is taken (no source file mutated) in the checkout while any auditor" cpm-next/skills/do/SKILL.md` printed 0 — red: n/a — manual
- `do` **Audit** says that in an unisolated suite the lead tells an auditor the suite is free only when it will wait for that audit in the foreground and makes no test-running call, starts no red and no other test-running audit until it reports; otherwise it tells the auditor the suite is not free `[manual]`
  - Evidence: `do/SKILL.md:101` (**Audit**) — "whether the suite is isolated or free; in a suite that is neither, the auditor runs no tests and no probes…", and the lead may say an unisolated suite is free only when it will wait for that audit in the foreground and make no test-running call, start no red pass and start no other test-running audit until it reports — red: n/a — manual
- The auditor's opening rules say it runs tests or probes only when told the suite is isolated or free, and runs nothing otherwise; check 8 follows the same rule `[manual]`
  - Evidence: `cpm-next/agents/auditor.md:12` (opening rules) — "Run the project's tests and probes only when the prompt says the suite is isolated or free; otherwise run neither, and work from the tests and the full-suite result you were given"; check 6 (`:25`) allows probes when isolated or free; check 8 (`:27`) runs the full suite only when isolated or free and no result was given; `:16` lists "whether the suite is isolated or free" and tells the auditor to take the story's files from the prompt's list — red: n/a — manual

### Edit the auditor and do's Audit section
**Task**: 2.1  
**Description**: Amend `auditor.md` (opening rules, check 3, check 8) and `do/SKILL.md` (**Audit**, **Scratch directories and isolation**).  
**Status**: Complete

---
